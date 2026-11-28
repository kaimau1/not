import 'package:flutter/foundation.dart';

import 'list_mode.dart';
import 'note.dart';
import 'note_type.dart';

/// Tek bir notta önceki günlerden kalıp bugüne devredilebilecek maddeler.
@immutable
class CarryOverNoteEntry {
  const CarryOverNoteEntry({
    required this.noteId,
    required this.noteTitle,
    required this.itemIds,
  });

  final String noteId;
  final String noteTitle;
  final List<String> itemIds;
}

/// Önceki günlerden kalan bitmemiş görevlerin toplu devir planı.
@immutable
class CarryOverPlan {
  const CarryOverPlan({required this.entries, required this.totalItems});

  static const empty = CarryOverPlan(entries: [], totalItems: 0);

  final List<CarryOverNoteEntry> entries;
  final int totalItems;

  bool get isEmpty => totalItems == 0;
  bool get isNotEmpty => totalItems > 0;
}

/// **ÖNCEKİ GÜNDEN DEVİR MOTORU** (Faz 3):
///
/// Kilitli, arşivlenmiş veya çöp kutusundaki notlara DOKUNMADAN, `dueDate`
/// alanı bugünden önceki bir güne ait ve hâlâ tamamlanmamış (`!checked`)
/// maddeleri tespit eder; tek dokunuşla hepsinin `dueDate` tarihini bugüne
/// taşıyacak atomik güncelleme haritasını üretir.
abstract final class CarryOverEngine {
  static const dismissedDayPrefsKey = 'carry_over_dismissed_day_v1';

  /// Bugünün yerel gün başlangıcını döndürür (00:00:00).
  static DateTime startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Bugünün ISO gün anahtarı (`YYYY-MM-DD`).
  static String dayKey(DateTime t) => isoDayKeyOf(t);

  /// Önceki günlerden kalan tamamlanmamış görevleri tarar.
  static CarryOverPlan scan(List<Note> notes, {DateTime? now}) {
    final todayStart = startOfDay(now ?? DateTime.now());
    final entries = <CarryOverNoteEntry>[];
    var total = 0;

    for (final note in notes) {
      if (note.locked || note.deletedAt != null || note.archivedAt != null) {
        continue;
      }
      if (note.type != NoteType.checklist && note.items.isEmpty) continue;
      final overdueIds = <String>[];
      for (final item in note.items) {
        if (item.header || item.checked || item.text.trim().isEmpty) continue;
        final due = item.dueDate;
        if (due == null) continue;
        final dueLocal = due.isUtc ? due.toLocal() : due;
        if (dueLocal.isBefore(todayStart)) {
          overdueIds.add(item.id);
        }
      }
      if (overdueIds.isNotEmpty) {
        entries.add(
          CarryOverNoteEntry(
            noteId: note.id,
            noteTitle: note.displayTitle,
            itemIds: overdueIds,
          ),
        );
        total += overdueIds.length;
      }
    }

    return CarryOverPlan(entries: entries, totalItems: total);
  }

  /// Devredilecek her not için `batchUpdateEach` uyumlu alan haritası ve
  /// geri alma (Undo) anlık görüntüsü üretir.
  static ({
    Map<String, Map<String, dynamic>> updates,
    Map<String, Map<String, dynamic>> undoSnapshots,
  })
  buildCarryOverBatch(List<Note> notes, CarryOverPlan plan, {DateTime? now}) {
    if (plan.isEmpty) {
      return (updates: const {}, undoSnapshots: const {});
    }
    final targetDay = startOfDay(now ?? DateTime.now());
    final byId = {for (final n in notes) n.id: n};
    final updates = <String, Map<String, dynamic>>{};
    final undoSnapshots = <String, Map<String, dynamic>>{};

    for (final entry in plan.entries) {
      final note = byId[entry.noteId];
      if (note == null || note.locked) continue;
      final idSet = entry.itemIds.toSet();
      final prevItems = [for (final i in note.items) i.toMap()];
      final nextItems = <Map<String, dynamic>>[];
      var changed = false;
      for (final item in note.items) {
        if (idSet.contains(item.id) && !item.checked) {
          final oldDue = item.dueDate;
          // Saat bilgisi varsa koru, günü bugüne taşı.
          final nextDue =
              oldDue != null && (oldDue.hour != 0 || oldDue.minute != 0)
              ? DateTime(
                  targetDay.year,
                  targetDay.month,
                  targetDay.day,
                  oldDue.hour,
                  oldDue.minute,
                )
              : targetDay;
          nextItems.add(item.copyWith(dueDate: nextDue).toMap());
          changed = true;
        } else {
          nextItems.add(item.toMap());
        }
      }
      if (changed) {
        updates[note.id] = {'items': nextItems};
        undoSnapshots[note.id] = {'items': prevItems};
      }
    }
    return (updates: updates, undoSnapshots: undoSnapshots);
  }
}
