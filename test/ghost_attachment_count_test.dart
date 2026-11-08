import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Hayalet ek sayacı: zemin görseli ek sayılmaz (kart/dışa aktarma gibi);
/// editörün ataç rozeti ve şeridi aynı kuralı kullanır.
void main() {
  const image = Attachment(
    id: 'bg',
    kind: AttachmentKind.image,
    fileName: 'z.jpg',
    mimeType: 'image/jpeg',
  );
  const file = Attachment(
    id: 'f',
    kind: AttachmentKind.pdf,
    fileName: 'a.pdf',
    mimeType: 'application/pdf',
  );

  test('zemin görseli ek sayılmaz', () {
    final note = Note(
      id: 'n',
      type: NoteType.text,
      attachments: const [image],
      backgroundImageId: 'bg',
    );
    expect(note.attachmentsWithoutBackground, isEmpty);
  });

  test('zeminsiz notta ve başka ekte liste aynen kalır', () {
    final plain = Note(id: 'n', type: NoteType.text, attachments: const [file]);
    expect(plain.attachmentsWithoutBackground, [file]);
    final mixed = Note(
      id: 'm',
      type: NoteType.text,
      attachments: const [image, file],
      backgroundImageId: 'bg',
    );
    expect(mixed.attachmentsWithoutBackground, [file]);
  });
}
