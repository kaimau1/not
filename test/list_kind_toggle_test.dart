import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// Alt çubuğun türe özgü yuvası (kullanıcı isteği 2026-11-16): liste notunda
/// "Numaralıya çevir", numaralı notta "Onay kutulu listeye çevir"; maddeler
/// ve işaretleri aynen kalır.
void main() {
  testWidgets('liste ↔ numaralı alt çubuktan çevrilir, maddeler kalır', (
    tester,
  ) async {
    const note = Note(
      id: 'n1',
      type: NoteType.checklist,
      title: 'Liste',
      items: [
        NoteItem(id: 'a', text: 'süt'),
        NoteItem(id: 'b', text: 'ekmek', checked: true),
      ],
    );
    final repo = CountingNotesRepository();
    await pumpEditor(tester, note, repo: repo);

    final toNumbered = find.byTooltip('Numaralıya çevir');
    expect(toNumbered, findsOneWidget);
    await tester.tap(toNumbered);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));

    expect(repo.lastSaved?.type, NoteType.ordered);
    expect([for (final i in repo.lastSaved!.items) i.text], ['süt', 'ekmek']);
    expect(repo.lastSaved!.items[1].checked, isTrue);

    final toChecklist = find.byTooltip('Onay kutulu listeye çevir');
    expect(toChecklist, findsOneWidget);
    expect(find.byTooltip('Numaralıya çevir'), findsNothing);
    await tester.tap(toChecklist);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    expect(repo.lastSaved?.type, NoteType.checklist);

    await endEditor(tester);
  });
}
