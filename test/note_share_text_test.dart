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
}
