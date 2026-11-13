import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/editor_quick_row.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Hızlı satırda etkin biçim basılı görünür (kullanıcı isteği 2026-11-13).
void main() {
  testWidgets('imleç kalın yazıdayken Kalın düğmesi basılı, değilken değil', (
    tester,
  ) async {
    final c = WrapTextController(text: 'düz **kalın** düz');
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final target = ValueNotifier<FormatTarget?>(
      FormatTarget(controller: c, focusNode: focus, commit: () {}),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EditorQuickRow(
            target: target,
            onBold: () {},
            onBullet: () {},
            onCheckbox: null,
            onHeading: () {},
            onPhoto: () {},
            onFile: () {},
            onPen: null,
            onPenSettings: null,
            onReminder: () {},
          ),
        ),
      ),
    );
    bool boldOn() {
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(const ValueKey('quick-row-bold')),
              matching: find.byType(Container),
            )
            .first,
      );
      return box.decoration != null;
    }

    c.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    expect(boldOn(), isFalse);
    c.selection = const TextSelection.collapsed(offset: 9);
    await tester.pump();
    expect(boldOn(), isTrue);
  });
}
