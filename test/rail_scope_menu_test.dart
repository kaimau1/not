import 'dart:async';

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
          for (final p in _paths)
            GoRoute(path: p, builder: (c, s) => Text('PAGE $p')),
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
      await tester.tap(find.byKey(const ValueKey('rail-home')));
      await tester.pump(const Duration(seconds: 1));
      expect(router.state.uri.path, '/');
    }
    await _end(tester);
  });

  testWidgets('dar web: üst çubuk ana sayfaya döner, ana sayfada yok', (
    tester,
  ) async {
    homeBarOnNarrow = true;
    addTearDown(() => homeBarOnNarrow = false);
    final router = await _pump(tester, const Size(420, 800));
    expect(find.byKey(const ValueKey('narrow-home')), findsNothing);
    for (final p in _paths) {
      unawaited(router.push(p));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('narrow-home')));
      await tester.pump(const Duration(seconds: 1));
      expect(router.state.uri.path, '/');
      expect(find.byKey(const ValueKey('narrow-home')), findsNothing);
    }
    await _end(tester);
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
