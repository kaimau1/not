import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

void main() {
  group('Note', () {
    test('isEmpty boş not için true döner', () {
      const note = Note(id: '1', type: NoteType.text);
      expect(note.isEmpty, isTrue);
    });

    test('isEmpty başlık varsa false döner', () {
      const note = Note(id: '1', type: NoteType.text, title: 'Merhaba');
      expect(note.isEmpty, isFalse);
    });

    test('isEmpty yalnızca boş öğeler varsa true döner', () {
      const note = Note(
        id: '1',
        type: NoteType.checklist,
        items: [NoteItem(id: 'a', text: '  ')],
      );
      expect(note.isEmpty, isTrue);
    });

    test('toPlainText checklist öğelerini işaret durumuyla yazar', () {
      const note = Note(
        id: '1',
        type: NoteType.checklist,
        title: 'Alışveriş',
        items: [
          NoteItem(id: 'a', text: 'Süt', checked: true),
          NoteItem(id: 'b', text: 'Ekmek'),
        ],
      );
      final text = note.toPlainText();
      expect(text, contains('Alışveriş'));
      expect(text, contains('- [x] Süt'));
      expect(text, contains('- [ ] Ekmek'));
    });

    test('toPlainText sıralı listeyi numaralandırır', () {
      const note = Note(
        id: '1',
        type: NoteType.ordered,
        items: [
          NoteItem(id: 'a', text: 'Birinci'),
          NoteItem(id: 'b', text: 'İkinci'),
        ],
      );
      final text = note.toPlainText();
      expect(text, contains('1. Birinci'));
      expect(text, contains('2. İkinci'));
    });

    test('copyWith clearDeletedAt silinme bilgisini temizler', () {
      final note = Note(
        id: '1',
        type: NoteType.text,
        deletedAt: DateTime(2026),
      );
      expect(note.copyWith(clearDeletedAt: true).deletedAt, isNull);
    });
  });

  group('NoteType', () {
    test('fromId bilinmeyen tip için text döner', () {
      expect(NoteType.fromId('garip'), NoteType.text);
      expect(NoteType.fromId(null), NoteType.text);
      expect(NoteType.fromId('checklist'), NoteType.checklist);
    });
  });

  group('NoteColor', () {
    test('fromId kimlikleri doğru çözer', () {
      expect(NoteColor.fromId('red'), NoteColor.red);
      expect(NoteColor.fromId('bilinmeyen'), NoteColor.none);
    });
  });
}
