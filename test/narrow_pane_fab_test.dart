import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/split_shell.dart';
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
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KT-17 (tablet turu 2026-11-18): bölünmüş görünümün dar liste bölmesinde
/// (~330 dp) "Başa dön" (↑) "+"nın ÜSTÜNDE duruyordu: düğme yığını
/// 16 + 56 + 10 + 40 = 122 dp, listenin altındaki boşluk 96 dp → listenin
/// sonuna inince bile son kartın tarih/etiket satırı ↑'nın arkasında kaldı.
/// Dar bölmede mikrofon ve ⚡ zaten gizli; ↑ artık "+"nın SOLUNDA, aynı
/// satırda — yığın 56 dp, boşluğun içinde.
void main() {
  Future<void> pump(WidgetTester tester, Size size, {bool split = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(
          NotesRepository(FakeFirebaseFirestore(), 'ben'),
        ),
        foldersRepositoryProvider.overrideWithValue(null),
        friendsRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith(
          (ref) => Stream.value([
            for (var i = 0; i < 40; i++)
              Note(id: 'n$i', type: NoteType.text, title: 'Not $i'),
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
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => DashboardPaneScope(
            singleColumn: split,
            child: const DashboardScreen(),
          ),
        ),
      ],
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
    // Aşağı kaydır: ↑ belirsin.
    await tester.dragFrom(
      Offset(size.width / 2, size.height / 2),
      const Offset(0, -1500),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Rect backToTop(WidgetTester tester) => tester.getRect(
    find.ancestor(
      of: find.byTooltip('Başa dön'),
      matching: find.byType(FloatingActionButton),
    ),
  );

  Rect addFab(WidgetTester tester) => tester.getRect(
    find.byWidgetPredicate(
      (w) => w is FloatingActionButton && w.heroTag == 'add-fab',
    ),
  );

  testWidgets('KT-17: dar liste bölmesinde ↑ "+"nın yanında, boşluğun içinde', (
    tester,
  ) async {
    const size = Size(330, 800);
    await pump(tester, size);
    final up = backToTop(tester);
    // Listenin sonundaki boşluk 96 dp: düğmeler bu şeridin içinde kalmalı.
    expect(
      up.top,
      greaterThanOrEqualTo(size.height - 96),
      reason: '↑ son kartın alt satırını örtmemeli (üst: ${up.top})',
    );
    expect(up.right, lessThanOrEqualTo(addFab(tester).left));
  });

  testWidgets('KT-17: telefonda ↑ yine "+"nın üstünde (değişmedi)', (
    tester,
  ) async {
    await pump(tester, const Size(412, 915), split: false);
    final up = backToTop(tester);
    final plus = addFab(tester);
    expect(up.right, lessThanOrEqualTo(plus.right));
    expect(
      up.left,
      greaterThanOrEqualTo(plus.left),
      reason: '↑ "+"nın üstünde',
    );
  });
}
