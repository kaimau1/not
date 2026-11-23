import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/app/web_workspace/web_workspace_scope.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
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

Future<
  ({GoRouter router, ProviderContainer container, SharedPreferences prefs})
>
_pumpWorkspace(WidgetTester tester, Size size, {String initial = '/'}) async {
  webWorkspaceOverride = true;
  addTearDown(() => webWorkspaceOverride = null);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (c, s, child) => AppFrame(child: child),
        routes: [
          ShellRoute(
            builder: (c, s, child) => SplitShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (c, s) => SplitScope.activeOf(c)
                    ? const SizedBox.shrink()
                    : const DashboardScreen(),
              ),
              GoRoute(
                path: '/note/:id',
                builder: (c, s) =>
                    Scaffold(body: Text('not:${s.pathParameters['id']}')),
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
      currentUidProvider.overrideWithValue('u1'),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(null),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      foldersStreamProvider.overrideWith(
        (ref) => Stream.value(const [
          NoteFolder(id: 'f1', name: 'İş', ownerId: 'u1'),
        ]),
      ),
      notesStreamProvider.overrideWith(
        (ref) => Stream.value(const [
          Note(id: 'a', type: NoteType.text, title: 'Alışveriş', body: 'süt'),
          Note(
            id: 'b',
            type: NoteType.text,
            title: 'Toplantı',
            body: 'notlar',
            folderId: 'f1',
          ),
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
  return (router: router, container: container, prefs: prefs);
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  testWidgets(
    'geniş webde 256px kenar çubuğu, klasör ağacı, Drive hapı ve başlık kurulur',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpWorkspace(tester, const Size(1440, 900));
      expect(tester.takeException(), isNull);

      final sidebar = find.byKey(const ValueKey('web-workspace-sidebar'));
      expect(sidebar, findsOneWidget);
      expect(tester.getSize(sidebar).width, kWebSidebarExpandedWidth);

      expect(
        find.byKey(const ValueKey('web-dashboard-header')),
        findsOneWidget,
      );
      expect(find.text('Ctrl+K'), findsOneWidget);
      expect(find.byKey(const ValueKey('web-view-toggle')), findsOneWidget);
      expect(find.byKey(const ValueKey('web-columns-menu')), findsOneWidget);

      expect(
        find.byKey(const ValueKey('web-sidebar-folder-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('web-sidebar-new-folder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('web-drive-status-pill')),
        findsOneWidget,
      );
      // Masaüstü ağaç açıkken mükerrer yatay klasör şeridi gizlenir.
      expect(find.byKey(const ValueKey('home-folder-strip')), findsNothing);

      expect(find.bySemanticsLabel(RegExp('^Notlar')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('^Klasörler')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Alışveriş')), findsOneWidget);

      handle.dispose();
      await _end(tester);
    },
  );

  testWidgets('kenar çubuğundan klasör seçimi başlığı ve filtreyi günceller', (
    tester,
  ) async {
    final res = await _pumpWorkspace(tester, const Size(1440, 900));
    await tester.tap(find.byKey(const ValueKey('web-sidebar-folder-f1')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(res.container.read(selectedFolderProvider), 'f1');
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('web-dashboard-title')))
          .data,
      'İş',
    );

    await tester.tap(find.byKey(const ValueKey('web-nav-notes')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(res.container.read(selectedFolderProvider), isNull);
    await _end(tester);
  });

  testWidgets(
    'not açıkken 3 sütunlu düzende kenar çubuğu 72px rıhtıma daralır ve açma kalıcıdır',
    (tester) async {
      final res = await _pumpWorkspace(
        tester,
        const Size(1440, 900),
        initial: '/note/a',
      );
      expect(tester.takeException(), isNull);

      final sidebar = find.byKey(const ValueKey('web-workspace-sidebar'));
      expect(sidebar, findsOneWidget);
      expect(tester.getSize(sidebar).width, kWebSidebarCompactWidth);
      expect(find.text('not:a'), findsOneWidget);
      expect(find.byType(DashboardScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('web-sidebar-toggle')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getSize(sidebar).width, kWebSidebarExpandedWidth);
      expect(res.container.read(railExtendedProvider), isTrue);
      expect(res.prefs.getBool('rail_extended'), isTrue);
      await _end(tester);
    },
  );

  testWidgets('dar web penceresinde masaüstü kabuk açılmaz', (tester) async {
    await _pumpWorkspace(tester, const Size(480, 840));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('web-workspace-sidebar')), findsNothing);
    expect(find.byKey(const ValueKey('web-dashboard-header')), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);
    await _end(tester);
  });

  testWidgets('üst başlık görünüm ve sütun yoğunluğu ayarlarını günceller', (
    tester,
  ) async {
    final res = await _pumpWorkspace(tester, const Size(1440, 900));
    expect(res.container.read(noteListViewProvider), isFalse);
    expect(res.container.read(gridColumnsProvider), 0);

    await tester.tap(find.byKey(const ValueKey('web-columns-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<int>, '3 sütun'));
    await tester.pumpAndSettle();
    expect(res.container.read(gridColumnsProvider), 3);

    await tester.tap(find.byKey(const ValueKey('web-view-toggle')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(res.container.read(noteListViewProvider), isTrue);
    await _end(tester);
  });
}
