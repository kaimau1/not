import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Biçim çubuğu (2026-10-20 sıfırdan): kaymayan ana satır + satır içi
/// tepsiler. Kullanıcı bulgusu: "renk paletine basılamıyor, çok kenarda
/// kaldığı için" — dar ekranda her düğme görünür ve basılabilir olmalı.
void main() {
  final formats = <(RichFormat, int?)>[];
  final removed = <RichFormat>[];
  final headings = <RichHeading>[];
  final fonts = <String?>[];
  var pageStyle = 0;
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
          onScaleEnd: (_) {},
          onOpacityChanged: (_) {},
          onOpacityEnd: (_) {},
          onClose: () => closed++,
          onPageStyle: () => pageStyle++,
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
    pageStyle = 0;
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

  testWidgets('dar ekranda ana satırın her düğmesi görünür ve çalışır', (
    tester,
  ) async {
    await pumpNarrow(tester);
    expect(tester.takeException(), isNull);
    for (final key in [
      'format-heading',
      'format-bold',
      'format-italic',
      'format-underline',
      'format-colors',
      'format-font',
      'format-clear',
      'format-page',
      'format-close',
    ]) {
      expectTappable(tester, find.byKey(ValueKey(key)));
    }
    await tester.tap(find.byKey(const ValueKey('format-bold')));
    await tester.tap(find.byKey(const ValueKey('format-page')));
    await tester.tap(find.byKey(const ValueKey('format-close')));
    expect(formats, [(RichFormat.bold, null)]);
    expect(pageStyle, 1);
    expect(closed, 1);
  });

  testWidgets('renk tepsisi: tonlar, kaldır ve TAM PALET basılabilir', (
    tester,
  ) async {
    await pumpNarrow(tester);
    await tester.tap(find.byKey(const ValueKey('format-colors')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('format-color-2')));
    await tester.tap(find.byKey(const ValueKey('format-highlight-5')));
    await tester.tap(find.byKey(const ValueKey('format-highlight-remove')));
    expect(formats, [(RichFormat.color, 2), (RichFormat.highlight, 5)]);
    expect(removed, [RichFormat.highlight]);

    // Kenardaki palet düğmesi ekranın içinde: dokununca palet levhası açılır.
    final palette = find.byKey(const ValueKey('format-color-palette'));
    expect(tester.getRect(palette).right, lessThanOrEqualTo(360));
    await tester.tap(palette);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('palette-custom-use')), findsOneWidget);
  });

  testWidgets('başlık ve yazı tepsileri satır içi açılır, ikinci dokunuş '
      'kapatır', (tester) async {
    await pumpNarrow(tester);
    await tester.tap(find.byKey(const ValueKey('format-heading')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('format-heading-h1')));
    expect(headings, [RichHeading.h1]);

    await tester.tap(find.byKey(const ValueKey('format-font')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('format-heading-h1')), findsNothing);
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
