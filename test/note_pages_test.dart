import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_pages.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// "Bir nota yeni sayfa ekleme" (2026-10-11): etkin sayfanın içeriği notun
/// gövdesinde yaşar, geçiş içerikleri yer değiştirir (bkz. note_pages.dart).
void main() {
  test('moveItemToPage: etkin sayfadan hedef sayfanın sonuna', () {
    var note = const Note(
      id: 'n',
      type: NoteType.checklist,
      items: [
        NoteItem(id: 'a', text: 'bir'),
        NoteItem(id: 'b', text: 'iki'),
      ],
    );
    note = addTextPage(note, 'p2'); // p2 etkin, boş
    note = note.copyWith(
      items: const [NoteItem(id: 'c', text: 'üç')],
    );
    note = switchTextPage(note, ''); // ilk sayfaya dön
    final moved = moveItemToPage(note, 'b', 'p2');
    expect([for (final i in moved.items) i.id], ['a']);
    final p2 = resolvedTextPages(moved).firstWhere((p) => p.id == 'p2');
    expect([for (final i in p2.items) i.id], ['c', 'b']);
    // Etkin sayfaya ya da olmayan sayfaya taşıma bir şey yapmaz.
    expect(identical(moveItemToPage(note, 'b', ''), note), isTrue);
    expect(identical(moveItemToPage(note, 'b', 'yok'), note), isTrue);
  });

  Attachment img(String id, {String section = ''}) => Attachment(
    id: id,
    kind: AttachmentKind.image,
    fileName: '$id.jpg',
    mimeType: 'image/jpeg',
    section: section,
  );

  const base = Note(id: 'n', type: NoteType.text, body: 'ilk sayfa');

  test('sayfa eklemek mevcut içeriği ilk sayfa yapar ve boş sayfaya geçer', () {
    final n = addTextPage(base, 'p2');
    expect(n.textPages.map((p) => p.id), ['', 'p2']);
    expect(n.activePage, 'p2');
    expect(n.body, '');
    expect(textPagePosition(n), (index: 1, count: 2));
    // İlk sayfanın yazısı kaybolmadı.
    expect(resolvedTextPages(n).first.body, 'ilk sayfa');
  });

  test('sayfalar arasında geçiş gövdeyi ve maddeleri taşır', () {
    var n = addTextPage(base, 'p2');
    n = n.copyWith(
      body: 'ikinci',
      items: const [NoteItem(id: 'i', text: 'madde')],
    );
    n = switchTextPage(n, '');
    expect(n.body, 'ilk sayfa');
    expect(n.items, isEmpty);
    expect(n.activePage, '');
    n = switchTextPage(n, 'p2');
    expect(n.body, 'ikinci');
    expect(n.items.single.text, 'madde');
    expect(resolvedTextPages(n).map((p) => p.body).toList(), [
      'ilk sayfa',
      'ikinci',
    ]);
  });

  test('yeni sayfa ETKİN sayfanın arkasına girer', () {
    var n = addTextPage(base, 'p2');
    n = switchTextPage(n, '');
    n = addTextPage(n, 'p1b');
    expect(n.textPages.map((p) => p.id), ['', 'p1b', 'p2']);
    expect(n.activePage, 'p1b');
  });

  test('sayfa silinince görselleri komşu sayfaya taşınır', () {
    var n = addTextPage(base, 'p2').copyWith(
      body: 'ikinci',
      attachments: [
        img('a'),
        img('b', section: 'p2'),
      ],
    );
    n = deleteTextPage(n, 'p2');
    // Tek sayfa kaldı: not yeniden tek sayfalı.
    expect(n.textPages, isEmpty);
    expect(n.activePage, '');
    expect(n.body, 'ilk sayfa');
    expect(n.attachments.map((a) => a.section), ['', '']);
  });

  test('İLK sayfa silinince komşusu ilk sayfa olur (kimliği "")', () {
    var n = addTextPage(base, 'p2');
    n = addTextPage(n, 'p3').copyWith(
      attachments: [
        img('a'),
        img('b', section: 'p2'),
        img('c', section: 'p3'),
      ],
    );
    n = switchTextPage(n, '');
    n = deleteTextPage(n, '');
    expect(n.textPages.map((p) => p.id), ['', 'p3']);
    expect(n.activePage, '');
    // Eski 2. sayfanın içeriği artık ilk sayfada (gövdede).
    expect(n.body, '');
    expect(
      {for (final a in n.attachments) a.id: a.section},
      {'a': '', 'b': '', 'c': 'p3'},
    );
  });

  test('düz metin ve "boş not" bütün sayfaları sayar', () {
    var n = addTextPage(base, 'p2').copyWith(body: 'ikinci');
    expect(n.toPlainText(), contains('ilk sayfa'));
    expect(n.toPlainText(), contains('ikinci'));
    // Etkin sayfa boş ama ilk sayfada yazı var → not boş DEĞİL.
    n = n.copyWith(body: '');
    expect(n.isEmpty, isFalse);
  });

  test('sayfalar kayıttan geri okunur', () {
    final n = addTextPage(base, 'p2').copyWith(body: 'ikinci');
    final map = n.toMap()
      ..remove('createdAt')
      ..remove('updatedAt');
    final back = Note.fromMap('n', map);
    expect(back.activePage, 'p2');
    expect(back.textPages.map((p) => p.id), ['', 'p2']);
    expect(resolvedTextPages(back).first.body, 'ilk sayfa');
  });

  test('bozuk kayıt: etkin sayfanın girdisi yoksa içerik kaybolmaz', () {
    const n = Note(
      id: 'n',
      type: NoteType.text,
      body: 'gövde',
      activePage: 'x',
      textPages: [
        NoteTextPage(id: ''),
        NoteTextPage(id: 'y', body: 'y'),
      ],
    );
    expect(resolvedTextPages(n).map((p) => p.body), ['gövde', '', 'y']);
  });
}
