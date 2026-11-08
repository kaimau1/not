import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/pen_icons.dart';
import 'package:notlar/features/notes/presentation/editor/pen_tray.dart';

void main() {
  testWidgets('PenToolPainter her araç için çizer', (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              for (final t in PenTrayTool.values)
                SizedBox(
                  width: 44,
                  height: 96,
                  child: CustomPaint(
                    painter: PenToolPainter(
                      tool: t,
                      ink: const Color(0xFFFFFFFF),
                      dark: dark,
                      lifted: t.index.isEven,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    expect(tester.takeException(), isNull);
  });
}
