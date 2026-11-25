import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';

/// Bring! tarzı "Bitmiş Olabilir" 1-dokunuşlu öneri şeridi (`predictDue` verisi).
class ShopDueStrip extends StatelessWidget {
  const ShopDueStrip({
    super.key,
    required this.dueItems,
    required this.onAddDue,
    required this.onDismissDue,
  });

  final List<({String name, int avgDays, int daysSince})> dueItems;
  final ValueChanged<String> onAddDue;
  final ValueChanged<String> onDismissDue;

  @override
  Widget build(BuildContext context) {
    if (dueItems.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.xs,
        AppSpace.l,
        AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.xs,
        children: [
          Text(l10n.shopDueHeader, style: text.meta),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dueItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s),
              itemBuilder: (_, i) {
                final d = dueItems[i];
                return InputChip(
                  key: ValueKey('shop-due-${d.name}'),
                  avatar: Icon(
                    Icons.add_circle_outline_rounded,
                    size: AppIconSize.xs,
                    color: scheme.primary,
                  ),
                  label: Text(
                    '${d.name} (${l10n.shopDueEveryDays(d.avgDays)})',
                    style: text.label,
                  ),
                  onPressed: () => onAddDue(d.name),
                  onDeleted: () => onDismissDue(d.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
