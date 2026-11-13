import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/item_divider_style.dart';

/// Kullanıcı bulgusu 2026-11-13: "alt çizgi varken madde altında kasma
/// oluyor klavye açılırken". Kesikli/noktalı ayırıcı satır başına 30–70 ayrı
/// çizgi, dalgalı ~250 noktalı yol çiziyordu; Impeller her karede hepsini
/// yeniden üçgenliyordu. Bekçi: her tür EN ÇOK 2 çizim çağrısı, dalga kısa
/// yol (yarım dalga başına tek eğri).
class _CountingCanvas implements Canvas {
  final calls = <String>[];
  Path? lastPath;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => calls.add('line');

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) =>
      calls.add('points');

  @override
  void drawPath(Path path, Paint paint) {
    calls.add('path');
    lastPath = path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName.toString());
    return null;
  }
}

void main() {
  for (final kind in [
    NoteItem.dividerSolid,
    NoteItem.dividerDashed,
    NoteItem.dividerDotted,
    NoteItem.dividerDouble,
    NoteItem.dividerWavy,
  ]) {
    for (final weight in [0.5, 1.0, 3.0]) {
      test('$kind ×$weight: en çok 2 çizim çağrısı', () {
        final canvas = _CountingCanvas();
        paintItemDivider(
          canvas,
          style: ItemDivider(kind, weight: weight),
          fallbackColor: Colors.teal,
          left: 8,
          right: 1272, // geniş ekran: eskiden noktalı ~250 çağrı
          y: 40,
          baseWidth: 2.2,
        );
        expect(canvas.calls.length, lessThanOrEqualTo(2), reason: '$canvas');
      });
    }
  }

  test('dalga: yol sınırları aynı genlikte (görünüş korunur)', () {
    final canvas = _CountingCanvas();
    paintItemDivider(
      canvas,
      style: const ItemDivider(NoteItem.dividerWavy),
      fallbackColor: Colors.teal,
      left: 8,
      right: 400,
      y: 40,
      baseWidth: 2.2,
    );
    final bounds = canvas.lastPath!.getBounds();
    final amplitude = 1.5 + 2.2 * 0.6;
    final mid = 40 - amplitude;
    // Eğri tepeleri ± genlik (denetim noktası 2× — sınır kutusu denetim
    // noktalarını içerebilir, o yüzden üst sınır 2× genlik).
    expect(bounds.top, greaterThanOrEqualTo(mid - 2 * amplitude - 0.01));
    expect(bounds.bottom, lessThanOrEqualTo(mid + 2 * amplitude + 0.01));
    expect(bounds.left, closeTo(8, 0.01));
    expect(bounds.right, closeTo(400, 0.01));
  });
}
