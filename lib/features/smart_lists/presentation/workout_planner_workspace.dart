import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/smart_lexicon_v2.dart';
import '../../notes/domain/smart_list.dart';
import '../domain/smart_item_meta.dart';

/// **ANTRENMAN ÇALIŞMA ALANI**: Etkileşimli set balonları, ağırlık/tekrar
/// düzenleyici, kas grubu süzgeci ve dahili dinlenme sayacı.
class WorkoutPlannerWorkspace extends StatefulWidget {
  const WorkoutPlannerWorkspace({
    super.key,
    required this.title,
    required this.initialItems,
    required this.onReplaceItems,
    this.liveItems,
  });

  final String title;
  final List<NoteItem> initialItems;
  final List<NoteItem> Function(List<NoteItem> updated) onReplaceItems;
  final ValueListenable<List<NoteItem>>? liveItems;

  @override
  State<WorkoutPlannerWorkspace> createState() =>
      _WorkoutPlannerWorkspaceState();
}

class _WorkoutPlannerWorkspaceState extends State<WorkoutPlannerWorkspace> {
  late List<NoteItem> _items = List<NoteItem>.of(
    widget.liveItems?.value ?? widget.initialItems,
  );
  String _zoneFilter = 'all';
  bool _autoRest = true;
  int _restTotal = 60;
  int _restRemaining = 0;
  Timer? _restTimer;
  final _addCtrl = TextEditingController();

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
  void didUpdateWidget(covariant WorkoutPlannerWorkspace oldWidget) {
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
    _restTimer?.cancel();
    _addCtrl.dispose();
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restTotal = seconds;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_restRemaining <= 1) {
        t.cancel();
        unawaited(AppHaptics.heavy());
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  void _stopRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  void _commit(List<NoteItem> next) {
    setState(() => _items = widget.onReplaceItems(next));
  }

  void _tapSet(NoteItem item, int setIndex) {
    unawaited(AppHaptics.tick());
    final nextMeta = WorkoutItemMeta.fromItem(item).toggleSet(setIndex);
    final updated = nextMeta.applyToItem(item);
    _commit([
      for (final it in _items)
        if (it.id == item.id) updated else it,
    ]);
    if (_autoRest && nextMeta.doneSets >= setIndex) {
      _startRest(_restTotal);
    }
  }

  void _addExercise(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return;
    unawaited(AppHaptics.tick());
    final zone = _zoneFilter == 'all' ? 'upper' : _zoneFilter;
    final item = WorkoutItemMeta(zone: zone)
        .applyToItem(NoteItem(id: const Uuid().v4(), text: clean));
    _commit([..._items, item]);
    _addCtrl.clear();
  }

  Future<void> _openStarterPacks() async {
    final l10n = context.l10n;
    final isTr = l10n.localeName.startsWith('tr');
    final spec = kSmartKindSpecs[SmartListKind.workout]!;
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
    final have = {for (final i in _items) i.text.trim().toLowerCase()};
    final fresh = <NoteItem>[];
    for (var i = 0; i < names.length; i++) {
      final t = names[i];
      if (have.contains(t.toLowerCase())) continue;
      final ex = pack.extrasByIndex[i];
      fresh.add(
        NoteItem(
          id: const Uuid().v4(),
          text: t,
          extras: ex == null ? const {} : Map<String, dynamic>.from(ex),
        ),
      );
    }
    if (fresh.isNotEmpty) {
      unawaited(AppHaptics.thud());
      _commit([..._items, ...fresh]);
    }
  }

  Future<void> _editExercise(NoteItem item) async {
    final l10n = context.l10n;
    final meta = WorkoutItemMeta.fromItem(item);
    final nameCtrl = TextEditingController(text: item.text);
    final repsCtrl = TextEditingController(text: meta.reps);
    final weightCtrl = TextEditingController(text: meta.weight);
    var sets = meta.sets;
    var zone = meta.zone;
    final res = await showAppSheet<({bool delete, NoteItem? updated})>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final text = AppText.of(Theme.of(ctx));
          return SheetInsetPadding(
            extra: AppSpace.l,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                    title: l10n.smartListEditItem,
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                        onPressed: () =>
                            Navigator.pop(ctx, (delete: true, updated: null)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.smartListItemNameHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.m),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.workoutSetsLabel,
                                style: text.section,
                              ),
                            ),
                            IconButton(
                              onPressed: sets > 1
                                  ? () => setSheet(() => sets--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$sets', style: text.rowTitle),
                            IconButton(
                              onPressed: sets < 10
                                  ? () => setSheet(() => sets++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.s),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: repsCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n.workoutRepsLabel,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.m,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.s),
                            Expanded(
                              child: TextField(
                                controller: weightCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n.workoutWeightLabel,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.m,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.m),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final z in WorkoutItemMeta.zones)
                              ChoiceChip(
                                label: Text(_zoneLabel(z, l10n)),
                                selected: zone == z,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => zone = z),
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
                          onPressed: () {
                            final nextName = nameCtrl.text.trim();
                            final nextItem = meta
                                .copyWith(
                                  sets: sets,
                                  reps: repsCtrl.text.trim().isEmpty
                                      ? '12'
                                      : repsCtrl.text.trim(),
                                  weight: weightCtrl.text.trim(),
                                  zone: zone,
                                )
                                .applyToItem(
                                  item.copyWith(
                                    text: nextName.isEmpty
                                        ? item.text
                                        : nextName,
                                  ),
                                );
                            Navigator.pop(ctx, (
                              delete: false,
                              updated: nextItem,
                            ));
                          },
                          child: Text(l10n.eventSave),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    nameCtrl.dispose();
    repsCtrl.dispose();
    weightCtrl.dispose();
    if (res == null || !mounted) return;
    if (res.delete) {
      _commit([
        for (final it in _items)
          if (it.id != item.id) it,
      ]);
      return;
    }
    if (res.updated != null) {
      _commit([
        for (final it in _items)
          if (it.id == item.id) res.updated! else it,
      ]);
    }
  }

  void _resetWorkout() {
    final before = List<NoteItem>.of(_items);
    unawaited(AppHaptics.heavy());
    _commit([
      for (final i in _items)
        WorkoutItemMeta.fromItem(i).copyWith(doneSets: 0).applyToItem(i),
    ]);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(
        context.l10n.smartListResetDone,
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () => _commit(before),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final exercises = [
      for (final i in _items)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    final doneCount = exercises.where((e) => e.checked).length;
    final visible = [
      for (final e in exercises)
        if (_zoneFilter == 'all' ||
            WorkoutItemMeta.fromItem(e).zone == _zoneFilter)
          e,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.trim().isEmpty ? l10n.smartListWorkout : widget.title,
        ),
        actions: [
          IconButton(
            tooltip: l10n.smartListStarterPacks,
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: _openStarterPacks,
          ),
          IconButton(
            key: const ValueKey('workout-reset-btn'),
            tooltip: l10n.workoutReset,
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetWorkout,
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
              AppSpace.s,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.m),
              decoration: BoxDecoration(
                color: tokens.resolvedSheetCard(scheme),
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: tokens.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.workoutRestTimer} · $doneCount/${exercises.length}',
                          style: text.rowTitle,
                        ),
                      ),
                      if (_restRemaining > 0)
                        FilledButton.tonalIcon(
                          key: const ValueKey('workout-rest-active'),
                          onPressed: _stopRest,
                          icon: const Icon(Icons.stop, size: AppIconSize.xs),
                          label: Text(l10n.workoutRestSeconds(_restRemaining)),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.workoutAutoTimer, style: text.badge),
                            Switch(
                              value: _autoRest,
                              onChanged: (v) => setState(() => _autoRest = v),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (_restRemaining > 0) ...[
                    const SizedBox(height: AppSpace.s),
                    LinearProgressIndicator(
                      value: _restTotal > 0 ? _restRemaining / _restTotal : 0,
                      minHeight: AppSpace.xs,
                    ),
                  ],
                  const SizedBox(height: AppSpace.s),
                  Wrap(
                    spacing: AppSpace.s,
                    children: [
                      for (final sec in const [30, 60, 90, 120])
                        ActionChip(
                          key: ValueKey('workout-timer-$sec'),
                          label: Text(l10n.workoutRestSeconds(sec)),
                          onPressed: () => _startRest(sec),
                        ),
                    ],
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
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.s),
                  child: ChoiceChip(
                    label: Text(l10n.smartListAll),
                    selected: _zoneFilter == 'all',
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _zoneFilter = 'all'),
                  ),
                ),
                for (final z in WorkoutItemMeta.zones)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.s),
                    child: ChoiceChip(
                      label: Text(_zoneLabel(z, l10n)),
                      selected: _zoneFilter == z,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _zoneFilter = z),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: FilledButton.tonalIcon(
                      onPressed: _openStarterPacks,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text(l10n.smartListStarterPacks),
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
                    itemBuilder: (context, idx) {
                      final item = visible[idx];
                      final meta = WorkoutItemMeta.fromItem(item);
                      final subtitle = [
                        '${meta.sets} × ${meta.reps}',
                        if (meta.weight.isNotEmpty) meta.weight,
                        _zoneLabel(meta.zone, l10n),
                      ].join(' · ');
                      return Container(
                        key: ValueKey('workout-card-${item.id}'),
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
                              onTap: () => _editExercise(item),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.text, style: text.rowTitle),
                                        Text(subtitle, style: text.meta),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    l10n.workoutSetsCount(
                                      meta.doneSets,
                                      meta.sets,
                                    ),
                                    style: text.label.copyWith(
                                      color: item.checked
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.s),
                            Wrap(
                              spacing: AppSpace.s,
                              runSpacing: AppSpace.xs,
                              children: [
                                for (var s = 1; s <= meta.sets; s++)
                                  InkWell(
                                    key: ValueKey('workout-set-${item.id}-$s'),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    onTap: () => _tapSet(item, s),
                                    child: Container(
                                      width: AppSpace.xxxl + AppSpace.s,
                                      height: AppSpace.xxxl + AppSpace.s,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: s <= meta.doneSets
                                            ? scheme.primary
                                            : scheme.surfaceContainerHigh,
                                      ),
                                      child: s <= meta.doneSets
                                          ? Icon(
                                              Icons.check,
                                              size: AppIconSize.xs,
                                              color: scheme.onPrimary,
                                            )
                                          : Text('$s', style: text.label),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.xs,
              AppSpace.l,
              AppSpace.m,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('workout-add-field'),
                      controller: _addCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _addExercise,
                      decoration: InputDecoration(
                        hintText: l10n.workoutAddHint,
                        isDense: true,
                        filled: true,
                        fillColor: scheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s),
                  FilledButton(
                    onPressed: () => _addExercise(_addCtrl.text),
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
          ),
        ],
      ),
    );
  }

  String _zoneLabel(String z, AppLocalizations l10n) => switch (z) {
    'warmup' => l10n.workoutZoneWarmup,
    'upper' => l10n.workoutZoneUpper,
    'lower' => l10n.workoutZoneLower,
    'core' => l10n.workoutZoneCore,
    'cardio' => l10n.workoutZoneCardio,
    'stretch' => l10n.workoutZoneStretch,
    _ => l10n.workoutZoneUpper,
  };
}
