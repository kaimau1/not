import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_commands.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// DENEYIM F80.3d (OTURTMA F67.7): kısayol yardımı (Ctrl+/) elle tutulan bir
/// liste değil, bağlamayla aynı tablodan ([kAppShortcuts]) üretilir.
void main() {
  test('tuş yazısı tuşun kendisinden çıkar', () {
    expect(
      describeShortcut(const [
        SingleActivator(LogicalKeyboardKey.keyN, control: true),
      ]),
      'Ctrl + N',
    );
    expect(
      describeShortcut(const [
        SingleActivator(LogicalKeyboardKey.arrowUp, alt: true),
        SingleActivator(LogicalKeyboardKey.arrowDown, alt: true),
      ]),
      'Alt + ↑ / ↓',
    );
    expect(
      describeShortcut(const [
        SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true),
      ]),
      'Ctrl + Shift + F',
    );
  });

  test('her kimlik tabloda bir kez; tuşlar çakışmaz', () {
    final ids = [for (final r in kAppShortcuts) r.id];
    // Ctrl+W web'de tabloda yok; testler web dışında koşar.
    expect(ids.toSet(), AppShortcutId.values.toSet());
    expect(ids, hasLength(ids.toSet().length));
    final keys = [
      for (final r in kAppShortcuts)
        for (final k in r.keys) (k.trigger, k.control, k.alt, k.shift),
    ];
    expect(keys, hasLength(keys.toSet().length));
  });

  testWidgets('yardım satırları tablodan, eski yazılarla aynı', (tester) async {
    late List<({String keys, String label})> rows;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            rows = shortcutHelpRows(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(rows, hasLength(kAppShortcuts.length));
    final keys = [for (final r in rows) r.keys];
    expect(
      keys,
      containsAllInOrder(<String>[
        'Ctrl + N',
        'Ctrl + K',
        'Ctrl + \\',
        'Ctrl + ,',
        'Alt + 1…8',
        'Alt + Home',
        'Ctrl + Shift + F',
        'Esc',
        'Alt + ↑ / ↓',
        'Alt + ← / →',
      ]),
    );
    expect(keys, contains(startsWith('Ctrl + ')));
    expect(keys, containsAll(['Ctrl + A', 'Delete', 'Ctrl + W', 'Ctrl + /']));
    for (final r in rows) {
      expect(r.label, isNotEmpty);
      expect(r.keys, isNotEmpty);
    }
  });

  testWidgets(
    'AppShortcuts Ctrl+/, Ctrl+Shift+/ ve Ctrl+NumpadDivide ile yardım açar',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => AppShortcuts(
              onToggleList: () {},
              child: const Scaffold(
                body: Center(
                  child: Focus(autofocus: true, child: Text('host')),
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> triggerAndClose(
        List<LogicalKeyboardKey> mods,
        LogicalKeyboardKey key,
      ) async {
        for (final m in mods) {
          await tester.sendKeyDownEvent(m);
        }
        await tester.sendKeyEvent(key);
        for (final m in mods.reversed) {
          await tester.sendKeyUpEvent(m);
        }
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      }

      await triggerAndClose(const [
        LogicalKeyboardKey.controlLeft,
      ], LogicalKeyboardKey.slash);
      await triggerAndClose(const [
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.shiftLeft,
      ], LogicalKeyboardKey.slash);
      await triggerAndClose(const [
        LogicalKeyboardKey.controlLeft,
      ], LogicalKeyboardKey.numpadDivide);
    },
  );
}
