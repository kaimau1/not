import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/second_note.dart';
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
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/note_actions_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// K32 — İKİ NOT YAN YANA (tablet yatay; kullanıcı K-O12 2026-11-12).
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _now = DateTime.now();
final _notes = [
  for (final id in ['a', 'b', 'c'])
    Note(
      id: id,
      type: NoteType.text,
      title: 'Not $id',
      body: 'gövde $id',
      updatedAt: _now,
    ),
];

late FakeFirebaseFirestore _db;

Future<(ProviderContainer, GoRouter)> _pump(
  WidgetTester tester, {
  Size size = const Size(1024, 640),
  String location = '/note/a',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = _db = FakeFirebaseFirestore();
  final col = db.collection('users').doc('u').collection('notes');
  for (final n in _notes) {
    await col.doc(n.id).set(n.toMap());
  }
  final router = GoRouter(
    initialLocation: location,
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
                builder: (c, s) => NoteEditorScreen(
                  key: ValueKey('note-${s.pathParameters['id']}'),
                  noteId: s.pathParameters['id']!,
                ),
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
      notesRepositoryProvider.overrideWithValue(NotesRepository(db, 'u')),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      notesStreamProvider.overrideWith((ref) => Stream.value(_notes)),
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
  return (container, router);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

Iterable<String> _editorIds(WidgetTester tester) => tester
    .widgetList<NoteEditorScreen>(find.byType(NoteEditorScreen))
    .map((e) => e.noteId);

void main() {
  test('(a) düzen tablosu', () {
    TwoNoteLayout f(double content, {bool landscape = true}) =>
        twoNoteLayoutFor(
          content: content,
          list: 320,
          landscape: landscape,
          secondOpen: true,
        );
    expect(f(1024), TwoNoteLayout.twoOnly);
    expect(f(1280), TwoNoteLayout.listAndTwo);
    expect(f(640, landscape: false), TwoNoteLayout.off);
    expect(f(780), TwoNoteLayout.off);
    expect(
      twoNoteLayoutFor(
        content: 1280,
        list: 320,
        landscape: true,
        secondOpen: false,
      ),
      TwoNoteLayout.off,
    );
  });

  testWidgets('(b) 1024×640: iki editör, liste çekilmiş', (tester) async {
    final (container, _) = await _pump(tester);
    // Giriş kapısı (A4): açık OLMAYAN not yanda açılabilir.
    final dash = tester.element(find.byType(DashboardScreen));
    expect(canOpenSide(dash, 'b'), isTrue);
    expect(canOpenSide(dash, 'a'), isFalse, reason: 'birincil kendisi');
    container.read(secondNoteProvider.notifier).open(const SecondNote('b'));
    await _settle(tester);
    expect(_editorIds(tester), unorderedEquals(['a', 'b']));
    expect(find.byType(DashboardScreen), findsNothing, reason: 'Offstage');
    expect(
      find.byType(DashboardScreen, skipOffstage: false),
      findsOneWidget,
      reason: 'liste ağaçta (State korunur)',
    );
    // Yan bölmenin sol yuvasında ✕; tam ekran/ana sayfa yok.
    expect(find.byKey(const ValueKey('second-note-close')), findsOneWidget);
    Finder inSide(String key) => find.descendant(
      of: find.byType(SecondNotePane),
      matching: find.byKey(ValueKey(key)),
    );
    expect(inSide('second-note-close'), findsOneWidget);
    for (final key in ['note-fullscreen', 'editor-home', 'note-show-list']) {
      expect(inSide(key), findsNothing, reason: key);
    }
    await _end(tester);
  });

  testWidgets('(c) sistem geri: liste, iki editör de kapanır', (tester) async {
    // Gerçek yol: liste `/`, not üstüne itilir.
    final (container, router) = await _pump(tester, location: '/');
    router.push('/note/a').ignore();
    await _settle(tester);
    container.read(secondNoteProvider.notifier).open(const SecondNote('b'));
    await _settle(tester);
    expect(_editorIds(tester), unorderedEquals(['a', 'b']));
    // A0 ölçümü: bölünmüş düzende geri iç gezginden mi geçiyor? Birincilin
    // PopScope zinciri → not rotası kapanır → konum `/`.
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(router.state.uri.path, '/');
    expect(find.byType(NoteEditorScreen), findsNothing);
    expect(container.read(secondNoteProvider), isNull);
    await _end(tester);
  });

  testWidgets('(d) ✕ yalnız yandakini kapatır, birincil State aynı', (
    tester,
  ) async {
    final (container, router) = await _pump(tester);
    container.read(secondNoteProvider.notifier).open(const SecondNote('b'));
    await _settle(tester);
    final primary = tester.state(find.byKey(const ValueKey('note-a')));
    await tester.tap(find.byKey(const ValueKey('second-note-close')));
    await _settle(tester);
    expect(_editorIds(tester), ['a']);
    expect(container.read(secondNoteProvider), isNull);
    expect(router.state.uri.path, '/note/a');
    expect(tester.state(find.byKey(const ValueKey('note-a'))), same(primary));
    await _end(tester);
  });

  testWidgets('(e) birincil yandaki nota geçerse yandaki kapanır', (
    tester,
  ) async {
    final (container, router) = await _pump(tester);
    container.read(secondNoteProvider.notifier).open(const SecondNote('b'));
    await _settle(tester);
    router.go('/note/b');
    await _settle(tester);
    expect(_editorIds(tester), ['b']);
    expect(container.read(secondNoteProvider), isNull);
    await _end(tester);
  });

  testWidgets('dikey tablette yandaki not çizilmez', (tester) async {
    final (container, _) = await _pump(tester, size: const Size(800, 1280));
    expect(
      canOpenSide(
        tester.element(find.byType(DashboardScreen, skipOffstage: false)),
        'b',
      ),
      isFalse,
    );
    container.read(secondNoteProvider.notifier).open(const SecondNote('b'));
    await _settle(tester);
    expect(_editorIds(tester), ['a']);
    await _end(tester);
  });

  // A6: yandaki not BAŞKA yerden çöpe atılırsa (kart menüsü, ikinci cihaz)
  // yalnız bölme kapanır; birincil yerinde.
  testWidgets('(f) yandaki not silinince yalnız bölme kapanır', (tester) async {
    final (container, router) = await _pump(tester);
    container.read(secondNoteProvider.notifier).open(const SecondNote('b'));
    await _settle(tester);
    final primary = tester.state(find.byKey(const ValueKey('note-a')));
    NotesRepository(_db, 'u').softDelete('b');
    await _settle(tester);
    expect(_editorIds(tester), ['a']);
    expect(container.read(secondNoteProvider), isNull);
    expect(router.state.uri.path, '/note/a');
    expect(tester.state(find.byKey(const ValueKey('note-a'))), same(primary));
    await _end(tester);
  });
}
