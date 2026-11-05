import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/bubble_view_retire.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Balonlu görünüm kalkınca (2026-11-05) sayfa notları kaybolmaz.
void main() {
  const pdf = Attachment(
    id: 'p',
    kind: AttachmentKind.pdf,
    fileName: 'a.pdf',
    mimeType: 'application/pdf',
  );
  Note note({String body = '', Map<String, String> pageNotes = const {}}) =>
      Note(
        id: 'n',
        type: NoteType.pdf,
        body: body,
        attachments: const [pdf],
        pageNotes: pageNotes,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  test('sayfa notları sayfa referanslı satırlar olarak gövdeye iner', () {
    final moved = movePageNotesToBody(
      note(body: 'giriş', pageNotes: {'p#p3': 'üçüncü', 'p#p1': ' birinci '}),
      turkish: true,
    );
    expect(moved.body, 'giriş\n\n📖 s.1 birinci\n📖 s.3 üçüncü');
    // Harita boş dizgiyle yazılır (anahtar silinmez).
    expect(moved.pageNotes, {'p#p3': '', 'p#p1': ''});
    expect(moved.hasPageNotes, isFalse);
  });

  test('sayfa notu yoksa not değişmez', () {
    final n = note(body: 'x', pageNotes: {'p#p1': '  '});
    expect(identical(movePageNotesToBody(n, turkish: true), n), isTrue);
  });
}
