import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

/// Kalem kipinin Samsung Notes benzeri araçları (kullanıcı isteği 2026-10-30:
/// "kalem modu üzerine çalış, Samsung S Note gibi özelliklerimiz olsun"):
/// basılı tutunca şekle dönüştürme, kement ile seç/taşı/boya/sil, kısmi
/// silgi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const size = Size(400, 400);

  setUp(InkToolMemory.reset);

  InkController controller({List<InkStroke> initial = const []}) =>
      InkController(initial: initial, onChanged: (_) {});

  List<Offset> circle(Offset c, double r, {int n = 40, double wobble = 0}) => [
    for (var i = 0; i <= n; i++)
      c +
          Offset(math.cos(2 * math.pi * i / n), math.sin(2 * math.pi * i / n)) *
              (r + (i.isEven ? wobble : -wobble)),
  ];

  group('şekil tanıma', () {
    test('titrek düz çizgi DÜZ ÇİZGİ olur', () {
      final pts = [
        for (var i = 0; i <= 20; i++)
          Offset(10.0 + i * 10, 50 + (i.isEven ? 2 : -2)),
      ];
      expect(recognizeInkShape(pts)?.shape, InkShape.line);
    });

    test('elle çizilmiş daire ELİPS olur', () {
      final found = recognizeInkShape(
        circle(const Offset(200, 200), 80, wobble: 3),
      );
      expect(found?.shape, InkShape.ellipse);
    });

    test('elle çizilmiş kare DİKDÖRTGEN olur', () {
      final pts = <Offset>[
        for (var i = 0; i <= 10; i++) Offset(100.0 + i * 10, 100),
        for (var i = 0; i <= 10; i++) Offset(200, 100.0 + i * 10),
        for (var i = 0; i <= 10; i++) Offset(200.0 - i * 10, 200),
        for (var i = 0; i <= 10; i++) Offset(100, 200.0 - i * 10),
      ];
      expect(recognizeInkShape(pts)?.shape, InkShape.rectangle);
    });

    test('karalama tanınmaz', () {
      final pts = [
        for (var i = 0; i < 30; i++)
          Offset(100.0 + (i * 37) % 90, 100.0 + (i * 53) % 70),
      ];
      expect(recognizeInkShape(pts), isNull);
    });

    testWidgets('kalem çizginin sonunda durunca çizgi şekle oturur', (
      tester,
    ) async {
      {
        final c = controller();
        final pts = circle(const Offset(200, 200), 80);
        c.pointerDown(1, pts.first, size);
        for (final p in pts.skip(1)) {
          c.pointerMove(1, p, size);
        }
        await tester.pump(const Duration(milliseconds: 700));
        c.pointerUp();
        // Elips 49 noktayla kurulur (bkz. inkShapePoints).
        expect(c.ink.single.points, hasLength(98));
      }
    });

    testWidgets('kapalıyken şekle oturmaz', (tester) async {
      {
        final c = controller()..setShapeSnap(false);
        final pts = circle(const Offset(200, 200), 80);
        c.pointerDown(1, pts.first, size);
        for (final p in pts.skip(1)) {
          c.pointerMove(1, p, size);
        }
        await tester.pump(const Duration(milliseconds: 700));
        c.pointerUp();
        expect(c.ink.single.points.length, isNot(98));
      }
    });
  });

  InkStroke stroke(double x1, double y1, double x2, double y2) => InkStroke(
    page: 1,
    color: 0xFF000000,
    width: 0.005,
    points: [
      for (var i = 0; i <= 10; i++) ...[
        x1 + (x2 - x1) * i / 10,
        y1 + (y2 - y1) * i / 10,
      ],
    ],
  );

  void drawLasso(InkController c, List<Offset> loop) {
    c.pointerDown(1, loop.first, size);
    for (final p in loop.skip(1)) {
      c.pointerMove(1, p, size);
    }
    c.pointerUp();
  }

  group('kement', () {
    test('çevresi çizilen çizgi seçilir, dışındaki seçilmez', () {
      final inside = stroke(0.2, 0.2, 0.3, 0.3);
      final outside = stroke(0.7, 0.7, 0.8, 0.8);
      final c = controller(initial: [inside, outside])..setLasso(true);
      drawLasso(c, circle(const Offset(100, 100), 60));
      expect(c.selected, [inside]);
    });

    test('seçimin içinden sürüklemek TAŞIR, geri al geri getirir', () {
      final s = stroke(0.2, 0.2, 0.3, 0.3);
      final c = controller(initial: [s])..setLasso(true);
      drawLasso(c, circle(const Offset(100, 100), 60));
      c
        ..pointerDown(1, const Offset(100, 100), size)
        ..pointerMove(1, const Offset(140, 120), size)
        ..pointerUp();
      expect(c.ink.single.points.first, closeTo(0.3, 1e-6));
      expect(c.ink.single.points[1], closeTo(0.25, 1e-6));
      c.undo();
      expect(c.ink.single.points.first, closeTo(0.2, 1e-6));
    });

    test('renk seçmek seçimi boyar, Sil siler', () {
      final s = stroke(0.2, 0.2, 0.3, 0.3);
      final other = stroke(0.7, 0.7, 0.8, 0.8);
      final c = controller(initial: [s, other])..setLasso(true);
      drawLasso(c, circle(const Offset(100, 100), 60));
      c.setColor(const Color(0xFFD32F2F));
      expect(c.ink.first.color, 0xFFD32F2F);
      expect(c.ink.last.color, 0xFF000000);
      c.deleteSelection();
      expect(c.ink, [other]);
    });

    test('başka araca geçmek seçimi bırakır', () {
      final c = controller(initial: [stroke(0.2, 0.2, 0.3, 0.3)])
        ..setLasso(true);
      drawLasso(c, circle(const Offset(100, 100), 60));
      expect(c.hasSelection, isTrue);
      c.setEraser(true);
      expect(c.lasso, isFalse);
      expect(c.hasSelection, isFalse);
    });
  });

  group('kısmi silgi', () {
    test('çizgi yalnız değilen yerden bölünür', () {
      final c = controller(initial: [stroke(0.1, 0.5, 0.9, 0.5)])
        ..setPartialEraser(true)
        ..setEraser(true);
      c
        ..pointerDown(1, const Offset(200, 200), size)
        ..pointerUp();
      expect(c.ink, hasLength(2), reason: 'ortadan kesilen çizgi iki parça');
    });

    test('kapalıyken bütün çizgi silinir', () {
      final c = controller(initial: [stroke(0.1, 0.5, 0.9, 0.5)])
        ..setEraser(true);
      c
        ..pointerDown(1, const Offset(200, 200), size)
        ..pointerUp();
      expect(c.ink, isEmpty);
    });
  });
}
