import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';

final calendarRepositoryProvider = Provider<CalendarRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return CalendarRepository(FirebaseFirestore.instance, uid);
});

/// Kendi etkinliklerim (silinmemiş). Kişisel takvimde kayıt sayısı küçük
/// (yüzler): tüm koleksiyon TEK dinleyici, aralık hesabı bellekte
/// ([CalendarEvent.occurrencesBetween]) — tekrarlayan etkinlik aralık
/// sorgusuyla zaten bulunamazdı. Binleri aşarsa `startKey` aralık sorgusuna
/// geçilir (plan §3).
final eventsStreamProvider = StreamProvider<List<CalendarEvent>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchEvents();
});

final tasksStreamProvider = StreamProvider<List<TaskItem>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchTasks();
});

final taskListsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchTaskLists();
});

/// Google etkinliği → bağlı not kimlikleri (`eventLinks`, F48.4).
final eventLinksStreamProvider = StreamProvider<Map<String, List<String>>>((
  ref,
) {
  final repo = ref.watch(calendarRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchEventLinks();
});

/// Gün → bağlı not kimlikleri (`dayLinks`).
final dayLinksStreamProvider = StreamProvider<Map<String, List<String>>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchDayLinks();
});

/// Takvim + görev CRUD'u. Notlar ve klasörler gibi YANGIN-VE-UNUT yazar:
/// yerel önbellek anında güncellenir, senkron arka planda (çevrimdışı çalışır).
class CalendarRepository {
  CalendarRepository(this._firestore, this.uid);

  final FirebaseFirestore _firestore;
  final String uid;
  static const _uuid = Uuid();

  DocumentReference<Map<String, dynamic>> get _user =>
      _firestore.collection(AppConstants.usersCollection).doc(uid);
  CollectionReference<Map<String, dynamic>> get _events =>
      _user.collection(AppConstants.eventsCollection);
  CollectionReference<Map<String, dynamic>> get _tasks =>
      _user.collection(AppConstants.tasksCollection);
  CollectionReference<Map<String, dynamic>> get _lists =>
      _user.collection(AppConstants.taskListsCollection);
  /// Google etkinliğine bağlı notlar (F48.4) — Google'a YAZILMAZ; belge
  /// kimliği Google etkinlik kimliği.
  CollectionReference<Map<String, dynamic>> get _eventLinks =>
      _user.collection(AppConstants.eventLinksCollection);

  CollectionReference<Map<String, dynamic>> get _dayLinks =>
      _user.collection(AppConstants.dayLinksCollection);

  String newId() => _uuid.v4();

  // ---------------------------------------------------------------- etkinlik

  Stream<List<CalendarEvent>> watchEvents() => _events.snapshots().map(
    (s) => [
      for (final d in s.docs)
        if (d.data()['deletedAt'] == null)
          CalendarEvent.fromMap(d.id, d.data()),
    ]..sort((a, b) => a.start.compareTo(b.start)),
  );

  /// Çöp kutusundaki etkinlikler.
  Stream<List<CalendarEvent>> watchDeletedEvents() => _events
      .where(
        'deletedAt',
        isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(0),
      )
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) CalendarEvent.fromMap(d.id, d.data())],
      );

  /// Yeni ya da değişmiş etkinliği yazar; `createdAt` yoksa koyar.
  CalendarEvent saveEvent(CalendarEvent event, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final saved = CalendarEvent(
      id: event.id.isEmpty ? newId() : event.id,
      title: event.title,
      description: event.description,
      location: event.location,
      allDay: event.allDay,
      start: event.start,
      end: event.end,
      repeat: event.repeat,
      exdates: event.exdates,
      reminders: event.reminders,
      color: event.color,
      noteIds: event.noteIds,
      google: event.google,
      createdAt: event.createdAt ?? at,
      updatedAt: at,
      deletedAt: event.deletedAt,
      extras: event.extras,
    );
    unawaited(_events.doc(saved.id).set(saved.toMap()));
    return saved;
  }

  /// Çöpe atar (geri alınabilir).
  void trashEvent(String id) => unawaited(
    _events.doc(id).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  void restoreEvent(String id) => unawaited(
    _events.doc(id).update({
      'deletedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  void deleteEventForever(String id) => unawaited(_events.doc(id).delete());

  /// Tekrarlayan etkinlikten tek günü çıkarır ("yalnız bunu sil", K3).
  void skipOccurrence(String id, DateTime occurrenceStart) => unawaited(
    _events.doc(id).update({
      'exdates': FieldValue.arrayUnion([dayKey(occurrenceStart)]),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  void linkNoteToEvent(String eventId, String noteId) => unawaited(
    _events.doc(eventId).update({
      'noteIds': FieldValue.arrayUnion([noteId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  void unlinkNoteFromEvent(String eventId, String noteId) => unawaited(
    _events.doc(eventId).update({
      'noteIds': FieldValue.arrayRemove([noteId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  // ------------------------------------------------------------------- görev

  Stream<List<TaskItem>> watchTasks() => _tasks.snapshots().map(
    (s) => [
      for (final d in s.docs)
        if (d.data()['deletedAt'] == null) TaskItem.fromMap(d.id, d.data()),
    ]..sort(compareTasks),
  );

  TaskItem saveTask(TaskItem task, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final saved = task.copyWith(
      id: task.id.isEmpty ? newId() : task.id,
      createdAt: task.createdAt ?? at,
      updatedAt: at,
    );
    unawaited(_tasks.doc(saved.id).set(saved.toMap()));
    return saved;
  }

  /// Tamamlar; tekrarlıysa sonraki oluşa ilerletir ve geçmiş kopyası yazar
  /// ([completeTask]). Tek toplu yazım: ikisi birlikte olur ya da hiç.
  TaskItem completeTaskNow(TaskItem task, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final r = completeTask(task, at, historyId: newId());
    final batch = _firestore.batch()
      ..set(_tasks.doc(r.task.id), r.task.toMap());
    if (r.history != null) {
      batch.set(_tasks.doc(r.history!.id), r.history!.toMap());
    }
    unawaited(batch.commit());
    return r.task;
  }

  TaskItem uncompleteTask(TaskItem task, {DateTime? now}) => saveTask(
    task.copyWith(completed: false, clearCompletedAt: true),
    now: now,
  );

  /// Görevi ve ALT görevlerini çöpe atar.
  void trashTask(TaskItem task, Iterable<TaskItem> all) {
    final batch = _firestore.batch();
    final stamp = {
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.update(_tasks.doc(task.id), stamp);
    for (final t in all) {
      if (t.parentId == task.id) batch.update(_tasks.doc(t.id), stamp);
    }
    unawaited(batch.commit());
  }

  void restoreTask(String id) => unawaited(
    _tasks.doc(id).update({
      'deletedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  /// Tamamlanmış görevleri çöpe atar (bir listede ya da hepsinde).
  void clearCompleted(Iterable<TaskItem> tasks, {String? listId}) {
    final batch = _firestore.batch();
    var any = false;
    for (final t in tasks) {
      if (!t.completed || (listId != null && t.listId != listId)) continue;
      batch.update(_tasks.doc(t.id), {
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      any = true;
    }
    if (any) unawaited(batch.commit());
  }

  // ------------------------------------------------------------ görev listesi

  Stream<List<TaskList>> watchTaskLists() => _lists.snapshots().map(
    (s) =>
        [for (final d in s.docs) TaskList.fromMap(d.id, d.data())]
          ..sort((a, b) {
            final c = a.position.compareTo(b.position);
            return c != 0
                ? c
                : a.title.toLowerCase().compareTo(b.title.toLowerCase());
          }),
  );

  TaskList saveTaskList(TaskList list) {
    final saved = TaskList(
      id: list.id.isEmpty ? newId() : list.id,
      title: list.title,
      position: list.position,
      google: list.google,
      createdAt: list.createdAt ?? DateTime.now(),
      extras: list.extras,
    );
    unawaited(_lists.doc(saved.id).set(saved.toMap()));
    return saved;
  }

  /// Listeyi ve içindeki görevleri siler (görevler çöpe).
  void deleteTaskList(String listId, Iterable<TaskItem> tasks) {
    if (listId == TaskList.defaultId) return;
    final batch = _firestore.batch()..delete(_lists.doc(listId));
    for (final t in tasks) {
      if (t.listId != listId) continue;
      batch.update(_tasks.doc(t.id), {
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    unawaited(batch.commit());
  }

  // ---------------------------------------------------------------- gün bağı

  Stream<Map<String, List<String>>> watchDayLinks() =>
      _dayLinks.snapshots().map(
        (s) => {
          for (final d in s.docs)
            if (parseDayKey(d.id) != null)
              d.id: [
                for (final n in d.data()['noteIds'] as List? ?? const [])
                  if (n is String && n.isNotEmpty) n,
              ],
        },
      );

  void linkNoteToDay(String day, String noteId) => unawaited(
    _dayLinks.doc(day).set({
      'noteIds': FieldValue.arrayUnion([noteId]),
    }, SetOptions(merge: true)),
  );

  void unlinkNoteFromDay(String day, String noteId) => unawaited(
    _dayLinks.doc(day).set({
      'noteIds': FieldValue.arrayRemove([noteId]),
    }, SetOptions(merge: true)),
  );

  // ------------------------------------------------- Google etkinlik bağı

  /// Google etkinlik kimliği → bağlı not kimlikleri.
  Stream<Map<String, List<String>>> watchEventLinks() =>
      _eventLinks.snapshots().map(
        (s) => {
          for (final d in s.docs)
            d.id: [
              for (final n in d.data()['noteIds'] as List? ?? const [])
                if (n is String && n.isNotEmpty) n,
            ],
        },
      );

  void linkNoteToGoogleEvent(String googleEventId, String noteId) => unawaited(
    _eventLinks.doc(googleEventId).set({
      'noteIds': FieldValue.arrayUnion([noteId]),
    }, SetOptions(merge: true)),
  );

  void unlinkNoteFromGoogleEvent(String googleEventId, String noteId) =>
      unawaited(
        _eventLinks.doc(googleEventId).set({
          'noteIds': FieldValue.arrayRemove([noteId]),
        }, SetOptions(merge: true)),
      );
}
