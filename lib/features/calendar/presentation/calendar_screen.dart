import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_frame.dart';
import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/calendar_repository.dart';
import '../domain/agenda.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';
import 'event_editor.dart';
import 'month_grid.dart';
import 'task_editor.dart';

/// Hatırlatıcılı notlar (gizli klasör bastırması Hatırlatıcılar ekranıyla
/// aynı kural).
final calendarReminderNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  return [
    for (final n in notes)
      if (n.reminderAt != null &&
          (n.folderId == null || !suppressed.contains(n.folderId)))
        n,
  ];
});

/// Geniş düzen eşiği: ay ızgarası solda sabit, ajanda sağda.
const _kWideCalendar = 720.0;

/// Ajandanın bir seferde gösterdiği gün sayısı ("Daha ileri" uzatır).
const _kAgendaWindowDays = 60;

/// **TAKVİM** (TAKVIM_PLANI Faz 47). Telefonda varsayılan AJANDA + üstte
/// açılır ay ızgarası; genişte yan yana. Etkinlikler, görevler ve not
/// hatırlatıcıları tek listede (K5).
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.now});

  /// Test için "şimdi".
  final DateTime? now;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _today = startOfDay(widget.now ?? DateTime.now());
  late DateTime _selected = _today;
  late DateTime _month = monthOf(_today);
  bool _monthOpen = false;
  int _windowDays = _kAgendaWindowDays;

  void _select(DateTime day) => setState(() {
    _selected = startOfDay(day);
    _month = monthOf(day);
    _windowDays = _kAgendaWindowDays;
  });

  void _goToday() {
    _today = startOfDay(widget.now ?? DateTime.now());
    _select(_today);
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  Future<void> _newEvent() => showEventEditor(context, day: _selected);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = ref.watch(eventsStreamProvider);
    final tasks = ref.watch(tasksStreamProvider).value ?? const <TaskItem>[];
    final reminders = ref.watch(calendarReminderNotesProvider);
    final eventList = events.value ?? const <CalendarEvent>[];
    final wide = MediaQuery.sizeOf(context).width >= _kWideCalendar;

    // Ay ızgarasının noktaları: görünen 6 haftanın kayıtları.
    final gridStart = gridStartFor(
      _month,
      MaterialLocalizations.of(context).firstDayOfWeekIndex,
    );
    final busy = buildAgenda(
      from: gridStart,
      to: DateTime(gridStart.year, gridStart.month, gridStart.day + 42),
      events: eventList,
      tasks: tasks,
      reminderNotes: reminders,
    ).keys.toSet();

    final grid = MonthGrid(
      month: _month,
      selected: _selected,
      busy: busy,
      now: _today,
      showHeader: wide,
      onSelect: (d) {
        _select(d);
        if (!wide) setState(() => _monthOpen = false);
      },
      onMonthChange: _shiftMonth,
    );

    final isEmpty =
        events.hasValue &&
        eventList.isEmpty &&
        tasks.isEmpty &&
        reminders.isEmpty;

    final agenda = isEmpty
        ? EmptyState(
            icon: Icons.calendar_month_outlined,
            title: l10n.calendarEmpty,
            subtitle: l10n.calendarEmptyHint,
            actionLabel: l10n.calendarNewEvent,
            actionIcon: Icons.add,
            onAction: _newEvent,
          )
        : _AgendaList(
            key: ValueKey(dayKey(_selected)),
            from: _selected,
            days: _windowDays,
            today: _today,
            events: eventList,
            tasks: tasks,
            reminders: reminders,
            onMore: () => setState(() => _windowDays += _kAgendaWindowDays),
          );

    final bar = AppBar(
      title: wide
          ? Text(l10n.calendarTitle)
          : InkWell(
              key: const ValueKey('calendar-month-toggle'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _monthOpen = !_monthOpen),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat.yMMMM().format(_month),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _monthOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      semanticLabel: _monthOpen
                          ? l10n.calendarHideMonth
                          : l10n.calendarShowMonth,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        IconButton(
          tooltip: l10n.calendarToday,
          icon: const Icon(Icons.today_outlined),
          onPressed: _goToday,
        ),
        IconButton(
          key: const ValueKey('calendar-tasks'),
          tooltip: l10n.tasksTitle,
          icon: const Icon(Icons.task_alt),
          onPressed: () => unawaited(context.push('/tasks')),
        ),
        IconButton(
          tooltip: l10n.remindersTitle,
          icon: const Icon(Icons.alarm_outlined),
          onPressed: () => unawaited(context.push('/reminders')),
        ),
      ],
    );

    return Scaffold(
      appBar: HomeInBar(appBar: bar),
      floatingActionButton: isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('calendar-new-event'),
              onPressed: _newEvent,
              icon: const Icon(Icons.add),
              label: Text(l10n.calendarNewEvent),
            ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: SingleChildScrollView(child: grid)),
                const VerticalDivider(width: 1),
                Expanded(child: agenda),
              ],
            )
          : Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _monthOpen
                      ? grid
                      : const SizedBox(width: double.infinity),
                ),
                if (_monthOpen) const Divider(height: 1),
                Expanded(child: agenda),
              ],
            ),
    );
  }
}

/// Seçili günden başlayan ajanda: kaydı olan günler + seçili gün (boşsa
/// "plan yok"). Tembel liste: satırlar görünür olunca kurulur.
class _AgendaList extends ConsumerWidget {
  const _AgendaList({
    super.key,
    required this.from,
    required this.days,
    required this.today,
    required this.events,
    required this.tasks,
    required this.reminders,
    required this.onMore,
  });

  final DateTime from;
  final int days;
  final DateTime today;
  final List<CalendarEvent> events;
  final List<TaskItem> tasks;
  final List<Note> reminders;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final to = DateTime(from.year, from.month, from.day + days);
    final agenda = buildAgenda(
      from: from,
      to: to,
      events: events,
      tasks: tasks,
      reminderNotes: reminders,
    );
    final rows = <Object>[];
    final selectedKey = dayKey(from);
    if (!agenda.containsKey(selectedKey)) {
      rows
        ..add(from)
        ..add(l10n.calendarNothingThisDay);
    }
    for (final e in agenda.entries) {
      rows.add(parseDayKey(e.key)!);
      rows.addAll(e.value);
    }
    rows.add(#more);

    return ListView.builder(
      key: const ValueKey('calendar-agenda'),
      padding: EdgeInsets.fromLTRB(
        12,
        4,
        12,
        96 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        return switch (row) {
          DateTime day => _DayHeader(day: day, today: today),
          String text => Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          EventOccurrence occ => _EventTile(occurrence: occ),
          TaskEntry t => _TaskTile(task: t.task),
          ReminderEntry r => _ReminderTile(entry: r),
          _ => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton.icon(
                onPressed: onMore,
                icon: const Icon(Icons.expand_more),
                label: Text(l10n.calendarMoreDays),
              ),
            ),
          ),
        };
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.today});

  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final text = isToday
        ? '${context.l10n.calendarToday} · ${DateFormat.MMMMEEEEd().format(day)}'
        : DateFormat.MMMMEEEEd().format(day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isToday ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Satır kabuğu: solda renk şeridi, kart zemini.
class _EntryShell extends StatelessWidget {
  const _EntryShell({required this.accent, required this.child, this.onTap});

  final Color accent;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.occurrence});

  final EventOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = occurrence.event;
    final scheme = Theme.of(context).colorScheme;
    final time = DateFormat.Hm();
    final when = e.allDay
        ? l10n.eventAllDay
        : '${time.format(occurrence.start)} – ${time.format(occurrence.end)}';
    final sub = [when, if (e.location.isNotEmpty) e.location].join(' · ');
    return _EntryShell(
      accent: e.color != null ? Color(e.color!) : scheme.primary,
      onTap: () => showEventEditor(
        context,
        existing: e,
        occurrenceStart: occurrence.start,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title.isEmpty ? l10n.eventUntitled : e.title,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (e.repeats)
            Icon(Icons.repeat, size: 16, color: scheme.onSurfaceVariant),
          if (e.reminders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.notifications_none,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(calendarRepositoryProvider);
    return _EntryShell(
      accent: scheme.tertiary,
      onTap: () => showTaskEditor(context, existing: task),
      child: Row(
        children: [
          Checkbox(
            value: task.completed,
            onChanged: repo == null
                ? null
                : (v) => v == true
                      ? repo.completeTaskNow(task)
                      : repo.uncompleteTask(task),
          ),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed ? scheme.onSurfaceVariant : null,
              ),
            ),
          ),
          if (task.hasTime)
            Text(
              DateFormat.Hm().format(task.dueAt!),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.entry});

  final ReminderEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final note = entry.note;
    final title = note.displayTitle.trim().isNotEmpty
        ? note.displayTitle.trim()
        : note.locked
        ? l10n.remindersUntitled
        : note.toPlainText().split('\n').first.trim();
    return _EntryShell(
      accent: scheme.secondary,
      onTap: () => unawaited(context.pushNote(noteRoutePath(note.id))),
      child: Row(
        children: [
          Icon(Icons.alarm, size: 18, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? l10n.remindersUntitled : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${DateFormat.Hm().format(entry.at)} · ${l10n.calendarReminderTag}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
