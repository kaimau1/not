import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';

/// PW-E (web keşfi 2026-11-18): KW-4 ay dışı gün şeridi saydamlık yerine
/// ton (≥ 3:1), KW-9 geniş hücrede (≥ 140 dp) yazı büyür.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('KW-4: ay dışı şerit tonu her temada en az 3:1', () {
    for (final family in ThemeFamily.values) {
      for (final b in Brightness.values) {
        final scheme = AppTheme.of(family, b).colorScheme;
        final tone = monthChipDimTone(scheme);
        expect(
          _contrast(tone.foreground, tone.background),
          greaterThanOrEqualTo(3),
          reason: '$family $b',
        );
      }
    }
  });

  test('KW-9: geniş hücrede şerit 11 pt, dar hücrede 9,5 pt', () {
    expect(monthChipFontSize(kMonthWideCell - 1), 9.5);
    expect(monthChipFontSize(kMonthWideCell), 11);
    expect(monthChipFontSize(245), 11);
  });

  test('KT-23: dikey tabletin uzun hücresi geniş yazı alır', () {
    expect(monthChipFontSize(80, 120), 11); // dikey tablet
    expect(monthChipFontSize(51, 120), 9.5); // telefon dikey
    expect(monthChipFontSize(100, 50), 9.5); // telefon yatay
  });
}
