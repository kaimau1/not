import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/hold_progress_ring.dart';

/// Kullanıcı isteği 2026-11-09: jest algılandığı andan yapılana dek dolum.
void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      home: Center(
        child: HoldRingArea(
          child: SizedBox(width: 200, height: 200, child: Text('kart')),
        ),
      ),
    ),
  );

  final ring = find.byKey(const ValueKey('hold-progress-ring'));

  testWidgets('basılı tut: halka sessiz paydan sonra görünür, dolunca kalkar', (
    tester,
  ) async {
    await pump(tester);
    final g = await tester.startGesture(tester.getCenter(find.text('kart')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(ring, findsNothing, reason: 'kısa dokunuşta yanıp sönmesin');
    await tester.pump(const Duration(milliseconds: 250));
    expect(ring, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(ring, findsNothing, reason: 'jest yapıldı');
    await g.up();
  });

  testWidgets('kayınca ya da kalkınca halka gider', (tester) async {
    await pump(tester);
    final g = await tester.startGesture(tester.getCenter(find.text('kart')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(ring, findsOneWidget);
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(ring, findsNothing);
    await g.up();
    await tester.pump(const Duration(seconds: 1));
  });
}
