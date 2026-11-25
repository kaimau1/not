import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';

/// TAKVIM_PLANI F52.1 (brifing satırları).
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
}
