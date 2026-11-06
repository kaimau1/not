import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/presentation/google_calendar_ui.dart';
import 'package:notlar/features/calendar/presentation/note_calendar_links.dart';

/// TAKVIM_PLANI Faz 49: not ↔ takvim bağları.
void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  test('notun bağları gün ve etkinliklerden ters hesaplanır, sıralı', () {
    final links = calendarLinksForNote(
      'n',
      dayLinks: const {
        '2026-11-10': ['n', 'x'],
        '2026-11-01': ['x'],
        'bozuk': ['n'],
      },
      events: [
        CalendarEvent(
          id: 'e',
          title: 'Toplantı',
          start: DateTime(2026, 11, 6, 14),
          end: DateTime(2026, 11, 6, 15),
          noteIds: const ['n'],
        ),
        CalendarEvent(
          id: 'sil',
          start: DateTime(2026, 11, 2),
          end: DateTime(2026, 11, 2, 1),
          noteIds: const ['n'],
          deletedAt: DateTime(2026, 11, 3),
        ),
        CalendarEvent(
          id: 'g:k/abc',
          start: DateTime(2026, 11, 8, 9),
          end: DateTime(2026, 11, 8, 10),
          noteIds: const ['n'],
        ),
      ],
    );
    expect(links.map((l) => (l.day.day, l.event?.id)), [
      (6, 'e'),
      (8, 'g:k/abc'),
      (10, null),
    ]);
  });

  test('günün notu başlığı ve toplantı notu gövdesi', () {
    expect(dayNoteTitle(DateTime(2026, 11, 6), 'tr'), '6 Kasım Cuma');
    final body = meetingNoteBody(
      CalendarEvent(
        id: 'e',
        title: 'Plan',
        location: 'Ofis',
        description: 'Gündem',
        start: DateTime(2026, 11, 6, 14),
        end: DateTime(2026, 11, 6, 15, 30),
      ),
      DateTime(2026, 11, 6, 14),
      'tr',
    );
    expect(body, contains('14:00–15:30'));
    expect(body.split('\n'), containsAllInOrder(['Ofis', 'Gündem']));
  });
}
