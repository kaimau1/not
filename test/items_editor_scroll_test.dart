import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void main() {
  testWidgets('Uzun listede satır üzerinden kaydırma listeyi kaydırır', (
    tester,
  ) async {
    final items = [
      for (var i = 0; i < 40; i++) NoteItem(id: 'i$i', text: 'Öğe $i'),
    ];
    await tester.pumpWidget(
      _wrap(ItemsEditor(items: items, onChanged: (_) {}, showCheckboxes: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Öğe 0'), findsOneWidget);
    // Satır başında artık sürükleme tutamacı YOK (yalnız "Seç" modunda gelir),
    // dolayısıyla satırın sol bölgesinden yapılan kaydırma listeyi kaydırır.
    await tester.fling(find.text('Öğe 0'), const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();

    expect(
      find.text('Öğe 0'),
      findsNothing,
      reason: 'satır üzerinden yapılan kaydırma listeyi kaydırmadı',
    );
  });

  testWidgets('Sürükleme tutamacı yalnız Seç modunda görünür', (tester) async {
    final items = [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek'),
    ];
    await tester.pumpWidget(
      _wrap(ItemsEditor(items: items, onChanged: (_) {}, showCheckboxes: true)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byIcon(Icons.drag_indicator),
      findsNothing,
      reason: 'tutamaç normal kipte satır başında yer kaplıyor',
    );

    // "Seç" artık editör ekranının alt çubuğunda (bkz. note_editor_screen);
    // düzenleyicinin genel giriş noktası aynı.
    tester.state<ItemsEditorState>(find.byType(ItemsEditor)).startSelection();
    await tester.pumpAndSettle();

    // Seç modunda her sıralanabilir satır tutamacını gösterir.
    expect(find.byIcon(Icons.drag_indicator), findsNWidgets(items.length));
  });

  testWidgets('sıralı listede de aynı seçim/sıralama/kopyalama vardır', (
    tester,
  ) async {
    // Checklist ve sıralı liste AYNI düzenleyiciyi kullanır; parite burada
    // doğrulanır ki sıralı liste sessizce geride kalmasın.
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );

    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: const [
            NoteItem(id: 'a', text: 'Un'),
            NoteItem(id: 'b', text: 'Şeker'),
          ],
          onChanged: (_) {},
          showCheckboxes: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    // "Seç" artık editör ekranının alt çubuğunda (bkz. note_editor_screen).
    tester.state<ItemsEditorState>(find.byType(ItemsEditor)).startSelection();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_indicator), findsNWidgets(2));

    await tester.tap(find.text('Şeker'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kopyala'));
    await tester.pumpAndSettle();

    // Sıralı listede kopya numaralı biçimde çıkar.
    expect(copied.single, '1. Şeker');
  });
}
