import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_commands.dart';
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
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/page_ink_layer.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Geniş ekran ekleri (2026-11-02): okuma genişliği, listede açık not
/// vurgusu, Alt+↑/↓ ve Ctrl+W, ayraca çift tık.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _notes = [
  Note(id: 'n1', type: NoteType.text, title: 'BİR', body: 'a'),
  Note(id: 'n2', type: NoteType.text, title: 'İKİ', body: 'b', locked: true),
  Note(id: 'n3', type: NoteType.text, title: 'ÜÇ', body: 'c'),
];

Future<(ProviderContainer, GoRouter)> _pumpShell(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(1400, 900);
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
                // Kısayollar odak ister: gerçek editörde odak gövdede.
                builder: (c, s) => Scaffold(
                  body: Focus(
                    autofocus: true,
                    child: Text('NOT ${s.pathParameters['id']}'),
                  ),
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
      sharedPreferencesProvider.overrideWithValue(sp),
      authRepositoryProvider.overrideWithValue(_NoAuth()),
      currentUidProvider.overrideWithValue(null),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(null),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      filteredNotesProvider.overrideWithValue(const AsyncData(_notes)),
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
  return (container, router);
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

/// Kartın çevresindeki vurgu çerçevesinin rengi.
Color? _haloColor(WidgetTester tester, String title) {
  final halo = find.ancestor(
    of: find.text(title).first,
    matching: find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).border is Border &&
          ((w.decoration! as BoxDecoration).border! as Border).top.width == 2,
    ),
  );
  final box = tester.widget<Container>(halo.first).decoration! as BoxDecoration;
  return (box.border! as Border).top.color;
}

void main() {
  testWidgets('ayraca çift tık: not kipinin varsayılan genişliği', (
    tester,
  ) async {
    final (container, _) = await _pumpShell(
      tester,
      prefs: {'note_pane_width': 500.0},
    );
    expect(container.read(notePaneWidthProvider), 500);
    final note = tester.getTopLeft(find.text('NOT n1'));
    final at = Offset(note.dx - 8, 450);
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(notePaneWidthProvider), 320);
    expect(
      container.read(sharedPreferencesProvider).getDouble('note_pane_width'),
      320,
    );
    await _end(tester);
  });

  testWidgets('açık not listede çerçeveli; yalnız açık olan', (tester) async {
    final (container, _) = await _pumpShell(tester);
    final primary = Theme.of(tester.element(find.text('BİR').first))
        .colorScheme
        .primary;
    expect(_haloColor(tester, 'BİR'), Colors.transparent);
    container.read(openNoteIdsProvider.notifier).open('n1');
    await tester.pump();
    expect(_haloColor(tester, 'BİR'), primary);
    expect(_haloColor(tester, 'ÜÇ'), Colors.transparent);
    // Üstüne ikinci not açılıp kapanınca vurgu alttakine döner.
    container.read(openNoteIdsProvider.notifier).open('n3');
    await tester.pump();
    expect(_haloColor(tester, 'BİR'), Colors.transparent);
    expect(_haloColor(tester, 'ÜÇ'), primary);
    container.read(openNoteIdsProvider.notifier).close('n3');
    await tester.pump();
    expect(_haloColor(tester, 'BİR'), primary);
    await _end(tester);
  });

  testWidgets(
    'Alt+↓/↑ görünen sırayla gezer (kilitliyi atlar), Ctrl+W kapatır',
    (tester) async {
      final (_, router) = await _pumpShell(tester);
      expect(visibleNoteOrder.map((n) => n.id), ['n1', 'n2', 'n3']);
      Future<void> press(LogicalKeyboardKey key, {bool alt = false}) async {
        final mod = alt
            ? LogicalKeyboardKey.altLeft
            : LogicalKeyboardKey.controlLeft;
        await tester.sendKeyDownEvent(mod);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(mod);
        await tester.pump(const Duration(milliseconds: 500));
      }

      await press(LogicalKeyboardKey.arrowDown, alt: true);
      expect(currentLocation(router), '/note/n3');
      await press(LogicalKeyboardKey.arrowDown, alt: true);
      expect(currentLocation(router), '/note/n3', reason: 'son not: yerinde');
      await press(LogicalKeyboardKey.arrowUp, alt: true);
      expect(currentLocation(router), '/note/n1');
      // Derin bağlantı: altta ana sayfa yok → ana sayfaya gider.
      await press(LogicalKeyboardKey.keyW);
      expect(currentLocation(router), '/');
      // Olağan yol: ana sayfanın üstüne açılan not geri çıkar.
      unawaited(router.push('/note/n3'));
      await tester.pump(const Duration(milliseconds: 500));
      await press(LogicalKeyboardKey.keyW);
      expect(currentLocation(router), '/');
      expect(router.canPop(), isFalse);
      await _end(tester);
    },
  );

  group('okuma genişliği', () {
    Future<double> pageWidth(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue(null),
          updateRequiredProvider.overrideWithValue(false),
          notesRepositoryProvider.overrideWithValue(null),
          attachmentRepositoryProvider.overrideWithValue(null),
          foldersRepositoryProvider.overrideWithValue(null),
          noteStreamProvider('n1')
              .overrideWith((ref) => Stream.value(_notes.first)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: NoteEditorScreen(noteId: 'n1'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      final rect = tester.getRect(find.byType(PageInkStack));
      // Ortada: iki yandaki boşluk eşit.
      expect(rect.left, moreOrLessEquals(size.width - rect.right));
      await _end(tester);
      return rect.width;
    }

    testWidgets('geniş ekranda sayfa 760 dp, ortada', (tester) async {
      expect(await pageWidth(tester, const Size(1600, 900)), kReadingWidth);
    });

    testWidgets('telefonda tam genişlik (değişmedi)', (tester) async {
      expect(await pageWidth(tester, const Size(400, 800)), 400);
    });
  });
}
