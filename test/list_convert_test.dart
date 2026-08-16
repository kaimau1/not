import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/list_convert.dart';
import 'package:notlar/features/notes/domain/note_item.dart';

/// Liste ↔ metin dönüşümü ve sıralama AI'sız çalışıyor mu.
void main() {
  var counter = 0;
  String nextId() => 'i${counter++}';

  setUp(() => counter = 0);

  test('metinden liste: işaretler sökülür, boş satır atlanır', () {
    final items = itemsFromText(
      '- süt\n\n* ekmek\n1. yumurta\n[x] peynir\nzeytin',
      newId: nextId,
    );
    expect([for (final i in items) i.text], [
      'süt',
      'ekmek',
      'yumurta',
      'peynir',
      'zeytin',
    ]);
    expect(items[3].checked, isTrue);
    expect(items[0].checked, isFalse);
  });

  test('listeden metin: gidiş-dönüş işaretli maddeyi korur', () {
    final items = [
      const NoteItem(id: 'a', text: 'süt'),
      const NoteItem(id: 'b', text: 'ekmek', checked: true),
    ];
    final text = textFromItems(items);
    expect(text, '- süt\n- [x] ekmek');
    final back = itemsFromText(text, newId: nextId);
    expect([for (final i in back) i.text], ['süt', 'ekmek']);
    expect(back[1].checked, isTrue);
  });

  test('sıralı listede numara yazılır, onay kutusu yazılmaz', () {
    expect(
      textFromItems([
        const NoteItem(id: 'a', text: 'ilk'),
        const NoteItem(id: 'b', text: 'ikinci', checked: true),
      ], numbered: true),
      '1. ilk\n2. ikinci',
    );
  });

  test('yıldızlılar üste çıkar, geri kalanın sırası bozulmaz', () {
    final items = [
      const NoteItem(id: 'a', text: 'bir'),
      const NoteItem(id: 'b', text: 'iki', starred: true),
      const NoteItem(id: 'c', text: 'üç'),
      const NoteItem(id: 'd', text: 'dört', starred: true),
    ];
    expect([for (final i in sortItems(items, ItemSort.starredFirst)) i.id], [
      'b',
      'd',
      'a',
      'c',
    ]);
  });

  test('alfabetik sıralama Türkçe harf sırasını kullanır', () {
    final items = [
      const NoteItem(id: 'a', text: 'zeytin'),
      const NoteItem(id: 'b', text: 'çilek'),
      const NoteItem(id: 'c', text: 'ıspanak'),
      const NoteItem(id: 'd', text: 'incir'),
    ];
    // ç < ı < i < z (Türkçe alfabe); kod noktası sırasında zeytin başa geçerdi.
    expect([for (final i in sortItems(items, ItemSort.alphabetical)) i.text], [
      'çilek',
      'ıspanak',
      'incir',
      'zeytin',
    ]);
  });

  test('işaretliler alta iner', () {
    final items = [
      const NoteItem(id: 'a', text: 'bir', checked: true),
      const NoteItem(id: 'b', text: 'iki'),
      const NoteItem(id: 'c', text: 'üç', checked: true),
      const NoteItem(id: 'd', text: 'dört'),
    ];
    expect([for (final i in sortItems(items, ItemSort.uncheckedFirst)) i.id], [
      'b',
      'd',
      'a',
      'c',
    ]);
  });
}
