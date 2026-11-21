import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/quick_drop.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';

void main() {
  group('AL-2 Note.listKind & miktar toplama & reyon ekleme/sıralama', () {
    test('Note.listKind: null iken toMap hiç yazmaz (S16 +0 bayt), doluysa korunur', () {
      final plain = Note(id: '1', type: NoteType.checklist, title: 'Düz');
      expect(plain.toMap().containsKey('listKind'), isFalse);

      final shop = plain.copyWith(listKind: 'shopping');
      final map = shop.toMap()
        ..remove('createdAt')
        ..remove('updatedAt');
      expect(map['listKind'], 'shopping');
      final restored = Note.fromMap('1', map);
      expect(restored.listKind, 'shopping');
      expect(restored.extras.containsKey('listKind'), isFalse);

      // HAFIZA kural 5: sameRenderedNote listKind farkını görür.
      expect(sameRenderedNote(plain, shop), isFalse);
      expect(shop.copyWith(clearListKind: true).listKind, isNull);
    });

    test('combineQuickQuantities ve planDropIntoList(addQuantities: true)', () {
      expect(combineQuickQuantities('2', '1'), '3');
      expect(combineQuickQuantities('1 kg', '2 kg'), '3 kg');
      expect(combineQuickQuantities('500 g', '250 g'), '750 g');
      expect(combineQuickQuantities('1,5 L', '0,5 L'), '2 L');
      expect(combineQuickQuantities('1 kg', '2 adet'), '2 adet');

      final plan = planDropIntoList(
        [
          (text: 'Süt (2)', checked: false),
          (text: 'Domates (1 kg)', checked: false),
          (text: 'Ekmek (2)', checked: true),
        ],
        const [
          QuickItem(name: 'Süt', qty: '1'),
          QuickItem(name: 'Domates', qty: '2 kg'),
          QuickItem(name: 'Ekmek', qty: '1'),
        ],
        addQuantities: true,
      );
      expect(plan.requantify[0], 'Süt (3)');
      expect(plan.requantify[1], 'Domates (3 kg)');
      // İşaretli madde yeniden açılırken eski miktarın üstüne eklemez.
      expect(plan.uncheck, [2]);
      expect(plan.requantify[2], 'Ekmek (1)');
    });

    test('quickDropFields: akıllı market listesinde doğru reyona ekler ve miktar toplar', () {
      final note = Note(
        id: 'm1',
        type: NoteType.checklist,
        title: 'Alışveriş listesi',
        listKind: 'shopping',
        items: const [
          NoteItem(id: '1', text: 'Domates'),
          NoteItem(id: '2', text: 'Süt (2)'),
        ],
      );
      var seq = 0;
      final r = quickDropFields(
        note,
        'elma, 1 süt',
        locale: 'tr',
        newId: () => 'n${seq++}',
      );
      final texts = [
        for (final m in (r.fields['items'] as List).cast<Map<String, dynamic>>())
          m['text'],
      ];
      // Elma (manav) Domates'in hemen arkasına, Süt'ün önüne girer; Süt (2)+1 → Süt (3).
      expect(texts, ['Domates', 'Elma', 'Süt (3)']);
    });

    test('sortItemsBySmartGroup: alt başlık eklemeden reyona dizer, işaretliler sonda', () {
      final items = const [
        NoteItem(id: '1', text: 'Et'),
        NoteItem(id: '2', text: 'Süt', checked: true),
        NoteItem(id: '3', text: 'Domates'),
        NoteItem(id: '4', text: 'Ekmek'),
      ];
      final sorted = sortItemsBySmartGroup(
        items,
        kind: SmartListKind.shopping,
        locale: 'tr',
      );
      expect([for (final i in sorted) i.text], ['Domates', 'Ekmek', 'Et', 'Süt']);
    });
  });

  group('AL-3 genişletilmiş liste türleri ve sözlükler', () {
    test('öbekten tüm yeni türler tanınır (TR + EN)', () {
      expect(smartKindFromPhrase('eczane listesi'), SmartListKind.pharmacy);
      expect(smartKindFromPhrase('kırtasiye'), SmartListKind.stationery);
      expect(smartKindFromPhrase('tamirat listesi'), SmartListKind.hardware);
      expect(smartKindFromPhrase('kamp listesi'), SmartListKind.camping);
      expect(smartKindFromPhrase('bebek çantası'), SmartListKind.baby);
      expect(smartKindFromPhrase('spor çantası'), SmartListKind.sport);
      expect(smartKindFromPhrase('camping list'), SmartListKind.camping);
      expect(smartKindFromPhrase('gym bag'), SmartListKind.sport);
    });

    test('detectNoteListKind başlık ve maddelerden AL-3 türlerini bulur', () {
      final camp = Note(
        id: 'c1',
        type: NoteType.checklist,
        title: 'Hafta sonu',
        items: const [
          NoteItem(id: '1', text: 'Çadır'),
          NoteItem(id: '2', text: 'Uyku tulumu'),
          NoteItem(id: '3', text: 'Kafa lambası'),
        ],
      );
      expect(detectNoteListKind(camp, locale: 'tr'), SmartListKind.camping);
      final sorted = sortItemsBySmartGroup(
        [camp.items[2], camp.items[0]],
        kind: SmartListKind.camping,
        locale: 'tr',
      );
      // Çadır (barınma, grup 0) Kafa lambası'ndan (aydınlatma, grup 2) önce.
      expect([for (final i in sorted) i.text], ['Çadır', 'Kafa lambası']);
    });
  });

  group('AL-4 öğrenen kategori ve yerel tahmin', () {
    test('kişisel grup eşlemesi sözlüğün önüne geçer ve JSON roundtrip korunur', () {
      final mem = const QuickEntryMemory().withItemGroup('Özel ürün', 0);
      final restored = QuickEntryMemory.decode(mem.encode());
      expect(restored.itemGroups['ozel urun'], 0);

      final items = const [
        NoteItem(id: '1', text: 'Et'),
        NoteItem(id: '2', text: 'Özel ürün'),
      ];
      final sorted = sortItemsBySmartGroup(
        items,
        kind: SmartListKind.shopping,
        locale: 'tr',
        learnedGroups: restored.itemGroups,
      );
      expect(sorted.first.text, 'Özel ürün');
    });

    test('predictDue: her hafta alınan ve 9 gündür alınmayan ürünü önerir', () {
      var mem = const QuickEntryMemory();
      mem = mem.recorded('smart:market', ['Süt', 'Yumurta'], at: DateTime(2026, 11));
      mem = mem.recorded('smart:market', ['Süt'], at: DateTime(2026, 11, 8));
      mem = mem.recorded('smart:market', ['Yumurta'], at: DateTime(2026, 11, 15));

      final restored = QuickEntryMemory.decode(mem.encode());
      final due = restored.predictDue('smart:market', now: DateTime(2026, 11, 17));
      // Süt: 7 günlük döngü, 9 gün geçmiş → gecikmiş; Yumurta: 14 gün döngü, 2 gün geçmiş → değil.
      expect(due.map((d) => d.name).toList(), ['Süt']);
      expect(due.single.avgDays, 7);
      expect(due.single.daysSince, 9);
    });
  });
}
