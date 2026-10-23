import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/color_palette.dart';
import '../domain/note_item.dart';

/// Madde altı ayırıcıyı ([ItemDivider]) çizer — editör satırı ve ana ekran
/// kartı aynı çizimi kullanır (yalnız temel kalınlık ve kenar payı farklı).
///
/// [baseWidth] düz çizginin varsayılan kalınlığı; noktalı çizgi ondan biraz
/// kalın çizilir (ince noktalar düz çizginin üstünde kayboluyordu).
void paintItemDivider(
  Canvas canvas, {
  required ItemDivider style,
  required Color fallbackColor,
  required double left,
  required double right,
  required double y,
  required double baseWidth,
}) {
  if (right <= left) return;
  final color = style.color == null ? fallbackColor : Color(style.color!);
  final dotted = style.kind == NoteItem.dividerDotted;
  final width = baseWidth * style.weight * (dotted ? 1.45 : 1);
  final paint = Paint()
    ..color = color
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..strokeCap = dotted ? StrokeCap.round : StrokeCap.butt;
  switch (style.kind) {
    case NoteItem.dividerDashed:
      final dash = 5 + 2.5 * width;
      final gap = 3 + 1.5 * width;
      for (var x = left; x < right; x += dash + gap) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + dash, right), y),
          paint,
        );
      }
    case NoteItem.dividerDotted:
      final step = math.max(5.0, width * 2.2);
      for (var x = left; x < right; x += step) {
        canvas.drawLine(Offset(x, y), Offset(x, y), paint);
      }
    case NoteItem.dividerDouble:
      // İki ince çizgi: toplam kalınlık tek çizgiyle aynı ağırlıkta dursun.
      final line = math.max(0.8, width * 0.6);
      final offset = line + math.max(1.5, width * 0.6);
      paint.strokeWidth = line;
      canvas
        ..drawLine(Offset(left, y - offset), Offset(right, y - offset), paint)
        ..drawLine(Offset(left, y), Offset(right, y), paint);
    case NoteItem.dividerWavy:
      final amplitude = 1.5 + width * 0.6;
      final wave = 10 + width * 2;
      final path = Path()..moveTo(left, y - amplitude);
      for (var x = left; x <= right; x += 1.5) {
        path.lineTo(
          x,
          y - amplitude + math.sin((x - left) / wave * 2 * math.pi) * amplitude,
        );
      }
      paint.strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    default:
      // Düz çizgi ve TANINMAYAN tür (daha yeni sürümün türü): düz çizgi.
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
  }
}

/// Son kullanılan ayırıcı biçimi (oturum boyu): yeni çizgi aynı renk ve
/// kalınlıkla gelsin — her maddede yeniden ayarlamak gerekmesin.
class ItemDividerMemory {
  ItemDividerMemory._();

  static int? color;
  static double weight = 1;

  static void remember(ItemDivider style) {
    color = style.color;
    weight = style.weight;
  }

  /// [kind] türünde, son kullanılan renk/kalınlıkla yeni biçim.
  static ItemDivider fresh(String kind) =>
      ItemDivider(kind, color: color, weight: weight);
}

/// Ayırıcı ayar levhasının sonucu: yeni biçim (null = çizgiyi kaldır) ve
/// listedeki TÜM çizgilere uygulansın mı.
typedef ItemDividerChoice = ({ItemDivider? style, bool applyAll});

/// **ÇİZGİ AYARLARI** levhası: tür (düz, kesikli, noktalı, çift, dalgalı),
/// renk ve kalınlık; canlı önizlemeyle. "Tüm çizgilere uygula" listedeki
/// bütün ayırıcıların biçimini birden değiştirir.
Future<ItemDividerChoice?> showItemDividerSheet(
  BuildContext context, {
  required ItemDivider initial,
}) => showModalBottomSheet<ItemDividerChoice>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _ItemDividerSheet(initial: initial),
);

class _ItemDividerSheet extends StatefulWidget {
  const _ItemDividerSheet({required this.initial});

  final ItemDivider initial;

  @override
  State<_ItemDividerSheet> createState() => _ItemDividerSheetState();
}

class _ItemDividerSheetState extends State<_ItemDividerSheet> {
  late ItemDivider _style = widget.initial;

  static const _swatches = <Color>[
    Color(0xFF424242),
    Color(0xFF9E9E9E),
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
  ];

  String _kindLabel(String kind) {
    final l10n = context.l10n;
    return switch (kind) {
      NoteItem.dividerDashed => l10n.dividerKindDashed,
      NoteItem.dividerDotted => l10n.dividerKindDotted,
      NoteItem.dividerDouble => l10n.dividerKindDouble,
      NoteItem.dividerWavy => l10n.dividerKindWavy,
      _ => l10n.dividerKindSolid,
    };
  }

  void _done({required bool applyAll}) {
    ItemDividerMemory.remember(_style);
    Navigator.pop(context, (style: _style, applyAll: applyAll));
  }

  Widget _swatch(Color? color) {
    final scheme = Theme.of(context).colorScheme;
    final selected = color == null
        ? _style.color == null
        : _style.color == color.toARGB32();
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => setState(
        () => _style = color == null
            ? _style.copyWith(clearColor: true)
            : _style.copyWith(color: color.toARGB32()),
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color ?? scheme.primary.withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        // Tema rengi: "otomatik" işareti.
        child: color == null
            ? Icon(Icons.auto_awesome, size: 14, color: scheme.onPrimary)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final custom = _style.color;
    final customOutsideSwatches =
        custom != null && !_swatches.any((c) => c.toARGB32() == custom);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dividerSettings,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Önizleme: örnek madde + altındaki çizgi.
            Container(
              height: 52,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: _PreviewPainter(_style, scheme.primary),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(l10n.dividerPreviewText),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.dividerKind, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final kind in ItemDivider.kinds)
                  ChoiceChip(
                    label: Text(_kindLabel(kind)),
                    selected: _style.kind == kind,
                    onSelected: (_) =>
                        setState(() => _style = _style.copyWith(kind: kind)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(l10n.dividerColor, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _swatch(null),
                for (final c in _swatches) _swatch(c),
                if (customOutsideSwatches) _swatch(Color(custom)),
                PaletteButton(
                  title: l10n.paletteMore,
                  current: customOutsideSwatches ? Color(custom) : null,
                  onPicked: (c) => setState(
                    () => _style = _style.copyWith(color: c.toARGB32()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(l10n.dividerWeight, style: theme.textTheme.labelLarge),
                Expanded(
                  child: Slider(
                    value: _style.weight,
                    min: ItemDivider.minWeight,
                    max: ItemDivider.maxWeight,
                    divisions: 10,
                    label: '${_style.weight.toStringAsFixed(1)}×',
                    onChanged: (v) =>
                        setState(() => _style = _style.copyWith(weight: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, (style: null, applyAll: false)),
                  icon: const Icon(Icons.format_strikethrough),
                  label: Text(l10n.itemDividerRemove),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _done(applyAll: true),
                  child: Text(l10n.dividerApplyAll),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => _done(applyAll: false),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  const _PreviewPainter(this.style, this.fallback);

  final ItemDivider style;
  final Color fallback;

  @override
  void paint(Canvas canvas, Size size) => paintItemDivider(
    canvas,
    style: style,
    fallbackColor: fallback.withValues(alpha: 0.75),
    left: 0,
    right: size.width,
    y: size.height - 8,
    baseWidth: 2.2,
  );

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.style.encode() != style.encode() || old.fallback != fallback;
}
