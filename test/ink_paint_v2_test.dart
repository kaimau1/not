import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_stroke_paint.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F62.1 / F62.2 (B4): kalem hareketinin maliyeti sayfadaki çizgi
/// sayısından bağımsız.
List<InkStroke> _strokes(int n, {bool pressure = false}) => [
  for (var i = 0; i < n; i++)
    InkStroke(
      page: 1,
      color: 0x99000000,
      width: 0.004,
      points: [
        for (var k = 0; k < 12; k++) ...[
          (i % 40) / 50 + k * 0.004,
          (i ~/ 40) / 60 + (k.isEven ? 0.0 : 0.006),
        ],
      ],
      pressures: pressure ? [for (var k = 0; k < 12; k++) k / 11] : null,
    ),
];

void main() {
  setUp(InkToolMemory.reset);

  testWidgets('çizerken bitmiş katman boyanmaz, kalkışta bir kez boyanır', (
    tester,
  ) async {
    final ink = InkController(initial: _strokes(300), onChanged: (_) {});
    addTearDown(ink.dispose);
    ink.setEditing(true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: SizedBox(
          width: 400,
          height: 600,
          child: InkPageLayer(controller: ink, page: 1),
        ),
      ),
    );
    RenderCustomPaint layerOf<T>() => tester.renderObject<RenderCustomPaint>(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter is T),
    );
    final committed = layerOf<CommittedInkPainter>();
    final active = layerOf<ActiveInkPainter>();

    final g = await tester.startGesture(
      const Offset(200, 500),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    final rev = ink.committedRev.value;
    for (var i = 1; i <= 5; i++) {
      await g.moveTo(Offset(200 + i * 6.0, 500));
      expect(committed.debugNeedsPaint, isFalse, reason: 'hareket $i');
      expect(active.debugNeedsPaint, isTrue, reason: 'hareket $i');
      await tester.pump();
    }
    expect(ink.committedRev.value, rev);
    expect(ink.strokesOf(1), hasLength(300));

    await g.up();
    expect(ink.committedRev.value, rev + 1);
    expect(committed.debugNeedsPaint, isTrue);
    expect(ink.strokesOf(1), hasLength(301));
    await tester.pump();
  });

  test('geri al bitmiş katmanı tazeler', () {
    final ink = InkController(initial: _strokes(3), onChanged: (_) {});
    addTearDown(ink.dispose);
    final rev = ink.committedRev.value;
    ink.undo();
    expect(ink.committedRev.value, greaterThan(rev));
    expect(ink.strokesOf(1), hasLength(2));
  });

  test(
    '1500 basınçlı (saydam) çizgi: çizgi başına tek çağrı, saveLayer yok',
    () {
      final strokes = _strokes(1500, pressure: true);
      final canvas = TestRecordingCanvas();
      InkPainter(strokes, 1).paint(canvas, const Size(400, 600));
      expect(canvas.invocations.length, lessThanOrEqualTo(strokes.length + 4));
      expect(
        canvas.invocations.where((i) => i.invocation.memberName == #saveLayer),
        isEmpty,
      );
    },
  );

  test('i noktası ve basınç 0 çizgi görünür', () {
    final canvas = TestRecordingCanvas();
    InkPainter(const [
      InkStroke(
        page: 1,
        color: 0xFF000000,
        width: 0.01,
        points: [0.5, 0.5],
        pressures: [0],
      ),
      InkStroke(
        page: 1,
        color: 0xFF000000,
        width: 0.01,
        points: [0.1, 0.1, 0.2, 0.1, 0.3, 0.1],
        pressures: [0, 0, 0],
      ),
    ], 1).paint(canvas, const Size(400, 600));
    final circle = canvas.invocations.first;
    expect(circle.invocation.memberName, #drawCircle);
    // 400 × 0,01 / 2 × 0,35 — taban kalınlığın ×0,35'i.
    expect(circle.invocation.positionalArguments[1], closeTo(0.7, 1e-9));
    final path = canvas.invocations.last.invocation.positionalArguments[0];
    expect((path as Path).getBounds().height, greaterThan(1));
  });

  group('F62.5 dolma kalem', () {
    const size = Size(400, 600);
    InkStroke line(double step, {List<double>? q}) => InkStroke(
      page: 1,
      color: InkPen.fountain.apply(Colors.black).toARGB32(),
      width: 4 / 400,
      points: [
        for (var k = 0; k < 6; k++) ...[0.1 + k * step, 0.5],
      ],
      pressures: q,
    );

    test('seçilince renk 0xFE saydamlıkla yazılır, şeffaflık sabit', () {
      final ink = InkController(initial: const [], onChanged: (_) {});
      addTearDown(ink.dispose);
      ink.setOpacity(0.5);
      ink.setPen(InkPen.fountain);
      expect(inkIsFountain(ink.penColor.toARGB32()), isTrue);
      expect(InkPen.fountain.fixedOpacity, 1.0);
      expect(inkIsFountain(Colors.black.toARGB32()), isFalse);
    });

    test('hızlı çizgi yavaştan ince', () {
      final slow = fountainRadii(line(0.003), size);
      final fast = fountainRadii(line(0.03), size);
      expect(fast[3], lessThan(slow[3] * 0.7));
    });

    test('basınç eğrisi dik: ×0,2 … ×1,8', () {
      // Büyük sayfa: ince uç 0,5 px tabanına takılmasın.
      const big = Size(800, 1200);
      final light = fountainRadii(line(0.003, q: List.filled(6, 0)), big);
      final hard = fountainRadii(line(0.003, q: List.filled(6, 1)), big);
      expect(hard[3] / light[3], closeTo(9, 0.01));
    });

    test('tek çağrıyla dolgu; nokta taban yarıçapla', () {
      final canvas = TestRecordingCanvas();
      InkPainter([
        line(0.01),
        InkStroke(
          page: 1,
          color: InkPen.fountain.apply(Colors.black).toARGB32(),
          width: 4 / 400,
          points: const [0.5, 0.5],
        ),
      ], 1).paint(canvas, size);
      expect(canvas.invocations, hasLength(2));
      expect(canvas.invocations.first.invocation.memberName, #drawPath);
      final dot = canvas.invocations.last.invocation;
      expect(dot.memberName, #drawCircle);
      expect(dot.positionalArguments[1], closeTo(2, 1e-9));
    });

    test('kalkışta sadeleşmez (hız nokta aralığında)', () {
      final ink = InkController(initial: const [], onChanged: (_) {});
      addTearDown(ink.dispose);
      ink.setPen(InkPen.fountain);
      for (var k = 0; k <= 20; k++) {
        final at = Offset(40 + k * 4.0, 300);
        k == 0
            ? ink.pointerDown(1, at, size, kind: PointerDeviceKind.mouse)
            : ink.pointerMove(1, at, size);
      }
      ink.pointerUp(kind: PointerDeviceKind.mouse);
      expect(ink.ink.single.points.length, 42);
    });
  });
}
