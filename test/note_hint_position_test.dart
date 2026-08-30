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
    // Bandın altı 150; ipucu METNİN SATIRINA oturur, yani gövdenin
    // tepesinden itibaren tam satır katına (100 + 3×20 = 160) — imleç de
    // orada yanıp söner (bkz. hintTopFor).
    const ust = FloatBox(top: 90, left: 0, right: 300, height: 60);
    expect(hintTopFor(const [ust], bodyTop, lineHeight), 160.0);
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
    // İpucu 160'a iner; bu görsel 200'de başlıyor, 160+20 bandını kesmiyor.
    const uzak = FloatBox(top: 200, left: 0, right: 300, height: 40);
    expect(hintTopFor(const [a, uzak], bodyTop, lineHeight), 160.0);
  });

  // ── İpucu ile İMLECİN AYNI YERDE olması ───────────────────────────────
  // Kullanıcı bulgusu 2026-08-16 (ekran görüntüsü): "Not... yazısı ile imleç
  // farklı yerlerde, imlecin yeri doğru". Metin görselin YANINDAN akıyorsa
  // ipucu da orada durmalı; yalnız yan taraf okunmayacak kadar darsa altına
  // inmeli (metnin kendi kuralıyla birebir aynı).
  const columnWidth = 400.0;

  test('yanında yer varsa ipucu görselin SAĞINDAN başlar, aşağı inmez', () {
    // Görsel sütunun solunda 160 dp yer kaplıyor; kalan 240 dp (%60) okunur.
    const sol = FloatBox(top: 90, left: 0, right: 160, height: 120);
    final place = hintPlacement(const [sol], bodyTop, lineHeight, columnWidth);
    expect(place.top, bodyTop);
    expect(place.left, 160.0);
  });

  test('yan taraf çok darsa ipucu eskisi gibi altına iner', () {
    // Görsel 340 dp kaplıyor; kalan 60 dp (%15) eşiğin altında.
    const genis = FloatBox(top: 90, left: 0, right: 340, height: 60);
    final place = hintPlacement(const [genis], bodyTop, lineHeight, columnWidth);
    expect(place.top, 160.0);
    expect(place.left, 0.0);
  });

  test('SAĞ kenardaki görsel ipucunu içeri itmez, yalnız daraltır', () {
    // Sağda duran görsel: sol kenar boşta, ipucu 0'dan başlamalı.
    const sag = FloatBox(top: 90, left: 260, right: 400, height: 120);
    final place = hintPlacement(const [sag], bodyTop, lineHeight, columnWidth);
    expect(place.top, bodyTop);
    expect(place.left, 0.0);
  });

  test('görsel yokken ipucu yine gövdenin tepesinde', () {
    final place = hintPlacement(const [], bodyTop, lineHeight, columnWidth);
    expect(place.top, bodyTop);
    expect(place.left, 0.0);
  });
}
