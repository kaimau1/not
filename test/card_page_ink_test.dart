import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card_media.dart';

/// Tablet bulgusu 2026-11-07: sayfa üstü el yazısı kartta basık çıkıyordu —
/// kare tuval (y genişlik birimiyle) kutunun ≤ 120 boyuna sıkışıyordu.
void main() {
  testWidgets('kart el yazısı tuvali kare kalır', (tester) async {
    const note = Note(
      id: 'n',
      type: NoteType.text,
      pageInk: [
        InkStroke(
          page: 1,
          color: 0xFF000000,
          width: 0.01,
          points: [0.1, 0.3, 0.4, 0.5],
        ),
      ],
    );
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 300, child: CardPageInk(note: note)),
        ),
      ),
    );
    final paint = find.descendant(
      of: find.byType(CardPageInk),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(paint), const Size(300, 300));
    // Görünen pay çizginin altına kadar (0.5 × 300 + 4), en çok 120.
    expect(tester.getSize(find.byType(ClipRect)).height, 120);
  });
}
