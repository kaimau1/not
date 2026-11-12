// F67.4: kısa pencere + klavye (yatay tablet 1024×640, klavye 300) iken
// editörün alt çubuğu gizlenir; uzun pencerede ve kayıt sürerken kalır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';

Future<bool> _barVisible(
  WidgetTester tester, {
  required Size size,
  required double keyboard,
  bool keep = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: KeyboardInsetScope(
        child: Column(
          children: [
            const Expanded(child: SizedBox()),
            ShortKeyboardBarHide(
              keep: keep,
              child: const SizedBox(height: 50, child: Text('bar')),
            ),
          ],
        ),
      ),
    ),
  );
  // Klavye "oturdu" (KeyboardInsetScope.settle).
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
  return find.text('bar').hitTestable().evaluate().isNotEmpty;
}

void main() {
  testWidgets('yatay tablet + klavye: alt çubuk gizli', (tester) async {
    expect(
      await _barVisible(tester, size: const Size(1024, 640), keyboard: 300),
      isFalse,
    );
  });

  testWidgets('kayıt sürerken çubuk kalır', (tester) async {
    expect(
      await _barVisible(
        tester,
        size: const Size(1024, 640),
        keyboard: 300,
        keep: true,
      ),
      isTrue,
    );
  });

  testWidgets('uzun telefon + klavye: çubuk kalır', (tester) async {
    expect(
      await _barVisible(tester, size: const Size(412, 915), keyboard: 300),
      isTrue,
    );
  });

  testWidgets('klavye yok: çubuk kalır', (tester) async {
    expect(
      await _barVisible(tester, size: const Size(1024, 640), keyboard: 0),
      isTrue,
    );
  });
}
