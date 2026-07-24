import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Liste modunda görsel sarması: liste, serbest görsel tuvalinin içinde
/// kendi kaydırmasını yapmadan (shrinkWrap) durur ve madde metni görselin
/// bandında sarma çapası alır.
void main() {
  final pageKey = GlobalKey();

  Future<void> pumpList(
    WidgetTester tester,
    List<NoteItem> items,
    List<FloatBox> floats,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: KeyedSubtree(
              key: pageKey,
              child: ItemsEditor(
                items: items,
                onChanged: (_) {},
                showCheckboxes: false,
                shrinkWrap: true,
                floats: floats,
                pageBox: () {
                  final box = pageKey.currentContext?.findRenderObject();
                  return box is RenderBox && box.hasSize ? box : null;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('liste dis kaydiricinin icinde tasmadan kurulur', (tester) async {
    await pumpList(tester, [
      for (var i = 0; i < 30; i++) NoteItem(id: 'i$i', text: 'Oge $i'),
    ], const []);
    expect(tester.takeException(), isNull);
    expect(find.text('Oge 0'), findsOneWidget);
    // Kendi kaydiricisi yok: dis SingleChildScrollView tum listeyi uzatir,
    // yani listenin sonu da agacta kurulmus olur.
    expect(find.text('Oge 29'), findsOneWidget);
  });

  testWidgets('gorselin bandindaki madde sarma capasi alir', (tester) async {
    final items = [
      NoteItem(
        id: 'a',
        text: 'Bu madde epey uzun bir metin icerir ve gorselin yanindan '
            'akmasi beklenir cunku ust bantta duruyor',
      ),
      NoteItem(id: 'b', text: 'Asagidaki madde gorselden uzak'),
    ];
    // Sayfanin sol ust kosesinde genis bir gorsel: yalnizca ilk maddeyi keser.
    await pumpList(tester, items, const [
      FloatBox(top: 0, left: 0, right: 140, height: 40),
    ]);
    await tester.pump();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    final first = fields.first.controller! as WrapTextController;
    final second = fields[1].controller! as WrapTextController;

    expect(first.isPlain, isFalse, reason: 'ilk madde sarilmadi');
    expect(first.text.contains(kWrapAnchorChar), isTrue);
    // Nota giden metin capasizdir.
    expect(first.logicalText, items.first.text);
    // Gorselin bandinin disindaki madde dokunulmadan kalir.
    expect(second.isPlain, isTrue);
  });

  testWidgets('gorselin bandindaki satirin tutamaci gorselin altinda kalmaz', (
    tester,
  ) async {
    final items = [
      NoteItem(id: 'a', text: 'Ust madde'),
      NoteItem(id: 'b', text: 'Alt madde'),
    ];
    await pumpList(tester, items, const [
      FloatBox(top: 0, left: 0, right: 140, height: 40),
    ]);
    // Olcum kare sonunda yapilir; kaydirma bir sonraki karede uygulanir.
    await tester.pumpAndSettle();

    final handles = find.byIcon(Icons.drag_indicator);
    final firstX = tester.getTopLeft(handles.first).dx;
    final secondX = tester.getTopLeft(handles.at(1)).dx;
    expect(
      firstX,
      greaterThanOrEqualTo(140.0),
      reason: 'gorselin bandindaki satir yana kaymadi',
    );
    // Gorselin altindaki satir yerinde durur.
    expect(secondX, lessThan(140.0));
  });
}
