import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';
import 'package:notlar/features/notes/presentation/listening_visuals.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı listesi 2026-10-20: kompakt menüler, ortak dinleme görünümü,
/// klavyede küçülen video.
void main() {
  Widget app(Widget home) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('not menüsünün grupları telefonda ÜÇ sütun simge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: ActionMenu(
            quick: [],
            sections: [
              MenuSection('Araçlar', [
                MenuAction('a', 'Bir', Icons.abc),
                MenuAction('b', 'İki', Icons.abc),
                MenuAction('c', 'Üç', Icons.abc),
                MenuAction('d', 'Dört', Icons.abc),
              ]),
            ],
          ),
        ),
      ),
    );
    double top(String id) =>
        tester.getTopLeft(find.byKey(ValueKey('menu-tile-$id'))).dy;
    expect(top('a'), top('b'));
    expect(top('b'), top('c'));
    expect(top('d'), greaterThan(top('a')), reason: 'dördüncü alt satırda');
  });

  testWidgets('küçülen pencere çocuğu kırpmaz, ölçekler', (tester) async {
    final sizes = <Size>[];
    Widget window(double visible) => app(
      Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: KeyboardClipWindow(
              full: 180,
              visible: visible,
              shrink: true,
              child: LayoutBuilder(
                builder: (context, c) {
                  sizes.add(c.biggest);
                  return const ColoredBox(
                    key: ValueKey('media'),
                    color: Colors.red,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(window(180));
    await tester.pumpWidget(window(90));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(const ValueKey('media')));
    // Yarı boy: görüntü yarıya iner, ortalanır (kırpılmaz).
    expect(rect.height, closeTo(90, 0.5));
    expect(rect.width, closeTo(160, 0.5));
    // Çocuk yeniden ölçülmedi.
    expect(sizes.map((s) => s.height).toSet(), {180});
    await tester.pumpWidget(window(180));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('media'))).height,
      closeTo(180, 0.5),
    );
  });

  testWidgets('dinleme rozeti ve etiketi kipe göre ayrışır', (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: Column(
            children: [
              ListeningBadge(mode: ListeningMode.ai, active: false),
              ListeningModeTag(mode: ListeningMode.ai),
              ListeningBadge(mode: ListeningMode.dictation, active: false),
              ListeningModeTag(mode: ListeningMode.dictation),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Yapay zekâ'), findsOneWidget);
    expect(find.text('Doğrudan yazım'), findsOneWidget);
    // Yapay zekâ rozetinde yıldız var, doğrudan yazımda yok.
    expect(
      find.descendant(
        of: find.byType(ListeningBadge).first,
        matching: find.byIcon(Icons.auto_awesome),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ListeningBadge).last,
        matching: find.byIcon(Icons.auto_awesome),
      ),
      findsNothing,
    );
  });
}
