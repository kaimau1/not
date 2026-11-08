import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı isteği 2026-11-08: madde seçiminde geri tuşu seçimi kapatır;
/// seçim çubuğundaki "Pakete al" seçilenleri tek pakette toplar.
void main() {
  Future<(GlobalKey<ItemsEditorState>, List<NoteItem> Function())> pump(
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var items = const [
      NoteItem(id: 'a', text: 'süt'),
      NoteItem(id: 'b', text: 'ekmek'),
      NoteItem(id: 'c', text: 'yumurta'),
    ];
    final key = GlobalKey<ItemsEditorState>();
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: const Scaffold(body: Text('ana')),
      ),
    );
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return ItemsEditor(
                key: key,
                items: items,
                onChanged: (next) => rebuild(() => items = next),
                showCheckboxes: true,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (key, () => items);
  }

  testWidgets('geri tuşu seçimi kapatır, notu değil', (tester) async {
    final (key, _) = await pump(tester);
    key.currentState!.startSelection();
    await tester.pumpAndSettle();
    await tester.tap(find.text('süt'));
    await tester.pumpAndSettle();
    expect(key.currentState!.isSelecting, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(key.currentState!.isSelecting, isFalse);
    expect(find.text('süt'), findsOneWidget, reason: 'sayfa kapanmadı');
    expect(tester.takeException(), isNull);
  });

  testWidgets('seçim çubuğundan Pakete al', (tester) async {
    final (key, items) = await pump(tester);
    key.currentState!.startSelection();
    await tester.pumpAndSettle();
    await tester.tap(find.text('süt'));
    await tester.tap(find.text('yumurta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('items-package')));
    await tester.pumpAndSettle();
    final pkgs = {for (final i in items()) i.text: i.package};
    expect(pkgs['süt'], isNotEmpty);
    expect(pkgs['süt'], pkgs['yumurta']);
    expect(pkgs['ekmek'], isEmpty);
    expect(key.currentState!.isSelecting, isFalse);
    expect(tester.takeException(), isNull);
  });
}
