import 'package:flutter/material.dart';

import '../l10n_ext.dart';
import 'app_sheet.dart';

/// **RENK PALETİ** (kullanıcı isteği 2026-10-20: "renk seçenekleri için bir
/// de palet olsun oradan seçim yapılabilsin — aynı palet çerçeve, zemin
/// rengi gibi diğer renk seçeneklerine de gelmeli").
///
/// Hızlı satırdaki beş/on iki ton yetmeyince açılan TEK levha: yazı rengi,
/// vurgu, not zemini ve çerçeve aynı levhayı kullanır. Üstte hazır tonlar
/// (8 renk ailesi × 4 ton + gri dizisi), altta "Özel" — ton ve açıklık
/// kaydırıcısı. Seçilen renk opak döner.

/// Hazır tonlar: satır = açıklık (açıktan koyuya), sütun = renk ailesi.
const List<Color> kPaletteColors = [
  // Açık
  Color(0xFFFFCDD2), Color(0xFFFFE0B2), Color(0xFFFFF59D), Color(0xFFC8E6C9),
  Color(0xFFB2EBF2), Color(0xFFBBDEFB), Color(0xFFD1C4E9), Color(0xFFF8BBD0),
  // Orta
  Color(0xFFE57373), Color(0xFFFFB74D), Color(0xFFFFD54F), Color(0xFF81C784),
  Color(0xFF4DD0E1), Color(0xFF64B5F6), Color(0xFF9575CD), Color(0xFFF06292),
  // Doygun
  Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFF43A047),
  Color(0xFF00ACC1), Color(0xFF1E88E5), Color(0xFF5E35B1), Color(0xFFD81B60),
  // Koyu
  Color(0xFFB71C1C), Color(0xFFE65100), Color(0xFFF57F17), Color(0xFF1B5E20),
  Color(0xFF006064), Color(0xFF0D47A1), Color(0xFF311B92), Color(0xFF880E4F),
  // Nötr
  Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFF9E9E9E),
  Color(0xFF757575), Color(0xFF616161), Color(0xFF424242), Color(0xFF212121),
];

/// Paleti alt levhada açar; seçilen rengi döner (vazgeçilirse null).
/// [current] seçili görünür ve özel kaydırıcıların başlangıcıdır.
Future<Color?> showColorPaletteSheet(
  BuildContext context, {
  required String title,
  Color? current,
}) {
  return showAppSheet<Color>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ColorPalette(
          title: title,
          current: current,
          onPick: (c) => Navigator.pop(sheetContext, c),
        ),
      ),
    ),
  );
}

/// Palet gövdesi (levhadan bağımsız — testte ve gömülü kullanımda).
class ColorPalette extends StatefulWidget {
  const ColorPalette({
    super.key,
    required this.title,
    required this.onPick,
    this.current,
  });

  final String title;
  final Color? current;
  final ValueChanged<Color> onPick;

  @override
  State<ColorPalette> createState() => _ColorPaletteState();
}

class _ColorPaletteState extends State<ColorPalette> {
  late HSLColor _custom = HSLColor.fromColor(
    widget.current ?? const Color(0xFF64B5F6),
  );

  bool _same(Color a, Color? b) =>
      b != null && (a.toARGB32() & 0xFFFFFF) == (b.toARGB32() & 0xFFFFFF);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final customColor = _custom.toColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 8;
            const gap = 8.0;
            final size =
                ((constraints.maxWidth - gap * (columns - 1)) / columns).clamp(
                  24.0,
                  44.0,
                );
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final color in kPaletteColors)
                  _Swatch(
                    key: ValueKey('palette-${color.toARGB32()}'),
                    color: color,
                    size: size,
                    selected: _same(color, widget.current),
                    onTap: () => widget.onPick(color),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              l10n.paletteCustom,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: customColor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              key: const ValueKey('palette-custom-use'),
              onPressed: () => widget.onPick(customColor),
              child: Text(l10n.paletteUse),
            ),
          ],
        ),
        _GradientSlider(
          label: l10n.paletteHue,
          value: _custom.hue / 360,
          colors: [
            for (var h = 0; h <= 360; h += 60)
              HSLColor.fromAHSL(1, h.toDouble(), 0.75, 0.55).toColor(),
          ],
          onChanged: (v) => setState(() => _custom = _custom.withHue(v * 360)),
        ),
        _GradientSlider(
          label: l10n.paletteSaturation,
          value: _custom.saturation,
          colors: [
            _custom.withSaturation(0).toColor(),
            _custom.withSaturation(1).toColor(),
          ],
          onChanged: (v) => setState(() => _custom = _custom.withSaturation(v)),
        ),
        _GradientSlider(
          label: l10n.paletteLightness,
          value: _custom.lightness,
          colors: [
            _custom.withLightness(0.05).toColor(),
            _custom.withLightness(0.5).toColor(),
            _custom.withLightness(0.95).toColor(),
          ],
          onChanged: (v) => setState(
            () => _custom = _custom.withLightness(v.clamp(0.05, 0.95)),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.color,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = color.computeLuminance() > 0.5;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: size * 0.45,
                color: light ? Colors.black87 : Colors.white,
              )
            : null,
      ),
    );
  }
}

/// Zemininde renk geçişi olan ince kaydırıcı.
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final double value;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: value.clamp(0.0, 1.0),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hızlı renk satırlarının sonundaki "daha fazla renk" düğmesi: tam paleti
/// açar, seçilen rengi [onPicked]e verir. [current] paletteki hazır
/// tonlardan biri değilse (özel renk) düğme o renkle dolu ve tikli çizilir.
class PaletteButton extends StatelessWidget {
  const PaletteButton({
    super.key,
    required this.title,
    required this.onPicked,
    this.current,
    this.size = 26,
  });

  final String title;
  final Color? current;
  final ValueChanged<Color> onPicked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final custom = current;
    return Tooltip(
      message: context.l10n.paletteMore,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final picked = await showColorPaletteSheet(
            context,
            title: title,
            current: custom,
          );
          if (picked != null) onPicked(picked.withValues(alpha: 1));
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: custom,
            gradient: custom != null
                ? null
                : const SweepGradient(
                    colors: [
                      Color(0xFFE57373),
                      Color(0xFFFFD54F),
                      Color(0xFF81C784),
                      Color(0xFF64B5F6),
                      Color(0xFF9575CD),
                      Color(0xFFE57373),
                    ],
                  ),
          ),
          child: Icon(
            custom != null ? Icons.check : Icons.palette_outlined,
            size: size * 0.55,
            color: custom != null && custom.computeLuminance() > 0.5
                ? Colors.black87
                : Colors.white,
          ),
        ),
      ),
    );
  }
}
