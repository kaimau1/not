import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// "+ Yeni öğe" düğmesi boş öğe BİRİKTİRMEZ (kullanıcı ekran görüntüsü
/// 2026-09-23: listenin sonunda boş "Yeni öğe" satırı + altında düğme).
void main() {
  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  final addButton = find.widgetWithText(TextButton, 'Yeni öğe');

  testWidgets('sonda boş öğe varsa yenisi açılmaz', (tester) async {
    var latest = <NoteItem>[
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: ''),
    ];
    await tester.pumpWidget(
      wrap(
        ItemsEditor(
          items: latest,
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(latest.map((i) => i.id).toList(), ['a', 'b']);
  });

  testWidgets('son öğe doluysa düğme yeni öğe açar', (tester) async {
    var latest = <NoteItem>[NoteItem(id: 'a', text: 'Süt')];
    await tester.pumpWidget(
      wrap(
        ItemsEditor(
          items: latest,
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(latest, hasLength(2));
    // İkinci dokunuş: yeni açılan öğe hâlâ boş — ikinci bir boş öğe YOK.
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(latest, hasLength(2));
  });
}
