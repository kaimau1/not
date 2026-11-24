import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/format_menu.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(body: child),
  );

  test('richScopeRange ve scopeSelection rich işaretlerde kelimeyi bölmez', () {
    const italic = '_merhaba_ dünya';
    final sItalic = scopeSelection(
      italic,
      const TextSelection.collapsed(offset: 4),
      FormatScope.word,
    )!;
    expect(italic.substring(sItalic.start, sItalic.end), 'merhaba');

    const colored = '%%3:**kalın**%% son';
    final sColored = scopeSelection(
      colored,
      const TextSelection.collapsed(offset: 9),
      FormatScope.word,
    )!;
    expect(colored.substring(sColored.start, sColored.end), 'kalın');

    const sized = 'abc ##5:def## ghi';
    final sSized = scopeSelection(
      sized,
      const TextSelection.collapsed(offset: 9),
      FormatScope.word,
    )!;
    expect(sized.substring(sSized.start, sSized.end), 'def');

    const wrapped = '${kWrapAnchorChar}ilk _satır_\nikinci';
    final sLine = scopeSelection(
      wrapped,
      const TextSelection.collapsed(offset: 7),
      FormatScope.line,
    )!;
    expect(
      stripRichMarkers(wrapped.substring(sLine.start, sLine.end)),
      'ilk satır',
    );
  });

  testWidgets(
    'FormatBar: kelime kapsamında peş peşe B / I / Boyut+ / %100 sıfırlama imleci kaydırmaz',
    (tester) async {
      final ctl = WrapTextController(text: 'merhaba dünya')
        ..selection = const TextSelection.collapsed(offset: 3); // mer|haba
      final focus = FocusNode();
      addTearDown(ctl.dispose);
      addTearDown(focus.dispose);

      await tester.pumpWidget(
        wrap(
          Align(
            alignment: Alignment.bottomCenter,
            child: FormatBar(
              target: FormatTarget(
                controller: ctl,
                focusNode: focus,
                commit: () {},
              ),
              onFormat: (f, {colorIndex}) =>
                  applyRichFormat(ctl, f, colorIndex: colorIndex),
              onClearFormat: () => clearRichFormat(ctl),
              onRemoveFormat: (f) => removeRichFormat(ctl, f),
              fontFamily: null,
              fontScale: 1.0,
              textOpacity: 1.0,
              hasSelection: () => !ctl.selection.isCollapsed,
              onFontChanged: (_) {},
              onScaleChanged: (_) {},
              onScaleEnd: (v) {
                final step = richStepIndex(kRichSizeSteps, v);
                applyRichStep(
                  ctl,
                  RichFormat.size,
                  step == kRichSizeDefault ? null : step,
                );
              },
              onOpacityChanged: (_) {},
              onOpacityEnd: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kelime kapsamına geç (İmleç → Kelime: düğme doğrudan döngüyle geçer).
      await tester.tap(find.byKey(const ValueKey('format-scope-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Kelime'), findsOneWidget);

      Future<void> checkPlainCaret(int expected) async {
        expect(ctl.selection.isCollapsed, isTrue);
        expect(
          logicalToPlainOffset(ctl.logicalText, ctl.selection.baseOffset),
          expected,
        );
      }

      await tester.tap(find.byKey(const ValueKey('format-bold')));
      await tester.pumpAndSettle();
      expect(ctl.logicalText, '**merhaba** dünya');
      await checkPlainCaret(3);

      await tester.tap(find.byKey(const ValueKey('format-italic')));
      await tester.pumpAndSettle();
      expect(ctl.logicalText, '**_merhaba_** dünya');
      await checkPlainCaret(3);

      await tester.tap(find.byKey(const ValueKey('format-size-up')));
      await tester.pumpAndSettle();
      expect(ctl.logicalText, '##5:**_merhaba_**## dünya');
      await checkPlainCaret(3);
      expect(find.text('%120'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('format-size-reset')));
      await tester.pumpAndSettle();
      expect(ctl.logicalText, '**_merhaba_** dünya');
      await checkPlainCaret(3);
      expect(find.text('%100'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('format-clear')));
      await tester.pumpAndSettle();
      expect(ctl.logicalText, 'merhaba dünya');
      await checkPlainCaret(3);
    },
  );
}
