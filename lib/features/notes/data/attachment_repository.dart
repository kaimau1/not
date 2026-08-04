import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../ai/data/ai_gate.dart' show premiumProvider;
import '../../auth/presentation/auth_providers.dart';
import '../domain/attachment.dart';
import 'notes_repository.dart' show storageUsedBytesProvider;

final attachmentRepositoryProvider = Provider<AttachmentRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  // Premium 50 MB, ücretsiz 10 MB'a kadar ek yükleyebilir.
  final premium = ref.watch(premiumProvider).value ?? false;
  final maxBytes = premium
      ? AppConstants.maxPremiumAttachmentBytes
      : AppConstants.maxFreeAttachmentBytes;
  return AttachmentRepository(
    FirebaseStorage.instance,
    uid,
    maxBytes,
    quotaBytes: premium
        ? AppConstants.maxPremiumStorageBytes
        : AppConstants.maxFreeStorageBytes,
    // Kullanılan alan İSTEK ANINDA okunur (`watch` değil): depo notlar her
    // değiştiğinde yeniden kurulsaydı yükleme kuyruğu elindeki nesneyi
    // kaybederdi.
    usedBytes: () => ref.read(storageUsedBytesProvider),
  );
});

class _CompressRequest {
  const _CompressRequest(this.bytes, this.maxDimension);

  final Uint8List bytes;
  final int maxDimension;
}

class _CompressResult {
  const _CompressResult(this.bytes, this.width, this.height, this.isJpg);

  final Uint8List bytes;
  final int width;
  final int height;
  final bool isJpg;
}

_CompressResult _compressImage(_CompressRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) {
    return _CompressResult(request.bytes, 0, 0, false);
  }
  var picture = decoded;
  final longest = picture.width > picture.height
      ? picture.width
      : picture.height;
  if (longest > request.maxDimension) {
    picture = img.copyResize(
      picture,
      width: picture.width >= picture.height ? request.maxDimension : null,
      height: picture.height > picture.width ? request.maxDimension : null,
      interpolation: img.Interpolation.linear,
    );
  }
  // Ölçüt tek yerde: [AppConstants.imageJpegQuality] (q75) ve
  // [AppConstants.maxImageDimension] (1600 px). OCR/"PDF'i özetle" akışları bu
  // görsellerden metin okuyor ama Gemini görseli 768 px'lik karolarla
  // işlediğinden bu ölçü onlara yetiyor; senkron boyutu belirgin küçülüyor.
  final encoded = Uint8List.fromList(
    img.encodeJpg(picture, quality: AppConstants.imageJpegQuality),
  );
  // Yeniden kodlama dosyayı büyüttüyse orijinali koru.
  if (encoded.length >= request.bytes.length) {
    return _CompressResult(request.bytes, decoded.width, decoded.height, false);
  }
  return _CompressResult(encoded, picture.width, picture.height, true);
}

class _CropRequest {
  const _CropRequest(this.bytes, this.left, this.top, this.right, this.bottom);

  final Uint8List bytes;

  /// Kırpma dikdörtgeni, görsel boyutunun oranı (0–1).
  final double left;
  final double top;
  final double right;
  final double bottom;
}

/// Kırpma her zaman JPEG üretir — `prepareImage` de girişte aynısını yapıyor,
/// ayrıca `image` paketi WebP YAZAMIYOR; tek çıkış biçimi tutmak "png olarak
/// kırpılınca dosya büyüdü" ve "webp kırpılamıyor" dallarının ikisini birden
/// siliyor. Saydamlık düzleşir; girişte de düzleştiği için yeni bir kayıp yok.
_CompressResult _cropImage(_CropRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) return _CompressResult(request.bytes, 0, 0, false);
  final x = (request.left * decoded.width).round().clamp(0, decoded.width - 1);
  final y = (request.top * decoded.height).round().clamp(0, decoded.height - 1);
  final w = ((request.right - request.left) * decoded.width).round().clamp(
    1,
    decoded.width - x,
  );
  final h = ((request.bottom - request.top) * decoded.height).round().clamp(
    1,
    decoded.height - y,
  );
  final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
  final encoded = Uint8List.fromList(
    img.encodeJpg(cropped, quality: AppConstants.imageJpegQuality),
  );
  return _CompressResult(encoded, cropped.width, cropped.height, true);
}

/// [incoming] bayt eklenirse toplam depolama tavanı aşılır mı.
///
/// [quota] 0 (ya da altı) = tavan yok. [incoming] EKSİ olabilir: yerini aldığı
/// eski ek düşüldüğünde (kırpma) fark küçülür.
bool storageQuotaExceeded({
  required int used,
  required int incoming,
  required int quota,
}) {
  if (quota <= 0) return false;
  return used + incoming > quota;
}

/// Ekleri önce cihaza kopyalar (not çevrimdışıyken bile eklenebilsin),
/// sonra Firebase Storage'a yükler. Yükleme kuyruğu [uploadPending] üzerinden
/// çalışır.
class AttachmentRepository {
  AttachmentRepository(
    this._storage,
    this.uid,
    this.maxBytes, {
    this.quotaBytes = 0,
    this.usedBytes,
  });

  final FirebaseStorage _storage;
  final String uid;

  /// Bu kullanıcı için izin verilen en büyük ek boyutu (premium'a göre).
  final int maxBytes;

  /// Bu kullanıcının TOPLAM depolama tavanı (bayt). 0 = sınırsız (testler ve
  /// tavan devre dışıyken).
  final int quotaBytes;

  /// Şu an kullanılan alan. Çağrı anında okunur; null ise tavan denetlenmez.
  final int Function()? usedBytes;

  /// Yeni gelen [incoming] bayt tavanı aşıyor mu. Tek kapı: her `prepare*`
  /// kendi denetimini yazsaydı biri eklendiğinde sessizce tavansız kalırdı.
  void _checkQuota(int incoming) {
    final used = usedBytes;
    if (used == null) return;
    if (storageQuotaExceeded(
      used: used(),
      incoming: incoming,
      quota: quotaBytes,
    )) {
      throw StorageFullException(quotaBytes);
    }
  }

  static const _uuid = Uuid();

  Future<Directory> _attachmentsDir(String noteId) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'attachments', noteId));
    await dir.create(recursive: true);
    return dir;
  }

  /// Eki kalıcı hâle getirir. Cihazda önce YEREL kopya yazılır (çevrimdışıyken
  /// de ek eklenebilsin; yükleme sonra [upload] ile yapılır). Tarayıcıda dosya
  /// sistemi yok — `path_provider`'ın web karşılığı olmadığından baytlar
  /// doğrudan Storage'a gider, yani web'de çevrimdışı-önce yoktur.
  ///
  /// Tüm ek türleri buradan geçer: bu ayrım her `prepare*` içinde ayrı ayrı
  /// yazılsaydı biri unutulduğunda yalnız o tür sessizce kırılırdı.
  Future<Attachment> _store(
    String noteId,
    Attachment meta,
    Uint8List bytes, {
    int freedBytes = 0,
  }) async {
    // [freedBytes]: aynı çağrıda yerini alacağı eski ekin boyutu (kırpma).
    // Sayılmasaydı tavana dayanmış kullanıcı görselini KIRPAMAZDI — kırpma
    // yeri neredeyse her zaman boşaltır.
    _checkQuota(bytes.length - freedBytes);
    final objectName = '${meta.id}_${meta.fileName}';
    if (!kIsWeb) {
      final dir = await _attachmentsDir(noteId);
      final file = File(p.join(dir.path, objectName));
      await file.writeAsBytes(bytes, flush: true);
      return meta.copyWith(localPath: file.path);
    }
    final storagePath = 'users/$uid/notes/$noteId/$objectName';
    final ref = _storage.ref(storagePath);
    // putFile'ın bayt karşılığı; web'de dosya tutamacı olmadığından tek yol.
    await ref.putData(bytes, SettableMetadata(contentType: meta.mimeType));
    return meta.copyWith(
      storagePath: storagePath,
      downloadUrl: await ref.getDownloadURL(),
    );
  }

  /// Görseli küçültüp yerel kopyasını oluşturur; yükleme sonradan yapılır.
  Future<Attachment> prepareImage({
    required String noteId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final result = await compute(
      _compressImage,
      _CompressRequest(bytes, AppConstants.maxImageDimension),
    );
    if (result.bytes.length > maxBytes) {
      throw const FileTooLargeException();
    }
    final id = _uuid.v4();
    final safeName = result.isJpg
        ? '${p.basenameWithoutExtension(fileName)}.jpg'
        : p.basename(fileName);
    return _store(
      noteId,
      Attachment(
        id: id,
        kind: AttachmentKind.image,
        fileName: safeName,
        mimeType: result.isJpg ? 'image/jpeg' : _mimeFromName(safeName),
        sizeBytes: result.bytes.length,
        width: result.width == 0 ? null : result.width,
        height: result.height == 0 ? null : result.height,
        createdAt: DateTime.now(),
      ),
      result.bytes,
    );
  }

  /// Görseli KALICI olarak kırpar (kullanıcı kararı 2026-07-30): dosyanın
  /// kendisi yeniden yazılır, kırpma dikdörtgeni saklanmaz.
  ///
  /// Neden kalıcı: görsel not tuvalinde, tam ekranda, PDF/Word dışa
  /// aktarımında, OCR'de ve AI'ya gönderimde ayrı ayrı çiziliyor. Kırpma
  /// dikdörtgen olarak saklansaydı bu yolların HEPSİ onu uygulamak zorunda
  /// kalırdı; biri unutulduğunda orada kırpılmamış görünürdü. Bedeli: geri
  /// alınamaz.
  ///
  /// Buluttaki kopya SİLİNİR ve ek "yüklenmemiş"e döner (`downloadUrl` boş),
  /// böylece kuyruk yeni baytları kendiliğinden gönderir. Silme, aynı adrese
  /// yazılan yeni dosyanın taze bir indirme adresi almasını da sağlar — eski
  /// adres önbellekte kalsaydı kırpılmamış görsel görünmeye devam ederdi.
  Future<Attachment> cropImage({
    required String noteId,
    required Attachment attachment,
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) async {
    final bytes = await readBytes(attachment);
    if (bytes == null) throw const AttachmentMissingException();
    final result = await compute(
      _cropImage,
      _CropRequest(bytes, left, top, right, bottom),
    );
    if (result.width == 0) throw const AttachmentMissingException();
    if (result.bytes.length > maxBytes) throw const FileTooLargeException();

    await deleteFromStorage(attachment);
    final oldLocalPath = attachment.localPath;
    final safeName = '${p.basenameWithoutExtension(attachment.fileName)}.jpg';
    final stored = await _store(
      noteId,
      attachment.copyWith(
        fileName: safeName,
        mimeType: 'image/jpeg',
        sizeBytes: result.bytes.length,
        width: result.width,
        height: result.height,
        storagePath: '',
        downloadUrl: '',
        ink: cropInk(
          attachment.ink,
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
      ),
      result.bytes,
      freedBytes: attachment.sizeBytes,
    );
    // Uzantı değiştiyse (ör. .png → .jpg) yerel dosya adı da değişti; eskisi
    // artık hiçbir yerden gösterilmiyor, yetim kalmasın.
    if (!kIsWeb && oldLocalPath.isNotEmpty && oldLocalPath != stored.localPath) {
      try {
        await File(oldLocalPath).delete();
      } on FileSystemException {
        // Dosya zaten yoksa yapacak bir şey yok.
      }
    }
    return stored;
  }

  Future<Attachment> preparePdf({
    required String noteId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.length > maxBytes) {
      throw const FileTooLargeException();
    }
    final id = _uuid.v4();
    final safeName = p.basename(fileName);
    return _store(
      noteId,
      Attachment(
        id: id,
        kind: AttachmentKind.pdf,
        fileName: safeName,
        mimeType: 'application/pdf',
        sizeBytes: bytes.length,
        createdAt: DateTime.now(),
      ),
      bytes,
    );
  }

  /// Sunum (PPTX) dosyasını eke dönüştürür. PDF gibi sıkıştırılmaz; metni
  /// yerelde çıkarılıp özetleneceği için baytlar olduğu gibi saklanır.
  Future<Attachment> prepareSlide({
    required String noteId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.length > maxBytes) {
      throw const FileTooLargeException();
    }
    final id = _uuid.v4();
    final safeName = p.basename(fileName);
    return _store(
      noteId,
      Attachment(
        id: id,
        kind: AttachmentKind.slide,
        fileName: safeName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        sizeBytes: bytes.length,
        createdAt: DateTime.now(),
      ),
      bytes,
    );
  }

  /// Ses kaydını yerel eke dönüştürür (kayıt dosyası zaten diskte).
  ///
  /// ponytail: diğer `prepare*`'ların aksine [_store]'a girmez — kaynak zaten
  /// diskte olduğundan `copy` kullanmak baytları belleğe almaktan iyi (ek 50 MB
  /// olabiliyor). Tarayıcıda `record` dosya yolu değil blob adresi döndürdüğü
  /// için bu akış cihaza özel; web'de kayıt düğmesi gizli, yine de buraya
  /// düşerse sessiz donma yerine net hata versin.
  Future<Attachment> prepareAudio({
    required String noteId,
    required String sourcePath,
    required Duration duration,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Tarayıcıda ses kaydı eki desteklenmiyor.');
    }
    final source = File(sourcePath);
    final sizeBytes = await source.length();
    if (sizeBytes > maxBytes) {
      throw const FileTooLargeException();
    }
    // Ses [_store]'a girmiyor (dosya kopyalanıyor), tavan kapısı burada.
    _checkQuota(sizeBytes);
    final id = _uuid.v4();
    final fileName = 'kayit_${duration.inSeconds}s.m4a';
    final dir = await _attachmentsDir(noteId);
    final file = await source.copy(p.join(dir.path, '${id}_$fileName'));
    await source.delete();

    return Attachment(
      id: id,
      kind: AttachmentKind.audio,
      fileName: fileName,
      mimeType: 'audio/mp4',
      localPath: file.path,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
    );
  }

  /// Görüntülü not: kamerayla çekilen videoyu YALNIZCA cihaza kopyalar.
  /// Buluta hiç gitmez (kullanıcı isteği) — bu yüzden boyut sınırı da
  /// uygulanmaz, dosya zaten cihazdan çıkmıyor. Uygulama silinirse ya da
  /// başka cihaza geçilirse video kaybolur; bu bilinçli bir takas.
  Future<Attachment> prepareVideo({
    required String noteId,
    required String sourcePath,
    required Duration duration,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Tarayıcıda görüntülü not desteklenmiyor.');
    }
    final source = File(sourcePath);
    final sizeBytes = await source.length();
    final id = _uuid.v4();
    final ext = p.extension(sourcePath).isEmpty
        ? '.mp4'
        : p.extension(sourcePath);
    final fileName = 'goruntu_${duration.inSeconds}s$ext';
    final dir = await _attachmentsDir(noteId);
    final file = await source.copy(p.join(dir.path, '${id}_$fileName'));

    return Attachment(
      id: id,
      kind: AttachmentKind.video,
      fileName: fileName,
      mimeType: ext == '.mov' ? 'video/quicktime' : 'video/mp4',
      localPath: file.path,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
    );
  }

  /// Bir eki AYNI ya da BAŞKA bir nota kopyalar ("Kopyala → Yapıştır").
  ///
  /// Baytlar yeniden yazılır ve yeni bir kimlik verilir: iki not aynı dosyayı
  /// paylaşsaydı birinden silmek diğerini de boşa düşürürdü. Tür ayrımı yok —
  /// görsel, PDF, sunum, ses ve görüntülü not aynı yoldan geçer; her tür için
  /// ayrı bir kopyalama yazılsaydı biri eklendiğinde sessizce dışarıda kalırdı.
  ///
  /// Kaynak yalnız buluttaysa (başka cihazdan gelen ek) baytlar oradan iner;
  /// hiçbir yerde yoksa [AttachmentMissingException].
  Future<Attachment> duplicate({
    required String noteId,
    required Attachment source,
  }) async {
    final bytes = await readBytes(source);
    if (bytes == null) throw const AttachmentMissingException();
    // Görüntülü not buluta hiç gitmediğinden boyut sınırına da girmez
    // (bkz. prepareVideo).
    if (source.kind != AttachmentKind.video && bytes.length > maxBytes) {
      throw const FileTooLargeException();
    }
    return _store(
      noteId,
      Attachment(
        id: _uuid.v4(),
        kind: source.kind,
        fileName: source.fileName,
        mimeType: source.mimeType,
        sizeBytes: bytes.length,
        width: source.width,
        height: source.height,
        // Görünüm ayarları da taşınır: kopyalanan görsel notta aynı boyutta
        // ve aynı yerleşim kipinde (sayfada/şeritte) belirir. Sayfa üzerindeki
        // KONUM taşınmaz — onu hedef not kendi imlecine göre verir.
        displayWidth: source.displayWidth,
        align: source.align,
        asFile: source.asFile,
        ink: source.ink,
        createdAt: DateTime.now(),
      ),
      bytes,
    );
  }

  /// Yerel kopyası olup henüz yüklenmemiş eki Storage'a gönderir ve
  /// indirme adresiyle birlikte güncellenmiş metadata'yı döner.
  Future<Attachment?> upload(String noteId, Attachment attachment) async {
    // Görüntülü not cihazda kalır: kuyruk atlasa da burada ikinci bir kapı
    // var — yeni bir çağrı yeri eklenirse video yine yüklenmesin.
    if (attachment.kind == AttachmentKind.video) return null;
    if (attachment.isUploaded || attachment.localPath.isEmpty) return null;
    final file = File(attachment.localPath);
    if (!await file.exists()) return null;

    final storagePath =
        'users/$uid/notes/$noteId/${attachment.id}_${attachment.fileName}';
    final ref = _storage.ref(storagePath);
    await ref.putFile(file, SettableMetadata(contentType: attachment.mimeType));
    final url = await ref.getDownloadURL();
    return attachment.copyWith(storagePath: storagePath, downloadUrl: url);
  }

  Future<void> deleteFromStorage(Attachment attachment) async {
    if (attachment.storagePath.isEmpty) return;
    try {
      await _storage.ref(attachment.storagePath).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// PDF baytlarını getirir: önce yerel kopya, yoksa Storage'dan indirir.
  Future<Uint8List?> readBytes(Attachment attachment) async {
    if (attachment.localPath.isNotEmpty) {
      final file = File(attachment.localPath);
      if (await file.exists()) return file.readAsBytes();
    }
    if (attachment.storagePath.isNotEmpty) {
      return _storage
          .ref(attachment.storagePath)
          // Premium tavanı: premium'un yüklediği dosya, sonradan premium
          // olmasa bile indirilebilmeli.
          .getData(AppConstants.maxPremiumAttachmentBytes);
    }
    return null;
  }

  static String _mimeFromName(String name) {
    final ext = p.extension(name).toLowerCase();
    return switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}

class FileTooLargeException implements Exception {
  const FileTooLargeException();
}

/// Toplam depolama tavanı doldu. [FileTooLargeException]'ı GENİŞLETİR:
/// arayüzdeki her `on FileTooLargeException` yakalaması bunu da tutar, yani
/// yeni bir çağrı yeri eklendiğinde ek sessizce tavansız eklenmez — en
/// kötü ihtimalle mesaj "dosya çok büyük" der.
class StorageFullException extends FileTooLargeException {
  const StorageFullException(this.quotaBytes);

  /// Aşılan tavan (bayt).
  final int quotaBytes;
}

/// Ekin baytlarına ulaşılamadı (yerel kopya silinmiş ve bulutta da yok) ya da
/// görsel çözülemedi.
class AttachmentMissingException implements Exception {
  const AttachmentMissingException();
}
