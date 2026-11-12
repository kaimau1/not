import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
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
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.l,
      0,
      AppSpace.s,
      AppSpace.s,
    ),
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
        // 56 dp (DENEYIM §2.3): ✕ olan levhada tutamak yok (K-D7), başlık
        // levhanın tepesinden başlar — 48'de üst kenara yapışıyordu.
        constraints: const BoxConstraints(minHeight: 56),
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
/// `AppText.sheetTitle` (18/24 w600, DENEYIM §2.1) — bütün levhalarda aynı.
TextStyle? sheetTitleStyle(BuildContext context) =>
    AppText.of(Theme.of(context)).sheetTitle;

/// Bölüm başlığı stili: CÜMLE DÜZENİ (`toUpperCase` yok — Türkçede
/// "i" → "I" bozuyordu), `AppText.section` (14/20 w600, DENEYIM F72.5),
/// varsayılan `primary`.
TextStyle? sectionLabelStyle(BuildContext context, {Color? color}) {
  final section = AppText.of(Theme.of(context)).section;
  return color == null ? section : section.copyWith(color: color);
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
