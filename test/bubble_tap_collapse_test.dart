import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';

/// Açık balon, sayfanın boşluğuna dokununca BEKLEMEDEN kapanır — alttaki
/// görüntüleyicinin çift dokunuş tanıyıcısı varken bile.
void main() {
  late int collapsed;
  late int doubleTaps;

  Future<void> pump(WidgetTester tester) async {
    collapsed = 0;
    doubleTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            // Görüntüleyici yerine: çift dokunuşla yakınlaştıran katman.
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: () => doubleTaps++,
                child: const ColoredBox(color: Colors.white),
              ),
            ),
            Positioned.fill(child: TapToCollapse(onTap: () => collapsed++)),
          ],
        ),
      ),
    );
  }

  testWidgets('tek dokunuş parmak kalkar kalkmaz kapatır', (tester) async {
    await pump(tester);
    await tester.tapAt(const Offset(200, 300));
    await tester.pump();
    expect(collapsed, 1);
    // Çift dokunuş süresi dolmadan kapanmış olmalı.
    await tester.pump(const Duration(milliseconds: 400));
    expect(collapsed, 1);
  });

  testWidgets('çift dokunuş alttaki görüntüleyiciye yine ulaşır', (
    tester,
  ) async {
    await pump(tester);
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();
    expect(doubleTaps, 1);
  });

  testWidgets('kaydırma ve basılı tutma kapatmaz', (tester) async {
    await pump(tester);
    await tester.dragFrom(const Offset(200, 300), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(collapsed, 0);
    final gesture = await tester.startGesture(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(collapsed, 0);
  });
}
