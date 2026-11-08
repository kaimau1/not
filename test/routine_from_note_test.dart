import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/domain/routine_from_note.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

void main() {
  test('liste notu: maddeler adım olur, boşlar atlanır', () {
    final r = routineFromNote(
      Note(
        id: 'a',
        type: NoteType.checklist,
        title: 'Sabah',
        items: [
          const NoteItem(id: '1', text: 'Su iç'),
          const NoteItem(id: '2', text: '  '),
          const NoteItem(id: '3', text: 'Egzersiz'),
        ],
      ),
    );
    expect(r.title, 'Sabah');
    expect(r.steps.map((s) => s.text), ['Su iç', 'Egzersiz']);
    expect(r.steps.map((s) => s.id).toSet().length, 2);
  });

  test('metin notu: gövde satırları, madde işareti atılır', () {
    final r = routineFromNote(
      Note(id: 'b', type: NoteType.text, title: 'X', body: '- bir\n2) iki\n\nüç'),
    );
    expect(r.steps.map((s) => s.text), ['bir', 'iki', 'üç']);
  });
}
