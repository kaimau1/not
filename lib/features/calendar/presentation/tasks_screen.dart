import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_frame.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/google_calendar_sync.dart' show googleCalendarAvailableProvider;
import '../data/google_tasks_sync.dart';
import '../data/calendar_repository.dart';
import '../data/task_note_sync.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';
import 'task_editor.dart';
import 'google_failure.dart';

/// **GÖREVLER** (TAKVIM_PLANI F50.1, Google Görevler benzeri): listeler
/// arası çip, açık görevler (alt görevler girintili), katlanır
/// "Tamamlananlar". Son tarihli görevler takvimin ajandasında da görünür.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, this.now});

  /// Test için "şimdi".
  final DateTime? now;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _listId = TaskList.defaultId;
  bool _showCompleted = false;

  /// Ekran açıkken Google Görevler 15 dk'da bir eşlenir (F50.4, K8).
  Timer? _googleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncGoogle());
    _googleTimer = Timer.periodic(
      GoogleTasksController.refreshEvery,
      (_) => _syncGoogle(),
    );
  }

  @override
  void dispose() {
    _googleTimer?.cancel();
    super.dispose();
  }

  void _syncGoogle() {
    if (!mounted) return;
    unawaited(ref.read(googleTasksProvider.notifier).sync());
  }

  Future<void> _googleMenu() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = ref.read(googleTasksProvider.notifier);
    if (!ref.read(googleTasksProvider).connected) {
      final ok = await ctrl.connect();
      if (ok) {
        messenger.showMessage(l10n.gtasksConnected);
      } else {
        showGoogleConnectFailure(
          messenger,
          l10n,
          ref.read(googleTasksProvider).error,
          fallback: l10n.gtasksFailed,
          apiName: 'Google Tasks API',
          apiHost: 'tasks.googleapis.com',
        );
      }
      return;
    }
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(l10n.gtasksSyncNow),
              onTap: () => Navigator.pop(ctx, 'sync'),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: Text(l10n.gcalDisconnect),
              onTap: () => Navigator.pop(ctx, 'off'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'sync') {
      await ctrl.sync(force: true);
      final error = ref.read(googleTasksProvider).error;
      messenger.showMessage(
        error == null ? l10n.gtasksSynced : l10n.gtasksFailed,
      );
    } else if (choice == 'off') {
      await ctrl.disconnect();
    }
  }

  Future<String?> _askListName({String initial = ''}) => showDialog<String>(
    context: context,
    builder: (_) => _ListNameDialog(initial: initial),
  );

  Future<void> _newList(List<TaskList> lists) async {
    final name = await _askListName();
    if (name == null || name.isEmpty || !mounted) return;
    final repo = ref.read(calendarRepositoryProvider);
    final saved = repo?.saveTaskList(
      TaskList(id: '', title: name, position: lists.length + 1),
    );
    if (saved != null) setState(() => _listId = saved.id);
  }

  Future<void> _listMenu(
    String action,
    TaskList? list,
    List<TaskItem> all,
  ) async {
    final repo = ref.read(calendarRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    switch (action) {
      case 'rename':
        if (list == null) return;
        final name = await _askListName(initial: list.title);
        if (name == null || name.isEmpty) return;
        repo.saveTaskList(
          TaskList(
            id: list.id,
            title: name,
            position: list.position,
            google: list.google,
            createdAt: list.createdAt,
            extras: list.extras,
          ),
        );
      case 'delete':
        if (list == null) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(l10n.tasksDeleteListConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        if (ok != true) return;
        repo.deleteTaskList(list.id, all);
        if (mounted) setState(() => _listId = TaskList.defaultId);
      case 'clear':
        repo.clearCompleted(all, listId: _listId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = ref.watch(tasksStreamProvider).value ?? const <TaskItem>[];
    final lists = [
      for (final l
          in ref.watch(taskListsStreamProvider).value ?? const <TaskList>[])
        if (!l.isDefault) l,
    ];
    if (_listId != TaskList.defaultId && !lists.any((l) => l.id == _listId)) {
      _listId = TaskList.defaultId;
    }
    final current = lists.where((l) => l.id == _listId).firstOrNull;
    // Silinmiş listeye ait görev varsayılan listede görünür (kaybolmasın).
    final known = {TaskList.defaultId, for (final l in lists) l.id};
    final inList = [
      for (final t in all)
        if ((known.contains(t.listId) ? t.listId : TaskList.defaultId) ==
            _listId)
          t,
    ];
    final ids = {for (final t in inList) t.id};
    final parents = [
      for (final t in inList)
        if (!t.completed && (t.parentId.isEmpty || !ids.contains(t.parentId)))
          t,
    ];
    final children = <String, List<TaskItem>>{};
    for (final t in inList) {
      if (t.parentId.isNotEmpty && ids.contains(t.parentId) && !t.completed) {
        (children[t.parentId] ??= []).add(t);
      }
    }
    final completed =
        [
          for (final t in inList)
            if (t.completed) t,
        ]..sort(
          (a, b) => (b.completedAt ?? DateTime(0)).compareTo(
            a.completedAt ?? DateTime(0),
          ),
        );
    final now = widget.now ?? DateTime.now();

    final rows = <Widget>[
      for (final p in parents) ...[
        _TaskRow(task: p, now: now, listId: _listId),
        for (final c in children[p.id] ?? const <TaskItem>[])
          _TaskRow(task: c, now: now, listId: _listId, indent: true),
      ],
      if (completed.isNotEmpty)
        ListTile(
          key: const ValueKey('tasks-completed-toggle'),
          title: Text(l10n.tasksCompleted(completed.length)),
          trailing: Icon(
            _showCompleted ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () => setState(() => _showCompleted = !_showCompleted),
        ),
      if (_showCompleted)
        for (final t in completed) _TaskRow(task: t, now: now, listId: _listId),
    ];

    final google = ref.watch(googleTasksProvider);
    final bar = AppBar(
      title: Text(l10n.tasksTitle),
      actions: [
        if (ref.watch(googleCalendarAvailableProvider))
          IconButton(
            key: const ValueKey('tasks-google'),
            tooltip: l10n.gtasksTitle,
            onPressed: google.loading ? null : () => unawaited(_googleMenu()),
            icon: google.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    google.connected
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_outlined,
                  ),
          ),
        PopupMenuButton<String>(
          onSelected: (v) => _listMenu(v, current, all),
          itemBuilder: (_) => [
            if (current != null) ...[
              PopupMenuItem(value: 'rename', child: Text(l10n.tasksRenameList)),
              PopupMenuItem(value: 'delete', child: Text(l10n.tasksDeleteList)),
            ],
            PopupMenuItem(
              value: 'clear',
              enabled: completed.isNotEmpty,
              child: Text(l10n.tasksClearCompleted),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: HomeInBar(appBar: bar),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('tasks-new'),
        onPressed: () => showTaskEditor(context, listId: _listId),
        icon: const Icon(Icons.add_task),
        label: Text(l10n.tasksNewTask),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final l in [
                  const TaskList(id: TaskList.defaultId),
                  ...lists,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(taskListTitle(l10n, l)),
                      selected: l.id == _listId,
                      onSelected: (_) => setState(() => _listId = l.id),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(l10n.tasksNewList),
                  onPressed: () => _newList(lists),
                ),
              ],
            ),
          ),
          Expanded(
            child: parents.isEmpty && completed.isEmpty
                ? EmptyState(
                    icon: Icons.task_alt,
                    title: l10n.tasksEmpty,
                    subtitle: l10n.tasksEmptyHint,
                  )
                : ListView(
                    key: const ValueKey('tasks-list'),
                    padding: EdgeInsets.only(
                      bottom: 96 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: rows,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({
    required this.task,
    required this.now,
    required this.listId,
    this.indent = false,
  });

  final TaskItem task;
  final DateTime now;
  final String listId;
  final bool indent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(calendarRepositoryProvider);
    final overdue = task.isOverdue(now);
    final dueText = switch (task.dueDay) {
      null => null,
      final d => [
        if (overdue) l10n.taskOverdue,
        d == startOfDay(now)
            ? l10n.calendarToday
            : DateFormat.MMMEd().format(d),
        if (task.hasTime) task.dueTime,
      ].join(' · '),
    };
    final sub = [if (task.notes.isNotEmpty) task.notes.split('\n').first];
    return ListTile(
      contentPadding: EdgeInsetsDirectional.only(
        start: indent ? 48 : 8,
        end: 4,
      ),
      leading: Checkbox(
        value: task.completed,
        onChanged: repo == null
            ? null
            : (v) => setTaskCompleted(ref, task, v == true),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          color: task.completed ? scheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: dueText == null && sub.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sub.isNotEmpty)
                  Text(sub.first, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (dueText != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dueText,
                        style: TextStyle(
                          color: overdue ? scheme.error : scheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      if (task.repeats)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.repeat,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.starred) Icon(Icons.star, size: 18, color: scheme.tertiary),
          if (!indent && !task.completed)
            IconButton(
              tooltip: l10n.taskAddSubtask,
              icon: const Icon(Icons.subdirectory_arrow_right, size: 20),
              onPressed: () => showTaskEditor(
                context,
                parentId: task.id,
                listId: task.listId,
              ),
            ),
        ],
      ),
      onTap: () => showTaskEditor(context, existing: task),
    );
  }
}

/// Liste adı penceresi. Denetleyici pencerenin KENDİ ömründe: dışarıda
/// `whenComplete` ile atılınca kapanış geçişi sürerken kullanılıyordu.
class _ListNameDialog extends StatefulWidget {
  const _ListNameDialog({required this.initial});

  final String initial;

  @override
  State<_ListNameDialog> createState() => _ListNameDialogState();
}

class _ListNameDialogState extends State<_ListNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.initial.isEmpty ? l10n.tasksNewList : l10n.tasksRenameList,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.tasksListNameHint),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.eventSave),
        ),
      ],
    );
  }
}
