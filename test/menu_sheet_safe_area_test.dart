import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/menu_layout.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı bulgusu 2026-11-14: uzun not menüsünde başlık, ⚙ ve ✕ telefonun
/// durum çubuğuyla çakışıyordu; levhada tutamak yoktu (aşağı çekilemiyordu).
/// Tek gruplu menüde hızlı satırdan düşen madde ayrı "Diğer" grubu açmaz.
void main() {
  setUp(MenuLayouts.reset);

  testWidgets('uzun menü levhası durum çubuğunun altında; tutamaklı', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.reset);
    final menu = ActionMenu(
      title: 'Uzun not',
      quick: const [MenuAction('a', 'Bir', Icons.star)],
      sections: [
        MenuSection('Grup', [
          for (var i = 0; i < 30; i++)
            MenuAction('x$i', 'Madde $i', Icons.circle_outlined),
        ]),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showActionMenuSheet(context, menu),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(BottomSheet)).dy,
      greaterThanOrEqualTo(40),
    );
    expect(tester.getTopLeft(find.text('Uzun not')).dy, greaterThan(40));
    // Tutamak: Material'in sürükleme tutamağı "kapat" anlamı taşır.
    final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(bottomSheet.showDragHandle, isTrue);
  });

  testWidgets('tek gruplu menüde öksüz madde grubun sonunda', (tester) async {
    MenuLayouts.set('t', const MenuLayout(quick: ['a']));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ActionMenu(
              menuId: 't',
              quick: [
                MenuAction('a', 'Bir', Icons.star),
                MenuAction('b', 'Arşiv', Icons.archive_outlined),
              ],
              sections: [
                MenuSection('Uygulama', [
                  MenuAction('c', 'Tema', Icons.palette_outlined),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Diğer'), findsNothing);
    expect(find.text('Arşiv'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Arşiv')).dy,
      tester.getTopLeft(find.text('Tema')).dy,
    );
  });
}
