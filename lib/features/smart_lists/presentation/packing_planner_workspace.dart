import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/quick_entry.dart';
import '../../notes/domain/smart_lexicon_v2.dart';
import '../../notes/domain/smart_list.dart';
import '../domain/smart_item_meta.dart';
import 'smart_wizards.dart';
import 'workspace_empty_packs.dart';

/// **BAVUL VE SEYAHAT ÇALIŞMA ALANI**: Seyahat sihirbazı (gün × hava × stil),
/// El bagajı / Valiz / Üstümde süzgeci, miktar adımlama ve tek dokunuş sıfırlama.
class PackingPlannerWorkspace extends StatefulWidget {
  const PackingPlannerWorkspace({
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
  State<PackingPlannerWorkspace> createState() =>
      _PackingPlannerWorkspaceState();
}

class _PackingPlannerWorkspaceState extends State<PackingPlannerWorkspace> {
  late List<NoteItem> _items = List<NoteItem>.of(
    widget.liveItems?.value ?? widget.initialItems,
  );
  String _bagFilter = 'all';
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
  void didUpdateWidget(covariant PackingPlannerWorkspace oldWidget) {
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

  void _stepQty(NoteItem item, int delta) {
    unawaited(AppHaptics.tick());
    final meta = PackingItemMeta.fromItem(item);
    final nextQty = ((meta.qty ?? 1) + delta).clamp(1.0, 30.0);
    final nextItem = meta
        .copyWith(qty: nextQty)
        .applyToItem(item, syncTextQty: true);
    _commit([
      for (final it in _items)
        if (it.id == item.id) nextItem else it,
    ]);
  }

  void _cycleBag(NoteItem item) {
    unawaited(AppHaptics.tick());
    final meta = PackingItemMeta.fromItem(item);
    final idx = PackingItemMeta.bags.indexOf(meta.bag);
    final nextBag =
        PackingItemMeta.bags[(idx + 1) % PackingItemMeta.bags.length];
    final nextItem = meta.copyWith(bag: nextBag).applyToItem(item);
    _commit([
      for (final it in _items)
        if (it.id == item.id) nextItem else it,
    ]);
  }

  void _addItem(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return;
    unawaited(AppHaptics.tick());
    final locale = context.l10n.localeName;
    final parsed = QuickParser(packingLexicon(locale))
        .parse(clean, flush: true);
    final newItems = parsed.items.isEmpty
        ? [NoteItem(id: const Uuid().v4(), text: quickCapitalize(clean))]
        : [
            for (final q in parsed.items)
              NoteItem(id: const Uuid().v4(), text: q.text),
          ];
    _commit([
      ..._items,
      for (final ni in newItems)
        if (_bagFilter != 'all')
          PackingItemMeta(bag: _bagFilter).applyToItem(ni)
        else
          ni,
    ]);
    _addCtrl.clear();
  }

  Future<void> _openTripWizard() async {
    final generated = await showTripPackingWizardSheet(context);
    if (generated == null || !mounted) return;
    final have = {for (final i in _items) quickItemKey(i.text)};
    final fresh = <NoteItem>[];
    for (final g in generated) {
      if (have.contains(quickItemKey(g.text))) continue;
      fresh.add(
        NoteItem(
          id: const Uuid().v4(),
          text: g.text,
          extras: Map<String, dynamic>.from(g.extras),
        ),
      );
    }
    if (fresh.isNotEmpty) {
      unawaited(AppHaptics.thud());
      _commit([..._items, ...fresh]);
    }
  }

  void _applyPack(SmartStarterPack pack) {
    final fresh = buildStarterPackItems(
      pack,
      _items,
      isTr: context.l10n.localeName.startsWith('tr'),
    );
    if (fresh.isNotEmpty) {
      unawaited(AppHaptics.thud());
      _commit([..._items, ...fresh]);
    }
  }

  void _resetAll() {
    final before = List<NoteItem>.of(_items);
    if (!before.any((i) => i.checked)) return;
    unawaited(AppHaptics.heavy());
    _commit([for (final i in _items) i.copyWith(checked: false)]);
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
    final isTr = l10n.localeName.startsWith('tr');
    final spec = kSmartKindSpecs[SmartListKind.packing]!;
    final pLex = packingLexicon(l10n.localeName);

    final items = [
      for (final i in _items)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    final packedCount = items.where((i) => i.checked).length;
    final visible = [
      for (final i in items)
        if (_bagFilter == 'all' ||
            PackingItemMeta.fromItem(i).bag == _bagFilter)
          i,
    ];

    // Gruplara göre dizilim
    final byGroup = <int, List<NoteItem>>{};
    for (final it in visible) {
      final g = pLex.groupOf(it.text);
      final idx = g >= kPackingGroupBase ? g - kPackingGroupBase : -1;
      (byGroup[idx] ??= []).add(it);
    }
    final orderedGroups = byGroup.keys.toList()
      ..sort((a, b) => (a < 0 ? 999 : a).compareTo(b < 0 ? 999 : b));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.trim().isEmpty ? l10n.smartListPacking : widget.title,
        ),
        actions: [
          IconButton(
            key: const ValueKey('packing-wizard-btn'),
            tooltip: l10n.smartListTripWizard,
            icon: const Icon(Icons.auto_fix_high_outlined),
            onPressed: _openTripWizard,
          ),
          IconButton(
            key: const ValueKey('packing-reset-btn'),
            tooltip: l10n.packingReset,
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetAll,
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
                          '$packedCount / ${items.length}',
                          key: const ValueKey('packing-summary-count'),
                          style: text.rowTitle,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        key: const ValueKey('packing-wizard-pill'),
                        onPressed: _openTripWizard,
                        icon: const Icon(
                          Icons.auto_awesome_outlined,
                          size: AppIconSize.xs,
                        ),
                        label: Text(l10n.smartListTripWizard),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.hair),
                    child: LinearProgressIndicator(
                      value: items.isEmpty ? 0 : packedCount / items.length,
                      minHeight: AppSpace.xs,
                    ),
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
                  ('checked', l10n.packingBagChecked),
                  ('cabin', l10n.packingBagCabin),
                  ('wear', l10n.packingBagWear),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.s),
                    child: ChoiceChip(
                      key: ValueKey('packing-bag-${f.$1}'),
                      label: Text(f.$2),
                      selected: _bagFilter == f.$1,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _bagFilter = f.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? WorkspaceEmptyPacks(
                    kind: SmartListKind.packing,
                    onApplyPack: _applyPack,
                    onWizard: _openTripWizard,
                    wizardLabel: l10n.smartListTripWizard,
                    wizardIcon: Icons.luggage_outlined,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.l,
                      AppSpace.s,
                      AppSpace.l,
                      AppSpace.l,
                    ),
                    children: [
                      for (final gIdx in orderedGroups) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpace.s,
                            bottom: AppSpace.xs,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                gIdx >= 0 && gIdx < spec.groups.length
                                    ? spec.groups[gIdx].icon
                                    : Icons.category_outlined,
                                size: AppIconSize.xs,
                                color: gIdx >= 0 && gIdx < spec.groups.length
                                    ? spec.groups[gIdx].color
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                gIdx >= 0 && gIdx < spec.groups.length
                                    ? spec.groups[gIdx].label(isTr: isTr)
                                    : l10n.expenseCatOther,
                                style: text.section,
                              ),
                            ],
                          ),
                        ),
                        for (final item in byGroup[gIdx]!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.xs),
                            child: _PackingRow(
                              item: item,
                              bagLabel: _bagLabel(
                                PackingItemMeta.fromItem(item).bag,
                                l10n,
                              ),
                              onToggle: () => _toggle(item),
                              onCycleBag: () => _cycleBag(item),
                              onStepQty: (d) => _stepQty(item, d),
                            ),
                          ),
                      ],
                    ],
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
                      key: const ValueKey('packing-add-field'),
                      controller: _addCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _addItem,
                      decoration: InputDecoration(
                        hintText: l10n.packingAddHint,
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
                    onPressed: () => _addItem(_addCtrl.text),
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

  String _bagLabel(String bag, AppLocalizations l10n) => switch (bag) {
    'cabin' => l10n.packingBagCabin,
    'wear' => l10n.packingBagWear,
    _ => l10n.packingBagChecked,
  };
}

class _PackingRow extends StatelessWidget {
  const _PackingRow({
    required this.item,
    required this.bagLabel,
    required this.onToggle,
    required this.onCycleBag,
    required this.onStepQty,
  });

  final NoteItem item;
  final String bagLabel;
  final VoidCallback onToggle;
  final VoidCallback onCycleBag;
  final ValueChanged<int> onStepQty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: tokens.hairline),
      ),
      child: Row(
        children: [
          Checkbox(
            key: ValueKey('packing-check-${item.id}'),
            value: item.checked,
            onChanged: (_) => onToggle(),
          ),
          Expanded(
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
                child: Text(
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
              ),
            ),
          ),
          InkWell(
            key: ValueKey('packing-bag-pill-${item.id}'),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onCycleBag,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: tokens.resolvedTintSoft(scheme),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                bagLabel,
                style: text.badge.copyWith(color: scheme.primary),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('packing-minus-${item.id}'),
            onPressed: () => onStepQty(-1),
            icon: const Icon(Icons.remove_circle_outline, size: AppIconSize.xs),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            key: ValueKey('packing-plus-${item.id}'),
            onPressed: () => onStepQty(1),
            icon: const Icon(Icons.add_circle_outline, size: AppIconSize.xs),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
