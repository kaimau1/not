import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/core/widgets/delayed_spinner.dart';
import 'package:notlar/core/widgets/sheet_header.dart';
import 'package:notlar/core/widgets/sheet_tile.dart';

/// DENEYIM_PLANI F72.2 (yazı rolleri), F72.4 (ortak bileşenler), F72.5
/// (bölüm adı).
void main() {
  group('AppText (F72.2)', () {
    // §2.1 tablosu: rol → (punto, satır, ağırlık).
    final table = <String, (double, double, FontWeight)>{
      'badge': (11, 14, FontWeight.w600),
      'meta': (12, 16, FontWeight.w400),
      'label': (13, 18, FontWeight.w500),
      'body': (14, 20, FontWeight.w400),
      'section': (14, 20, FontWeight.w600),
      'rowTitle': (16, 22, FontWeight.w500),
      'sheetTitle': (18, 24, FontWeight.w600),
      'screenTitle': (20, 26, FontWeight.w600),
    };
    Map<String, TextStyle> roles(AppText t) => {
      'badge': t.badge,
      'meta': t.meta,
      'label': t.label,
      'body': t.body,
      'section': t.section,
      'rowTitle': t.rowTitle,
      'sheetTitle': t.sheetTitle,
      'screenTitle': t.screenTitle,
    };

    for (final (name, make) in <(String, ThemeData Function())>[
      ('açık', AppTheme.light),
      ('zıt (ham)', () => AppTheme.opposite(AppTheme.light())),
      ('düz ThemeData', ThemeData.new),
    ]) {
      testWidgets('$name temada 8 rol tabloyla aynı, null yok', (_) async {
        final theme = make();
        final got = roles(AppText.of(theme));
        for (final MapEntry(:key, :value) in table.entries) {
          final s = got[key]!;
          expect(s.fontSize, value.$1, reason: key);
          expect(
            s.height! * s.fontSize!,
            closeTo(value.$2, 0.001),
            reason: key,
          );
          expect(s.fontWeight, value.$3, reason: key);
          expect(s.color, isNotNull, reason: key);
        }
        expect(got['section']!.color, theme.colorScheme.primary);
        expect(got['meta']!.color, theme.colorScheme.onSurfaceVariant);
      });
    }

    testWidgets('tema başına bir kez kurulur', (_) async {
      final theme = AppTheme.light();
      expect(identical(AppText.of(theme), AppText.of(theme)), isTrue);
    });
  });

  Widget host(Widget child, {double width = 360}) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );

  const longLabel = 'Çok uzun bir karo adı ki kesinlikle tek satıra sığmaz';

  group('SheetTile / DestructiveRow / SheetTileGrid (F72.4)', () {
    testWidgets('360 dp: taşma yok, uzun ad tek satır + üç nokta + Tooltip', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: Column(
              children: [
                SheetTileGrid(
                  children: [
                    SheetTile.tile(
                      icon: Icons.share,
                      label: longLabel,
                      onTap: () => taps++,
                    ),
                    SheetTile.tile(
                      icon: Icons.copy,
                      label: 'Kopyala',
                      onTap: () {},
                    ),
                  ],
                ),
                SheetTile.rich(
                  icon: Icons.picture_as_pdf,
                  label: longLabel,
                  description: '$longLabel $longLabel $longLabel',
                  onTap: () {},
                ),
                DestructiveRow(
                  icon: Icons.delete,
                  label: longLabel,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      final texts = tester.widgetList<Text>(find.text(longLabel));
      expect(texts, isNotEmpty);
      for (final t in texts) {
        expect(t.maxLines, 1);
        expect(t.overflow, TextOverflow.ellipsis);
      }
      expect(
        find.byWidgetPredicate((w) => w is Tooltip && w.message == longLabel),
        findsNWidgets(2),
      );

      // 2 sütun, eşit genişlik; karo 56, zengin ≥ 64, yıkıcı 48.
      final a = tester.getSize(find.byType(SheetTile).at(0));
      final b = tester.getSize(find.byType(SheetTile).at(1));
      expect(a.width, b.width);
      expect(a.width, lessThan(180));
      expect(a.height, 56);
      expect(
        tester.getSize(find.byType(SheetTile).at(2)).height,
        greaterThanOrEqualTo(64),
      );
      expect(tester.getSize(find.byType(DestructiveRow)).height, 48);

      await tester.tap(find.byType(SheetTile).first);
      expect(taps, 1);
    });

    testWidgets('düğme anlamı taşır', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(SheetTile.tile(icon: Icons.copy, label: 'Kopyala', onTap: () {})),
      );
      expect(
        tester.getSemantics(find.byType(SheetTile)),
        matchesSemantics(
          label: 'Kopyala',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('600 dp ve üstü 3 sütun', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          SheetTileGrid(
            children: [
              for (final l in ['a', 'b', 'c'])
                SheetTile.tile(icon: Icons.copy, label: l, onTap: () {}),
            ],
          ),
          width: 640,
        ),
      );
      final ys = {
        for (var i = 0; i < 3; i++)
          tester.getTopLeft(find.byType(SheetTile).at(i)).dy,
      };
      expect(ys, hasLength(1));
    });
  });

  group('DelayedSpinner (F72.4)', () {
    double opacity(WidgetTester t) =>
        t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

    testWidgets('300 ms önce görünmez, sonra belirir', (tester) async {
      await tester.pumpWidget(host(const DelayedSpinner()));
      await tester.pump(const Duration(milliseconds: 299));
      expect(opacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 2));
      expect(opacity(tester), 1);
      await tester.pump(AppMotion.quick);
    });

    testWidgets('kısa işte kapanırsa zamanlayıcı sızmaz', (tester) async {
      await tester.pumpWidget(host(const DelayedSpinner()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(host(const SizedBox()));
      // Bekleyen Timer kalsaydı test sonunda hata verirdi.
    });
  });

  testWidgets('SectionLabel = AppText.section (F72.5)', (tester) async {
    await tester.pumpWidget(host(const SectionLabel('Sabit')));
    final style = tester.widget<Text>(find.text('Sabit')).style!;
    final theme = AppTheme.light();
    expect(style.fontSize, 14);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, theme.colorScheme.primary);
  });
}
