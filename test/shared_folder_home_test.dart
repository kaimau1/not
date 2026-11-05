import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_icons.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/auth/presentation/account_required.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/folders/presentation/folder_nav.dart';
import 'package:notlar/features/folders/presentation/shared_folder_home.dart';
import 'package:notlar/features/inbox/presentation/shared_hub_screen.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_clipboard.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F43.2 (K8): paylaşılan klasör süzgeçli ana ekran; F43.4, F43.5.
void main() {
  const folder = (ownerId: 'ayse', folderId: 'f1');
  SharedFolderRef refOf(FolderRole role) => SharedFolderRef(
    folderId: 'f1',
    ownerId: 'ayse',
    name: 'Ortak',
    icon: NoteFolder.defaultIcon,
    role: role,
  );

  Note note(String id, String title, {bool starred = false}) => Note(
    id: id,
    type: NoteType.text,
    title: title,
    starred: starred,
    folderId: 'f1',
  );

  Future<ProviderContainer> pump(
    WidgetTester tester,
    FolderRole role, {
    List<Note> notes = const [],
    String query = '',
    void Function(ProviderContainer)? setup,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        folderUnreadProvider.overrideWith((ref, key) => 0),
        myNoteSharesProvider.overrideWith((ref) => Stream.value(const {})),
        sharedFolderRefsProvider.overrideWith(
          (ref) => Stream.value([refOf(role)]),
        ),
        sharedFolderNotesProvider.overrideWith(
          (ref, key) => Stream.value(notes),
        ),
      ],
    );
    addTearDown(container.dispose);
    setup?.call(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            floatingActionButton: const SharedFolderFab(folder: folder),
            body: Consumer(
              builder: (context, ref, _) => CustomScrollView(
                slivers: sharedFolderSlivers(
                  context,
                  ref,
                  folder: folder,
                  columns: 2,
                  cellWidth: 180,
                  query: query,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    container.listen(sharedFolderRefsProvider, (_, _) {});
    await tester.pump();
    await tester.pump();
    return container;
  }

  group('süzgeç durumu', () {
    late BuildContext ctx;
    Future<ProviderContainer> host(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          currentUidProvider.overrideWithValue('ben'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return container;
    }

    testWidgets('paylaşılan klasör ayrı sayfa açmaz, ana ekranı süzer', (
      tester,
    ) async {
      final c = await host(tester);
      c.read(selectedFolderProvider.notifier).set('kendi');
      c.read(sharedHubOnHomeProvider.notifier).set(true);
      final routes = Navigator.of(ctx);
      openFolder(ctx, 'f1', ownerId: 'ayse');
      await tester.pump();
      expect(c.read(selectedSharedFolderProvider), folder);
      expect(c.read(selectedFolderProvider), isNull);
      expect(c.read(sharedHubOnHomeProvider), isFalse);
      expect(routes.canPop(), isFalse);
    });

    testWidgets('kendi klasörüm ve Gelen paylaşılan süzgeci kapatır', (
      tester,
    ) async {
      final c = await host(tester);
      openFolder(ctx, 'f1', ownerId: 'ayse');
      openFolder(ctx, 'kendi');
      expect(c.read(selectedSharedFolderProvider), isNull);
      expect(c.read(selectedFolderProvider), 'kendi');

      openFolder(ctx, 'f1', ownerId: 'ayse');
      showSharedHubOnHome(ctx);
      expect(c.read(selectedSharedFolderProvider), isNull);
      expect(c.read(sharedHubOnHomeProvider), isTrue);
    });

    testWidgets('sahibi bensem kendi klasörüm sayılır', (tester) async {
      final c = await host(tester);
      openFolder(ctx, 'f2', ownerId: 'ben');
      expect(c.read(selectedSharedFolderProvider), isNull);
      expect(c.read(selectedFolderProvider), 'f2');
    });
  });

  group('yetki', () {
    testWidgets('salt okunur: kilitli şerit, ekleme düğmesi yok', (
      tester,
    ) async {
      await pump(tester, FolderRole.read, notes: [note('a', 'Birinci')]);
      expect(find.text('Paylaşılan klasör · Okuma'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SharedFolderBar),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('shared-folder-add')), findsNothing);
      expect(find.text('Birinci'), findsOneWidget);
    });

    testWidgets('okuma + yazma: kilit yok, ekleme düğmesi var', (tester) async {
      await pump(tester, FolderRole.both, notes: [note('a', 'Birinci')]);
      expect(
        find.descendant(
          of: find.byType(SharedFolderBar),
          matching: find.byIcon(AppIcons.shared),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('shared-folder-add')), findsOneWidget);
    });

    testWidgets('yalnız yazma: notlar yerine açıklama, ekleme düğmesi var', (
      tester,
    ) async {
      await pump(tester, FolderRole.write, notes: [note('a', 'Gizli')]);
      expect(find.text('Yalnız yazma yetkin var'), findsOneWidget);
      expect(find.text('Gizli'), findsNothing);
      expect(find.byKey(const ValueKey('shared-folder-add')), findsOneWidget);
    });

    testWidgets('boş klasörde salt okunur için eylem yok', (tester) async {
      await pump(tester, FolderRole.read);
      expect(find.text('Metin notu'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('kendi klasördeki gibi süzülür', () {
    testWidgets('arama kutusu', (tester) async {
      await pump(
        tester,
        FolderRole.both,
        notes: [note('a', 'Elma'), note('b', 'Armut')],
        query: 'elma',
      );
      expect(find.text('Armut'), findsNothing);
      expect(find.byType(SharedFolderBar), findsOneWidget);
    });

    testWidgets('Süz: durum süzgeci', (tester) async {
      await pump(
        tester,
        FolderRole.both,
        notes: [note('a', 'Elma', starred: true), note('b', 'Armut')],
        setup: (c) =>
            c.read(noteFilterProvider.notifier).set(NoteFilter.starred),
      );
      expect(find.text('Elma'), findsOneWidget);
      expect(find.text('Armut'), findsNothing);
    });
  });

  test('yana çekiş durağı kendi klasör kimliğiyle çakışmaz', () {
    expect(sharedFolderStopId(refOf(FolderRole.both)), 'ayse/f1');
  });

  testWidgets('F43.4: ek dosyası yoksa tek açıklama (not ve ek aynı yol)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late BuildContext ctx;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ctx = context;
                widgetRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    final l10n = AppLocalizations.of(ctx);
    await shareAttachmentFiles(ctx, widgetRef, const <Attachment>[], subject: 's');
    await tester.pump();
    expect(find.text(l10n.shareAttachmentFilesNone), findsOneWidget);
  });

  testWidgets('F43.5: menü maddesi kilit rozetini taşır', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showActionMenuSheet(
                context,
                const ActionMenu(
                  sections: [],
                  quick: [
                    MenuAction(
                      'collaborators',
                      'Ortak çalışanlar',
                      Icons.person_add_alt_1_outlined,
                      badge: AccountLockBadge(size: 14),
                    ),
                  ],
                ),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountLockBadge), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
