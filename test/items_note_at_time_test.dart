import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Videonun "Bu ana not al" düğmesi liste notunda DAMGALI MADDE açar
/// (kullanıcı isteği 2026-10-16).
void main() {
  Future<(GlobalKey<ItemsEditorState>, List<List<NoteItem>>)> pump(
    WidgetTester tester,
    List<NoteItem> items,
  ) async {
    final key = GlobalKey<ItemsEditorState>();
    final changes = <List<NoteItem>>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: ItemsEditor(
            key: key,
            items: items,
            onChanged: changes.add,
            showCheckboxes: true,
          ),
        ),
      ),
    );
    await tester.pump();
    return (key, changes);
  }

  testWidgets('sona damgalı madde açılır, imleç damganın ardında', (
    tester,
  ) async {
    final (key, changes) = await pump(tester, [
      NoteItem(id: 'a', text: 'giriş'),
    ]);
    key.currentState!.addItemWithText('1:23 ');
    await tester.pumpAndSettle();
    expect([for (final i in changes.last) i.text], ['giriş', '1:23 ']);
    final field = tester.widget<EditableText>(find.byType(EditableText).last);
    expect(field.focusNode.hasFocus, isTrue);
    expect(field.controller.selection.baseOffset, 5);
  });

  testWidgets('sondaki BOŞ madde kullanılır (boş satır birikmez)', (
    tester,
  ) async {
    final (key, changes) = await pump(tester, [
      NoteItem(id: 'a', text: 'giriş'),
      NoteItem(id: 'b', text: ''),
    ]);
    key.currentState!.addItemWithText('0:42 ');
    await tester.pumpAndSettle();
    expect([for (final i in changes.last) i.text], ['giriş', '0:42 ']);
    expect(changes.last.last.id, 'b');
  });
}
