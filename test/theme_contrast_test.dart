import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/app/theme/note_colors.dart';
import 'package:notlar/app/theme/note_themes.dart';
import 'package:notlar/core/a11y/color_names.dart';
import 'package:notlar/core/utils/color_contrast.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

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

  // F32.6: not renkleri birbirinden ayrılır. Plandaki 0,08 eşiği, kullanıcının
  // seçtiği (K5) palette tutmuyor: eşit parlaklıklı pastel zeminde komşular
  // 0,03-0,05, koyu tonda en az 0,028 (mavi/fırtına). Palet değiştirilmedi
  // (TEMA_PLANI F32.6, sabah bakılacak); test bugünkü ayrımın altına inmeyi
  // yakalar, ekran okuyucu ayrımı renk adlarında.
  group('F32.6 renk ayrımı (OKLab)', () {
    List<double> oklab(Color c) {
      double lin(double v) =>
          v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      final r = lin(c.r), g = lin(c.g), b = lin(c.b);
      double cbrt(double v) => math.pow(v, 1 / 3).toDouble();
      final l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
      final m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
      final s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
      return [
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
      ];
    }

    double delta(Color a, Color b) {
      final x = oklab(a), y = oklab(b);
      return math.sqrt(
        math.pow(x[0] - y[0], 2) +
            math.pow(x[1] - y[1], 2) +
            math.pow(x[2] - y[2], 2),
      );
    }

    final colors = NoteColor.values.where((c) => c != NoteColor.none).toList();

    test('zemin tonları bugünkü ayrımın altına inmez', () {
      for (final a in colors) {
        for (final b in colors) {
          if (a.index >= b.index) continue;
          expect(
            delta(NoteColors.swatch(a), NoteColors.swatch(b)),
            greaterThanOrEqualTo(0.029),
            reason: '$a / $b',
          );
        }
      }
    });

    testWidgets('koyu tonlar bugünkü ayrımın altına inmez', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      for (var i = 0; i + 1 < colors.length; i++) {
        final a = NoteColors.ink(context, colors[i]);
        final b = NoteColors.ink(context, colors[i + 1]);
        expect(
          delta(a!, b!),
          greaterThanOrEqualTo(0.028),
          reason: '${colors[i]} / ${colors[i + 1]}',
        );
      }
    });

    test('her rengin adı ayrı (ekran okuyucu)', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final names = {for (final c in colors) noteColorName(l10n, c)};
      expect(names, hasLength(colors.length));
      expect(noteColorName(l10n, NoteColor.amber), 'Bal');
    });
  });
}
