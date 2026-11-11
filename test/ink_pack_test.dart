import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/firestore_size.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/ink_pack.dart';

/// Gerçekçi el yazısı: küçük adımlarla kıvrılan çizgi.
InkStroke _hand(int n, {int seed = 1, bool pressure = true, double y0 = 0.3}) {
  final rnd = Random(seed);
  final pts = <double>[];
  final q = <double>[];
  var x = 0.2, y = y0, a = 0.0;
  for (var i = 0; i < n; i++) {
    a += (rnd.nextDouble() - 0.5) * 0.6;
    x += cos(a) * 0.0012;
    y += sin(a) * 0.0012;
    pts
      ..add(x)
      ..add(y);
    q.add(0.3 + 0.4 * rnd.nextDouble());
  }
  return InkStroke(
    page: 1,
    color: 0xFF112233,
    width: 0.004,
    points: pts,
    pressures: pressure ? q : null,
  );
}

void _expectSame(InkStroke a, InkStroke b) {
  expect(b.page, a.page);
  expect(b.color, a.color);
  expect(b.width, closeTo(a.width, 1e-7));
  expect(b.arrow, a.arrow);
  expect(b.points.length, a.points.length);
  for (var i = 0; i < a.points.length; i++) {
    expect((b.points[i] - a.points[i]).abs(), lessThanOrEqualTo(kInkUnit));
  }
  expect(b.hasPressure, a.hasPressure);
  if (a.hasPressure) {
    for (var i = 0; i < a.pressures!.length; i++) {
      expect((b.pressures![i] - a.pressures![i]).abs(), lessThan(1 / 255));
    }
  }
}

void main() {
  test('F61.0(a): bugünkü harita 1000 basınçlı noktada ≈ 24 KB', () {
    final bytes = estimateValueBytes(_hand(1000).toMap());
    // 2000 koordinat × 8 + 1000 basınç × 8 + üst alanlar.
    expect(bytes, inInclusiveRange(24000, 24200));
  });

  test('gidiş-dönüş: boş paket', () {
    final r = decodeInkPack(encodeInkPack(const []));
    expect(r.strokes, isEmpty);
    expect(r.z, isEmpty);
  });

  test('gidiş-dönüş: çeşitli çizgiler + z', () {
    final strokes = [
      const InkStroke(
        page: 1,
        color: 0xFF000000,
        width: 0.003,
        points: [0.5, 0.5],
      ),
      const InkStroke(
        page: 2,
        color: 0xFFFF0000,
        width: 0.01,
        points: [0.1, 0.1, 0.9, 0.9],
        arrow: true,
      ),
      // Şekil (kapalı dikdörtgen).
      const InkStroke(
        page: 1,
        color: 0xFF00FF00,
        width: 0.005,
        points: [0.1, 0.1, 0.4, 0.1, 0.4, 0.3, 0.1, 0.3, 0.1, 0.1],
      ),
      _hand(300),
      // Saydam (fosforlu).
      _hand(50, seed: 3, pressure: false).copyWith(),
      InkStroke(
        page: 1,
        color: 0x55FFFF00,
        width: 0.02,
        points: _hand(40, seed: 4).points,
      ),
      // Uzun sayfa: y > 1.
      _hand(200, seed: 5, y0: 7.5),
    ];
    final z = [for (var i = 0; i < strokes.length; i++) i * 1.5 - 2];
    final r = decodeInkPack(encodeInkPack(strokes, z: z));
    expect(r.z, z);
    expect(r.strokes.length, strokes.length);
    for (var i = 0; i < strokes.length; i++) {
      _expectSame(strokes[i], r.strokes[i]);
    }
    expect(r.strokes.first.points, isA<Float32List>());
  });

  test('gidiş-dönüş: 5000 çizgi', () {
    final strokes = [for (var i = 0; i < 5000; i++) _hand(20, seed: i)];
    final r = decodeInkPack(encodeInkPack(strokes));
    expect(r.strokes.length, 5000);
    _expectSame(strokes[4999], r.strokes[4999]);
    expect(r.z.last, 4999);
  });

  test('boyut: 1000 basınçlı nokta ≤ 4500 bayt', () {
    expect(encodeInkPack([_hand(1000)]).length, lessThanOrEqualTo(4500));
  });

  test('bozuk / kısa girdi FormatException, çökme yok', () {
    final good = encodeInkPack([_hand(100)]);
    expect(() => decodeInkPack(Uint8List(0)), throwsFormatException);
    expect(
      () => decodeInkPack(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
    for (final cut in [3, 4, 10, 30, good.length - 1]) {
      expect(
        () => decodeInkPack(Uint8List.sublistView(good, 0, cut)),
        throwsFormatException,
      );
    }
    // Rastgele çöp: yalnız FormatException.
    final rnd = Random(9);
    for (var t = 0; t < 200; t++) {
      final junk = Uint8List.fromList([
        0x49,
        0x4B,
        1,
        for (var i = 0; i < 40; i++) rnd.nextInt(256),
      ]);
      try {
        decodeInkPack(junk);
      } on FormatException {
        // beklenen
      }
    }
  });

  test('bilinmeyen sürüm baytı FormatException', () {
    final b = Uint8List.fromList(encodeInkPack([_hand(5)]));
    b[2] = 2;
    expect(() => decodeInkPack(b), throwsFormatException);
  });

  group('simplifyStroke (F61.2)', () {
    double segDist(
      double px,
      double py,
      double ax,
      double ay,
      double bx,
      double by,
    ) {
      final dx = bx - ax, dy = by - ay;
      final l2 = dx * dx + dy * dy;
      final t = l2 == 0
          ? 0.0
          : (((px - ax) * dx + (py - ay) * dy) / l2).clamp(0.0, 1.0);
      final ex = px - ax - t * dx, ey = py - ay - t * dy;
      return sqrt(ex * ex + ey * ey);
    }

    test('en büyük sapma ≤ tolerans, el yazısında ≥ %40 azalma', () {
      const tol = 0.0004;
      final s = _hand(600, seed: 7);
      final r = simplifyStroke(s.points, tol, pressures: s.pressures);
      final n = s.points.length ~/ 2, m = r.points.length ~/ 2;
      expect(m, lessThanOrEqualTo((n * 0.6).floor()));
      expect(r.pressures!.length, m);
      // İlk / son nokta korunur.
      expect(r.points[0], closeTo(s.points[0], 1e-6));
      expect(r.points[2 * m - 1], closeTo(s.points[2 * n - 1], 1e-6));
      // Her özgün nokta sadeleşmiş çizgiye ≤ tol.
      for (var i = 0; i < n; i++) {
        var best = double.infinity;
        for (var k = 0; k + 1 < m; k++) {
          best = min(
            best,
            segDist(
              s.points[2 * i],
              s.points[2 * i + 1],
              r.points[2 * k],
              r.points[2 * k + 1],
              r.points[2 * k + 2],
              r.points[2 * k + 3],
            ),
          );
        }
        expect(best, lessThanOrEqualTo(tol + 1e-6));
      }
    });

    test('tek nokta ve 2 noktalı çizgi dokunulmaz', () {
      const one = [0.5, 0.5];
      const two = [0.1, 0.1, 0.2, 0.2];
      expect(identical(simplifyStroke(one, 0.0004).points, one), isTrue);
      expect(identical(simplifyStroke(two, 0.0004).points, two), isTrue);
    });
  });
}
