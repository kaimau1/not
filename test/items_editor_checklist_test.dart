import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('İşaretlenen öğe işaretsizlerin altına iner', (tester) async {
    List<NoteItem>? latest;
    final items = [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta'),
    ];
    await tester.pumpWidget(_wrap(ItemsEditor(
      items: items,
      onChanged: (updated) => latest = updated,
      showCheckboxes: true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(latest!.map((i) => i.text).toList(), ['Ekmek', 'Yumurta', 'Süt']);
    expect(latest!.last.checked, isTrue);
  });

  testWidgets('En son işaretlenen, işaretlilerin EN ÜSTÜnde olur',
      (tester) async {
    List<NoteItem>? latest;
    // 'c' zaten işaretli ve altta; 'a' işaretlenince onun ÜSTÜne girmeli.
    final items = [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta', checked: true),
    ];
    await tester.pumpWidget(_wrap(ItemsEditor(
      items: items,
      onChanged: (updated) => latest = updated,
      showCheckboxes: true,
    )));
    await tester.pumpAndSettle();

    // İlk işaretsiz satırın kutusu = 'Süt'.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(latest!.map((i) => i.text).toList(), ['Ekmek', 'Süt', 'Yumurta']);
  });

  testWidgets('İşaretlileri sil tüm işaretli öğeleri kaldırır', (tester) async {
    List<NoteItem>? latest;
    final items = [
      NoteItem(id: 'a', text: 'Süt', checked: true),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta', checked: true),
    ];
    await tester.pumpWidget(_wrap(ItemsEditor(
      items: items,
      onChanged: (updated) => latest = updated,
      showCheckboxes: true,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('İşaretlileri sil'), findsOneWidget);
    await tester.tap(find.textContaining('İşaretlileri sil'));
    await tester.pumpAndSettle();

    expect(latest!.map((i) => i.text).toList(), ['Ekmek']);
  });

  testWidgets('Dışarıdan eklenen öğe ANINDA ekranda görünür', (tester) async {
    // Regresyon: dikte/hesap makinesi/AI bir öğe eklediğinde didUpdateWidget
    // yerel listeyi yenilemiyordu; öğe ancak editör kapanıp açılınca
    // görünüyordu ("söylediğim yazılmıyor, geri gelince beliriyor").
    var items = [NoteItem(id: 'a', text: 'Süt')];
    late StateSetter rebuild;

    await tester.pumpWidget(_wrap(StatefulBuilder(
      builder: (context, setState) {
        rebuild = setState;
        return ItemsEditor(
          items: items,
          onChanged: (updated) => items = updated,
          showCheckboxes: true,
        );
      },
    )));
    await tester.pumpAndSettle();
    expect(find.text('Ekmek'), findsNothing);

    // Dışarıdan (dikte gibi) yeni öğe eklendi.
    rebuild(() => items = [...items, NoteItem(id: 'b', text: 'Ekmek')]);
    await tester.pumpAndSettle();

    expect(find.text('Ekmek'), findsOneWidget);
  });
}
