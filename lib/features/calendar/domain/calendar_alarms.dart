import 'calendar_event.dart';
import 'day_key.dart';
import 'task_item.dart';

/// Planlanacak bir takvim bildirimi (TAKVIM_PLANI F47.6). Bildirim motoru
/// AYRI DEĞİL: `ReminderService` bunları not hatırlatıcılarıyla aynı
/// eklentiyle kurar; yük `cal:` ile BAŞLAR (`note:` DEĞİL — HAFIZA kuralı:
/// not mutabakatı yalnız `note:` öneklilere bakar).
class CalendarAlarm {
  const CalendarAlarm({
    required this.key,
    required this.at,
    required this.title,
    required this.start,
    required this.allDay,
    required this.payload,
  });

  /// Oluş + hatırlatma başına kararlı anahtar (bildirim kimliği bundan).
  final String key;

  /// Çalma anı.
  final DateTime at;
  final String title;

  /// Etkinlik başı / görevin son anı (bildirim metni için).
  final DateTime start;
  final bool allDay;
  final String payload;

  /// Değişince yeniden kurulur.
  String get signature => '${at.millisecondsSinceEpoch}|$title|$allDay';

  int get notificationId => key.hashCode & 0x7fffffff;
}

/// Yük öneki.
const kCalendarPayloadPrefix = 'cal:';

/// `[now, now + horizon)` içinde çalacak bildirimler, zamana göre; en çok
/// [max] tane (Android'in planlı alarm sınırı ~500, not hatırlatıcılarına
/// yer kalsın). Uygulama her açılışta ufku yeniden doldurur.
List<CalendarAlarm> calendarAlarms({
  required Iterable<CalendarEvent> events,
  required Iterable<TaskItem> tasks,
  required DateTime now,
  Duration horizon = const Duration(days: 14),
  int max = 60,
}) {
  final until = now.add(horizon);
  final out = <CalendarAlarm>[];
  for (final e in events) {
    if (e.deletedAt != null || e.reminders.isEmpty) continue;
    final maxLead = e.reminders.reduce((a, b) => a > b ? a : b);
    // Hatırlatması ufka düşen oluşlar: başlangıcı ufuktan `maxLead` sonra
    // olabilir.
    final occs = e.recurrence.between(
      e.start,
      now,
      until.add(Duration(minutes: maxLead + 24 * 60)),
      exdates: e.exdates.toSet(),
      max: 100,
    );
    for (final s in occs) {
      final base = e.reminderBase(s);
      for (final m in e.reminders) {
        final at = base.subtract(Duration(minutes: m));
        if (!at.isAfter(now) || !at.isBefore(until)) continue;
        out.add(
          CalendarAlarm(
            key: 'event:${e.id}@${dayKey(s)}T${s.hour}:${s.minute}#$m',
            at: at,
            title: e.title,
            start: s,
            allDay: e.allDay,
            payload: '${kCalendarPayloadPrefix}event:${e.id}',
          ),
        );
      }
    }
  }
  for (final t in tasks) {
    if (t.deletedAt != null || t.completed || t.reminders.isEmpty) continue;
    final due = t.dueAt;
    if (due == null) continue;
    for (final m in t.reminders) {
      final at = due.subtract(Duration(minutes: m));
      if (!at.isAfter(now) || !at.isBefore(until)) continue;
      out.add(
        CalendarAlarm(
          key: 'task:${t.id}@${t.due}#$m',
          at: at,
          title: t.title,
          start: due,
          allDay: !t.hasTime,
          payload: '${kCalendarPayloadPrefix}task:${t.id}',
        ),
      );
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.length > max ? out.sublist(0, max) : out;
}
