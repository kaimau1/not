import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// K34 — parmağa ayrı araç (F63.6): Kaydırır / Çizer / Siler. Siler var olan
/// geçici silgi yolunu kullanır; avuç ve iki parmak silineni geri getirir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const size = Size(200, 400);
  const mouse = PointerDeviceKind.mouse;
  const stylus = PointerDeviceKind.stylus;

  setUp(InkToolMemory.reset);

  InkController controller() =>
      InkController(initial: const [], onChanged: (_) {});

  /// Fareyle (avuç penceresi açmadan) (20,20)→(180,20) yatay çizgi.
  void line(InkController c, {int pointer = 90, double y = 20}) => c
    ..pointerDown(1, Offset(20, y), size, pointer: pointer, kind: mouse)
    ..pointerMove(1, Offset(100, y), size, pointer: pointer)
    ..pointerMove(1, Offset(180, y), size, pointer: pointer)
    ..pointerUp(pointer: pointer, kind: mouse);

  /// Parmakla çizginin üstünden dikey geçiş (silerse siler).
  void fingerAcross(InkController c, {int pointer = 1}) => c
    ..pointerDown(1, const Offset(100, 5), size, pointer: pointer)
    ..pointerMove(1, const Offset(100, 20), size, pointer: pointer)
    ..pointerMove(1, const Offset(100, 40), size, pointer: pointer);

  test('Siler: parmak siler, iz bırakmaz; tek geri al adımı', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    line(c);
    expect(c.ink, hasLength(1));
    fingerAcross(c);
    c.pointerUp(pointer: 1);
    expect(c.ink, isEmpty);
    c.undo();
    expect(c.ink, hasLength(1));
  });

  test('Siler: kalem/fare çizer (aracı kalemde kalır)', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    line(c);
    line(c, y: 200);
    expect(c.ink, hasLength(2));
  });

  test('Çizer: parmak çizer; Kaydırır: parmak ne çizer ne siler', () {
    final c = controller()..setFingerTool(FingerTool.draw);
    c
      ..pointerDown(1, const Offset(10, 300), size, pointer: 1)
      ..pointerMove(1, const Offset(60, 350), size, pointer: 1)
      ..pointerUp(pointer: 1);
    expect(c.ink, hasLength(1));
    c.setFingerTool(FingerTool.scroll);
    line(c);
    fingerAcross(c, pointer: 2);
    c.pointerUp(pointer: 2);
    expect(c.ink, hasLength(2));
    expect(c.penOnly, isTrue);
  });

  test('ikinci parmak (yakınlaştırma) silineni geri getirir', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    line(c);
    fingerAcross(c);
    expect(c.ink, isEmpty);
    c.pointerDown(1, const Offset(150, 300), size, pointer: 2);
    expect(c.ink, hasLength(1));
    // Kalan parmak artık silmez.
    c
      ..pointerUp(pointer: 2)
      ..pointerMove(1, const Offset(100, 21), size, pointer: 1)
      ..pointerUp(pointer: 1);
    expect(c.ink, hasLength(1));
    expect(c.canRedo, isFalse);
  });

  test('beginNav (iki parmak gezinme) silineni geri getirir', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    line(c);
    fingerAcross(c);
    c.beginNav();
    expect(c.ink, hasLength(1));
    c
      ..endNav()
      ..pointerUp(pointer: 1);
    expect(c.ink, hasLength(1));
  });

  test('sistem iptali (Android avuç) geri getirir', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    line(c);
    fingerAcross(c);
    c.pointerCancel(pointer: 1);
    expect(c.ink, hasLength(1));
  });

  test('parmak sildikten sonra kalem inince çizgi geri gelir (avuç)', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    line(c);
    fingerAcross(c);
    expect(c.ink, isEmpty);
    c.pointerDown(1, const Offset(20, 300), size, pointer: 3, kind: stylus);
    // Geri gelen çizgi + kalemin yeni başlattığı çizgi.
    expect(c.ink, hasLength(2));
  });

  test('kalem ekrandayken parmak silmez', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    line(c);
    c.pointerDown(1, const Offset(20, 300), size, pointer: 3, kind: stylus);
    fingerAcross(c);
    // Çizgi + kalemin başlattığı çizgi; parmak hiçbirini silmedi.
    expect(c.ink, hasLength(2));
  });

  test(
    'geniş temas (avuç yarıçapı) silmez; bildirilmeyen yarıçap süzülmez',
    () {
      final c = controller()..setFingerTool(FingerTool.erase);
      line(c);
      c
        ..pointerDown(
          1,
          const Offset(100, 20),
          size,
          pointer: 1,
          touchRadius: InkController.kFingerEraserPalmRadius + 10,
        )
        ..pointerMove(1, const Offset(100, 22), size, pointer: 1)
        ..pointerUp(pointer: 1);
      expect(c.ink, hasLength(1));
      c
        ..pointerDown(
          1,
          const Offset(100, 20),
          size,
          pointer: 2,
          touchRadius: 0,
        )
        ..pointerUp(pointer: 2);
      expect(c.ink, isEmpty);
    },
  );

  test('kement seçiminin içinde parmak siler DEĞİL taşır', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    line(c);
    c.setLasso(true);
    c
      ..pointerDown(1, const Offset(5, 5), size, pointer: 91, kind: mouse)
      ..pointerMove(1, const Offset(195, 5), size, pointer: 91)
      ..pointerMove(1, const Offset(195, 40), size, pointer: 91)
      ..pointerMove(1, const Offset(5, 40), size, pointer: 91)
      ..pointerUp(pointer: 91, kind: mouse);
    expect(c.selectionBounds, isNotNull);
    c
      ..pointerDown(1, const Offset(100, 20), size, pointer: 1)
      ..pointerMove(1, const Offset(100, 60), size, pointer: 1)
      ..pointerUp(pointer: 1);
    expect(c.ink, hasLength(1), reason: 'seçili çizgi silinmemeli');
    expect(c.ink.single.points[1], greaterThan(0.1), reason: 'taşınmalı');
  });

  test('Siler seçiliyse ilk kalem dokunuşu "yalnız kalem"e çevirmez', () {
    final c = controller()..setFingerTool(FingerTool.erase);
    c.pointerDown(1, const Offset(20, 300), size, pointer: 3, kind: stylus);
    expect(InkToolMemory.fingerTool, FingerTool.erase);
  });

  test('eski kayıt (yalnız ink_pen_only) Kaydırır/Çizer okunur', () async {
    SharedPreferences.setMockInitialValues({'ink_pen_only': true});
    InkToolMemory.attach(await SharedPreferences.getInstance());
    expect(InkToolMemory.fingerTool, FingerTool.scroll);
    SharedPreferences.setMockInitialValues({'ink_pen_only': false});
    InkToolMemory.attach(await SharedPreferences.getInstance());
    expect(InkToolMemory.fingerTool, FingerTool.draw);
    InkToolMemory.saveFingerTool(FingerTool.erase);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ink_finger_eraser'), isTrue);
    expect(prefs.getBool('ink_pen_only'), isFalse);
    expect(prefs.getBool('ink_pen_only_chosen'), isTrue);
  });
}
