import 'dart:io';
import 'dart:math' as math;

import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../domain/attachment.dart' show PageBubbleRect;
import '../note_pdf.dart' show NotePdf;
import 'scan_ocr.dart';

/// Taranan sayfa görsellerini **tek PDF**te toplar — gerçek bir tarayıcı gibi
/// her sayfa A4, görsel oranı korunarak ortalanır (kırpılmaz, esnetilmez).
///
/// (dosya-okuyucu projesindeki `ConversionService.imagesToPdf`ten uyarlandı.)
///
/// [ocrLinesPerPage] verilirse i. listedeki satırlar i. sayfaya **görünmez
/// metin** olarak yazılır → PDF içinde arama/kopyalama çalışır ("aranabilir
/// PDF"). Görünmezlik grafik durumunun SAYDAMLIĞIYLA (`ca 0`) sağlanır:
/// metin seçilebilir/aranabilir ama çizilmez. Her satır kendi kutusuna
/// yatay ölçekle sıkıştırılır ve katman resim dikdörtgeniyle kırpılır.
///
/// Üretim compute() izolesinde koşar (sayfa başına MB'larca görsel kodlama);
/// font baytları ANA izolede yüklenir (rootBundle izolede yok — bkz. NotePdf).
abstract final class ScanPdf {
  static const _a4 = Size(595.28, 841.89);

  /// [imgWidth]×[imgHeight] görselin [build] sayfasında KAPLADIĞI alan,
  /// sayfanın oranı (0–1) olarak — yerleşim [_buildInIsolate]'teki ile
  /// birebir (A4, yatay görselde yatay kâğıt, ortalanmış "contain").
  /// Görselin üstündeki çizim/balonlar belgeye bununla taşınır
  /// (bkz. `placeInk`).
  static PageBubbleRect imageFrameOnPage(num imgWidth, num imgHeight) {
    if (imgWidth <= 0 || imgHeight <= 0) {
      return const PageBubbleRect(0, 0, 1, 1);
    }
    final landscape = imgWidth > imgHeight;
    final pageWidth = landscape ? _a4.height : _a4.width;
    final pageHeight = landscape ? _a4.width : _a4.height;
    final sx = pageWidth / imgWidth;
    final sy = pageHeight / imgHeight;
    final scale = sx < sy ? sx : sy;
    final w = imgWidth * scale / pageWidth;
    final h = imgHeight * scale / pageHeight;
    final left = (1 - w) / 2;
    final top = (1 - h) / 2;
    return PageBubbleRect(left, top, left + w, top + h);
  }

  static Future<Uint8List> build(
    List<String> imagePaths, {
    List<List<OcrLine>> ocrLinesPerPage = const [],
  }) async {
    if (imagePaths.isEmpty) {
      throw ArgumentError('PDF için en az bir görsel gerekli');
    }
    // Görünmez katman Türkçe karakter içerebilir → gömülü PT Sans (varsayılan
    // Helvetica'da ğ/ş/ı yok, pdf paketi hata atar). Katman yoksa font da yok.
    final hasOcr = ocrLinesPerPage.any((lines) => lines.isNotEmpty);
    final font = hasOcr ? await rootBundle.load(NotePdf.fontAsset) : null;
    return compute(
      _buildInIsolate,
      _ScanPdfRequest(
        imagePaths: imagePaths,
        ocrLinesPerPage: [
          for (final lines in ocrLinesPerPage)
            [
              for (final l in lines)
                _OcrLineData(
                  l.text,
                  l.box.left,
                  l.box.top,
                  l.box.width,
                  l.box.height,
                ),
            ],
        ],
        fontBytes: font,
      ),
    );
  }

  static Future<Uint8List> _buildInIsolate(_ScanPdfRequest r) async {
    final fontData = r.fontBytes?.buffer.asUint8List(
      r.fontBytes!.offsetInBytes,
      r.fontBytes!.lengthInBytes,
    );
    // Satır kutusuna göre punto; aynı punto tek yazı tipi örneğini paylaşır
    // (her örnek belgeye ayrı gömülürdü).
    final fonts = <double, PdfFont>{};
    PdfFont fontOf(double size) =>
        fonts[size] ??= PdfTrueTypeFont(fontData!, size);
    final doc = PdfDocument();
    doc.pageSettings.margins.all = 0;
    for (var i = 0; i < r.imagePaths.length; i++) {
      final bytes = await File(r.imagePaths[i]).readAsBytes();
      PdfBitmap bitmap;
      try {
        bitmap = PdfBitmap(bytes);
      } catch (_) {
        // PdfBitmap yalnız JPEG/PNG okur; diğerleri PNG'ye çevrilir.
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          throw const FormatException('Bu görsel biçimi çözülemedi.');
        }
        bitmap = PdfBitmap(img.encodePng(decoded));
      }
      final imgWidth = bitmap.width;
      final imgHeight = bitmap.height;
      if (imgWidth == 0 || imgHeight == 0) {
        throw const FormatException('Bu görsel biçimi çözülemedi.');
      }

      // Sabit kâğıt (A4): arka arkaya çekilen sayfalar birkaç piksel farklı
      // olduğu için sayfa oranı görselden alınsaydı PDF'te sayfa boyu sayfa
      // sayfa oynardı. Yatay görselde kâğıt yatay çevrilir.
      final landscape = imgWidth > imgHeight;
      final pageWidth = landscape ? _a4.height : _a4.width;
      final pageHeight = landscape ? _a4.width : _a4.height;
      final sx = pageWidth / imgWidth;
      final sy = pageHeight / imgHeight;
      final scale = sx < sy ? sx : sy; // contain: kırpma yok, esnetme yok
      final offsetX = (pageWidth - imgWidth * scale) / 2;
      final offsetY = (pageHeight - imgHeight * scale) / 2;
      final drawWidth = imgWidth * scale;
      final drawHeight = imgHeight * scale;
      final ocrLines = i < r.ocrLinesPerPage.length
          ? r.ocrLinesPerPage[i]
          : const <_OcrLineData>[];

      final section = doc.sections!.add();
      section.pageSettings.size = Size(pageWidth, pageHeight);
      section.pageSettings.margins.all = 0;
      final g = section.pages.add().graphics;
      final frame = Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);
      g.drawImage(bitmap, frame);
      if (fontData != null && ocrLines.isNotEmpty) {
        g.save();
        g.setClip(bounds: frame);
        g.setTransparency(0);
        final probe = fontOf(12);
        for (final line in ocrLines) {
          final w = (line.width * scale).clamp(1.0, drawWidth);
          final h = (line.height * scale).clamp(1.0, drawHeight);
          final natural = probe.measureString(line.text);
          if (natural.width <= 0 || natural.height <= 0) continue;
          final fit = 12 * math.min(w / natural.width, h / natural.height);
          final size = math.max(1.0, (fit * 2).floorToDouble() / 2);
          g.drawString(
            line.text,
            fontOf(size),
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: Rect.fromLTWH(
              offsetX + line.left * scale,
              offsetY + line.top * scale,
              w + 1,
              h + 1,
            ),
            format: PdfStringFormat(wordWrap: PdfWordWrapType.none),
          );
        }
        g.restore();
      }
    }
    final out = Uint8List.fromList(doc.saveSync());
    doc.dispose();
    return out;
  }
}

/// İzoleye taşınan istek — ui.Rect yerine düz sayılar (her alan sendable).
class _ScanPdfRequest {
  const _ScanPdfRequest({
    required this.imagePaths,
    required this.ocrLinesPerPage,
    required this.fontBytes,
  });

  final List<String> imagePaths;
  final List<List<_OcrLineData>> ocrLinesPerPage;
  final ByteData? fontBytes;
}

class _OcrLineData {
  const _OcrLineData(this.text, this.left, this.top, this.width, this.height);

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;
}
