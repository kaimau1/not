import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Biçim paneli (2026-11-05): iki sıra; stil, renk, kapsam, çizgi ve yazı
/// tipi panelin üstünde açılan tepside.
/// Kullanıcı bulgusu: "renk paletine basılamıyor, çok kenarda kaldığı için"
/// — dar ekranda her düğme görünür ve basılabilir olmalı.
void main() {
  final formats = <(RichFormat, int?)>[];
  final removed = <RichFormat>[];
  final headings = <RichHeading>[];
  final fonts = <String?>[];
  final scales = <double>[];
  var closed = 0;

  Widget app() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: FormatBar(
          onFormat: (format, {colorIndex}) => formats.add((format, colorIndex)),
          onClearFormat: () {},
          onRemoveFormat: removed.add,
          fontFamily: null,
          fontScale: 1,
          textOpacity: 1,
          hasSelection: () => false,
          onFontChanged: fonts.add,
          onScaleChanged: (_) {},
          onScaleEnd: scales.add,
          onOpacityChanged: (_) {},
          onOpacityEnd: (_) {},
          onClose: () => closed++,
          onHeading: headings.add,
        ),
      ),
    ),
  );

  setUp(() {
    formats.clear();
    removed.clear();
    headings.clear();
    fonts.clear();
    scales.clear();
    closed = 0;
  });

  Future<void> pumpNarrow(WidgetTester tester) async {
    // 360 dp: piyasadaki en dar yaygın telefon.
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
  }

  /// Düğmenin merkezi ekranın içinde ve dokunuş ona ulaşıyor mu.
  void expectTappable(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    final center = tester.getCenter(finder);
    expect(center.dx, inInclusiveRange(0, 360));
    tester.hitTestOnBinding(center);
  }

  testWidgets('iki sıra: dar ekranda her düğme görünür; renk tepside', (
    tester,
  ) async {
    await pumpNarrow(tester);
    expect(tester.takeException(), isNull);
    for (final key in [
      'format-style-menu',
      'format-bold',
      'format-italic',
      'format-underline',
      'format-color-menu',
      'format-scope-menu',
      'format-font',
      'format-size-down',
      'format-size-up',
      'format-clear',
      'format-close',
    ]) {
      expectTappable(tester, find.byKey(ValueKey(key)));
    }
    // Tepsideki öğeler kapalıyken yer kaplamaz (kullanıcı isteği
    // 2026-11-05: "çok satır var, çok yer kaplıyor").
    expect(find.byKey(const ValueKey('format-heading-h1')), findsNothing);
    expect(find.byKey(const ValueKey('format-color-1')), findsNothing);
    expect(find.byKey(const ValueKey('format-scope-line')), findsNothing);
    expect(tester.getSize(find.byType(FormatBar)).height, lessThan(110));

    await tester.tap(find.byKey(const ValueKey('format-color-menu')));
    await tester.pumpAndSettle();
    for (final key in [
      'format-mode-text',
      'format-mode-highlight',
      'format-color-1',
      'format-color-5',
      'format-color-palette',
      'format-color-remove',
    ]) {
      expectTappable(tester, find.byKey(ValueKey(key)));
    }
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('format-bold')));
    await tester.tap(find.byKey(const ValueKey('format-close')));
    expect(formats, [(RichFormat.bold, null)]);
    expect(closed, 1);
  });

  testWidgets('renk tek dokunuş; anahtar vurguya geçirir; TAM PALET '
      'basılabilir', (tester) async {
    await pumpNarrow(tester);
    await tester.tap(find.byKey(const ValueKey('format-color-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('format-color-2')));
    await tester.tap(find.byKey(const ValueKey('format-mode-highlight')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('format-color-2')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('format-highlight-5')));
    await tester.tap(find.byKey(const ValueKey('format-highlight-remove')));
    expect(formats, [(RichFormat.color, 2), (RichFormat.highlight, 5)]);
    expect(removed, [RichFormat.highlight]);
    expect(tester.takeException(), isNull);

    // Kenardaki palet düğmesi ekranın içinde: dokununca palet levhası açılır.
    final palette = find.byKey(const ValueKey('format-highlight-palette'));
    expect(tester.getRect(palette).right, lessThanOrEqualTo(360));
    await tester.tap(palette);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('palette-custom-use')), findsOneWidget);
  });

  testWidgets('başlık hapı tek dokunuş; boyut − / + adım uygular; yazı '
      'tipi tepsisi ikinci dokunuşla kapanır', (tester) async {
    await pumpNarrow(tester);
    // Stil hapı tepsi açmaz, sıradakine geçer (2026-11-05).
    await tester.tap(find.byKey(const ValueKey('format-style-menu')));
    await tester.pumpAndSettle();
    expect(headings, [RichHeading.h1]);
    expect(find.byKey(const ValueKey('format-heading-h1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('format-size-up')));
    await tester.pump();
    expect(scales.single, closeTo(1.1, 1e-9));

    await tester.tap(find.byKey(const ValueKey('format-font')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('format-size-slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('format-opacity-slider')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('format-font-serif')));
    expect(fonts, ['serif']);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('format-font')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('format-size-slider')), findsNothing);
  });
}
