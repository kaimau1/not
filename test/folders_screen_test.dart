import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/folders/presentation/folder_tile.dart';
import 'package:notlar/features/folders/presentation/folders_screen.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F79.3 (DENEYIM D19): Klasörler ekranında boş klasör kartı 72 dp
/// (simge + ad + "Boş"), dolu kart 128 dp; ızgarada "Yeni klasör" karosu
/// YOK (aynı iş üst çubuktaki düğmede); sırala düğmesinin ipucu var.
void main() {
  testWidgets(
    'boş klasör kartı kısa, dolu kart tam boy, ızgarada yeni karo yok',
    (tester) async {
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
          notesStreamProvider.overrideWith(
            (ref) => Stream.value(const [
              Note(
                id: 'n',
                type: NoteType.text,
                title: 'Dolu klasörün notu',
                folderId: 'dolu',
              ),
            ]),
          ),
          foldersStreamProvider.overrideWith(
            (ref) => Stream.value(const [
              NoteFolder(id: 'dolu', name: 'Dolu', ownerId: 'ben'),
              NoteFolder(id: 'bos', name: 'Bomboş', ownerId: 'ben'),
            ]),
          ),
          sharedFolderRefsProvider.overrideWith(
            (ref) => Stream.value(const <SharedFolderRef>[]),
          ),
          folderUnreadProvider.overrideWith((ref, key) => 0),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FoldersScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final full = find.byKey(const ValueKey('folder-card-dolu'));
      final empty = find.byKey(const ValueKey('folder-card-bos'));
      expect(full, findsOneWidget);
      expect(empty, findsOneWidget);
      expect(tester.getSize(full).height, FoldersScreen.cardHeight);
      expect(tester.getSize(empty).height, FoldersScreen.emptyCardHeight);
      expect(
        find.descendant(of: empty, matching: find.text('Boş')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: full, matching: find.text('Dolu klasörün notu')),
        findsOneWidget,
      );
      // Aynı satırda: kartlar üste yaslı.
      expect(tester.getTopLeft(full).dy, tester.getTopLeft(empty).dy);
      expect(find.byType(NewFolderTile), findsNothing);
      expect(find.text('Yeni klasör'), findsOneWidget); // üst çubuk düğmesi
      expect(find.byTooltip('Klasörleri sırala'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
