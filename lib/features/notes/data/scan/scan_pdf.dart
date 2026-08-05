import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../note_pdf.dart' show NotePdf;
import 'scan_ocr.dart';

/// Taranan sayfa görsellerini **tek PDF**te toplar — gerçek bir tarayıcı gibi
/// her sayfa A4, görsel oranı korunarak ortalanır (kırpılmaz, esnetilmez).
///
/// (dosya-okuyucu projesindeki `ConversionService.imagesToPdf`ten uyarlandı.)
///
/// [ocrLinesPerPage] verilirse i. listedeki satırlar i. sayfaya **görünmez
/// metin** olarak yazılır → PDF içinde arama/kopyalama çalışır ("aranabilir
/// PDF"). Görünmezlik PDF'in kendi "metin çizim kipi 3"üyle
/// ([PdfTextRenderingMode.invisible]) sağlanır — saydam RENK İŞE YARAMAZ:
/// `pdf` paketi doldurma renginde alfa kanalını yazmıyor, metin simsiyah
/// basılıyordu (dosya-okuyucu, 2026-07-31 kök nedeni). Her satır kendi
/// kutusuna sıkıştırılır (FittedBox) ve katman resim dikdörtgeniyle kırpılır
/// — taşma fiziksel olarak imkânsız.
///
/// Üretim compute() izolesinde koşar (sayfa başına MB'larca görsel kodlama);
/// font baytları ANA izolede yüklenir (rootBundle izolede yok — bkz. NotePdf).
abstract final class ScanPdf {
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
    final font = r.fontBytes == null ? null : pw.Font.ttf(r.fontBytes!);
    final doc = pw.Document();
    for (var i = 0; i < r.imagePaths.length; i++) {
      final bytes = await File(r.imagePaths[i]).readAsBytes();
      final image = pw.MemoryImage(bytes);
      final imgWidth = image.width;
      final imgHeight = image.height;
      if (imgWidth == null || imgHeight == null || imgWidth == 0) {
        throw const FormatException('Bu görsel biçimi çözülemedi.');
      }

      // Sabit kâğıt (A4): arka arkaya çekilen sayfalar birkaç piksel farklı
      // olduğu için sayfa oranı görselden alınsaydı PDF'te sayfa boyu sayfa
      // sayfa oynardı. Yatay görselde kâğıt yatay çevrilir.
      final landscape = imgWidth > imgHeight;
      final pageWidth = landscape ? PdfPageFormat.a4.height : PdfPageFormat.a4.width;
      final pageHeight = landscape ? PdfPageFormat.a4.width : PdfPageFormat.a4.height;
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

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pageWidth, pageHeight),
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            fit: pw.StackFit.expand,
            children: [
              pw.Positioned(
                left: offsetX,
                top: offsetY,
                child: pw.SizedBox(
                  width: drawWidth,
                  height: drawHeight,
                  child: pw.Image(image, fit: pw.BoxFit.fill),
                ),
              ),
              if (ocrLines.isNotEmpty)
                pw.Positioned(
                  left: offsetX,
                  top: offsetY,
                  child: pw.SizedBox(
                    width: drawWidth,
                    height: drawHeight,
                    child: pw.ClipRect(
                      child: pw.Stack(
                        children: [
                          for (final line in ocrLines)
                            pw.Positioned(
                              left: line.left * scale,
                              top: line.top * scale,
                              child: pw.SizedBox(
                                width: (line.width * scale).clamp(
                                  1.0,
                                  drawWidth,
                                ),
                                height: (line.height * scale).clamp(
                                  1.0,
                                  drawHeight,
                                ),
                                child: pw.FittedBox(
                                  fit: pw.BoxFit.fill,
                                  child: pw.Text(
                                    line.text,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 12,
                                      renderingMode:
                                          PdfTextRenderingMode.invisible,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return doc.save();
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
