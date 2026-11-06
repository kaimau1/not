import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';
import 'calendar_repository.dart';

/// **TAKVİM YEDEĞİ** (TAKVIM_PLANI F46.5): etkinlik, görev, görev listesi ve
/// gün bağları tam yedeğin (`yedek.json`) `calendar` alanında taşınır.
///
/// Kayıtların Firestore biçimi ([CalendarEvent.toMap] vb.) JSON'a çevrilir:
/// `Timestamp` → `{"$ts": ISO}`. Geri yüklemede NOT KİMLİKLERİ yeniden
/// eşlenir — `NoteShare.import` notlara yeni kimlik verir; eşlenemeyen bağ
/// düşer (bağsız kayıt yine gelir). Aynı kimlikli kayıt varsa atlanır: yedek
/// iki kez yüklense de takvim çoğalmaz.
class CalendarSnapshot {
  const CalendarSnapshot({
    this.events = const [],
    this.tasks = const [],
    this.lists = const [],
    this.dayLinks = const {},
  });

  final List<CalendarEvent> events;
  final List<TaskItem> tasks;
  final List<TaskList> lists;

  /// Gün anahtarı → not kimlikleri.
  final Map<String, List<String>> dayLinks;

  bool get isEmpty =>
      events.isEmpty && tasks.isEmpty && lists.isEmpty && dayLinks.isEmpty;
}

const _tsKey = r'$ts';

Object? _toJson(Object? v) => switch (v) {
  Timestamp() => {_tsKey: v.toDate().toUtc().toIso8601String()},
  Map() => {for (final e in v.entries) e.key.toString(): _toJson(e.value)},
  List() => [for (final x in v) _toJson(x)],
  _ => v,
};

Object? _fromJson(Object? v) {
  if (v is Map) {
    if (v.length == 1 && v[_tsKey] is String) {
      final d = DateTime.tryParse(v[_tsKey] as String);
      return d == null ? null : Timestamp.fromDate(d);
    }
    return <String, dynamic>{
      for (final e in v.entries) e.key.toString(): _fromJson(e.value),
    };
  }
  if (v is List) return [for (final x in v) _fromJson(x)];
  return v;
}

Map<String, dynamic> _record(String id, Map<String, dynamic> map) => {
  'id': id,
  'data': _toJson(map),
};

/// Yedeğe yazılacak JSON (silinmiş kayıtlar girmez).
Map<String, dynamic> encodeCalendarBackup(CalendarSnapshot s) => {
  'events': [
    for (final e in s.events)
      if (e.deletedAt == null) _record(e.id, e.toMap()),
  ],
  'tasks': [
    for (final t in s.tasks)
      if (t.deletedAt == null) _record(t.id, t.toMap()),
  ],
  'lists': [for (final l in s.lists) _record(l.id, l.toMap())],
  'dayLinks': {
    for (final e in s.dayLinks.entries)
      if (e.value.isNotEmpty) e.key: e.value,
  },
};

/// [raw] yedekten okunan `calendar` alanı; [noteIds] eski → yeni not
/// kimliği. Eşlenemeyen not bağları düşer.
CalendarSnapshot decodeCalendarBackup(
  Map<String, dynamic> raw,
  Map<String, String> noteIds,
) {
  Iterable<(String, Map<String, dynamic>)> records(String key) sync* {
    for (final r in raw[key] as List? ?? const []) {
      if (r is! Map) continue;
      final id = r['id']?.toString() ?? '';
      final data = _fromJson(r['data']);
      if (id.isEmpty || data is! Map<String, dynamic>) continue;
      yield (id, data);
    }
  }

  List<String> remap(Iterable<Object?> ids) => [
    for (final id in ids) ?noteIds[id],
  ];

  final events = <CalendarEvent>[];
  for (final (id, data) in records('events')) {
    final e = CalendarEvent.fromMap(id, data);
    events.add(e.copyWith(noteIds: remap(e.noteIds)));
  }
  final tasks = <TaskItem>[];
  for (final (id, data) in records('tasks')) {
    final t = TaskItem.fromMap(id, data);
    final note = noteIds[t.noteId];
    tasks.add(
      note == null && t.noteId.isNotEmpty
          ? t.copyWith(noteId: '', noteItemId: '')
          : t.copyWith(noteId: note ?? t.noteId),
    );
  }
  final lists = [
    for (final (id, data) in records('lists')) TaskList.fromMap(id, data),
  ];
  final links = <String, List<String>>{};
  final rawLinks = raw['dayLinks'];
  if (rawLinks is Map) {
    for (final e in rawLinks.entries) {
      final day = e.key.toString();
      if (parseDayKey(day) == null || e.value is! List) continue;
      final mapped = remap(e.value as List);
      if (mapped.isNotEmpty) links[day] = mapped;
    }
  }
  return CalendarSnapshot(
    events: events,
    tasks: tasks,
    lists: lists,
    dayLinks: links,
  );
}

/// [snapshot]ı [repo]ya yazar; [existing]'de aynı kimlikli kayıt atlanır.
/// Yazılan kayıt sayısını döner (etkinlik + görev).
int restoreCalendarSnapshot(
  CalendarRepository repo,
  CalendarSnapshot snapshot, {
  CalendarSnapshot existing = const CalendarSnapshot(),
}) {
  final eventIds = {for (final e in existing.events) e.id};
  final taskIds = {for (final t in existing.tasks) t.id};
  final listIds = {for (final l in existing.lists) l.id};
  var written = 0;
  for (final l in snapshot.lists) {
    if (listIds.contains(l.id)) continue;
    repo.saveTaskList(l);
  }
  for (final e in snapshot.events) {
    if (eventIds.contains(e.id)) continue;
    repo.saveEvent(e);
    written++;
  }
  for (final t in snapshot.tasks) {
    if (taskIds.contains(t.id)) continue;
    repo.saveTask(t);
    written++;
  }
  for (final e in snapshot.dayLinks.entries) {
    final have = existing.dayLinks[e.key] ?? const <String>[];
    for (final id in e.value) {
      if (!have.contains(id)) repo.linkNoteToDay(e.key, id);
    }
  }
  return written;
}
