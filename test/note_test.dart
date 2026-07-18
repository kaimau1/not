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

    test('copyWith hatırlatıcı ve arşiv alanlarını temizleyebilir', () {
      final note = Note(
        id: '1',
        type: NoteType.text,
        reminderAt: DateTime(2026, 5, 1, 9),
        archivedAt: DateTime(2026, 4, 1),
      );
      final cleared =
          note.copyWith(clearReminderAt: true, clearArchivedAt: true);
      expect(cleared.reminderAt, isNull);
      expect(cleared.archivedAt, isNull);
      expect(note.copyWith().reminderAt, isNotNull);
    });

    test('yıldız copyWith ile değişir ve toMap/fromMap yazılır', () {
      const note = Note(id: '1', type: NoteType.text);
      expect(note.starred, isFalse);
      final starred = note.copyWith(starred: true);
      expect(starred.starred, isTrue);
      expect(starred.toMap()['starred'], isTrue);
      // copyWith başka alan değişince yıldız korunur.
      expect(starred.copyWith(title: 'x').starred, isTrue);
    });

    test('etiketler toMap çıktısına yazılır', () {
      const note = Note(
        id: '1',
        type: NoteType.text,
        tags: ['is', 'ev'],
      );
      expect(note.toMap()['tags'], ['is', 'ev']);
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
