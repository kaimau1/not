import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/app/app_commands.dart';
import 'package:notlar/app/router.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/error_log.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/utils/color_contrast.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/core/widgets/back_closes.dart';
import 'package:notlar/core/widgets/hold_progress_ring.dart';
import 'package:notlar/features/ai/data/ai_policy.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/data/google_scope_auth.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_backup.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/data/google_calendar_sync.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/routine.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';
import 'package:notlar/features/calendar/presentation/pinch_zoom.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/backup_service.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/due_banner.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/quick_add_actions.dart';
import 'package:notlar/features/notes/presentation/share_target_sheet.dart';
import 'package:notlar/features/settings/presentation/app_lock.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser implements User {
  @override
  String? get displayName => 'Ada Yılmaz';

  @override
  String? get email => 'ada@example.com';

  @override
  String? get photoURL => null;

  @override
  bool get isAnonymous => false;

  @override
  String get uid => 'u1';

  @override
  List<UserInfo> get providerData => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _LoggedInAuth implements AuthRepository {
  _LoggedInAuth(this._user);

  final User _user;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> authStateChanges() => Stream.value(_user);

  @override
  Stream<User?> userChanges() => Stream.value(_user);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeGoogleAuth implements GoogleScopeAuth {
  @override
  Future<({String token, DateTime expiry})?> connect() async =>
      (token: 'tok', expiry: DateTime.now().add(const Duration(hours: 1)));

  @override
  Future<({String token, DateTime expiry})?> silent() => connect();
}

class _FakeDoors implements HomeDoors {
  final calls = <String>[];

  @override
  QuickAddActions get quickAddActions => throw UnimplementedError();

  @override
  void captureVoiceNote() => calls.add('voice');

  @override
  void cycleFolder(int direction) => calls.add('cycle$direction');

  @override
  void deleteSelection() => calls.add('delete');

  @override
  void dictateNote() => calls.add('dictate');

  @override
  void selectAllVisible() => calls.add('all');
}

http.Response _jsonResp(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('Telefon 1: tam yedek pageInk ve takvimle esit doner, ikinci yukleme cogaltmaz', () async {
    final db1 = FakeFirebaseFirestore();
    final notes1 = NotesRepository(db1, 'u1');
    final folders1 = FoldersRepository(db1, 'u1');
    final cal1 = CalendarRepository(db1, 'u1');

    final fId = await folders1.createFolder('Klinik');
    final folderList = await folders1.watchFolders().first;
    final folder = folderList.singleWhere((f) => f.id == fId);

    final srcNote = Note(
      id: 'n1',
      type: NoteType.pdf,
      title: 'Anatomi',
      folderId: fId,
      pageInk: const [
        InkStroke(
          page: 1,
          color: 0xFF1E88E5,
          width: 0.012,
          points: [0.1, 0.2, 0.4, 0.5],
        ),
      ],
    );

    final calSnap = CalendarSnapshot(
      events: [
        CalendarEvent(
          id: 'e1',
          title: 'Konsey',
          start: DateTime(2026, 11, 28, 9),
          end: DateTime(2026, 11, 28, 10),
          noteIds: const ['n1'],
        ),
      ],
      tasks: const [
        TaskItem(
          id: 't1',
          title: 'Slayt hazirla',
          due: '2026-11-28',
          noteId: 'n1',
          noteItemId: 'i1',
        ),
      ],
      lists: const [TaskList(id: 'l1', title: 'Gunluk')],
      dayLinks: const {
        '2026-11-28': ['n1'],
      },
      routines: [
        Routine(
          id: 'r1',
          title: 'Sabah okumasi',
          steps: const [RoutineStep(id: 'rs1', text: '10 sayfa')],
          startDay: '2026-11-01',
          time: '07:30',
          remind: true,
          createdAt: DateTime(2026, 11, 1, 7),
        ),
      ],
      routineLogs: const [
        RoutineLog(
          routineId: 'r1',
          day: '2026-11-28',
          done: {'rs1'},
          completed: true,
        ),
      ],
    );

    final sink = MemoryBackupSink();
    final exported =
        await BackupService(
          notes: notes1,
          attachments: null,
          folders: folders1,
          calendar: cal1,
        ).export(
          sink,
          allNotes: [srcNote],
          folderList: [folder],
          calendarData: calSnap,
        );
    expect(exported, 1);

    final archive = ZipDecoder().decodeBytes(sink.bytes!);
    final db2 = FakeFirebaseFirestore();
    final notes2 = NotesRepository(db2, 'u2');
    final folders2 = FoldersRepository(db2, 'u2');
    final cal2 = CalendarRepository(db2, 'u2');
    final svc2 = BackupService(
      notes: notes2,
      attachments: null,
      folders: folders2,
      calendar: cal2,
    );

    final first = await svc2.restore(archive, existing: const []);
    expect(first.restored, 1);
    expect(first.skipped, 0);
    await Future<void>.delayed(Duration.zero);

    final restoredLights = await notes2.watchNotes().first;
    expect(restoredLights, hasLength(1));
    final restoredNote = await notes2.hydrate(restoredLights.single);
    expect(restoredNote.title, 'Anatomi');
    expect(restoredNote.pageInk, hasLength(1));
    const expectedPts = [0.1, 0.2, 0.4, 0.5];
    expect(restoredNote.pageInk.single.points, hasLength(expectedPts.length));
    for (var i = 0; i < expectedPts.length; i++) {
      expect(
        restoredNote.pageInk.single.points[i],
        closeTo(expectedPts[i], 1e-6),
      );
    }

    final restoredFolders = await folders2.watchFolders().first;
    expect(restoredFolders.map((f) => f.name), ['Klinik']);

    final events = await cal2.watchEvents().first;
    final tasks = await cal2.watchTasks().first;
    final lists = await cal2.watchTaskLists().first;
    final linksSnap = await cal2.watchDayLinkSnapshot().first;
    final routines = await cal2.watchRoutines().first;
    final routineLogsById = await cal2.watchRoutineLogs().first;
    expect(events, hasLength(1));
    expect(events.single.noteIds, [restoredNote.id]);
    expect(tasks, hasLength(1));
    expect(tasks.single.noteId, restoredNote.id);
    expect(lists.map((l) => l.title), ['Gunluk']);
    expect(linksSnap.links['2026-11-28'], [restoredNote.id]);
    expect(routines.map((r) => r.id), ['r1']);
    expect(routines.single.title, 'Sabah okumasi');
    expect(routineLogsById['r1']?['2026-11-28']?.completed, isTrue);

    final second = await svc2.restore(
      archive,
      existing: [restoredNote],
      existingFolders: restoredFolders,
      existingCalendar: CalendarSnapshot(
        events: events,
        tasks: tasks,
        lists: lists,
        dayLinks: linksSnap.links,
        routines: routines,
        routineLogs: [
          for (final byDay in routineLogsById.values) ...byDay.values,
        ],
      ),
    );
    expect(second.restored, 0);
    expect(second.skipped, 1);
    await Future<void>.delayed(Duration.zero);
    expect(await notes2.watchNotes().first, hasLength(1));
    expect(await folders2.watchFolders().first, hasLength(1));
    expect(await cal2.watchEvents().first, hasLength(1));
    expect(await cal2.watchTasks().first, hasLength(1));
    expect(await cal2.watchTaskLists().first, hasLength(1));
    expect(await cal2.watchRoutines().first, hasLength(1));
  });

  test('Telefon 6/7: 1 dk yeniden kilitleme saati ve AppLockSecureScope ref sayaci', () {
    final bgAt = DateTime(2026, 11, 27, 12);
    const oneMin = AppLockSettings(enabled: true);
    expect(
      appLockShouldRelock(
        settings: oneMin,
        backgroundedAt: bgAt,
        now: bgAt.add(const Duration(seconds: 59)),
      ),
      isFalse,
    );
    expect(
      appLockShouldRelock(
        settings: oneMin,
        backgroundedAt: bgAt,
        now: bgAt.add(const Duration(minutes: 1)),
      ),
      isTrue,
    );
    expect(
      appLockShouldRelock(
        settings: const AppLockSettings(delayMinutes: 0),
        backgroundedAt: bgAt,
        now: bgAt.add(const Duration(minutes: 10)),
      ),
      isFalse,
    );

    AppLockSecureScope.reset();
    addTearDown(AppLockSecureScope.reset);
    final applied = <bool>[];
    AppLockSecureScope.debugApply = (on) async => applied.add(on);

    expect(AppLockSecureScope.isActive, isFalse);
    AppLockSecureScope.acquireNote();
    expect(AppLockSecureScope.isActive, isTrue);
    AppLockSecureScope.setAppLockSecure(true);
    expect(AppLockSecureScope.isActive, isTrue);
    AppLockSecureScope.releaseNote();
    expect(
      AppLockSecureScope.isActive,
      isTrue,
      reason: 'hideInRecents halen acik',
    );
    AppLockSecureScope.setAppLockSecure(false);
    expect(AppLockSecureScope.isActive, isFalse);
    expect(applied, [true, false]);
  });

  testWidgets('Telefon 8: 3 katmanli BackCloses LIFO kapanis sirasi', (
    tester,
  ) async {
    final layers = {'penMode': false, 'capsule': false, 'settingsCard': false};
    late StateSetter setModal;

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('kok')),
        routes: {
          '/editor': (_) => StatefulBuilder(
            builder: (context, setState) {
              setModal = setState;
              return PopScope(
                child: Scaffold(
                  body: BackCloses(
                    open: layers['penMode']!,
                    onClose: () => setState(() => layers['penMode'] = false),
                    child: BackCloses(
                      open: layers['capsule']!,
                      onClose: () => setState(() => layers['capsule'] = false),
                      child: BackCloses(
                        open: layers['settingsCard']!,
                        onClose: () =>
                            setState(() => layers['settingsCard'] = false),
                        child: const Text('tuval'),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        },
      ),
    );
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(nav.pushNamed('/editor'));
    await tester.pumpAndSettle();

    setModal(() => layers['penMode'] = true);
    await tester.pump();
    setModal(() => layers['capsule'] = true);
    await tester.pump();
    setModal(() => layers['settingsCard'] = true);
    await tester.pump();
    expect(BackCloses.openCount, 3);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(layers, {'penMode': true, 'capsule': true, 'settingsCard': false});

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(layers, {'penMode': true, 'capsule': false, 'settingsCard': false});

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(layers, {'penMode': false, 'capsule': false, 'settingsCard': false});
    expect(BackCloses.openCount, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('kok'), findsOneWidget);
  });

  testWidgets(
    'Telefon 11-13: DueBanner otomatik belirir, +N ve kilitli notu maskeler',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notesStream = StreamController<List<Note>>();
      addTearDown(notesStream.close);

      final now = DateTime.now();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notesStreamProvider.overrideWith((ref) => notesStream.stream),
            tasksStreamProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: DueBanner()),
          ),
        ),
      );
      notesStream.add(const []);
      await tester.pump();
      expect(find.byKey(const ValueKey('due-banner')), findsNothing);

      notesStream.add([
        Note(
          id: 'l1',
          type: NoteType.text,
          title: 'CokGizliBaslik',
          locked: true,
          reminderAt: now.subtract(const Duration(minutes: 10)),
        ),
        Note(
          id: 'n2',
          type: NoteType.text,
          title: 'Fatura',
          reminderAt: now.subtract(const Duration(minutes: 5)),
        ),
        Note(
          id: 'n3',
          type: NoteType.text,
          title: 'Kargo',
          reminderAt: now.subtract(const Duration(minutes: 2)),
        ),
      ]);
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('due-banner')), findsOneWidget);
      expect(find.textContaining('CokGizliBaslik'), findsNothing);
      expect(find.textContaining('🔒'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('due-banner-close')));
      await tester.pump();
      expect(find.byKey(const ValueKey('due-banner')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Telefon 17/18: ?item= sorgusu revealItemId tasir ve HoldRingArea 0.25 sessiz pay',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final note = Note(
        id: 'n1',
        type: NoteType.checklist,
        title: 'Liste',
        items: const [NoteItem(id: 'item_42', text: 'Hedef madde')],
      );
      final repo = NotesRepository(FakeFirebaseFirestore(), 'u1');
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(_LoggedInAuth(_FakeUser())),
          currentUidProvider.overrideWithValue('u1'),
          updateRequiredProvider.overrideWithValue(false),
          notesRepositoryProvider.overrideWithValue(repo),
          attachmentRepositoryProvider.overrideWithValue(null),
          foldersRepositoryProvider.overrideWithValue(null),
          calendarRepositoryProvider.overrideWithValue(null),
          notesStreamProvider.overrideWith((ref) => Stream.value([note])),
          trashStreamProvider.overrideWith((ref) => Stream.value(const [])),
          inboxNotesProvider.overrideWith((ref) => Stream.value(const [])),
          foldersStreamProvider.overrideWith((ref) => Stream.value(const [])),
          sharedFolderRefsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          noteStreamProvider('n1').overrideWith((ref) => Stream.value(note)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
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
      await tester.pump();
      unawaited(router.push(noteRoutePath('n1', query: '?item=item_42')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final editor = tester.widget<NoteEditorScreen>(
        find.byType(NoteEditorScreen),
      );
      expect(editor.revealItemId, 'item_42');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: HoldRingArea(
              duration: Duration(milliseconds: 400),
              child: SizedBox(width: 120, height: 120, child: Text('hedef')),
            ),
          ),
        ),
      );
      final ring = find.byKey(const ValueKey('hold-progress-ring'));
      final g = await tester.startGesture(tester.getCenter(find.text('hedef')));
      await tester.pump(const Duration(milliseconds: 80));
      expect(ring, findsNothing);
      await tester.pump(const Duration(milliseconds: 120));
      expect(ring, findsOneWidget);
      await g.up();
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'Telefon 26: backgroundImageId haric tutulur, arsiv rozeti ve shareTarget filtresi',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const bg = Attachment(
        id: 'bg',
        kind: AttachmentKind.image,
        fileName: 'bg.jpg',
        mimeType: 'image/jpeg',
      );
      const keep = Attachment(
        id: 'keep',
        kind: AttachmentKind.image,
        fileName: 'doc.jpg',
        mimeType: 'image/jpeg',
      );
      const archiveNote = Note(
        id: 'arch1',
        type: NoteType.archive,
        title: 'Klinik Arsivi',
        backgroundImageId: 'bg',
        attachments: [bg, keep],
        items: [NoteItem(id: 'i1', text: 'Ozet')],
      );
      expect(archiveNote.attachmentsWithoutBackground.map((a) => a.id), [
        'keep',
      ]);

      expect(
        canReceiveShare(
          const Note(id: 'l', type: NoteType.text, locked: true),
          hasFiles: true,
        ),
        isFalse,
      );
      expect(
        canReceiveShare(
          Note(id: 'ar', type: NoteType.text, archivedAt: DateTime(2026)),
          hasFiles: true,
        ),
        isFalse,
      );
      expect(
        canReceiveShare(
          const Note(id: 'ok', type: NoteType.text),
          hasFiles: true,
        ),
        isTrue,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUidProvider.overrideWithValue('ben'),
            notesRepositoryProvider.overrideWithValue(
              NotesRepository(FakeFirebaseFirestore(), 'ben'),
            ),
            calendarRepositoryProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(width: 300, child: NoteCard(note: archiveNote)),
            ),
          ),
        ),
      );
      await tester.pump();
      final ctx = tester.element(find.byType(NoteCard));
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
      expect(
        find.text(AppLocalizations.of(ctx).archiveNotebook),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'Telefon 37: GoogleCalendarSync cevrimdisiyken pending == 1 kuyruklar',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var offline = true;
      GoogleCalendarController.authOverride = _FakeGoogleAuth.new;
      GoogleCalendarController.writeAuthOverride = _FakeGoogleAuth.new;
      GoogleCalendarController.clientOverride = () => MockClient((req) async {
        if (req.url.path.endsWith('/calendarList')) {
          return _jsonResp({
            'items': [
              {'id': 'k', 'summary': 'Kisisel', 'primary': true},
            ],
          });
        }
        if (req.method == 'GET') {
          return _jsonResp({'items': [], 'nextSyncToken': 'S1'});
        }
        if (offline) throw http.ClientException('offline');
        final body =
            jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;
        return _jsonResp({
          ...body,
          'id': 'ev1',
          'status': 'confirmed',
          'start': {'dateTime': '2026-11-28T09:00:00Z'},
          'end': {'dateTime': '2026-11-28T10:00:00Z'},
        });
      });
      addTearDown(() {
        GoogleCalendarController.authOverride = null;
        GoogleCalendarController.writeAuthOverride = null;
        GoogleCalendarController.clientOverride = null;
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('u1'),
          eventLinksStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(googleCalendarProvider.notifier);
      await ctrl.connect();
      await ctrl.connectWrite();
      await ctrl.saveToGoogle(
        CalendarEvent(
          id: '',
          title: 'Vizit',
          start: DateTime(2026, 11, 28, 9),
          end: DateTime(2026, 11, 28, 10),
        ),
      );
      expect(container.read(googleCalendarProvider).pending, 1);

      offline = false;
      await ctrl.refresh(force: true);
      expect(container.read(googleCalendarProvider).pending, 0);
    },
  );

  testWidgets(
    'Web 8: AppShortcuts Alt+Ok klasor degistirir ve PinchColumns Ctrl+tekerlek calisir',
    (tester) async {
      final doors = _FakeDoors();
      homeDoors = doors;
      addTearDown(() {
        if (identical(homeDoors, doors)) homeDoors = null;
      });

      final focusNode = FocusNode();
      final textFocus = FocusNode();
      addTearDown(() {
        focusNode.dispose();
        textFocus.dispose();
      });

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => AppShortcuts(
              onToggleList: () {},
              child: Scaffold(
                body: Column(
                  children: [
                    Focus(focusNode: focusNode, child: const Text('liste')),
                    TextField(focusNode: textFocus),
                  ],
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
      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      expect(doors.calls, ['cycle1', 'cycle-1']);

      textFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      expect(doors.calls, [
        'cycle1',
        'cycle-1',
      ], reason: 'yazarken yoksayilmali');

      expect(pinchTargetColumns(2, 1.3), 1);
      expect(pinchTargetColumns(4, 0.5), 4);
      final commits = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PinchColumns(
              columns: 3,
              onCommit: commits.add,
              child: const SizedBox(width: 400, height: 400),
            ),
          ),
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(200, 200),
          scrollDelta: Offset(0, -100),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(commits, [2]);
    },
  );

  testWidgets('Web 12: AI kapaliyken not kaydirmada ErrorLog bos kalir', (
    tester,
  ) async {
    ErrorLog.resetForTest();
    addTearDown(ErrorLog.resetForTest);
    SharedPreferences.setMockInitialValues({Personalize.aiOffKey: true});
    final prefs = await SharedPreferences.getInstance();
    final repo = NotesRepository(FakeFirebaseFirestore(), 'ben');

    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(_LoggedInAuth(_FakeUser())),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(repo),
        foldersRepositoryProvider.overrideWithValue(null),
        foldersStreamProvider.overrideWith((ref) => Stream.value(const [])),
        sharedFolderRefsProvider.overrideWith((ref) => Stream.value(const [])),
        calendarRepositoryProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    container.read(aiTurnedOffProvider.notifier).set(true);
    addTearDown(() => Personalize.aiOff.value = false);

    expect(container.read(aiTurnedOffProvider), isTrue);
    expect(
      () => container.read(aiAdmissionProvider).check(),
      throwsA(
        isA<AiPolicyException>().having(
          (e) => e.kind,
          'kind',
          AiPolicyErrorKind.aiTurnedOff,
        ),
      ),
    );

    final sampleNotes = [
      for (var i = 0; i < 12; i++)
        Note(id: 'n$i', type: NoteType.text, title: 'Not $i', body: 'Metin $i'),
    ];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView.builder(
              itemCount: sampleNotes.length,
              itemBuilder: (_, i) => NoteCard(note: sampleNotes[i]),
            ),
          ),
        ),
      ),
    );
    await tester.fling(find.byType(ListView), const Offset(0, -400), 1000);
    await tester.pumpAndSettle();

    expect(ErrorLog.entries, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'Telefon 3 (D7): acik pakette Enter yeni maddeyi paketin icinde acar',
    (tester) async {
      var items = const [
        NoteItem(id: 'p1', text: 'bir', package: 'pk'),
        NoteItem(id: 'p2', text: 'iki', package: 'pk'),
        NoteItem(id: 'z', text: 'sonra'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: ItemsEditor(
                  items: items,
                  onChanged: (next) => setState(() => items = next),
                  showCheckboxes: true,
                  shrinkWrap: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('note-package-pill')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('note-package-pill')), findsNothing);

      await tester.tap(find.text('bir'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      final state = tester.state<ItemsEditorState>(find.byType(ItemsEditor));
      expect(state.debugItems, hasLength(4));
      expect(state.debugItems[0].package, 'pk');
      expect(state.debugItems[1].package, 'pk');
      expect(state.debugItems[2].package, 'pk');
      expect(state.debugItems[3].package, isEmpty);
      expect(find.byKey(const ValueKey('note-package-pill')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('Telefon 14: Backspace geri alir, ek degisimi ogrenilmez', () {
    final savedMem = AutoSpell.memory;
    final savedOn = AutoSpell.enabled.value;
    final savedMode = AutoSpell.mode.value;
    final savedRules = AutoSpell.rulesOnly.value;
    addTearDown(() {
      AutoSpell.memory = savedMem;
      AutoSpell.enabled.value = savedOn;
      AutoSpell.mode.value = savedMode;
      AutoSpell.rulesOnly.value = savedRules;
    });
    AutoSpell.memory = SpellMemory()..addWord('kalemi', 5);
    AutoSpell.mode.value = SpellMode.auto;
    AutoSpell.enabled.value = true;
    AutoSpell.rulesOnly.value = false;
    AutoSpell.beginNote();

    final c = WrapTextController();
    AutoSpell.attach(c, () {});
    addTearDown(() => AutoSpell.detach(c));

    void typeStr(String s) {
      for (final ch in s.split('')) {
        final caret = c.selection.isValid
            ? c.selection.baseOffset
            : c.logicalText.length;
        c.value = TextEditingValue(
          text: c.logicalText.replaceRange(caret, caret, ch),
          selection: TextSelection.collapsed(offset: caret + 1),
        );
      }
    }

    // Backspace geri alma: duzeltme hemen geri alinir ve cift reddedilir.
    typeStr('bu kalen ');
    expect(c.logicalText, 'Bu kalem ');
    final caret = c.selection.baseOffset;
    c.value = TextEditingValue(
      text: c.logicalText.replaceRange(caret - 1, caret, ''),
      selection: TextSelection.collapsed(offset: caret - 1),
    );
    expect(c.logicalText, 'Bu kalen');
    expect(AutoSpell.memory.isRejected('kalen', 'kalem'), isTrue);

    // Ek degisimi: "kalemi" -> "kalemde" ogrenilmez.
    AutoSpell.beginNote();
    final c2 = WrapTextController();
    AutoSpell.attach(c2, () {});
    addTearDown(() => AutoSpell.detach(c2));
    for (final ch in 'bu kalemi '.split('')) {
      final at = c2.selection.isValid
          ? c2.selection.baseOffset
          : c2.logicalText.length;
      c2.value = TextEditingValue(
        text: c2.logicalText.replaceRange(at, at, ch),
        selection: TextSelection.collapsed(offset: at + 1),
      );
    }
    final i = c2.logicalText.indexOf('kalemi');
    expect(i, greaterThanOrEqualTo(0));
    c2.value = TextEditingValue(
      text: c2.logicalText.replaceRange(i, i + 'kalemi'.length, 'kalemde'),
      selection: TextSelection.collapsed(offset: i + 'kalemde'.length),
    );
    expect(AutoSpell.memory.fixes.containsKey('kalemi'), isFalse);
  });

  test('Telefon 29: Lavanta, Zeytin, Saman, Krem, Seftali ve Nane WCAG kontrast ciftleri', () {
    const namedFamilies = [
      ThemeFamily.lavender,
      ThemeFamily.olive,
      ThemeFamily.straw,
      ThemeFamily.cream,
      ThemeFamily.peach,
      ThemeFamily.mint,
    ];
    for (final family in namedFamilies) {
      for (final brightness in Brightness.values) {
        final theme = AppTheme.of(family, brightness);
        final scheme = theme.colorScheme;
        final card = AppTokens.fromTheme(theme).card;
        for (final bg in [scheme.surface, card]) {
          expect(
            contrastRatio(scheme.onSurface, bg),
            greaterThanOrEqualTo(7.0),
            reason: '$family $brightness onSurface',
          );
          expect(
            contrastRatio(scheme.onSurfaceVariant, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$family $brightness onSurfaceVariant',
          );
        }
        expect(
          contrastRatio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: '$family $brightness onPrimary',
        );
      }
    }
  });

  testWidgets(
    'Telefon 35-36: MonthPage surukle-tasi etkinligi baska gune tasir',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final moved = <(AgendaEntry, DateTime)>[];
      final ev = CalendarEvent(
        id: 'ev-drag',
        title: 'TasimaNotu',
        start: DateTime(2026, 11, 6, 10),
        end: DateTime(2026, 11, 6, 11),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MonthPage(
              month: DateTime(2026, 11),
              data: CalendarData(events: [ev]),
              today: DateTime(2026, 11, 6),
              selected: DateTime(2026, 11, 6),
              firstDow: 1,
              targets: ZoomTargets(),
              onDayTap: (_) {},
              onDayLongPress: (_) {},
              onEntryMove: (entry, day) => moved.add((entry, day)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final drag = await tester.startGesture(
        tester.getCenter(find.text('TasimaNotu')),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await drag.moveTo(tester.getCenter(find.text('18')));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(moved, hasLength(1));
      expect((moved.single.$1 as EventOccurrence).event.id, 'ev-drag');
      expect(moved.single.$2, DateTime(2026, 11, 18));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
