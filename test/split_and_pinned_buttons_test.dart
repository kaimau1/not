import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/second_note.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/app/web_workspace/web_workspace_scope.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_side.dart';
import 'package:notlar/features/notes/presentation/editor/view_mode_switch.dart';
import 'package:notlar/features/notes/presentation/filter_sheet.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart';

class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<
  ({GoRouter router, ProviderContainer container, FakeFirebaseFirestore db})
>
_pumpSplitShell(
  WidgetTester tester,
  Size size, {
  required bool webWorkspace,
  String initial = '/note/a',
}) async {
  if (webWorkspace) {
    webWorkspaceOverride = true;
    addTearDown(() => webWorkspaceOverride = null);
  }
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = FakeFirebaseFirestore();
  final now = DateTime(2026, 11, 23, 10);
  final notes = [
    Note(
      id: 'a',
      type: NoteType.text,
      title: 'Birinci not',
      body: 'birinci içerik',
      updatedAt: now,
    ),
    Note(
      id: 'b',
      type: NoteType.text,
      title: 'Toplantı',
      body: 'ikinci içerik',
      updatedAt: now,
    ),
  ];
  final col = db.collection('users').doc('u1').collection('notes');
  for (final n in notes) {
    await col.doc(n.id).set(n.toMap());
  }

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
      currentUidProvider.overrideWithValue('u1'),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(NotesRepository(db, 'u1')),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      foldersStreamProvider.overrideWith(
        (ref) => Stream.value(const <NoteFolder>[]),
      ),
      notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
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
  return (router: router, container: container, db: db);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  setUp(() {
    InkToolMemory.reset();
    PinnedSideMemory.reset();
    Personalize.debugReset();
  });

  tearDown(() {
    InkToolMemory.reset();
    PinnedSideMemory.reset();
    Personalize.debugReset();
  });

  const youtubeAtt = Attachment(
    id: 'yt',
    kind: AttachmentKind.video,
    fileName: 'Ders',
    mimeType: 'video/youtube',
    webUrl: 'https://youtu.be/dQw4w9WgXcQ',
    pinHeight: 220,
  );

  const pdfAtt = Attachment(
    id: 'pdf',
    kind: AttachmentKind.pdf,
    fileName: 'belge.pdf',
    mimeType: 'application/pdf',
    pinHeight: 240,
    onPage: true,
  );

  final pinnedYouTube = Note(
    id: 'yt-note',
    type: NoteType.text,
    title: 'Video başlığı',
    body: 'not içeriği',
    updatedAt: DateTime(2026, 11, 23, 9),
    attachments: const [youtubeAtt],
  );

  final pinnedPdf = Note(
    id: 'pdf-note',
    type: NoteType.pdf,
    title: 'PDF başlığı',
    body: 'sayfa notu',
    updatedAt: DateTime(2026, 11, 23, 9),
    attachments: const [pdfAtt],
  );

  group('sabitli / belgeli not üst çubuğu', () {
    for (final entry in <(String, Note, bool)>[
      ('YouTube', pinnedYouTube, false),
      ('PDF', pinnedPdf, true),
    ]) {
      for (final size in const [Size(1280, 800), Size(412, 915)]) {
        testWidgets(
          '${entry.$1} (${size.width.toInt()}×${size.height.toInt()}): '
          'Sabitle + Ara üst çubukta ve kişiselleştirme çalışır',
          (tester) async {
            final repo = CountingNotesRepository();
            await pumpEditor(tester, entry.$2, size: size, repo: repo);
            if (entry.$3) {
              // Test ortamında pdfium yok; pdfrx yükleme istisnasını tüket.
              tester.takeException();
            }

            final pin = find.byKey(const ValueKey('editor-top-pin'));
            final search = find.byKey(const ValueKey('editor-top-search'));
            final more = find.byKey(const ValueKey('editor-more'));
            expect(pin, findsOneWidget);
            expect(search, findsOneWidget);

            final pinCenter = tester.getCenter(pin);
            final searchCenter = tester.getCenter(search);
            expect(searchCenter.dx, greaterThan(pinCenter.dx));
            expect((searchCenter.dy - pinCenter.dy).abs(), lessThan(4));

            await tester.tap(pin);
            await tester.pump(const Duration(milliseconds: 200));
            if (entry.$3) tester.takeException();
            expect(repo.lastSaved?.pinned, isTrue);

            // Üst çubukta görünürken ⋮ içinde mükerrer "Sabitle" yok.
            await tester.tap(more);
            await tester.pumpAndSettle();
            if (entry.$3) tester.takeException();
            expect(find.byKey(const ValueKey('menu-quick-pin')), findsNothing);
            await tester.tap(find.byKey(const ValueKey('sheet-close')));
            await tester.pumpAndSettle();

            // Üst çubuktan gizlenince "Sabitle" ⋮ menüsüne geri gelir, Ara kalır.
            Personalize.update((p) => p.withVisible(UiItem.topPin, false));
            await tester.pump();
            expect(pin, findsNothing);
            expect(search, findsOneWidget);

            await tester.tap(more);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('menu-quick-pin')),
              findsOneWidget,
            );
            await endEditor(tester);
          },
        );
      }
    }

    testWidgets(
      'yıldız ve acil göstergeleri sabitli notta ve tarihsiz/etiketsiz notta '
      'görünür, dokununca kalkar',
      (tester) async {
        for (final note in [
          pinnedYouTube.copyWith(starred: true, urgent: true),
          const Note(
            id: 'bare',
            type: NoteType.text,
            title: 'Tarihsiz',
            body: 'gövde',
            starred: true,
            urgent: true,
          ),
        ]) {
          final repo = CountingNotesRepository();
          await pumpEditor(
            tester,
            note,
            size: const Size(1280, 800),
            repo: repo,
          );
          final star = find.byTooltip('Yıldızı kaldır');
          final urgent = find.byKey(const ValueKey('editor-urgent'));
          expect(star, findsOneWidget, reason: note.id);
          expect(urgent, findsOneWidget, reason: note.id);

          await tester.tap(star);
          await tester.pump(const Duration(milliseconds: 200));
          expect(repo.lastSaved?.starred, isFalse, reason: note.id);
          expect(star, findsNothing, reason: note.id);

          await tester.tap(urgent);
          await tester.pump(const Duration(milliseconds: 200));
          expect(repo.lastSaved?.urgent, isFalse, reason: note.id);
          expect(urgent, findsNothing, reason: note.id);

          await endEditor(tester);
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  });

  group('PinnedMediaPane yan yerleştirme ve ⋮ levhası', () {
    testWidgets(
      'fill=true solda iken ölü tutamak yok, tooltip konumu söyler ve '
      '≥600dp ⋮ levhasında görünüm + Üstte/Solda/Sağda kartları görünür',
      (tester) async {
        tester.view.physicalSize = const Size(650, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        var cycled = 0;
        PinnedSide? selected;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PinnedMediaPane(
                media: youtubeAtt,
                fill: true,
                side: PinnedSide.left,
                onCycleSide: () => cycled++,
                onSelectSide: (s) => selected = s,
                onHeightChanged: (_) {},
                onUnpin: () {},
                onOpen: () {},
                viewSwitch: AttachmentViewSwitch(
                  current: AttachmentView.pinned,
                  available: const {
                    AttachmentView.pinned,
                    AttachmentView.floating,
                  },
                  onChanged: (_) {},
                  dense: true,
                ),
                sheetViewSwitch: (_) => AttachmentViewSwitch(
                  current: AttachmentView.pinned,
                  available: const {
                    AttachmentView.pinned,
                    AttachmentView.floating,
                  },
                  onChanged: (_) {},
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byKey(const ValueKey('pinned-media-fit')), findsNothing);
        final sideFinder = find.byKey(const ValueKey('pinned-side'));
        expect(sideFinder, findsOneWidget);
        final sideBtn = tester.widget<IconButton>(
          find.descendant(of: sideFinder, matching: find.byType(IconButton)),
        );
        expect(sideBtn.tooltip, contains('Solda'));

        await tester.tap(sideFinder);
        await tester.pump();
        expect(cycled, 1);

        await tester.tap(find.byKey(const ValueKey('pinned-media-menu')));
        await tester.pumpAndSettle();

        final sheet = find.byType(BottomSheet);
        expect(sheet, findsOneWidget);
        expect(
          find.descendant(
            of: sheet,
            matching: find.byKey(const ValueKey('attachment-view-switch')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheet, matching: find.text('Yüzen')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('pinned-sheet-side')), findsOneWidget);
        for (final name in ['top', 'left', 'right']) {
          expect(
            find.byKey(ValueKey('pinned-side-pick-$name')),
            findsOneWidget,
          );
        }

        await tester.tap(find.byKey(const ValueKey('pinned-side-pick-right')));
        await tester.pumpAndSettle();
        expect(selected, PinnedSide.right);
      },
    );
  });

  group('web masaüstü bölünmüş liste ve kart sağ tık menüsü', () {
    testWidgets(
      'bölünmüş masaüstü webde liste başlığında Süz doğrudan görünür, '
      'mükerrer hesap simgesi yoktur',
      (tester) async {
        await _pumpSplitShell(
          tester,
          const Size(1440, 900),
          webWorkspace: true,
        );
        expect(tester.takeException(), isNull);

        expect(
          find.descendant(
            of: find.byType(DashboardScreen),
            matching: find.byType(HomeFilterButton),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('home-filter-button')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(DashboardScreen),
            matching: find.byKey(const ValueKey('home-account-avatar')),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('web-workspace-sidebar')),
            matching: find.byKey(const ValueKey('home-account-avatar')),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 30));
      },
    );

    testWidgets(
      'ikili not düzeninde kart sağ tık menüsünde Yanda aç ve Not menüsü vardır',
      (tester) async {
        final res = await _pumpSplitShell(
          tester,
          const Size(1280, 800),
          webWorkspace: false,
        );
        expect(tester.takeException(), isNull);

        final secondCard = find.widgetWithText(NoteCard, 'Toplantı');
        expect(secondCard, findsOneWidget);

        await tester.tap(secondCard, buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();
        expect(find.text('Yanda aç'), findsOneWidget);
        expect(find.text('Not menüsü'), findsOneWidget);

        await tester.tap(find.text('Yanda aç'));
        await tester.pump(const Duration(seconds: 1));
        expect(res.container.read(secondNoteProvider)?.id, 'b');

        // Tekrar sağ tık → Not menüsü tüm eylem levhasını açar.
        await tester.tap(secondCard, buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Not menüsü'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 30));
      },
    );
  });
}
