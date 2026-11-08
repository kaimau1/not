import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/presentation/pinch_zoom.dart';

void main() {
  Future<List<ZoomDirection>> wheel(
    WidgetTester tester, {
    required bool enabled,
    required double dy,
  }) async {
    final fired = <ZoomDirection>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PinchZoomDetector(
          wheelZoom: enabled,
          onZoom: (d, _) => fired.add(d),
          child: const SizedBox.expand(),
        ),
      ),
    );
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 100)));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
    await tester.pump(const Duration(milliseconds: 400));
    return fired;
  }

  testWidgets('düz tekerlek yukarı yakınlaşır, aşağı uzaklaşır', (t) async {
    expect(await wheel(t, enabled: true, dy: -100), [ZoomDirection.zoomIn]);
    expect(await wheel(t, enabled: true, dy: 100), [ZoomDirection.zoomOut]);
  });

  testWidgets('wheelZoom kapalıyken düz tekerlek geçiş yapmaz', (t) async {
    expect(await wheel(t, enabled: false, dy: -100), isEmpty);
  });
}
