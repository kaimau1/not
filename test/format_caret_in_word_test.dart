import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';

/// İmleç bir kelimenin İÇİNDEyken biçim düğmesi.
///
/// KÖK NEDEN (kullanıcı bildirdi): imleç kelimenin ortasındayken boş biçim
/// kutusu açılıyordu ve geriye HAM işaret kalıyordu — `merh__aba`. `_` ve `~`
/// çözümleyicide kelime içinde sayılmadığı için (bkz. `_formatPattern`) o
/// metin hiçbir zaman italiğe dönüşmüyor, kullanıcı notunda alt çizgi
/// görüyordu. `**` çözümleniyordu ama kelimeyi ikiye bölüyordu.
///
/// Doğru davranış Word/Docs'taki: kelimenin içindeki imleç → biçim KELİMENİN
/// TAMAMINA. Kelime kenarında ya da boşlukta imleç → eski davranış (boş kutu,
/// "biçimli yazmaya başla").
void main() {
  group('kelime ORTASINDA imleç → tüm kelime', () {
    test('italik ham işaret bırakmaz, kelimeyi sarar', () {
      final r = toggleFormat('merhaba', 4, 4, RichFormat.italic);
      expect(r.text, '_merhaba_');
      // Asıl kanıt: işaret ÇÖZÜMLENİYOR — kullanıcı ham `_` görmüyor.
      expect(stripRichMarkers(r.text), 'merhaba');
    });

    test('kalın kelimeyi ikiye bölmez', () {
      final r = toggleFormat('merhaba', 4, 4, RichFormat.bold);
      expect(r.text, '**merhaba**');
      expect(stripRichMarkers(r.text), 'merhaba');
    });

    test('altı çizili de sarar', () {
      final r = toggleFormat('merhaba', 3, 3, RichFormat.underline);
      expect(stripRichMarkers(r.text), 'merhaba');
      expect(r.text.contains('~merhaba~'), isTrue);
    });

    test('TÜRKÇE harfli kelimede de çalışır', () {
      // "ş" ASCII \w değil; kelime sınırı ASCII'ye göre hesaplansaydı bu
      // kelime ortadan bölünürdü.
      final r = toggleFormat('çalışma', 4, 4, RichFormat.bold);
      expect(r.text, '**çalışma**');
      expect(stripRichMarkers(r.text), 'çalışma');
    });

    test('cümlenin ortasındaki kelime yalnız kendisi biçimlenir', () {
      final r = toggleFormat('bugün hava çok güzel', 8, 8, RichFormat.bold);
      expect(r.text, 'bugün **hava** çok güzel');
      expect(stripRichMarkers(r.text), 'bugün hava çok güzel');
    });

    test('renk indeksi kelimeye taşınır', () {
      final r = toggleFormat('merhaba', 4, 4, RichFormat.color, colorIndex: 3);
      expect(r.text, '%%3:merhaba%%');
      expect(activeFormats(r.text, 6, 6).color, 3);
    });

    test('seçim biçimlenen kelimenin üstünde kalır', () {
      final r = toggleFormat('merhaba', 4, 4, RichFormat.bold);
      // Seçim gövdeyi kapsamalı: kullanıcı arka arkaya kalın + renk verebilsin.
      expect(r.text.substring(r.start, r.end), 'merhaba');
    });
  });

  group('kelime KENARINDA imleç → eski davranış (boş kutu)', () {
    test('kelime başında boş kutu açılır', () {
      final r = toggleFormat('merhaba', 0, 0, RichFormat.bold);
      expect(r.text, '****merhaba');
    });

    test('kelime sonunda boş kutu açılır', () {
      final r = toggleFormat('merhaba', 7, 7, RichFormat.bold);
      expect(r.text, 'merhaba****');
    });

    test('boşlukta boş kutu açılır', () {
      final r = toggleFormat('bir iki', 4, 4, RichFormat.bold);
      // "bir " ile "iki" sınırı: solda boşluk var, kelime içi değil.
      expect(r.text, 'bir ****iki');
    });
  });

  group('zaten biçimli kelime', () {
    test('kelime içindeki imleç biçimi KALDIRIR (aç/kapa korunur)', () {
      final r = toggleFormat('**merhaba**', 6, 6, RichFormat.bold);
      expect(r.text, 'merhaba');
    });
  });
}
