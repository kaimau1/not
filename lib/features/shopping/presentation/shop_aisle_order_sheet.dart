import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../domain/shop_aisles.dart';

/// Seçili marketin (BİM, Migros vb.) yürüyüş reyon sırasını sürükle-bırak ile
/// özelleştirme levhası.
Future<List<int>?> showShopAisleOrderSheet(
  BuildContext context, {
  required String storeLabel,
  required List<int> currentOrder,
}) => showAppSheet<List<int>>(
  context: context,
  isScrollControlled: true,
  builder: (_) =>
      _ShopAisleOrderSheet(storeLabel: storeLabel, currentOrder: currentOrder),
);

class _ShopAisleOrderSheet extends StatefulWidget {
  const _ShopAisleOrderSheet({
    required this.storeLabel,
    required this.currentOrder,
  });

  final String storeLabel;
  final List<int> currentOrder;

  @override
  State<_ShopAisleOrderSheet> createState() => _ShopAisleOrderSheetState();
}

class _ShopAisleOrderSheetState extends State<_ShopAisleOrderSheet> {
  late List<int> _order = List<int>.of(widget.currentOrder);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = AppText.of(theme);
    final isTr = l10n.localeName.startsWith('tr');

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: l10n.shopAisleOrderTitle(widget.storeLabel),
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  _order = [for (final a in kShopAisles) a.index];
                }),
                child: Text(l10n.shopResetOrder),
              ),
            ],
          ),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: _order.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final moved = _order.removeAt(oldIndex);
                  _order.insert(newIndex, moved);
                });
              },
              itemBuilder: (_, i) {
                final meta = shopAisleMetaOfIndex(_order[i]);
                return ListTile(
                  key: ValueKey('aisle-order-${meta.index}'),
                  leading: Icon(meta.icon, color: meta.color),
                  title: Text(meta.label(isTr: isTr), style: text.rowTitle),
                  trailing: const Icon(Icons.drag_handle_rounded),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.l,
            ),
            child: FilledButton(
              key: const ValueKey('shop-aisle-order-save'),
              onPressed: () => Navigator.pop(context, _order),
              child: Text(l10n.eventSave),
            ),
          ),
        ],
      ),
    );
  }
}
