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
import 'drive_store.dart';
import 'notes_repository.dart' show storageUsedBytesProvider;

final attachmentRepositoryProvider = Provider<AttachmentRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  // Premium 50 MB, ücretsiz 10 MB'a kadar ek yükleyebilir.
  final premium = ref.watch(premiumProvider).value ?? false;
  // Ekler Firebase'e GİTMİYORSA (Drive'a ya da hiçbir yere) uygulamanın
  // Firebase tavanları anlamsız: dosya başına sınır premium tavanına çıkar,
  // toplam tavan kalkar — Drive'ın kendi kotası geçerli (kullanıcı isteği
  // 2026-10-15: "oradaki kota kullanılsın").
  final mode = ref.watch(attachmentSyncModeProvider);
  final firebaseBound = mode == AttachmentSyncMode.storage;
  final maxBytes = premium || !firebaseBound
      ? AppConstants.maxPremiumAttachmentBytes
      : AppConstants.maxFreeAttachmentBytes;
  return AttachmentRepository(
    FirebaseStorage.instance,
    uid,
    maxBytes,
    drive: ref.watch(driveStoreProvider),
    quotaBytes: !firebaseBound
        ? 0
        : premium
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

/// Çeyrek tur döndürme isteği (izolat tek argüman alır). [quarterTurns]
/// pozitifse saat yönünde, negatifse tersine.
class _RotateRequest {
  const _RotateRequest(this.bytes, this.quarterTurns);

  final Uint8List bytes;
  final int quarterTurns;
}

/// Görseli 90°'nin katlarıyla döndürür. Kırpmayla aynı gerekçeyle JPEG
/// üretir (bkz. [_cropImage] yorumu).
_CompressResult _rotateImage(_RotateRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) return _CompressResult(request.bytes, 0, 0, false);
  final turned = img.copyRotate(decoded, angle: request.quarterTurns * 90);
  final encoded = Uint8List.fromList(
    img.encodeJpg(turned, quality: AppConstants.imageJpegQuality),
  );
  return _CompressResult(encoded, turned.width, turned.height, true);
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
    this.drive,
  });

  final FirebaseStorage _storage;
  final String uid;

  /// Kullanıcının Google Drive'ı (bağlıysa). null = Drive yok/bağlı değil.
  final DriveStore? drive;

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
    if (used == null || quotaBytes <= 0) return;
    if (storageQuotaExceeded(
      used: used(),
      incoming: incoming,
      quota: quotaBytes,
    )) {
      throw StorageFullException(quotaBytes);
    }
  }

  static const _uuid = Uuid();

  /// Aynı sınırlarla, ekleri BAŞKA bir kullanıcının Storage yoluna
  /// (`users/{ownerUid}/…`) yazan kopya.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-09-23: "ortak nottaki görsel
  /// sorunu"): ortak nota (ya da paylaşılan klasördeki nota) eklenen görsel
  /// ekleyenin KENDİ yoluna gidiyordu — sahip o yolu okuyamaz. Paylaşılan
  /// notun ekleri notun SAHİBİNİN yoluna yazılır; storage.rules ortak
  /// çalışana tam bu yolu açar. Kota yine ekleyenin kendi kullanımıyla
  /// denetlenir (tavanı aşan dosyayı kimse başkasının deposuna bırakamasın).
  AttachmentRepository forOwner(String ownerUid) => ownerUid == uid
      ? this
      : AttachmentRepository(
          _storage,
          ownerUid,
          maxBytes,
          quotaBytes: quotaBytes,
          usedBytes: usedBytes,
          // Başkasının notu Drive'a GİTMEZ: dosya benim Drive'ımda olursa
          // sahibi ve öbür ortak çalışanlar ona erişemez.
        );

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
    //
    // Görüntülü not tavana girmez: buluta hiç yüklenmiyor (bkz. prepareVideo,
    // upload). Ayrım kaynağın türünden okunuyor ki "video kopyala" gibi yeni
    // bir yol eklendiğinde ayrıca hatırlanması gerekmesin.
    if (meta.kind != AttachmentKind.video) {
      _checkQuota(bytes.length - freedBytes);
    }
    // basename ŞART: fileName Firestore'dan geliyor (Attachment.fromMap) ve
    // prepare* yolları temizlese de duplicate() gibi yollar mevcut kaydı
    // olduğu gibi taşır. "../../x" biçimli bir ad, yazmayı uygulama
    // sandbox'ının dışına taşırdı (path traversal); tek noktada kesilir.
    final objectName = '${meta.id}_${p.basename(meta.fileName)}';
    if (!kIsWeb) {
      final dir = await _attachmentsDir(noteId);
      final file = File(p.join(dir.path, objectName));
      await file.writeAsBytes(bytes, flush: true);
      return meta.copyWith(localPath: file.path);
    }
    final storagePath = 'users/$uid/notes/$noteId/$objectName';
    final ref = _storage.ref(storagePath);
    // putFile'ın bayt karşılığı; web'de dosya tutamacı olmadığından tek yol.
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: meta.mimeType,
        cacheControl: AppConstants.attachmentCacheControl,
      ),
    );
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

    // Silme hatası (özellikle ÇEVRİMDIŞI) kırpmayı DÜŞÜRMEZ: dosya cihazda
    // dururken "attachmentFailed" veriliyordu. Silinemeyen bulut kopyası
    // sorun değil — ek "yüklenmemiş"e döndüğü için kuyruk yeni baytları aynı
    // adrese yazıp üzerine geçer (ad değiştiyse eski kopya yetim kalır; bu,
    // kullanıcının kırpamamasından iyidir). Silme _store'dan ÖNCE kalmalı:
    // sonra olsaydı kuyruk yeni baytları yükledikten hemen sonra silme
    // YENİ dosyayı götürebilirdi (yarış).
    try {
      await deleteFromStorage(attachment);
    } catch (_) {
      // Çevrimdışı ya da geçici Storage hatası — yukarıdaki nota bak.
    }
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
        driveId: '',
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
    if (!kIsWeb &&
        oldLocalPath.isNotEmpty &&
        oldLocalPath != stored.localPath) {
      try {
        await File(oldLocalPath).delete();
      } on FileSystemException {
        // Dosya zaten yoksa yapacak bir şey yok.
      }
    }
    return stored;
  }

  /// Görseli 90°'nin katlarıyla döndürüp KALICI olarak yeniden yazar
  /// (kullanıcı isteği 2026-08-16: "resim düzenlemede döndürme lazım").
  ///
  /// [cropImage] ile birebir aynı yol ve aynı gerekçeler: dosya aynı ek
  /// kimliğiyle yeniden yazılır, bulut kopyası silinip ek "yüklenmemiş"e
  /// döner, kuyruk yeni baytları gönderir. Döndürme de kalıcıdır — görsel
  /// tuvalde, tam ekranda, dışa aktarımda, OCR'de ayrı ayrı çiziliyor;
  /// "şu kadar dönük" bilgisi alan olarak saklansaydı bu yolların HEPSİ onu
  /// uygulamak zorunda kalırdı.
  ///
  /// En/boy yer değiştirdiğinde [Attachment.width]/[height] de takas edilir:
  /// tuvaldeki yerleşim ve sarma bantları bu ölçüye bakıyor.
  Future<Attachment> rotateImage({
    required String noteId,
    required Attachment attachment,
    required int quarterTurns,
  }) async {
    final bytes = await readBytes(attachment);
    if (bytes == null) throw const AttachmentMissingException();
    final result = await compute(
      _rotateImage,
      _RotateRequest(bytes, quarterTurns),
    );
    if (result.width == 0) throw const AttachmentMissingException();
    if (result.bytes.length > maxBytes) throw const FileTooLargeException();

    // Kırpmadaki sıra ve gerekçenin aynısı (bkz. cropImage): silme _store'dan
    // ÖNCE, hatası döndürmeyi düşürmez.
    try {
      await deleteFromStorage(attachment);
    } catch (_) {
      // Çevrimdışı ya da geçici Storage hatası.
    }
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
        driveId: '',
        ink: rotateInk(attachment.ink, quarterTurns),
      ),
      result.bytes,
      freedBytes: attachment.sizeBytes,
    );
    if (!kIsWeb &&
        oldLocalPath.isNotEmpty &&
        oldLocalPath != stored.localPath) {
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

  /// VAR OLAN bir belgenin baytlarını yenisiyle değiştirir (PDF düzenleme:
  /// sayfa sil/döndür/sırala, çizimi belgeye gömme).
  ///
  /// Kırpma yolunun ([cropImage]) aynısı: dosya aynı ek kimliğiyle yeniden
  /// yazılır, bulut kopyası silinip yükleme kuyruğuna geri konur. Ek kimliği
  /// KORUNUR — sayfa notlarının anahtarları ek kimliğine bağlı, değişseydi
  /// bütün notlar sahipsiz kalırdı.
  ///
  /// [pageIds] verilirse sayfa kimlik listesi de güncellenir (sayfa silme/
  /// sıralama sonrası); verilmezse (döndürme, çizim gömme) dokunulmaz.
  Future<Attachment> replaceDocumentBytes({
    required String noteId,
    required Attachment attachment,
    required Uint8List bytes,
    List<String>? pageIds,
  }) async {
    if (bytes.length > maxBytes) throw const FileTooLargeException();
    // Silme _store'dan ÖNCE: sonra olsaydı kuyruk yeni baytları yükledikten
    // hemen sonra silme YENİ dosyayı götürebilirdi (kırpmadaki aynı yarış).
    // Çevrimdışı silme hatası işlemi DÜŞÜRMEZ — dosya cihazda duruyor ve
    // kuyruk aynı adrese yeniden yazacak.
    try {
      await deleteFromStorage(attachment);
    } catch (_) {
      // Çevrimdışı ya da geçici Storage hatası — yukarıdaki nota bak.
    }
    return _store(
      noteId,
      attachment.copyWith(
        sizeBytes: bytes.length,
        storagePath: '',
        downloadUrl: '',
        driveId: '',
        pageIds: pageIds,
      ),
      bytes,
      freedBytes: attachment.sizeBytes,
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
    // Galeriden seçilen/paylaşılan videonun süresi bilinmiyorsa (0) addan
    // çıkarılır — "goruntu_0s" yanıltıcıydı.
    final fileName = duration > Duration.zero
        ? 'goruntu_${duration.inSeconds}s$ext'
        : 'goruntu$ext';
    final dir = await _attachmentsDir(noteId);
    final file = await source.copy(p.join(dir.path, '${id}_$fileName'));

    return Attachment(
      id: id,
      kind: AttachmentKind.video,
      fileName: fileName,
      mimeType: switch (ext.toLowerCase()) {
        '.mov' => 'video/quicktime',
        '.webm' => 'video/webm',
        '.mkv' => 'video/x-matroska',
        '.3gp' => 'video/3gpp',
        _ => 'video/mp4',
      },
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
    // YouTube eki dosyasızdır: kopyası yeni kimlikli aynı bağlantı.
    if (source.isWebVideo) {
      return Attachment(
        id: _uuid.v4(),
        kind: source.kind,
        fileName: source.fileName,
        mimeType: source.mimeType,
        webUrl: source.webUrl,
        width: source.width,
        height: source.height,
        displayWidth: source.displayWidth,
        align: source.align,
        asFile: source.asFile,
        createdAt: DateTime.now(),
      );
    }
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

  /// **Not paketinden** gelen eki bu cihazda kalıcı hâle getirir: baytlar
  /// yerel kopyaya yazılır, yükleme kuyruğa kalır.
  ///
  /// [meta] paketten çözülmüş ek — kimliği, adı ve DÜZEN alanları (konum,
  /// boyut, çizim, balon, sayfa kimlikleri) olduğu gibi korunur. Kimliğin
  /// korunması ŞART: sayfa notlarının anahtarı (`<ekId>#<sayfaKimliği>`) ve
  /// notun zemin görseli ek kimliğine bağlıdır; yeni bir kimlik verilseydi
  /// paketten gelen not açılırken sayfa notları ve zemini kaybolurdu.
  /// (Kimlikler UUID; iki kullanıcının aynı kimliği üretmesi söz konusu
  /// değil, üstelik depo yolu not kimliğiyle ayrışıyor.)
  Future<Attachment> importAttachment({
    required String noteId,
    required Attachment meta,
    required Uint8List bytes,
  }) async {
    var data = bytes;
    // Paketten gelen görsel başka bir uygulamadan/eski sürümden tam boyutlu
    // gelebilir; senkrona girmeden önce `prepareImage` ile aynı ölçüye
    // indirilir. Ad ve MIME KORUNUR (paketin sayfa/zemin bağları ek
    // kimliğine bağlı, dosya adına değil — ama adı değiştirmeye gerek yok):
    // yalnız JPEG ise küçültülmüş hâli alınır, PNG/GIF olduğu gibi kalır.
    if (meta.kind == AttachmentKind.image &&
        meta.mimeType == 'image/jpeg' &&
        bytes.length > 400 * 1024) {
      final result = await compute(
        _compressImage,
        _CompressRequest(bytes, AppConstants.maxImageDimension),
      );
      if (result.isJpg) data = result.bytes;
    }
    if (meta.kind != AttachmentKind.video && data.length > maxBytes) {
      throw const FileTooLargeException();
    }
    return _store(noteId, meta.copyWith(sizeBytes: data.length), data);
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
    await ref.putFile(
      file,
      SettableMetadata(
        contentType: attachment.mimeType,
        cacheControl: AppConstants.attachmentCacheControl,
      ),
    );
    final url = await ref.getDownloadURL();
    return attachment.copyWith(storagePath: storagePath, downloadUrl: url);
  }

  /// Yerel kopyası olup henüz Drive'da olmayan eki kullanıcının Google
  /// Drive'ına (uygulama klasörü) yükler; Drive kimliğiyle güncellenmiş
  /// metadata'yı döner. Drive bağlı değilse ya da dosya yoksa null.
  Future<Attachment?> uploadToDrive(
    String noteId,
    Attachment attachment,
  ) async {
    final store = drive;
    if (store == null) return null;
    if (attachment.kind == AttachmentKind.video) return null;
    if (attachment.isInDrive || attachment.localPath.isEmpty) return null;
    final file = File(attachment.localPath);
    if (!await file.exists()) return null;
    final id = await store.upload(
      file,
      name: driveFileName(
        noteId: noteId,
        attachmentId: attachment.id,
        fileName: p.basename(attachment.fileName),
      ),
      mimeType: attachment.mimeType.isEmpty
          ? 'application/octet-stream'
          : attachment.mimeType,
    );
    return attachment.copyWith(driveId: id);
  }

  /// Drive'daki eki bu cihazın yerel kopyasına indirir (yoksa). İndirildiyse
  /// true; Drive yoksa/ek Drive'da değilse false.
  Future<bool> fetchFromDrive(Attachment attachment) async {
    final store = drive;
    if (store == null || !attachment.isInDrive) return false;
    if (attachment.localPath.isEmpty) return false;
    final target = File(attachment.localPath);
    if (await target.exists()) return false;
    await store.download(attachment.driveId, target);
    return true;
  }

  Future<void> deleteFromStorage(Attachment attachment) async {
    // Drive kopyası da gider (bağlı değilse dosya Drive'da kalır — yalnız
    // yer kaplar, veri riski yok).
    if (attachment.isInDrive) {
      final store = drive;
      if (store != null) await store.delete(attachment.driveId);
    }
    if (attachment.storagePath.isEmpty) return;
    try {
      await _storage.ref(attachment.storagePath).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// PDF baytlarını getirir: önce yerel kopya, yoksa Drive'dan (bağlıysa
  /// indirip yerel kopyaya da yazarak), o da yoksa Storage'dan.
  Future<Uint8List?> readBytes(Attachment attachment) async {
    if (attachment.localPath.isNotEmpty) {
      final file = File(attachment.localPath);
      if (await file.exists()) return file.readAsBytes();
    }
    if (attachment.isInDrive && drive != null) {
      if (!kIsWeb && attachment.localPath.isNotEmpty) {
        await fetchFromDrive(attachment);
        final file = File(attachment.localPath);
        if (await file.exists()) return file.readAsBytes();
      }
      return drive!.downloadBytes(attachment.driveId);
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
