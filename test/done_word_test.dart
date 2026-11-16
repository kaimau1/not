import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/done_word.dart';

void main() {
  test('sondaki bitiş sözü atılır', () {
    expect(stripDoneWord('süt ekmek yumurta bitti'), 'süt ekmek yumurta');
    expect(stripDoneWord('süt ekmek Bitti.'), 'süt ekmek');
    expect(
      stripDoneWord('pasaport şarj aleti bu kadar'),
      'pasaport şarj aleti',
    );
    expect(stripDoneWord('milk eggs done'), 'milk eggs');
    expect(stripDoneWord('BİTTİ'), '');
    expect(stripDoneWord('bitti'), '');
  });

  test('ortada ya da kelime içinde geçen söz sayılmaz', () {
    expect(stripDoneWord('bitti süt ekmek'), isNull);
    expect(stripDoneWord('süt ekmek'), isNull);
    expect(stripDoneWord('yabitti'), isNull);
    expect(stripDoneWord(''), isNull);
  });
}
