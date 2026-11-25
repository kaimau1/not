import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/utils/note_e2ee.dart';
import 'package:notlar/core/utils/note_e2ee_session.dart';
import 'package:notlar/features/notes/data/starter_notes.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Faz 4 — E2EE Kilitli Notlar (AES-256-GCM)', () {
    setUp(NoteE2eeSession.debugReset);
    tearDown(NoteE2eeSession.debugReset);

    test('şifreleme/çözme tam turu, yanlış anahtar ve bozuk veri reddi', () {
      final key = NoteE2ee.deriveKey('gizli-parola', 'tuz-1', iterations: 100);
      final wrong = NoteE2ee.deriveKey(
        'baska-parola',
        'tuz-1',
        iterations: 100,
      );
      const plain = 'IBAN: TR12 3456 7890 — Türkçe karakterler ğüşiöç';

      final enc = NoteE2ee.encryptText(plain, key, aad: 'note-1');
      expect(NoteE2ee.isEncrypted(enc), isTrue);
      expect(enc, isNot(contains('IBAN')));
      expect(NoteE2ee.decryptText(enc, key, aad: 'note-1'), plain);
      expect(NoteE2ee.decryptText(enc, wrong, aad: 'note-1'), isNull);
      expect(NoteE2ee.decryptText(enc, key, aad: 'note-2'), isNull);
      // Geriye uyumluluk: şifresiz metin olduğu gibi döner.
      expect(NoteE2ee.decryptText('eski düz metin', key), 'eski düz metin');
    });

    test('Note.toMap/fromMap kilitli notu şifreler, kilitsiz nota dokunmaz', () {
      final key = Uint8List.fromList(List.generate(32, (i) => i + 7));
      NoteE2eeSession.setKey(key);

      final lockedNote = Note(
        id: 'sec-1',
        type: NoteType.checklist,
        title: 'Kasa',
        body: 'gizli gövde',
        items: const [NoteItem(id: 'i1', text: 'gizli madde')],
        locked: true,
      );
      final map = lockedNote.toMap();
      expect(map['body'], '');
      expect(map['items'], isEmpty);
      expect(NoteE2ee.isEncrypted(map['e2ee'] as String?), isTrue);

      final persisted = Map<String, dynamic>.from(map)
        ..remove('createdAt')
        ..remove('updatedAt');
      final restored = Note.fromMap('sec-1', persisted);
      expect(restored.body, 'gizli gövde');
      expect(restored.items.single.text, 'gizli madde');
      expect(restored.extras.containsKey('e2ee'), isFalse);

      // Kilitsiz not: e2ee anahtarı hiç yazılmaz (S16 bayt bütçesi sıfır fark).
      final openNote = Note(
        id: 'open-1',
        type: NoteType.text,
        title: 'Açık',
        body: 'normal metin',
      );
      final openMap = openNote.toMap();
      expect(openMap.containsKey('e2ee'), isFalse);
      expect(openMap['body'], 'normal metin');
    });
  });

  group('Faz 4 — 3 Hazır Arayüz Profili', () {
    setUp(Personalize.debugReset);
    tearDown(Personalize.debugReset);

    test(
      'Sade / Standart / Tablet & Kalem profilleri uygulanır ve tanınır',
      () {
        expect(Personalize.activeProfile, UiProfile.standard);

        Personalize.applyProfile(UiProfile.simple);
        expect(Personalize.activeProfile, UiProfile.simple);
        expect(Personalize.current.shows(UiItem.barPen), isFalse);
        expect(Personalize.current.shows(UiItem.topTheme), isFalse);

        Personalize.applyProfile(UiProfile.tabletPen);
        expect(Personalize.activeProfile, UiProfile.tabletPen);
        expect(Personalize.current.shows(UiItem.barPen), isTrue);
        expect(Personalize.current.shows(UiItem.barUndo), isTrue);
        expect(Personalize.current.shows(UiItem.barTable), isTrue);

        Personalize.applyProfile(UiProfile.standard);
        expect(Personalize.activeProfile, UiProfile.standard);
      },
    );
  });

  group('Faz 4 — İlk 60 Saniye Başlangıç Notları', () {
    test(
      'boş hesapta 2 örnek not bir kez üretilir, ikinci çağrıda tekrarlanmaz',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final saved = <Note>[];
        final first = await seedStarterNotesIfNeeded(
          prefs: prefs,
          hasExistingNotes: false,
          saveNote: (n) async => saved.add(n),
        );
        expect(first, isTrue);
        expect(saved, hasLength(2));
        expect(saved.first.items, isNotEmpty);

        final second = await seedStarterNotesIfNeeded(
          prefs: prefs,
          hasExistingNotes: false,
          saveNote: (n) async => saved.add(n),
        );
        expect(second, isFalse);
        expect(saved, hasLength(2));
      },
    );
  });
}
