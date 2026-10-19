import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/scan/scan_ocr.dart';
import 'package:notlar/features/notes/data/scan/scan_pdf.dart';

/// Geçerli 1x1 piksel PNG.
const _png1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// Sayfa **içerik akışları** (çizim komutları), açılmış hâlde.
///
/// Yalnız metin çizen akışlar süzülüyor (`BT` = begin text, `Tf` = yazı
/// tipi): gömülü yazı tipi programı da sıkıştırılmış bir akış.
List<String> _textContentStreams(List<int> pdf) => _inflatedStreams(
  pdf,
).where((s) => s.contains('BT') && s.contains(' Tf')).toList();

/// PDF içindeki sıkıştırılmış akışları açıp metin olarak döndürür.
List<String> _inflatedStreams(List<int> pdf) {
  final raw = latin1.decode(pdf, allowInvalid: true);
  final out = <String>[];
  var i = 0;
  while (true) {
    final start = raw.indexOf('stream', i);
    if (start < 0) break;
    var dataStart = start + 'stream'.length;
    if (raw.startsWith('\r\n', dataStart)) {
      dataStart += 2;
    } else if (raw.startsWith('\n', dataStart)) {
      dataStart += 1;
    }
    final end = raw.indexOf('endstream', dataStart);
    if (end < 0) break;
    try {
      out.add(
        latin1.decode(
          zlib.decode(pdf.sublist(dataStart, end)),
          allowInvalid: true,
        ),
      );
    } catch (_) {
      // Sıkıştırılmamış ya da resim akışı — bu testin ilgi alanı değil.
    }
    i = end + 'endstream'.length;
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File image;

  setUp(() async {
    image = File(
      '${Directory.systemTemp.path}/scan_ocr_test_'
      '${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await image.writeAsBytes(base64Decode(_png1x1));
  });

  tearDown(() {
    if (image.existsSync()) image.deleteSync();
  });

  /// dosya-okuyucu kök nedeni (2026-07-31): OCR metni KOYU SİYAH basılıyordu.
  /// Görünmezlik grafik durumunun saydamlığıyla (`/ca 0`) sağlanır; metin
  /// seçilebilir/aranabilir kalır.
  group('aranabilir PDF görünmez metin katmanı', () {
    test('OCR satırları saydam (ca 0) durumda çizilir', () async {
      final pdf = await ScanPdf.build(
        [image.path],
        ocrLinesPerPage: [
          [
            const OcrLine('Sour Cream & Chive', ui.Rect.fromLTWH(0, 0, 80, 12)),
            const OcrLine(
              'İçindekiler: Buğday Unu',
              ui.Rect.fromLTWH(0, 14, 90, 12),
            ),
          ],
        ],
      );

      expect(
        _textContentStreams(pdf),
        isNotEmpty,
        reason: 'metin hiç çizilmemiş',
      );
      final raw = latin1.decode(pdf, allowInvalid: true);
      expect(raw, contains('/ca 0'), reason: 'metin katmanı saydam olmalı');
    });

    test('OCR yoksa hiç metin çizilmez', () async {
      final pdf = await ScanPdf.build([image.path]);
      expect(_textContentStreams(pdf), isEmpty);
    });
  });
}
