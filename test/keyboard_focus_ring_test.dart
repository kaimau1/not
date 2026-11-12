import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/focus_ring.dart';

/// DENEYIM F80.3c: klavyeyle gezinirken odaklı öğede 2 dp `primary` halka;
/// dokunmatikte ve metin alanında yok.
void main() {
  Rect? ringOf(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('keyboard-focus-ring')),
    );
    return (paint.painter! as FocusRingPainter).rect.value;
  }

  Widget app() => MaterialApp(
    builder: (context, child) => KeyboardFocusRing(child: child!),
    home: Scaffold(
      body: Column(
        children: [
          TextButton(onPressed: () {}, child: const Text('bir')),
          TextButton(onPressed: () {}, child: const Text('iki')),
          const SizedBox(width: 200, child: TextField()),
        ],
      ),
    ),
  );

  tearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );

  testWidgets('Tab ile gezinince halka odaklı düğmeyi sarar', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.pumpWidget(app());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring = ringOf(tester);
    expect(ring, isNotNull);
    final button = tester.getRect(find.widgetWithText(TextButton, 'bir'));
    expect(ring!.overlaps(button), isTrue);
    // Sonraki öğeye geçince halka da geçer.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final second = tester.getRect(find.widgetWithText(TextButton, 'iki'));
    expect(ringOf(tester)!.center.dy, closeTo(second.center.dy, 4));
  });

  testWidgets('metin alanında halka yok (imleç gösterir)', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.pumpWidget(app());
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(ringOf(tester), isNull);
  });

  testWidgets('dokunmatik kipte halka çizilmez', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    await tester.pumpWidget(app());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(ringOf(tester), isNull);
  });
}
