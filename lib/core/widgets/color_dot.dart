// P63 iskelet — docs/plan_tasarim_B.md §6.6
import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Açık renkli noktanın (beyaz mürekkep, sarı) zeminden ayrılmasını sağlayan
/// ince kenar: `onSurface` × bu saydamlık. Kalem tepsisindeki değer aynen.
const double _edgeAlpha = 0.18;
const double _edgeWidth = 0.8;

/// Halka kalınlığı ve halka ile nokta arasındaki boşluk.
const double _ring = AppSpace.xxs;

/// **TEK RENK NOKTASI**: kalem tepsisi, kalem paneli, kalem sütunu ve çizgi
/// ayarları aynı noktayı çizer.
///
/// Seçili = arada [_ring] boşluk bırakan [_ring] kalınlığında `primary`
/// halka. Halka yalnız RENK değiştirir ([AppMotion.selection]); kapladığı
/// alan her zaman `size + 8` — seçilince komşuları itmez.
class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
    required this.color,
    required this.selected,
    this.size = 28,
    this.onTap,
    this.tooltip,
    this.child,
  });

  final Color color;
  final bool selected;

  /// Noktanın çapı (halka payı hariç).
  final double size;
  final VoidCallback? onTap;

  /// İpucu ve erişilebilirlik adı.
  final String? tooltip;

  /// Noktanın ortasındaki işaret (ör. "tema rengi" simgesi).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extent = size + 4 * _ring;
    // Boy dışarıdan sabit: canlanan yalnız halkanın rengi.
    Widget dot = SizedBox.square(
      dimension: extent,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.selection),
        curve: AppMotion.curveOf(context, AppMotion.standard),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.primary.withValues(alpha: 0),
            width: _ring,
          ),
        ),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: _edgeAlpha),
              width: _edgeWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
    final tap = onTap;
    if (tap != null) {
      dot = InkResponse(onTap: tap, radius: extent / 2, child: dot);
    }
    final tip = tooltip;
    return Semantics(
      button: tap != null,
      selected: selected,
      label: tip,
      child: tip == null
          ? dot
          : Tooltip(message: tip, excludeFromSemantics: true, child: dot),
    );
  }
}
