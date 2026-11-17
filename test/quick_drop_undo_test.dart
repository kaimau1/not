import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';

/// H10 (2026-11-17): hızlı eklemenin "Geri al"ı eski kopyayı körlemesine
/// geri yazıyordu; ekleme ile geri al arasında nota yapılan değişiklik
/// (başka cihaz, ortak kişi, editör) siliniyordu.
void main() {
  var seq = 0;
  String id() => 'yeni${seq++}';

  test(
    'liste: geri al yalnız eklenen maddeyi çıkarır, sonradan geleni korur',
    () {
      final before = Note(
        id: 'm',
        type: NoteType.checklist,
        title: 'Market',
        items: const [NoteItem(id: 'a', text: 'Süt')],
      );
      final r = quickDropFields(before, 'ekmek', locale: 'tr', newId: id);
      expect(r.added, 1);
      final written = [
        for (final m in r.fields['items'] as List)
          NoteItem.fromMap(Map<String, dynamic>.from(m as Map)),
      ];
      // Ekleme sonrası başka cihazdan "Yumurta" geldi.
      final current = before.copyWith(
        items: [
          ...written,
          const NoteItem(id: 'b', text: 'Yumurta'),
        ],
      );
      final undo = quickDropUndoFields(
        before: before,
        current: current,
        written: r.fields,
      );
      final texts = [for (final m in undo['items'] as List) (m as Map)['text']];
      expect(texts, ['Süt', 'Yumurta']);
    },
  );

  test('yazı: eklenen satır çıkar, sonradan yazılan kalır', () {
    final before = Note(
      id: 't',
      type: NoteType.text,
      title: 'Günlük',
      body: 'bir',
    );
    final r = quickDropFields(before, 'iki', locale: 'tr');
    final w = r.fields['body'] as String;
    expect(w, 'bir\niki');
    final current = before.copyWith(body: '$w\nüç');
    final undo = quickDropUndoFields(
      before: before,
      current: current,
      written: r.fields,
    );
    expect(undo['body'], 'bir\nüç');
  });

  test('yazı: gövde baştan değiştiyse geri al dokunmaz', () {
    final before = Note(id: 't', type: NoteType.text, title: 'G', body: 'bir');
    final r = quickDropFields(before, 'iki', locale: 'tr');
    final current = before.copyWith(body: 'tamamen başka');
    expect(
      quickDropUndoFields(before: before, current: current, written: r.fields),
      isEmpty,
    );
  });
}
