import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_side.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-11-09: tablet/web'de sabit ek solda ya da sağda; ayraç sürüklenince
/// genişlik değişir ve saklanır.
void main() {
  tearDown(PinnedSideMemory.reset);

  Future<void> pump(WidgetTester tester, PinnedSide side) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinnedSideLayout(
            side: side,
            media: const ColoredBox(key: ValueKey('m'), color: Colors.red),
            body: const ColoredBox(key: ValueKey('b'), color: Colors.blue),
          ),
        ),
      ),
    );
  }

  testWidgets('solda: medya solda yarı genişlik, ayraçla genişler', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    PinnedSideMemory.attach(await SharedPreferences.getInstance());
    await pump(tester, PinnedSide.left);
    final media = tester.getRect(find.byKey(const ValueKey('m')));
    final body = tester.getRect(find.byKey(const ValueKey('b')));
    expect(media.left, 0);
    expect(media.width, closeTo(600, 1));
    expect(body.left, greaterThan(media.right));
    await tester.drag(
      find.byKey(const ValueKey('pinned-side-divider')),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    expect(PinnedSideMemory.fraction, closeTo(0.6, 0.02));
    expect(
      tester.getRect(find.byKey(const ValueKey('m'))).width,
      closeTo(720, 20),
    );
  });

  testWidgets('sağda: medya sağda', (tester) async {
    await pump(tester, PinnedSide.right);
    final media = tester.getRect(find.byKey(const ValueKey('m')));
    expect(media.right, 1200);
  });

  test('sıra üst → sol → sağ → üst', () {
    expect(PinnedSideMemory.next(PinnedSide.top), PinnedSide.left);
    expect(PinnedSideMemory.next(PinnedSide.left), PinnedSide.right);
    expect(PinnedSideMemory.next(PinnedSide.right), PinnedSide.top);
  });
}
