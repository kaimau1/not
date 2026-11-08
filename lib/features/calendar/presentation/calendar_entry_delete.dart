import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/data/notes_repository.dart';
import '../data/calendar_repository.dart';
import '../data/google_calendar_sync.dart';
import '../domain/agenda.dart';
import '../domain/task_item.dart';

/// Kayıt TEK DOKUNUŞLA silinebilir mi (gün levhasındaki çöp düğmesi)?
/// Rutinin günü silinmez (rutin kendi ekranından yönetilir).
bool canQuickDelete(AgendaEntry entry) => entry is! RoutineEntry;

/// **HIZLI SİLME** (kullanıcı isteği 2026-11-08: "silmek için 3 farklı alana
/// girmek gerekiyor; üzerine tıklayınca ilk açılan yerde silme de olmalı").
/// Gün levhasındaki satırın çöp düğmesi buraya gelir; editörü açmadan siler
/// ve "Geri al" sunar. Tekrarlayan etkinlikte "yalnız bu / hepsi" sorulur,
/// Google etkinliğinde (geri alınamaz) onay istenir — editördeki kuralın
/// aynısı.
Future<void> quickDeleteEntry(
  BuildContext context,
  WidgetRef ref,
  AgendaEntry entry,
) async {
  final l10n = context.l10n;
  final calendar = ref.read(calendarRepositoryProvider);
  switch (entry) {
    case EventOccurrence(:final event, :final start):
      if (event.fromGoogle) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(l10n.gcalDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.eventDelete),
              ),
            ],
          ),
        );
        if (ok != true) return;
        unawaited(
          ref.read(googleCalendarProvider.notifier).deleteFromGoogle(event),
        );
        return;
      }
      if (calendar == null) return;
      if (event.repeats) {
        final onlyThis = await showDialog<bool>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text(l10n.eventDeleteRepeatingTitle),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.eventDeleteThis),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.eventDeleteAll),
              ),
            ],
          ),
        );
        if (onlyThis == null) return;
        if (onlyThis) {
          calendar.skipOccurrence(event.id, start);
          unawaited(HapticFeedback.selectionClick());
          return;
        }
      }
      calendar.trashEvent(event.id);
      if (!context.mounted) return;
      showUndoSnackBar(
        context,
        message: l10n.eventDeleted,
        undoLabel: l10n.undo,
        onUndo: () => calendar.restoreEvent(event.id),
      );
    case TaskEntry(:final task):
      if (calendar == null) return;
      final all = ref.read(tasksStreamProvider).value ?? const <TaskItem>[];
      calendar.trashTask(task, all);
      showUndoSnackBar(
        context,
        message: l10n.taskDeleted,
        undoLabel: l10n.undo,
        onUndo: () {
          calendar.restoreTask(task.id);
          for (final t in all) {
            if (t.parentId == task.id) calendar.restoreTask(t.id);
          }
        },
      );
    case ReminderEntry(:final note):
      final notes = ref.read(notesRepositoryProvider);
      if (notes == null) return;
      final before = note.reminderAt;
      notes.setReminder(note.id, null);
      showUndoSnackBar(
        context,
        message: l10n.reminderRemoved,
        undoLabel: l10n.undo,
        onUndo: () => notes.setReminder(
          note.id,
          before,
          repeat: note.reminderRepeat,
          level: note.reminderLevel,
        ),
      );
    case RoutineEntry():
      return;
  }
}

/// Satırın sonundaki küçük çöp düğmesi.
class QuickDeleteButton extends ConsumerWidget {
  const QuickDeleteButton({super.key, required this.entry});

  final AgendaEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    key: const ValueKey('calendar-entry-delete'),
    tooltip: context.l10n.delete,
    visualDensity: VisualDensity.compact,
    iconSize: 20,
    icon: Icon(
      Icons.delete_outline,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    onPressed: () => unawaited(quickDeleteEntry(context, ref, entry)),
  );
}
