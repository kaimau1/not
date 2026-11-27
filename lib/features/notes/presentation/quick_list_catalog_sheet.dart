import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/search_fold.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../smart_lists/presentation/smart_wizards.dart';
import '../domain/quick_entry.dart';
import '../domain/smart_lexicon_v2.dart';
import '../domain/smart_list.dart';

/// Tüm 16 akıllı liste türünü ikon, renk ve yetenek özetiyle sunan seçici.
Future<SmartListKind?> showSmartKindPickerSheet(
  BuildContext context, {
  required SmartListKind current,
}) {
  return showAppSheet<SmartListKind>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) {
      final l10n = ctx.l10n;
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      final tokens = AppTokens.fromTheme(theme);
      final text = AppText.of(theme);
      final isTr = l10n.localeName.startsWith('tr');
      final entries = kSmartKindSpecs.values.toList();
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            SheetHeader(title: l10n.smartListKindSelect),
            Expanded(
              child: GridView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.xs,
                  AppSpace.l,
                  AppSpace.xl,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpace.s,
                  crossAxisSpacing: AppSpace.s,
                  childAspectRatio: 1.85,
                ),
                itemCount: entries.length + 1,
                itemBuilder: (ctx, i) {
                  final isGeneric = i == entries.length;
                  final kind = isGeneric
                      ? SmartListKind.generic
                      : entries[i].kind;
                  final icon = isGeneric
                      ? Icons.checklist_outlined
                      : entries[i].icon;
                  final accent = isGeneric
                      ? scheme.onSurfaceVariant
                      : entries[i].accent;
                  final title = isGeneric
                      ? l10n.smartListGeneric
                      : entries[i].name(isTr: isTr);
                  final desc = isGeneric
                      ? l10n.quickListEmpty
                      : entries[i].desc(isTr: isTr);
                  final selected = kind == current;
                  return Material(
                    color: selected
                        ? tokens.resolvedTintSoft(scheme)
                        : tokens.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      side: BorderSide(
                        color: selected ? scheme.primary : tokens.hairline,
                      ),
                    ),
                    child: InkWell(
                      key: ValueKey('smart-kind-option-${kind.name}'),
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      onTap: () {
                        unawaited(AppHaptics.tick());
                        Navigator.pop(ctx, kind);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(icon, size: AppIconSize.m, color: accent),
                                const SizedBox(width: AppSpace.s),
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.label.copyWith(
                                      fontWeight: AppWeight.strong,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.badge.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: AppWeight.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Aranabilir madde kataloğu, hazır başlangıç paketleri ve sihirbazlar levhası.
Future<void> showQuickListCatalogSheet(
  BuildContext context, {
  required SmartListKind kind,
  required bool Function(String text) hasItem,
  required ValueChanged<List<({String text, Map<String, dynamic> extras})>>
  onAddItems,
  ValueChanged<String>? onRemoveItem,
}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _QuickListCatalogSheet(
      kind: kind,
      hasItem: hasItem,
      onAddItems: onAddItems,
      onRemoveItem: onRemoveItem,
    ),
  );
}

class _QuickListCatalogSheet extends StatefulWidget {
  const _QuickListCatalogSheet({
    required this.kind,
    required this.hasItem,
    required this.onAddItems,
    this.onRemoveItem,
  });

  final SmartListKind kind;
  final bool Function(String text) hasItem;
  final ValueChanged<List<({String text, Map<String, dynamic> extras})>>
  onAddItems;
  final ValueChanged<String>? onRemoveItem;

  @override
  State<_QuickListCatalogSheet> createState() => _QuickListCatalogSheetState();
}

class _QuickListCatalogSheetState extends State<_QuickListCatalogSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyPack(SmartStarterPack pack, bool isTr) {
    unawaited(AppHaptics.thud());
    final items = pack.items(isTr: isTr);
    widget.onAddItems([
      for (var i = 0; i < items.length; i++)
        (
          text: items[i],
          extras: pack.extrasByIndex[i] == null
              ? const <String, dynamic>{}
              : Map<String, dynamic>.from(pack.extrasByIndex[i]!),
        ),
    ]);
    setState(() {});
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showMessage(context.l10n.smartListPackAdded(pack.name(isTr: isTr)));
  }

  Future<void> _openWizard() async {
    final List<({String text, Map<String, dynamic> extras})>? generated;
    if (widget.kind == SmartListKind.packing) {
      generated = await showTripPackingWizardSheet(context);
    } else if (widget.kind == SmartListKind.event) {
      generated = await showEventWizardSheet(context);
    } else {
      return;
    }
    if (generated == null || !mounted) return;
    widget.onAddItems(generated);
    setState(() {});
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
    final specs = spec != null ? [spec] : kSmartKindSpecs.values.toList();
    final packs = [for (final s in specs) ...s.starterPacks];
    final groups = [for (final s in specs) ...s.groups];
    final q = foldForSearch(_query.trim());

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (ctx, scrollCtrl) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: spec?.name(isTr: isTr) ?? l10n.smartListCatalog,
            actions: [
              if (widget.kind == SmartListKind.packing ||
                  widget.kind == SmartListKind.event)
                TextButton.icon(
                  key: const ValueKey('catalog-wizard-btn'),
                  onPressed: _openWizard,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: Text(
                    widget.kind == SmartListKind.packing
                        ? l10n.smartListTripWizard
                        : l10n.smartListEventWizard,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
            child: TextField(
              key: const ValueKey('catalog-search-field'),
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l10n.smartListSearchCatalog,
                isDense: true,
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.m),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.xl,
              ),
              children: [
                if (q.isEmpty && packs.isNotEmpty) ...[
                  Text(l10n.smartListStarterPacks, style: text.section),
                  const SizedBox(height: AppSpace.s),
                  SizedBox(
                    height: AppSpace.xxxl + AppSpace.xxxl + AppSpace.xl,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: packs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpace.s),
                      itemBuilder: (ctx, i) {
                        final p = packs[i];
                        return SizedBox(
                          width: 210,
                          child: Material(
                            color: tokens.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              side: BorderSide(color: tokens.hairline),
                            ),
                            child: InkWell(
                              key: ValueKey('catalog-pack-${p.id}'),
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              onTap: () => _applyPack(p, isTr),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpace.m),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          p.icon,
                                          size: AppIconSize.s,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(width: AppSpace.xs),
                                        Expanded(
                                          child: Text(
                                            p.name(isTr: isTr),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: text.label.copyWith(
                                              fontWeight: AppWeight.strong,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpace.xs),
                                    Text(
                                      p.desc(isTr: isTr),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.meta,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpace.l),
                ],
                for (final g in groups)
                  () {
                    final all = g.items(isTr: isTr);
                    final matchGroup =
                        q.isEmpty ||
                        foldForSearch(g.label(isTr: isTr)).contains(q);
                    final shown = matchGroup
                        ? all
                        : [
                            for (final item in all)
                              if (foldForSearch(item).contains(q)) item,
                          ];
                    if (shown.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.m),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpace.m),
                        decoration: BoxDecoration(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(AppRadius.l),
                          border: Border.all(color: tokens.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  g.icon,
                                  size: AppIconSize.s,
                                  color: g.color,
                                ),
                                const SizedBox(width: AppSpace.s),
                                Expanded(
                                  child: Text(
                                    g.label(isTr: isTr),
                                    style: text.section.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text('${shown.length}', style: text.meta),
                              ],
                            ),
                            const SizedBox(height: AppSpace.s),
                            Wrap(
                              spacing: AppSpace.s,
                              runSpacing: AppSpace.xs,
                              children: [
                                for (final item in shown.take(40))
                                  () {
                                    final added = widget.hasItem(item);
                                    return FilterChip(
                                      key: ValueKey('catalog-item-$item'),
                                      label: Text(item),
                                      selected: added,
                                      onSelected: (_) {
                                        unawaited(AppHaptics.tick());
                                        if (added &&
                                            widget.onRemoveItem != null) {
                                          widget.onRemoveItem!(item);
                                        } else if (!added) {
                                          widget.onAddItems([
                                            (
                                              text: item,
                                              extras: const <String, dynamic>{},
                                            ),
                                          ]);
                                        }
                                        setState(() {});
                                      },
                                    );
                                  }(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hızlı listedeki bir satıra dokunulunca açılan kompakt madde düzenleyici.
Future<({bool remove, String name, String qty})?> showQuickItemEditSheet(
  BuildContext context, {
  required String name,
  required String qty,
}) {
  return showAppSheet<({bool remove, String name, String qty})>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _QuickItemEditSheet(name: name, qty: qty),
  );
}

class _QuickItemEditSheet extends StatefulWidget {
  const _QuickItemEditSheet({required this.name, required this.qty});

  final String name;
  final String qty;

  @override
  State<_QuickItemEditSheet> createState() => _QuickItemEditSheetState();
}

class _QuickItemEditSheetState extends State<_QuickItemEditSheet> {
  late final _nameCtrl = TextEditingController(text: widget.name);
  late final _qtyCtrl = TextEditingController(text: widget.qty);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focusAfterRouteOpens(this, _focus);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final parsed = parseQuickQty(_qtyCtrl.text.trim());
    final cur = parsed?.value ?? 1.0;
    final unit = parsed?.rawUnit ?? '';
    final next = (cur + delta).clamp(1.0, 999.0);
    final n = formatQuickNumber(next);
    _qtyCtrl.text = unit.isEmpty ? n : '$n $unit';
  }

  void _applyUnit(String unit) {
    final parsed = parseQuickQty(_qtyCtrl.text.trim());
    final val = parsed?.value ?? 1.0;
    final n = formatQuickNumber(val);
    _qtyCtrl.text = '$n $unit';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isTr = l10n.localeName.startsWith('tr');
    final units = isTr
        ? const ['adet', 'kg', 'g', 'lt', 'paket']
        : const ['pcs', 'kg', 'g', 'lt', 'pack'];
    return SheetInsetPadding(
      extra: AppSpace.l,
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
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () =>
                    Navigator.pop(context, (remove: true, name: '', qty: '')),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameCtrl,
                  focusNode: _focus,
                  textCapitalization: TextCapitalization.sentences,
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
                    IconButton(
                      onPressed: () => _step(-1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _qtyCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.smartListItemQty,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _step(1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s),
                Wrap(
                  spacing: AppSpace.xs,
                  children: [
                    for (final u in units)
                      ActionChip(
                        label: Text(u),
                        onPressed: () => _applyUnit(u),
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
                  onPressed: () => Navigator.pop(context, (
                    remove: false,
                    name: _nameCtrl.text.trim(),
                    qty: _qtyCtrl.text.trim(),
                  )),
                  child: Text(l10n.eventSave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
