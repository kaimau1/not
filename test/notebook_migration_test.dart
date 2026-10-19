import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_pages.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/notebook_migration.dart';

/// F3.5: eski defter (ayrı editör) → normal notun Defter görünümü.
void main() {
  Attachment file(String id, String section) => Attachment(
    id: id,
    kind: AttachmentKind.image,
    fileName: '$id.jpg',
    mimeType: 'image/jpeg',
    section: section,
  );

  final notebook = Note(
    id: 'd1',
    type: NoteType.archive,
    title: 'Tez',
    archivePages: const ['Kaynaklar'],
    archiveGeneralName: 'Giriş',
    items: const [
      NoteItem(id: 'w0', text: 'ilk sayfanın yazısı'),
      NoteItem(id: 'w1', text: 'kaynak yazısı', section: 'Kaynaklar'),
      NoteItem(
        id: 'b1',
        title: 'Alıntı',
        text: 'önemli cümle',
        section: 'Kaynaklar',
      ),
      NoteItem(id: 'orphan', title: 'Öksüz', text: 'x', section: 'Silinmiş'),
    ],
    attachments: [file('a0', ''), file('a1', 'Kaynaklar'), file('a2', '?')],
  );

  final paged = notebookToPagedNote(notebook, pageId: (i) => 'p$i');

  test('defter metin notu olur, Defter görünümü açık', () {
    expect(paged.type, NoteType.text);
    expect(paged.paged, isTrue);
    expect(paged.items, isEmpty);
    expect(paged.archivePages, isEmpty);
    expect(paged.title, 'Tez');
  });

  test('her defter sayfası bir not sayfası; ad başlık satırı', () {
    final pages = resolvedTextPages(paged);
    expect(pages.map((p) => p.id), ['', 'p1']);
    expect(stripRichMarkers(pages[0].body), contains('Giriş'));
    expect(pages[0].body, contains('ilk sayfanın yazısı'));
    // Öksüz blok (silinmiş sayfaya bağlı) ilk sayfaya düşer.
    expect(pages[0].body, contains('Öksüz'));
    expect(stripRichMarkers(pages[1].body), startsWith('Kaynaklar'));
    expect(pages[1].body, contains('kaynak yazısı'));
    expect(pages[1].body, contains('önemli cümle'));
  });

  test('ekler kendi sayfasına, öksüzler ilk sayfaya', () {
    final bySection = {for (final a in paged.attachments) a.id: a.section};
    expect(bySection, {'a0': '', 'a1': 'p1', 'a2': ''});
  });

  test('defter olmayan not olduğu gibi döner', () {
    const text = Note(id: 'n', type: NoteType.text, body: 'x');
    expect(
      identical(notebookToPagedNote(text, pageId: (_) => 'p'), text),
      isTrue,
    );
  });
}
