import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/pen_stroke_preview.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_stroke_paint.dart';

/// P63 iskelet (docs/plan_tasarim_B.md §6.3): kalemin gerçek çizgi
/// önizlemesi — `paintInkStroke` ile, ekranda ne çıkacaksa o.
void main() {
  const box = Size(300, 44);
  final highlighter = InkPen.highlighter.apply(Colors.yellow).toARGB32();
  final fountain = InkPen.fountain.apply(Colors.black).toARGB32();

  Widget host(Widget child, {Size size = box}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );

  PenStrokePainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(PenStrokePreview),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as PenStrokePainter;

  test('kalınlık ekrandaki gerçek boy: widthPx / genişlik', () {
    final s = penPreviewStroke(argb: highlighter, widthPx: 22, size: box);
    expect(s.width * box.width, closeTo(22, 1e-9));
    expect(s.color, highlighter);
    for (var i = 0; i < s.points.length; i += 2) {
      final x = s.points[i] * box.width;
      expect(x - 11, greaterThanOrEqualTo(0), reason: 'uç kutudan taşmaz');
      expect(x + 11, lessThanOrEqualTo(box.width));
    }
  });

  test('compact: kalınlık kutu boyunun %45’ine kırpılır', () {
    const chip = Size(30, 30);
    final s = penPreviewStroke(
      argb: highlighter,
      widthPx: 46,
      size: chip,
      compact: true,
    );
    expect(s.width * chip.width, closeTo(30 * 0.45, 1e-9));
    final thin = penPreviewStroke(
      argb: highlighter,
      widthPx: 3,
      size: chip,
      compact: true,
    );
    expect(thin.width * chip.width, closeTo(3, 1e-9));
  });

  test('dolma kalem S eğrisinin uçlarında incelir (nokta aralığı)', () {
    final s = penPreviewStroke(argb: fountain, widthPx: 8, size: box);
    final r = fountainRadii(s, box);
    final mid = r[r.length ~/ 2];
    expect(r.first, lessThan(mid * 0.6));
    expect(r.last, lessThan(mid * 0.6));
  });

  testWidgets('fosforlu: boyanan renk alfası 0x66', (tester) async {
    await tester.pumpWidget(
      host(PenStrokePreview(argb: highlighter, widthPx: 22)),
    );
    expect(
      find.descendant(
        of: find.byType(PenStrokePreview),
        matching: find.byType(CustomPaint),
      ),
      paints..path(color: Color(highlighter)),
    );
    expect((highlighter >> 24) & 0xFF, 0x66);
  });

  testWidgets('aynı girdi → aynı InkStroke örneği; widthPx değişince yeni', (
    tester,
  ) async {
    await tester.pumpWidget(host(PenStrokePreview(argb: fountain, widthPx: 4)));
    final first = painter(tester).stroke;
    await tester.pumpWidget(host(PenStrokePreview(argb: fountain, widthPx: 4)));
    expect(identical(painter(tester).stroke, first), isTrue);
    await tester.pumpWidget(host(PenStrokePreview(argb: fountain, widthPx: 6)));
    expect(identical(painter(tester).stroke, first), isFalse);
    expect(
      find.descendant(
        of: find.byType(PenStrokePreview),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
  });
}
