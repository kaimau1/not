import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../../../core/utils/local_file.dart';
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
/// tarama bedeli ödüyor, sonrası önbellekten (ek kimliği → metin,
/// SharedPreferences'ta kalıcı).
///
/// **Sınırlar (bilinçli):**
///  * Yalnız CİHAZDA DURAN dosyalar okunur. Bulut kopyasını indirmek arama
///    için kabul edilemez bir maliyet; senkronlanan cihazda dosya zaten var.
///  * OCR yalnız Android/iOS'ta (ML Kit — bkz. [ScanOcr.supported]).
///  * Her turda en çok [_batch] ek işlenir: uzun bir defterde arama kutusu
///    donmasın, indeks tur tur dolsun.
final attachmentSearchProvider =
    NotifierProvider<AttachmentSearchNotifier, bool>(
      AttachmentSearchNotifier.new,
    );

class AttachmentSearchNotifier extends Notifier<bool> {
  static const _key = 'attachment_search';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// noteId → o notun eklerinden çıkarılmış metin. Seçenek kapalıyken BOŞ:
/// kapalı bir seçeneğin bellekte indeks tutması yanlış olurdu.
final attachmentTextProvider =
    NotifierProvider<AttachmentTextIndex, Map<String, String>>(
      AttachmentTextIndex.new,
    );

class AttachmentTextIndex extends Notifier<Map<String, String>> {
  /// Bir turda işlenecek en çok ek sayısı.
  static const int _batch = 8;

  /// Tek ekten alınacak en çok karakter: vektör de arama da sulanmasın.
  static const int maxCharsPerFile = 4000;

  static const _cacheKey = 'attachment_text_v1';

  /// ek kimliği → metin (kalıcı önbellek; dosya değişmediği sürece geçerli).
  final _texts = <String, String>{};

  bool _running = false;

  @override
  Map<String, String> build() {
    if (!ref.watch(attachmentSearchProvider)) return const {};
    final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
    _loadCache();
    scheduleMicrotask(() => unawaited(_index(notes)));
    return _byNote(notes);
  }

  bool _cacheLoaded = false;

  void _loadCache() {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    final raw = ref.read(sharedPreferencesProvider).getString(_cacheKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        _texts[entry.key.toString()] = entry.value.toString();
      }
    } catch (_) {
      // Bozuk önbellek aramayı kilitlemesin: sıfırdan taranır.
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
    _running = true;
    try {
      final pending = <({String noteId, Attachment file})>[];
      for (final note in notes) {
        for (final attachment in note.attachments) {
          if (_texts.containsKey(attachment.id)) continue;
          if (!_readable(attachment)) continue;
          pending.add((noteId: note.id, file: attachment));
        }
      }
      if (pending.isEmpty) return;
      var changed = false;
      for (final entry in pending.take(_batch)) {
        // Sonuç BOŞ da olsa yazılır: "bu ekte metin yok" da bir yanıt,
        // yoksa aynı dosya her turda yeniden taranırdı.
        _texts[entry.file.id] = await _extract(entry.file);
        changed = true;
      }
      if (!changed) return;
      unawaited(
        ref
            .read(sharedPreferencesProvider)
            .setString(_cacheKey, jsonEncode(_texts)),
      );
      state = _byNote(notes);
      // Kuyrukta kalan varsa bir sonraki tur: kullanıcı beklemesin, indeks
      // arka planda dolsun.
      if (pending.length > _batch) {
        _running = false;
        unawaited(_index(notes));
        return;
      }
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
      AttachmentKind.audio ||
      AttachmentKind.video ||
      AttachmentKind.slide => false,
    };
  }

  static Future<String> _extract(Attachment attachment) async {
    try {
      final bytes = await File(attachment.localPath).readAsBytes();
      final text = switch (attachment.kind) {
        AttachmentKind.pdf => extractPdfText(bytes),
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
