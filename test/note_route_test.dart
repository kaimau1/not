import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/router.dart';

void main() {
  // v1.0.181: rota metni elle kuruluyordu ve kacan bir ters bolu yuzunden
  // '/note/$id' DUZ METIN olarak gitti; uygulama olmayan bir notu bekledigi
  // icin yeni not acan butun modlar "yukleniyor" ekraninda kaldi. Derleyici
  // ve testler goremedi (gecerli bir dizeydi). Artik tek yer, tek test.
  test('not rotasi id ve sorguyu YERINE KOYAR', () {
    expect(noteRoutePath('abc123'), '/note/abc123');
    expect(noteRoutePath('abc123', query: '?draw=1'), '/note/abc123?draw=1');
    expect(noteRoutePath('x').contains(r'$'), isFalse);
  });
}
