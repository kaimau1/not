import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/menu_layout.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/notes/presentation/folder_hold_button.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  home: Scaffold(body: Center(child: child)),
);

/// Kullanıcı isteği 2026-11-06: menüler düzenlenebilir; klasör düğmesi.
void main() {
  setUp(MenuLayouts.reset);

  const menu = ActionMenu(
    menuId: 'test.menu',
    quick: [
      MenuAction('a', 'Bir', Icons.star),
      MenuAction('b', 'İki', Icons.share),
    ],
    sections: [
      MenuSection('Grup', [
        MenuAction('c', 'Üç', Icons.copy),
        MenuAction('d', 'Dört', Icons.delete),
      ]),
    ],
  );

  testWidgets('menü: düzenle düğmesi var; gizlenen, hızlıya alınan, sıra', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SingleChildScrollView(child: menu)));
    expect(find.byKey(const ValueKey('menu-edit')), findsOneWidget);
    expect(find.text('Dört'), findsOneWidget);

    MenuLayouts.set(
      'test.menu',
      const MenuLayout(hidden: {'d'}, quick: ['c', 'a'], order: ['b']),
    );
    await tester.pump();
    expect(find.text('Dört'), findsNothing);
    // Hızlı satırdan çıkarılan "İki" kaybolmaz: "Diğer" grubunda.
    expect(find.text('İki'), findsOneWidget);
    expect(find.text('Diğer'), findsOneWidget);
    // Hızlı satır sırası: Üç, Bir.
    final dxC = tester.getCenter(find.text('Üç')).dx;
    final dxA = tester.getCenter(find.text('Bir')).dx;
    expect(dxC, lessThan(dxA));
  });

  testWidgets('menü düzenleyicisi: gözle gizle, kaydet', (tester) async {
    await tester.pumpWidget(_app(const SingleChildScrollView(child: menu)));
    await tester.tap(find.byKey(const ValueKey('menu-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-visible-c')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('menu-edit-save')));
    await tester.pumpAndSettle();
    expect(MenuLayouts.of('test.menu').hidden, {'c'});
    expect(find.text('Üç'), findsNothing);
  });

  test('basılı tutup kaydırma durağı uçlarda durur', () {
    expect(folderIndexForDrag(0, 80, 4), 2);
    expect(folderIndexForDrag(1, -200, 4), 0);
    expect(folderIndexForDrag(2, 500, 4), 3);
    expect(folderIndexForDrag(0, 10, 0), 0);
  });

  testWidgets('klasör düğmesi: dokun açar, basılı tut + kaydır seçer', (
    tester,
  ) async {
    var opened = 0;
    String? picked = 'yok';
    await tester.pumpWidget(
      _app(
        FolderHoldButton(
          stops: const [(null, 'Tümü'), ('f1', 'İş'), ('f2', 'Ev')],
          currentId: null,
          onOpen: () => opened++,
          onSelect: (id) => picked = id,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('folder-hold-button')));
    expect(opened, 1);

    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('folder-hold-button'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('folder-hold-strip')), findsOneWidget);
    await g.moveBy(const Offset(80, 0));
    await tester.pump();
    await g.up();
    await tester.pump();
    expect(picked, 'f2');
    expect(opened, 1);
  });
}
