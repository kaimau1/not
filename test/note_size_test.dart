import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/firestore_size.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F1.6 — 1 MiB belge sınırına karşı boyut tahmini.
void main() {
  test('metin UTF-8 bayt + 1, sayı 8, bool 1', () {
    expect(estimateValueBytes('abc'), 4);
    expect(estimateValueBytes('ış'), 5); // 2 + 2 bayt + 1
    expect(estimateValueBytes(3.5), 8);
    expect(estimateValueBytes(true), 1);
    expect(estimateValueBytes({'a': 1}), 2 + 8);
    expect(estimateValueBytes([1, 2]), 16);
  });

  test('en büyük kalem: çizimli ek gövdeyi geçer', () {
    final note = Note(
      id: 'n',
      type: NoteType.pdf,
      body: 'kısa',
      attachments: [
        Attachment(
          id: 'a',
          kind: AttachmentKind.pdf,
          fileName: 'ders.pdf',
          mimeType: 'application/pdf',
          ink: [
            InkStroke(
              page: 1,
              color: 0xFF000000,
              width: 0.004,
              points: List.filled(20000, 0.5),
            ),
          ],
        ),
      ],
    );
    final part = NotesRepository.largestPart(note);
    expect(part.kind, NotePartKind.attachment);
    expect(part.name, 'ders.pdf');
    expect(part.bytes, greaterThan(160000));
  });

  test('eşik 1 MiB\'in altında', () {
    expect(NotesRepository.docWarnBytes, lessThan(1024 * 1024));
  });
}
