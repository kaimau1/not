import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/data/calendar_backup.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// TAKVIM_PLANI F47.5 (sürükleyerek taşıma) ve F46.5 (takvim yedeği).
void main() {
  group('movedToDay', () {
    final event = CalendarEvent(
      id: 'e',
      title: 'Toplantı',
      start: DateTime(2026, 11, 6, 14, 30),
      end: DateTime(2026, 11, 6, 15, 30),
    );

    test('etkinlik saati korunarak güne kayar', () {
      final moved = movedToDay(
        EventOccurrence(event, event.start),
        DateTime(2026, 11, 9),
      ) as CalendarEvent;
      expect(moved.start, DateTime(2026, 11, 9, 14, 30));
      expect(moved.end, DateTime(2026, 11, 9, 15, 30));
    });

    test('aynı gün ve tekrarlı etkinlik taşınmaz', () {
      expect(
        movedToDay(EventOccurrence(event, event.start), DateTime(2026, 11, 6)),
        isNull,
      );
      final weekly = event.copyWith(repeat: 'weekly:5');
      expect(canMoveEntry(EventOccurrence(weekly, weekly.start)), isFalse);
      expect(
        movedToDay(
          EventOccurrence(weekly, weekly.start),
          DateTime(2026, 11, 7),
        ),
        isNull,
      );
    });

    test('görevin günü değişir, saati kalır; tamamlanmış taşınmaz', () {
      const task = TaskItem(
        id: 't',
        title: 'Fatura',
        due: '2026-11-06',
        dueTime: '09:00',
      );
      final moved =
          movedToDay(TaskEntry(task), DateTime(2026, 11, 10)) as TaskItem;
      expect(moved.due, '2026-11-10');
      expect(moved.dueTime, '09:00');
      expect(
        movedToDay(
          TaskEntry(task.copyWith(completed: true)),
          DateTime(2026, 11, 10),
        ),
        isNull,
      );
    });

    test('tekrarlı hatırlatıcıda serinin başı oluş farkı kadar kayar', () {
      final note = Note(
        id: 'n',
        type: NoteType.text,
        reminderAt: DateTime(2026, 11, 2, 8),
        reminderRepeat: 'daily',
      );
      // 6 Kasım'daki oluş 8 Kasım'a sürüklendi: +2 gün.
      final moved = movedToDay(
        ReminderEntry(note, DateTime(2026, 11, 6, 8)),
        DateTime(2026, 11, 8),
      ) as Note;
      expect(moved.reminderAt, DateTime(2026, 11, 4, 8));
    });
  });

  group('takvim yedeği', () {
    test('JSON gidiş-dönüş; not kimlikleri yeniden eşlenir', () {
      final snapshot = CalendarSnapshot(
        events: [
          CalendarEvent(
            id: 'e1',
            title: 'Diş hekimi',
            start: DateTime(2026, 11, 6, 14),
            end: DateTime(2026, 11, 6, 15),
            noteIds: const ['eski1', 'kayip'],
            createdAt: DateTime(2026, 11, 1, 9),
          ),
          CalendarEvent(
            id: 'sil',
            title: 'Silinmiş',
            start: DateTime(2026, 11, 6),
            end: DateTime(2026, 11, 7),
            allDay: true,
            deletedAt: DateTime(2026, 11, 2),
          ),
        ],
        tasks: const [
          TaskItem(id: 't1', title: 'Görev', noteId: 'eski1', noteItemId: 'm'),
          TaskItem(id: 't2', title: 'Bağsız', noteId: 'kayip', noteItemId: 'm'),
        ],
        lists: const [TaskList(id: 'l1', title: 'İş')],
        dayLinks: const {
          '2026-11-06': ['eski1', 'kayip'],
        },
      );
      // Gerçek yedekteki gibi JSON metnine yazılıp okunur.
      final json = jsonDecode(
        jsonEncode(encodeCalendarBackup(snapshot)),
      ) as Map<String, dynamic>;
      final back = decodeCalendarBackup(json, {'eski1': 'yeni1'});

      expect(back.events.map((e) => e.id), ['e1']);
      final e = back.events.single;
      expect(e.title, 'Diş hekimi');
      expect(e.start, DateTime(2026, 11, 6, 14));
      expect(e.noteIds, ['yeni1']);
      expect(e.createdAt, DateTime(2026, 11, 1, 9));
      expect(back.tasks.first.noteId, 'yeni1');
      expect(back.tasks.first.noteItemId, 'm');
      // Notu yedekte olmayan bağ düşer, görev yine gelir.
      expect(back.tasks.last.noteId, '');
      expect(back.tasks.last.noteItemId, '');
      expect(back.lists.single.title, 'İş');
      expect(back.dayLinks, {
        '2026-11-06': ['yeni1'],
      });
    });

    test('boş takvim yedeğe alan açmaz', () {
      expect(const CalendarSnapshot().isEmpty, isTrue);
    });
  });
}
