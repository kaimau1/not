import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

/// F61.2: serbest çizgi kalkışta sadeleşir; kaydedilen çizgi de sadeleşmiş.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(InkToolMemory.reset);
  const size = Size(400, 400);

  test('düz serbest çizgi kalkışta iki noktaya iner, kayıt da öyle', () {
    var saved = 0;
    final c = InkController(
      initial: const [],
      onChanged: (ink) => saved = ink.isEmpty ? 0 : ink.single.points.length,
    )..shapeSnap = false;
    c.pointerDown(1, const Offset(50, 100), size, pointer: 1);
    for (var i = 1; i <= 50; i++) {
      c.pointerMove(1, Offset(50 + i * 4.0, 100), size, pointer: 1);
    }
    c.pointerUp(pointer: 1);
    expect(c.ink.single.points.length, 4);
    expect(c.ink.single.points.first, closeTo(50 / 400, 1e-6));
    expect(c.ink.single.points[2], closeTo(250 / 400, 1e-6));
    expect(saved, 4);
    // Geri al: çizgi tamamen gider (ara sadeleşmiş adım geçmişe girmez).
    c.undo();
    expect(c.ink, isEmpty);
    c.dispose();
  });
}
