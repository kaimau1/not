import '../../notes/domain/reminder_repeat.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/recurrence.dart';
import 'google_calendar_api.dart' show rruleOf;

/// **.ics (iCalendar)** dışa/içe aktarma (TAKVIM_PLANI F52.4, RFC 5545'in
/// gündelik alt kümesi): etkinlik, tüm gün, konum, açıklama, basit tekrar.
/// Saat dilimi (`TZID`) yerel saat sayılır; `Z` ile biten UTC'dir.

String _esc(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\n', r'\n');

String _unesc(String s) => s
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\N', '\n')
    .replaceAll(r'\,', ',')
    .replaceAll(r'\;', ';')
    .replaceAll(r'\\', r'\');

String _two(int v) => v.toString().padLeft(2, '0');

String _utc(DateTime d) {
  final u = d.toUtc();
  return '${u.year}${_two(u.month)}${_two(u.day)}T'
      '${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
}

String _date(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';

/// 75 sekizlikte satır katlama (RFC 5545 §3.1) — basitçe 74 karakter.
Iterable<String> _fold(String line) sync* {
  if (line.length <= 74) {
    yield line;
    return;
  }
  yield line.substring(0, 74);
  for (var i = 74; i < line.length; i += 73) {
    yield ' ${line.substring(i, i + 73 > line.length ? line.length : i + 73)}';
  }
}

/// Etkinlikleri `.ics` metnine çevirir (silinmişler ve Google'dakiler hariç).
String encodeIcs(Iterable<CalendarEvent> events, {DateTime? now}) {
  final stamp = _utc(now ?? DateTime.now());
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Notlar//TR',
    'CALSCALE:GREGORIAN',
  ];
  for (final e in events) {
    if (e.deletedAt != null || e.fromGoogle) continue;
    final rule = rruleOf(e.recurrence);
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:${e.extras['icsUid'] as String? ?? '${e.id}@notlar'}',
      'DTSTAMP:$stamp',
      if (e.allDay) ...[
        'DTSTART;VALUE=DATE:${_date(e.start)}',
        'DTEND;VALUE=DATE:${_date(e.end)}',
      ] else ...[
        'DTSTART:${_utc(e.start)}',
        'DTEND:${_utc(e.end)}',
      ],
      'SUMMARY:${_esc(e.title)}',
      if (e.location.isNotEmpty) 'LOCATION:${_esc(e.location)}',
      if (e.description.isNotEmpty) 'DESCRIPTION:${_esc(e.description)}',
      ?rule,
      'END:VEVENT',
    ]);
  }
  lines.add('END:VCALENDAR');
  return '${[for (final l in lines) ..._fold(l)].join('\r\n')}\r\n';
}

DateTime? _parseIcsTime(String value, {required bool dateOnly}) {
  final v = value.trim();
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$')
      .firstMatch(v);
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  if (dateOnly || m[4] == null) return DateTime(y, mo, d);
  final h = int.parse(m[4]!), mi = int.parse(m[5]!);
  final s = int.tryParse(m[6] ?? '') ?? 0;
  return m[7] == 'Z'
      ? DateTime.utc(y, mo, d, h, mi, s).toLocal()
      : DateTime(y, mo, d, h, mi, s);
}

const _icsDays = {
  'MO': 1,
  'TU': 2,
  'WE': 3,
  'TH': 4,
  'FR': 5,
  'SA': 6,
  'SU': 7,
};

/// `RRULE` → bizim tekrar dizemiz; desteklenmeyen kural ''.
String repeatFromRrule(String rule) {
  final parts = {
    for (final p in rule.replaceFirst('RRULE:', '').split(';'))
      if (p.contains('='))
        p.substring(0, p.indexOf('=')).toUpperCase(): p.substring(
          p.indexOf('=') + 1,
        ),
  };
  final byDay = [
    for (final d in (parts['BYDAY'] ?? '').split(','))
      ?_icsDays[d.replaceAll(RegExp(r'^[+-]?\d+'), '')],
  ];
  final base = switch (parts['FREQ']) {
    'DAILY' => ReminderRepeat.daily,
    'WEEKLY'
        when byDay.length == 5 && !byDay.contains(6) && !byDay.contains(7) =>
      ReminderRepeat.weekdays,
    'WEEKLY' when byDay.isNotEmpty => ReminderRepeat.weekly(byDay),
    'MONTHLY' => ReminderRepeat.monthly,
    'YEARLY' => ReminderRepeat.yearly,
    _ => ReminderRepeat.none,
  };
  if (base.isNone) return '';
  final until = parts['UNTIL'];
  final untilDay = until == null || until.length < 8
      ? ''
      : '${until.substring(0, 4)}-${until.substring(4, 6)}-'
            '${until.substring(6, 8)}';
  return Recurrence(
    base,
    every: int.tryParse(parts['INTERVAL'] ?? '') ?? 1,
    count: int.tryParse(parts['COUNT'] ?? '') ?? 0,
    until: parseDayKey(untilDay) == null ? '' : untilDay,
  ).encode();
}

/// `.ics` metnindeki etkinlikler (kimliksiz; `extras.icsUid` ile).
/// Haftalık kuralda gün verilmemişse başlangıcın günü kullanılır.
List<CalendarEvent> parseIcs(String text) {
  // Katlanmış satırları aç (boşluk/sekme ile başlayan devam satırı).
  final unfolded = text
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'\n[ \t]'), '')
      .split('\n');
  final out = <CalendarEvent>[];
  Map<String, String>? cur;
  Map<String, String>? params;
  for (final raw in unfolded) {
    final line = raw.trimRight();
    if (line == 'BEGIN:VEVENT') {
      cur = {};
      params = {};
      continue;
    }
    if (line == 'END:VEVENT') {
      final e = _eventFrom(cur ?? const {}, params ?? const {});
      if (e != null) out.add(e);
      cur = null;
      continue;
    }
    if (cur == null) continue;
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final head = line.substring(0, colon);
    final name = head.split(';').first.toUpperCase();
    cur[name] = line.substring(colon + 1);
    params![name] = head;
  }
  return out;
}

CalendarEvent? _eventFrom(Map<String, String> v, Map<String, String> p) {
  final startRaw = v['DTSTART'];
  if (startRaw == null) return null;
  final allDay =
      (p['DTSTART'] ?? '').contains('VALUE=DATE') || !startRaw.contains('T');
  final start = _parseIcsTime(startRaw, dateOnly: allDay);
  if (start == null) return null;
  var end = v['DTEND'] == null
      ? null
      : _parseIcsTime(v['DTEND']!, dateOnly: allDay);
  if (end == null || !end.isAfter(start)) {
    end = allDay
        ? DateTime(start.year, start.month, start.day + 1)
        : start.add(const Duration(hours: 1));
  }
  var rule = v['RRULE'];
  if (rule != null && rule.contains('FREQ=WEEKLY') && !rule.contains('BYDAY')) {
    const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    rule = '$rule;BYDAY=${codes[start.weekday - 1]}';
  }
  final repeat = rule == null ? '' : repeatFromRrule(rule);
  return CalendarEvent(
    id: '',
    title: _unesc(v['SUMMARY'] ?? ''),
    location: _unesc(v['LOCATION'] ?? ''),
    description: _unesc(v['DESCRIPTION'] ?? ''),
    allDay: allDay,
    start: start,
    end: end,
    repeat: repeat,
    extras: {'icsUid': ?v['UID']},
  );
}

/// İçe aktarılacaklardan zaten var olanları ayıklar (aynı `icsUid` ya da
/// aynı başlık + başlangıç) — ikinci içe aktarma çoğaltmasın.
List<CalendarEvent> newIcsEvents(
  List<CalendarEvent> incoming,
  Iterable<CalendarEvent> existing,
) {
  final uids = {
    for (final e in existing)
      if (e.extras['icsUid'] case final String u) u,
    for (final e in existing) '${e.id}@notlar',
  };
  final keys = {for (final e in existing) '${e.title}|${e.start}'};
  return [
    for (final e in incoming)
      if (!uids.contains(e.extras['icsUid']) &&
          !keys.contains('${e.title}|${e.start}'))
        e,
  ];
}
