import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/assistant_service.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TAKVIM_PLANI F52.1 (brifing) ve F52.2 (asistan araçları).
void main() {
  test('brifing: bugün/yarın sıralı, gecikmiş görev ayrı, tamamlanan yok', () {
    final lines = calendarBriefingLines(
      now: DateTime(2026, 11, 6, 8),
      events: [
        CalendarEvent(
          id: 'e',
          title: 'Toplantı',
          location: 'Ofis',
          start: DateTime(2026, 11, 6, 14),
          end: DateTime(2026, 11, 6, 15),
        ),
        CalendarEvent(
          id: 'uzak',
          title: 'Gelecek hafta',
          start: DateTime(2026, 11, 13, 9),
          end: DateTime(2026, 11, 13, 10),
        ),
      ],
      tasks: const [
        TaskItem(id: '1', title: 'Fatura', due: '2026-11-07'),
        TaskItem(id: '2', title: 'Eski iş', due: '2026-11-01'),
        TaskItem(id: '3', title: 'Bitti', due: '2026-11-06', completed: true),
      ],
    );
    expect(lines, [
      '- Bugün 14:00 · etkinlik: Toplantı (Ofis)',
      '- Yarın gün boyu · görev: Fatura',
      '- GECİKMİŞ (2026-11-01) görev: Eski iş',
    ]);
  });

  test('asistan: etkinlik ve görev ekler, ajandayı listeler', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = CalendarRepository(FakeFirebaseFirestore(), 'u1');
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('u1'),
        calendarRepositoryProvider.overrideWithValue(repo),
        notesStreamProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    final assistant = c.read(assistantServiceProvider);
    final day = DateTime.now().add(const Duration(days: 1));
    String two(int v) => v.toString().padLeft(2, '0');
    final key = '${day.year}-${two(day.month)}-${two(day.day)}';

    final e = await assistant.execute('create_event', {
      'title': 'Dişçi',
      'start': '${key}T15:00:00',
      'reminderMinutes': 30,
    });
    expect(e['status'], 'ok');
    final t = await assistant.execute('create_task', {
      'title': 'Raporu bitir',
      'due': key,
      'dueTime': '18:30',
    });
    expect(t['status'], 'ok');
    expect(
      (await assistant.execute('create_task', {'title': ' '}))['status'],
      'error',
    );

    final events = await repo.watchEvents().first;
    expect(events.single.end.difference(events.single.start).inHours, 1);
    expect(events.single.reminders, [30]);
    final tasks = await repo.watchTasks().first;
    expect(tasks.single.due, key);
    expect(tasks.single.dueTime, '18:30');

    final agenda = await assistant.execute('list_agenda', {'from': key});
    expect(
      [for (final i in agenda['items'] as List) (i as Map)['title']],
      ['Dişçi', 'Raporu bitir'],
    );
  });
}
