import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pumpHome(
  WidgetTester tester,
  Size size, {
  Widget? home,
  bool split = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (c, s, child) => AppFrame(child: child),
        routes: [
          ShellRoute(
            builder: (c, s, child) => split ? SplitShell(child: child) : child,
            routes: [
              GoRoute(
                path: '/',
                builder: (c, s) =>
                    home ??
                    (SplitScope.activeOf(c)
                        ? const SizedBox.shrink()
                        : const DashboardScreen()),
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
      notesStreamProvider.overrideWith(
        (ref) => Stream.value(const [
          Note(id: 'a', type: NoteType.text, title: 'Alışveriş', body: 'süt'),
        ]),
      ),
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
  await tester.pump(const Duration(seconds: 1));
}

/// PW-A (web keşfi 2026-11-18): KW-1 ana ekran + ray erişilebilirlik
/// ağacında; KW-2 ana ekranda Tab Flutter içinde ilerler.
///
/// KÖK NEDEN: Navigator'ın sayfa rotası `ModalBarrier` → `BlockSemantics`
/// taşır; sınır olmadan ondan önce çizilen kardeşler (ray, bölünmüş
/// kabukta soldaki liste) ağaçtan düşüyordu. Tab'da ise boş '/' rotası
/// odağı tutuyordu (içinde odaklanacak bir şey yok).
void main() {
  testWidgets('KW-1: geniş ekranda ray ve ana ekran ağaçta', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpHome(tester, const Size(1440, 900));
    // Ray: bölüm adları ("Notlar · Sekme 1 / 7" gibi).
    expect(find.bySemanticsLabel(RegExp('^Notlar')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('^Klasörler')), findsWidgets);
    // Ana ekran: arama ve not kartı.
    expect(find.bySemanticsLabel(RegExp('Ara')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Alışveriş')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('KW-1: bölünmüş kabuk olmadan da ray ağaçta', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpHome(
      tester,
      const Size(1440, 900),
      home: const Scaffold(body: Text('merhaba')),
      split: false,
    );
    expect(find.bySemanticsLabel('merhaba'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Notlar')), findsWidgets);
    handle.dispose();
  });

  testWidgets('KW-2: Tab ana ekranda ilerler, boş rotada takılmaz', (
    tester,
  ) async {
    await _pumpHome(tester, const Size(1440, 900));
    final seen = <FocusNode>{};
    var inHome = false;
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final node = FocusManager.instance.primaryFocus!;
      expect(node, isNot(isA<FocusScopeNode>()));
      seen.add(node);
      inHome |=
          node.context?.findAncestorWidgetOfExactType<DashboardScreen>() !=
          null;
    }
    expect(seen.length, greaterThan(3));
    expect(inHome, isTrue);
  });
}
