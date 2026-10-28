// Klasör içi süzgeç (kullanıcı isteği 2026-10-28: "klasörler içinde
// filtreleme yok, dashboard'da ne varsa orası da aynı olmalı").
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';

void main() {
  final notes = [
    const Note(id: 'a', type: NoteType.checklist, title: 'a', tags: ['iş']),
    const Note(id: 'b', type: NoteType.text, title: 'b', starred: true),
    const Note(
      id: 'c',
      type: NoteType.text,
      title: 'c',
      tags: ['iş'],
      starred: true,
    ),
  ];

  List<String> ids(List<Note> list) => [for (final n in list) n.id];

  test('süzgeçsiz klasör olduğu gibi', () {
    expect(ids(applyFolderFilter(notes, null)), ['a', 'b', 'c']);
    expect(ids(applyFolderFilter(notes, kNoFolderFilter)), ['a', 'b', 'c']);
  });

  test('durum ve etiket birlikte daraltır', () {
    expect(
      ids(applyFolderFilter(notes, (filter: NoteFilter.starred, tag: null))),
      ['b', 'c'],
    );
    expect(ids(applyFolderFilter(notes, (filter: NoteFilter.all, tag: 'iş'))), [
      'a',
      'c',
    ]);
    expect(
      ids(applyFolderFilter(notes, (filter: NoteFilter.starred, tag: 'iş'))),
      ['c'],
    );
  });
}
