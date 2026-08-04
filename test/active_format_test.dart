import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';

/// Biçim şeridindeki "aktif biçim" vurgusu.
///
/// Kural: vurgu, düğmeye basılınca biçimin KALKACAĞI durumu göstermeli —
/// yani [toggleFormat] ile aynı tanımı kullanmalı. Yoksa şerit yalan söyler:
/// basılı görünen düğmeye basınca biçim kalkmaz, eklenir.
void main() {
  group('imleç (seçim yok)', () {
    test('biçimsiz metinde hiçbir düğme basılı değil', () {
      expect(activeFormats('merhaba', 3, 3), RichMark.none);
    });

    test('kalın parçanın içindeki imleç kalını basılı gösterir', () {
      const text = '**kalin**';
      // "kalin"in ortası (işaretten sonra).
      final mark = activeFormats(text, 4, 4);
      expect(mark.bold, isTrue);
      expect(mark.italic, isFalse);
    });

    test('imlecin SOLUNDAKİ karakter esas alınır', () {
      const text = '**ab**cd';
      // "b" ile "c" arasındaki sınır: soldaki karakter kalın.
      expect(activeFormats(text, 4, 4).bold, isTrue);
      // "c" ile "d" arasında: artık kalın değil.
      expect(activeFormats(text, 7, 7).bold, isFalse);
    });

    test('iç içe biçimlerin hepsi birden etkin olur', () {
      const text = '**_ikisi_**';
      final mark = activeFormats(text, 5, 5);
      expect(mark.bold, isTrue);
      expect(mark.italic, isTrue);
    });
  });

  group('seçim', () {
    test('tamamı kalın olan seçimde kalın etkin', () {
      const text = '**hepsi**';
      expect(activeFormats(text, 2, 7).bold, isTrue);
    });

    test('yalnız bir kısmı kalınsa etkin DEĞİL', () {
      // toggleFormat böyle bir seçimde biçimi EKLER, kaldırmaz; vurgu da
      // bu yüzden sönük kalmalı.
      const text = '**ab**cd';
      expect(activeFormats(text, 0, text.length).bold, isFalse);
    });
  });

  group('indeks alan biçimler', () {
    test('renk indeksi vurguya taşınır', () {
      const text = '%%3:yesil%%';
      final mark = activeFormats(text, 5, 5);
      expect(mark.color, 3);
      expect(mark.highlight, isNull);
    });

    test('vurgu (chip) rengi ayrı alanda döner', () {
      const text = '==2:sari==';
      final mark = activeFormats(text, 5, 5);
      expect(mark.highlight, 2);
      expect(mark.color, isNull);
    });
  });

  group('sınır durumları', () {
    test('geçersiz aralıkta biçimsiz döner', () {
      expect(activeFormats('abc', -1, 2), RichMark.none);
      expect(activeFormats('abc', 0, 99), RichMark.none);
      expect(activeFormats('abc', 3, 1), RichMark.none);
    });

    test('boş metin', () {
      expect(activeFormats('', 0, 0), RichMark.none);
    });
  });
}
