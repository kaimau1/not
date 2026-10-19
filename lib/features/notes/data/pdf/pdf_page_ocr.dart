import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../scan/scan_ocr.dart';
import 'ocr_page_text.dart';

/// Taranmış (metin katmanı olmayan) PDF sayfası için OCR'dan **seçilebilir**
/// metin üretir: sayfa bitmap'e çizilir → ML Kit sözcük kutuları →
/// [buildOcrPageText] ile pdfrx metniyle aynı arayüzü giyen sahte sayfa metni.
///
/// Seçim katmanı (`PdfSelectLayer`) bunu pdfium metniyle birebir aynı yoldan
/// kullanır; kullanıcı için yazılmış/taranmış farkı yoktur.
///
/// Gizlilik: OCR tamamen cihaz içinde (ML Kit yerel modeli) koşar, buluta hiç
/// veri gitmez ve AI kotası harcamaz. Tanınan metin yalnız bellekte tutulur;
/// diske sayfa görüntüsünden başka bir şey yazılmaz, o da iş biter bitmez
/// silinir.
class PdfPageOcr {
  const PdfPageOcr._();

  /// Test kancası: bütün boru hattının (çiz → ML Kit → kur) yerine geçer.
  /// Testler Linux'ta koşar; orada ne ML Kit ne de pdfium bitmap çizimi var.
  static Future<OcrPageText?> Function(PdfPage page)? debugOcrOverride;

  /// OCR bu platformda çalışır mı? (ML Kit modeli mobil APK ile gelir;
  /// masaüstünde taranmış sayfa seçimi — şimdilik — yok.)
  static bool get isSupported => debugOcrOverride != null || ScanOcr.supported;

  /// Sayfa başına sonuç önbelleği (null = denendi, sayfada metin yok — yeniden
  /// denemek pil yakar). Anahtar belge kaynağı + sayfa numarası.
  static final _cache = <String, OcrPageText?>{};
  static final _inFlight = <String, Future<OcrPageText?>>{};

  /// Bellekte tutulan en çok sayfa sayısı: uzun bir belgede sayfa sayfa
  /// gezilirken kutular sınırsız birikmesin.
  static const _cacheCap = 24;

  static String _key(PdfPage page) =>
      '${page.document.sourceName}#${page.pageNumber}';

  /// [page] için OCR metni. Aynı sayfa için eşzamanlı ikinci çağrı ilk işi
  /// bekler; sonuç (boş olsa da) önbelleğe girer.
  static Future<OcrPageText?> forPage(PdfPage page) {
    if (!isSupported) return Future.value(null);
    final key = _key(page);
    if (_cache.containsKey(key)) {
      // LRU tazele: sonda duran en taze olandır.
      final value = _cache.remove(key);
      _cache[key] = value;
      return Future.value(value);
    }
    return _inFlight[key] ??= _run(
      page,
      key,
    ).whenComplete(() => _inFlight.remove(key));
  }

  static Future<OcrPageText?> _run(PdfPage page, String key) async {
    OcrPageText? result;
    try {
      final override = debugOcrOverride;
      if (override != null) {
        result = await override(page);
      } else {
        // ÖNCE DİSK (kullanıcı bulgusu 2026-10-16: "metin tanıma her
        // seferinde baştan yapılıyor"): sonuç yalnız bellekteydi — uygulama
        // her açılışta (ve 24 sayfayı aşan belgede geri dönünce) aynı sayfayı
        // 1600 px'te yeniden çizip ML Kit'e veriyordu; hem bekletiyor hem
        // kaydırmayı ağırlaştırıyordu.
        final disk = await _readDisk(page);
        if (disk != null) {
          result = disk.text;
        } else {
          final rendered = await renderPageToPng(page);
          if (rendered != null) {
            try {
              final lines = await ScanOcr.recognizeImageWordLines(
                rendered.path,
              );
              result = buildOcrPageText(
                pageNumber: page.pageNumber,
                pageHeight: page.height,
                imageScale: rendered.scale,
                lines: lines,
              );
              unawaited(_writeDisk(page, rendered.scale, lines));
            } finally {
              try {
                File(rendered.path).deleteSync();
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {
      // OCR başarısızlığı seçimi değil yalnız TARANMIŞ sayfa desteğini düşürür;
      // sessizce "metin yok" say (önbelleğe de öyle yaz — tekrar deneme yok).
    }
    _cache[key] = result;
    if (_cache.length > _cacheCap) _cache.remove(_cache.keys.first);
    return result;
  }

  // ── Kalıcı önbellek ──────────────────────────────────────────────────────
  //
  // Sayfa başına küçük bir JSON: sözcük kutuları (görüntü pikseli) + çizim
  // ölçeği. Anahtar belgenin kaynağı + yerel dosyanın BOYU ve DEĞİŞME ZAMANI
  // + sayfa numarası/ölçüsü: dosya yeniden yazılınca (sayfa düzenle,
  // döndür, kırp) eski sonuç kendiliğinden geçersiz olur. Yalnız tanınan
  // sözcükler yazılır (sayfa görüntüsü değil) ve uygulamanın kendi
  // klasöründe kalır.

  static Directory? _dir;

  @visibleForTesting
  static Directory? debugDiskDir;

  static Future<Directory?> _diskDir() async {
    if (debugDiskDir != null) return debugDiskDir;
    if (_dir != null) return _dir;
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/pdf_ocr');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return _dir = dir;
    } catch (_) {
      return null;
    }
  }

  /// Kalıcı önbelleğin dosya adı (kaynağı tanımlayan her şeyin özeti).
  @visibleForTesting
  static String diskName({
    required String source,
    required String stamp,
    required int pageNumber,
    required double width,
    required double height,
  }) {
    final raw =
        'v1|$source|$stamp|$pageNumber|'
        '${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)}';
    return '${sha1.convert(utf8.encode(raw))}.json';
  }

  static Future<File?> _diskFile(PdfPage page) async {
    final dir = await _diskDir();
    if (dir == null) return null;
    final source = page.document.sourceName;
    var stamp = '';
    try {
      final file = File(source);
      if (file.existsSync()) {
        final stat = file.statSync();
        stamp = '${stat.size}_${stat.modified.millisecondsSinceEpoch}';
      }
    } catch (_) {}
    return File(
      '${dir.path}/${diskName(source: source, stamp: stamp, pageNumber: page.pageNumber, width: page.width, height: page.height)}',
    );
  }

  static Future<({OcrPageText? text})?> _readDisk(PdfPage page) async {
    try {
      final file = await _diskFile(page);
      if (file == null || !file.existsSync()) return null;
      final data = jsonDecode(await file.readAsString());
      if (data is! Map) return null;
      final lines = decodeWordLines(data['lines']);
      final scale = (data['scale'] as num?)?.toDouble() ?? 0;
      return (
        text: buildOcrPageText(
          pageNumber: page.pageNumber,
          pageHeight: page.height,
          imageScale: scale,
          lines: lines,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeDisk(
    PdfPage page,
    double scale,
    List<List<OcrWordBox>> lines,
  ) async {
    try {
      final file = await _diskFile(page);
      if (file == null) return;
      await file.writeAsString(
        jsonEncode({'scale': scale, 'lines': encodeWordLines(lines)}),
      );
    } catch (_) {}
  }

  /// Sözcük satırlarının JSON'u: `[[["metin", sol, üst, sağ, alt], …], …]`.
  @visibleForTesting
  static List<List<List<Object>>> encodeWordLines(
    List<List<OcrWordBox>> lines,
  ) => [
    for (final line in lines)
      [
        for (final w in line)
          [w.text, w.box.left, w.box.top, w.box.right, w.box.bottom],
      ],
  ];

  @visibleForTesting
  static List<List<OcrWordBox>> decodeWordLines(Object? raw) => [
    if (raw is List)
      for (final line in raw)
        if (line is List)
          [
            for (final w in line)
              if (w is List && w.length >= 5)
                OcrWordBox(
                  w[0].toString(),
                  ui.Rect.fromLTRB(
                    (w[1] as num).toDouble(),
                    (w[2] as num).toDouble(),
                    (w[3] as num).toDouble(),
                    (w[4] as num).toDouble(),
                  ),
                ),
          ],
  ];

  /// Sayfayı ~1600 px genişlikte geçici bir PNG'ye çizer (OCR için yeterli
  /// çözünürlük). `scale` = görüntü pikseli / PDF punto oranı — OCR kutularını
  /// sayfa koordinatına geri çevirmek için gerekir.
  static Future<({String path, double scale})?> renderPageToPng(
    PdfPage page,
  ) async {
    final scale = (1600 / page.width).clamp(1.0, 4.0);
    final img = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: 0xFFFFFFFF,
    );
    if (img == null) return null;
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        img.pixels,
        img.width,
        img.height,
        ui.PixelFormat.bgra8888,
        completer.complete,
      );
      final uiImage = await completer.future;
      final png = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      uiImage.dispose();
      if (png == null) return null;
      final file = File(
        '${Directory.systemTemp.path}/pdf_sel_ocr_${page.pageNumber}.png',
      );
      await file.writeAsBytes(png.buffer.asUint8List());
      return (path: file.path, scale: scale.toDouble());
    } finally {
      img.dispose();
    }
  }

  /// Testler arası sızıntı olmasın diye.
  static void debugReset() {
    _cache.clear();
    _inFlight.clear();
    debugOcrOverride = null;
  }
}
