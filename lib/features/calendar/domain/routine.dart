import 'package:cloud_firestore/cloud_firestore.dart';

import 'day_key.dart';
import 'recurrence.dart';

/// **RUTİN** (TAKVIM_PLANI Faz 53, K9: görev şablonu + hafif seri) —
/// `users/{uid}/routines/{id}`. Adı ve adımları olan, tekrarlayan bir plan:
/// zamanı gelen gün ajandaya ve görev listesine düşer, adımları tiklenir;
/// tamamlanma `routineLogs/{rutin}_{gün}` belgesine yazılır (seri + 30 gün).
class RoutineStep {
  const RoutineStep({required this.id, required this.text});

  final String id;
  final String text;

  Map<String, dynamic> toMap() => {'id': id, 'text': text};

  static RoutineStep? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'] as String? ?? '';
    if (id.isEmpty) return null;
    return RoutineStep(id: id, text: raw['text'] as String? ?? '');
  }
}

class Routine {
  const Routine({
    required this.id,
    this.title = '',
    this.steps = const [],
    this.repeat = 'daily',
    this.startDay = '',
    this.time = '',
    this.color,
    this.remind = false,
    this.createdAt,
    this.deletedAt,
    this.extras = const {},
  });

  final String id;
  final String title;
  final List<RoutineStep> steps;

  /// [Recurrence] dizesi; boş/geçersizse günlük sayılır.
  final String repeat;

  /// İlk gün `YYYY-MM-DD` (tekrarın çıpası).
  final String startDay;

  /// `HH:mm`; '' = gün boyu.
  final String time;
  final int? color;

  /// Zamanı gelince bildirim.
  final bool remind;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final Map<String, dynamic> extras;

  static const knownKeys = {
    'title',
    'steps',
    'repeat',
    'startDay',
    'time',
    'color',
    'remind',
    'createdAt',
    'deletedAt',
  };

  Recurrence get recurrence {
    final r = Recurrence.parse(repeat);
    return r.isNone ? Recurrence.parse('daily') : r;
  }

  DateTime get anchor => parseDayKey(startDay) ?? DateTime(2000);

  /// [day] bir oluş günü mü.
  bool occursOn(DateTime day) {
    final d = startOfDay(day);
    return recurrence
        .between(anchor, d, DateTime(d.year, d.month, d.day + 1))
        .isNotEmpty;
  }

  /// `[from, to)` aralığındaki oluş günleri.
  List<DateTime> daysBetween(DateTime from, DateTime to) => [
    for (final d in recurrence.between(anchor, startOfDay(from), to))
      startOfDay(d),
  ];

  Routine copyWith({
    String? id,
    String? title,
    List<RoutineStep>? steps,
    String? repeat,
    String? startDay,
    String? time,
    int? color,
    bool? remind,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) => Routine(
    id: id ?? this.id,
    title: title ?? this.title,
    steps: steps ?? this.steps,
    repeat: repeat ?? this.repeat,
    startDay: startDay ?? this.startDay,
    time: time ?? this.time,
    color: color ?? this.color,
    remind: remind ?? this.remind,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt ?? this.deletedAt,
    extras: extras,
  );

  factory Routine.fromMap(String id, Map<String, dynamic> map) {
    DateTime? ts(String k) => (map[k] as Timestamp?)?.toDate();
    return Routine(
      id: id,
      title: map['title'] as String? ?? '',
      steps: [
        for (final s in map['steps'] as List? ?? const [])
          ?RoutineStep.fromMap(s),
      ],
      repeat: map['repeat'] as String? ?? 'daily',
      startDay: map['startDay'] as String? ?? '',
      time: parseHm(map['time'] as String?) == null
          ? ''
          : map['time'] as String,
      color: (map['color'] as num?)?.toInt(),
      remind: map['remind'] == true,
      createdAt: ts('createdAt'),
      deletedAt: ts('deletedAt'),
      extras: {
        for (final e in map.entries)
          if (!knownKeys.contains(e.key)) e.key: e.value,
      },
    );
  }

  Map<String, dynamic> toMap() => {
    ...extras,
    'title': title,
    'steps': [for (final s in steps) s.toMap()],
    'repeat': repeat,
    'startDay': startDay,
    'time': time,
    'color': color,
    'remind': remind,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
  };
}

/// Bir rutinin bir günkü kaydı — `routineLogs/{rutin}_{gün}`.
class RoutineLog {
  const RoutineLog({
    required this.routineId,
    required this.day,
    this.done = const {},
    this.completed = false,
  });

  final String routineId;

  /// `YYYY-MM-DD`.
  final String day;

  /// Tiklenen adım kimlikleri.
  final Set<String> done;

  /// Rutin o gün tamamlandı (adımsız rutinde tek tik; adımlıda hepsi).
  final bool completed;

  static String docId(String routineId, String day) => '${routineId}_$day';

  factory RoutineLog.fromMap(Map<String, dynamic> map) => RoutineLog(
    routineId: map['routineId'] as String? ?? '',
    day: map['day'] as String? ?? '',
    done: {
      for (final d in map['done'] as List? ?? const [])
        if (d is String) d,
    },
    completed: map['completed'] == true,
  );

  Map<String, dynamic> toMap() => {
    'routineId': routineId,
    'day': day,
    'done': done.toList()..sort(),
    'completed': completed,
  };
}

/// Adım tiklenince kaydın yeni hâli: bütün adımlar tikliyse tamam.
RoutineLog toggleRoutineStep(Routine r, RoutineLog log, String stepId) {
  final done = {...log.done};
  done.contains(stepId) ? done.remove(stepId) : done.add(stepId);
  final all = r.steps.isNotEmpty && r.steps.every((s) => done.contains(s.id));
  return RoutineLog(
    routineId: log.routineId,
    day: log.day,
    done: done,
    completed: all,
  );
}

/// **SERİ**: [today]den geriye, tamamlanmış ardışık oluş sayısı. Bugün henüz
/// tamamlanmadıysa seri bozulmaz (dünden sayılır).
int routineStreak(
  Routine r,
  Map<String, RoutineLog> logsByDay,
  DateTime today, {
  int lookbackDays = 366,
}) {
  final t = startOfDay(today);
  final days = r
      .daysBetween(
        DateTime(t.year, t.month, t.day - lookbackDays),
        DateTime(t.year, t.month, t.day + 1),
      )
      .reversed;
  var streak = 0;
  var first = true;
  for (final d in days) {
    final done = logsByDay[dayKey(d)]?.completed ?? false;
    if (first && d == t && !done) {
      first = false;
      continue;
    }
    first = false;
    if (!done) break;
    streak++;
  }
  return streak;
}

/// Son 30 günün şeridi: her gün için null (oluş yok) / false / true.
List<bool?> routineStrip(
  Routine r,
  Map<String, RoutineLog> logsByDay,
  DateTime today, {
  int days = 30,
}) {
  final t = startOfDay(today);
  final from = DateTime(t.year, t.month, t.day - days + 1);
  final occurs = {
    for (final d in r.daysBetween(from, DateTime(t.year, t.month, t.day + 1)))
      dayKey(d),
  };
  return [
    for (var i = 0; i < days; i++)
      if (occurs.contains(
        dayKey(DateTime(from.year, from.month, from.day + i)),
      ))
        logsByDay[dayKey(DateTime(from.year, from.month, from.day + i))]
                ?.completed ??
            false
      else
        null,
  ];
}
