import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../../../core/error_log.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/search_fold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/data/scan/scan_ocr.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../../settings/settings_providers.dart';

/// **EKLERİN İÇİNDEKİ METİN** — kullanıcı isteği 2026-09-04: "anlamsal arama
/// görsel ve pdf'leri de arayabilir, seçenek olarak sunmalıyız".
///
/// Arama bugüne dek yalnız notun YAZISINI görüyordu; taranmış bir faturanın
/// ya da eklenen bir PDF'in içindeki sözcükler hiçbir aramaya girmiyordu.
///
/// **Neden SEÇENEK ve neden varsayılan KAPALI:** metni çıkarmak ucuz değil —
/// PDF ayrıştırılıyor, görsel cihaz-içi OCR'dan geçiyor. Her açılışta bütün
/// ekleri taramak pili ve zamanı yakar. Açan kullanıcı bir kerelik bir
/// tarama bedeli ödüyor, sonrası önbellekten (ek kimliği → metin, hesaba
/// özgü dosyada kalıcı — bkz. [AttachmentTextIndex._cacheFile]).
///
/// **Sınırlar (bilinçli):**
///  * Yalnız CİHAZDA DURAN dosyalar okunur. Bulut kopyasını indirmek arama
///    için kabul edilemez bir maliyet; senkronlanan cihazda dosya zaten var.
///  * OCR yalnız Android/iOS'ta (ML Kit — bkz. [ScanOcr.supported]).
///  * Her turda en çok [_batch] ek işlenir: uzun bir defterde arama kutusu
///    donmasın, indeks tur tur dolsun.
final attachmentSearchProvider = boolPref('attachment_search', defaultValue: false);

/// noteId → o notun eklerinden çıkarılmış metin. Seçenek kapalıyken BOŞ:
/// kapalı bir seçeneğin bellekte indeks tutması yanlış olurdu.
final attachmentTextProvider =
    NotifierProvider<AttachmentTextIndex, Map<String, String>>(
      AttachmentTextIndex.new,
    );

/// [attachmentTextProvider]'ın aramaya hazır, KATLANMIŞ ([foldForSearch])
/// hâli (F6.3): süzgeç her hesapta her notun ek metnini yeniden
/// katlıyordu; bu yalnız indeks değişince kurulur.
final attachmentFoldedTextProvider = Provider<Map<String, String>>((ref) {
  final texts = ref.watch(attachmentTextProvider);
  if (texts.isEmpty) return const {};
  return {for (final e in texts.entries) e.key: foldForSearch(e.value)};
});

class AttachmentTextIndex extends Notifier<Map<String, String>> {
  /// Bir turda işlenecek en çok ek sayısı.
  static const int _batch = 8;

  /// Tek ekten alınacak en çok karakter: vektör de arama da sulanmasın.
  static const int maxCharsPerFile = 4000;

  /// ESKİ önbellek: SharedPreferences'ta tek JSON (F6.3'e dek). Her 8 ekte
  /// bir bütün harita yeniden yazılıyordu ve SharedPreferences açılışta
  /// TAMAMEN belleğe yüklendiği için her açılışta MB'larca metin okunuyordu.
  /// Bir kez dosyaya taşınıp silinir.
  static const legacyCacheKey = 'attachment_text_v1';

  /// Testler gerçek uygulama klasörüne yazmasın diye.
  @visibleForTesting
  static String? overrideDir;

  /// ek kimliği → metin (kalıcı önbellek; dosya değişmediği sürece geçerli).
  final _texts = <String, String>{};

  bool _running = false;

  /// Önbelleğin yüklendiği hesap; değişince bellekteki metin bırakılır.
  String? _uid;
  Future<void>? _loading;

  @override
  Map<String, String> build() {
    if (!ref.watch(attachmentSearchProvider)) return const {};
    final uid = ref.watch(currentUidProvider);
    final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
    if (uid != _uid) {
      _uid = uid;
      _texts.clear();
      _loading = uid == null ? null : _loadCache(uid);
    }
    final loading = _loading;
    if (loading != null) {
      unawaited(loading.then((_) => _index(notes)));
    }
    final next = _byNote(notes);
    // İçerik aynıysa ÖNCEKİ harita: her not yayınında yeni harita, süzgeci
    // ve katlanmış kopyayı boşuna yeniden kurdururdu (F6.3).
    final previous = stateOrNull;
    if (previous != null && mapEquals(previous, next)) return previous;
    return next;
  }

  /// Hesaba özgü önbellek dosyası; web'de (dosya sistemi yok) null.
  File? _cacheFile(String uid) {
    final base = overrideDir ?? appSupportPath;
    if (kIsWeb || base == null) return null;
    return File('$base/attachment_text_$uid.json');
  }

  Future<void> _loadCache(String uid) async {
    final file = _cacheFile(uid);
    final prefs = ref.read(sharedPreferencesProvider);
    String? raw;
    try {
      if (file != null && await file.exists()) raw = await file.readAsString();
    } catch (e) {
      ErrorLog.record('attachment-text-cache', e);
    }
    final legacy = prefs.getString(legacyCacheKey);
    raw ??= legacy;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && uid == _uid) {
          for (final entry in decoded.entries) {
            _texts[entry.key.toString()] = entry.value.toString();
          }
        }
      } catch (_) {
        // Bozuk önbellek aramayı kilitlemesin: sıfırdan taranır.
      }
    }
    if (legacy != null) {
      if (file != null) await _saveCache(uid);
      await prefs.remove(legacyCacheKey);
    }
  }

  Future<void> _saveCache(String uid) async {
    final file = _cacheFile(uid);
    if (file == null || uid != _uid) return;
    try {
      final tmp = File('${file.path}.tmp');
      await tmp.parent.create(recursive: true);
      await tmp.writeAsString(jsonEncode(_texts), flush: true);
      await tmp.rename(file.path);
    } catch (_) {
      // Disk dolu vb.: sonraki turda yeniden denenir.
    }
  }

  Map<String, String> _byNote(List<Note> notes) {
    final out = <String, String>{};
    for (final note in notes) {
      final buffer = StringBuffer();
      for (final attachment in note.attachments) {
        final text = _texts[attachment.id];
        if (text == null || text.isEmpty) continue;
        buffer
          ..write(text)
          ..write('\n');
      }
      if (buffer.isNotEmpty) out[note.id] = buffer.toString();
    }
    return out;
  }

  /// Sırası gelmemiş ekleri tur tur işler; her turda durum yenilenir ki
  /// arama sonuçları indeks doldukça zenginleşsin.
  Future<void> _index(List<Note> notes) async {
    if (_running) return;
    final uid = _uid;
    if (uid == null) return;
    _running = true;
    try {
      final pending = <({String noteId, Attachment file})>[];
      final live = <String>{};
      for (final note in notes) {
        for (final attachment in note.attachments) {
          live.add(attachment.id);
          if (_texts.containsKey(attachment.id)) continue;
          if (!_readable(attachment)) continue;
          pending.add((noteId: note.id, file: attachment));
        }
      }
      // Silinen eklerin metni önbellekte kalmasın (F6.3). Liste boşken
      // (akış henüz gelmedi) budanmaz.
      final before = _texts.length;
      if (notes.isNotEmpty) _texts.removeWhere((id, _) => !live.contains(id));
      if (pending.isEmpty) {
        if (_texts.length != before) await _saveCache(uid);
        return;
      }
      // Tur tur ilerler: her turdan sonra durum yenilenir ki arama sonuçları
      // indeks doldukça zenginleşsin, kullanıcı bütün defterin taranmasını
      // beklemesin.
      for (var i = 0; i < pending.length; i += _batch) {
        final slice = pending.skip(i).take(_batch);
        for (final entry in slice) {
          if (uid != _uid) return;
          // Sonuç BOŞ da olsa yazılır: "bu ekte metin yok" da bir yanıt,
          // yoksa aynı dosya her turda yeniden taranırdı.
          _texts[entry.file.id] = await _extract(entry.file);
        }
        if (uid != _uid) return;
        state = _byNote(notes);
      }
      // Tur sonunda BİR kez (eskiden her 8 ekte bir — ilk taramada karesel).
      await _saveCache(uid);
    } catch (e) {
      debugPrint('Ek metni çıkarılamadı: $e');
    } finally {
      _running = false;
    }
  }

  /// Bu ekten metin çıkarılabilir mi: dosya CİHAZDA mı ve türü uygun mu.
  static bool _readable(Attachment attachment) {
    if (attachment.localPath.isEmpty) return false;
    if (!localFileExists(attachment.localPath)) return false;
    return switch (attachment.kind) {
      AttachmentKind.pdf => true,
      AttachmentKind.image => ScanOcr.supported,
      // Metin eki aramaya DOĞRUDAN girer (bkz. notes_providers
      // `_searchableBody`) — çıkarılacak bir şey yok.
      AttachmentKind.audio ||
      AttachmentKind.video ||
      AttachmentKind.slide ||
      AttachmentKind.text ||
      AttachmentKind.unknown => false,
    };
  }

  static Future<String> _extract(Attachment attachment) async {
    try {
      final text = switch (attachment.kind) {
        // AYRI İZOLEDE (F6.3): Syncfusion ayrıştırması büyük PDF'te saniyeler
        // sürüyor, ana izolede arayüz donuyordu. Dosya da orada okunur —
        // baytlar izoleler arasında kopyalanmasın.
        AttachmentKind.pdf => await compute(
          _extractPdfFile,
          attachment.localPath,
        ),
        AttachmentKind.image => await _ocr(attachment.localPath),
        _ => '',
      };
      return text.length > maxCharsPerFile
          ? text.substring(0, maxCharsPerFile)
          : text;
    } catch (e) {
      // Bozuk/şifreli dosya aramayı düşürmez; o ek metinsiz kalır.
      debugPrint('Ek okunamadı (${attachment.fileName}): $e');
      return '';
    }
  }

  static Future<String> _ocr(String path) async {
    final lines = await ScanOcr.recognizeImageLines(path);
    return [for (final line in lines) line.text].join('\n');
  }

  /// PDF'in metin katmanı. Saf Dart (Syncfusion) — platform kanalı yok, bu
  /// yüzden masaüstünde ve testte de çalışır. Taranmış (metin katmanı
  /// olmayan) PDF boş döner; onun metni tarama sırasında zaten görünmez
  /// katman olarak gömülüyor (bkz. scan_ocr.dart).
  static String _extractPdfFile(String path) =>
      extractPdfText(File(path).readAsBytesSync());

  @visibleForTesting
  static String extractPdfText(Uint8List bytes) {
    sf.PdfDocument? document;
    try {
      document = sf.PdfDocument(inputBytes: bytes);
      return sf.PdfTextExtractor(document).extractText();
    } catch (_) {
      return '';
    } finally {
      document?.dispose();
    }
  }
}
