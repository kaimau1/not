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
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F60.S3 (kullanıcı 2026-11-09): "Tümü" DOKUN = ana ekranda bütün notlar
/// (klasör/süzgeç sıfırlanır), UZUN BAS = Klasörler ekranı. Şeritteki her
/// çip: dokun → beklenen küme, YALNIZ dokunulan çip vurgulu.
void main() {
  testWidgets('şerit çipleri: dokun → beklenen küme, tek vurgu', (
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
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
        friendsRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith(
          (ref) => Stream.value(const [
            Note(id: 'k', type: NoteType.text, title: 'Klasörsüz not'),
            Note(
              id: 'f',
              type: NoteType.text,
              title: 'Klasördeki not',
              folderId: 'f1',
            ),
          ]),
        ),
        foldersStreamProvider.overrideWith(
          (ref) => Stream.value(const [
            NoteFolder(id: 'f1', name: 'Benim', ownerId: 'ben'),
          ]),
        ),
        sharedFolderRefsProvider.overrideWith(
          (ref) => Stream.value(const [
            SharedFolderRef(
              folderId: 'f2',
              ownerId: 'ayse',
              name: 'Ortak',
              icon: NoteFolder.defaultIcon,
              role: FolderRole.read,
            ),
          ]),
        ),
        sharedFolderNotesProvider.overrideWith(
          (ref, key) => Stream.value(const [
            Note(
              id: 'o',
              type: NoteType.text,
              title: 'Ortak not',
              folderId: 'f2',
            ),
          ]),
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
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        GoRoute(
          path: '/folders',
          builder: (_, _) => const Scaffold(body: Text('KLASORLER-EKRANI')),
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
    Future<void> settle() async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Set<String> visible() => {
      for (final n in container.read(filteredNotesProvider).value!) n.id,
    };
    // Çip kimlikleri; şerit yatay kaydırılır, ekran dışındaki çip de bulunur.
    const keys = {
      'Tümü': 'all-notes-chip',
      'Gelen': 'shared-hub-chip',
      'Benim': 'folder-chip-f1',
      'Ortak': 'shared-chip-f2',
    };
    Finder chip(String label) =>
        find.byKey(ValueKey(keys[label]!), skipOffstage: false);
    Finder chipLabel(String label) => find.descendant(
      of: chip(label),
      matching: find.text(label, skipOffstage: false),
      skipOffstage: false,
    );
    Future<void> tapChip(String label) async {
      await tester.ensureVisible(chip(label));
      await tester.pump();
      await tester.tap(chipLabel(label));
      await settle();
    }

    // Seçili çip adı kalın (bkz. `_ChipShell`).
    Set<String> highlighted() => {
      for (final label in keys.keys)
        if (tester.widget<Text>(chipLabel(label)).style?.fontWeight ==
            FontWeight.w700)
          label,
    };

    await settle();
    // Varsayılan ana ekran: klasördeki not ana ekranda durmaz.
    expect(visible(), {'k'});
    expect(highlighted(), isEmpty);

    // Klasördeyken "Tümü": hepsi, klasör sıfır (süzgeçliyken şerit gizli).
    await tapChip('Benim');
    expect(visible(), {'f'});
    expect(highlighted(), {'Benim'});
    await tapChip('Tümü');
    expect(router.state.uri.path, '/');
    expect(container.read(selectedFolderProvider), isNull);
    expect(visible(), {'k', 'f'});
    expect(highlighted(), {'Tümü'});
    expect(find.text('Klasördeki not'), findsOneWidget);

    // Tümü açıkken kendi klasörüm: yalnız klasör çipi vurgulu.
    await tapChip('Benim');
    expect(visible(), {'f'});
    expect(highlighted(), {'Benim'});

    // Ev düğmesi: klasör kalkar, "Tümü" seçimi korunur.
    await tester.tap(find.byKey(const ValueKey('home-strip-go-home')));
    await settle();
    expect(container.read(selectedFolderProvider), isNull);
    expect(visible(), {'k', 'f'});
    expect(highlighted(), {'Tümü'});

    // Gelen.
    await tapChip('Gelen');
    expect(container.read(sharedHubOnHomeProvider), isTrue);
    expect(highlighted(), {'Gelen'});

    // Paylaşılan klasör.
    await tapChip('Ortak');
    expect(container.read(selectedSharedFolderProvider), (
      ownerId: 'ayse',
      folderId: 'f2',
    ));
    expect(container.read(sharedHubOnHomeProvider), isFalse);
    expect(find.text('Ortak not'), findsOneWidget);
    expect(highlighted(), {'Ortak'});

    // Uzun bas "Tümü" → Klasörler ekranı.
    await tester.ensureVisible(chip('Tümü'));
    await tester.pump();
    await tester.longPress(chipLabel('Tümü'));
    await settle();
    expect(router.state.uri.path, '/folders');
    expect(find.text('KLASORLER-EKRANI'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
