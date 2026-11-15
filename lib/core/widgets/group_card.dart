import 'package:flutter/material.dart';

import '../../app/theme/app_design.dart';
import '../../app/theme/app_tokens.dart';

/// **GRUP KARTI** (P62 PA4, plan_tasarim_A §2.2 "yan ekranlar"): ayarlardaki
/// grup kartıyla aynı dil — `AppSurface.group` zemini, köşe [AppRadius.l],
/// satırlar arası ince ayraç. Ham `Card` + `ListTile` yığınının yerine
/// (Premium, kılavuz, kişiler, hesap gerekli ekranları).
///
/// Ayar alanları bunu KULLANMAZ: orada satırlar karelere yayılarak kurulur ve
/// tek render nesnesinde çizilir (`_GroupColumn`, settings_area.dart).
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children, this.color});

  final List<Widget> children;

  /// Zemin (yoksa `surfaceContainerLow`): durum kartı gibi vurgulu grup.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = theme.colorScheme.outlineVariant.withValues(
      alpha: AppAlpha.muted,
    );
    return DecoratedBox(
      decoration: AppSurface.group(theme).copyWith(color: color),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpace.l,
                    endIndent: AppSpace.l,
                    color: line,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
