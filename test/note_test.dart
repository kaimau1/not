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

    test('toContentText işaretleri ve başlığı katmaz', () {
      const note = Note(
        id: '1',
        type: NoteType.checklist,
        title: 'Alışveriş',
        items: [
          NoteItem(id: 'a', text: 'Süt', checked: true),
          NoteItem(id: 'b', text: 'Ekmek'),
        ],
      );
      final text = note.toContentText();
      expect(text, isNot(contains('Alışveriş')));
      expect(text, isNot(contains('[x]')));
      expect(text, 'Süt\nEkmek');
    });

    test('toContentText(skipChecked: true) işaretli maddeyi dışlar', () {
      const note = Note(
        id: '1',
        type: NoteType.checklist,
        items: [
          NoteItem(id: 'a', text: 'Süt', checked: true),
          NoteItem(id: 'b', text: 'Ekmek'),
          NoteItem(id: 'c', text: 'Yumurta', checked: true),
        ],
      );
      // İşaretsiz yalnız "Ekmek" kalır; tamamlananlar AI'a gitmez.
      expect(note.toContentText(skipChecked: true), 'Ekmek');
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
        archivedAt: DateTime(2026, 4),
      );
      final cleared =
          note.copyWith(clearReminderAt: true, clearArchivedAt: true);
      expect(cleared.reminderAt, isNull);
      expect(cleared.archivedAt, isNull);
      expect(note.copyWith().reminderAt, isNotNull);
    });

    test('yıldız sabitlemeden ayrı okunur ve yazılır (2026-10-20)', () {
      final note = Note.fromMap('1', {'type': 'text', 'starred': true});
      expect(note.starred, isTrue);
      expect(note.pinned, isFalse);
      expect(note.toMap()['starred'], isTrue);
      expect(note.toMap()['pinned'], isFalse);
      // copyWith başka alan değişince yıldız korunur.
      expect(note.copyWith(title: 'x').starred, isTrue);
      expect(note.copyWith(starred: false).toMap()['starred'], isFalse);
    });

    test('zemin ve çerçeve bağımsız okunur (2026-10-20)', () {
      final note = Note.fromMap('1', {
        'type': 'text',
        'color': 'default',
        'frameColor': 'red',
      });
      expect(note.color, NoteColor.none);
      expect(note.frameColor, NoteColor.red);
      expect(note.toMap()['frameColor'], 'red');
    });

    test('etiketler toMap çıktısına yazılır', () {
      const note = Note(
        id: '1',
        type: NoteType.text,
        tags: ['is', 'ev'],
      );
      expect(note.toMap()['tags'], ['is', 'ev']);
    });

    test('copyWith tipi değiştirebilir (AI listeye çevir)', () {
      const note = Note(id: '1', type: NoteType.text, body: 'a\nb');
      final asList = note.copyWith(type: NoteType.checklist, body: '');
      expect(asList.type, NoteType.checklist);
      expect(note.copyWith().type, NoteType.text);
    });

    test('klasör alanı copyWith ve toMap/fromMap ile korunur', () {
      const note = Note(id: '1', type: NoteType.text, folderId: 'f1');
      expect(note.toMap()['folderId'], 'f1');
      expect(note.copyWith(title: 'x').folderId, 'f1');
      expect(note.copyWith(clearFolderId: true).folderId, isNull);
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

  test('boyut ve seffaflik HER ZAMAN belgeye yazilir', () {
    // Belgeler set(..., merge: true) ile guncelleniyor: alan haritada yoksa
    // Firestore'daki ESKI deger kalir. Kosullu yazilirsa kullanici degeri
    // %100'e geri cektiginde ayar geri geliyordu (v1.0.178 hatasi).
    const plain = Note(id: 'n1', type: NoteType.text);
    expect(plain.textOpacity, 1);
    expect(plain.toMap()['textOpacity'], 1);
    expect(plain.toMap()['fontScale'], 1);
    final faded = plain.copyWith(textOpacity: 0.6);
    expect(faded.toMap()['textOpacity'], 0.6);
  });

  test('zemin gorseli kaydedilir ve KALDIRILABILIR', () {
    // Alanlar kosulsuz yazilir: merge:true ile alan haritada yoksa eski deger
    // kalirdi ve zemin bir daha kaldirilamazdi (bkz. seffaflik hatasi).
    const plain = Note(id: 'n1', type: NoteType.text);
    expect(plain.backgroundImageId, isNull);
    expect(plain.toMap().containsKey('backgroundImageId'), isTrue);
    final withBg = plain.copyWith(
      backgroundImageId: 'att1',
      backgroundOpacity: 0.5,
    );
    expect(withBg.toMap()['backgroundImageId'], 'att1');
    expect(withBg.toMap()['backgroundOpacity'], 0.5);
    final cleared = withBg.copyWith(clearBackgroundImage: true);
    expect(cleared.backgroundImageId, isNull);
    expect(cleared.toMap()['backgroundImageId'], isNull);
  });
}
