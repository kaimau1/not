import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı bulgusu 2026-10-30 ikinci tur: "imleç kelime satır tümü hepsi
/// aynı şeyi yapıyor" — ilk kapsamın açtığı seçim sonrakileri kilitliyordu.
/// 2026-11-05: kapsam seçimi geçici (yalnız biçim uygulanırken).
void main() {
  testWidgets('kapsamlar arasında geçiş imleçten yeniden hesaplanır', (
    tester,
  ) async {
    final controller = WrapTextController(text: 'abc def\nghi');
    final focus = FocusNode();
    addTearDown(focus.dispose);
    controller.selection = const TextSelection.collapsed(offset: 5);
    final seen = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                controller: controller,
                focusNode: focus,
                maxLines: null,
              ),
              FormatBar(
                target: FormatTarget(
                  controller: controller,
                  focusNode: focus,
                  commit: () {},
                ),
                onFormat: (_, {colorIndex}) =>
                    seen.add(controller.selection.textInside(controller.text)),
                onClearFormat: () {},
                onRemoveFormat: (_) {},
                fontFamily: null,
                fontScale: 1,
                textOpacity: 1,
                hasSelection: () => !controller.selection.isCollapsed,
                onFontChanged: (_) {},
                onScaleChanged: (_) {},
                onScaleEnd: (_) {},
                onOpacityChanged: (_) {},
                onOpacityEnd: (_) {},
                onClose: () {},
              ),
            ],
          ),
        ),
      ),
    );
    // Kapsam hapı TEPSİ AÇMAZ, sırayla geçer (kullanıcı isteği 2026-11-05):
    // İmleç → Kelime → Satır → Tümü → İmleç.
    const labels = {
      'caret': 'İmleç',
      'word': 'Kelime',
      'line': 'Satır',
      'all': 'Tümü',
    };
    Future<void> scope(String name) async {
      for (
        var i = 0;
        i < 4 && find.text(labels[name]!).evaluate().isEmpty;
        i++
      ) {
        await tester.tap(find.byKey(const ValueKey('format-scope-menu')));
        await tester.pumpAndSettle();
      }
      expect(find.text(labels[name]!), findsOneWidget);
    }

    // Kapsam seçmek SEÇİM AÇMAZ (kullanıcı bulgusu 2026-11-05: seçili
    // kalan kelime yazmaya devam edince siliniyordu).
    await tester.tap(find.byKey(const ValueKey('format-scope-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Kelime'), findsOneWidget);
    expect(controller.selection, const TextSelection.collapsed(offset: 5));
    expect(find.byKey(const ValueKey('format-scope-line')), findsNothing);
    // Biçim uygulanırken kapsam imleçten açılır, iş bitince imleç döner.
    Future<String> boldScope() async {
      await tester.tap(find.byKey(const ValueKey('format-bold')));
      await tester.pump();
      return seen.removeLast();
    }

    expect(await boldScope(), 'def');
    expect(controller.selection, const TextSelection.collapsed(offset: 5));
    await scope('line');
    expect(await boldScope(), 'abc def');
    await scope('all');
    expect(await boldScope(), 'abc def\nghi');
    await scope('word');
    expect(await boldScope(), 'def');
    await scope('caret');
    expect(await boldScope(), '');
    expect(controller.selection, const TextSelection.collapsed(offset: 5));
    // Elle seçimde kapsam düğmesi "Seçim" der ve seçime dokunulmaz.
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.pumpAndSettle();
    expect(find.text('Seçim'), findsOneWidget);
    expect(await boldScope(), 'ab');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
    // Elle seçimde hapa basmak seçimi bırakır (imleç ucunda), son kapsam
    // geri gelir — "Seçim"de kilitli kalmaz.
    await tester.tap(find.byKey(const ValueKey('format-scope-menu')));
    await tester.pumpAndSettle();
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
    expect(find.text('İmleç'), findsOneWidget);
  });

  testWidgets('kapsam önizlemesi: kelime/satır soluk zeminle görünür', (
    tester,
  ) async {
    final controller = WrapTextController(text: 'abc def\nghi');
    final focus = FocusNode();
    addTearDown(focus.dispose);
    controller.selection = const TextSelection.collapsed(offset: 5);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: Column(
            children: [
              TextField(controller: controller, focusNode: focus),
              FormatBar(
                target: FormatTarget(
                  controller: controller,
                  focusNode: focus,
                  commit: () {},
                ),
                onFormat: (_, {colorIndex}) {},
                onClearFormat: () {},
                onRemoveFormat: (_) {},
                fontFamily: null,
                fontScale: 1,
                textOpacity: 1,
                hasSelection: () => false,
                onFontChanged: (_) {},
                onScaleChanged: (_) {},
                onScaleEnd: (_) {},
                onOpacityChanged: (_) {},
                onOpacityEnd: (_) {},
                onClose: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    List<String> shaded() {
      final context = tester.element(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: context,
        withComposing: false,
      );
      final out = <String>[];
      span.visitChildren((s) {
        if (s is TextSpan &&
            s.text != null &&
            s.style?.backgroundColor != null) {
          out.add(s.text!);
        }
        return true;
      });
      if (span.text != null && span.style?.backgroundColor != null) {
        out.add(span.text!);
      }
      return out;
    }

    // İmleç kipinde önizleme yok; hapa basınca Kelime görünür.
    expect(shaded(), isEmpty);
    await tester.tap(find.byKey(const ValueKey('format-scope-menu')));
    await tester.pumpAndSettle();
    expect(shaded().join(), 'def');
    await tester.tap(find.byKey(const ValueKey('format-scope-menu')));
    await tester.pumpAndSettle();
    expect(shaded().join(), 'abc def');
    // İmleç taşınınca önizleme izler.
    controller.selection = const TextSelection.collapsed(offset: 10);
    await tester.pumpAndSettle();
    expect(shaded().join(), 'ghi');
  });
}
