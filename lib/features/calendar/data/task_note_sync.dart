import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note_item.dart';
import '../domain/task_item.dart';
import 'calendar_repository.dart';

/// **MADDE ↔ GÖREV** (TAKVIM_PLANI F50.3, K6 "iki yönlü").
///
/// Liste maddesinden üretilen görev `noteId` + `noteItemId` taşır. Görev
/// tamamlanınca madde işaretlenir, madde işaretlenince görev tamamlanır.
/// TEKRARLI görev eşlenmez: tamamlanınca bir sonraki oluşa ilerler (açık
/// kalır), maddeyi işaretlemek onu kapatmamalı.

/// [items] içinde [itemId]'nin işaretini [checked] yapar; değişiklik yoksa
/// null (gereksiz yazım olmasın).
List<NoteItem>? itemsWithChecked(
  List<NoteItem> items,
  String itemId,
  bool checked,
) {
  final i = items.indexWhere((x) => x.id == itemId);
  if (i < 0 || items[i].checked == checked) return null;
  return [
    for (final x in items) x.id == itemId ? x.copyWith(checked: checked) : x,
  ];
}

/// [noteId]/[itemId] maddesine bağlı, durumu [checked]tan farklı ve
/// tekrarsız görevler.
List<TaskItem> tasksToSync(
  Iterable<TaskItem> tasks,
  String noteId,
  String itemId,
  bool checked,
) => [
  for (final t in tasks)
    if (t.noteId == noteId &&
        t.noteItemId == itemId &&
        t.deletedAt == null &&
        !t.repeats &&
        t.completed != checked)
      t,
];

/// Görevi tamamla/aç + bağlı maddeyi eşle (görev listesi, ajanda).
void setTaskCompleted(WidgetRef ref, TaskItem task, bool done) {
  final repo = ref.read(calendarRepositoryProvider);
  if (repo == null) return;
  done ? repo.completeTaskNow(task) : repo.uncompleteTask(task);
  if (task.repeats || task.noteId.isEmpty || task.noteItemId.isEmpty) return;
  final notes = ref.read(notesRepositoryProvider);
  if (notes == null) return;
  unawaited(() async {
    final note = await notes.watchNote(task.noteId).first;
    if (note == null) return;
    final items = itemsWithChecked(note.items, task.noteItemId, done);
    if (items == null) return;
    notes.updateFields(note.id, {
      'items': [for (final i in items) i.toMap()],
    });
  }());
}

/// Madde işaretlendi/kaldırıldı → bağlı görevler (kart ve editör).
void syncItemToTasks(
  WidgetRef ref,
  String noteId,
  String itemId,
  bool checked,
) {
  final repo = ref.read(calendarRepositoryProvider);
  if (repo == null) return;
  // Takvim hiç açılmadıysa akış henüz dinlenmiyor: bir kez okunur.
  final cached = ref.read(tasksStreamProvider).value;
  unawaited(() async {
    final tasks = cached ?? await repo.watchTasks().first;
    for (final t in tasksToSync(tasks, noteId, itemId, checked)) {
      checked ? repo.completeTaskNow(t) : repo.uncompleteTask(t);
    }
  }());
}
