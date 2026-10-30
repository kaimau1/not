import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı isteği 2026-10-30: seçim çubuğunda "Kopyala ve işaretle".
void main() {
  testWidgets('seçilenler kopyalanır ve işaretlenir', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
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
        home: Scaffold(
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
    key.currentState!.startSelection();
    await tester.pumpAndSettle();
    await tester.tap(find.text('süt'));
    await tester.tap(find.text('yumurta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('seçildi'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('items-copy-check')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final checked = {
      for (final i in items)
        if (i.checked) i.text,
    };
    expect(checked, {'süt', 'yumurta'});
    expect(copied, allOf(contains('süt'), contains('yumurta')));
    expect(copied, isNot(contains('ekmek')));
    expect(find.byKey(const ValueKey('items-copy-check')), findsNothing);
  });
}
