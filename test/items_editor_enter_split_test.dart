// Madde ortasında klavyenin Enter/"İleri" tuşu maddeyi imleçten böler
// (kullanıcı isteği 2026-10-28: "cümlenin arasında enter yapılınca oradan
// itibaren cümleyi bölüp yeni madde yapmalı").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<List<NoteItem>?> _enterAt(
  WidgetTester tester, {
  required String text,
  required int caret,
}) async {
  List<NoteItem>? latest;
  await tester.pumpWidget(
    _wrap(
      ItemsEditor(
        items: [NoteItem(id: 'a', text: text)],
        onChanged: (updated) => latest = updated,
        showCheckboxes: true,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final field = find.byType(TextField).first;
  await tester.tap(field);
  await tester.pump();
  final controller = tester.widget<TextField>(field).controller!;
  controller.selection = TextSelection.collapsed(offset: caret);
  await tester.pump();
  await tester.testTextInput.receiveAction(TextInputAction.next);
  await tester.pumpAndSettle();
  return latest;
}

void main() {
  testWidgets('ortadan Enter: sağdaki kısım yeni maddeye geçer', (
    tester,
  ) async {
    final latest = await _enterAt(tester, text: 'ekmek süt al', caret: 6);
    expect(latest!.map((i) => i.text).toList(), ['ekmek', 'süt al']);
    // İmleç yeni maddenin BAŞINDA.
    final second = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(second.focusNode!.hasFocus, isTrue);
    expect(second.controller!.selection.baseOffset, 0);
  });

  testWidgets('sonda Enter: altına boş madde açar', (tester) async {
    final latest = await _enterAt(tester, text: 'ekmek', caret: 5);
    expect(latest!.map((i) => i.text).toList(), ['ekmek', '']);
  });

  testWidgets('başta Enter: üstüne boş madde açar, madde bozulmaz', (
    tester,
  ) async {
    final latest = await _enterAt(tester, text: 'ekmek', caret: 0);
    expect(latest!.map((i) => i.text).toList(), ['', 'ekmek']);
  });
}
