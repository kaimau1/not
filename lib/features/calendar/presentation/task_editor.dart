import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/toggle_pop.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/presentation/reminder_level_ui.dart';
import '../../notes/presentation/reminder_repeat_ui.dart';
import '../../notes/presentation/reminders_screen.dart'
    show maybeShowAutoStartHint;
import '../data/calendar_repository.dart';
import '../domain/day_key.dart';
import '../domain/recurrence.dart';
import '../domain/task_item.dart';

/// Listenin görünen adı (varsayılan liste yerelleştirilir).
String taskListTitle(AppLocalizations l10n, TaskList list) =>
    list.isDefault || list.title.trim().isEmpty
    ? l10n.tasksDefaultList
    : list.title.trim();

/// Görev oluştur/düzenle levhası (TAKVIM_PLANI F50.1). [existing] null ise
/// yeni; [due] yeni görevin son günü (takvimden açılınca seçili gün),
/// [parentId] alt görev, [listId] hangi listeye.
Future<void> showTaskEditor(
  BuildContext context, {
  TaskItem? existing,
  DateTime? due,
  String parentId = '',
  String listId = TaskList.defaultId,
  String? initialTitle,
  String? initialNotes,
  String noteId = '',
  String noteItemId = '',
}) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => TaskEditorSheet(
    existing: existing,
    due: due,
    parentId: parentId,
    listId: listId,
    initialTitle: initialTitle,
    initialNotes: initialNotes,
    noteId: noteId,
    noteItemId: noteItemId,
  ),
);

class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({
    super.key,
    this.existing,
    this.due,
    this.parentId = '',
    this.listId = TaskList.defaultId,
    this.initialTitle,
    this.initialNotes,
    this.noteId = '',
    this.noteItemId = '',
  });

  /// Liste maddesinden görev (TAKVIM F50.3, K6): başlık maddenin metni,
  /// tamamlanma madde ile iki yönlü eşlenir ([noteId]/[noteItemId]).
  final String? initialTitle;

  /// Yeni görevin ayrıntısı (Gmail'den: iletinin bağlantısı, F52.3).
  final String? initialNotes;
  final String noteId;
  final String noteItemId;

  final TaskItem? existing;
  final DateTime? due;
  final String parentId;
  final String listId;

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  final _titleFocus = FocusNode();

  late final _title = TextEditingController(
    text: widget.existing?.title ?? widget.initialTitle,
  );
  late final _notes = TextEditingController(
    text: widget.existing?.notes ?? widget.initialNotes,
  );
  late DateTime? _due =
      widget.existing?.dueDay ??
      (widget.due == null ? null : startOfDay(widget.due!));
  late String _time = widget.existing?.dueTime ?? '';
  late Recurrence _repeat = Recurrence.parse(widget.existing?.repeat);
  late bool _remind = widget.existing?.reminders.isNotEmpty ?? false;
  late bool _starred = widget.existing?.starred ?? false;
  late String _listId = widget.existing?.listId ?? widget.listId;
  late String _level = widget.existing?.level ?? '';
  late final _contact = TextEditingController(
    text: widget.existing?.contact ?? '',
  );
  late final _gmail = TextEditingController(
    text: widget.existing?.gmailLink ?? '',
  );

  @override
  void initState() {
    super.initState();
    // Klavye levha açıldıktan SONRA (bkz. [focusAfterRouteOpens]).
    if (widget.existing == null) focusAfterRouteOpens(this, _titleFocus);
  }

  @override
  void dispose() {
    _title.dispose();
    _titleFocus.dispose();
    _notes.dispose();
    _contact.dispose();
    _gmail.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _due = startOfDay(picked));
  }

  Future<void> _pickTime() async {
    final hm = parseHm(_time);
    final picked = await showTimePicker(
      context: context,
      initialTime: hm == null
          ? const TimeOfDay(hour: TaskItem.defaultDueHour, minute: 0)
          : TimeOfDay(hour: hm.hour, minute: hm.minute),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = formatHm(picked.hour, picked.minute));
  }

  Future<void> _pickRepeat() async {
    final anchor = _due ?? startOfDay(DateTime.now());
    final picked = await pickReminderRepeat(
      context,
      current: _repeat.base,
      anchor: anchor,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _due ??= anchor;
      _repeat = picked.isNone
          ? Recurrence.none
          : _repeat.copyWith(base: picked).anchoredTo(anchor);
    });
  }

  void _save() {
    final repo = ref.read(calendarRepositoryProvider);
    final title = _title.text.trim();
    if (repo == null) return;
    if (title.isEmpty && widget.existing == null) {
      Navigator.pop(context);
      return;
    }
    final base =
        widget.existing ??
        TaskItem(
          id: '',
          parentId: widget.parentId,
          noteId: widget.noteId,
          noteItemId: widget.noteItemId,
        );
    final due = _due == null ? '' : dayKey(_due!);
    repo.saveTask(
      base.copyWith(
        title: title,
        notes: _notes.text.trim(),
        due: due,
        dueTime: due.isEmpty ? '' : _time,
        repeat: due.isEmpty ? '' : _repeat.encode(),
        reminders: _remind && due.isNotEmpty ? const [0] : const [],
        starred: _starred,
        listId: _listId,
        level: _level,
        contact: _contact.text.trim(),
        gmailLink: _gmail.text.trim(),
      ),
    );
    final outer = Navigator.of(context).context;
    Navigator.pop(context);
    if (_remind && due.isNotEmpty && outer.mounted) {
      unawaited(maybeShowAutoStartHint(outer));
    }
  }

  void _delete() {
    final task = widget.existing;
    final repo = ref.read(calendarRepositoryProvider);
    if (task == null || repo == null) return;
    final l10n = context.l10n;
    final all = ref.read(tasksStreamProvider).value ?? const <TaskItem>[];
    repo.trashTask(task, all);
    final outer = Navigator.of(context).context;
    Navigator.pop(context);
    if (outer.mounted) {
      showUndoSnackBar(
        outer,
        message: l10n.taskDeleted,
        undoLabel: l10n.undo,
        onUndo: () {
          repo.restoreTask(task.id);
          for (final t in all) {
            if (t.parentId == task.id) repo.restoreTask(t.id);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lists = ref.watch(taskListsStreamProvider).value ?? const [];
    final allLists = [
      const TaskList(id: TaskList.defaultId),
      for (final l in lists)
        if (!l.isDefault) l,
    ];

    // Klavye payı ayrı, ince widget'ta (bkz. [SheetInsetPadding]).
    return SheetInsetPadding(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: widget.existing == null
                  ? l10n.tasksNewTask
                  : l10n.taskEditTitle,
              actions: [
                TogglePop(
                  on: _starred,
                  child: IconButton(
                    tooltip: l10n.taskStar,
                    isSelected: _starred,
                    icon: const Icon(Icons.star_outline),
                    selectedIcon: const Icon(Icons.star),
                    onPressed: () => setState(() => _starred = !_starred),
                  ),
                ),
                if (widget.existing != null)
                  IconButton(
                    tooltip: l10n.taskDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _delete,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('task-title'),
                    controller: _title,
                    focusNode: _titleFocus,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                      hintText: l10n.taskTitleHint,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                  TextField(
                    controller: _notes,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.notes_outlined),
                      hintText: l10n.taskNotesHint,
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(l10n.taskDue),
                    subtitle: Text(
                      _due == null
                          ? l10n.taskNoDue
                          : DateFormat.yMMMEd().format(_due!),
                    ),
                    trailing: _due == null
                        ? null
                        : IconButton(
                            tooltip: l10n.taskNoDue,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _due = null;
                              _time = '';
                              _repeat = Recurrence.none;
                            }),
                          ),
                    onTap: _pickDue,
                  ),
                  if (_due != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(l10n.taskTime),
                      subtitle: Text(_time.isEmpty ? l10n.taskNoTime : _time),
                      trailing: _time.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.taskNoTime,
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _time = ''),
                            ),
                      onTap: _pickTime,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.repeat),
                      title: Text(l10n.repeatTitle),
                      subtitle: Text(reminderRepeatLabel(l10n, _repeat.base)),
                      onTap: _pickRepeat,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.notifications_none_outlined),
                      title: Text(l10n.taskReminderAtDue),
                      value: _remind,
                      onChanged: (v) => setState(() => _remind = v),
                    ),
                    if (_remind)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ReminderLevelPicker(
                          value: _level,
                          onChanged: (v) => setState(() => _level = v),
                        ),
                      ),
                  ],
                  // Kişi ve Gmail bağlantısı (not içi görev satırı,
                  // 2026-11-08): kime / hangi iletiyle ilgili.
                  TextField(
                    key: const ValueKey('task-contact'),
                    controller: _contact,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.person_outline),
                      hintText: l10n.taskContactHint,
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    key: const ValueKey('task-gmail'),
                    controller: _gmail,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.mail_outline),
                      hintText: l10n.taskGmailHint,
                      border: InputBorder.none,
                    ),
                  ),
                  if (allLists.length > 1 && widget.parentId.isEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.list_alt_outlined),
                      title: Text(l10n.taskList),
                      trailing: DropdownButton<String>(
                        value: allLists.any((l) => l.id == _listId)
                            ? _listId
                            : TaskList.defaultId,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final l in allLists)
                            DropdownMenuItem(
                              value: l.id,
                              child: Text(taskListTitle(l10n, l)),
                            ),
                        ],
                        onChanged: (v) =>
                            setState(() => _listId = v ?? TaskList.defaultId),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('task-save'),
                    onPressed: _save,
                    child: Text(l10n.eventSave),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
