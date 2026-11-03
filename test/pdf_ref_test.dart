import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/pdf_ref.dart';

void main() {
  group('PDF sayfa referansı', () {
    test('Türkçe ve İngilizce biçim', () {
      expect(
        formatPdfRef(page: 12, line: 5, turkish: true),
        '📖 s.12 · 5. satır',
      );
      expect(
        formatPdfRef(page: 12, line: 5, turkish: false),
        '📖 p.12 · line 5',
      );
      expect(formatPdfRef(page: 3, turkish: true), '📖 s.3');
    });

    test('metinde bulunur; sayfa ve satır okunur', () {
      const text = 'giriş\n📖 s.12 · 5. satır “alıntı” yorum\n📖 p.7 sonra';
      final refs = findPdfPageRefs(text);
      expect(refs, hasLength(2));
      expect(refs[0].page, 12);
      expect(refs[0].line, 5);
      expect(text.substring(refs[0].start, refs[0].end), '📖 s.12 · 5. satır');
      expect(refs[1].page, 7);
      expect(refs[1].line, isNull);
      expect(pdfPageRefAt(text, refs[1].start + 3)?.page, 7);
      expect(pdfPageRefAt(text, 2), isNull);
    });

    test('kitap işareti olmayan "s.12" referans değildir', () {
      expect(findPdfPageRefs('bkz. s.12'), isEmpty);
    });

    test('not satırı alıntıyı tek satıra indirir ve kısaltır', () {
      expect(
        pdfNoteLine(page: 2, line: 1, quote: 'bir\niki  üç', turkish: true),
        '📖 s.2 · 1. satır “bir iki üç”',
      );
      final long = List.filled(100, 'kelime').join(' ');
      final snippet = pdfQuoteSnippet(long);
      expect(snippet.length, lessThanOrEqualTo(281));
      expect(snippet.endsWith('…'), isTrue);
      expect(pdfNoteLine(page: 4, turkish: false), '📖 p.4');
    });
  });

  group('satır numarası', () {
    // PDF koordinatı: y yukarı artar. Sol sütunda 4 satır, sağ sütunda 2.
    PdfTextBand band(double left, double top, double right) =>
        (left: left, top: top, right: right, bottom: top - 10);
    final fragments = [
      band(50, 700, 250),
      band(50, 685, 150), // aynı satırın iki parçası
      band(160, 686, 250),
      band(50, 670, 250),
      band(50, 655, 250),
      band(320, 700, 520),
      band(320, 685, 520),
    ];

    test('ilk satır 1, üçüncü satır 3', () {
      expect(pdfLineNumber(fragments, band(60, 700, 120)), 1);
      expect(pdfLineNumber(fragments, band(60, 670, 120)), 3);
    });

    test('yalnız aynı sütun sayılır', () {
      expect(pdfLineNumber(fragments, band(330, 685, 400)), 2);
    });

    test('parça yoksa null', () {
      expect(pdfLineNumber(const [], band(0, 10, 5)), isNull);
    });
  });
}
