import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/inbox/presentation/shared_hub_screen.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/shared_note_activity.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'sharedNoteUnreadProvider kendi notumun aynasını okunmamış saymaz',
    () async {
      SharedPreferences.setMockInitialValues({
        'shared_note_seen_v1': '{"":1000}',
      });
      final prefs = await SharedPreferences.getInstance();
      const selfShare = NoteShare(
        ownerId: 'me',
        noteId: 'n1',
        ownerName: 'Ben',
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('me'),
          sharedNotesWithMeProvider.overrideWithValue(
            const AsyncValue.data([selfShare]),
          ),
          ownedNoteStreamProvider((ownerId: 'me', noteId: 'n1'))
              .overrideWithValue(
                AsyncValue.data(
                  Note(
                    id: 'n1',
                    type: NoteType.text,
                    title: 'Kendi notum',
                    updatedBy: 'other',
                    updatedAt: DateTime.fromMillisecondsSinceEpoch(5000),
                  ),
                ),
              ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(sharedNoteUnreadProvider), isEmpty);
      expect(container.read(sharedNotesVisibleCountProvider), 0);
    },
  );

  testWidgets(
    'sharedHubPlaceholder ortak notlar yüklenirken boş mesajı göstermez',
    (tester) async {
      final pendingShares = StreamController<List<NoteShare>>();
      addTearDown(pendingShares.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxNotesProvider.overrideWithValue(const AsyncValue.data([])),
            sharedNotesWithMeProvider.overrideWith(
              (ref) => pendingShares.stream,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) =>
                    sharedHubPlaceholder(context, ref, skeleton: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Burada gelen ya da paylaşılan not yok'), findsNothing);
      pendingShares.add(const []);
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Burada gelen ya da paylaşılan not yok'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'showSharedHubOnHome başka rotadan çağrılınca Gelen açıkken kapatmaz, ana ekrana döner',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      container.read(sharedHubOnHomeProvider.notifier).set(true);
      final router = GoRouter(
        initialLocation: '/folders',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('HOME')),
          GoRoute(
            path: '/folders',
            builder: (context, _) => TextButton(
              onPressed: () => showSharedHubOnHome(context),
              child: const Text('OPEN_HUB'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPEN_HUB'));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(container.read(sharedHubOnHomeProvider), isTrue);
    },
  );
}
