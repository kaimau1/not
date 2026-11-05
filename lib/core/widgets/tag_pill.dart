import 'package:flutter/material.dart';

/// Etiket hapının renkleri (kullanıcı isteği 2026-11-05: "etiketler çok
/// sönük görünüyor, temaya göre biraz renklendirilebilir"). Eskiden kartta
/// yalnız soluk gri yazı, editör çubuğunda gri çerçeveydi. Artık temanın
/// İKİNCİL kabı ile dolu bir hap: her ailede (Adaçayı, Porselen, Kil, …)
/// kendi tonunda. Renkli notta notun koyu vurgusu ([accent]) hafif bir
/// zeminle kullanılır — kartın kendi rengine karışmaz.
({Color background, Color foreground}) tagPillColors(
  ColorScheme scheme,
  Color? accent,
) {
  if (accent != null) {
    return (background: accent.withValues(alpha: 0.14), foreground: accent);
  }
  return (
    background: scheme.secondaryContainer.withValues(alpha: 0.85),
    foreground: scheme.onSecondaryContainer,
  );
}

/// Kart ve editör çubuğundaki tek etiket hapı.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.tag,
    this.accent,
    this.fontSize = 11,
    this.maxWidth,
  });

  final String tag;
  final Color? accent;
  final double fontSize;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = tagPillColors(Theme.of(context).colorScheme, accent);
    Widget pill = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          '#$tag',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
      ),
    );
    if (maxWidth != null) {
      pill = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: pill,
      );
    }
    return pill;
  }
}
