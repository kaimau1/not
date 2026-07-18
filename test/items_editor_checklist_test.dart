import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('İşaretlenen öğe listenin en altına düşer (madde 10)',
      (tester) async {
    List<NoteItem>? latest;
    final items = [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta'),
    ];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ItemsEditor(
          items: items,
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // İlk öğeyi (Süt) işaretle → en alta düşmeli.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(latest, isNotNull);
    expect(latest!.last.text, 'Süt');
    expect(latest!.last.checked, isTrue);
    // Diğerleri sırasını korur.
    expect(latest!.map((i) => i.text).toList(), ['Ekmek', 'Yumurta', 'Süt']);
  });

  testWidgets('İşaretlileri sil tüm işaretli öğeleri kaldırır (madde 18)',
      (tester) async {
    List<NoteItem>? latest;
    final items = [
      NoteItem(id: 'a', text: 'Süt', checked: true),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta', checked: true),
    ];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ItemsEditor(
          items: items,
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // "İşaretlileri sil (2)" düğmesi görünür olmalı.
    expect(find.textContaining('İşaretlileri sil'), findsOneWidget);
    await tester.tap(find.textContaining('İşaretlileri sil'));
    await tester.pumpAndSettle();

    expect(latest, isNotNull);
    expect(latest!.map((i) => i.text).toList(), ['Ekmek']);
  });
}
