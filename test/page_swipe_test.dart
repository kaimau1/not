import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/page_swipe.dart';

/// Defterde yana çekişle sayfa değiştirme (kullanıcı isteği 2026-10-20).
void main() {
  Future<List<int>> pump(WidgetTester tester) async {
    final got = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PageSwipeDetector(
          onSwipe: got.add,
          child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ),
      ),
    );
    return got;
  }

  testWidgets('hızlı sola çekiş sonraki, sağa çekiş önceki sayfa', (
    tester,
  ) async {
    final got = await pump(tester);
    await tester.flingFrom(const Offset(300, 300), const Offset(-160, 0), 1500);
    await tester.flingFrom(const Offset(100, 300), const Offset(160, 0), 1500);
    expect(got, [1, -1]);
  });

  testWidgets('dikey kaydırma ve kısa hareket sayfa çevirmez', (tester) async {
    final got = await pump(tester);
    await tester.flingFrom(
      const Offset(200, 400),
      const Offset(60, -200),
      1500,
    );
    await tester.flingFrom(const Offset(200, 300), const Offset(-30, 0), 1500);
    expect(got, isEmpty);
  });

  // U3 (kullanıcı bulgusu 2026-11-18): sayfa çevirme kaydırma, seçim ve
  // kalemle karışıyordu — ham Listener başka işin kullandığı hareketi de
  // çekiş sayıyordu.
  testWidgets('yatay kaydırılabilir kayarken sayfa çevrilmez', (tester) async {
    final got = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PageSwipeDetector(
          onSwipe: got.add,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < 20; i++)
                const SizedBox(width: 120, child: Text('hücre')),
            ],
          ),
        ),
      ),
    );
    await tester.flingFrom(const Offset(300, 300), const Offset(-160, 0), 1500);
    await tester.pumpAndSettle();
    expect(got, isEmpty);
  });

  testWidgets('kalem basılıyken avuç/parmak kayması sayfa çevirmez', (
    tester,
  ) async {
    final got = await pump(tester);
    final pen = await tester.startGesture(
      const Offset(100, 100),
      kind: PointerDeviceKind.stylus,
    );
    await tester.flingFrom(const Offset(300, 300), const Offset(-160, 0), 1500);
    await pen.up();
    expect(got, isEmpty);
    // Kalem kalkınca parmak çekişi yine çevirir.
    await tester.flingFrom(const Offset(300, 300), const Offset(-160, 0), 1500);
    expect(got, [1]);
  });

  testWidgets('seçim sürüklenirken (seçim değişti) sayfa çevrilmez', (
    tester,
  ) async {
    final got = <int>[];
    final text = TextEditingController(text: 'bir iki üç dört beş altı');
    final focus = FocusNode();
    addTearDown(text.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: PageSwipeDetector(
          onSwipe: got.add,
          child: Material(
            child: Column(
              children: [
                TextField(controller: text, focusNode: focus),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    final g = await tester.startGesture(const Offset(300, 300));
    await g.moveBy(const Offset(-80, 0));
    // Hareket sırasında seçim değişir (tutamaç/çift dokunuş sürüklemesi).
    text.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
    await g.moveBy(const Offset(-80, 0));
    await g.up();
    expect(got, isEmpty);
  });
}
