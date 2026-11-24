import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı bulgusu (2026-11-24, ekran görüntüsü): "tablo varken bir madde
/// sildiğimde tüm yazılar üstüne biniyor, tablo yokmuş gibi". KÖK NEDEN:
/// satırlar önbellekten aynı örnekle döndüğü için silinen maddenin altındaki
/// satırlar yukarı kayınca yeniden ÖLÇÜLMÜYORDU; tablonun altına itilmiş
/// satır silinince yerine gelen satır itmesiz (0) kalıp tablonun üstüne
/// biniyordu.
void main() {
  final pageKey = GlobalKey();
  const table = FloatBox(
    top: 100,
    left: 0,
    right: 800,
    height: 150,
    block: true,
  );

  Widget app(
    List<NoteItem> items, {
    ValueChanged<List<NoteItem>>? onChanged,
    bool checks = false,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: KeyedSubtree(
          key: pageKey,
          child: ItemsEditor(
            items: items,
            onChanged: onChanged ?? (_) {},
            showCheckboxes: checks,
            shrinkWrap: true,
            floats: const [table],
            pageBox: () {
              final box = pageKey.currentContext?.findRenderObject();
              return box is RenderBox && box.hasSize ? box : null;
            },
          ),
        ),
      ),
    ),
  );

  void expectClear(WidgetTester tester, Iterable<String> texts) {
    final page = tester.getTopLeft(find.byKey(pageKey)).dy;
    for (final t in texts) {
      final r = tester.getRect(find.text(t));
      final top = r.top - page;
      final bottom = r.bottom - page;
      expect(
        bottom <= table.top + 0.5 || top >= table.bottom - 0.5,
        isTrue,
        reason: '"$t" tablonun üstüne biniyor ($top..$bottom)',
      );
    }
  }

  testWidgets(
    'odaktaki madde x ile silinince satırlar tablonun altında kalır',
    (tester) async {
      var items = [
        for (var i = 0; i < 8; i++) NoteItem(id: 'm$i', text: 'Madde $i'),
        NoteItem(id: 'c', text: 'Bitti', checked: true),
      ];
      late StateSetter set;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, s) {
            set = s;
            return app(
              items,
              onChanged: (n) => set(() => items = n),
              checks: true,
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      for (final victim in ['m1', 'm0', 'm2']) {
        await tester.tap(
          find.text(items.firstWhere((i) => i.id == victim).text),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('item-remove-$victim')));
        await tester.pumpAndSettle();
        expectClear(tester, [
          for (final i in items)
            if (!i.checked) i.text,
        ]);
      }
    },
  );

  testWidgets('madde silinince alttaki satırlar tablonun altında kalır', (
    tester,
  ) async {
    final items = [
      for (var i = 0; i < 8; i++) NoteItem(id: 'm$i', text: 'Madde $i'),
    ];
    await tester.pumpWidget(app(items));
    await tester.pumpAndSettle();
    final texts = [for (final i in items) i.text];
    expectClear(tester, texts);

    // Tablonun altına itilen ilk satırı ve ondan öncekini sırayla sil.
    final page = tester.getTopLeft(find.byKey(pageKey)).dy;
    final pushed = items.firstWhere(
      (i) => tester.getRect(find.text(i.text)).top - page >= table.bottom - 1,
    );
    var left = [...items]..remove(pushed);
    await tester.pumpWidget(app(left));
    await tester.pumpAndSettle();
    expectClear(tester, [for (final i in left) i.text]);

    left = [...left]..removeAt(0);
    await tester.pumpWidget(app(left));
    await tester.pumpAndSettle();
    expectClear(tester, [for (final i in left) i.text]);
  });
}
