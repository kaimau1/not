import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Seçim çubuğu (Kopyala/Sil) eskiden listenin header'ındaydı ve listeyle
/// birlikte kayıyordu: uzun listede aşağıdaki maddeleri seçtikten sonra
/// kopyalamak için başa dönmek gerekiyordu. Artık ekranın dibinde, kaydırmadan
/// bağımsız bir katmanda durur.
void main() {
  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ItemsEditor(
            items: [
              for (var i = 0; i < 40; i++) NoteItem(id: 'i$i', text: 'Öğe $i'),
            ],
            onChanged: (_) {},
            showCheckboxes: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Seçim kipini açar. "Seç" düğmesi artık düzenleyicinin İÇİNDE değil,
  /// editör ekranının alt çubuğunda (bkz. note_editor_screen); buradan aynı
  /// genel giriş noktası çağrılır.
  Future<void> startSelection(WidgetTester tester) async {
    tester.state<ItemsEditorState>(find.byType(ItemsEditor)).startSelection();
    await tester.pumpAndSettle();
  }

  testWidgets('seçim çubuğu listenin İÇİNDE değil, ekranın dibindedir', (
    tester,
  ) async {
    await pumpEditor(tester);
    await startSelection(tester);

    final copy = find.byTooltip('Kopyala');
    expect(copy, findsOneWidget);
    // Çubuk kayan listenin parçası OLMAMALI (regresyon koruması).
    expect(
      find.descendant(of: find.byType(ReorderableListView), matching: copy),
      findsNothing,
    );
    // Ekranın alt şeridinde durur (test yüzeyi 600 px yüksek).
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getCenter(copy).dy, greaterThan(screenHeight - 100));
  });

  testWidgets('liste başa kaydırılsa da çubuk yerinde kalır', (tester) async {
    await pumpEditor(tester);
    await startSelection(tester);
    final before = tester.getCenter(find.byTooltip('Kopyala'));

    // Listeyi yukarı (başa) kaydır: çubuk kaymamalı.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Kopyala'), findsOneWidget);
    expect(tester.getCenter(find.byTooltip('Kopyala')), before);
  });

  testWidgets('"Tümünü seç" bütün maddeleri seçer', (tester) async {
    await pumpEditor(tester);
    await startSelection(tester);

    await tester.tap(find.byTooltip('Tümünü seç'));
    await tester.pumpAndSettle();

    expect(find.text('40 madde seçildi'), findsOneWidget);
  });
}
