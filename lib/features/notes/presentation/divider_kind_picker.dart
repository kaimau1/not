import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../domain/note_item.dart';
import 'item_divider_style.dart';

/// P63 iskelet (docs/plan_tasarim_B.md §6.5): tepside ve levhada AYNI tür
/// seçici. Her hücre gerçek çizimle (tek `paintItemDivider` çağrısı). Ekrana
/// PB6 bağlar.

const double _compactHeight = 32;
const double _sheetHeight = 44;
const double _compactBaseWidth = 1.6;
const double _sheetBaseWidth = 2.2;
const double _compactMaxWeight = 1.5;

/// Tür adı (`dividerKind*`).
String dividerKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  NoteItem.dividerDashed => l10n.dividerKindDashed,
  NoteItem.dividerDotted => l10n.dividerKindDotted,
  NoteItem.dividerDouble => l10n.dividerKindDouble,
  NoteItem.dividerWavy => l10n.dividerKindWavy,
  _ => l10n.dividerKindSolid,
};

class DividerKindPicker extends StatelessWidget {
  const DividerKindPicker({
    super.key,
    required this.selected,
    required this.onPick,
    this.style,
    this.compact = false,
    this.keyPrefix = 'format-divider-',
    this.scheme,
  });

  /// '' = çizgi yok.
  final String selected;
  final ValueChanged<String> onPick;

  /// Renk + kalınlık örneklere yansır.
  final ItemDivider? style;

  /// Tepsi: 32 dp, adsız, kalınlık ≤ 1.5; levha: 44 dp + ad.
  final bool compact;
  final String keyPrefix;

  /// Editör `_themeOf` rengini verebilsin diye; null = `Theme.of`.
  final ColorScheme? scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = scheme ?? theme.colorScheme;
    final l10n = context.l10n;
    final radius = BorderRadius.circular(compact ? AppRadius.s : AppRadius.m);
    final weight = style?.weight ?? 1;
    final cells = <Widget>[];
    for (final kind in ItemDivider.kinds) {
      final isSel = kind == selected;
      final label = dividerKindLabel(l10n, kind);
      final paint = ItemDivider(
        kind,
        color: style?.color,
        weight: compact ? math.min(weight, _compactMaxWeight) : weight,
      );
      Widget cell = Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: AppMotion.selection,
          height: compact ? _compactHeight : _sheetHeight,
          decoration: BoxDecoration(
            color: isSel ? colors.primaryContainer : Colors.transparent,
            borderRadius: radius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: ValueKey('$keyPrefix$kind'),
              borderRadius: radius,
              onTap: () => onPick(kind),
              child: Semantics(
                selected: isSel,
                button: true,
                label: label,
                child: CustomPaint(
                  painter: DividerSamplePainter(
                    style: paint,
                    fallbackColor: isSel
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                    baseWidth: compact ? _compactBaseWidth : _sheetBaseWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      );
      if (!compact) {
        cell = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            cell,
            const SizedBox(height: AppSpace.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.of(theme).meta,
            ),
          ],
        );
      }
      if (cells.isNotEmpty) cells.add(const SizedBox(width: AppSpace.xs));
      cells.add(Expanded(child: cell));
    }
    return Row(children: cells);
  }
}

/// Tek hücrenin örnek çizgisi (açık sınıf: testler `style`/`baseWidth` okur).
class DividerSamplePainter extends CustomPainter {
  const DividerSamplePainter({
    required this.style,
    required this.fallbackColor,
    required this.baseWidth,
  });

  final ItemDivider style;
  final Color fallbackColor;
  final double baseWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final shift =
        style.kind == NoteItem.dividerDouble ||
            style.kind == NoteItem.dividerWavy
        ? AppSpace.xxs
        : 0.0;
    paintItemDivider(
      canvas,
      style: style,
      fallbackColor: fallbackColor,
      left: AppSpace.s,
      right: size.width - AppSpace.s,
      y: size.height / 2 + shift,
      baseWidth: baseWidth,
    );
  }

  @override
  bool shouldRepaint(DividerSamplePainter old) =>
      old.style != style ||
      old.fallbackColor != fallbackColor ||
      old.baseWidth != baseWidth;
}
