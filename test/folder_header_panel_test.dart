import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/folders/presentation/folder_header_panel.dart';
import 'package:notlar/features/folders/presentation/folders_screen.dart';
import 'package:notlar/features/folders/presentation/shared_folder_home.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _makeContainer({
  String? selectedFolder,
  List<NoteFolder>? folders,
  List<Note>? notes,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUidProvider.overrideWithValue('ben'),
      notesRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      notesStreamProvider.overrideWith(
        (ref) => Stream.value(
          notes ??
              const [
                Note(
                  id: 'n1',
                  type: NoteType.text,
                  title: 'Sabit not',
                  folderId: 'work',
                  pinned: true,
                ),
                Note(
                  id: 'n2',
                  type: NoteType.text,
                  title: 'Normal not',
                  folderId: 'work',
                ),
                Note(
                  id: 'n3',
                  type: NoteType.text,
                  title: 'Kişisel not',
                  folderId: 'life',
                ),
              ],
        ),
      ),
      foldersStreamProvider.overrideWith(
        (ref) => Stream.value(
          folders ??
              const [
                NoteFolder(id: 'work', name: 'İş', ownerId: 'ben', color: 1),
                NoteFolder(id: 'life', name: 'Yaşam', ownerId: 'ben', color: 2),
                NoteFolder(
                  id: 'idle',
                  name: 'Taslak',
                  ownerId: 'ben',
                  color: 3,
                ),
              ],
        ),
      ),
      sharedFolderRefsProvider.overrideWith(
        (ref) => Stream.value(const <SharedFolderRef>[]),
      ),
      folderUnreadProvider.overrideWith((ref, key) => 0),
    ],
  );
  if (selectedFolder != null) {
    c.read(selectedFolderProvider.notifier).set(selectedFolder);
  }
  return c;
}

Widget _host(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets(
    'FolderHeaderPanel hides when no folder is selected and shows counts/actions when active',
    (tester) async {
      final c = await _makeContainer();
      addTearDown(c.dispose);
      var created = 0;

      await tester.pumpWidget(
        _host(c, FolderHeaderPanel(onCreateNote: () => created++)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('folder-header-none')), findsOneWidget);
      expect(find.byType(AnimatedSize), findsNothing);

      c.read(selectedFolderProvider.notifier).set('work');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('folder-header-work')), findsOneWidget);
      expect(find.text('İş'), findsOneWidget);
      expect(find.text('2 not'), findsOneWidget);
      expect(find.text('1 sabit'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('folder-header-new-note')));
      await tester.pump();
      expect(created, 1);

      await tester.tap(find.byKey(const ValueKey('folder-header-all')));
      await tester.pumpAndSettle();
      expect(c.read(selectedFolderProvider), isNull);
      expect(find.byKey(const ValueKey('folder-header-none')), findsOneWidget);
    },
  );

  testWidgets(
    'SharedFolderBar renders Bento bar with name, role and chat button',
    (tester) async {
      final c = await _makeContainer();
      addTearDown(c.dispose);

      await tester.pumpWidget(
        _host(
          c,
          const SharedFolderBar(
            folder: (ownerId: 'ayse', folderId: 'shared1'),
            name: 'Ortak Proje',
            role: FolderRole.both,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('shared-folder-bar')), findsOneWidget);
      expect(find.text('Ortak Proje'), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FoldersScreen adapts columns for desktop width and keeps action buttons',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final c = await _makeContainer();
      addTearDown(c.dispose);

      await tester.pumpWidget(_host(c, const FoldersScreen()));
      await tester.pump();
      await tester.pump();

      final workTop = tester.getTopLeft(
        find.byKey(const ValueKey('folder-card-work')),
      );
      final lifeTop = tester.getTopLeft(
        find.byKey(const ValueKey('folder-card-life')),
      );
      final idleTop = tester.getTopLeft(
        find.byKey(const ValueKey('folder-card-idle')),
      );
      // Desktop width lays out 3 folders side by side on the first row
      // (alphabetical fallback order: İş, Taslak, Yaşam).
      expect(workTop.dy, idleTop.dy);
      expect(idleTop.dy, lifeTop.dy);
      expect(workTop.dx, lessThan(idleTop.dx));
      expect(idleTop.dx, lessThan(lifeTop.dx));
      expect(find.byIcon(Icons.note_add_outlined), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
}
