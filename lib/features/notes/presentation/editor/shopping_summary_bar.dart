import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../shopping/domain/shop_item_meta.dart';
import '../../../shopping/presentation/shop_budget_bar.dart';
import '../../domain/note_item.dart';

/// Alışveriş kipinde notun altındaki sabit yükseklikli canlı özet çubuğu.
///
/// Yükseklik animasyonu KULLANMAZ (S17 klavye kasma koruması); klavye açıkken
/// `KeyboardSwitch` üzerinden gizlenir. Alınan/kalan sayacını ve fiyat girilmiş
/// maddeler varsa canlı toplam tutarı gösterir.
class ShoppingSummaryBar extends StatelessWidget {
  const ShoppingSummaryBar({
    super.key,
    required this.items,
    this.onFinishChecked,
    this.accentColor,
  });

  final List<NoteItem> items;
  final VoidCallback? onFinishChecked;
  final Color? accentColor;

  /// Tüm maddeler (fiyatı girilmiş olanlar) ve alınanlar için canlı toplamlar.
  static ({
    int bought,
    int remaining,
    double boughtTotal,
    double allTotal,
    bool hasPrices,
  })
  summarize(List<NoteItem> items) {
    var bought = 0;
    var remaining = 0;
    var boughtTotal = 0.0;
    var allTotal = 0.0;
    var hasPrices = false;
    for (final item in items) {
      if (item.header || item.text.trim().isEmpty) continue;
      if (item.checked) {
        bought++;
      } else {
        remaining++;
      }
      final line = shopItemLineTotal(item);
      if (line != null && line > 0) {
        hasPrices = true;
        allTotal += line;
        if (item.checked) boughtTotal += line;
      }
    }
    return (
      bought: bought,
      remaining: remaining,
      boughtTotal: boughtTotal,
      allTotal: allTotal,
      hasPrices: hasPrices,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = summarize(items);
    final total = stats.bought + stats.remaining;
    if (total == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = accentColor ?? scheme.primary;
    final currency = l10n.localeName.startsWith('tr') ? '₺' : '';

    return SizedBox(
      key: const ValueKey('shopping-summary-bar'),
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: AppAlpha.muted),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: AppIconSize.s,
                color: accent,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        l10n.shoppingBoughtCount(stats.bought, total),
                        key: const ValueKey('shopping-summary-bought'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: AppWeight.strong,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (stats.remaining > 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.xxs,
                        ),
                        child: Text(
                          '·',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          l10n.shoppingSummaryRemaining(stats.remaining),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (stats.hasPrices) ...[
                const SizedBox(width: AppSpace.xs),
                Text(
                  l10n.shoppingTotalAmount(
                    currency.isEmpty
                        ? ShopBudgetBar.formatTl(stats.allTotal)
                        : '${ShopBudgetBar.formatTl(stats.allTotal)} $currency',
                  ),
                  key: const ValueKey('shopping-summary-total'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: AppWeight.strong,
                    color: accent,
                  ),
                ),
              ],
              if (stats.bought > 0 && onFinishChecked != null) ...[
                const SizedBox(width: AppSpace.xs),
                TextButton(
                  key: const ValueKey('shopping-summary-finish'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xs,
                    ),
                    foregroundColor: accent,
                  ),
                  onPressed: onFinishChecked,
                  child: Text(
                    l10n.finishShopping,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
