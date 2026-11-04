import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/app/theme/note_colors.dart';
import 'package:notlar/app/theme/note_themes.dart';
import 'package:notlar/core/utils/color_contrast.dart';
import 'package:notlar/features/notes/domain/note.dart';

/// TEMA_PLANI F29.4: yeni temanın her rolü okunur kalsın. Renk değiştiren
/// biri bu testi kırmadan "güzel ama okunmaz" bir ton ekleyemez.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final themes = [
    for (final f in ThemeFamily.values)
      for (final b in Brightness.values) (f, b, AppTheme.of(f, b)),
  ];

  void atLeast(Color fg, Color bg, double min, String reason) => expect(
    contrastRatio(fg, bg),
    greaterThanOrEqualTo(min),
    reason: '$reason: $fg / $bg',
  );

  test('yazı ve soluk yazı her yüzeyde okunur', () {
    for (final (f, b, theme) in themes) {
      final s = theme.colorScheme;
      final card = AppTokens.fromTheme(theme).card;
      for (final bg in [
        s.surface,
        card,
        s.surfaceContainerLowest,
        s.surfaceContainerLow,
        s.surfaceContainer,
        s.surfaceContainerHigh,
      ]) {
        atLeast(s.onSurface, bg, 7, '$f $b yazı');
        atLeast(s.onSurfaceVariant, bg, 4.5, '$f $b soluk yazı');
      }
    }
  });

  test('vurgular ve kapları okunur', () {
    for (final (f, b, theme) in themes) {
      final s = theme.colorScheme;
      final card = AppTokens.fromTheme(theme).card;
      atLeast(s.onPrimary, s.primary, 4.5, '$f $b onPrimary');
      atLeast(s.onPrimaryContainer, s.primaryContainer, 4.5, '$f $b pc');
      atLeast(s.onSecondary, s.secondary, 4.5, '$f $b onSecondary');
      atLeast(s.onSecondaryContainer, s.secondaryContainer, 4.5, '$f $b sc');
      atLeast(s.onTertiary, s.tertiary, 4.5, '$f $b onTertiary');
      atLeast(s.onInverseSurface, s.inverseSurface, 4.5, '$f $b inverse');
      // Simge ve çizgi düzeyi (WCAG 1.4.11): ≥ 3.
      atLeast(s.primary, card, 3, '$f $b vurgu/kart');
      atLeast(s.primary, s.surface, 3, '$f $b vurgu/zemin');
      atLeast(s.secondary, card, 3, '$f $b ikinci vurgu/kart');
      atLeast(s.outline, card, 3, '$f $b outline');
    }
  });

  test('masa ve kâğıt: açık temada kart zeminden açık', () {
    for (final f in ThemeFamily.values) {
      final theme = AppTheme.of(f, Brightness.light);
      final ground = theme.colorScheme.surface.computeLuminance();
      final card = AppTokens.fromTheme(theme).card.computeLuminance();
      expect(card, greaterThan(ground), reason: '$f');
    }
  });

  test('her not renginde her ailenin yazısı ve rengin koyu tonu okunur', () {
    for (final (f, b, theme) in themes) {
      final dark = b == Brightness.dark;
      final palette = NoteColors.palette(dark: dark);
      final inks = NoteColors.inkPalette(dark: dark);
      for (final c in NoteColor.values) {
        if (c == NoteColor.none) continue;
        atLeast(theme.colorScheme.onSurface, palette[c]!, 4.5, '$f $b $c yazı');
        atLeast(inks[c]!, palette[c]!, 4.5, '$f $b $c koyu ton');
      }
    }
  });

  test('not temalarının düz zemininde yazı okunur', () {
    for (final (f, b, theme) in themes) {
      for (final t in NoteThemes.all) {
        final base = t.palette(b == Brightness.dark).base;
        atLeast(theme.colorScheme.onSurface, base, 4.5, '$f $b ${t.id}');
      }
    }
  });

  test('açık paletin parlaklıkları eşit (bağıran/kaybolan kart yok)', () {
    final lum = [
      for (final c in NoteColors.palette(dark: false).values)
        c.computeLuminance(),
    ];
    final hi = lum.reduce((a, b) => a > b ? a : b);
    final lo = lum.reduce((a, b) => a < b ? a : b);
    // Keep'in kendi paletinde oran ~1,9 idi (şeftali 0,45 ↔ bal 0,92).
    expect(hi / lo, lessThan(1.45));
  });
}
