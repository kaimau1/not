import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

/// Kırpma görselin ORANLI (0–1) çizim koordinatlarını geçersiz kılar; bu
/// eşleme bozulursa kullanıcı kırptığı görselde çizgiyi bambaşka bir yerde
/// bulur — ekranda fark edilmesi zor, testte kolay.
void main() {
  InkStroke stroke(List<double> points, {double width = 0.01}) =>
      InkStroke(page: 1, color: 0xFF000000, width: width, points: points);

  test('kırpılan alandaki nokta yeni çerçeveye göre yeniden ölçeklenir', () {
    // Sağ alt çeyrek kırpılıyor: (0.5,0.5) yeni çerçevenin sol-üst köşesi.
    final out = cropInk(
      [
        stroke([0.5, 0.5, 0.75, 1.0]),
      ],
      left: 0.5,
      top: 0.5,
      right: 1.0,
      bottom: 1.0,
    );
    expect(out, hasLength(1));
    expect(out.single.points, [0.0, 0.0, 0.5, 1.0]);
  });

  test('kalınlık daralan çerçeveyle aynı oranda büyür', () {
    final out = cropInk(
      [
        stroke([0.5, 0.5], width: 0.01),
      ],
      left: 0.5,
      top: 0.0,
      right: 1.0,
      bottom: 1.0,
    );
    // Genişlik yarıya indi → aynı kalınlık oranın iki katı.
    expect(out.single.width, closeTo(0.02, 1e-9));
  });

  test('tümüyle dışarıda kalan çizgi düşer, kısmen taşan korunur', () {
    final out = cropInk(
      [
        stroke([0.1, 0.1, 0.2, 0.2]), // sol üstte, kırpma dışında
        stroke([0.45, 0.6, 0.6, 0.6]), // bir ucu içeride
      ],
      left: 0.5,
      top: 0.5,
      right: 1.0,
      bottom: 1.0,
    );
    expect(out, hasLength(1));
    // Taşan uç negatif kalır; çizim katmanı kırpar, çizgi kesilmez.
    expect(out.single.points.first, lessThan(0));
  });

  test('sıfır alanlı kırpma çizimleri siler, bölme hatası vermez', () {
    expect(
      cropInk(
        [
          stroke([0.5, 0.5]),
        ],
        left: 0.5,
        top: 0.5,
        right: 0.5,
        bottom: 0.5,
      ),
      isEmpty,
    );
  });
}
