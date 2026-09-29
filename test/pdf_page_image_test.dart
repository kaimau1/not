import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/pdf_page_image.dart';

/// Sayfaya gömülü PDF kutusunun çizim kararı (kullanıcı bulgusu 2026-09-29:
/// "2. sayfadan sonrası görülmüyor, numara değişiyor ama görüntü aynı
/// kalıyor"). pdfrx'in PdfPageView'ı yalnız ölçüye bakıp yeniden çizmiyordu;
/// buradaki anahtar SAYFA NUMARASINI da taşımalı.
void main() {
  const target = Size(400, 560);

  String key(int page, {bool loaded = true, Size size = target}) =>
      pdfRenderKey(
        documentId: 7,
        pageNumber: page,
        pageWidth: 595,
        pageHeight: 842,
        loaded: loaded,
        target: size,
      );

  test('aynı boydaki iki sayfanın çizim anahtarı FARKLI', () {
    expect(key(2), isNot(key(3)));
    expect(key(3), isNot(key(4)));
  });

  test('aynı sayfa, aynı ölçü → aynı anahtar (gereksiz yeniden çizim yok)', () {
    expect(key(5), key(5));
  });

  test('gerçek ölçü sonradan gelince yeniden çizilir', () {
    expect(key(2, loaded: false), isNot(key(2)));
  });

  test('kutu büyüyünce yeniden çizilir', () {
    expect(key(2), isNot(key(2, size: const Size(800, 1120))));
  });

  test('piksel ölçüsü kutuya sığar ve DPI tavanını aşmaz', () {
    final fit = pdfRenderSize(
      pageWidth: 595,
      pageHeight: 842,
      boxWidth: 300,
      boxHeight: 1000,
    )!;
    expect(fit.width, 300);
    expect(fit.height, closeTo(842 * 300 / 595, 1));

    final capped = pdfRenderSize(
      pageWidth: 100,
      pageHeight: 100,
      boxWidth: 10000,
      boxHeight: 10000,
      maximumDpi: 72,
    )!;
    expect(capped, const Size(100, 100));
  });

  test('ölçüsüz kutu ya da sayfa için çizim yok', () {
    expect(
      pdfRenderSize(
        pageWidth: 0,
        pageHeight: 842,
        boxWidth: 300,
        boxHeight: 300,
      ),
      isNull,
    );
    expect(
      pdfRenderSize(
        pageWidth: 595,
        pageHeight: 842,
        boxWidth: double.infinity,
        boxHeight: 300,
      ),
      isNull,
    );
  });
}
