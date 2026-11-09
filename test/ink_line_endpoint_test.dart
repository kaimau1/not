import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

/// F55.2 (2026-11-09): uçta bekleyip düz çizgiye oturan çizginin ucu, kalem
/// kalkana dek kalemi izler; başlangıç ucu yerinde kalır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const size = Size(400, 400);
  setUp(InkToolMemory.reset);

  testWidgets('düz çizgiye oturunca uç kalemle taşınır', (tester) async {
    final c = InkController(initial: const [], onChanged: (_) {});
    c.pointerDown(1, const Offset(50, 300), size);
    for (var x = 60.0; x <= 250; x += 10) {
      c.pointerMove(1, Offset(x, 300 + (x % 20 == 0 ? 1 : -1)), size);
    }
    await tester.pump(kInkHoldDuration + const Duration(milliseconds: 100));
    final snapped = c.ink.single;
    expect(snapped.points, hasLength(4), reason: 'düz çizgiye oturdu');

    c.pointerMove(1, const Offset(300, 200), size);
    final moved = c.ink.single;
    expect(moved.points, hasLength(4));
    // Başlangıç ucu yerinde, öbür uç kalemin yerinde.
    expect(moved.points[0], closeTo(50 / 400, 0.02));
    expect(moved.points[1], closeTo(300 / 400, 0.02));
    expect(moved.points[2], closeTo(300 / 400, 1e-9));
    expect(moved.points[3], closeTo(200 / 400, 1e-9));
    c.pointerUp();
    expect(c.ink.single.points, hasLength(4));

    // Yeni çizgi eski davranışla başlar (ucu izleme bitti).
    c.pointerDown(1, const Offset(100, 50), size);
    c.pointerMove(1, const Offset(120, 60), size);
    c.pointerMove(1, const Offset(140, 50), size);
    expect(c.ink.last.points.length, greaterThan(4));
    c.pointerUp();
    c.dispose();
  });
}
