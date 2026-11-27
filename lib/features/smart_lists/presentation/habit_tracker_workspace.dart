import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/smart_lexicon_v2.dart';
import '../../notes/domain/smart_list.dart';
import '../domain/smart_item_meta.dart';

/// **ALIŞKANLIK TAKİBİ ÇALIŞMA ALANI**: 7 günlük dokunulabilir daireler,
/// seri sayacı, zaman dilimi süzgeci ve 30 günlük ısı haritası.
class HabitTrackerWorkspace extends StatefulWidget {
  const HabitTrackerWorkspace({
    super.key,
    required this.title,
    required this.initialItems,
    required this.onReplaceItems,
    this.liveItems,
    this.now,
  });

  final String title;
  final List<NoteItem> initialItems;
  final List<NoteItem> Function(List<NoteItem> updated) onReplaceItems;
  final ValueListenable<List<NoteItem>>? liveItems;
  final DateTime? now;

  @override
  State<HabitTrackerWorkspace> createState() => _HabitTrackerWorkspaceState();
}

class _HabitTrackerWorkspaceState extends State<HabitTrackerWorkspace> {
  late List<NoteItem> _items = List<NoteItem>.of(
    widget.liveItems?.value ?? widget.initialItems,
  );
  int _weekOffset = 0;
  String _filter = 'all'; // all | morning | afternoon | evening | remaining
  final _addCtrl = TextEditingController();

  DateTime get _today {
    final d = widget.now ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  DateTime get _monday {
    final base = _today.subtract(Duration(days: _today.weekday - 1));
    return base.add(Duration(days: _weekOffset * 7));
  }

  void _onLive() {
    final live = widget.liveItems;
    if (!mounted || live == null) return;
    setState(() => _items = List<NoteItem>.of(live.value));
  }

  @override
  void initState() {
    super.initState();
    widget.liveItems?.addListener(_onLive);
  }

  @override
  void didUpdateWidget(covariant HabitTrackerWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveItems != widget.liveItems) {
      oldWidget.liveItems?.removeListener(_onLive);
      widget.liveItems?.addListener(_onLive);
      if (widget.liveItems != null) {
        _items = List<NoteItem>.of(widget.liveItems!.value);
      }
    }
  }

  @override
  void dispose() {
    widget.liveItems?.removeListener(_onLive);
    _addCtrl.dispose();
    super.dispose();
  }

  void _commit(List<NoteItem> next) {
    setState(() => _items = widget.onReplaceItems(next));
  }

  void _toggleDay(NoteItem item, DateTime day) {
    unawaited(AppHaptics.tick());
    final key = isoDayKey(day);
    final todayKey = isoDayKey(_today);
    final meta = HabitItemMeta.fromItem(item).toggledOn(key);
    final updated = meta.applyToItem(item, todayKey: todayKey);
    _commit([
      for (final it in _items)
        if (it.id == item.id) updated else it,
    ]);
  }

  void _addHabit(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return;
    unawaited(AppHaptics.tick());
    final time =
        (_filter == 'morning' || _filter == 'afternoon' || _filter == 'evening')
        ? _filter
        : '';
    var item = NoteItem(id: const Uuid().v4(), text: clean);
    if (time.isNotEmpty) {
      item = HabitItemMeta(timeOfDay: time).applyToItem(item);
    }
    _commit([..._items, item]);
    _addCtrl.clear();
  }

  Future<void> _openStarterPacks() async {
    final l10n = context.l10n;
    final isTr = l10n.localeName.startsWith('tr');
    final spec = kSmartKindSpecs[SmartListKind.habits]!;
    final pack = await showAppSheet<SmartStarterPack>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          0,
          AppSpace.l,
          AppSpace.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.smartListStarterPacks),
            for (final p in spec.starterPacks)
              ListTile(
                leading: Icon(p.icon, color: spec.accent),
                title: Text(p.name(isTr: isTr)),
                subtitle: Text(p.desc(isTr: isTr)),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (pack == null || !mounted) return;
    final names = pack.items(isTr: isTr);
    final existingKeys = {for (final i in _items) i.text.trim().toLowerCase()};
    final added = <NoteItem>[];
    for (var i = 0; i < names.length; i++) {
      final t = names[i].trim();
      if (t.isEmpty || existingKeys.contains(t.toLowerCase())) continue;
      final ex = pack.extrasByIndex[i];
      added.add(
        NoteItem(
          id: const Uuid().v4(),
          text: t,
          extras: ex == null ? const {} : Map<String, dynamic>.from(ex),
        ),
      );
    }
    if (added.isNotEmpty) {
      unawaited(AppHaptics.thud());
      _commit([..._items, ...added]);
    }
  }

  Future<void> _openHabitDetails(NoteItem item) async {
    final l10n = context.l10n;
    final today = _today;
    final meta = HabitItemMeta.fromItem(item);
    final ctrl = TextEditingController(text: item.text);
    var target = meta.weeklyTarget;
    var time = meta.timeOfDay;
    final res =
        await showAppSheet<
          ({bool delete, String name, int target, String time})
        >(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              final theme = Theme.of(ctx);
              final scheme = theme.colorScheme;
              final text = AppText.of(theme);
              final dots = meta.last30Days(today);
              return SheetInsetPadding(
                extra: AppSpace.l,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SheetHeader(
                      title: item.text,
                      actions: [
                        IconButton(
                          tooltip: l10n.delete,
                          icon: Icon(Icons.delete_outline, color: scheme.error),
                          onPressed: () => Navigator.pop(ctx, (
                            delete: true,
                            name: '',
                            target: target,
                            time: time,
                          )),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.l,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: ctrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: l10n.smartListItemNameHint,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.m,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.m),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.habitWeeklyGoal,
                                  style: text.section,
                                ),
                              ),
                              IconButton(
                                onPressed: target > 1
                                    ? () => setSheetState(() => target--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$target / 7', style: text.rowTitle),
                              IconButton(
                                onPressed: target < 7
                                    ? () => setSheetState(() => target++)
                                    : null,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.s),
                          Wrap(
                            spacing: AppSpace.s,
                            children: [
                              for (final opt in [
                                ('', l10n.smartListAll),
                                ('morning', l10n.habitTimeMorning),
                                ('afternoon', l10n.habitTimeAfternoon),
                                ('evening', l10n.habitTimeEvening),
                              ])
                                ChoiceChip(
                                  label: Text(opt.$2),
                                  selected: time == opt.$1,
                                  showCheckmark: false,
                                  onSelected: (_) =>
                                      setSheetState(() => time = opt.$1),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.m),
                          Text(
                            '${l10n.habitLast30Days} · ${l10n.habitBestStreak(meta.bestStreak())}',
                            style: text.meta,
                          ),
                          const SizedBox(height: AppSpace.s),
                          Wrap(
                            spacing: AppSpace.xs,
                            runSpacing: AppSpace.xs,
                            children: [
                              for (final ok in dots)
                                Container(
                                  width: AppSpace.m,
                                  height: AppSpace.m,
                                  decoration: BoxDecoration(
                                    color: ok
                                        ? scheme.primary
                                        : scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.xs,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.l),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                kMinInteractiveDimension,
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx, (
                              delete: false,
                              name: ctrl.text.trim(),
                              target: target,
                              time: time,
                            )),
                            child: Text(l10n.eventSave),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
    ctrl.dispose();
    if (res == null || !mounted) return;
    if (res.delete) {
      _commit([
        for (final it in _items)
          if (it.id != item.id) it,
      ]);
      return;
    }
    final nextName = res.name.isEmpty ? item.text : res.name;
    final nextItem = meta
        .copyWith(weeklyTarget: res.target, timeOfDay: res.time)
        .applyToItem(item.copyWith(text: nextName));
    _commit([
      for (final it in _items)
        if (it.id == item.id) nextItem else it,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final today = _today;
    final todayKey = isoDayKey(today);
    final monday = _monday;
    final weekDays = [
      for (var i = 0; i < 7; i++) monday.add(Duration(days: i)),
    ];
    final habits = [
      for (final it in _items)
        if (!it.header && it.text.trim().isNotEmpty) it,
    ];
    var doneToday = 0;
    var bestActiveStreak = 0;
    for (final h in habits) {
      final m = HabitItemMeta.fromItem(h);
      if (m.isDoneOn(todayKey)) doneToday++;
      final st = m.currentStreak(today);
      if (st > bestActiveStreak) bestActiveStreak = st;
    }
    final visible = [
      for (final h in habits)
        if (_matchesFilter(h, todayKey)) h,
    ];
    final weekLabel =
        '${DateFormat.MMMd(l10n.localeName).format(weekDays.first)} – ${DateFormat.MMMd(l10n.localeName).format(weekDays.last)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.trim().isEmpty ? l10n.smartListHabits : widget.title,
        ),
        actions: [
          IconButton(
            key: const ValueKey('habit-starter-packs'),
            tooltip: l10n.smartListStarterPacks,
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: _openStarterPacks,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.xs,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.m),
              decoration: BoxDecoration(
                color: tokens.resolvedSheetCard(scheme),
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: tokens.hairline),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSpace.xxxl + AppSpace.m,
                    height: AppSpace.xxxl + AppSpace.m,
                    child: CircularProgressIndicator(
                      value: habits.isEmpty ? 0 : doneToday / habits.length,
                      strokeWidth: AppSpace.xs,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.habitDoneToday(doneToday, habits.length),
                          key: const ValueKey('habit-summary-today'),
                          style: text.rowTitle,
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          l10n.habitBestStreak(bestActiveStreak),
                          style: text.meta.copyWith(color: scheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.habitPrevWeek,
                    onPressed: () => setState(() => _weekOffset--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(weekLabel, style: text.label),
                  IconButton(
                    tooltip: l10n.habitNextWeek,
                    onPressed: _weekOffset < 0
                        ? () => setState(() => _weekOffset++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: AppSpace.xxxl + AppSpace.m,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
              children: [
                for (final f in [
                  ('all', l10n.smartListAll),
                  ('remaining', l10n.habitFilterRemaining),
                  ('morning', l10n.habitTimeMorning),
                  ('afternoon', l10n.habitTimeAfternoon),
                  ('evening', l10n.habitTimeEvening),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.s),
                    child: ChoiceChip(
                      key: ValueKey('habit-filter-${f.$1}'),
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = f.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.smartListWorkspaceEmpty,
                            textAlign: TextAlign.center,
                            style: text.body.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpace.m),
                          FilledButton.tonalIcon(
                            onPressed: _openStarterPacks,
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: Text(l10n.smartListStarterPacks),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.l,
                      AppSpace.s,
                      AppSpace.l,
                      AppSpace.l,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.s),
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final meta = HabitItemMeta.fromItem(item);
                      final streak = meta.currentStreak(today);
                      final weekDone = meta.weekDoneCount(monday);
                      return Container(
                        key: ValueKey('habit-card-${item.id}'),
                        padding: const EdgeInsets.all(AppSpace.m),
                        decoration: BoxDecoration(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(AppRadius.l),
                          border: Border.all(color: tokens.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(AppRadius.s),
                              onTap: () => _openHabitDetails(item),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.text,
                                      style: text.rowTitle,
                                    ),
                                  ),
                                  if (meta.timeOfDay.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: AppSpace.xs,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpace.s,
                                          vertical: AppSpace.xxs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pill,
                                          ),
                                        ),
                                        child: Text(
                                          _timeLabel(meta.timeOfDay, l10n),
                                          style: text.badge,
                                        ),
                                      ),
                                    ),
                                  if (streak > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpace.s,
                                        vertical: AppSpace.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tokens.resolvedWarmTint(scheme),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        '🔥 ${l10n.habitStreakDays(streak)}',
                                        key: ValueKey(
                                          'habit-streak-${item.id}',
                                        ),
                                        style: text.badge.copyWith(
                                          color: scheme.secondary,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: AppSpace.xs),
                                  Text(
                                    '$weekDone/${meta.weeklyTarget}',
                                    style: text.meta,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.s),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final day in weekDays)
                                  _DayCircle(
                                    key: ValueKey(
                                      'habit-day-${item.id}-${isoDayKey(day)}',
                                    ),
                                    label: DateFormat.E(l10n.localeName)
                                        .format(day)
                                        .substring(0, 2),
                                    done: meta.isDoneOn(isoDayKey(day)),
                                    isToday: isoDayKey(day) == todayKey,
                                    onTap: () => _toggleDay(item, day),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          _BottomQuickAddBar(
            controller: _addCtrl,
            hint: l10n.habitAddHint,
            onSubmit: _addHabit,
          ),
        ],
      ),
    );
  }

  bool _matchesFilter(NoteItem item, String todayKey) {
    final m = HabitItemMeta.fromItem(item);
    return switch (_filter) {
      'remaining' => !m.isDoneOn(todayKey),
      'morning' => m.timeOfDay == 'morning',
      'afternoon' => m.timeOfDay == 'afternoon',
      'evening' => m.timeOfDay == 'evening',
      _ => true,
    };
  }

  String _timeLabel(String t, AppLocalizations l10n) => switch (t) {
    'morning' => l10n.habitTimeMorning,
    'afternoon' => l10n.habitTimeAfternoon,
    'evening' => l10n.habitTimeEvening,
    _ => '',
  };
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    super.key,
    required this.label,
    required this.done,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final bool done;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    return Semantics(
      button: true,
      toggled: done,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: SizedBox(
          width: AppSpace.xxxl + AppSpace.m,
          height: kMinInteractiveDimension,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: text.badge.copyWith(
                  color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Container(
                width: AppSpace.xl + AppSpace.xs,
                height: AppSpace.xl + AppSpace.xs,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? scheme.primary : scheme.surfaceContainerHigh,
                  border: isToday && !done
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                child: done
                    ? Icon(
                        Icons.check,
                        size: AppIconSize.xs,
                        color: scheme.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomQuickAddBar extends StatelessWidget {
  const _BottomQuickAddBar({
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          AppSpace.xs,
          AppSpace.l,
          AppSpace.m,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('workspace-quick-add'),
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: onSubmit,
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.l,
                    vertical: AppSpace.m,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s),
            FilledButton(
              key: const ValueKey('workspace-quick-add-btn'),
              onPressed: () => onSubmit(controller.text),
              style: FilledButton.styleFrom(
                minimumSize: const Size(
                  kMinInteractiveDimension,
                  kMinInteractiveDimension,
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
