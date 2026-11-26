import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/dictation_tidy.dart';

void main() {
  test('dolgu sesleri atılır, gerçek kelimeler kalır', () {
    expect(
      tidyDictation('ııı yarın eee markete gideceğim'),
      'Yarın markete gideceğim',
    );
    expect(tidyDictation('hmm bence, eee, olur'), 'Bence, olur');
    expect(isDictationFiller('ııı'), isTrue);
    expect(isDictationFiller('Eee,'), isTrue);
    expect(isDictationFiller('eh'), isFalse, reason: '"eh işte" anlamlı');
    expect(isDictationFiller('ee'), isFalse, reason: '"ee ne oldu" anlamlı');
    expect(isDictationFiller('şey'), isFalse);
    expect(isDictationFiller('mı'), isFalse);
  });

  test('noktalama boşlukları; sayılar bozulmaz', () {
    expect(
      tidyDictation('süt , ekmek ve yumurta .', before: 'a '),
      'süt, ekmek ve yumurta.',
    );
    expect(
      tidyDictation('saat 10:30 da 3,5 kilo', before: 'x '),
      'saat 10:30 da 3,5 kilo',
    );
    expect(tidyDictation('tamam,sonra', before: 'x '), 'tamam, sonra');
  });

  test('soru eki ile biten satıra soru işareti', () {
    expect(tidyDictation('yarın geliyor musun'), 'Yarın geliyor musun?');
    expect(tidyDictation('bunu yaptın mı'), 'Bunu yaptın mı?');
    expect(tidyDictation('hazır mıyız'), 'Hazır mıyız?');
    expect(
      tidyDictation('bunu yaptın mı bilmiyorum'),
      'Bunu yaptın mı bilmiyorum',
    );
    expect(tidyDictation('geliyor musun?'), 'Geliyor musun?');
    expect(tidyDictation('mi'), 'Mi', reason: 'tek kelime soru sayılmaz');
  });

  test('cümle başı büyür, ortadaki yazım korunur', () {
    expect(
      tidyDictation('ve sonra Ahmet geldi', before: 'Dün eve gittim '),
      've sonra Ahmet geldi',
    );
    expect(
      tidyDictation('yarın görüşürüz', before: 'Tamam. '),
      'Yarın görüşürüz',
    );
    expect(tidyDictation('iyi. ışıklar yandı'), 'İyi. Işıklar yandı');
    expect(tidyDictation('3. kat', before: 'x '), '3. kat');
    expect(tidyDictation('ilk\nikinci satır'), 'İlk\nİkinci satır');
  });

  test('liste maddesinde sondaki tek nokta atılır', () {
    expect(tidyDictation('Ekmek.', item: true), 'Ekmek');
    expect(tidyDictation('ekmek', item: true), 'Ekmek');
    expect(tidyDictation('geliyor mu', item: true), 'Geliyor mu?');
    expect(tidyDictation('devamı...', item: true), 'Devamı...');
  });
}
