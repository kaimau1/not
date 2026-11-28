import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/routine_reset.dart';

void main() {
  group('RoutineResetEngine', () {
    test('günlük rutin ertesi gün tikleri sıfırlar ama doneDays ve seriyi korur (Kural 2)', () {
      final yesterday = DateTime(2026, 11, 26);
      final today = DateTime(2026, 11, 27, 8, 30);
      final note = Note(
        id: 'r1',
        type: NoteType.checklist,
        title: 'Sabah Rutini',
        listMode: ListMode.routine,
        resetSchedule: ResetSchedule.daily,
        lastResetAt: yesterday,
        items: [
          NoteItem(
            id: 'i1',
            text: 'Su iç',
            checked: true,
            doneDays: [
              isoDayKeyOf(DateTime(2026, 11, 24)),
              isoDayKeyOf(DateTime(2026, 11, 25)),
              isoDayKeyOf(yesterday),
            ],
          ),
          const NoteItem(id: 'i2', text: 'Esneme'),
        ],
      );

      expect(RoutineResetEngine.needsReset(note, today), isTrue);
      final reset = RoutineResetEngine.resetNote(note, today);

      expect(reset.items.length, 2);
      expect(reset.items.first.checked, isFalse);
      // Kural 2: doneDays geçmişi ve seri aynen korunur!
      expect(reset.items.first.doneDays, hasLength(3));
      expect(reset.items.first.streakCountAt(today), 3);
      expect(reset.lastResetAt, DateTime(2026, 11, 27));
      expect(RoutineResetEngine.needsReset(reset, today), isFalse);
    });

    test('bugün işaretlenmiş madde (lastResetAt null olsa bile) sıfırlanmaz', () {
      final today = DateTime(2026, 11, 27, 10);
      final note = Note(
        id: 'r-new',
        type: NoteType.checklist,
        title: 'Yeni Rutin',
        listMode: ListMode.routine,
        resetSchedule: ResetSchedule.daily,
        items: [
          NoteItem(
            id: 'i1',
            text: 'Vitamin',
            checked: true,
            doneDays: [isoDayKeyOf(today)],
          ),
        ],
      );

      expect(RoutineResetEngine.needsReset(note, today), isFalse);
    });

    test('haftalık rutin Pazartesi sınırında sıfırlar, hafta içinde sıfırlamaz', () {
      final sunday = DateTime(2026, 11, 22);
      final monday = DateTime(2026, 11, 23, 9);
      final wednesday = DateTime(2026, 11, 25, 9);

      final note = Note(
        id: 'r-week',
        type: NoteType.checklist,
        title: 'Haftalık Temizlik',
        listMode: ListMode.routine,
        resetSchedule: ResetSchedule.weekly,
        lastResetAt: DateTime(2026, 11, 16),
        items: [
          NoteItem(
            id: 'i1',
            text: 'Çarşafları değiştir',
            checked: true,
            doneDays: [isoDayKeyOf(sunday)],
          ),
        ],
      );

      expect(RoutineResetEngine.needsReset(note, monday), isTrue);
      final reset = RoutineResetEngine.resetNote(note, monday);
      expect(reset.items.single.checked, isFalse);
      expect(reset.lastResetAt, DateTime(2026, 11, 23));

      // Çarşamba günü yeniden sıfırlamaz
      final checkedWed = reset.copyWith(
        items: [reset.items.single.toggledDoneDay(isoDayKeyOf(wednesday))],
      );
      expect(RoutineResetEngine.needsReset(checkedWed, wednesday), isFalse);
    });

    test('özel günler (Pzt/Çar/Cum) yalnızca seçili günlerde sıfırlar ve kilitli notu atlar', () {
      // 2026-11-25 Çarşamba (weekday=3), 2026-11-26 Perşembe (weekday=4), 2026-11-27 Cuma (weekday=5)
      final wed = DateTime(2026, 11, 25);
      final thu = DateTime(2026, 11, 26, 10);
      final fri = DateTime(2026, 11, 27, 10);

      final custom = Note(
        id: 'r-custom',
        type: NoteType.checklist,
        title: 'Antrenman',
        listMode: ListMode.routine,
        resetSchedule: ResetSchedule.customDays,
        resetCustomDays: const [1, 3, 5],
        lastResetAt: wed,
        items: [
          NoteItem(
            id: 'i1',
            text: 'Koşu',
            checked: true,
            doneDays: [isoDayKeyOf(wed)],
          ),
        ],
      );

      // Perşembe günü hâlâ Çarşamba dönemindeyiz → sıfırlamaz.
      expect(RoutineResetEngine.needsReset(custom, thu), isFalse);
      // Cuma yeni dönem → sıfırlar.
      expect(RoutineResetEngine.needsReset(custom, fri), isTrue);

      // Kilitli not asla sıfırlanmaz.
      final locked = custom.copyWith(locked: true);
      expect(RoutineResetEngine.needsReset(locked, fri), isFalse);
    });
  });
}
