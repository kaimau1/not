import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_links.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/embed_sheet.dart';

/// F18.16: not bağlantıları kimlikle; geri bağlantılar türetilir.
void main() {
  const a = Note(
    id: 'a',
    type: NoteType.text,
    title: 'Proje',
    body: 'Bkz. 📎 Toplantı notu',
    tagLinks: [NoteTagLink(label: 'Toplantı notu', attachmentId: 'note:b')],
  );
  const b = Note(id: 'b', type: NoteType.text, title: 'Toplantı (yeni ad)');
  final trashed = Note(
    id: 'c',
    type: NoteType.text,
    deletedAt: DateTime(2026),
    tagLinks: const [NoteTagLink(label: 'x', attachmentId: 'note:b')],
  );

  test('bağ kimlikle çözülür (başlık değişse de)', () {
    expect(noteLinkTarget(a, 'Toplantı notu'), 'b');
    expect(noteLinkTarget(a, 'başka'), isNull);
    expect(outgoingNoteLinks(a), ['b']);
  });

  test('ek bağı not bağlantısı sayılmaz', () {
    const e = NoteTagLink(label: 'rapor', attachmentId: 'att1');
    expect(linkedNoteId(e), isNull);
  });

  test('geri bağlantılar: çöptekiler ve kendisi hariç', () {
    expect(backlinksTo('b', [a, b, trashed]).map((n) => n.id), ['a']);
    expect(backlinksTo('a', [a, b]), isEmpty);
  });

  test('etiket görünümü: hedef yoksa soluk', () {
    final live = embedTagLooks(a, liveNoteIds: {'a', 'b'});
    final gone = embedTagLooks(a, liveNoteIds: {'a'});
    expect(live['Toplantı notu'], isNotNull);
    expect(
      gone['Toplantı notu']!.color.a,
      lessThan(live['Toplantı notu']!.color.a),
    );
  });
}
