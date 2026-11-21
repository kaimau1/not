import 'dart:async';
import 'dart:collection';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
import 'package:notlar/features/folders/data/folder_order.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/drive_store.dart';
import 'package:notlar/features/notes/data/due_state.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/upload_queue.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_scroll_memory.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart';

class _LiveRepo extends NotesRepository {
  _LiveRepo(this.db) : super(db, 'u');
  final FakeFirebaseFirestore db;
  int updateNoteCalls = 0;
  void Function(Note note)? onSaved;

  @override
  Future<void> updateNote(Note note, {bool clientTime = false}) {
    updateNoteCalls++;
    final f = super.updateNote(note, clientTime: clientTime);
    onSaved?.call(note);
    return f;
  }
}

class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();
  @override
  Stream<Never> userChanges() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TrackedNotes extends ListBase<Note> {
  _TrackedNotes(this._inner);
  final List<Note> _inner;
  int reads = 0;
  int iterations = 0;

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) => throw UnsupportedError('readonly');

  @override
  Note operator [](int index) {
    reads++;
    return _inner[index];
  }

  @override
  void operator []=(int index, Note value) =>
      throw UnsupportedError('readonly');

  @override
  Iterator<Note> get iterator {
    iterations++;
    return super.iterator;
  }
}

final class _EchoObserver extends ProviderObserver {
  bool tracking = false;
  final recomputed = <String>[];
  final updated = <String>[];

  String _name(ProviderObserverContext context) => '${context.provider}';

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (!tracking) return;
    recomputed.add(_name(context));
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!tracking) return;
    updated.add(_name(context));
  }
}

void main() {
  testWidgets(
    'T2 (K-22a/K-23/K-26): otomatik kayıt yankısında türetilmiş sağlayıcılar yeniden hesaplanmaz',
    (tester) async {
      DashboardScrollMemory.clear();
      TipOnce.resetSession();
      final now = DateTime.now();
      final open = Note(
        id: 'n',
        type: NoteType.text,
        title: 'Açık not',
        body: 'yazı',
        updatedAt: now,
      );
      final all = <Note>[
        open,
        Note(
          id: 'linker',
          type: NoteType.text,
          title: 'Bağlayan not',
          body: '📎 Açık not',
          tagLinks: const [
            NoteTagLink(label: 'Açık not', attachmentId: 'note:n'),
          ],
          updatedAt: now,
        ),
        for (var i = 0; i < 28; i++)
          Note(
            id: 'x$i',
            type: NoteType.text,
            title: 'Not $i',
            body: 'gövde $i',
            folderId: i < 5 ? 'f1' : null,
            reminderAt: i == 0 ? now.add(const Duration(hours: 2)) : null,
            expiresAt: i == 1 ? now.add(const Duration(days: 1)) : null,
            attachments: i == 2
                ? const [
                    Attachment(
                      id: 'a1',
                      kind: AttachmentKind.image,
                      fileName: 'a.jpg',
                      mimeType: 'image/jpeg',
                      storagePath: 'users/u/a.jpg',
                    ),
                  ]
                : const [],
            updatedAt: now,
          ),
      ];
      final list = StreamController<List<Note>>.broadcast();
      addTearDown(list.close);
      final repo = _LiveRepo(FakeFirebaseFirestore());
      await repo.db
          .collection('users')
          .doc('u')
          .collection('notes')
          .doc('n')
          .set(open.toMap());
      _TrackedNotes? trackedEcho;
      repo.onSaved = (n) {
        trackedEcho = _TrackedNotes([n, ...all.skip(1)]);
        list.add(trackedEcho!);
      };

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: '/note/n',
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
                    pageBuilder: (c, s) => MaterialPage<void>(
                      key: s.pageKey,
                      child: NoteEditorScreen(
                        key: ValueKey(s.pathParameters['id']),
                        noteId: s.pathParameters['id']!,
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
      final observer = _EchoObserver();
      final container = ProviderContainer(
        retry: (_, _) => null,
        observers: [observer],
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(_NoAuth()),
          currentUidProvider.overrideWithValue(null),
          updateRequiredProvider.overrideWithValue(false),
          notesRepositoryProvider.overrideWithValue(repo),
          attachmentRepositoryProvider.overrideWithValue(null),
          foldersRepositoryProvider.overrideWithValue(null),
          notesStreamProvider.overrideWith((ref) => list.stream),
        ],
      );
      addTearDown(container.dispose);
      final badgeSub = container.listen<int>(dueBadgeProvider, (_, _) {});
      addTearDown(badgeSub.close);

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
      list.add(all);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(TextField, 'yazı').first);
      await tester.pump(const Duration(milliseconds: 400));
      tester.testTextInput.enterText('yazı ek');
      await tester.pump(const Duration(milliseconds: 100));

      // Otomatik kayıt + yankı penceresi:
      // ÖNCE: recomputed=20 (10 türetilmiş sağlayıcı), derivedUpdated=4,
      // iterations=11 (330 okuma), toplam widget kurulumu=242
      // (HomeCalendarStrip:1, _DayCell:10, BacklinksChip:1, GuestBackupCard:1).
      observer.tracking = true;
      final counter = BuildCounter()..start();
      await tester.pump(const Duration(milliseconds: 2500));
      counter.stop();
      observer.tracking = false;

      expect(repo.updateNoteCalls, 1);
      expect(observer.recomputed, isEmpty);
      final derivedUpdated = observer.updated
          .where((name) => !name.startsWith('StreamProvider<'))
          .toList();
      expect(derivedUpdated, isEmpty);
      expect(trackedEcho, isNotNull);
      expect(trackedEcho!.iterations, lessThanOrEqualTo(2));
      expect(trackedEcho!.reads, lessThanOrEqualTo(60));
      expect(counter.of('HomeCalendarStrip'), 0);
      expect(counter.of('HomeCalendarStripView'), 0);
      expect(counter.of('_DayCell'), 0);
      expect(counter.of('BacklinksChip'), 0);
      expect(counter.of('GuestBackupCard'), 0);
      final totalBuilds = counter.counts.values.fold<int>(0, (a, b) => a + b);
      expect(totalBuilds, lessThanOrEqualTo(25));

      container.read(dueClockProvider.notifier).armFor(null);
      await endEditor(tester);
    },
  );

  test('T2 doğruluk: ilgili dilim değiştiğinde türetilmiş sağlayıcılar anında güncellenir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final list = StreamController<List<Note>>.broadcast();
    addTearDown(list.close);
    final observer = _EchoObserver();
    final container = ProviderContainer(
      retry: (_, _) => null,
      observers: [observer],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        attachmentSyncModeProvider.overrideWithValue(
          AttachmentSyncMode.storage,
        ),
        notesStreamProvider.overrideWith((ref) => list.stream),
      ],
    );
    addTearDown(container.dispose);

    final subBacklinks = container.listen(
      noteBacklinksProvider('n'),
      (_, _) {},
    );
    final subDue = container.listen(dueItemsProvider, (_, _) {});
    final subCalRem = container.listen(
      calendarReminderNotesProvider,
      (_, _) {},
    );
    final subCalTimed = container.listen(calendarTimedNotesProvider, (_, _) {});
    final subUploads = container.listen(pendingUploadsProvider, (_, _) {});
    final subFolders = container.listen(folderNoteCountsProvider, (_, _) {});
    final subCount = container.listen(allNotesCountProvider, (_, _) {});
    addTearDown(() {
      subBacklinks.close();
      subDue.close();
      subCalRem.close();
      subCalTimed.close();
      subUploads.close();
      subFolders.close();
      subCount.close();
    });

    final now = DateTime.now();
    final n = Note(
      id: 'n',
      type: NoteType.text,
      title: 'Hedef',
      body: 'ilk',
      folderId: 'f1',
      updatedAt: now,
    );
    final linker = Note(
      id: 'l1',
      type: NoteType.text,
      title: 'Bağ 1',
      body: '📎 Hedef',
      tagLinks: const [NoteTagLink(label: 'Hedef', attachmentId: 'note:n')],
      updatedAt: now,
    );
    final reminded = Note(
      id: 'r1',
      type: NoteType.text,
      title: 'Hatırlatıcı',
      reminderAt: now.add(const Duration(hours: 1)),
      expiresAt: now.add(const Duration(days: 1)),
      updatedAt: now,
    );

    list.add([n, linker, reminded]);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(noteBacklinksProvider('n')).map((e) => e.id), ['l1']);
    expect(container.read(allNotesCountProvider), 3);
    expect(container.read(folderNoteCountsProvider)['f1'], 1);
    expect(container.read(calendarReminderNotesProvider).length, 1);
    expect(container.read(calendarTimedNotesProvider).length, 1);
    expect(container.read(dueItemsProvider), isEmpty);
    expect(container.read(pendingUploadsProvider).pending, 0);

    // Yalnız gövde değiştiğinde hiçbir türetilmiş sağlayıcı yeniden hesaplanmaz.
    observer.tracking = true;
    list.add([n.copyWith(body: 'ikinci'), linker, reminded]);
    await Future<void>.delayed(Duration.zero);
    observer.tracking = false;
    expect(observer.recomputed, isEmpty);

    // Yeni geri bağlantı, klasör değişimi, yeni hatırlatıcı ve bekleyen yükleme eklendiğinde güncellenir.
    final linker2 = Note(
      id: 'l2',
      type: NoteType.text,
      title: 'Bağ 2',
      body: '📎 Hedef',
      folderId: 'f2',
      tagLinks: const [NoteTagLink(label: 'Hedef', attachmentId: 'note:n')],
      attachments: const [
        Attachment(
          id: 'att1',
          kind: AttachmentKind.image,
          fileName: 'p.jpg',
          mimeType: 'image/jpeg',
          localPath: 'pubspec.yaml',
        ),
      ],
      reminderAt: now.add(const Duration(hours: 3)),
      expiresAt: now.add(const Duration(days: 2)),
      updatedAt: now,
    );
    list.add([n.copyWith(folderId: 'f2'), linker, reminded, linker2]);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(noteBacklinksProvider('n')).map((e) => e.id), [
      'l1',
      'l2',
    ]);
    expect(container.read(allNotesCountProvider), 4);
    expect(container.read(folderNoteCountsProvider)['f1'], isNull);
    expect(container.read(folderNoteCountsProvider)['f2'], 2);
    expect(container.read(calendarReminderNotesProvider).length, 2);
    expect(container.read(calendarTimedNotesProvider).length, 2);
    expect(container.read(pendingUploadsProvider).pending, 1);
    container.read(dueClockProvider.notifier).armFor(null);
  });
}
