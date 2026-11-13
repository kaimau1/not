import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/presentation/reminder_repeat_ui.dart';
import '../data/calendar_repository.dart';
import '../domain/day_key.dart';
import '../domain/recurrence.dart';
import '../domain/routine.dart';
import '../domain/routine_from_note.dart';
import '../../notes/presentation/note_target_picker.dart';
import '../../../app/theme/app_tokens.dart';

/// **RUTİNLER** (TAKVIM_PLANI Faz 53, K9): liste + seri + son 30 gün şeridi.
/// Rutin, zamanı gelen gün ajandada görünür; adımları gün levhasında tiklenir.
/// Rutinlerin simgesi (kullanıcı isteği 2026-11-06: "rutin simgesini
/// değiştir" — eski meditasyon yapan kişi rutini anlatmıyordu). Takvim
/// çubuğu, ⋮ menüsü, ajanda satırı ve boş ekran hep bunu kullanır.
const IconData kRoutineIcon = Icons.event_repeat_outlined;

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key, this.now});

  /// Test için "bugün".
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final routines = ref.watch(routinesStreamProvider).value ?? const [];
    final logs = ref.watch(routineLogsStreamProvider).value ?? const {};
    final today = startOfDay(now ?? DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routinesTitle),
        actions: [
          IconButton(
            key: const ValueKey('routine-from-note'),
            tooltip: l10n.routineFromNote,
            icon: const Icon(Icons.playlist_add_check),
            onPressed: () => unawaited(_fromNote(context, ref)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('routine-new'),
        tooltip: l10n.routineNew,
        onPressed: () => unawaited(showRoutineEditor(context)),
        child: const Icon(Icons.add),
      ),
      body: routines.isEmpty
          ? EmptyState(
              icon: kRoutineIcon,
              title: l10n.routinesEmpty,
              subtitle: l10n.routinesEmptyHint,
              actionLabel: l10n.routineNew,
              onAction: () => unawaited(showRoutineEditor(context)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                for (final r in routines)
                  _RoutineCard(
                    routine: r,
                    logs: logs[r.id] ?? const {},
                    today: today,
                  ),
              ],
            ),
    );
  }
}

/// Bir notun maddelerinden rutin kurar ve düzenleyicide açar.
Future<void> _fromNote(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(calendarRepositoryProvider);
  final target = await showNoteTargetPicker(context);
  final note = target?.note;
  if (repo == null || note == null || !context.mounted) return;
  final draft = routineFromNote(note);
  final saved = repo.saveRoutine(
    Routine(id: '', title: draft.title, steps: draft.steps),
  );
  unawaited(showRoutineEditor(context, existing: saved));
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.logs,
    required this.today,
  });

  final Routine routine;
  final Map<String, RoutineLog> logs;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final streak = routineStreak(routine, logs, today);
    final strip = routineStrip(routine, logs, today);
    final color = routine.color == null
        ? scheme.primary
        : Color(routine.color!);
    final occursToday = routine.occursOn(today);
    final todayLog = logs[dayKey(today)];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.m),
        onTap: () => unawaited(showRoutineEditor(context, existing: routine)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      routine.title.trim().isEmpty
                          ? l10n.eventUntitled
                          : routine.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (streak > 0)
                    Text(
                      l10n.routineStreak(streak),
                      key: ValueKey('routine-streak-${routine.id}'),
                      style: TextStyle(
                        color: color,
                        fontWeight: AppWeight.strong,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  reminderRepeatLabel(l10n, routine.recurrence.base),
                  if (routine.time.isNotEmpty) routine.time,
                  if (routine.steps.isNotEmpty)
                    l10n.routineStepCount(routine.steps.length),
                ].join(' · '),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              // Son 30 gün: oluş yok = boşluk, yapılmadı = soluk, yapıldı = dolu.
              Row(
                children: [
                  for (final s in strip)
                    Expanded(
                      child: Container(
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: s == null
                              ? Colors.transparent
                              : s
                              ? color
                              : color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.hair),
                        ),
                      ),
                    ),
                ],
              ),
              if (occursToday) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        unawaited(showRoutineDaySheet(context, routine, today)),
                    icon: Icon(
                      todayLog?.completed ?? false
                          ? Icons.check_circle
                          : Icons.play_circle_outline,
                    ),
                    label: Text(
                      todayLog?.completed ?? false
                          ? l10n.routineDoneToday
                          : l10n.routineStartToday,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rutinin bir günü: adımlar tiklenir (adımsızsa tek "Tamamlandı").
Future<void> showRoutineDaySheet(
  BuildContext context,
  Routine routine,
  DateTime day,
) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => _RoutineDaySheet(routine: routine, day: startOfDay(day)),
);

class _RoutineDaySheet extends ConsumerWidget {
  const _RoutineDaySheet({required this.routine, required this.day});

  final Routine routine;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = dayKey(day);
    final log =
        ref.watch(routineLogsStreamProvider).value?[routine.id]?[key] ??
        RoutineLog(routineId: routine.id, day: key);
    final repo = ref.read(calendarRepositoryProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(routine.title, style: Theme.of(context).textTheme.titleLarge),
          Text(DateFormat.yMMMMEEEEd().format(day)),
          const SizedBox(height: 8),
          if (routine.steps.isEmpty)
            CheckboxListTile(
              key: const ValueKey('routine-done'),
              contentPadding: EdgeInsets.zero,
              value: log.completed,
              title: Text(l10n.routineDone),
              onChanged: (v) => repo?.setRoutineLog(
                RoutineLog(
                  routineId: routine.id,
                  day: key,
                  completed: v ?? false,
                ),
              ),
            )
          else
            for (final s in routine.steps)
              CheckboxListTile(
                key: ValueKey('routine-step-${s.id}'),
                contentPadding: EdgeInsets.zero,
                value: log.done.contains(s.id),
                title: Text(s.text),
                onChanged: (_) =>
                    repo?.setRoutineLog(toggleRoutineStep(routine, log, s.id)),
              ),
        ],
      ),
    );
  }
}

/// Rutin oluştur/düzenle.
Future<void> showRoutineEditor(BuildContext context, {Routine? existing}) =>
    showAppSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _RoutineEditor(existing: existing),
    );

class _RoutineEditor extends ConsumerStatefulWidget {
  const _RoutineEditor({this.existing});

  final Routine? existing;

  @override
  ConsumerState<_RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends ConsumerState<_RoutineEditor> {
  final _titleFocus = FocusNode();

  late final _title = TextEditingController(text: widget.existing?.title);
  late final List<TextEditingController> _steps = [
    for (final s in widget.existing?.steps ?? const <RoutineStep>[])
      TextEditingController(text: s.text),
  ];
  late List<String> _stepIds = [
    for (final s in widget.existing?.steps ?? const <RoutineStep>[]) s.id,
  ];
  late Recurrence _repeat =
      widget.existing?.recurrence ?? Recurrence.parse('daily');
  late String _time = widget.existing?.time ?? '';
  late bool _remind = widget.existing?.remind ?? false;

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
    for (final c in _steps) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStep() => setState(() {
    _steps.add(TextEditingController());
    _stepIds = [..._stepIds, 's${DateTime.now().microsecondsSinceEpoch}'];
  });

  Future<void> _pickRepeat() async {
    final picked = await pickReminderRepeat(
      context,
      current: _repeat.base,
      anchor: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _repeat = picked.isNone
          ? Recurrence.parse('daily')
          : _repeat.copyWith(base: picked),
    );
  }

  Future<void> _pickTime() async {
    final hm = parseHm(_time);
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hm?.hour ?? 7, minute: hm?.minute ?? 0),
    );
    if (t == null || !mounted) return;
    String two(int v) => v.toString().padLeft(2, '0');
    setState(() => _time = '${two(t.hour)}:${two(t.minute)}');
  }

  void _save() {
    final repo = ref.read(calendarRepositoryProvider);
    final title = _title.text.trim();
    if (repo == null || title.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final steps = [
      for (var i = 0; i < _steps.length; i++)
        if (_steps[i].text.trim().isNotEmpty)
          RoutineStep(id: _stepIds[i], text: _steps[i].text.trim()),
    ];
    final base = widget.existing ?? const Routine(id: '');
    repo.saveRoutine(
      base.copyWith(
        title: title,
        steps: steps,
        repeat: _repeat.encode(),
        time: _time,
        remind: _remind && _time.isNotEmpty,
      ),
    );
    Navigator.pop(context);
  }

  void _delete() {
    final r = widget.existing;
    final repo = ref.read(calendarRepositoryProvider);
    if (r == null || repo == null) return;
    repo.trashRoutine(r.id);
    final outer = Navigator.of(context).context;
    Navigator.pop(context);
    if (outer.mounted) {
      showUndoSnackBar(
        outer,
        message: outer.l10n.routineDeleted,
        undoLabel: outer.l10n.undo,
        onUndo: () => repo.restoreRoutine(r.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Klavye payı ayrı, ince widget'ta (bkz. [SheetInsetPadding]).
    return SheetInsetPadding(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: widget.existing == null
                  ? l10n.routineNew
                  : l10n.routineEdit,
              actions: [
                if (widget.existing != null)
                  IconButton(
                    tooltip: l10n.eventDelete,
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
                    key: const ValueKey('routine-title'),
                    controller: _title,
                    focusNode: _titleFocus,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                      hintText: l10n.routineTitleHint,
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.repeat),
                    title: Text(l10n.repeatTitle),
                    subtitle: Text(reminderRepeatLabel(l10n, _repeat.base)),
                    onTap: _pickRepeat,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n.routineTime),
                    subtitle: Text(_time.isEmpty ? l10n.eventAllDay : _time),
                    onTap: _pickTime,
                  ),
                  if (_time.isNotEmpty)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.notifications_none),
                      title: Text(l10n.routineRemind),
                      value: _remind,
                      onChanged: (v) => setState(() => _remind = v),
                    ),
                  const Divider(),
                  Text(
                    l10n.routineSteps,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  for (var i = 0; i < _steps.length; i++)
                    Row(
                      children: [
                        const Icon(Icons.check_box_outline_blank, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _steps[i],
                            decoration: InputDecoration(
                              hintText: l10n.routineStepHint,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() {
                            _steps.removeAt(i).dispose();
                            _stepIds = [..._stepIds]..removeAt(i);
                          }),
                        ),
                      ],
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const ValueKey('routine-add-step'),
                      onPressed: _addStep,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.routineAddStep),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const ValueKey('routine-save'),
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

/// Ajanda/gün levhasındaki rutin satırının alt metni: "2/5 adım" ya da durum.
String routineProgressLabel(AppLocalizations l10n, Routine r, RoutineLog log) {
  if (log.completed) return l10n.routineDone;
  if (r.steps.isEmpty) return l10n.routinesTitle;
  return l10n.routineProgress(log.done.length, r.steps.length);
}
