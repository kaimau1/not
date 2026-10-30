import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı bulgusu 2026-10-30 ikinci tur: "imleç kelime satır tümü hepsi
/// aynı şeyi yapıyor" — ilk kapsamın açtığı seçim sonrakileri kilitliyordu.
void main() {
  testWidgets('kapsamlar arasında geçiş imleçten yeniden hesaplanır', (
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
                onFormat: (_, {colorIndex}) {},
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
    String selected() => controller.selection.textInside(controller.text);
    Future<void> scope(String name) async {
      await tester.tap(find.byKey(ValueKey('format-scope-$name')));
      await tester.pump();
    }

    await scope('word');
    expect(selected(), 'def');
    await scope('line');
    expect(selected(), 'abc def');
    await scope('all');
    expect(selected(), 'abc def\nghi');
    await scope('word');
    expect(selected(), 'def');
    await scope('caret');
    expect(controller.selection, const TextSelection.collapsed(offset: 5));
    // Elle yapılan seçime kapsam dokunmaz.
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    await scope('line');
    expect(selected(), 'ab');
  });
}
