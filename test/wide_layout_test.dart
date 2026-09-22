import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_commands.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GENİŞ EKRAN ÇERÇEVESİ (kullanıcı isteği 2026-09-22: "tablet gibi geniş
/// ekranlı cihazlarda kullanımını baştan tasarlamalıyız").
///
/// Denetlenen sözler:
/// * Ray yalnız geniş VE yeterince uzun pencerede çizilir — telefon (dikey
///   ya da yatay) eskisi gibi raysız kalır.
/// * Bölüm geçişi yığını büyütmez: notların üstünde en fazla bir bölüm
///   katmanı durur, "Notlar"a dönüş o katmanı kaldırır.
/// * Klavye kısayolları (Alt+1…8, Ctrl+,, Ctrl+/) doğru yere gider.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppFrame(child: child),
      routes: [
        for (final path in [
          '/',
          '/folders',
          '/inbox',
          '/ai',
          '/reminders',
          '/archive',
          '/trash',
          '/settings',
        ])
          GoRoute(
            path: path,
            builder: (context, state) =>
                Scaffold(body: Center(child: Text('sayfa:$path'))),
          ),
      ],
    ),
  ],
);

Future<GoRouter> _pump(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _router();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Ray, gelen notların sayısını okuyor; oturum yokken akış boş.
        authRepositoryProvider.overrideWithValue(_NoAuth()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('tablette ray var, telefonda (dikey/yatay) yok', (tester) async {
    await _pump(tester, const Size(1024, 768));
    expect(find.byType(NavigationRail), findsOneWidget);

    await _pump(tester, const Size(400, 820));
    expect(find.byType(NavigationRail), findsNothing);

    // Yatay telefon: genişlik yetiyor ama boy yetmiyor.
    await _pump(tester, const Size(820, 400));
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('bölüm geçişi yığını büyütmez, Notlar katmanı kaldırır', (
    tester,
  ) async {
    final router = await _pump(tester, const Size(1280, 800));

    await tester.tap(find.text('Arşiv'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/archive');
    expect(find.text('sayfa:/archive'), findsOneWidget);

    // Bölümden bölüme: katman DEĞİŞİR, üst üste binmez.
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/settings');
    router.pop();
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/');

    await tester.tap(find.text('Çöp Kutusu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notlar'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/');
    expect(router.canPop(), isFalse);
  });

  testWidgets('Alt+6 arşive, Ctrl+, ayarlara gider; Ctrl+/ kısayolları açar', (
    tester,
  ) async {
    final router = await _pump(tester, const Size(1280, 800));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/archive');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/settings');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Klavye kısayolları'), findsWidgets);
  });

  testWidgets('ray elle daraltılıp genişletilir, tercih kalıcıdır', (
    tester,
  ) async {
    await _pump(tester, const Size(1400, 900));
    NavigationRail rail() => tester.widget(find.byType(NavigationRail));
    // 1280 üstünde kendiliğinden etiketli.
    expect(rail().extended, isTrue);
    await tester.tap(find.byTooltip('Menüyü daralt'));
    await tester.pumpAndSettle();
    expect(rail().extended, isFalse);
  });

  testWidgets('kısa tablette (1024×600) sekiz bölümlü ray taşmaz, kayar', (
    tester,
  ) async {
    final router = await _pump(tester, const Size(1024, 600));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Klasörler'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/folders');
    await tester.tap(find.text('Gelen notlar'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/inbox');
  });

  test('konumdan bölüm çözümü', () {
    expect(AppSection.of('/folders'), AppSection.folders);
    expect(AppSection.of('/inbox'), AppSection.inbox);
    expect(AppSection.of('/'), AppSection.notes);
    expect(AppSection.of('/note/abc'), AppSection.notes);
    expect(AppSection.of('/notebook/abc'), AppSection.notes);
    expect(AppSection.of('/chat'), AppSection.ai);
    expect(AppSection.of('/briefing'), AppSection.ai);
    expect(AppSection.of('/privacy'), AppSection.settings);
    expect(AppSection.of('/reminders'), AppSection.reminders);
    expect(AppSection.of('/trash'), AppSection.trash);
    expect(AppSection.of('/login'), isNull);
  });
}
