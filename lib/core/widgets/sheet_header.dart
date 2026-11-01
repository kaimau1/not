import 'package:flutter/material.dart';

import '../l10n_ext.dart';

/// Levha iskeleti (F16.2, 2026-10-31): bütün alt levhalar AYNI başlıkla açılır
/// — başlık solda, ✕ sağda. Eskiden Süz başlık + "Kapat" hapı, Ekle başlık + ✕,
/// ⋮ menüleri yalnız tutamak, AI simgeli başlık kullanıyordu (U7).
///
/// [badge] başlığın hemen yanında (ör. Süz'de uygulanan süzgeç sayısı),
/// [actions] ✕'in solunda (ör. "Sıfırla"). [onClose] verilmezse levha
/// `Navigator.pop` ile kapanır; `showClose: false` yalnız levhanın kendisi
/// zaten tek dokunuşla kapanan bir menüyse (⋮ menüleri) kullanılır.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.badge,
    this.actions = const [],
    this.onClose,
    this.showClose = true,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 8, 8),
  });

  final String title;
  final Widget? badge;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final bool showClose;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            // Expanded: Flexible + Spacer boş alanı yarı yarıya bölüyor, ✕ sağ
            // kenara değil ortaya yakın düşüyordu (cihaz turu 2026-11-01).
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sheetTitleStyle(context),
                      ),
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 8), badge!],
                ],
              ),
            ),
            ...actions,
            if (showClose)
              IconButton(
                key: const ValueKey('sheet-close'),
                tooltip: context.l10n.close,
                icon: const Icon(Icons.close),
                onPressed: onClose ?? () => Navigator.maybePop(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// Levha başlığının yazı stili — başlığı kendi düzeninde çizen levhalar da
/// (ör. önizlemeli Paylaş) bunu kullanır.
TextStyle? sheetTitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700);

/// Bölüm başlığı stili: CÜMLE DÜZENİ (`toUpperCase` yok — Türkçede
/// "i" → "I" bozuyordu), `labelLarge`, kalın, varsayılan `primary`.
TextStyle? sectionLabelStyle(BuildContext context, {Color? color}) {
  final theme = Theme.of(context);
  return theme.textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.w700,
    color: color ?? theme.colorScheme.primary,
  );
}

/// Tek bölüm başlığı bileşeni (levha ve liste ekranları).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: sectionLabelStyle(context, color: color),
    ),
  );
}
