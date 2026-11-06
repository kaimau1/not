import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_commands.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F28.5: ⋮ menüsü "rayda zaten var" diye Ayarlar'ı saklıyordu; ray not
/// açıkken çekmece, tam ekranda gizli → web'de menüde Ayarlar yoktu.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Probe extends StatelessWidget {
  const _Probe(this.name);
  final String name;

  @override
  Widget build(BuildContext context) =>
      Text('$name:${AppRailScope.visible(context)}');
}

const _paths = ['/settings', '/ai', '/archive', '/trash', '/guide'];
const _l10nGoHome = 'Ana sayfaya dön';

/// Üst çubuğu olan sahte ekran: gerçek ekranlar gibi çubuğunu [HomeInBar] sarar.
Widget _page(String path) => hasHomeInBar(path)
    ? Scaffold(
        appBar: HomeInBar(appBar: AppBar(title: Text('PAGE $path'))),
      )
    : Text('PAGE $path');

Future<GoRouter> _pump(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (c, s, child) => AppFrame(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const Text('HOME')),
          for (final p in [..._paths, '/x'])
            GoRoute(path: p, builder: (c, s) => _page(p)),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      authRepositoryProvider.overrideWithValue(_NoAuth()),
      currentUidProvider.overrideWithValue(null),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(null),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  return router;
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  testWidgets('geniş ekran: her ekrandan ray düğmesi ana sayfaya döner', (
    tester,
  ) async {
    final router = await _pump(tester, const Size(1400, 900));
    for (final p in _paths) {
      unawaited(router.push(p));
      await tester.pump(const Duration(seconds: 1));
      // K4: ayrı 🏠 yok, "Notlar" hedefi ana sayfa.
      expect(find.byIcon(Icons.home_outlined), findsNothing);
      await tester.tap(find.byIcon(Icons.sticky_note_2_outlined));
      await tester.pump(const Duration(seconds: 1));
      expect(router.state.uri.path, '/');
    }
    await _end(tester);
  });

  testWidgets('dar web, üst çubuğu olmayan ekran: şerit ana sayfaya döner', (
    tester,
  ) async {
    homeBarOnNarrow = true;
    addTearDown(() => homeBarOnNarrow = false);
    final router = await _pump(tester, const Size(420, 800));
    expect(find.byKey(const ValueKey('narrow-home')), findsNothing);
    // '/x' çubuksuz sayılır (kHomeInBarLocations dışında).
    unawaited(router.push('/x'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_l10nGoHome), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('narrow-home')));
    await tester.pump(const Duration(seconds: 1));
    expect(router.state.uri.path, '/');
    expect(find.byKey(const ValueKey('narrow-home')), findsNothing);
    await _end(tester);
  });

  testWidgets('dar web, üst çubuklu ekran: 🏠 çubukta, şerit yok (K5)', (
    tester,
  ) async {
    homeBarOnNarrow = true;
    addTearDown(() => homeBarOnNarrow = false);
    final router = await _pump(tester, const Size(420, 800));
    unawaited(router.push('/settings'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_l10nGoHome), findsNothing);
    expect(find.byKey(const ValueKey('narrow-home')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('narrow-home')));
    await tester.pump(const Duration(seconds: 1));
    expect(router.state.uri.path, '/');
    await _end(tester);
  });

  test('çubuğu 🏠 taşıyan her konumun ekranı HomeInBar kullanır', () {
    // Liste ile ekranlar ayrışırsa dar web'de ev düğmesi kaybolur.
    const screens = {
      '/settings': 'settings/presentation/settings_screen.dart',
      '/personalize': 'settings/presentation/personalize_screen.dart',
      '/privacy': 'settings/presentation/privacy_screen.dart',
      '/guide': 'settings/presentation/guide_screen.dart',
      '/gmail': 'gmail/presentation/gmail_screen.dart',
      '/premium': 'settings/presentation/premium_screen.dart',
      '/ai': 'ai/presentation/ai_hub_screen.dart',
      '/chat': 'ai/presentation/ai_chat_screen.dart',
      '/briefing': 'ai/presentation/briefing_screen.dart',
      '/cards': 'notes/presentation/study_cards_screen.dart',
      '/calendar': 'calendar/presentation/calendar_screen.dart',
      '/tasks': 'calendar/presentation/tasks_screen.dart',
      '/reminders': 'notes/presentation/reminders_screen.dart',
      '/archive': 'notes/presentation/archive_screen.dart',
      '/trash': 'notes/presentation/trash_screen.dart',
      '/folders': 'folders/presentation/folders_screen.dart',
      '/inbox': 'inbox/presentation/shared_hub_screen.dart',
      '/note/': 'notes/presentation/editor/note_editor_screen.dart',
      '/notebook/': 'notes/presentation/editor/note_editor_screen.dart',
      '/open/': 'notes/presentation/editor/note_editor_screen.dart',
    };
    expect(kHomeInBarLocations.toSet(), screens.keys.toSet());
    for (final path in screens.values.toSet()) {
      final source = File('lib/features/$path').readAsStringSync();
      // Biçimlendirici `appBar:`ı alt satıra alabilir.
      expect(
        RegExp(r'HomeInBar\(\s*appBar:').hasMatch(source),
        isTrue,
        reason: path,
      );
    }
  });

  testWidgets('telefon (web değil): çubuk yok', (tester) async {
    final router = await _pump(tester, const Size(420, 800));
    unawaited(router.push('/settings'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('narrow-home')), findsNothing);
    await _end(tester);
  });

  testWidgets('ray yalnız yuvalıyken menüden kapı düşer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (c, s, child) => AppFrame(child: child),
          routes: [
            GoRoute(path: '/', builder: (c, s) => const _Probe('home')),
            GoRoute(path: '/note/:id', builder: (c, s) => const _Probe('note')),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        authRepositoryProvider.overrideWithValue(_NoAuth()),
        currentUidProvider.overrideWithValue(null),
        updateRequiredProvider.overrideWithValue(false),
        notesRepositoryProvider.overrideWithValue(null),
        attachmentRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('home:true'), findsOneWidget);

    router.go('/note/n1');
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining(':false'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
