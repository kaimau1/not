import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';

/// Sürükleyerek sıralarken kenar kaydırması: liste serbest görsel tuvalinin
/// içinde `shrinkWrap` ile durduğundan ReorderableListView'ın yerleşik
/// otomatik kaydırıcısı çalışmıyor, kenar mantığını editör kendi yürütüyor.
void main() {
  // Görünür sayfa kutusu: ekranda 100–700 arası.
  const top = 100.0;
  const bottom = 700.0;

  double step(double y) =>
      reorderAutoScrollStep(pointerY: y, top: top, bottom: bottom);

  test('ortada kaydırma yok', () {
    expect(step(400), 0);
    expect(step(top + 88), 0);
    expect(step(bottom - 88), 0);
  });

  test('üst banda girince yukarı kaydırır', () {
    expect(step(top + 40), lessThan(0));
    // Bandın dibine inildikçe hızlanır.
    expect(step(top + 10).abs(), greaterThan(step(top + 40).abs()));
  });

  test('alt banda girince aşağı kaydırır', () {
    expect(step(bottom - 40), greaterThan(0));
    expect(step(bottom - 10), greaterThan(step(bottom - 40)));
  });

  test('kutunun dışına taşan parmakta hız tavanda kalır', () {
    expect(step(top - 500), -14);
    expect(step(bottom + 500), 14);
  });

  test('bandın iki katından kısa kutuda üst ve alt bant örtüşmez', () {
    // 100 px'lik kutuda 88'lik bant kullanılsaydı her nokta hem üst hem alt
    // banda düşer, parmak nerede olursa olsun kaydırma tetiklenirdi.
    double short(double y) =>
        reorderAutoScrollStep(pointerY: y, top: 0, bottom: 100);
    expect(short(50), 0);
    expect(short(10), lessThan(0));
    expect(short(90), greaterThan(0));
  });

  test('yüksekliği sıfır kutuda kaydırma yok', () {
    expect(reorderAutoScrollStep(pointerY: 5, top: 10, bottom: 10), 0);
  });
}
