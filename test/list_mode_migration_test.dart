import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folder_order.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/note_package.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/text_merge.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/shopping/domain/shop_item_meta.dart';
import 'package:notlar/features/smart_lists/domain/smart_item_meta.dart';

void main() {
  group('Faz 1 — Veri modeli, okuma migrasyonu ve Kural 1/2/3/4', () {
    test('Kural 1: NoteItem şemasında isGhost yok; tüm kanonik anahtarlar knownKeys içinde', () {
      expect(NoteItem.knownKeys.contains('isGhost'), isFalse);
      final item = NoteItem(
        id: 'i1',
        text: 'Domates',
        category: 'produce',
        quantity: 2,
        unit: 'kg',
        price: 65,
        doneDays: const ['2026-11-26', '2026-11-27'],
        priority: ItemPriority.high,
        dueDate: DateTime(2026, 11, 28, 10),
      );
      final map = item.toMap();
      expect(NoteItem.knownKeys.containsAll(map.keys), isTrue);
      final back = NoteItem.fromMap(map);
      expect(back.category, 'produce');
      expect(back.quantity, 2);
      expect(back.unit, 'kg');
      expect(back.price, 65);
      expect(back.doneDays, ['2026-11-26', '2026-11-27']);
      expect(back.priority, ItemPriority.high);
      expect(back.dueDate, DateTime(2026, 11, 28, 10));
      expect(back.extras, isEmpty);
    });

    test('Kural 3: eski extras (q/u/p/g/hd/hc) okununca kanonik alanlara taşınır, çift yazım olmaz', () {
      final legacy = NoteItem.fromMap({
        'id': 's1',
        'text': 'Süt',
        'checked': false,
        'q': 2,
        'u': 'lt',
        'p': 45.5,
        'g': 2, // breakfast
        's': 'migros',
      });
      expect(legacy.quantity, 2.0);
      expect(legacy.unit, 'lt');
      expect(legacy.price, 45.5);
      expect(legacy.category, 'breakfast');
      expect(legacy.extras, {'s': 'migros'});

      final wire = legacy.toMap();
      expect(wire['quantity'], 2.0);
      expect(wire['unit'], 'lt');
      expect(wire['price'], 45.5);
      expect(wire['category'], 'breakfast');
      expect(wire['s'], 'migros');
      expect(wire.containsKey('q'), isFalse);
      expect(wire.containsKey('u'), isFalse);
      expect(wire.containsKey('p'), isFalse);
      expect(wire.containsKey('g'), isFalse);

      // ShopItemMeta ince wrapper: yalnız kanonik alanlara yazar.
      final updated = ShopItemMeta.fromItem(legacy)
          .copyWith(qty: 3, unitPrice: 50, aisle: 0)
          .applyToItem(legacy);
      expect(updated.quantity, 3.0);
      expect(updated.price, 50.0);
      expect(updated.category, 'produce');
      expect(updated.extras, {'s': 'migros'});
    });

    test('Kural 2: streakCount doneDays üzerinden deterministik hesaplanır ve mergeItems3 union birleştirir', () {
      final base = NoteItem.fromMap({
        'id': 'h1',
        'text': 'Su iç',
        'checked': true,
        'hd': ['2026-11-24', '2026-11-25'],
      });
      expect(base.doneDays, ['2026-11-24', '2026-11-25']);
      expect(base.extras.containsKey('hd'), isFalse);
      expect(base.streakCountAt(DateTime(2026, 11, 25)), 2);
      expect(base.streakCountAt(DateTime(2026, 11, 26)), 2);
      expect(base.streakCountAt(DateTime(2026, 11, 27)), 0);
      expect(base.lastCompletedAt, DateTime(2026, 11, 25));

      // İki cihaz çevrimdışı farklı günleri işaretler -> union.
      final deviceA = base.toggledDoneDay('2026-11-26');
      final deviceB = base.toggledDoneDay('2026-11-27');
      final merged = mergeItems3([base], [deviceA], [deviceB]);
      expect(merged.single.doneDays, [
        '2026-11-24',
        '2026-11-25',
        '2026-11-26',
        '2026-11-27',
      ]);
      expect(merged.single.streakCountAt(DateTime(2026, 11, 27)), 4);

      // HabitItemMeta ince wrapper: doneDays'i kanonik alana yazar, hd siler.
      final viaMeta = HabitItemMeta.fromItem(base)
          .toggledOn('2026-11-26')
          .applyToItem(base, todayKey: '2026-11-26');
      expect(viaMeta.doneDays, ['2026-11-24', '2026-11-25', '2026-11-26']);
      expect(viaMeta.extras.containsKey('hd'), isFalse);
    });

    test('Note.fromMap eski listKind değerinden listMode ve resetSchedule türetir; S16 +0 bayt', () {
      final plain = const Note(id: 'n1', type: NoteType.text);
      final plainMap = plain.toMap();
      expect(plainMap.containsKey('listMode'), isFalse);
      expect(plainMap.containsKey('resetSchedule'), isFalse);
      expect(plainMap.containsKey('contextTimeSlot'), isFalse);
      expect(plainMap.containsKey('isQuickInbox'), isFalse);

      final legacyHabit = Note.fromMap('n2', {
        'type': 'checklist',
        'title': 'Alışkanlıklar',
        'listKind': 'habits',
      });
      expect(legacyHabit.listMode, ListMode.routine);
      expect(legacyHabit.resetSchedule, ResetSchedule.daily);

      final legacyPack = Note.fromMap('n3', {
        'type': 'checklist',
        'title': 'Bavul',
        'listKind': 'packing',
      });
      expect(legacyPack.listMode, ListMode.template);

      // NotePackage gidiş-dönüş (listKind + listMode + structured NoteItem + dueDate)
      final rich = Note(
        id: 'n4',
        type: NoteType.checklist,
        title: 'Proje',
        listKind: 'moving',
        listMode: ListMode.project,
        resetSchedule: ResetSchedule.weekly,
        resetCustomDays: const [1, 4],
        lastResetAt: DateTime(2026, 11, 25),
        contextTimeSlot: ContextTimeSlot.morning,
        items: [
          NoteItem(
            id: 'p1',
            text: 'Sunum hazırla',
            priority: ItemPriority.urgent,
            dueDate: DateTime(2026, 11, 28, 10),
          ),
        ],
      );
      final decoded = decodeNoteJson(encodeNoteJson(rich));
      expect(decoded.listKind, 'moving');
      expect(decoded.listMode, ListMode.project);
      expect(decoded.resetSchedule, ResetSchedule.weekly);
      expect(decoded.resetCustomDays, [1, 4]);
      expect(decoded.lastResetAt, DateTime(2026, 11, 25));
      expect(decoded.contextTimeSlot, ContextTimeSlot.morning);
      expect(decoded.items.single.priority, ItemPriority.urgent);
      expect(decoded.items.single.dueDate, DateTime(2026, 11, 28, 10));

      // HAFIZA kural 5: sameRenderedNote ve sameItemsVisually farkları görür.
      expect(
        sameRenderedNote(rich, rich.copyWith(listMode: ListMode.template)),
        isFalse,
      );
      expect(
        sameItemsVisually(
          rich.items,
          [rich.items.single.copyWith(priority: ItemPriority.low)],
        ),
        isFalse,
      );
    });

    test('Kural 4: Hızlı Not klasörü bekleyen madde sayısı rozeti', () {
      const folder = NoteFolder(
        id: 'f-quick',
        name: 'Hızlı Not',
        icon: 'bolt',
        ownerId: 'u1',
        systemRole: NoteFolder.roleQuickInbox,
      );
      expect(folder.isQuickInbox, isTrue);
      expect(folder.toMap()['systemRole'], 'quick_inbox');

      final notes = [
        const Note(
          id: 'q1',
          type: NoteType.checklist,
          title: 'Hızlı Not',
          folderId: 'f-quick',
          isQuickInbox: true,
          items: [
            NoteItem(id: 'a', text: 'Fatura öde'),
            NoteItem(id: 'b', text: 'Tamamlanan', checked: true),
            NoteItem(id: 'c', text: 'Başlık', header: true),
            NoteItem(id: 'd', text: 'Kargoyu al'),
          ],
        ),
        const Note(
          id: 'q2',
          type: NoteType.text,
          title: 'Kilitli',
          body: 'gizli',
          folderId: 'f-quick',
          locked: true,
        ),
      ];
      expect(quickInboxPendingItemCount(notes, 'f-quick'), 2);
      // Boşalansa bile isQuickInbox notu isEmpty sayılmaz (sessizce silinmez).
      const emptyInbox = Note(
        id: 'q-empty',
        type: NoteType.checklist,
        folderId: 'f-quick',
        isQuickInbox: true,
      );
      expect(emptyInbox.isEmpty, isFalse);
    });
  });
}
