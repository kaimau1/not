import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/reminder_service.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/reminder_repeat.dart';

/// F18.14: tekrarlayan hatırlatıcının sonraki çalma hesabı.
void main() {
  test('dize gidiş-dönüş', () {
    for (final s in [
      'daily',
      'weekdays',
      'weekly:1,3',
      'monthly:31',
      'yearly:2-29',
    ]) {
      expect(ReminderRepeat.parse(s).encode(), s);
    }
    expect(ReminderRepeat.parse('').isNone, isTrue);
    expect(ReminderRepeat.parse('bilinmeyen').isNone, isTrue);
  });

  test('her gün: saat korunur, geçtiyse yarın', () {
    final anchor = DateTime(2026, 11, 2, 9);
    expect(
      ReminderRepeat.daily.next(anchor, DateTime(2026, 11, 2, 8)),
      DateTime(2026, 11, 2, 9),
    );
    expect(
      ReminderRepeat.daily.next(anchor, DateTime(2026, 11, 2, 9)),
      DateTime(2026, 11, 3, 9),
    );
  });

  test('hafta içi: cuma → pazartesi', () {
    final fri = DateTime(2026, 11, 6, 9); // cuma
    expect(fri.weekday, DateTime.friday);
    expect(ReminderRepeat.weekdays.next(fri, fri), DateTime(2026, 11, 9, 9));
  });

  test('her hafta seçili günler', () {
    final r = ReminderRepeat.weekly([3, 1]);
    expect(r.encode(), 'weekly:1,3');
    final mon = DateTime(2026, 11, 2, 9); // pazartesi
    expect(r.next(mon, mon), DateTime(2026, 11, 4, 9)); // çarşamba
    expect(r.next(mon, DateTime(2026, 11, 4, 9)), DateTime(2026, 11, 9, 9));
  });

  test('her ay 31: kısa ayda ay sonu, sonra yine 31', () {
    final r = ReminderRepeat.monthly.anchoredTo(DateTime(2027, 1, 31, 8));
    final feb = r.next(DateTime(2027, 1, 31, 8), DateTime(2027, 1, 31, 8));
    expect(feb, DateTime(2027, 2, 28, 8));
    // Çapa artık 28 Şubat ama gün dizede 31.
    expect(r.next(feb!, feb), DateTime(2027, 3, 31, 8));
  });

  test('her yıl 29 Şubat: artık olmayan yılda 28', () {
    final r = ReminderRepeat.yearly.anchoredTo(DateTime(2028, 2, 29, 10));
    expect(
      r.next(DateTime(2028, 2, 29, 10), DateTime(2028, 2, 29, 10)),
      DateTime(2029, 2, 28, 10),
    );
    expect(
      r.next(DateTime(2029, 2, 28, 10), DateTime(2031, 3, 2)),
      DateTime(2032, 2, 29, 10),
    );
  });

  test('yaz saati: duvar saati korunur', () {
    // Avrupa'da 2026-03-29 saat ileri alınır; yerel saat dilimi testte UTC
    // olabilir — takvim günü ilerletildiği için saat her durumda 9.
    final anchor = DateTime(2026, 3, 28, 9);
    final n = ReminderRepeat.daily.next(anchor, anchor)!;
    expect(n.day, 29);
    expect(n.hour, 9);
  });

  test('sonraki birkaç çalma', () {
    final anchor = DateTime(2026, 11, 2, 9);
    final list = ReminderRepeat.daily.upcoming(anchor, anchor, 3);
    expect(list, [
      DateTime(2026, 11, 3, 9),
      DateTime(2026, 11, 4, 9),
      DateTime(2026, 11, 5, 9),
    ]);
  });

  test('planlama: tek seferlik geçmişte yok, tekrarlı ilerler', () {
    final now = DateTime(2026, 11, 2, 12);
    final once = Note(
      id: 'a',
      type: NoteType.text,
      reminderAt: DateTime(2026, 11, 2, 9),
    );
    expect(reminderFireTimes(once, now), isEmpty);
    final daily = once.copyWith(reminderRepeat: 'daily');
    final times = reminderFireTimes(daily, now, count: 3);
    expect(times, [
      DateTime(2026, 11, 3, 9),
      DateTime(2026, 11, 4, 9),
      DateTime(2026, 11, 5, 9),
    ]);
  });
}
