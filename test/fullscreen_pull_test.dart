import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ÇEKEREK TAM EKRAN (kullanıcı isteği 2026-11-02): tablette ayracı listenin
/// en dar hâlinden sola biraz zorlayınca ipucu çıkar, bırakınca not tam
/// ekrana geçer; sol kenardan sağa çekmek çıkarır.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  Future<ProviderContainer> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/note/n1',
      routes: [
        ShellRoute(
          builder: (c, s, child) => AppFrame(child: child),
          routes: [
            ShellRoute(
              builder: (c, s, child) => SplitShell(child: child),
              routes: [
                GoRoute(
                  path: '/',
                  builder: (c, s) => const Scaffold(body: Text('HOME')),
                ),
                GoRoute(
                  path: '/note/:id',
                  builder: (c, s) => const Scaffold(body: Text('NOT')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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
    return container;
  }

  /// Ayracın tutma alanı: listenin sağ kenarı.
  Offset divider(WidgetTester tester) {
    final note = tester.getTopLeft(find.text('NOT'));
    return Offset(note.dx - 8, 400);
  }

  testWidgets('az itiş yalnız ipucu, eşiği geçip bırakınca tam ekran', (
    tester,
  ) async {
    final container = await pump(tester);
    expect(container.read(noteFullscreenProvider), isFalse);

    // Önce en dar hâle, sonra biraz daha: ipucu çıkar ama eşik altında.
    final start = divider(tester);
    final g = await tester.startGesture(start);
    await g.moveBy(const Offset(-20, 0));
    await tester.pump();
    await g.moveTo(const Offset(260 + 8 - 20, 400));
    await tester.pump();
    expect(find.text('Tam ekran için çek'), findsOneWidget);
    await g.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(noteFullscreenProvider), isFalse);
    expect(find.text('Tam ekran için çek'), findsNothing);

    // Eşiği geç: "Bırak" yazar, bırakınca tam ekran.
    final g2 = await tester.startGesture(divider(tester));
    await g2.moveBy(const Offset(-20, 0));
    await tester.pump();
    await g2.moveTo(const Offset(260 + 8 - 90, 400));
    await tester.pump();
    expect(find.text('Bırak: tam ekran'), findsOneWidget);
    await g2.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(noteFullscreenProvider), isTrue);

    // Sol kenardan sağa çek: tam ekrandan çıkar.
    await tester.dragFrom(const Offset(6, 400), const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(noteFullscreenProvider), isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
