import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

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
        final rendered = await renderPageToPng(page);
        if (rendered != null) {
          try {
            final lines = await ScanOcr.recognizeImageWordLines(rendered.path);
            result = buildOcrPageText(
              pageNumber: page.pageNumber,
              pageHeight: page.height,
              imageScale: rendered.scale,
              lines: lines,
            );
          } finally {
            try {
              File(rendered.path).deleteSync();
            } catch (_) {}
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
      backgroundColor: const ui.Color(0xFFFFFFFF),
    );
    if (img == null) return null;
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        img.pixels,
        img.width,
        img.height,
        img.format,
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
