import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_design.dart';

/// Yana çekiş karar kuralı (P62 §6.2): bütün yüzeyler aynı sayılarla.
void main() {
  group('AppSwipe.commits', () {
    test('çekiş yok / ölçü yok → geçmez', () {
      expect(AppSwipe.commits(dragged: 0, extent: 400, velocity: 900), isFalse);
      expect(AppSwipe.commits(dragged: 50, extent: 0, velocity: 0), isFalse);
    });
    test('eşik: genişliğin %22si', () {
      expect(AppSwipe.commits(dragged: 87, extent: 400, velocity: 0), isFalse);
      expect(AppSwipe.commits(dragged: -88, extent: 400, velocity: 0), isTrue);
    });
    test('fiske yalnız çekişle aynı yönde', () {
      expect(AppSwipe.commits(dragged: 10, extent: 400, velocity: 300), isTrue);
      expect(
        AppSwipe.commits(dragged: 10, extent: 400, velocity: -900),
        isFalse,
      );
      expect(
        AppSwipe.commits(dragged: 10, extent: 400, velocity: 299),
        isFalse,
      );
    });
  });

  group('AppSwipe.settleFor', () {
    test('alt ve üst sınır', () {
      expect(AppSwipe.settleFor(distance: 0), AppSwipe.settleMin);
      expect(AppSwipe.settleFor(distance: 5000), AppSwipe.settleMax);
    });
    test('kalan yolla artar, hızla kısalır', () {
      final short = AppSwipe.settleFor(distance: 150);
      final long = AppSwipe.settleFor(distance: 300);
      expect(short, lessThan(long));
      expect(AppSwipe.settleFor(distance: 300, velocity: 3000), lessThan(long));
    });
  });
}
