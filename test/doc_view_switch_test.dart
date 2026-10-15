import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// BALONLU ⇄ KLASİK görünüm geçişi (kullanıcı isteği 2026-10-15: "balonlu
/// mod ve normal ek arasında hızlı geçiş, düzenler kaydedilsin").
///
/// TUZAK: sayfa notu taşıyan bir "text" notu, eski sürüm onarımı
/// ([repairNoteType]) tarafından belge notuna GERİ yükseltiliyordu — klasik
/// görünüme alınan not her açılışta kendiliğinden balonluya dönerdi.
void main() {
  test('klasik görünüme bilerek alınan not onarılmaz', () {
    expect(
      repairNoteType(
        NoteType.text,
        attachmentKinds: const ['pdf'],
        hasPageNotes: true,
        classicDocument: true,
      ),
      NoteType.text,
    );
    // Bayrak yoksa eski davranış (eski sürümün bozduğu not onarılır).
    expect(
      repairNoteType(
        NoteType.text,
        attachmentKinds: const ['pdf'],
        hasPageNotes: true,
      ),
      NoteType.pdf,
    );
  });

  test('gidiş-dönüş: balonlar, sayfa notları ve klasik yerleşim kaybolmaz', () {
    const pdf = Attachment(
      id: 'd',
      kind: AttachmentKind.pdf,
      fileName: 'rapor.pdf',
      mimeType: 'application/pdf',
      onPage: true,
      x: 0.1,
      pageY: 120,
      displayWidth: 0.6,
      pdfPage: 3,
      bubbles: [PageBubble(id: 'b', page: 2, x: .4, y: .4, text: 'bak')],
    );
    const bubbles = Note(
      id: 'n',
      type: NoteType.pdf,
      pageNotes: {'d:p2': 'ikinci sayfanın notu'},
      attachments: [pdf],
    );
    final classic = bubbles.copyWith(
      type: NoteType.text,
      classicDocument: true,
    );
    final stored = Map<String, dynamic>.from(classic.toMap())
      ..remove('createdAt')
      ..remove('updatedAt');
    stored['attachments'] = [
      for (final a in classic.attachments)
        Map<String, dynamic>.from(a.toMap())..remove('createdAt'),
    ];
    final read = Note.fromMap('n', stored);
    expect(read.type, NoteType.text, reason: 'klasik görünüm kalıcı');
    expect(read.classicDocument, isTrue);
    expect(read.pageNotes, bubbles.pageNotes);
    final doc = read.attachments.single;
    expect(doc.bubbles.single.text, 'bak');
    expect(doc.x, 0.1);
    expect(doc.pageY, 120);
    expect(doc.pdfPage, 3);

    // Geri balonluya: bayrak iner, her şey yerinde.
    final back = read.copyWith(type: NoteType.pdf, classicDocument: false);
    expect(back.toMap()['classicDocument'], isFalse);
    expect(back.attachments.single.bubbles, hasLength(1));
  });
}
