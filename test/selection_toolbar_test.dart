import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/selection_toolbar.dart';
import 'package:notlar/features/notes/presentation/editor/tag_tap.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: AppNoticeHost(child: Scaffold(body: child)),
  );

  testWidgets('NoteSelectionToolbar: pano eylemleri, hızlı biçim ve ⋯ açılır', (
    tester,
  ) async {
    final ctl = WrapTextController(text: 'Merhaba dünya')
      ..selection = const TextSelection(baseOffset: 0, extentOffset: 7);
    addTearDown(ctl.dispose);
    var committed = 0;

    await tester.pumpWidget(
      wrap(
        TextField(
          controller: ctl,
          autofocus: true,
          contextMenuBuilder: (context, state) => NoteSelectionToolbar(
            editableState: state,
            formatController: ctl,
            onFormatCommit: () => committed++,
            buttonItems: arrangeSelectionMenu(
              platform: cleanClipboardMenuItems(state),
              afterClipboard: [
                ContextMenuButtonItem(label: 'Ek göm', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    editable.userUpdateTextEditingValue(
      TextEditingValue(
        text: ctl.text,
        selection: const TextSelection(baseOffset: 0, extentOffset: 7),
      ),
      SelectionChangedCause.longPress,
    );
    editable.showToolbar();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('note-selection-toolbar')),
      findsOneWidget,
    );
    expect(find.text('Kopyala'), findsOneWidget);
    expect(find.text('Kes'), findsOneWidget);
    expect(find.text('Tümünü seç'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sel-fmt-bold')));
    await tester.pumpAndSettle();
    expect(ctl.logicalText, '**Merhaba** dünya');
    expect(committed, 1);

    await tester.tap(find.byKey(const ValueKey('selection-toolbar-more')));
    await tester.pumpAndSettle();
    expect(find.text('Ek göm'), findsOneWidget);
  });

  testWidgets(
    'NoteSelectionToolbar: Kopyala panoya biçimsiz temiz metin yazar',
    (tester) async {
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
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final ctl = WrapTextController(text: '**kalın** test')
        ..selection = const TextSelection(baseOffset: 0, extentOffset: 9);
      addTearDown(ctl.dispose);

      await tester.pumpWidget(
        wrap(
          TextField(
            controller: ctl,
            autofocus: true,
            contextMenuBuilder: (context, state) => NoteSelectionToolbar(
              editableState: state,
              buttonItems: arrangeSelectionMenu(
                platform: cleanClipboardMenuItems(state),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pump();
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      editable.userUpdateTextEditingValue(
        TextEditingValue(
          text: ctl.text,
          selection: const TextSelection(baseOffset: 0, extentOffset: 9),
        ),
        SelectionChangedCause.longPress,
      );
      editable.showToolbar();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Kopyala'));
      await tester.pumpAndSettle();
      expect(copied, 'kalın');
    },
  );

  testWidgets(
    'ItemsEditor: aralık seçimi, ters çevirme, toplu biçim ve geri al',
    (tester) async {
      var items = const [
        NoteItem(id: 'a', text: 'bir'),
        NoteItem(id: 'b', text: 'iki'),
        NoteItem(id: 'c', text: 'üç'),
        NoteItem(id: 'd', text: 'dört'),
      ];
      final key = GlobalKey<ItemsEditorState>();
      late StateSetter rebuild;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return ItemsEditor(
                key: key,
                items: items,
                showCheckboxes: true,
                onChanged: (next) => rebuild(() => items = next),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      key.currentState!.startSelection();
      await tester.pumpAndSettle();

      await tester.tap(find.text('bir'), warnIfMissed: false);
      await tester.tap(find.text('üç'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('2 madde seçildi'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('items-range-select')));
      await tester.pumpAndSettle();
      expect(find.text('3 madde seçildi'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('items-invert-select')));
      await tester.pumpAndSettle();
      expect(find.text('1 madde seçildi'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('items-batch-format')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('items-batch-bold')));
      await tester.pumpAndSettle();
      expect(items.last.text, '**dört**');

      await tester.tap(find.byTooltip('Sil'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(items, hasLength(3));

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(items, hasLength(4));
    },
  );
}
