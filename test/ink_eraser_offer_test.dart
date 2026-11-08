import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

/// Kullanıcı isteği 2026-11-08: parmakla çizilmiş yazının üstüne basılı
/// tutunca silgi düğmesi çıkar; dokununca silgi seçilir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const size = Size(400, 400);
  setUp(InkToolMemory.reset);

  InkController drawn() {
    final c = InkController(initial: const [], onChanged: (_) {});
    c.pointerDown(1, const Offset(100, 100), size);
    for (var x = 110.0; x <= 200; x += 10) {
      c.pointerMove(1, Offset(x, 100), size);
    }
    c.pointerUp();
    return c;
  }

  testWidgets('çizginin üstünde basılı tut → silgi önerisi → silgi', (
    tester,
  ) async {
    final c = drawn();
    expect(c.ink, hasLength(1));
    c.pointerDown(1, const Offset(150, 100), size);
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.eraserOffer.value, isNotNull);
    c.pointerUp();
    // Basışın noktası kalmadı.
    expect(c.ink, hasLength(1));
    c.acceptEraserOffer();
    expect(c.eraser, isTrue);
    expect(c.eraserOffer.value, isNull);
    c.dispose();
  });

  testWidgets('boş yerde basılı tut ya da kaydır → öneri yok', (tester) async {
    final c = drawn();
    c.pointerDown(1, const Offset(300, 300), size);
    await tester.pump(const Duration(milliseconds: 600));
    c.pointerUp();
    expect(c.eraserOffer.value, isNull);
    c.pointerDown(1, const Offset(150, 100), size);
    c.pointerMove(1, const Offset(150, 160), size);
    await tester.pump(const Duration(milliseconds: 600));
    c.pointerUp();
    expect(c.eraserOffer.value, isNull);
    expect(c.ink, hasLength(3));
    c.dispose();
  });
}
