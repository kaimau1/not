import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Cihaz-içi OCR (Google ML Kit, Latin alfabesi — Türkçe karakterler dahil).
///
/// (dosya-okuyucu projesindeki `OcrService`ten uyarlandı.) İnternet gerekmez;
/// model APK ile gelir ve **AI kotası harcamaz** — taranan belgeye görünmez
/// metin katmanı (aranabilir PDF) ve akıllı belge adı bunun üstüne kurulur.
/// Notun gövdesine "Metni al" akışı ise Gemini'de kalır: el yazısı ve düzeni
/// bozuk sayfalarda model belirgin daha iyi.
class ScanOcr {
  const ScanOcr._();

  /// ML Kit yalnız Android/iOS'ta var; masaüstünde aranabilir katman ve
  /// akıllı ad sessizce atlanır (tarama yine PDF olur, katmansız).
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Bir görselden metni SATIR SATIR, resim piksel koordinatındaki kutusuyla
  /// birlikte tanır. Aranabilir PDF üretiminde her satırı kendi yerine
  /// yazmak için gerekir.
  ///
  /// ponytail: kutular ML Kit'in EXIF döndürmesi uygulanmış hâline göredir;
  /// EXIF ile döndürülmüş fotoğraflarda katman kayabilir — şikâyet gelirse
  /// resmi önce normalize edip (döndürmeyi baytlara işleyip) OCR'la.
  static Future<List<OcrLine>> recognizeImageLines(String path) async {
    if (!supported) return const [];
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      return [
        for (final block in result.blocks)
          for (final line in block.lines)
            if (line.text.trim().isNotEmpty)
              OcrLine(line.text, line.boundingBox),
      ];
    } finally {
      await recognizer.close();
    }
  }

  /// Sayfaları sırayla OCR'lar; [onProgress] sayfa sayfa ilerlemeyi bildirir
  /// (OCR sayfa başına birkaç saniye sürebilir).
  static Future<List<List<OcrLine>>> recognizePages(
    List<String> imagePaths, {
    void Function(int done, int total)? onProgress,
  }) async {
    final out = <List<OcrLine>>[];
    for (var i = 0; i < imagePaths.length; i++) {
      onProgress?.call(i, imagePaths.length);
      out.add(await recognizeImageLines(imagePaths[i]));
    }
    onProgress?.call(imagePaths.length, imagePaths.length);
    return out;
  }
}

/// OCR'ın bulduğu tek metin satırı ve resmin piksel koordinatındaki kutusu.
class OcrLine {
  const OcrLine(this.text, this.box);

  final String text;
  final ui.Rect box;
}
