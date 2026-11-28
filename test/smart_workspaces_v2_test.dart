import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/smart_lists/domain/smart_item_meta.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  group('SmartItemMeta domain codecs & S16 zero-overhead rules', () {
    test(
      'HabitItemMeta toggles days, computes streaks, leaves default empty',
      () {
        const bare = NoteItem(id: '1', text: '2L su');
        final def = HabitItemMeta.fromItem(bare).applyToItem(bare);
        expect(def.extras, isEmpty);

        final today = DateTime(2026, 11, 27);
        final meta = const HabitItemMeta()
            .toggledOn(isoDayKey(today.subtract(const Duration(days: 2))))
            .toggledOn(isoDayKey(today.subtract(const Duration(days: 1))))
            .toggledOn(isoDayKey(today));
        expect(meta.currentStreak(today), 3);
        expect(meta.bestStreak(), 3);

        final saved = meta.applyToItem(bare, todayKey: isoDayKey(today));
        expect(saved.checked, isTrue);
        expect(saved.doneDays, hasLength(3));
        expect(saved.streakCountAt(today), 3);
        final roundTrip = HabitItemMeta.fromItem(saved);
        expect(roundTrip.doneDays, hasLength(3));
      },
    );

    test('WorkoutItemMeta toggles sets progressively and resets cleanly', () {
      const bare = NoteItem(id: 'w1', text: 'Bench Press');
      final m0 = WorkoutItemMeta.fromItem(bare);
      expect(m0.sets, 3);
      expect(m0.doneSets, 0);

      final m2 = m0.toggleSet(2);
      expect(m2.doneSets, 2);
      final m3 = m2.toggleSet(3);
      expect(m3.doneSets, 3);
      final applied = m3.applyToItem(bare);
      expect(applied.checked, isTrue);

      final undone = m3.toggleSet(3);
      expect(undone.doneSets, 2);
    });

    test('parseExpenseQuickInput extracts numbers cleanly', () {
      final a = parseExpenseQuickInput('Elektrik 850');
      expect(a.title, 'Elektrik');
      expect(a.amount, 850.0);

      final b = parseExpenseQuickInput('Kira 12500 tl');
      expect(b.title, 'Kira');
      expect(b.amount, 12500.0);
    });

    test('listModeFromLegacyKind maps legacy workspace kinds to 4 adaptive modes', () {
      expect(listModeFromLegacyKind('shopping'), ListMode.shopping);
      expect(listModeFromLegacyKind('habits'), ListMode.routine);
      expect(listModeFromLegacyKind('workout'), ListMode.routine);
      expect(listModeFromLegacyKind('packing'), ListMode.template);
      expect(listModeFromLegacyKind('moving'), ListMode.project);
      expect(listModeFromLegacyKind(null), ListMode.general);
    });
  });
}
