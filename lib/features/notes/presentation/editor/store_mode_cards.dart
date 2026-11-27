part of 'store_mode_screen.dart';

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.item,
    required this.aisleIndex,
    required this.memory,
    required this.activeStore,
    required this.isShopping,
    required this.onToggle,
    required this.onToggleUnavailable,
    required this.onEditPrice,
    required this.onStepQty,
  });

  final NoteItem item;
  final int aisleIndex;
  final ShopMemory memory;
  final String activeStore;
  final bool isShopping;
  final VoidCallback onToggle;
  final VoidCallback onToggleUnavailable;
  final VoidCallback onEditPrice;
  final ValueChanged<bool> onStepQty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);

    final meta = ShopItemMeta.fromItem(item);
    final checked = item.checked;
    final unavailable = meta.isUnavailable;

    final histEntry = memory.lastPrice(
      item.text,
      store: meta.store.isNotEmpty
          ? meta.store
          : (activeStore.isEmpty ? null : activeStore),
    );
    final displayPrice = meta.unitPrice ?? histEntry?.price;
    final isEstimated = meta.unitPrice == null && histEntry != null;
    final qtyLabel = formatShopQty(meta.qty, meta.unit);

    final baseName = quickBaseName(item.text);

    return Dismissible(
      key: ValueKey('store-dismiss-${item.id}'),
      direction: isShopping
          ? DismissDirection.horizontal
          : DismissDirection.none,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onEditPrice();
        } else if (dir == DismissDirection.endToStart) {
          onToggleUnavailable();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Icon(
          Icons.payments_outlined,
          color: scheme.onPrimaryContainer,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.xs,
          children: [
            Text(
              l10n.shopStatusUnavailable,
              style: text.label.copyWith(color: scheme.onSecondaryContainer),
            ),
            Icon(
              Icons.hourglass_empty_rounded,
              color: scheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
      child: Material(
        key: ValueKey('store-item-${item.id}'),
        color: checked
            ? scheme.surfaceContainerLow
            : unavailable
            ? scheme.secondaryContainer.withValues(alpha: AppAlpha.soft)
            : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(
            color: checked
                ? scheme.outlineVariant.withValues(alpha: AppAlpha.soft)
                : unavailable
                ? scheme.secondary.withValues(alpha: AppAlpha.soft)
                : scheme.primary.withValues(alpha: AppAlpha.soft),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.m,
              vertical: AppSpace.m,
            ),
            child: Row(
              spacing: AppSpace.s,
              children: [
                Icon(
                  checked
                      ? Icons.check_circle_rounded
                      : unavailable
                      ? Icons.hourglass_bottom_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: AppIconSize.l,
                  color: checked
                      ? scheme.primary
                      : unavailable
                      ? scheme.secondary
                      : scheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpace.xxs,
                    children: [
                      Text(
                        item.text.trim(),
                        style: text.sheetTitle.copyWith(
                          color: checked
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (isShopping &&
                          (displayPrice != null ||
                              meta.store.isNotEmpty ||
                              unavailable ||
                              meta.takenBy.isNotEmpty))
                        Wrap(
                          spacing: AppSpace.s,
                          runSpacing: AppSpace.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (unavailable)
                              Text(
                                l10n.shopStatusUnavailableBadge,
                                style: text.badge.copyWith(
                                  color: scheme.secondary,
                                ),
                              ),
                            if (displayPrice != null)
                              InkWell(
                                key: ValueKey('store-price-${item.id}'),
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                                onTap: onEditPrice,
                                child: Text(
                                  isEstimated
                                      ? l10n.shopEstimatedPrefix(
                                          ShopBudgetBar.formatTl(displayPrice),
                                        )
                                      : l10n.shopActualPrice(
                                          ShopBudgetBar.formatTl(displayPrice),
                                        ),
                                  style: text.meta.copyWith(
                                    color: isEstimated
                                        ? scheme.onSurfaceVariant
                                        : scheme.primary,
                                    fontWeight: isEstimated
                                        ? AppWeight.regular
                                        : AppWeight.strong,
                                  ),
                                ),
                              ),
                            if (meta.store.isNotEmpty)
                              Text(
                                shopStoreLabel(meta.store),
                                style: text.badge.copyWith(
                                  color: scheme.secondary,
                                ),
                              ),
                            if (meta.takenBy.isNotEmpty && checked)
                              Text(
                                l10n.shopTakenBy(meta.takenBy),
                                style: text.badge.copyWith(
                                  color: scheme.primary,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isShopping && !checked) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: ValueKey('store-qty-minus-${item.id}'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        tooltip: baseName,
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          size: AppIconSize.m,
                        ),
                        onPressed: () => onStepQty(false),
                      ),
                      if (qtyLabel.isNotEmpty)
                        Text(qtyLabel, style: text.label),
                      IconButton(
                        key: ValueKey('store-qty-plus-${item.id}'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        tooltip: baseName,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: AppIconSize.m,
                        ),
                        onPressed: () => onStepQty(true),
                      ),
                    ],
                  ),
                  IconButton(
                    key: ValueKey('store-price-btn-${item.id}'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    tooltip: l10n.shopUnitPriceLabel,
                    icon: Icon(
                      displayPrice != null
                          ? Icons.sell_rounded
                          : Icons.sell_outlined,
                      size: AppIconSize.s,
                      color: displayPrice != null
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    onPressed: onEditPrice,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnknownBarcodeSheet extends StatefulWidget {
  const _UnknownBarcodeSheet({required this.ean});

  final String ean;

  @override
  State<_UnknownBarcodeSheet> createState() => _UnknownBarcodeSheetState();
}

class _UnknownBarcodeSheetState extends State<_UnknownBarcodeSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focusAfterRouteOpens(this, _focus);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetInsetPadding(
      extra: AppSpace.l,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.shopBarcodeUnknownPrompt(widget.ean)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
            child: Row(
              spacing: AppSpace.s,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: l10n.shopBarcodeNameHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.m),
                      ),
                    ),
                  ),
                ),
                FilledButton(onPressed: _save, child: Text(l10n.eventSave)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
