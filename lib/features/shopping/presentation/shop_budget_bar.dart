import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';

/// Mağaza Kipi üst canlı Sepet / Tahmini Toplam / Bütçe çubuğu.
class ShopBudgetBar extends StatelessWidget {
  const ShopBudgetBar({
    super.key,
    required this.cartTotal,
    required this.estimatedTotal,
    this.budgetLimit,
    required this.onEditBudget,
  });

  final double cartTotal;
  final double estimatedTotal;
  final double? budgetLimit;
  final ValueChanged<double?> onEditBudget;

  static String formatTl(double v) {
    final rounded = v.roundToDouble();
    if ((v - rounded).abs() < 0.05) return '${rounded.round()}';
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);

    final hasPrices =
        cartTotal > 0 || estimatedTotal > 0 || budgetLimit != null;
    if (!hasPrices) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          0,
          AppSpace.l,
          AppSpace.xs,
        ),
        child: Row(
          children: [
            ActionChip(
              key: const ValueKey('shop-budget-chip'),
              avatar: Icon(
                Icons.account_balance_wallet_outlined,
                size: AppIconSize.xs,
                color: scheme.primary,
              ),
              label: Text(l10n.shopBudgetSet, style: text.label),
              onPressed: () => _openBudgetSheet(context),
            ),
          ],
        ),
      );
    }

    final limit = budgetLimit;
    final overBudget = limit != null && limit > 0 && estimatedTotal > limit;
    final nearBudget =
        limit != null &&
        limit > 0 &&
        !overBudget &&
        estimatedTotal >= limit * 0.85;
    final barColor = overBudget
        ? scheme.error
        : nearBudget
        ? scheme.tertiary
        : scheme.primary;
    final ratio = limit != null && limit > 0
        ? (cartTotal / limit).clamp(0.0, 1.0)
        : (estimatedTotal > 0
              ? (cartTotal / estimatedTotal).clamp(0.0, 1.0)
              : 0.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.xs,
        AppSpace.l,
        AppSpace.xs,
      ),
      child: InkWell(
        key: const ValueKey('shop-budget-bar'),
        borderRadius: BorderRadius.circular(AppRadius.m),
        onTap: () => _openBudgetSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.s,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: overBudget
                  ? scheme.error.withValues(alpha: AppAlpha.soft)
                  : scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.xs,
            children: [
              Wrap(
                spacing: AppSpace.m,
                runSpacing: AppSpace.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.shopBudgetCart(formatTl(cartTotal)),
                    key: const ValueKey('shop-budget-cart-text'),
                    style: text.label.copyWith(
                      color: scheme.primary,
                      fontWeight: AppWeight.strong,
                    ),
                  ),
                  Text(
                    l10n.shopBudgetEstimated(formatTl(estimatedTotal)),
                    key: const ValueKey('shop-budget-est-text'),
                    style: text.meta,
                  ),
                  Text(
                    limit != null && limit > 0
                        ? l10n.shopBudgetLimit(formatTl(limit))
                        : l10n.shopBudgetSet,
                    key: const ValueKey('shop-budget-limit-text'),
                    style: text.meta.copyWith(
                      color: overBudget
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                      fontWeight: overBudget
                          ? AppWeight.strong
                          : AppWeight.regular,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.hair),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: AppSpace.xs,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: barColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBudgetSheet(BuildContext context) async {
    final result = await showAppSheet<({bool cleared, double? value})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BudgetEditSheet(initial: budgetLimit),
    );
    if (result == null) return;
    onEditBudget(result.cleared ? null : result.value);
  }
}

class _BudgetEditSheet extends StatefulWidget {
  const _BudgetEditSheet({this.initial});

  final double? initial;

  @override
  State<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends State<_BudgetEditSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initial != null && widget.initial! > 0
        ? ShopBudgetBar.formatTl(widget.initial!)
        : '',
  );
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
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    Navigator.pop(context, (cleared: v == null || v <= 0, value: v));
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
          SheetHeader(
            title: l10n.shopBudgetSet,
            actions: [
              if (widget.initial != null && widget.initial! > 0)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, (cleared: true, value: null)),
                  child: Text(l10n.delete),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
            child: Row(
              spacing: AppSpace.s,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('shop-budget-input'),
                    controller: _ctrl,
                    focusNode: _focus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: l10n.shopBudgetHint,
                      suffixText: '₺',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.m),
                      ),
                    ),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('shop-budget-save'),
                  onPressed: _save,
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
