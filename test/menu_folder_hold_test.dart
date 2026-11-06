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

  test('yuvarlak menü: halkalar ve yönle seçim', () {
    expect(radialRings(3), [3]);
    expect(radialRings(8), [8]);
    expect(radialRings(11), [6, 5]);
    expect(radialRings(0), isEmpty);
    // Ölü bölge: seçim yok (bırakmak vazgeçer).
    expect(radialFolderIndex(const Offset(5, 5), 4), isNull);
    // 4 durak: tepe 0, sağ 1, alt 2, sol 3 — küçük kayma yeter.
    expect(radialFolderIndex(const Offset(0, -20), 4), 0);
    expect(radialFolderIndex(const Offset(20, 0), 4), 1);
    expect(radialFolderIndex(const Offset(0, 20), 4), 2);
    expect(radialFolderIndex(const Offset(-20, 0), 4), 3);
    // İki halka (11 → 6 + 5): uzak kayma dış halkaya.
    expect(radialFolderIndex(const Offset(0, -20), 11), 0);
    final outer = radialFolderIndex(const Offset(0, -120), 11)!;
    expect(outer, greaterThanOrEqualTo(6));
  });

  testWidgets('klasör düğmesi: dokun açar, basılı tut + kaydır seçer', (
    tester,
  ) async {
    var opened = 0;
    String? picked = 'yok';
    await tester.pumpWidget(
      _app(
        FolderHoldButton(
          stops: const [
            FolderStop(id: null, name: 'Tümü'),
            FolderStop(id: 'f1', name: 'İş', count: 3),
            FolderStop(id: 'f2', name: 'Ev'),
          ],
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
    expect(find.byKey(const ValueKey('folder-radial-menu')), findsOneWidget);
    expect(find.text('Bırak = vazgeç'), findsOneWidget);
    // 3 durak: tepe Tümü, sağ-alt İş, sol-alt Ev → sola-aşağı kaydır.
    await g.moveBy(const Offset(-20, 12));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(picked, 'f2');
    expect(opened, 1);
    expect(find.byKey(const ValueKey('folder-radial-menu')), findsNothing);
  });

  testWidgets('klasör düğmesi: ortada bırakmak vazgeçer', (tester) async {
    String? picked = 'yok';
    await tester.pumpWidget(
      _app(
        FolderHoldButton(
          stops: const [
            FolderStop(id: null, name: 'Tümü'),
            FolderStop(id: 'f1', name: 'İş'),
          ],
          currentId: null,
          onOpen: () {},
          onSelect: (id) => picked = id,
        ),
      ),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('folder-hold-button'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await g.moveBy(const Offset(4, 3));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(picked, 'yok');
  });
}
