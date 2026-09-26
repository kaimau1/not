import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// "+ Yeni öğe" düğmesi boş öğe BİRİKTİRMEZ (kullanıcı ekran görüntüsü
/// 2026-09-23) — ama tek boş öğeyle de sınırlamaz: üst üste en çok
/// [kMaxTrailingEmptyItems] boş öğe açılabilir (kullanıcı isteği 2026-09-26:
/// "1'den fazla yeni boş öğe eklenebilmeli, max 3 tane").
void main() {
  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  final addButton = find.widgetWithText(TextButton, 'Yeni öğe');

  test('sondaki boş öğe sayısı', () {
    NoteItem item(String text) => NoteItem(id: text, text: text);
    expect(trailingEmptyCount(const []), 0);
    expect(trailingEmptyCount([item('a')]), 0);
    expect(trailingEmptyCount([item('a'), item(''), item(' ')]), 2);
    expect(trailingEmptyCount([item(''), item('a'), item('')]), 1);
  });

  testWidgets('en çok üç boş öğe açılır', (tester) async {
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

    for (var i = 0; i < 5; i++) {
      await tester.tap(addButton);
      await tester.pumpAndSettle();
    }
    expect(latest, hasLength(1 + kMaxTrailingEmptyItems));
    expect(latest.first.id, 'a');
    expect(latest.skip(1).every((i) => i.text.isEmpty), isTrue);
  });

  testWidgets('sonda üç boş öğe varsa yenisi açılmaz', (tester) async {
    var latest = <NoteItem>[
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: ''),
      NoteItem(id: 'c', text: ''),
      NoteItem(id: 'd', text: ''),
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

    expect(latest.map((i) => i.id).toList(), ['a', 'b', 'c', 'd']);
  });
}
