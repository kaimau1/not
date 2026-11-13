import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/drag_trash_target.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Silmeleri ve sıra kayıtlarını sayan depo (Firestore sahte).
class _TrashRepo extends NotesRepository {
  _TrashRepo() : super(FakeFirebaseFirestore(), 'ben');
  final deleted = <String>[];
  int reorders = 0;

  @override
  void softDelete(String noteId) => deleted.add(noteId);

  @override
  void reorderNotes(List<Note> ordered) => reorders++;
}

/// F60.S9 (kullanıcı 2026-11-11) + F60.S12 (2026-11-12): ana ekranda kart
/// sürüklenirken altta çöp kutusu; hedefe girip BIRAKMAK yeter (bekleme
/// yok), hedef dışında bırakılan not yerinde kalır; yaklaştıkça kart küçülür.
void main() {
  Future<_TrashRepo> pump(WidgetTester tester, {String? folder}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _TrashRepo();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(repo),
        foldersRepositoryProvider.overrideWithValue(null),
        friendsRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith(
          (ref) => Stream.value([
            Note(
              id: 'a',
              type: NoteType.text,
              title: 'Birinci not',
              folderId: folder,
            ),
            Note(
              id: 'b',
              type: NoteType.text,
              title: 'İkinci not',
              folderId: folder,
            ),
          ]),
        ),
        foldersStreamProvider.overrideWith(
          (ref) => Stream.value([
            if (folder != null)
              NoteFolder(id: folder, name: 'İş', ownerId: 'ben'),
          ]),
        ),
        sharedFolderRefsProvider.overrideWith(
          (ref) => Stream.value(const <SharedFolderRef>[]),
        ),
        folderUnreadProvider.overrideWith((ref, key) => 0),
        myNoteSharesProvider.overrideWith((ref) => Stream.value(const {})),
        sharedNotesWithMeProvider.overrideWith(
          (ref) => Stream.value(const <NoteShare>[]),
        ),
        inboxNotesProvider.overrideWith(
          (ref) => Stream.value(const <InboxNote>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const DashboardScreen())],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    if (folder != null) {
      container.read(selectedFolderProvider.notifier).set(folder);
    }
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return repo;
  }

  double trashOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(DragTrashTarget),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  Offset trashCenter(WidgetTester tester) => tester.getCenter(
    find
        .descendant(
          of: find.byType(DragTrashTarget),
          matching: find.byType(CustomPaint),
        )
        .first,
  );

  /// "Birinci not" kartını basılı tutup çöp hedefinin üstüne taşır.
  Future<TestGesture> dragToTrash(WidgetTester tester) async {
    final card = find.ancestor(
      of: find.text('Birinci not'),
      matching: find.byType(NoteCard),
    );
    expect(card, findsOneWidget);
    expect(trashOpacity(tester), 0, reason: 'sürükleme yokken gizli');
    final g = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 700));
    // Hedef kayarak belirir.
    for (var i = 0; i < 4; i++) {
      await g.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(trashOpacity(tester), 1, reason: 'sürüklerken çöp görünür');
    await g.moveTo(trashCenter(tester));
    await tester.pump();
    await g.moveBy(const Offset(1, 1));
    await tester.pump();
    return g;
  }

  // Kullanıcı isteği 2026-11-13: "klasörlerin içinde de çöp kutusu olsun,
  // basılı tutup sürüklerken aynı dashboarddaki gibi". Klasörde elle sıra
  // kapalı (alt küme) — sürükleme yalnız çöpe, sıra yazılmaz.
  testWidgets('klasörün içinde de basılı tut + çöpe bırak = silinir', (
    tester,
  ) async {
    final repo = await pump(tester, folder: 'f1');
    final g = await dragToTrash(tester);
    await g.up();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repo.deleted, ['a']);
    expect(repo.reorders, 0, reason: 'klasörde sıra yazılmaz');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('klasörde oynatmadan bırakınca eskisi gibi seçer', (
    tester,
  ) async {
    final repo = await pump(tester, folder: 'f1');
    final card = find.ancestor(
      of: find.text('Birinci not'),
      matching: find.byType(NoteCard),
    );
    final g = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 700));
    await g.up();
    await tester.pump(const Duration(milliseconds: 300));
    final c = ProviderScope.containerOf(tester.element(card));
    expect(c.read(selectedNoteIdsProvider), {'a'});
    expect(repo.deleted, isEmpty);
    expect(repo.reorders, 0);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('hedefe gelip hemen bırakınca not çöpe gider', (tester) async {
    final repo = await pump(tester);
    final g = await dragToTrash(tester);
    expect(find.text('Bırak: çöpe at'), findsOneWidget);
    await g.up();
    // Kart küçülüp solar, sonra silinir.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repo.deleted, ['a']);
    expect(repo.reorders, 0, reason: 'çöpe giden not sırayı yazmaz');
    expect(find.text('Not silindi'), findsOneWidget);
    // Hedef yeniden gizlenir.
    await tester.pump(const Duration(milliseconds: 400));
    expect(trashOpacity(tester), 0);
    await tester.pump(const Duration(seconds: 5));
  });

  // F60.S12 (a) KANIT (kullanıcı 2026-11-12: "çöp işareti ekranda kalıyor"):
  // kart başka bir kartın üstünden geçince önizleme sırası onu başka
  // sütuna/satıra taşır, sürüklenen hücre ağaçtan çıkar. Flutter KABUL
  // edilen bırakmada `onDragEnd`'i yalnız hâlâ bağlı Draggable'a iletir →
  // `_dragNoteId` temizlenmez, çöp hedefi ekranda kalırdı.
  testWidgets('başka kartın üstünden geçip çöpe bırakınca hedef gizlenir', (
    tester,
  ) async {
    final repo = await pump(tester);
    final card = find.ancestor(
      of: find.text('Birinci not'),
      matching: find.byType(NoteCard),
    );
    final g = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 700));
    await g.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 80));
    final other = find.ancestor(
      of: find.text('İkinci not'),
      matching: find.byType(NoteCard),
    );
    await g.moveTo(tester.getCenter(other));
    await tester.pump();
    await g.moveBy(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 300));
    await g.moveTo(trashCenter(tester));
    await tester.pump();
    await g.moveBy(const Offset(1, 1));
    await tester.pump();
    await g.up();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repo.deleted, ['a']);
    expect(trashOpacity(tester), 0, reason: 'sürükleme bitti, çöp gizli');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('hedef dışında bırakınca not yerinde kalır', (tester) async {
    final repo = await pump(tester);
    final g = await dragToTrash(tester);
    await g.moveBy(const Offset(0, -260));
    await tester.pump();
    await g.up();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repo.deleted, isEmpty);
    expect(find.text('Birinci not'), findsOneWidget);
    expect(trashOpacity(tester), 0);
  });

  /// Sürüklenen kartın görselindeki ölçek (overlay'de).
  double feedbackScale(WidgetTester tester) => tester
      .widget<Transform>(
        find
            .descendant(
              of: find.byType(TrashPullFeedback),
              matching: find.byType(Transform),
            )
            .at(2),
      )
      .transform
      .entry(0, 0); // Transform.scale: köşegen (z ekseni hep 1).

  testWidgets('çöpe yaklaştıkça kart küçülür, uzaklaşınca toparlanır', (
    tester,
  ) async {
    await pump(tester);
    final g = await dragToTrash(tester);
    final near = feedbackScale(tester);
    expect(near, lessThan(0.5), reason: 'hedefte kart küçük');
    await g.moveBy(const Offset(0, -400));
    await tester.pump();
    expect(feedbackScale(tester), closeTo(1, 0.001), reason: 'uzakta tam boy');
    await g.moveTo(trashCenter(tester) + const Offset(0, -150));
    await tester.pump();
    final mid = feedbackScale(tester);
    expect(mid, inExclusiveRange(near, 1), reason: 'yaklaştıkça kademeli');
    await g.up();
    await tester.pump(const Duration(seconds: 1));
    expect(DragTrashTarget.pull.value, isNull);
  });
}
