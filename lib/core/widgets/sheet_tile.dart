import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../a11y/min_tap_target.dart';
import '../app_icons.dart';

/// **LEVHA KAROLARI** (DENEYIM_PLANI §2.3, F72.4): levhalardaki "simge + ad"
/// düğmelerinin tek kılığı. Zemin `surfaceContainer`, köşe `AppRadius.m`,
/// çerçeve YOK; fareyle üstüne gelince `AppAlpha.pressed` tonu.
///
/// Not menüsünün simge ızgarası (`ActionMenu`) ve Ekle karosu (`AddTile`)
/// kullanıcı isteğiyle kendi biçiminde — bunlara ÇEVRİLMEZ (§4 Y6, Y16).
class SheetTile extends StatelessWidget {
  /// Küçük karo: 56 dp, simge 20 `primary`, ad `AppText.label`. Ad sığmazsa
  /// tek satırda üç noktayla biter; tam adı `Tooltip` verir.
  const SheetTile.tile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : description = null,
       badge = null;

  /// Zengin karo: en az 64 dp, simge 24 solda, `rowTitle` + `meta`
  /// açıklama (en çok 2 satır), sağda ›.
  const SheetTile.rich({
    super.key,
    required this.icon,
    required this.label,
    required String this.description,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback? onTap;

  /// Zengin karoda ›'nin solunda küçük işaret (ör. misafirde hesap kilidi).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final rich = description != null;
    final title = Tooltip(
      message: label,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: rich ? text.rowTitle : text.label,
      ),
    );
    return _TileSurface(
      color: scheme.surfaceContainer,
      hover: scheme.onSurface.withValues(alpha: AppAlpha.pressed),
      label: label,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: rich ? 64 : 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.s,
          ),
          child: Row(
            children: [
              AppIcons.glyph(
                icon,
                size: rich ? AppIconSize.l : AppIconSize.m,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: rich
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          title,
                          Text(
                            description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.meta,
                          ),
                        ],
                      )
                    : title,
              ),
              if (badge case final b?) ...[
                const SizedBox(width: AppSpace.s),
                b,
              ],
              if (rich)
                Icon(
                  Icons.chevron_right,
                  size: AppIconSize.m,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yıkıcı satır ("Sil", "Kalıcı sil"): 48 dp, zemin `errorContainer` %50,
/// yazı ve simge `error`.
class DestructiveRow extends StatelessWidget {
  const DestructiveRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _TileSurface(
      color: scheme.errorContainer.withValues(alpha: 0.5),
      hover: scheme.error.withValues(alpha: AppAlpha.pressed),
      label: label,
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
          child: Row(
            children: [
              Icon(icon, size: AppIconSize.m, color: scheme.error),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.of(theme).label.copyWith(color: scheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Karoları eşit genişlikte dizer: [columns] sütun (varsayılan 2), alan
/// 600 dp ve üstündeyse 3.
class SheetTileGrid extends StatelessWidget {
  const SheetTileGrid({super.key, required this.children, this.columns = 2});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final n = c.maxWidth >= 600 && columns < 3 ? 3 : columns;
      final w = (c.maxWidth - AppSpace.s * (n - 1)) / n;
      return Wrap(
        spacing: AppSpace.s,
        runSpacing: AppSpace.s,
        children: [
          for (final child in children) SizedBox(width: w, child: child),
        ],
      );
    },
  );
}

class _TileSurface extends StatelessWidget {
  const _TileSurface({
    required this.color,
    required this.hover,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final Color hover;
  final String label;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.m);
    return MinTapTarget(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: Material(
          color: color,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: hover,
            borderRadius: radius,
            child: child,
          ),
        ),
      ),
    );
  }
}
