import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_share_text.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F13.1 (2026-10-31): balon yazısı dışarı çıkar. Eskiden "Metni paylaş" /
/// "Kopyala" balonları HİÇ içermiyordu; PDF'in üstüne yazılan her şey
/// uygulamada kalıyordu.
void main() {
  String label(int p) => 'Sayfa $p';

  const pdf = Attachment(
    id: 'd',
    kind: AttachmentKind.pdf,
    fileName: 'rapor.pdf',
    mimeType: 'application/pdf',
    bubbles: [
      PageBubble(id: 'b3', page: 2, x: 0.5, y: 0.1, text: 'Kaynak?'),
      PageBubble(id: 'b1', page: 1, x: 0.5, y: 0.8, text: 'Altta'),
      PageBubble(
        id: 'b2',
        page: 1,
        x: 0.2,
        y: 0.2,
        title: 'Fatura',
        text: '**Öde**',
      ),
      PageBubble(id: 'empty', page: 3, x: 0.5, y: 0.5),
    ],
  );
  const note = Note(
    id: 'n',
    type: NoteType.pdf,
    title: 'Rapor',
    attachments: [pdf],
  );

  test('paylaşım metni balonları sayfa sırasıyla içerir', () {
    expect(
      noteShareText(note, pageLabel: label),
      'Rapor\n\n'
      'Sayfa 1 — Fatura: Öde\n'
      'Sayfa 1 — Altta\n'
      'Sayfa 2 — Kaynak?',
    );
  });

  test('"Balonlar" çipi kapalıyken balon yok', () {
    expect(
      noteShareText(
        note,
        pageLabel: label,
        options: const ShareTextOptions(bubbles: false),
      ),
      'Rapor',
    );
  });

  test('çip tercihi saklanır; eski kayıtta varsayılan açık', () {
    const off = ShareTextOptions(bubbles: false);
    expect(ShareTextOptions.decode(off.encode()).bubbles, isFalse);
    expect(ShareTextOptions.decode('1101').bubbles, isTrue);
  });

  test('yazısız balon sayılmaz', () {
    expect(noteHasTextBubbles(note), isTrue);
    const blank = Note(
      id: 'b',
      type: NoteType.pdf,
      attachments: [
        Attachment(
          id: 'x',
          kind: AttachmentKind.pdf,
          fileName: 'x.pdf',
          mimeType: 'application/pdf',
          bubbles: [PageBubble(id: 'e', page: 1, x: 0, y: 0)],
        ),
      ],
    );
    expect(noteHasTextBubbles(blank), isFalse);
  });

  test('Nota aktar: kendi sayfa notuna, ikinci kez çoğaltmaz', () {
    final withNote = note.withPageNote(pdf, 1, 'Önceki not');
    final changed = pageNotesWithBubbles(withNote, pdf, pdf.bubbles);
    expect(changed, {1: 'Önceki not\nFatura: Öde\nAltta', 2: 'Kaynak?'});
    var after = withNote;
    changed.forEach((p, t) => after = after.withPageNote(pdf, p, t));
    expect(pageNotesWithBubbles(after, pdf, pdf.bubbles), isEmpty);
  });
}
