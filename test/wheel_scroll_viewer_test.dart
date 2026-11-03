import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/wheel_scroll_viewer.dart';

void main() {
  testWidgets('tekerlek sayfayı kaydırır, yakınlaştırmaz', (tester) async {
    final zoom = TransformationController();
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: WheelScrollViewer(
              controller: zoom,
              panEnabled: false,
              child: SingleChildScrollView(
                controller: scroll,
                child: const SizedBox(width: 200, height: 1000),
              ),
            ),
          ),
        ),
      ),
    );
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(const Offset(400, 300)));
    // Aşağı: kaydırır. Yukarı: eskiden yakınlaştırırdı (InteractiveViewer).
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, 100)));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -50)));
    await tester.pump();
    expect(zoom.value.getMaxScaleOnAxis(), 1);
    expect(scroll.offset, 50);
  });
}
