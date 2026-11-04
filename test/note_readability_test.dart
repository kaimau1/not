import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/note_colors.dart';
import 'package:notlar/core/utils/color_contrast.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/domain/note.dart';

/// KULLANICI BULGUSU (2026-11-04): "not arka plan rengini değiştirince bazen
/// yazı rengi sabit kaldığı için okuma zorluğu oluyor."
///
/// KÖK NEDEN 1: özel renk kâğıda sabit oranda karıştırılıyor, yazı hep
/// temanın mürekkebinde kalıyordu — koyu renkler açık temada gri-orta bir
/// zemin veriyordu (koyu yazı da açık yazı da < 3:1).
/// KÖK NEDEN 2: satır içi renkli yazı (sarı, yeşil…) sabit renkteydi; sarı
/// yazı açık zeminde ~1,6:1.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Paletten seçilebilecek uç renkler: siyah, lacivert, koyu yeşil, orta gri,
  // saf kırmızı, saf mavi, sarı, beyaz, pastel.
  const customs = [
    Color(0xFF000000),
    Color(0xFF1A237E),
    Color(0xFF1B5E20),
    Color(0xFF777777),
    Color(0xFFFF0000),
    Color(0xFF0000FF),
    Color(0xFFFFEB3B),
    Color(0xFFFFFFFF),
    Color(0xFFF8BBD0),
  ];

  test('her özel renkte notun yazısı okunur (≥ 4,5:1)', () {
    for (final f in ThemeFamily.values) {
      for (final b in Brightness.values) {
        final theme = AppTheme.of(f, b);
        for (final c in customs) {
          final bg = NoteColors.customSurface(theme, c);
          final ink = NoteColors.inkThemeFor(theme, bg) ?? theme;
          expect(
            contrastRatio(ink.colorScheme.onSurface, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$f $b $c → $bg',
          );
        }
      }
    }
  });

  test('açık temada koyu renk korunur, yazı zıt temadan gelir', () {
    final theme = AppTheme.light();
    final bg = NoteColors.customSurface(theme, const Color(0xFF1A237E));
    // Zemin koyu kalır (kullanıcı koyu bir not istedi)…
    expect(bg.computeLuminance(), lessThan(0.1));
    // …ve not ZIT temayla (açık yazı) çizilir.
    final ink = NoteColors.inkThemeFor(theme, bg);
    expect(ink, isNotNull);
    expect(ink!.brightness, Brightness.dark);
  });

  test('hazır renklerde tema değişmez (gereksiz katman yok)', () {
    for (final f in ThemeFamily.values) {
      for (final b in Brightness.values) {
        final theme = AppTheme.of(f, b);
        for (final c in NoteColor.values) {
          final bg = NoteColors.surfaceIn(theme, c);
          expect(NoteColors.inkThemeFor(theme, bg), isNull, reason: '$f $b $c');
        }
      }
    }
  });

  test('renkli yazı zemine göre okunur hâle gelir, tonu korunur', () {
    const yellow = Color(0xFFFFC94D);
    const paper = Color(0xFFFAFCFA);
    expect(contrastRatio(yellow, paper), lessThan(2));
    final fixed = readableOn(yellow, paper);
    expect(contrastRatio(fixed, paper), greaterThanOrEqualTo(4.5));
    final h0 = HSLColor.fromColor(yellow).hue;
    final h1 = HSLColor.fromColor(fixed).hue;
    expect((h0 - h1).abs(), lessThan(8));
    // Koyu zeminde açılır.
    const night = Color(0xFF131916);
    const navy = Color(0xFF283593);
    expect(
      contrastRatio(readableOn(navy, night), night),
      greaterThanOrEqualTo(4.5),
    );
    // Zaten okunan renge dokunulmaz.
    const ink = Color(0xFF923B33);
    expect(readableOn(ink, paper), ink);
  });

  test('markStyle: zemin verilince renkli yazı okunur, verilmezse aynen', () {
    const palette = [Color(0xFFE57373), Color(0xFFFFC94D)];
    const mark = RichMark(color: 2);
    const base = TextStyle(color: Color(0xFF1B2420));
    expect(markStyle(base, mark, palette).color, const Color(0xFFFFC94D));
    final onPaper = markStyle(
      base,
      mark,
      palette,
      background: const Color(0xFFFAFCFA),
    ).color!;
    expect(
      contrastRatio(onPaper, const Color(0xFFFAFCFA)),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('NoteInkScope koyu zeminde yazıyı ve temayı çevirir', (
    tester,
  ) async {
    late ThemeData inner;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Material(
          color: const Color(0xFF101418),
          child: NoteInkScope(
            background: const Color(0xFF101418),
            child: Builder(
              builder: (context) {
                inner = Theme.of(context);
                return const Text('okunur');
              },
            ),
          ),
        ),
      ),
    );
    expect(inner.brightness, Brightness.dark);
    final style = DefaultTextStyle.of(tester.element(find.text('okunur')));
    expect(
      contrastRatio(style.style.color!, const Color(0xFF101418)),
      greaterThanOrEqualTo(4.5),
    );
  });
}
