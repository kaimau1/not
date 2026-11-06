import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/day_key.dart';
import 'package:notlar/features/calendar/domain/recurrence.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';

/// TAKVIM_PLANI Faz 46: model, tekrar kuralı, depo.
void main() {
  group('dayKey', () {
    test('gidiş-dönüş ve geçersiz tarih', () {
      expect(dayKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
      expect(parseDayKey('2026-03-05'), DateTime(2026, 3, 5));
      expect(parseDayKey('2026-02-31'), isNull);
      expect(parseDayKey('2026-13-01'), isNull);
      expect(parseDayKey('dün'), isNull);
    });

    test('gün farkı yaz saatinden etkilenmez', () {
      // Avrupa'da 29 Mart 2026 23 saatlik gün.
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
      expect(daysBetween(DateTime(2026, 3, 30), DateTime(2026, 3, 28)), -2);
    });
  });

  group('Recurrence', () {
    test('dize gidiş-dönüş', () {
      for (final s in [
        'daily',
        'weekly:1,3;every=2',
        'monthly:31;until=2027-01-31',
        'yearly:2-29;count=5',
        'weekdays;every=3;until=2026-12-31;count=10',
      ]) {
        expect(Recurrence.parse(s).encode(), s);
      }
      expect(Recurrence.parse('').isNone, isTrue);
      expect(Recurrence.parse(';every=2').isNone, isTrue);
      // Geçersiz parametre yok sayılır.
      expect(Recurrence.parse('daily;every=x;until=dün').encode(), 'daily');
    });

    test('tekrarsız: yalnız başlangıç, aralıktaysa', () {
      final s = DateTime(2026, 11, 6, 10);
      expect(
        Recurrence.none.between(s, DateTime(2026, 11), DateTime(2026, 12)),
        [s],
      );
      expect(
        Recurrence.none.between(s, DateTime(2026, 12), DateTime(2027)),
        isEmpty,
      );
    });

    test('iki günde bir', () {
      final s = DateTime(2026, 11, 1, 8);
      final r = Recurrence.parse('daily;every=2');
      expect(r.between(s, DateTime(2026, 11), DateTime(2026, 11, 8)), [
        DateTime(2026, 11, 1, 8),
        DateTime(2026, 11, 3, 8),
        DateTime(2026, 11, 5, 8),
        DateTime(2026, 11, 7, 8),
      ]);
    });

    test('iki haftada bir Pazartesi ve Çarşamba', () {
      final s = DateTime(2026, 11, 2, 9); // Pazartesi
      final r = Recurrence.parse('weekly:1,3;every=2');
      expect(r.between(s, DateTime(2026, 11), DateTime(2026, 11, 30)), [
        DateTime(2026, 11, 2, 9),
        DateTime(2026, 11, 4, 9),
        DateTime(2026, 11, 16, 9),
        DateTime(2026, 11, 18, 9),
      ]);
    });

    test('ayın 31i kısa ayda ay sonuna, sonra yine 31e', () {
      final s = DateTime(2027, 1, 31, 12);
      final r = Recurrence.parse('monthly').anchoredTo(s);
      expect(r.between(s, DateTime(2027), DateTime(2027, 4)), [
        DateTime(2027, 1, 31, 12),
        DateTime(2027, 2, 28, 12),
        DateTime(2027, 3, 31, 12),
      ]);
    });

    test('until ve count sınırı; exdate atlanır ama sayılır', () {
      final s = DateTime(2026, 11, 1, 8);
      expect(
        Recurrence.parse('daily;until=2026-11-03')
            .between(s, DateTime(2026, 10), DateTime(2027))
            .length,
        3,
      );
      expect(
        Recurrence.parse('daily;count=3').between(
          s,
          DateTime(2026, 10),
          DateTime(2027),
          exdates: {'2026-11-02'},
        ),
        [DateTime(2026, 11, 1, 8), DateTime(2026, 11, 3, 8)],
      );
    });

    test('sonraki oluş', () {
      final s = DateTime(2026, 11, 2, 9);
      final r = Recurrence.parse('weekdays');
      // Cuma 10:00'dan sonra → Pazartesi 09:00.
      expect(
        r.nextAfter(s, DateTime(2026, 11, 6, 10)),
        DateTime(2026, 11, 9, 9),
      );
      expect(
        Recurrence.parse('daily;count=2')
            .nextAfter(s, DateTime(2026, 11, 3, 10)),
        isNull,
      );
    });
  });

  group('CalendarEvent', () {
    test('saatli etkinlik gidiş-dönüş + bilinmeyen alan korunur', () {
      final e = CalendarEvent(
        id: 'e1',
        title: 'Diş hekimi',
        start: DateTime(2026, 11, 6, 14),
        end: DateTime(2026, 11, 6, 15),
        reminders: const [10, 60],
        noteIds: const ['n1'],
        repeat: 'weekly:5',
        google: const GoogleLink(container: 'primary', id: 'g1', etag: 'x'),
        extras: const {'gelecek': 1},
      );
      final map = e.toMap();
      expect(map['startKey'], '2026-11-06');
      final back = CalendarEvent.fromMap('e1', map);
      expect(back.start, e.start);
      expect(back.end, e.end);
      expect(back.reminders, [10, 60]);
      expect(back.noteIds, ['n1']);
      expect(back.google!.id, 'g1');
      expect(back.extras, {'gelecek': 1});
      expect(back.toMap()['gelecek'], 1);
    });

    test('tüm gün: gün dizesi, saat dilimi taşımaz', () {
      final e = CalendarEvent(
        id: 'e2',
        allDay: true,
        start: DateTime(2026, 11, 6),
        end: DateTime(2026, 11, 8),
      );
      final map = e.toMap();
      expect(map['startDay'], '2026-11-06');
      expect(map['endDay'], '2026-11-08');
      expect(map.containsKey('start'), isFalse);
      final back = CalendarEvent.fromMap('e2', map);
      expect(back.start, DateTime(2026, 11, 6));
      expect(back.end, DateTime(2026, 11, 8));
      expect(back.reminderBase(back.start), DateTime(2026, 11, 6, 9));
    });

    test('çok günlü etkinlik aralıktan önce başlasa da görünür', () {
      final e = CalendarEvent(
        id: 'e3',
        allDay: true,
        start: DateTime(2026, 10, 30),
        end: DateTime(2026, 11, 3),
      );
      expect(e.occurrencesBetween(DateTime(2026, 11), DateTime(2026, 12)), [
        DateTime(2026, 10, 30),
      ]);
      // Bittiği gün (bitiş HARİÇ) görünmez.
      expect(
        e.occurrencesBetween(DateTime(2026, 11, 3), DateTime(2026, 11, 4)),
        isEmpty,
      );
    });
  });

  group('TaskItem', () {
    test('gidiş-dönüş, geçersiz tarih/saat temizlenir', () {
      const t = TaskItem(
        id: 't1',
        title: 'Fatura',
        due: '2026-11-10',
        dueTime: '18:30',
        reminders: [0],
        noteId: 'n1',
        noteItemId: 'i1',
        extras: {'x': true},
      );
      final back = TaskItem.fromMap('t1', t.toMap());
      expect(back.dueAt, DateTime(2026, 11, 10, 18, 30));
      expect(back.noteItemId, 'i1');
      expect(back.extras, {'x': true});
      final bad = TaskItem.fromMap('t2', {
        'due': '2026-02-31',
        'dueTime': '25:00',
      });
      expect(bad.due, '');
      expect(bad.dueTime, '');
      expect(bad.dueAt, isNull);
    });

    test('gecikme: saatsizde gün sonuna dek gecikmiş sayılmaz', () {
      final now = DateTime(2026, 11, 6, 20);
      expect(
        const TaskItem(id: 'a', due: '2026-11-06').isOverdue(now),
        isFalse,
      );
      expect(const TaskItem(id: 'a', due: '2026-11-05').isOverdue(now), isTrue);
      expect(
        const TaskItem(
          id: 'a',
          due: '2026-11-06',
          dueTime: '19:00',
        ).isOverdue(now),
        isTrue,
      );
    });

    test('tekrarsız görev tamamlanır', () {
      final now = DateTime(2026, 11, 6, 12);
      final r = completeTask(
        const TaskItem(id: 'a', due: '2026-11-06'),
        now,
        historyId: 'h',
      );
      expect(r.task.completed, isTrue);
      expect(r.task.completedAt, now);
      expect(r.history, isNull);
    });

    test('tekrarlı görev ilerler, geçmiş kopyası tekrarsız', () {
      final now = DateTime(2026, 11, 6, 12); // Cuma
      final r = completeTask(
        const TaskItem(
          id: 'a',
          title: 'Spor',
          due: '2026-11-06',
          repeat: 'weekly:1,3,5',
        ),
        now,
        historyId: 'h',
      );
      expect(r.task.completed, isFalse);
      expect(r.task.due, '2026-11-09');
      expect(r.history!.id, 'h');
      expect(r.history!.completed, isTrue);
      expect(r.history!.due, '2026-11-06');
      expect(r.history!.repeat, '');
    });

    test('haftalarca gecikmiş günlük görev bugüne atlar', () {
      final r = completeTask(
        const TaskItem(id: 'a', due: '2026-10-01', repeat: 'daily'),
        DateTime(2026, 11, 6, 12),
        historyId: 'h',
      );
      expect(r.task.due, '2026-11-06');
    });

    test('count biter: son oluşta görev kapanır', () {
      var t = const TaskItem(
        id: 'a',
        due: '2026-11-06',
        repeat: 'daily;count=2',
      );
      final now = DateTime(2026, 11, 6, 8);
      var r = completeTask(t, now, historyId: 'h1');
      expect(r.task.due, '2026-11-07');
      expect(r.task.repeat, 'daily;count=1');
      t = r.task;
      r = completeTask(t, DateTime(2026, 11, 7, 8), historyId: 'h2');
      expect(r.task.completed, isTrue);
    });

    test('sıralama: açıklar önce, erken son tarih önce, tarihsiz sonra', () {
      final list = [
        const TaskItem(id: 'c', completed: true, due: '2026-01-01'),
        const TaskItem(id: 'n'),
        const TaskItem(id: 'b', due: '2026-11-10'),
        const TaskItem(id: 'a', due: '2026-11-09'),
      ]..sort(compareTasks);
      expect(list.map((t) => t.id), ['a', 'b', 'n', 'c']);
    });
  });

  group('CalendarRepository', () {
    late FakeFirebaseFirestore db;
    late CalendarRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = CalendarRepository(db, 'u1');
    });

    Future<Map<String, dynamic>?> read(String path) async =>
        (await db.doc('users/u1/$path').get()).data();

    test('etkinlik kaydı, çöp ve geri alma; akışta silinen görünmez', () async {
      final e = repo.saveEvent(
        CalendarEvent(
          id: '',
          title: 'Toplantı',
          start: DateTime(2026, 11, 6, 10),
          end: DateTime(2026, 11, 6, 11),
        ),
      );
      expect(e.id, isNotEmpty);
      await pumpEventQueue();
      expect((await repo.watchEvents().first).single.title, 'Toplantı');
      repo.trashEvent(e.id);
      await pumpEventQueue();
      expect(await repo.watchEvents().first, isEmpty);
      expect((await read('events/${e.id}'))!['deletedAt'], isA<Timestamp>());
      repo.restoreEvent(e.id);
      await pumpEventQueue();
      expect(await repo.watchEvents().first, hasLength(1));
    });

    test('tek oluşu atlama ve not bağı', () async {
      final e = repo.saveEvent(
        CalendarEvent(
          id: 'e',
          start: DateTime(2026, 11, 2, 9),
          end: DateTime(2026, 11, 2, 10),
          repeat: 'daily',
        ),
      );
      await pumpEventQueue();
      repo.skipOccurrence(e.id, DateTime(2026, 11, 3, 9));
      repo.linkNoteToEvent(e.id, 'n1');
      await pumpEventQueue();
      final back = (await repo.watchEvents().first).single;
      expect(back.exdates, ['2026-11-03']);
      expect(back.noteIds, ['n1']);
      expect(
        back
            .occurrencesBetween(DateTime(2026, 11, 2), DateTime(2026, 11, 5))
            .length,
        2,
      );
    });

    test('tekrarlı görevi tamamlamak geçmiş yazar', () async {
      final t = repo.saveTask(
        const TaskItem(
          id: 't',
          title: 'Su iç',
          due: '2026-11-06',
          repeat: 'daily',
        ),
      );
      repo.completeTaskNow(t, now: DateTime(2026, 11, 6, 9));
      await pumpEventQueue();
      final tasks = await repo.watchTasks().first;
      expect(tasks, hasLength(2));
      expect(tasks.first.id, 't');
      expect(tasks.first.due, '2026-11-07');
      expect(tasks.last.completed, isTrue);
    });

    test('görevi silmek alt görevleri de çöpe atar', () async {
      final p = repo.saveTask(const TaskItem(id: 'p', title: 'Taşın'));
      final c = repo.saveTask(
        const TaskItem(id: 'c', title: 'Kutu', parentId: 'p'),
      );
      repo.saveTask(const TaskItem(id: 'x', title: 'Başka'));
      await pumpEventQueue();
      repo.trashTask(p, [p, c]);
      await pumpEventQueue();
      expect((await repo.watchTasks().first).map((t) => t.id), ['x']);
    });

    test('gün bağı', () async {
      repo.linkNoteToDay('2026-11-06', 'n1');
      repo.linkNoteToDay('2026-11-06', 'n2');
      await pumpEventQueue();
      expect((await repo.watchDayLinks().first)['2026-11-06'], ['n1', 'n2']);
      repo.unlinkNoteFromDay('2026-11-06', 'n1');
      await pumpEventQueue();
      expect((await repo.watchDayLinks().first)['2026-11-06'], ['n2']);
    });
  });
}
