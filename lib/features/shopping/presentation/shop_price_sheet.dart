import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/quick_entry.dart';
import '../data/shop_memory.dart';
import '../domain/shop_aisles.dart';
import '../domain/shop_item_meta.dart';
import 'shop_budget_bar.dart';

@immutable
class ShopPriceSheetResult {
  const ShopPriceSheetResult({
    this.price,
    required this.store,
    required this.aisle,
  });

  final double? price;
  final String store;
  final int aisle;
}

/// Sağ kaydırma veya fiyat etiketine dokununca açılan hızlı fiyat, market ve
/// reyon düzenleme levhası (+ marketler arası son fiyat kıyaslaması).
Future<ShopPriceSheetResult?> showShopPriceSheet(
  BuildContext context, {
  required NoteItem item,
  required int currentAisle,
  required ShopMemory memory,
  String? activeStore,
}) => showAppSheet<ShopPriceSheetResult>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ShopPriceSheet(
    item: item,
    currentAisle: currentAisle,
    memory: memory,
    activeStore: activeStore ?? '',
  ),
);

class _ShopPriceSheet extends StatefulWidget {
  const _ShopPriceSheet({
    required this.item,
    required this.currentAisle,
    required this.memory,
    required this.activeStore,
  });

  final NoteItem item;
  final int currentAisle;
  final ShopMemory memory;
  final String activeStore;

  @override
  State<_ShopPriceSheet> createState() => _ShopPriceSheetState();
}

class _ShopPriceSheetState extends State<_ShopPriceSheet> {
  late final ShopItemMeta _meta = ShopItemMeta.fromItem(widget.item);
  late final TextEditingController _priceCtrl;
  final _focus = FocusNode();
  late String _store = _meta.store.isNotEmpty
      ? _meta.store
      : widget.activeStore;
  late int _aisle = widget.currentAisle;

  @override
  void initState() {
    super.initState();
    final initialPrice =
        _meta.unitPrice ??
        widget.memory.lastPrice(widget.item.text, store: _store)?.price;
    _priceCtrl = TextEditingController(
      text: initialPrice != null && initialPrice > 0
          ? ShopBudgetBar.formatTl(initialPrice)
          : '',
    );
    focusAfterRouteOpens(this, _focus);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));
    Navigator.pop(
      context,
      ShopPriceSheetResult(
        price: parsed != null && parsed > 0 ? parsed : null,
        store: _store,
        aisle: _aisle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final isTr = l10n.localeName.startsWith('tr');
    final baseName = quickBaseName(widget.item.text);
    final comparisons = widget.memory.storeComparisons(widget.item.text);

    return SheetInsetPadding(
      extra: AppSpace.l,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: l10n.shopPriceTitle(baseName),
              actions: [
                if (_meta.unitPrice != null)
                  TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      ShopPriceSheetResult(store: _store, aisle: _aisle),
                    ),
                    child: Text(l10n.shopClearPrice),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.m,
                children: [
                  TextField(
                    key: const ValueKey('shop-price-input'),
                    controller: _priceCtrl,
                    focusNode: _focus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: l10n.shopUnitPriceLabel,
                      suffixText: '₺',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.m),
                      ),
                    ),
                  ),
                  if (comparisons.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpace.s),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.m),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.xs,
                        children: [
                          Text(l10n.shopPriceCompareHeader, style: text.meta),
                          Wrap(
                            spacing: AppSpace.s,
                            runSpacing: AppSpace.xs,
                            children: [
                              for (final c in comparisons)
                                Chip(
                                  key: ValueKey('shop-compare-${c.store}'),
                                  label: Text(
                                    '${shopStoreLabel(c.store)}: ${ShopBudgetBar.formatTl(c.price)} ₺',
                                    style: text.label,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  SectionLabel(l10n.shopStoreLabel),
                  Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.xs,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.shopAllStores),
                        selected: _store.isEmpty,
                        onSelected: (_) => setState(() => _store = ''),
                      ),
                      for (final s in kDefaultShopStores)
                        ChoiceChip(
                          key: ValueKey('shop-price-store-${s.id}'),
                          label: Text(s.label),
                          selected: _store == s.id,
                          onSelected: (_) => setState(() => _store = s.id),
                        ),
                    ],
                  ),
                  SectionLabel(l10n.shopAisleLabel),
                  Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.xs,
                    children: [
                      for (final a in kShopAisles)
                        ChoiceChip(
                          key: ValueKey('shop-price-aisle-${a.index}'),
                          avatar: Icon(
                            a.icon,
                            size: AppIconSize.xs,
                            color: a.color,
                          ),
                          label: Text(a.label(isTr: isTr)),
                          selected: _aisle == a.index,
                          onSelected: (_) => setState(() => _aisle = a.index),
                        ),
                    ],
                  ),
                  FilledButton(
                    key: const ValueKey('shop-price-save'),
                    onPressed: _save,
                    child: Text(l10n.eventSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
