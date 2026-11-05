import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';

void main() {
  final now = DateTime(2026, 11, 6, 2);
  Note note({
    String title = '',
    String body = '',
    NoteType type = NoteType.text,
    DateTime? created,
  }) => Note(
    id: 'n',
    type: type,
    title: title,
    body: body,
    createdAt: created ?? now.subtract(const Duration(seconds: 2)),
  );

  test('az önce açılmış boş metin notu klavyeyi açar', () {
    expect(isFreshEmptyTextNote(note(), now: now), isTrue);
  });

  test('eski, dolu ya da liste notu klavyeyi açmaz', () {
    expect(
      isFreshEmptyTextNote(
        note(created: now.subtract(const Duration(minutes: 5))),
        now: now,
      ),
      isFalse,
    );
    expect(isFreshEmptyTextNote(note(body: 'x'), now: now), isFalse);
    expect(isFreshEmptyTextNote(note(title: 'x'), now: now), isFalse);
    expect(
      isFreshEmptyTextNote(note(type: NoteType.checklist), now: now),
      isFalse,
    );
  });
}
