import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/zoom_math.dart';

/// **ÇİFT DOKUNUŞLA YAKINLAŞTIRMA** (kullanıcı isteği 2026-09-06: "görsel
/// açılınca çift tık zoom mantığı Google fotoğraflar gibi").
///
/// Google Fotoğraflar'ın üç kuralı burada ölçülüyor: dokunulan nokta yerinde
/// kalır, ikinci çift dokunuş sığdırır, görüntü kutunun dışına taşmaz.
void main() {
  const viewport = Size(400, 800);

  /// [point]'in ekrandaki (kutu uzayındaki) yeni yeri.
  Offset screenOf(Matrix4 m, Offset scenePoint) =>
      MatrixUtils.transformPoint(m, scenePoint);

  group('zoomAt', () {
    test('dokunulan nokta EKRANDA yerinde kalır', () {
      const tap = Offset(200, 400); // tam orta: sınır kırpması karışmasın
      final m = zoomAt(
        current: Matrix4.identity(),
        viewportPoint: tap,
        viewport: viewport,
      );
      expect(m.getMaxScaleOnAxis(), closeTo(kDoubleTapScale, 0.0001));
      // Sahnedeki aynı nokta (kimlik matrisinde sahne = ekran) yerinde.
      expect(screenOf(m, tap).dx, closeTo(tap.dx, 0.01));
      expect(screenOf(m, tap).dy, closeTo(tap.dy, 0.01));
    });

    test('KENARA dokunmak boşluk açmaz — görüntü kenara yaslanır', () {
      final m = zoomAt(
        current: Matrix4.identity(),
        viewportPoint: const Offset(2, 2),
        viewport: viewport,
      );
      // Sol-üst köşe kutunun içinde ya da tam kenarında; sağ-alt köşe de
      // kutunun kenarında ya da dışında (yani boşluk yok).
      final topLeft = screenOf(m, Offset.zero);
      final bottomRight = screenOf(
        m,
        Offset(viewport.width, viewport.height),
      );
      expect(topLeft.dx, lessThanOrEqualTo(0.01));
      expect(topLeft.dy, lessThanOrEqualTo(0.01));
      expect(bottomRight.dx, greaterThanOrEqualTo(viewport.width - 0.01));
      expect(bottomRight.dy, greaterThanOrEqualTo(viewport.height - 0.01));
    });

    test('ölçek 1 istenirse sığdır hâline döner', () {
      final m = zoomAt(
        current: Matrix4.identity()..scaleByDouble(3, 3, 3, 1),
        viewportPoint: const Offset(10, 10),
        viewport: viewport,
        scale: 1,
      );
      expect(m, Matrix4.identity());
    });

    test('YAKINKEN ikinci yakınlaştırmada da doğru nokta sabit kalır', () {
      // Önce ortadan 2,5×, sonra o hâlin bir noktasından 4×.
      final first = zoomAt(
        current: Matrix4.identity(),
        viewportPoint: const Offset(200, 400),
        viewport: viewport,
      );
      const tap = Offset(200, 400);
      final scene = MatrixUtils.transformPoint(Matrix4.inverted(first), tap);
      final second = zoomAt(
        current: first,
        viewportPoint: tap,
        viewport: viewport,
        scale: 4,
      );
      expect(second.getMaxScaleOnAxis(), closeTo(4, 0.0001));
      expect(screenOf(second, scene).dx, closeTo(tap.dx, 0.01));
      expect(screenOf(second, scene).dy, closeTo(tap.dy, 0.01));
    });
  });

  group('clampToViewport', () {
    test('kutudan KÜÇÜK içerik ortalanır', () {
      final m = clampToViewport(
        Matrix4.identity()..scaleByDouble(0.5, 0.5, 0.5, 1),
        viewport,
      );
      final translation = m.getTranslation();
      expect(translation.x, closeTo(100, 0.01)); // (400 - 200) / 2
      expect(translation.y, closeTo(200, 0.01)); // (800 - 400) / 2
    });

    test('kutudan BÜYÜK içerikte kayma sınırın içinde tutulur', () {
      final m = clampToViewport(
        Matrix4.identity()
          ..translateByDouble(500, 500, 0, 1)
          ..scaleByDouble(2, 2, 2, 1),
        viewport,
      );
      final translation = m.getTranslation();
      // Pozitif kayma sol kenarda boşluk demek: sıfıra kırpılır.
      expect(translation.x, closeTo(0, 0.01));
      expect(translation.y, closeTo(0, 0.01));
    });
  });

  group('settle', () {
    test('1 altına düşen ölçek sığdır hâline geri yaylanır', () {
      final m = settle(
        Matrix4.identity()..scaleByDouble(0.7, 0.7, 0.7, 1),
        viewport,
      );
      expect(m, Matrix4.identity());
    });

    test('yakınken yalnız kenar boşluğu kapanır, ölçek korunur', () {
      final m = settle(
        Matrix4.identity()
          ..translateByDouble(80, 0, 0, 1)
          ..scaleByDouble(2, 2, 2, 1),
        viewport,
      );
      expect(m.getMaxScaleOnAxis(), closeTo(2, 0.0001));
      expect(m.getTranslation().x, closeTo(0, 0.01));
    });
  });

  group('isZoomed', () {
    test('kimlik matrisi yakınlaşmış SAYILMAZ', () {
      expect(isZoomed(Matrix4.identity()), isFalse);
    });

    test('kılpayı büyük ölçek (yuvarlama hatası) yakın sayılmaz', () {
      expect(isZoomed(Matrix4.identity()..scaleByDouble(1.01, 1.01, 1.01, 1)),
          isFalse);
    });

    test('gerçek yakınlaştırma yakalanır', () {
      expect(
        isZoomed(Matrix4.identity()..scaleByDouble(1.5, 1.5, 1.5, 1)),
        isTrue,
      );
    });
  });
}
