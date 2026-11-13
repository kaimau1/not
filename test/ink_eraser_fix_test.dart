import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

/// Silgi bulguları (kullanıcı 2026-11-13): kısmi silgide kalan yazının
/// basıncı korunur (boy değişmez); alt sayfada başlayıp üst sayfaya taşan
/// çizgi üst sayfada silinir.
void main() {
  const size = Size(1000, 1000);
  setUp(InkToolMemory.reset);
  tearDown(InkToolMemory.reset);

  InkController make(List<InkStroke> ink) =>
      InkController(initial: ink, onChanged: (_) {})..setEditing(true);

  void erase(InkController c, int page, Offset at) {
    c.setEraser(true);
    c.pointerDown(page, at, size, pointer: 1);
    c.pointerUp(pointer: 1);
  }

  test('kısmi silgi basıncı korur, ara nokta eklemez', () {
    InkToolMemory.partialEraser = true;
    // Seyrek noktalı basınçlı çizgi (aralık > silgi yarıçapı).
    final c = make([
      InkStroke(
        page: 1,
        color: 0xFF000000,
        width: 0.004,
        points: const [
          0.1,
          0.5,
          0.2,
          0.5,
          0.3,
          0.5,
          0.4,
          0.5,
          0.5,
          0.5,
          0.6,
          0.5,
        ],
        pressures: const [0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
      ),
    ]);
    erase(c, 1, const Offset(350, 500));
    expect(c.ink, hasLength(2));
    for (final s in c.ink) {
      expect(s.hasPressure, isTrue, reason: 'basınç düştü → boy değişir');
      expect(s.pressures!.every((q) => q == 0.3), isTrue);
    }
    expect(c.ink.first.points, const [0.1, 0.5, 0.2, 0.5, 0.3, 0.5]);
  });

  test('alt sayfadan üst sayfaya taşan çizgi üst sayfada silinir', () {
    // Sayfa 2'de başlayıp yukarı (y < 0) sayfa 1'e taşan çizgi.
    final c = make([
      const InkStroke(
        page: 2,
        color: 0xFF000000,
        width: 0.004,
        points: [0.5, 0.1, 0.5, 0.0, 0.5, -0.1, 0.5, -0.2],
      ),
    ]);
    // Sayfa 1'de y = 0,85 ↔ sayfa 2'de y = -0,15.
    erase(c, 1, const Offset(500, 850));
    expect(c.ink, isEmpty);
  });
}
