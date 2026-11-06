import '../../notes/domain/note.dart';
import '../../notes/domain/reminder_repeat.dart';
import 'calendar_event.dart';
import 'day_key.dart';
import 'task_item.dart';

/// Ajandada bir satır (TAKVIM_PLANI §2.7: etkinlik, görev ve not
/// hatırlatıcısı TEK listede).
sealed class AgendaEntry {
  const AgendaEntry();

  /// Gün içi sıralama anı (tüm gün kayıtlarında gün başı).
  DateTime get at;

  /// Saatsiz (tüm gün etkinliği, saatsiz görev): günün en üstünde.
  bool get allDay;
}

/// Etkinliğin bir oluşu (tekrarlıda her oluş ayrı satır).
class EventOccurrence extends AgendaEntry {
  const EventOccurrence(this.event, this.start);

  final CalendarEvent event;
  final DateTime start;
  DateTime get end => start.add(event.duration);

  @override
  DateTime get at => start;
  @override
  bool get allDay => event.allDay;
}

class TaskEntry extends AgendaEntry {
  const TaskEntry(this.task);

  final TaskItem task;

  @override
  DateTime get at => task.dueAt!;
  @override
  bool get allDay => !task.hasTime;
}

/// Hatırlatıcılı not (bugünkü `reminderAt`/`reminderRepeat`, DEĞİŞMEDİ).
class ReminderEntry extends AgendaEntry {
  const ReminderEntry(this.note, this.at);

  final Note note;
  @override
  final DateTime at;
  @override
  bool get allDay => false;
}

int _compareEntries(AgendaEntry a, AgendaEntry b) {
  if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
  final c = a.at.compareTo(b.at);
  if (c != 0) return c;
  // Aynı anda: etkinlik, görev, hatırlatıcı.
  int rank(AgendaEntry e) => switch (e) {
    EventOccurrence() => 0,
    TaskEntry() => 1,
    ReminderEntry() => 2,
  };
  return rank(a) - rank(b);
}

/// `[from, to)` aralığındaki kayıtlar, gün anahtarına göre (sıralı harita;
/// boş gün YOK). Çok günlü etkinlik kapsadığı HER günde görünür (Google
/// Takvim'deki gibi). Tamamlanmış görevler [includeCompleted] ise girer.
Map<String, List<AgendaEntry>> buildAgenda({
  required DateTime from,
  required DateTime to,
  Iterable<CalendarEvent> events = const [],
  Iterable<TaskItem> tasks = const [],
  Iterable<Note> reminderNotes = const [],
  bool includeCompleted = true,
}) {
  final out = <String, List<AgendaEntry>>{};
  void add(DateTime day, AgendaEntry e) => (out[dayKey(day)] ??= []).add(e);

  final first = startOfDay(from);
  for (final event in events) {
    if (event.deletedAt != null) continue;
    for (final s in event.occurrencesBetween(from, to)) {
      final occ = EventOccurrence(event, s);
      // Kapsanan günler: başlangıç günü … bitişten önceki son gün.
      var day = startOfDay(s);
      final last = event.allDay || occ.end == startOfDay(occ.end)
          ? startOfDay(occ.end).subtract(const Duration(microseconds: 1))
          : occ.end;
      var guard = 0;
      do {
        if (!day.isBefore(first) && day.isBefore(to)) add(day, occ);
        day = DateTime(day.year, day.month, day.day + 1);
      } while (!day.isAfter(last) && ++guard < 366);
    }
  }

  for (final task in tasks) {
    if (task.deletedAt != null) continue;
    if (task.completed && !includeCompleted) continue;
    final d = task.dueDay;
    if (d == null || d.isBefore(first) || !d.isBefore(to)) continue;
    add(d, TaskEntry(task));
  }

  for (final note in reminderNotes) {
    final at = note.reminderAt;
    if (at == null || note.deletedAt != null) continue;
    final times = <DateTime>[at];
    final repeat = ReminderRepeat.parse(note.reminderRepeat);
    if (!repeat.isNone) {
      var cursor = at;
      for (var i = 0; i < 400; i++) {
        final n = repeat.next(at, cursor);
        if (n == null || !n.isBefore(to)) break;
        times.add(n);
        cursor = n;
      }
    }
    for (final t in times) {
      if (t.isBefore(from) || !t.isBefore(to)) continue;
      add(t, ReminderEntry(note, t));
    }
  }

  final keys = out.keys.toList()..sort();
  return {for (final k in keys) k: out[k]!..sort(_compareEntries)};
}

/// Kayıt sürüklenip başka güne taşınabilir mi (bkz. [movedToDay]).
bool canMoveEntry(AgendaEntry entry) => switch (entry) {
  EventOccurrence(:final event) => !event.repeats && !event.fromGoogle,
  TaskEntry(:final task) => !task.completed,
  ReminderEntry(:final note) => note.reminderAt != null,
};

/// **SÜRÜKLEYEREK TAŞIMA** (F47.5): kaydın [target] güne taşınmış hâli.
/// Saat korunur, yalnız gün değişir. Dönüş: güncellenmiş [CalendarEvent],
/// [TaskItem] ya da [Note]; taşınamıyorsa (aynı gün, tekrarlı etkinlik,
/// tamamlanmış görev) null.
///
/// Tekrarlı ETKİNLİK taşınmaz: sürüklenen tek oluş ama kayıt serinin
/// tamamı — bütün seriyi kaydırmak sürpriz olurdu (yalnız bu oluş için
/// "istisna + kopya" Google'da da yok, K3). Tekrarlı not hatırlatıcısı ve
/// görev ise serinin ilk anı kayar (editördeki tarih değişimiyle aynı).
Object? movedToDay(AgendaEntry entry, DateTime target) {
  final day = startOfDay(target);
  switch (entry) {
    case EventOccurrence(:final event, :final start):
      if (event.repeats || event.fromGoogle) return null;
      final delta = daysBetween(startOfDay(start), day);
      if (delta == 0) return null;
      DateTime shift(DateTime d) =>
          DateTime(d.year, d.month, d.day + delta, d.hour, d.minute);
      return event.copyWith(start: shift(event.start), end: shift(event.end));
    case TaskEntry(:final task):
      if (task.completed || task.dueDay == day) return null;
      return task.copyWith(due: dayKey(day));
    case ReminderEntry(:final note, :final at):
      final from = note.reminderAt;
      if (from == null) return null;
      final delta = daysBetween(startOfDay(at), day);
      if (delta == 0) return null;
      return note.copyWith(
        reminderAt: DateTime(
          from.year,
          from.month,
          from.day + delta,
          from.hour,
          from.minute,
        ),
      );
  }
}
