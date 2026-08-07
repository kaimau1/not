import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/pdf/edge_auto_scroll.dart';
import 'package:notlar/features/notes/data/pdf/ocr_page_text.dart';
import 'package:notlar/features/notes/data/pdf/selection_rects.dart';
import 'package:pdfrx/pdfrx.dart';

/// PDF metin seciminin SAF mantigi: satir birlestirme (vurgu nasil gorunur),
/// taranmis sayfanin OCR metni (secim onun uzerinden calisir) ve kenar
/// oto-kaydirmasi. Jest/katman davranisi widget testinin degil cihazin isi.
void main() {
  group('mergeSameLineRects', () {
    test('ayni satirdaki komsu kutular tek kutuda birlesir', () {
      // PDF koordinati: top > bottom (orijin sol-ALT kose).
      final merged = mergeSameLineRects([
        PdfRect(10, 100, 40, 90),
        PdfRect(42, 100, 80, 90),
      ]);
      expect(merged, hasLength(1));
      expect(merged.single.left, 10);
      expect(merged.single.right, 80);
    });

    test('farkli satirlar ayri kalir', () {
      final merged = mergeSameLineRects([
        PdfRect(10, 100, 40, 90),
        PdfRect(10, 80, 40, 70),
      ]);
      expect(merged, hasLength(2));
    });

    test('SUTUN araligi birlestirilmez — vurgu sayfayi kaplamasin', () {
      // Ayni yukseklikte ama yatayda cok uzak iki kutu (iki sutun).
      final merged = mergeSameLineRects([
        PdfRect(10, 100, 40, 90),
        PdfRect(300, 100, 340, 90),
      ]);
      expect(merged, hasLength(2));
    });

    test('bozuk kutu (top <= bottom) atilir', () {
      expect(mergeSameLineRects([PdfRect(10, 90, 40, 100)]), isEmpty);
    });
  });

  group('buildOcrPageText', () {
    test('sozcuk kutularindan secilebilir sayfa metni kurar', () {
      final text = buildOcrPageText(
        pageNumber: 3,
        pageHeight: 200,
        imageScale: 2,
        lines: [
          [
            const OcrWordBox('ab', Rect.fromLTRB(0, 0, 20, 20)),
            const OcrWordBox('cd', Rect.fromLTRB(30, 0, 50, 20)),
          ],
        ],
      );
      expect(text, isNotNull);
      expect(text!.pageNumber, 3);
      expect(text.fullText, 'ab cd\n');
      // Karakter kutusu sayisi metinle BIREBIR ayni olmali: secim tutamaci
      // metin indeksinden kutu ariyor, kayarsa yanlis harf secilir.
      expect(
        text.fragments.single.charRects.length,
        text.fullText.length,
      );
    });

    test('y ekseni cevrilir — PDF orijini sol ALT kosede', () {
      final text = buildOcrPageText(
        pageNumber: 1,
        pageHeight: 200,
        imageScale: 2,
        lines: [
          [const OcrWordBox('a', Rect.fromLTRB(0, 0, 20, 40))],
        ],
      );
      final rect = text!.fragments.single.charRects.first;
      // Goruntunun tepesi (y=0) PDF'te sayfa yuksekligidir.
      expect(rect.top, 200);
      expect(rect.bottom, 180); // 200 - 40/2
      expect(rect.right, 10); // 20/2
      expect(rect.top, greaterThan(rect.bottom));
    });

    test('sozcuk yoksa null doner (OCR bos)', () {
      expect(
        buildOcrPageText(
          pageNumber: 1,
          pageHeight: 100,
          imageScale: 1,
          lines: const [[]],
        ),
        isNull,
      );
    });

    test('gecersiz olcek null doner — sifira bolme yok', () {
      expect(
        buildOcrPageText(
          pageNumber: 1,
          pageHeight: 100,
          imageScale: 0,
          lines: [
            [const OcrWordBox('a', Rect.fromLTRB(0, 0, 10, 10))],
          ],
        ),
        isNull,
      );
    });
  });

  group('edgeAutoScrollDelta', () {
    const viewport = Size(400, 800);

    test('ortada duran parmak sayfayi kaydirmaz', () {
      expect(edgeAutoScrollDelta(const Offset(200, 400), viewport), Offset.zero);
    });

    test('alt kenara yaklasinca asagi akar', () {
      final delta = edgeAutoScrollDelta(const Offset(200, 795), viewport);
      expect(delta.dy, greaterThan(0));
      expect(delta.dx, 0);
    });

    test('ust kenarda ters yone akar', () {
      expect(
        edgeAutoScrollDelta(const Offset(200, 2), viewport).dy,
        lessThan(0),
      );
    });

    test('kenara yaklastikca hizlanir ama maxStep asilmaz', () {
      final yakin = edgeAutoScrollDelta(const Offset(200, 770), viewport).dy;
      final kenar = edgeAutoScrollDelta(const Offset(200, 800), viewport).dy;
      expect(kenar, greaterThan(yakin));
      expect(kenar, lessThanOrEqualTo(14));
    });
  });
}
