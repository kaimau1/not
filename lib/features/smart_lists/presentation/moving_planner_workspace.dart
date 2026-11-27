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
import '../../notes/domain/note_item.dart';
import '../../notes/domain/smart_lexicon_v2.dart';
import '../../notes/domain/smart_list.dart';
import '../domain/smart_item_meta.dart';

/// **TAŞINMA PLANI ÇALIŞMA ALANI**: Zaman çizelgesi (1 ay önce → yeni ev) veya
/// oda & koli görünümü; kırılacak & önce açılacak etiketleri.
class MovingPlannerWorkspace extends StatefulWidget {
  const MovingPlannerWorkspace({
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
  State<MovingPlannerWorkspace> createState() => _MovingPlannerWorkspaceState();
}

class _MovingPlannerWorkspaceState extends State<MovingPlannerWorkspace> {
  late List<NoteItem> _items = List<NoteItem>.of(
    widget.liveItems?.value ?? widget.initialItems,
  );
  bool _byRoom = false;
  String _selectedSub = 'all';
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
  void didUpdateWidget(covariant MovingPlannerWorkspace oldWidget) {
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

  void _toggle(NoteItem item) {
    unawaited(AppHaptics.tick());
    _commit([
      for (final it in _items)
        if (it.id == item.id) it.copyWith(checked: !it.checked) else it,
    ]);
  }

  void _addTask(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return;
    unawaited(AppHaptics.tick());
    final meta = MovingItemMeta(
      phase: !_byRoom && _selectedSub != 'all' ? _selectedSub : 'week',
      room: _byRoom && _selectedSub != 'all' ? _selectedSub : 'general',
    );
    final item = meta.applyToItem(NoteItem(id: const Uuid().v4(), text: clean));
    _commit([..._items, item]);
    _addCtrl.clear();
  }

  Future<void> _addStarterPack() async {
    final l10n = context.l10n;
    final isTr = l10n.localeName.startsWith('tr');
    final pack = kSmartKindSpecs[SmartListKind.moving]!.starterPacks.first;
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

  Future<void> _editItem(NoteItem item) async {
    final l10n = context.l10n;
    final meta = MovingItemMeta.fromItem(item);
    final nameCtrl = TextEditingController(text: item.text);
    final boxCtrl = TextEditingController(text: meta.box);
    var phase = meta.phase;
    var room = meta.room;
    var fragile = meta.fragile;
    var openFirst = meta.openFirst;
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
                        TextField(
                          key: const ValueKey('moving-edit-box'),
                          controller: boxCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.movingBoxNumber,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.m),
                        Text(l10n.movingViewTimeline, style: text.section),
                        const SizedBox(height: AppSpace.xs),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final p in MovingItemMeta.phases)
                              ChoiceChip(
                                label: Text(_phaseLabel(p, l10n)),
                                selected: phase == p,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => phase = p),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.m),
                        Text(l10n.movingViewRooms, style: text.section),
                        const SizedBox(height: AppSpace.xs),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final r in MovingItemMeta.rooms)
                              ChoiceChip(
                                label: Text(_roomLabel(r, l10n)),
                                selected: room == r,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => room = r),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.s),
                        SwitchListTile(
                          key: const ValueKey('moving-edit-fragile'),
                          title: Text(l10n.movingFragile),
                          value: fragile,
                          onChanged: (v) => setSheet(() => fragile = v),
                        ),
                        SwitchListTile(
                          key: const ValueKey('moving-edit-open-first'),
                          title: Text(l10n.movingOpenFirst),
                          value: openFirst,
                          onChanged: (v) => setSheet(() => openFirst = v),
                        ),
                        const SizedBox(height: AppSpace.m),
                        FilledButton(
                          key: const ValueKey('moving-edit-save'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              kMinInteractiveDimension,
                            ),
                          ),
                          onPressed: () {
                            final nextName = nameCtrl.text.trim();
                            final nextItem =
                                MovingItemMeta(
                                  phase: phase,
                                  room: room,
                                  box: boxCtrl.text.trim(),
                                  fragile: fragile,
                                  openFirst: openFirst,
                                ).applyToItem(
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
    boxCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final tasks = [
      for (final i in _items)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    final done = tasks.where((t) => t.checked).length;
    final boxes = <String>{};
    var fragileCount = 0;
    for (final t in tasks) {
      final m = MovingItemMeta.fromItem(t);
      if (m.box.isNotEmpty) boxes.add(m.box);
      if (m.fragile) fragileCount++;
    }
    final subs = _byRoom ? MovingItemMeta.rooms : MovingItemMeta.phases;
    final visible = [
      for (final t in tasks)
        if (_selectedSub == 'all' ||
            (_byRoom
                ? MovingItemMeta.fromItem(t).room == _selectedSub
                : MovingItemMeta.fromItem(t).phase == _selectedSub))
          t,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.trim().isEmpty ? l10n.smartListMoving : widget.title,
        ),
        actions: [
          IconButton(
            tooltip: l10n.smartListStarterPacks,
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: _addStarterPack,
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
                          '$done / ${tasks.length}',
                          style: text.rowTitle,
                        ),
                      ),
                      Text(
                        '📦 ${l10n.movingBoxesCount(boxes.length)} · ⚠️ ${l10n.movingFragileCount(fragileCount)}',
                        style: text.meta,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.hair),
                    child: LinearProgressIndicator(
                      value: tasks.isEmpty ? 0 : done / tasks.length,
                      minHeight: AppSpace.xs,
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.timeline_outlined),
                        label: Text(l10n.movingViewTimeline),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.meeting_room_outlined),
                        label: Text(l10n.movingViewRooms),
                      ),
                    ],
                    selected: {_byRoom},
                    onSelectionChanged: (s) => setState(() {
                      _byRoom = s.first;
                      _selectedSub = 'all';
                    }),
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
                    selected: _selectedSub == 'all',
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedSub = 'all'),
                  ),
                ),
                for (final s in subs)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.s),
                    child: ChoiceChip(
                      key: ValueKey('moving-sub-$s'),
                      label: Text(
                        _byRoom ? _roomLabel(s, l10n) : _phaseLabel(s, l10n),
                      ),
                      selected: _selectedSub == s,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedSub = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: FilledButton.tonalIcon(
                      onPressed: _addStarterPack,
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
                      final m = MovingItemMeta.fromItem(item);
                      return Material(
                        color: tokens.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          side: BorderSide(color: tokens.hairline),
                        ),
                        child: InkWell(
                          key: ValueKey('moving-row-${item.id}'),
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          onTap: () => _editItem(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.m,
                              vertical: AppSpace.s,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.checked,
                                  onChanged: (_) => _toggle(item),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.text,
                                        style: text.rowTitle.copyWith(
                                          decoration: item.checked
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: item.checked
                                              ? scheme.onSurfaceVariant
                                              : scheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpace.xxs),
                                      Wrap(
                                        spacing: AppSpace.xs,
                                        runSpacing: AppSpace.xxs,
                                        children: [
                                          _MiniTag(
                                            label: _byRoom
                                                ? _phaseLabel(m.phase, l10n)
                                                : _roomLabel(m.room, l10n),
                                            color: scheme.surfaceContainerHigh,
                                            textColor: scheme.onSurfaceVariant,
                                          ),
                                          if (m.box.isNotEmpty)
                                            _MiniTag(
                                              label: m.box,
                                              color: tokens.resolvedTintSoft(
                                                scheme,
                                              ),
                                              textColor: scheme.primary,
                                            ),
                                          if (m.fragile)
                                            _MiniTag(
                                              label: '⚠️ ${l10n.movingFragile}',
                                              color: scheme.errorContainer,
                                              textColor:
                                                  scheme.onErrorContainer,
                                            ),
                                          if (m.openFirst)
                                            _MiniTag(
                                              label: l10n.movingOpenFirst,
                                              color: tokens.resolvedWarmTint(
                                                scheme,
                                              ),
                                              textColor: scheme.secondary,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
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
                      key: const ValueKey('moving-add-field'),
                      controller: _addCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _addTask,
                      decoration: InputDecoration(
                        hintText: l10n.movingAddHint,
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
                    onPressed: () => _addTask(_addCtrl.text),
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

  String _phaseLabel(String p, AppLocalizations l10n) => switch (p) {
    'month' => l10n.movingPhaseMonth,
    'week' => l10n.movingPhaseWeek,
    'day' => l10n.movingPhaseDay,
    'new_home' => l10n.movingPhaseNewHome,
    _ => l10n.movingPhaseWeek,
  };

  String _roomLabel(String r, AppLocalizations l10n) => switch (r) {
    'kitchen' => l10n.movingRoomKitchen,
    'living' => l10n.movingRoomLiving,
    'bedroom' => l10n.movingRoomBedroom,
    'bath' => l10n.movingRoomBath,
    'study' => l10n.movingRoomStudy,
    _ => l10n.movingRoomGeneral,
  };
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.of(Theme.of(context)).badge.copyWith(color: textColor),
      ),
    );
  }
}
