import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

void main() {
  // Gövdenin ilk satırı 100 dp'de başlıyor, satır yüksekliği 20 dp.
  const bodyTop = 100.0;
  const lineHeight = 20.0;

  test('görsel yokken ipucu gövdenin tepesinde kalır', () {
    expect(hintTopFor(const [], bodyTop, lineHeight), bodyTop);
  });

  test('ipucunu kesmeyen görsel onu yerinden oynatmaz', () {
    // Görsel ipucu bandının ALTINDA başlıyor (130 > 100+20).
    const alt = FloatBox(top: 130, left: 0, right: 300, height: 80);
    expect(hintTopFor(const [alt], bodyTop, lineHeight), bodyTop);
  });

  test('ipucunu kesen görsel ipucunu altına iter', () {
    // Asıl bug: görsel en üste sürüklendiğinde ipucu altında kayboluyordu.
    const ust = FloatBox(top: 90, left: 0, right: 300, height: 60);
    expect(hintTopFor(const [ust], bodyTop, lineHeight), 150.0);
  });

  test('üst üste binen iki görsel ipucunu en alttakinin altına iter', () {
    const a = FloatBox(top: 90, left: 0, right: 300, height: 60); // bottom 150
    const b = FloatBox(top: 140, left: 0, right: 300, height: 40); // bottom 180
    // Sıra bozuk verilse de sonuç aynı olmalı (fonksiyon kendi sıralıyor).
    expect(hintTopFor(const [b, a], bodyTop, lineHeight), 180.0);
    expect(hintTopFor(const [a, b], bodyTop, lineHeight), 180.0);
  });

  test('araya boşluk giren ikinci görsel ipucunu bir daha itmez', () {
    const a = FloatBox(top: 90, left: 0, right: 300, height: 60); // bottom 150
    // İpucu 150'ye iner; bu görsel 200'de başlıyor, 150+20 bandını kesmiyor.
    const uzak = FloatBox(top: 200, left: 0, right: 300, height: 40);
    expect(hintTopFor(const [a, uzak], bodyTop, lineHeight), 150.0);
  });
}
