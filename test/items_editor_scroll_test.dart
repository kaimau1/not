import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('Uzun listede sürükleme tutamacından kaydırma listeyi kaydırır',
      (tester) async {
    final items = [
      for (var i = 0; i < 40; i++) NoteItem(id: 'i$i', text: 'Öğe $i'),
    ];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ItemsEditor(
          items: items,
          onChanged: (_) {},
          showCheckboxes: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Başlangıçta ilk öğe görünür, son öğe görünmez.
    expect(find.text('Öğe 0'), findsOneWidget);

    // Sürükleme tutamacının ÜZERİNDEN aşağı-yukarı kaydırma: eskiden yeniden
    // sıralamaya takılıp kaydırmıyordu; artık listeyi kaydırmalı.
    final handle = find.byIcon(Icons.drag_indicator).first;
    await tester.fling(handle, const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();

    // Kaydırma çalıştıysa ilk öğe artık ekranda değil (yukarı kaydı).
    expect(find.text('Öğe 0'), findsNothing,
        reason: 'Tutamaçtan yapılan kaydırma listeyi kaydırmadı');
  });
}
