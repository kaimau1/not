import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_alarms.dart';
import 'package:notlar/features/calendar/domain/routine.dart';
import 'package:notlar/features/notes/data/widget_service.dart';

/// TAKVIM_PLANI Faz 53: rutinler.
void main() {
  const steps = [
    RoutineStep(id: 'a', text: 'Su iç'),
    RoutineStep(id: 'b', text: 'Esne'),
  ];
  const daily = Routine(
    id: 'r',
    title: 'Sabah',
    steps: steps,
    startDay: '2026-11-01',
    time: '07:30',
    remind: true,
  );

  test('adımlar tiklenince tamamlanır; gidiş-dönüş', () {
    var log = const RoutineLog(routineId: 'r', day: '2026-11-06');
    log = toggleRoutineStep(daily, log, 'a');
    expect(log.completed, isFalse);
    log = toggleRoutineStep(daily, log, 'b');
    expect(log.completed, isTrue);
    expect(RoutineLog.fromMap(log.toMap()).done, {'a', 'b'});
    final back = Routine.fromMap('r', daily.toMap());
    expect(back.steps.map((s) => s.text), ['Su iç', 'Esne']);
    expect(back.time, '07:30');
  });

  test('seri: bugün yapılmadıysa dünden sayılır, boşlukta kopar', () {
    Map<String, RoutineLog> done(List<String> days) => {
      for (final d in days)
        d: RoutineLog(routineId: 'r', day: d, completed: true),
    };
    final today = DateTime(2026, 11, 6);
    expect(routineStreak(daily, done(['2026-11-05', '2026-11-04']), today), 2);
    expect(
      routineStreak(
        daily,
        done(['2026-11-06', '2026-11-05', '2026-11-03']),
        today,
      ),
      2,
    );
    final strip = routineStrip(daily, done(['2026-11-06']), today);
    expect(strip, hasLength(30));
    expect(strip.last, isTrue);
    // 1 Kasım'dan önce oluş yok.
    expect(strip.first, isNull);
  });

  test('haftalık rutin yalnız gününde ajandada; hatırlatma o saatte', () {
    const weekly = Routine(
      id: 'w',
      title: 'Spor',
      repeat: 'weekly:1,3',
      startDay: '2026-11-02',
      time: '18:00',
      remind: true,
    );
    final agenda = buildAgenda(
      from: DateTime(2026, 11, 2),
      to: DateTime(2026, 11, 9),
      routines: const [weekly],
    );
    expect(agenda.keys, ['2026-11-02', '2026-11-04']);
    final alarms = calendarAlarms(
      events: const [],
      tasks: const [],
      routines: const [weekly, daily],
      now: DateTime(2026, 11, 3, 12),
      horizon: const Duration(days: 2),
    );
    expect(alarms.map((a) => a.at), [
      DateTime(2026, 11, 4, 7, 30),
      DateTime(2026, 11, 4, 18),
      DateTime(2026, 11, 5, 7, 30),
    ]);
  });

  test('Bugün widget\'ı takvim kayıtlarını da taşır', () {
    final payload = todayWidgetPayload(
      const [],
      DateTime(2026, 11, 6, 8),
      calendar: [(at: DateTime(2026, 11, 6, 9), title: '📅 Toplantı')],
    );
    expect(payload, endsWith('\t📅 Toplantı'));
  });
}
