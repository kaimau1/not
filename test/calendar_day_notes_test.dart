import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Kullanıcı isteği 2026-11-21: güne bağlı not takvimde (ay hücresi, gün
/// çizelgesi, ana ekran şeridi) görünür; saatle bağlanabilir, taşınabilir.
void main() {
  const note = Note(id: 'n1', type: NoteType.text, title: '24 Kasım Salı');

  test('saatsiz bağ tüm gün, saatli bağ o saatte', () {
    final agenda = buildAgenda(
      from: DateTime(2026, 11, 23),
      to: DateTime(2026, 11, 26),
      dayNotes: {
        '2026-11-24': [(note: note, minutes: null)],
        '2026-11-25': [(note: note, minutes: 9 * 60 + 30)],
        '2026-12-01': [(note: note, minutes: null)],
      },
    );
    expect(agenda.keys, ['2026-11-24', '2026-11-25']);
    final allDay = agenda['2026-11-24']!.single as ReminderEntry;
    expect(allDay.isDayLink, isTrue);
    expect(allDay.allDay, isTrue);
    final timed = agenda['2026-11-25']!.single as ReminderEntry;
    expect(timed.allDay, isFalse);
    expect(timed.at, DateTime(2026, 11, 25, 9, 30));
  });

  test('bağ başka güne taşınır, saat korunur', () {
    final e = ReminderEntry(
      note,
      DateTime(2026, 11, 25, 9, 30),
      linkDay: '2026-11-25',
      linkTimed: true,
    );
    expect(canMoveEntry(e), isTrue);
    final moved = movedToDay(e, DateTime(2026, 11, 27)) as DayLinkMove;
    expect(moved.from, '2026-11-25');
    expect(moved.to, '2026-11-27');
    expect(moved.minutes, 570);
    expect(movedToDay(e, DateTime(2026, 11, 25)), isNull);
  });
}
