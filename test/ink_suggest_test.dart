import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_recognize.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(InkToolMemory.reset);

  const size = Size(400, 400);

  void draw(InkController c, List<Offset> pts) {
    c.pointerDown(1, pts.first, size, pointer: 1);
    for (final p in pts.skip(1)) {
      c.pointerMove(1, p, size, pointer: 1);
    }
    c.pointerUp(pointer: 1);
  }

  List<Offset> circle() => [
    for (var i = 0; i <= 60; i++)
      Offset(
        200 + (60 + 2 * math.sin(i * 0.9)) * math.cos(2 * math.pi * i / 60),
        200 + 55 * math.sin(2 * math.pi * i / 60),
      ),
  ];

  test('kaba daire → işaretçi; uygula temizler, geri al geri getirir', () {
    final c = InkController(initial: const [], onChanged: (_) {})
      ..shapeSnap = false;
    draw(c, circle());
    expect(c.suggestion.value?.kind, InkFixKind.ellipse);
    final drawn = c.ink.single;
    c.applySuggestion();
    expect(c.suggestion.value, isNull);
    expect(c.ink, hasLength(1));
    expect(identical(c.ink.single, drawn), isFalse);
    c.undo();
    expect(identical(c.ink.single, drawn), isTrue);
    c.dispose();
  });

  test('yeni çizgi başlayınca öneri kalkar', () {
    final c = InkController(initial: const [], onChanged: (_) {})
      ..shapeSnap = false;
    draw(c, circle());
    expect(c.suggestion.value, isNotNull);
    c.pointerDown(1, const Offset(10, 10), size, pointer: 2);
    expect(c.suggestion.value, isNull);
    c.dispose();
  });

  test('tik: ayar sorulmadıysa onay ister, kapalıysa önerilmez', () {
    final tick = [
      for (var i = 0; i <= 10; i++)
        Offset.lerp(const Offset(100, 120), const Offset(115, 140), i / 10)!,
      for (var i = 1; i <= 14; i++)
        Offset.lerp(const Offset(115, 140), const Offset(150, 90), i / 14)!,
    ];
    final c = InkController(initial: const [], onChanged: (_) {})
      ..shapeSnap = false;
    draw(c, tick);
    expect(c.suggestion.value?.kind, InkFixKind.tick);
    expect(c.suggestion.value!.needsConsent, isTrue);
    InkToolMemory.markFix = false;
    c.dismissSuggestion();
    draw(c, [for (final p in tick) p + const Offset(150, 0)]);
    expect(c.suggestion.value?.kind, isNot(InkFixKind.tick));
    c.dispose();
  });

  test('şekil önerisi kapalıyken işaretçi yok', () {
    final c = InkController(initial: const [], onChanged: (_) {})
      ..shapeSnap = false
      ..shapeSuggest = false;
    draw(c, circle());
    expect(c.suggestion.value, isNull);
    c.dispose();
  });
}
