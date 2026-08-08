import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/slide_scroll.dart';

/// Slaytlar artik PDF gibi ALT ALTA kayiyor. Burada olculen sey liste
/// mekanigi degil, o kaydirmanin MATEMATIGI: hangi slayttayiz, "balona git"
/// nereye kaydirir, acik balon klavyenin ustunde nerede ortalanir.
void main() {
  group('SlideStripMetrics', () {
    // 400 px genislik, 16:9 slaytlar → her biri 225 px.
    SlideStripMetrics wide(int count) => SlideStripMetrics.forWidth(
      List<double>.filled(count, 16 / 9),
      400,
    );

    test('yukseklikler orandan gelir, konumlar birikimli — ARADA BOSLUK YOK', () {
      final m = wide(3);
      expect(m.heightOf(1), closeTo(225, 1e-9));
      expect(m.offsets, [0, closeTo(225, 1e-9), closeTo(450, 1e-9), closeTo(675, 1e-9)]);
      expect(m.total, closeTo(675, 1e-9));
      // Ucuncu slaydin basi, ikincinin sonuyla AYNI nokta.
      expect(m.startOf(3), m.offsets[2]);
    });

    test('oran bilinmiyorsa 16:9 varsayilir — sifira bolme yok', () {
      final m = SlideStripMetrics.forWidth([0, -1], 320);
      expect(m.heightOf(1), closeTo(180, 1e-9));
      expect(m.heightOf(2), closeTo(180, 1e-9));
    });

    test('gecerli slayt EKRANIN ORTASINDAKI slayttir', () {
      final m = wide(3);
      // Gorunur yukseklik 300: basta merkez 150 → 1. slayt.
      expect(m.pageAt(0, 300), 1);
      // 150 kaydirinca merkez 300 → 2. slayt (225..450).
      expect(m.pageAt(150, 300), 2);
      // Sona kadar: son slayt.
      expect(m.pageAt(1000, 300), 3);
    });

    test('bos sunum coken deger vermez', () {
      final m = SlideStripMetrics.forWidth(const [], 400);
      expect(m.isEmpty, isTrue);
      expect(m.pageAt(0, 300), 1);
      expect(m.heightOf(1), 0);
      expect(m.centerOffset(page: 1, y: 0.5, free: 100, maxScroll: 0), 0);
    });

    test('aralik disi slayt numarasi kistirilir — cokmek yerine ucta durur', () {
      final m = wide(2);
      expect(m.startOf(99), m.startOf(2));
      expect(m.startOf(0), m.startOf(1));
    });

    group('centerOffset', () {
      test('balonu, kartin USTUNDE kalan alanin ortasina getirir', () {
        final m = wide(3);
        // 2. slaydin ortasi: 225 + 112.5 = 337.5. Serbest alan 200 → -100.
        expect(
          m.centerOffset(page: 2, y: 0.5, free: 200, maxScroll: 1000),
          closeTo(237.5, 1e-9),
        );
      });

      test('serbest alan daralinca (klavye+kart) balon YUKARI kayar', () {
        final m = wide(3);
        final withKeyboard = m.centerOffset(
          page: 2,
          y: 0.5,
          free: 200,
          maxScroll: 1000,
        );
        final without = m.centerOffset(
          page: 2,
          y: 0.5,
          free: 500,
          maxScroll: 1000,
        );
        expect(withKeyboard, greaterThan(without));
      });

      test('kaydirma araliginin disina cikmaz', () {
        final m = wide(3);
        expect(m.centerOffset(page: 1, y: 0, free: 400, maxScroll: 675), 0);
        expect(
          m.centerOffset(page: 3, y: 1, free: 100, maxScroll: 300),
          300,
        );
      });
    });
  });
}
