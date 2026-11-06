import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/data/ics.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';

/// TAKVIM_PLANI F52.4: .ics dışa/içe aktarma.
void main() {
  test('gidiş-dönüş: saatli, tüm gün, kaçışlı metin, tekrar', () {
    final events = [
      CalendarEvent(
        id: 'a',
        title: 'Toplantı; plan, bütçe',
        description: 'Satır 1\nSatır 2',
        location: 'Ofis',
        start: DateTime(2026, 11, 6, 14, 30),
        end: DateTime(2026, 11, 6, 15, 30),
        repeat: 'weekly:1,3;count=4',
      ),
      CalendarEvent(
        id: 'b',
        title: 'Bayram',
        allDay: true,
        start: DateTime(2026, 11, 7),
        end: DateTime(2026, 11, 9),
      ),
      CalendarEvent(
        id: 'g:k/x',
        title: 'Google',
        start: DateTime(2026, 11, 6),
        end: DateTime(2026, 11, 7),
      ),
    ];
    final text = encodeIcs(events, now: DateTime.utc(2026, 11, 6));
    expect(text, contains('BEGIN:VCALENDAR'));
    expect(text, isNot(contains('Google')));
    final back = parseIcs(text);
    expect(back, hasLength(2));
    final t = back.first;
    expect(t.title, 'Toplantı; plan, bütçe');
    expect(t.description, 'Satır 1\nSatır 2');
    expect(t.location, 'Ofis');
    expect(t.start, DateTime(2026, 11, 6, 14, 30));
    expect(t.end, DateTime(2026, 11, 6, 15, 30));
    expect(t.repeat, 'weekly:1,3;count=4');
    expect(t.extras['icsUid'], 'a@notlar');
    final d = back.last;
    expect(d.allDay, isTrue);
    expect(d.start, DateTime(2026, 11, 7));
    expect(d.end, DateTime(2026, 11, 9));

    // Aynı dosya ikinci kez: hiçbiri yeni değil.
    expect(newIcsEvents(back, events), isEmpty);
  });

  test(
    'başka uygulamanın dosyası: katlanmış satır, TZID, kuralsız haftalık',
    () {
      const ics =
          'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:x1\r\n'
          'DTSTART;TZID=Europe/Istanbul:20261110T090000\r\n'
          'SUMMARY:Uzun bir başlık ki iki satıra katlanmış o\r\n lsun\r\n'
          'RRULE:FREQ=WEEKLY;INTERVAL=2\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';
      final e = parseIcs(ics).single;
      expect(e.title, 'Uzun bir başlık ki iki satıra katlanmış olsun');
      expect(e.start, DateTime(2026, 11, 10, 9));
      expect(e.end, DateTime(2026, 11, 10, 10));
      // 10 Kasım 2026 salı → BYDAY başlangıçtan.
      expect(e.repeat, 'weekly:2;every=2');
    },
  );
}
