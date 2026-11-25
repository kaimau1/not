import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_link_ui.dart';

/// İlgili notlar (yerel, 0 kredi): kelime örtüşmesi, kilitli ve zaten bağlı
/// notlar hariç.
void main() {
  test('yerel ilgili notlar: kelime örtüşmesi, kilitli ve zaten bağlı hariç', () {
    const target = Note(
      id: 't',
      type: NoteType.text,
      title: 'Bahçe sulama planı',
      body: 'domates biber sulama',
      tagLinks: [NoteTagLink(label: 'x', attachmentId: 'note:linked')],
    );
    const notes = [
      target,
      Note(id: 'r', type: NoteType.text, title: 'Domates fideleri'),
      Note(id: 'u', type: NoteType.text, title: 'Fatura ödemeleri'),
      Note(id: 'l', type: NoteType.text, title: 'Domates gizli', locked: true),
      Note(id: 'linked', type: NoteType.text, title: 'Sulama saati'),
    ];
    final related = localRelatedNotes('t', notes);
    expect(related.map((n) => n.id), ['r']);
  });
}
