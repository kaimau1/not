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

  testWidgets('dolum halkası: basılı tutarken var, iş yapılınca/kayınca yok', (
    tester,
  ) async {
    final c = drawn();
    c.pointerDown(1, const Offset(150, 100), size);
    expect(c.holdProgress.value?.eraser, isTrue);
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.holdProgress.value, isNull, reason: 'öneri çıktı, halka kalkar');
    c.pointerUp();
    c.pointerDown(1, const Offset(150, 100), size);
    c.pointerMove(1, const Offset(150, 160), size);
    expect(c.holdProgress.value?.eraser, isNot(true));
    c.pointerUp();
    expect(c.holdProgress.value, isNull);
    c.dispose();
  });

  // P59 (kullanıcı 2026-11-14): silgiden kaleme dönüş zordu. Silgideyken
  // aynı hareket (kıpırdamadan basılı tut) kalem düğmesini çıkarır.
  testWidgets('silgide basılı tut → kalem önerisi → kalem; silinen geri', (
    tester,
  ) async {
    final c = drawn();
    final pen = c.pen;
    c.setEraser(true);
    c.pointerDown(1, const Offset(150, 100), size);
    expect(c.ink, isEmpty, reason: 'silgi inişte siler');
    expect(c.holdProgress.value, isNotNull);
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.penOffer.value, isNotNull);
    expect(c.ink, hasLength(1), reason: 'basılı tutuş silmez');
    c.pointerUp();
    c.acceptPenOffer();
    expect(c.eraser, isFalse);
    expect(c.pen, pen);
    expect(c.penOffer.value, isNull);
    c.dispose();
  });

  testWidgets('silgide sürükle → kalem önerisi yok, siler', (tester) async {
    final c = drawn();
    c.setEraser(true);
    c.pointerDown(1, const Offset(100, 300), size);
    c.pointerMove(1, const Offset(150, 300), size);
    await tester.pump(const Duration(milliseconds: 600));
    c.pointerUp();
    expect(c.penOffer.value, isNull);
    expect(c.eraser, isTrue);
    c.dispose();
  });
}
