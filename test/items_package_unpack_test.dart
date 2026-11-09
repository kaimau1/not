import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// 2026-11-09: paketten çıkarmak zordu — hapta ve açık paketin ilk
/// maddesinde × paketi çözer, maddeler yerinde kalır.
void main() {
  Future<List<NoteItem>> Function() setup(WidgetTester tester) {
    var current = [
      const NoteItem(id: 'a', text: 'bir'),
      const NoteItem(id: 'b', text: 'iki', package: 'p'),
      const NoteItem(id: 'c', text: 'uc', package: 'p'),
      const NoteItem(id: 'd', text: 'dort'),
    ];
    return () async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: ItemsEditor(
                  items: current,
                  onChanged: (next) => setState(() => current = next),
                  showCheckboxes: true,
                  shrinkWrap: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return current;
    };
  }

  testWidgets('kapalı haptaki × paketi çözer', (tester) async {
    final pump = setup(tester);
    await pump();
    expect(find.byKey(const ValueKey('note-package-pill')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-package-unpack')));
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const ValueKey('note-package-pill')), findsNothing);
    final state = tester.state<ItemsEditorState>(find.byType(ItemsEditor));
    expect(state.debugItems.map((i) => i.package), everyElement(''));
    expect(state.debugItems.map((i) => i.id), ['a', 'b', 'c', 'd']);
  });

  testWidgets('açık paketin ilk maddesindeki × de çözer', (tester) async {
    final pump = setup(tester);
    await pump();
    await tester.tap(find.byKey(const ValueKey('note-package-pill')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-package-unpack')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-package-unpack')));
    await tester.pump(const Duration(seconds: 4));
    final state = tester.state<ItemsEditorState>(find.byType(ItemsEditor));
    expect(state.debugItems.map((i) => i.package), everyElement(''));
  });
}
