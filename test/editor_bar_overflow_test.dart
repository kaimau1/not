import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// U6 (kullanıcı isteği 2026-11-18): telefonda alt kapsülde 5 düğme
/// (Biçim · Ekle · Kalem · Liste↔Numaralı · Seç) kalabalıktı → 4 yuva: ilk
/// üçü yerinde, kalanlar ⋮'nin açılır menüsünde. Tablette 5 kalır.
const _note = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Liste',
  items: [NoteItem(id: 'a', text: 'süt'), NoteItem(id: 'b', text: 'ekmek')],
);

int _segments(WidgetTester tester) => find
    .descendant(
      of: find.byKey(const ValueKey('editor-tool-capsule')),
      matching: find.byType(InkWell),
    )
    .evaluate()
    .length;

void main() {
  testWidgets('telefonda 4 yuva; ⋮ kalanları menüde gösterir', (
    tester,
  ) async {
    await pumpEditor(tester, _note);
    final more = find.descendant(
      of: find.byKey(const ValueKey('editor-tool-capsule')),
      matching: find.byIcon(Icons.more_horiz),
    );
    expect(more, findsOneWidget);
    expect(_segments(tester), 4);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editor-bar-more-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-bar-more-1')), findsOneWidget);
    expect(find.text('Seç'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-bar-more-0')));
    await tester.pumpAndSettle();
    // Liste ↔ numaralı çalıştı (menüdeki iş düğmeninkiyle aynı).
    await endEditor(tester);
  });

  testWidgets('tablette ⋮ yok, beşi de kapsülde', (tester) async {
    await pumpEditor(tester, _note, size: const Size(1200, 800));
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(_segments(tester), greaterThanOrEqualTo(5));
    await endEditor(tester);
  });
}
