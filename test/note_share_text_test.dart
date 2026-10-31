import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_share_text.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Paylaşım/kopyalama metni (kullanıcı isteği 2026-09-26: "paylaşım
/// içeriğinin düzeni", "kopyalama vb. şeylerin düzeni"). Eskiden
/// `toPlainText` gidiyordu: `- [ ] Süt`, başlık gövdeye yapışık.
void main() {
  const list = Note(
    id: 'n',
    type: NoteType.checklist,
    title: '**Market**',
    body: 'Akşam  \n\n\n\nuğra',
    tags: ['ev', 'alış veriş'],
    items: [
      NoteItem(id: '1', text: 'Süt'),
      NoteItem(id: '2', text: 'Ekmek', checked: true),
      NoteItem(id: '3', text: '  '),
      NoteItem(id: '4', text: '==2:Yumurta=='),
    ],
  );

  test('başlık ayrı satırda, maddeler ☐/☑, tamamlananlar sonda', () {
    expect(
      noteShareText(list),
      'Market\n\nAkşam\n\nuğra\n\n☐ Süt\n☐ Yumurta\n☑ Ekmek',
    );
  });

  test('seçenekler: başlıksız, tamamlanansız, etiketli', () {
    expect(
      noteShareText(
        list,
        options: const ShareTextOptions(
          title: false,
          checked: false,
          tags: true,
        ),
      ),
      'Akşam\n\nuğra\n\n☐ Süt\n☐ Yumurta\n\n#ev #alış_veriş',
    );
  });

  test('sıralı liste numaralanır, boş maddeler sayılmaz', () {
    const ordered = Note(
      id: 'o',
      type: NoteType.ordered,
      items: [
        NoteItem(id: '1', text: 'Birinci'),
        NoteItem(id: '2', text: ''),
        NoteItem(id: '3', text: 'İkinci'),
      ],
    );
    expect(noteShareText(ordered), '1. Birinci\n2. İkinci');
  });

  test('birden çok not ayraçla birleşir, boşlar atlanır', () {
    expect(joinShareTexts(['A', '  ', 'B\n']), 'A\n\n—————\n\nB');
  });

  test('boş not boş metin verir', () {
    expect(noteShareText(const Note(id: 'e', type: NoteType.text)), isEmpty);
  });

  test('çok sayfalı not: bütün sayfalar "Sayfa N" altında (F10.2)', () {
    // Etkin sayfa ikinci: içeriği gövdede, listedeki karşılığı boş.
    const paged = Note(
      id: 'p',
      type: NoteType.text,
      title: 'Ders',
      body: 'İkinci sayfa',
      activePage: 'b',
      textPages: [
        NoteTextPage(
          id: '',
          body: 'Birinci sayfa',
          items: [NoteItem(id: '1', text: 'Madde')],
        ),
        NoteTextPage(id: 'b'),
        NoteTextPage(id: 'c'),
      ],
    );
    expect(
      noteShareText(paged, pageLabel: (n) => 'Sayfa $n'),
      'Ders\n\nSayfa 1\nBirinci sayfa\n\n☐ Madde\n\nSayfa 2\nİkinci sayfa',
    );
  });

  test('tek sayfalı notta sayfa başlığı yok', () {
    const one = Note(
      id: 'q',
      type: NoteType.text,
      body: 'Yalnız',
      textPages: [NoteTextPage(id: '')],
    );
    expect(noteShareText(one, pageLabel: (n) => 'Sayfa $n'), 'Yalnız');
  });
}
