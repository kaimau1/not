import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/sentence_select.dart';

/// Uzun basış Flutter'da yalnız KELİMEYİ seçer; notta seçim neredeyse hep bir
/// cümleyi taşımak/silmek için yapılıyor. Bu testler cümle sınırı bulmayı ve
/// "kelime seçimini cümleye büyüt" davranışını korur.
void main() {
  group('sentenceRangeAt', () {
    const text = 'Birinci cümle. İkinci cümle burada! Üçüncü olsun?';

    String at(String source, int offset) {
      final range = sentenceRangeAt(source, offset);
      return source.substring(range.start, range.end);
    }

    test('ortadaki kelimeden tüm cümle bulunur', () {
      expect(at(text, 3), 'Birinci cümle.');
      expect(at(text, 20), 'İkinci cümle burada!');
      expect(at(text, 40), 'Üçüncü olsun?');
    });

    test('cümle sonundaki boşluk seçime girmez', () {
      final range = sentenceRangeAt(text, 3);
      expect(text[range.end - 1], '.');
    });

    test('satır sonu da cümle sınırıdır', () {
      const lines = 'Alışveriş listesi\nSüt al\nEkmek al';
      expect(at(lines, 20), 'Süt al');
      expect(at(lines, 0), 'Alışveriş listesi');
    });

    test('ondalık sayıdaki nokta cümleyi bitirmez', () {
      const price = 'Fiyat 12.50 lira oldu. Ucuz.';
      expect(at(price, 8), 'Fiyat 12.50 lira oldu.');
    });

    test('ardışık noktalama ve kapanış işareti cümlede kalır', () {
      const shout = 'Ne oldu?! Bilmiyorum.';
      expect(at(shout, 2), 'Ne oldu?!');
      const quoted = 'Dedi ki "bitti." Sonra gitti.';
      expect(at(quoted, 2), 'Dedi ki "bitti."');
    });

    test('noktalama yoksa tüm metin tek cümledir', () {
      expect(at('kısa not', 2), 'kısa not');
    });

    test('boş metin çökmez', () {
      expect(sentenceRangeAt('', 0).start, 0);
    });

    test('kısaltmalar cümleyi bitirmez', () {
      const doctor = 'Dr. Ahmet yarın geliyor.';
      expect(at(doctor, 6), 'Dr. Ahmet yarın geliyor.');
      const see = 'Ayrıntı için bkz. yukarıdaki not';
      expect(at(see, 2), 'Ayrıntı için bkz. yukarıdaki not');
      const tc = 'T.C. kimlik numarası gerekli.';
      expect(at(tc, 8), 'T.C. kimlik numarası gerekli.');
    });

    test('ad baş harfi (tek harf + nokta) cümleyi bitirmez', () {
      const name = 'Toplantıya A. Yılmaz da katıldı.';
      expect(at(name, 15), 'Toplantıya A. Yılmaz da katıldı.');
    });

    test('sıra sayısı küçük harfle sürüyorsa cümle bitmez', () {
      const floor = 'Yarın 3. katta buluşalım.';
      expect(at(floor, 10), 'Yarın 3. katta buluşalım.');
    });

    test('sayı + nokta + BÜYÜK harf cümle sonudur', () {
      const time = 'Saat tam 5. Sonra çıktık.';
      expect(at(time, 2), 'Saat tam 5.');
      expect(at(time, 14), 'Sonra çıktık.');
    });

    test('üç nokta küçük harfle sürüyorsa duraksamadır', () {
      const pause = 'Olur mu bilmem... belki yarın gelirim.';
      expect(at(pause, 2), 'Olur mu bilmem... belki yarın gelirim.');
    });

    test('üç nokta + BÜYÜK harf cümle sonudur', () {
      const done = 'Bitti... Sonra gittik.';
      expect(at(done, 2), 'Bitti...');
    });
  });

  group('tokenRangeAt', () {
    String tokenAt(String source, int start, int end) {
      final range = tokenRangeAt(
        source,
        TextRange(start: start, end: end),
      );
      return source.substring(range.start, range.end);
    }

    test('API anahtarı gibi noktalamalı token bütün seçilir', () {
      const text = 'anahtar: sk-abc.Def_123 kaydet';
      // Çift dokunuş yalnız "abc"yi seçmişti (12..15).
      expect(tokenAt(text, 12, 15), 'sk-abc.Def_123');
    });

    test('kenardaki tırnak/parantez/virgül tokena girmez', () {
      const text = 'adres (https://x.com/a?b=1), tamam';
      // "com" parçası seçildi.
      expect(tokenAt(text, 17, 20), 'https://x.com/a?b=1');
    });

    test('cümle sonundaki nokta tokena girmez', () {
      const text = 'site example.com. Sonra bak.';
      expect(tokenAt(text, 5, 12), 'example.com');
    });

    test('düz kelimede aralık değişmez', () {
      const text = 'sade kelime burada';
      expect(tokenAt(text, 5, 11), 'kelime');
    });
  });

  group('attachSentenceSelection', () {
    const text = 'Birinci cümle. İkinci cümle burada!';

    TextEditingController attached() {
      final controller = TextEditingController(text: text);
      attachSentenceSelection(controller);
      addTearDown(controller.dispose);
      return controller;
    }

    test('kelime seçimi cümleye büyür', () {
      final controller = attached();
      // "İkinci" kelimesi (uzun basışın ürettiği seçim).
      controller.selection = const TextSelection(
        baseOffset: 15,
        extentOffset: 21,
      );
      expect(
        text.substring(controller.selection.start, controller.selection.end),
        'İkinci cümle burada!',
      );
    });

    test('imleç (boş seçim) büyütülmez', () {
      final controller = attached();
      controller.selection = const TextSelection.collapsed(offset: 4);
      expect(controller.selection.isCollapsed, isTrue);
    });

    test('tümünü seç bozulmaz', () {
      final controller = attached();
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      );
      expect(controller.selection.start, 0);
      expect(controller.selection.end, text.length);
    });

    test('tutamakla daraltma korunur (cümle içinde kalan seçim)', () {
      final controller = attached();
      controller.selection = const TextSelection(
        baseOffset: 15,
        extentOffset: 21,
      );
      final expanded = controller.selection;
      // Kullanıcı tutamağı çekip tek kelimeye indiriyor: yeniden büyütülmemeli.
      controller.selection = TextSelection(
        baseOffset: expanded.start,
        extentOffset: expanded.start + 6,
      );
      expect(controller.selection.end, expanded.start + 6);
    });

    test('başka bir cümledeki kelime yeniden büyütülür', () {
      final controller = attached();
      controller.selection = const TextSelection(
        baseOffset: 15,
        extentOffset: 21,
      );
      // Seçim dururken ilk cümledeki bir kelimeye uzun basış.
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 7,
      );
      expect(
        text.substring(controller.selection.start, controller.selection.end),
        'Birinci cümle.',
      );
    });

    test('noktalamalı token önce BÜTÜN olarak seçilir (API anahtarı)', () {
      const keyed = 'anahtar: sk-abc.Def_123 kaydet';
      final controller = TextEditingController(text: keyed);
      attachSentenceSelection(controller);
      addTearDown(controller.dispose);
      // Çift dokunuş anahtarın yalnız "abc" parçasını seçer (12..15).
      controller.selection = const TextSelection(
        baseOffset: 12,
        extentOffset: 15,
      );
      expect(
        keyed.substring(controller.selection.start, controller.selection.end),
        'sk-abc.Def_123',
      );
    });

    test('aynı kelimeye ikinci çift dokunuş tokendan cümleye çıkar', () {
      const keyed = 'anahtar: sk-abc.Def_123 kaydet';
      final controller = TextEditingController(text: keyed);
      attachSentenceSelection(controller);
      addTearDown(controller.dispose);
      controller.selection = const TextSelection(
        baseOffset: 12,
        extentOffset: 15,
      );
      // Flutter ikinci çift dokunuşta yine baz kelimeyi ("abc") seçer.
      controller.selection = const TextSelection(
        baseOffset: 12,
        extentOffset: 15,
      );
      expect(
        keyed.substring(controller.selection.start, controller.selection.end),
        keyed,
      );
    });

    test('token seçiminden tutamakla daraltma korunur', () {
      const keyed = 'anahtar: sk-abc.Def_123 kaydet';
      final controller = TextEditingController(text: keyed);
      attachSentenceSelection(controller);
      addTearDown(controller.dispose);
      controller.selection = const TextSelection(
        baseOffset: 12,
        extentOffset: 15,
      );
      // Tutamak, tokenın İLK yarısına çekiliyor (baz kelimeyle aynı değil).
      controller.selection = const TextSelection(
        baseOffset: 9,
        extentOffset: 15,
      );
      expect(controller.selection.start, 9);
      expect(controller.selection.end, 15);
    });

    test('METİN değiştiyse (biçim uygulandıysa) genişletme yapılmaz', () {
      // KÖK NEDEN (v1.0.179): biçim uygulamak metne işaret ekler ve seçimi
      // yeni konumuna taşır; bu programlı seçim "kullanıcı bir kelimeye uzun
      // bastı" sanılıp TÜM SATIRA büyütülüyordu — kullanıcının seçtiği tek
      // kelime yerine satırın tamamı biçimleniyordu.
      final controller = attached();
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 7,
      );
      // (buraya kadar normal: kelime cümleye büyüdü)
      controller.value = const TextEditingValue(
        text: '**Birinci** cümle. İkinci cümle.',
        selection: TextSelection(baseOffset: 2, extentOffset: 9),
      );
      expect(controller.selection.baseOffset, 2);
      expect(controller.selection.extentOffset, 9);
    });
  });
}
