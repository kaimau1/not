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
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends NotesRepository {
  _Repo() : super(FakeFirebaseFirestore(), 'ben');
  @override
  void reorderNotes(List<Note> ordered) {}
}

/// P56 KANIT (kullanıcı 2026-11-13: "not sıralama iki sütunun arasında
/// geldiğinde anlık bir sağa bir sola geçtiği için aşırı zıplamalar oluyor"):
/// iki sütunlu ana ekranda kart iki sütunun SINIRINDA tutulup parmak birkaç
/// piksel titrerse sıra en çok bir kez değişmeli (eskiden her karede).
void main() {
  testWidgets('sınırda titreyen sürükleme → en çok 1 yer değişimi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(_Repo()),
        foldersRepositoryProvider.overrideWithValue(null),
        friendsRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith(
          (ref) => Stream.value([
            Note(id: 'a', type: NoteType.text, title: 'Birinci not'),
            Note(id: 'b', type: NoteType.text, title: 'İkinci not'),
          ]),
        ),
        foldersStreamProvider.overrideWith(
          (ref) => Stream.value(const <NoteFolder>[]),
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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    Finder card(String title) =>
        find.ancestor(of: find.text(title), matching: find.byType(NoteCard));
    final a = tester.getRect(card('Birinci not'));
    final b = tester.getRect(card('İkinci not'));
    expect(b.left, greaterThan(a.right - 1), reason: 'iki sütun yan yana');
    final boundaryX = (a.right + b.left) / 2;
    bool bLeft() => tester.getCenter(card('İkinci not')).dx < boundaryX;

    final g = await tester.startGesture(a.center);
    await tester.pump(const Duration(milliseconds: 700));
    await g.moveTo(Offset(boundaryX, a.center.dy));
    await tester.pump(const Duration(milliseconds: 16));

    var side = bLeft();
    var flips = 0;
    for (var frame = 0; frame < 60; frame++) {
      // Parmak sınırda ±6 px titriyor (gerçek parmak hiç tam durmaz).
      await g.moveTo(Offset(boundaryX + (frame.isEven ? 6 : -6), a.center.dy));
      await tester.pump(const Duration(milliseconds: 16));
      final now = bLeft();
      if (now != side) flips++;
      side = now;
    }
    expect(flips, lessThanOrEqualTo(1), reason: 'sınırda zıplama');
    await g.up();
    await tester.pump(const Duration(seconds: 5));
  });
}
