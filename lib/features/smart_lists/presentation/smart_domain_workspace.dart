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
import '../../notes/domain/quick_entry.dart';
import '../../notes/domain/smart_lexicon_v2.dart';
import '../../notes/domain/smart_list.dart';
import '../../shopping/presentation/shop_budget_bar.dart';
import '../domain/smart_item_meta.dart';
import 'smart_wizards.dart';

/// Temizlik, Hediye, İzlenecekler, Bütçe, Etkinlik, Eczane, Kırtasiye,
/// Tamirat, Kamp, Bebek ve Spor için türe özel etkileşimli çalışma alanı.
class SmartDomainWorkspace extends StatefulWidget {
  const SmartDomainWorkspace({
    super.key,
    required this.kind,
    required this.title,
    required this.initialItems,
    required this.onReplaceItems,
    this.liveItems,
  });

  final SmartListKind kind;
  final String title;
  final List<NoteItem> initialItems;
  final List<NoteItem> Function(List<NoteItem> updated) onReplaceItems;
  final ValueListenable<List<NoteItem>>? liveItems;

  @override
  State<SmartDomainWorkspace> createState() => _SmartDomainWorkspaceState();
}

class _SmartDomainWorkspaceState extends State<SmartDomainWorkspace> {
  late List<NoteItem> _items = List<NoteItem>.of(
    widget.liveItems?.value ?? widget.initialItems,
  );
  String _filter = 'all';
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
  void didUpdateWidget(covariant SmartDomainWorkspace oldWidget) {
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

  void _toggleCheck(NoteItem item) {
    unawaited(AppHaptics.tick());
    var nextItem = item.copyWith(checked: !item.checked);
    if (widget.kind == SmartListKind.gifts) {
      final m = GiftItemMeta.fromItem(item);
      final nextStage = !item.checked ? 'bought' : 'idea';
      nextItem = m.copyWith(stage: nextStage).applyToItem(item);
    } else if (widget.kind == SmartListKind.watchlist) {
      final m = WatchlistItemMeta.fromItem(item);
      final nextStatus = !item.checked ? 'done' : 'queued';
      nextItem = m.copyWith(status: nextStatus).applyToItem(item);
    }
    _commit([
      for (final it in _items)
        if (it.id == item.id) nextItem else it,
    ]);
  }

  void _addItem(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return;
    unawaited(AppHaptics.tick());
    NoteItem item;
    if (widget.kind == SmartListKind.expense) {
      final parsed = parseExpenseQuickInput(clean);
      final cat = _filter != 'all' ? _filter : 'other';
      item = ExpenseItemMeta(
        amount: parsed.amount,
        category: cat,
      ).applyToItem(NoteItem(id: const Uuid().v4(), text: parsed.title));
    } else if (widget.kind == SmartListKind.gifts) {
      final priced = extractInlinePrice(clean);
      item = GiftItemMeta(price: priced.price).applyToItem(
        NoteItem(id: const Uuid().v4(), text: quickCapitalize(priced.text)),
      );
    } else if (widget.kind == SmartListKind.watchlist) {
      final t = _filter != 'all' && WatchlistItemMeta.types.contains(_filter)
          ? _filter
          : 'movie';
      item = WatchlistItemMeta(mediaType: t).applyToItem(
        NoteItem(id: const Uuid().v4(), text: quickCapitalize(clean)),
      );
    } else if (widget.kind == SmartListKind.cleaning) {
      final room = _filter != 'all' && CleaningItemMeta.rooms.contains(_filter)
          ? _filter
          : 'general';
      final freq = _filter != 'all' && CleaningItemMeta.freqs.contains(_filter)
          ? _filter
          : 'weekly';
      item = CleaningItemMeta(room: room, freq: freq).applyToItem(
        NoteItem(id: const Uuid().v4(), text: quickCapitalize(clean)),
      );
    } else {
      item = NoteItem(id: const Uuid().v4(), text: quickCapitalize(clean));
    }
    _commit([..._items, item]);
    _addCtrl.clear();
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

  Future<void> _openEventWizard() async {
    final generated = await showEventWizardSheet(context);
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

  Future<void> _addStarterPack() async {
    final isTr = context.l10n.localeName.startsWith('tr');
    final spec = kSmartKindSpecs[widget.kind];
    if (spec == null || spec.starterPacks.isEmpty) return;
    final pack = spec.starterPacks.first;
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

  Future<void> _editDomainItem(NoteItem item) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: item.text);
    final extraCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    var optA = '';
    var optB = '';
    var rating = 0;

    if (widget.kind == SmartListKind.gifts) {
      final m = GiftItemMeta.fromItem(item);
      extraCtrl.text = m.recipient;
      if (m.price != null) priceCtrl.text = ShopBudgetBar.formatTl(m.price!);
      optA = m.stage;
    } else if (widget.kind == SmartListKind.watchlist) {
      final m = WatchlistItemMeta.fromItem(item);
      extraCtrl.text = m.platform;
      optA = m.mediaType;
      optB = m.status;
      rating = m.rating;
    } else if (widget.kind == SmartListKind.expense) {
      final m = ExpenseItemMeta.fromItem(item);
      if (m.amount != null) priceCtrl.text = ShopBudgetBar.formatTl(m.amount!);
      optA = m.category;
    } else if (widget.kind == SmartListKind.cleaning) {
      final m = CleaningItemMeta.fromItem(item);
      optA = m.room;
      optB = m.freq;
    }

    final res = await showAppSheet<({bool delete, NoteItem? updated})>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SheetInsetPadding(
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
                      if (widget.kind == SmartListKind.gifts) ...[
                        const SizedBox(height: AppSpace.m),
                        TextField(
                          controller: extraCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.giftRecipient,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.m),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.giftPrice,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.m),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final s in GiftItemMeta.stages)
                              ChoiceChip(
                                label: Text(_giftStageLabel(s, l10n)),
                                selected: optA == s,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => optA = s),
                              ),
                          ],
                        ),
                      ] else if (widget.kind == SmartListKind.watchlist) ...[
                        const SizedBox(height: AppSpace.m),
                        TextField(
                          controller: extraCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.watchPlatform,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.m),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final t in WatchlistItemMeta.types)
                              ChoiceChip(
                                label: Text(_watchTypeLabel(t, l10n)),
                                selected: optA == t,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => optA = t),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.s),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final st in WatchlistItemMeta.statuses)
                              ChoiceChip(
                                label: Text(_watchStatusLabel(st, l10n)),
                                selected: optB == st,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => optB = st),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.s),
                        Row(
                          children: [
                            Text(l10n.watchRating),
                            const SizedBox(width: AppSpace.s),
                            for (var star = 1; star <= 5; star++)
                              IconButton(
                                icon: Icon(
                                  star <= rating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Theme.of(ctx).colorScheme.secondary,
                                ),
                                onPressed: () => setSheet(
                                  () => rating = rating == star ? 0 : star,
                                ),
                              ),
                          ],
                        ),
                      ] else if (widget.kind == SmartListKind.expense) ...[
                        const SizedBox(height: AppSpace.m),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.expenseAmountHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.m),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final c in ExpenseItemMeta.categories)
                              ChoiceChip(
                                label: Text(_expenseCatLabel(c, l10n)),
                                selected: optA == c,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => optA = c),
                              ),
                          ],
                        ),
                      ] else if (widget.kind == SmartListKind.cleaning) ...[
                        const SizedBox(height: AppSpace.m),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final r in CleaningItemMeta.rooms)
                              ChoiceChip(
                                label: Text(_cleanRoomLabel(r, l10n)),
                                selected: optA == r,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => optA = r),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.s),
                        Wrap(
                          spacing: AppSpace.xs,
                          children: [
                            for (final f in CleaningItemMeta.freqs)
                              ChoiceChip(
                                label: Text(_cleanFreqLabel(f, l10n)),
                                selected: optB == f,
                                showCheckmark: false,
                                onSelected: (_) => setSheet(() => optB = f),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpace.l),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            kMinInteractiveDimension,
                          ),
                        ),
                        onPressed: () {
                          final cleanName = nameCtrl.text.trim();
                          final base = item.copyWith(
                            text: cleanName.isEmpty ? item.text : cleanName,
                          );
                          final parsedPrice = double.tryParse(
                            priceCtrl.text.trim().replaceAll(',', '.'),
                          );
                          final NoteItem nextItem;
                          if (widget.kind == SmartListKind.gifts) {
                            nextItem = GiftItemMeta(
                              recipient: extraCtrl.text.trim(),
                              price: parsedPrice,
                              stage: optA,
                            ).applyToItem(base);
                          } else if (widget.kind == SmartListKind.watchlist) {
                            nextItem = WatchlistItemMeta(
                              mediaType: optA,
                              status: optB,
                              rating: rating,
                              platform: extraCtrl.text.trim(),
                            ).applyToItem(base);
                          } else if (widget.kind == SmartListKind.expense) {
                            nextItem = ExpenseItemMeta(
                              amount: parsedPrice,
                              category: optA,
                            ).applyToItem(base);
                          } else if (widget.kind == SmartListKind.cleaning) {
                            nextItem = CleaningItemMeta(
                              room: optA,
                              freq: optB,
                            ).applyToItem(base);
                          } else {
                            nextItem = base;
                          }
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
        ),
      ),
    );
    nameCtrl.dispose();
    extraCtrl.dispose();
    priceCtrl.dispose();
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
    final isTr = l10n.localeName.startsWith('tr');
    final spec = kSmartKindSpecs[widget.kind];

    final items = [
      for (final i in _items)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    final doneCount = items.where((i) => i.checked).length;
    final visible = [
      for (final i in items)
        if (_matchesFilter(i)) i,
    ];

    final filters = _filterChips(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.trim().isEmpty
              ? (spec?.name(isTr: isTr) ?? l10n.smartList)
              : widget.title,
        ),
        actions: [
          if (widget.kind == SmartListKind.event)
            IconButton(
              key: const ValueKey('event-wizard-btn'),
              tooltip: l10n.smartListEventWizard,
              icon: const Icon(Icons.auto_fix_high_outlined),
              onPressed: _openEventWizard,
            ),
          if (spec != null && spec.starterPacks.isNotEmpty)
            IconButton(
              tooltip: l10n.smartListStarterPacks,
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: _addStarterPack,
            ),
          if (_supportsReset)
            IconButton(
              key: const ValueKey('domain-reset-btn'),
              tooltip: widget.kind == SmartListKind.cleaning
                  ? l10n.cleaningReset
                  : l10n.domainGearReset,
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
            child: _buildHeaderCard(
              context,
              items,
              doneCount,
              tokens,
              scheme,
              text,
              l10n,
            ),
          ),
          if (filters.isNotEmpty)
            SizedBox(
              height: AppSpace.xxxl + AppSpace.m,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                children: [
                  for (final f in filters)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.s),
                      child: ChoiceChip(
                        key: ValueKey('domain-filter-${f.$1}'),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.smartListWorkspaceEmpty,
                          style: text.body.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (spec != null && spec.starterPacks.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.m),
                          FilledButton.tonalIcon(
                            onPressed: _addStarterPack,
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: Text(l10n.smartListStarterPacks),
                          ),
                        ],
                      ],
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
                    itemBuilder: (context, idx) => _buildRow(
                      context,
                      visible[idx],
                      tokens,
                      scheme,
                      text,
                      l10n,
                    ),
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
                      key: const ValueKey('domain-add-field'),
                      controller: _addCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _addItem,
                      decoration: InputDecoration(
                        hintText: _addHint(l10n),
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

  bool get _supportsReset =>
      widget.kind == SmartListKind.cleaning ||
      widget.kind == SmartListKind.camping ||
      widget.kind == SmartListKind.baby ||
      widget.kind == SmartListKind.sport;

  Widget _buildHeaderCard(
    BuildContext context,
    List<NoteItem> items,
    int doneCount,
    AppTokens tokens,
    ColorScheme scheme,
    AppText text,
    AppLocalizations l10n,
  ) {
    String summary;
    if (widget.kind == SmartListKind.expense) {
      var total = 0.0;
      var paid = 0.0;
      for (final i in items) {
        final a = ExpenseItemMeta.fromItem(i).amount ?? 0;
        total += a;
        if (i.checked) paid += a;
      }
      summary = l10n.expenseSummaryBar(
        ShopBudgetBar.formatTl(total),
        ShopBudgetBar.formatTl(paid),
        ShopBudgetBar.formatTl((total - paid).clamp(0, double.infinity)),
      );
    } else if (widget.kind == SmartListKind.gifts) {
      var total = 0.0;
      var bought = 0.0;
      for (final i in items) {
        final m = GiftItemMeta.fromItem(i);
        final p = m.price ?? 0;
        total += p;
        if (m.stage != 'idea') bought += p;
      }
      summary = l10n.giftSummaryPlanned(
        ShopBudgetBar.formatTl(total),
        ShopBudgetBar.formatTl(bought),
      );
    } else {
      summary = '$doneCount / ${items.length}';
    }

    return Container(
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
                  summary,
                  key: const ValueKey('domain-summary-text'),
                  style: text.rowTitle,
                ),
              ),
              if (widget.kind == SmartListKind.event)
                FilledButton.tonalIcon(
                  onPressed: _openEventWizard,
                  icon: const Icon(
                    Icons.celebration_outlined,
                    size: AppIconSize.xs,
                  ),
                  label: Text(l10n.smartListEventWizard),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.hair),
            child: LinearProgressIndicator(
              value: items.isEmpty ? 0 : doneCount / items.length,
              minHeight: AppSpace.xs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    NoteItem item,
    AppTokens tokens,
    ColorScheme scheme,
    AppText text,
    AppLocalizations l10n,
  ) {
    Widget? trailing;
    String? badge;
    if (widget.kind == SmartListKind.gifts) {
      final m = GiftItemMeta.fromItem(item);
      if (m.recipient.isNotEmpty || m.price != null) {
        badge = [
          if (m.recipient.isNotEmpty) m.recipient,
          if (m.price != null) '${ShopBudgetBar.formatTl(m.price!)} ₺',
        ].join(' · ');
      }
      trailing = ActionChip(
        key: ValueKey('gift-stage-${item.id}'),
        label: Text(_giftStageLabel(m.stage, l10n)),
        onPressed: () {
          unawaited(AppHaptics.tick());
          final next = m.nextStage().applyToItem(item);
          _commit([
            for (final it in _items)
              if (it.id == item.id) next else it,
          ]);
        },
      );
    } else if (widget.kind == SmartListKind.watchlist) {
      final m = WatchlistItemMeta.fromItem(item);
      badge = [
        _watchTypeLabel(m.mediaType, l10n),
        _watchStatusLabel(m.status, l10n),
        if (m.platform.isNotEmpty) m.platform,
      ].join(' · ');
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var s = 1; s <= 5; s++)
            InkWell(
              key: ValueKey('watch-star-${item.id}-$s'),
              onTap: () {
                unawaited(AppHaptics.tick());
                final next = m
                    .copyWith(rating: m.rating == s ? 0 : s)
                    .applyToItem(item);
                _commit([
                  for (final it in _items)
                    if (it.id == item.id) next else it,
                ]);
              },
              child: Icon(
                s <= m.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: AppIconSize.s,
                color: s <= m.rating
                    ? scheme.secondary
                    : scheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    } else if (widget.kind == SmartListKind.expense) {
      final m = ExpenseItemMeta.fromItem(item);
      badge = _expenseCatLabel(m.category, l10n);
      if (m.amount != null) {
        trailing = Text(
          '${ShopBudgetBar.formatTl(m.amount!)} ₺',
          style: text.rowTitle.copyWith(color: scheme.primary),
        );
      }
    } else if (widget.kind == SmartListKind.cleaning) {
      final m = CleaningItemMeta.fromItem(item);
      badge =
          '${_cleanRoomLabel(m.room, l10n)} · ${_cleanFreqLabel(m.freq, l10n)}';
    }

    return Material(
      color: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(color: tokens.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.m),
        onTap: () => _editDomainItem(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s,
            vertical: AppSpace.xs,
          ),
          child: Row(
            children: [
              Checkbox(
                key: ValueKey('domain-check-${item.id}'),
                value: item.checked,
                onChanged: (_) => _toggleCheck(item),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (badge != null && badge.isNotEmpty)
                      Text(badge, style: text.meta),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }

  List<(String, String)> _filterChips(AppLocalizations l10n) =>
      switch (widget.kind) {
        SmartListKind.cleaning => [
          ('all', l10n.smartListAll),
          ('daily', l10n.cleaningFreqDaily),
          ('weekly', l10n.cleaningFreqWeekly),
          ('monthly', l10n.cleaningFreqMonthly),
          ('kitchen', l10n.movingRoomKitchen),
          ('bath', l10n.movingRoomBath),
        ],
        SmartListKind.gifts => [
          ('all', l10n.smartListAll),
          ('idea', l10n.giftStageIdea),
          ('bought', l10n.giftStageBought),
          ('wrapped', l10n.giftStageWrapped),
          ('given', l10n.giftStageGiven),
        ],
        SmartListKind.watchlist => [
          ('all', l10n.smartListAll),
          ('movie', l10n.watchTypeMovie),
          ('series', l10n.watchTypeSeries),
          ('book', l10n.watchTypeBook),
          ('doc', l10n.watchTypeDoc),
          ('done', l10n.watchStatusDone),
        ],
        SmartListKind.expense => [
          ('all', l10n.smartListAll),
          for (final c in ExpenseItemMeta.categories)
            (c, _expenseCatLabel(c, l10n)),
        ],
        _ => const [],
      };

  bool _matchesFilter(NoteItem item) {
    if (_filter == 'all') return true;
    return switch (widget.kind) {
      SmartListKind.cleaning => () {
        final m = CleaningItemMeta.fromItem(item);
        return m.freq == _filter || m.room == _filter;
      }(),
      SmartListKind.gifts => GiftItemMeta.fromItem(item).stage == _filter,
      SmartListKind.watchlist => () {
        final m = WatchlistItemMeta.fromItem(item);
        return m.mediaType == _filter || m.status == _filter;
      }(),
      SmartListKind.expense =>
        ExpenseItemMeta.fromItem(item).category == _filter,
      _ => true,
    };
  }

  String _addHint(AppLocalizations l10n) => switch (widget.kind) {
    SmartListKind.cleaning => l10n.cleaningAddHint,
    SmartListKind.gifts => l10n.giftAddHint,
    SmartListKind.watchlist => l10n.watchAddHint,
    SmartListKind.expense => l10n.expenseAddHint,
    _ => l10n.domainAddHint,
  };

  String _giftStageLabel(String s, AppLocalizations l10n) => switch (s) {
    'bought' => l10n.giftStageBought,
    'wrapped' => l10n.giftStageWrapped,
    'given' => l10n.giftStageGiven,
    _ => l10n.giftStageIdea,
  };

  String _watchTypeLabel(String t, AppLocalizations l10n) => switch (t) {
    'series' => l10n.watchTypeSeries,
    'book' => l10n.watchTypeBook,
    'doc' => l10n.watchTypeDoc,
    'podcast' => l10n.watchTypePodcast,
    _ => l10n.watchTypeMovie,
  };

  String _watchStatusLabel(String st, AppLocalizations l10n) => switch (st) {
    'watching' => l10n.watchStatusWatching,
    'done' => l10n.watchStatusDone,
    _ => l10n.watchStatusQueued,
  };

  String _expenseCatLabel(String c, AppLocalizations l10n) => switch (c) {
    'market' => l10n.expenseCatMarket,
    'bills' => l10n.expenseCatBills,
    'transport' => l10n.expenseCatTransport,
    'food' => l10n.expenseCatFood,
    'home' => l10n.expenseCatHome,
    'health' => l10n.expenseCatHealth,
    'fun' => l10n.expenseCatFun,
    _ => l10n.expenseCatOther,
  };

  String _cleanRoomLabel(String r, AppLocalizations l10n) => switch (r) {
    'kitchen' => l10n.movingRoomKitchen,
    'bath' => l10n.movingRoomBath,
    'living' => l10n.movingRoomLiving,
    'bedroom' => l10n.movingRoomBedroom,
    _ => l10n.movingRoomGeneral,
  };

  String _cleanFreqLabel(String f, AppLocalizations l10n) => switch (f) {
    'daily' => l10n.cleaningFreqDaily,
    'monthly' => l10n.cleaningFreqMonthly,
    _ => l10n.cleaningFreqWeekly,
  };
}
