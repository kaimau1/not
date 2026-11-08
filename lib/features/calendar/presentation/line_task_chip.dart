import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/reminder_service.dart' show reminderTimePrefix;
import '../../notes/domain/reminder_level.dart';
import '../../notes/presentation/reminder_level_ui.dart';
import '../data/calendar_repository.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';
import 'task_editor.dart';

/// Bir notun SATIRLARINA bağlı görevler: madde kimliği → görev (silinmemiş).
/// Not içi hatırlatıcı/görev satırı (kullanıcı isteği 2026-11-08) ayrı bir
/// kayıt değil, takvimin `tasks` kaydıdır (`noteId` + `noteItemId`):
/// bildirimi `ReminderService` sistem alarmıyla kurar — zamanlayıcı yok.
final noteLineTasksProvider = Provider.autoDispose
    .family<Map<String, TaskItem>, String>((ref, noteId) {
      final tasks = ref.watch(tasksStreamProvider).value ?? const <TaskItem>[];
      return {
        for (final t in tasks)
          if (t.noteId == noteId &&
              t.noteItemId.isNotEmpty &&
              t.deletedAt == null)
            t.noteItemId: t,
      };
    });

/// Gün + saat seçtirir (gün varsayılanı [initial] ya da bugün). Saat
/// seçilmezse null (vazgeçildi).
Future<DateTime?> pickLineTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  final base = initial ?? now.add(const Duration(hours: 1));
  final day = await showDatePicker(
    context: context,
    initialDate: base.isBefore(now) ? now : base,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 10),
  );
  if (day == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
  );
  if (time == null) return null;
  return DateTime(day.year, day.month, day.day, time.hour, time.minute);
}

/// Satıra hatırlatıcı: zaman seçilir, satırın metniyle nota bağlı görev
/// (son anında hatırlatmalı) kurulur.
Future<void> addLineReminder(
  BuildContext context,
  WidgetRef ref, {
  required String noteId,
  required String itemId,
  required String text,
}) async {
  final repo = ref.read(calendarRepositoryProvider);
  if (repo == null) return;
  final at = await pickLineTime(context);
  if (at == null) return;
  repo.saveTask(
    TaskItem(
      id: '',
      title: text.trim(),
      noteId: noteId,
      noteItemId: itemId,
      due: dayKey(at),
      dueTime: formatHm(at.hour, at.minute),
      reminders: const [0],
    ),
  );
}

/// Çipin sabit boyu (satırın ilk yazı satırına ortalanır).
const double kLineTaskChipHeight = 22;

/// Satırın sonundaki hatırlatıcı/görev çipi: zil (düzeyin simgesi) + zaman.
/// Zamana dokun = tarih/saat seçici; basılı tut = görev levhası (düzey,
/// kişi, Gmail, tekrar, silme).
class LineTaskChip extends ConsumerWidget {
  const LineTaskChip({super.key, required this.noteId, required this.itemId});

  final String noteId;
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(
      noteLineTasksProvider(noteId).select((m) => m[itemId]),
    );
    if (task == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueAt;
    final now = DateTime.now();
    final overdue = !task.completed && due != null && due.isBefore(now);
    final label = due == null
        ? l10n.taskNoDue
        : reminderTimePrefix(due, now: now, l10n: l10n);
    final fg = task.completed
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : overdue
        ? scheme.error
        : scheme.primary;
    final icon = task.reminders.isEmpty
        ? Icons.task_alt_rounded
        : reminderLevelIcon(ReminderLevel.parse(task.level));

    Future<void> retime() async {
      final at = await pickLineTime(context, initial: due);
      if (at == null) return;
      ref
          .read(calendarRepositoryProvider)
          ?.saveTask(
            task.copyWith(
              due: dayKey(at),
              dueTime: formatHm(at.hour, at.minute),
              completed: false,
              clearCompletedAt: true,
            ),
          );
    }

    // DOKUN = küçük menü (kullanıcı isteği 2026-11-08: "üzerine basınca
    // çıkan düzenleme alanında sil tuşu olmalı"): zamanı değiştir,
    // ayrıntılar, tamamlandı, SİL.
    Future<void> actions() async {
      final choice = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  task.title.isEmpty ? l10n.taskDue : task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(label),
                leading: Icon(icon, color: fg),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('line-task-retime'),
                leading: const Icon(Icons.schedule_rounded),
                title: Text(l10n.lineTaskRetime),
                onTap: () => Navigator.pop(sheet, 'retime'),
              ),
              ListTile(
                key: const ValueKey('line-task-done'),
                leading: Icon(
                  task.completed
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                title: Text(
                  task.completed ? l10n.lineTaskUndone : l10n.lineTaskDone,
                ),
                onTap: () => Navigator.pop(sheet, 'done'),
              ),
              ListTile(
                key: const ValueKey('line-task-details'),
                leading: const Icon(Icons.tune_rounded),
                title: Text(l10n.lineTaskDetails),
                onTap: () => Navigator.pop(sheet, 'details'),
              ),
              ListTile(
                key: const ValueKey('line-task-delete'),
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text(
                  l10n.lineTaskDelete,
                  style: TextStyle(color: scheme.error),
                ),
                onTap: () => Navigator.pop(sheet, 'delete'),
              ),
            ],
          ),
        ),
      );
      if (!context.mounted) return;
      final repo = ref.read(calendarRepositoryProvider);
      switch (choice) {
        case 'retime':
          await retime();
        case 'done':
          repo?.saveTask(
            task.copyWith(
              completed: !task.completed,
              completedAt: task.completed ? null : DateTime.now(),
              clearCompletedAt: task.completed,
            ),
          );
        case 'details':
          await showTaskEditor(context, existing: task);
        case 'delete':
          final all = ref.read(tasksStreamProvider).value ?? const <TaskItem>[];
          repo?.trashTask(task, all);
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.taskDeleted),
                action: SnackBarAction(
                  label: l10n.undo,
                  onPressed: () => repo?.restoreTask(task.id),
                ),
              ),
            );
      }
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Semantics(
        button: true,
        label: '${l10n.taskDue}: $label',
        child: Material(
          key: ValueKey('line-task-$itemId'),
          color: fg.withValues(alpha: 0.10),
          shape: StadiumBorder(
            side: BorderSide(color: fg.withValues(alpha: 0.35), width: 0.8),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => unawaited(actions()),
            onLongPress: () =>
                unawaited(showTaskEditor(context, existing: task)),
            // SABİT 22 dp boy: satır ilk yazı satırının ortasına hizalar
            // (bkz. ItemsEditor `lineTrailing`, kChipHeight).
            child: Container(
              height: kLineTaskChipHeight,
              padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: fg),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.contact.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.person_outline, size: 13, color: fg),
                  ],
                  if (task.gmailLink.isNotEmpty) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.mail_outline, size: 13, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
