import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_recognize.dart';

/// [a]'dan [b]'ye [n] ara noktalı doğru; [wobble] küçük el titremesi.
List<Offset> seg(Offset a, Offset b, {int n = 12, double wobble = 0}) => [
  for (var i = 0; i <= n; i++)
    Offset.lerp(a, b, i / n)! +
        Offset(0, wobble * math.sin(i * 1.7)) +
        Offset(wobble * math.cos(i * 2.3), 0),
];

List<Offset> poly(List<Offset> corners, {double wobble = 0}) => [
  for (var i = 0; i + 1 < corners.length; i++)
    ...seg(corners[i], corners[i + 1], wobble: wobble).skip(i == 0 ? 0 : 1),
];

List<Offset> ellipse(Offset c, double rx, double ry, {double wobble = 0}) => [
  for (var i = 0; i <= 60; i++)
    c +
        Offset(
          (rx + wobble * math.sin(i * 0.9)) * math.cos(2 * math.pi * i / 60),
          (ry + wobble * math.cos(i * 1.3)) * math.sin(2 * math.pi * i / 60),
        ),
];

void main() {
  test('kabaca daire → elips', () {
    final fix = recognizeInkFix(
      ellipse(const Offset(200, 200), 60, 55, wobble: 2),
    );
    expect(fix?.kind, InkFixKind.ellipse);
    expect(fix!.strokes.single.arrow, isFalse);
  });

  test('kabaca dikdörtgen', () {
    final fix = recognizeInkFix(
      poly(const [
        Offset(100, 100),
        Offset(260, 102),
        Offset(258, 200),
        Offset(101, 198),
        Offset(100, 101),
      ], wobble: 1.5),
    );
    expect(fix?.kind, InkFixKind.rectangle);
  });

  test('üçgen (köşeden ya da kenar ortasından başlayınca)', () {
    const a = Offset(150, 60), b = Offset(240, 220), c = Offset(60, 220);
    expect(
      recognizeInkFix(poly(const [a, b, c, a], wobble: 1.5))?.kind,
      InkFixKind.triangle,
    );
    final mid = Offset.lerp(a, b, 0.5)!;
    final fromMid = recognizeInkFix(poly([mid, b, c, a, mid], wobble: 1));
    expect(fromMid?.kind, InkFixKind.triangle);
    expect(fromMid!.strokes.single.points, hasLength(4));
  });

  test('düz çizgi', () {
    final fix = recognizeInkFix(
      seg(const Offset(20, 100), const Offset(260, 108), wobble: 1.5),
    );
    expect(fix?.kind, InkFixKind.line);
    expect(fix!.strokes.single.points, hasLength(2));
  });

  test('tek çizgide ok: gövde + iki kanat', () {
    const a = Offset(40, 200), b = Offset(240, 200);
    final fix = recognizeInkFix(
      poly(const [a, b, Offset(210, 180), b, Offset(210, 222)]),
    );
    expect(fix?.kind, InkFixKind.arrow);
    expect(fix!.strokes.single.arrow, isTrue);
    expect(fix.strokes.single.points.last.dx, closeTo(240, 6));
  });

  test('iki çizgide ok: önce gövde sonra ^', () {
    final shaft = seg(const Offset(40, 300), const Offset(240, 200));
    final head = poly(const [
      Offset(205, 200),
      Offset(240, 199),
      Offset(222, 232),
    ]);
    final fix = recognizeInkFix(head, previous: shaft);
    expect(fix?.kind, InkFixKind.arrow);
    expect(fix!.usesPrevious, isTrue);
    expect(fix.strokes.single.points.first.dx, closeTo(40, 1));
  });

  test('tik: kısa kol aşağı, uzun kol yukarı', () {
    final fix = recognizeInkFix(
      poly(const [Offset(100, 120), Offset(115, 140), Offset(150, 90)]),
    );
    expect(fix?.kind, InkFixKind.tick);
    expect(fix!.isMark, isTrue);
  });

  test('simetrik v harfi tik değil', () {
    final fix = recognizeInkFix(
      poly(const [Offset(100, 100), Offset(115, 130), Offset(130, 100)]),
    );
    expect(fix?.kind, isNot(InkFixKind.tick));
  });

  test('çarpı: iki çapraz kol; artı işareti çarpı sayılmaz', () {
    final first = seg(const Offset(100, 100), const Offset(130, 132));
    final second = seg(const Offset(131, 99), const Offset(99, 131));
    final fix = recognizeInkFix(second, previous: first);
    expect(fix?.kind, InkFixKind.cross);
    expect(fix!.strokes, hasLength(2));
    expect(fix.usesPrevious, isTrue);

    final plusA = seg(const Offset(100, 115), const Offset(132, 115));
    final plusB = seg(const Offset(116, 99), const Offset(116, 131));
    expect(
      recognizeInkFix(plusB, previous: plusA)?.kind,
      isNot(InkFixKind.cross),
    );
  });

  test('ayar kapalıyken tik/çarpı önerilmez', () {
    final first = seg(const Offset(100, 100), const Offset(130, 132));
    final second = seg(const Offset(131, 99), const Offset(99, 131));
    expect(
      recognizeInkFix(second, previous: first, marks: false)?.kind,
      isNot(InkFixKind.cross),
    );
  });

  test('küçük harf boyu ve karalama şekil sayılmaz', () {
    // "l" harfi: 20 dp düz çizgi.
    expect(
      recognizeInkFix(seg(const Offset(10, 10), const Offset(12, 30))),
      isNull,
    );
    final rnd = math.Random(3);
    final scribble = [
      for (var i = 0; i < 80; i++)
        Offset(100 + rnd.nextDouble() * 120, 100 + rnd.nextDouble() * 120),
    ];
    expect(recognizeInkFix(scribble, marks: false), isNull);
  });

  group('kapalı şekil (2026-11-08)', () {
    test('köşeleri yuvarlak elle çizilmiş kare → KARE (çember değil)', () {
      // Köşeleri 12 dp yuvarlatılmış 140'lık kare + titreme.
      final pts = <Offset>[];
      const r = 14.0, s0 = 100.0, s1 = 240.0;
      void arc(Offset c, double from) {
        for (var i = 0; i <= 6; i++) {
          final a = from + (math.pi / 2) * i / 6;
          pts.add(c + Offset(r * math.cos(a), r * math.sin(a)));
        }
      }
      pts.addAll(seg(const Offset(s0 + r, s0), const Offset(s1 - r, s0), wobble: 1.5));
      arc(const Offset(s1 - r, s0 + r), -math.pi / 2);
      pts.addAll(seg(const Offset(s1, s0 + r), const Offset(s1, s1 - r), wobble: 1.5));
      arc(const Offset(s1 - r, s1 - r), 0);
      pts.addAll(seg(const Offset(s1 - r, s1), const Offset(s0 + r, s1), wobble: 1.5));
      arc(const Offset(s0 + r, s1 - r), math.pi / 2);
      pts.addAll(seg(const Offset(s0, s1 - r), const Offset(s0, s0 + r), wobble: 1.5));
      arc(const Offset(s0 + r, s0 + r), math.pi);
      final shape = recognizeClosedShape(pts);
      expect(shape?.kind, InkFixKind.rectangle);
      expect(shape!.regular, isTrue, reason: 'en/boy ≈ 1 → kare');
    });

    test('eğik dikdörtgen tanınır, eğimi korunur', () {
      Offset rot(Offset p) {
        const a = 0.5; // ~29°
        final c = math.cos(a), s = math.sin(a);
        final q = p - const Offset(200, 200);
        return const Offset(200, 200) +
            Offset(q.dx * c - q.dy * s, q.dx * s + q.dy * c);
      }
      final pts = poly([
        rot(const Offset(100, 150)),
        rot(const Offset(300, 150)),
        rot(const Offset(300, 250)),
        rot(const Offset(100, 250)),
        rot(const Offset(100, 151)),
      ], wobble: 1.5);
      final shape = recognizeClosedShape(pts);
      expect(shape?.kind, InkFixKind.rectangle);
      expect(shape!.regular, isFalse);
    });

    test('kabaca daire → düzgün daire; belirgin elips → elips', () {
      final circle = recognizeClosedShape(
        ellipse(const Offset(200, 200), 60, 54, wobble: 2),
      );
      expect(circle?.kind, InkFixKind.ellipse);
      expect(circle!.regular, isTrue);
      final oval = recognizeClosedShape(
        ellipse(const Offset(200, 200), 100, 50, wobble: 2),
      );
      expect(oval?.kind, InkFixKind.ellipse);
      expect(oval!.regular, isFalse);
    });

    test('yamuk → serbest dörtgen', () {
      final shape = recognizeClosedShape(
        poly(const [
          Offset(140, 100),
          Offset(260, 100),
          Offset(320, 220),
          Offset(80, 220),
          Offset(140, 101),
        ], wobble: 1),
      );
      expect(shape?.kind, InkFixKind.quad);
    });

    test('üçgen', () {
      final shape = recognizeClosedShape(
        poly(const [
          Offset(150, 60),
          Offset(250, 230),
          Offset(50, 228),
          Offset(150, 62),
        ], wobble: 1.5),
      );
      expect(shape?.kind, InkFixKind.triangle);
    });

    // F55.3 (2026-11-09): 5–7 köşe düzgün çokgen daire sanılmamalı.
    List<Offset> ngon(int k, double r, {double rot = 0, double wobble = 1.5}) {
      const c = Offset(200, 200);
      final corners = [
        for (var i = 0; i <= k; i++)
          c +
              Offset(
                r * math.cos(rot + 2 * math.pi * i / k),
                r * math.sin(rot + 2 * math.pi * i / k),
              ),
      ];
      return poly(corners, wobble: wobble);
    }

    for (final k in [5, 6, 7]) {
      test('$k köşe düzgün çokgen → çokgen ($k köşe)', () {
        final shape = recognizeClosedShape(ngon(k, 90, rot: 0.2));
        expect(shape?.kind, InkFixKind.polygon, reason: '$k-gen');
        expect(shape!.outline, hasLength(k + 1));
      });
    }

    test('daire çokgen sanılmaz; kare ve üçgen bozulmaz', () {
      for (final w in [1.0, 2.0, 4.0]) {
        expect(
          recognizeClosedShape(
            ellipse(const Offset(200, 200), 80, 76, wobble: w),
          )?.kind,
          InkFixKind.ellipse,
          reason: 'titreme $w',
        );
      }
      expect(recognizeClosedShape(ngon(4, 90, rot: 0.785))?.kind,
          InkFixKind.rectangle);
      expect(recognizeClosedShape(ngon(3, 90, rot: -1.57))?.kind,
          InkFixKind.triangle);
    });
  });
}
