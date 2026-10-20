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
}
