import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_links.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/dashboard_scroll_memory.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart' show BuildCounter, endEditor;

class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

List<Note> _syntheticNotes(int count) {
  final base = DateTime.utc(2026, 11, 27, 12);
  return [
    for (var i = 0; i < count; i++)
      Note(
        id: 'n$i',
        type: i % 5 == 0 ? NoteType.checklist : NoteType.text,
        title: i == count - 7 ? 'Aranan Hedef Not' : 'Sentetik Not $i',
        body: i % 5 == 0
            ? ''
            : 'Örnek içerik satırı $i market toplantı planı #etiket${i % 8}',
        items: i % 5 == 0
            ? [
                NoteItem(id: 'a$i', text: 'Süt $i'),
                NoteItem(id: 'b$i', text: 'Ekmek $i', checked: i.isEven),
              ]
            : const [],
        tags: ['etiket${i % 8}'],
        pinned: i < 6,
        archivedAt: i % 25 == 0 ? base : null,
        updatedAt: base.subtract(Duration(minutes: i)),
        createdAt: base.subtract(Duration(minutes: i)),
        tagLinks: i % 10 == 0 && i > 0
            ? [
                NoteTagLink(
                  label: 'ref',
                  attachmentId: '${kNoteLinkPrefix}n${i - 1}',
                ),
              ]
            : const [],
      ),
  ];
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
  });

  group('K-63 ölçek testi (1.000 ve 3.000 sentetik not)', () {
    for (final count in [1000, 3000]) {
      test(
        'sağlayıcı dizinleri + arama + aday sıralama ($count not)',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final notes = _syntheticNotes(count);
          final sw = Stopwatch()..start();

          final c = ProviderContainer(
            retry: (_, _) => null,
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              authRepositoryProvider.overrideWithValue(_NoAuth()),
              currentUidProvider.overrideWithValue(null),
              updateRequiredProvider.overrideWithValue(false),
              notesRepositoryProvider.overrideWithValue(null),
              attachmentRepositoryProvider.overrideWithValue(null),
              foldersRepositoryProvider.overrideWithValue(null),
              notesStreamProvider.overrideWith((_) => Stream.value(notes)),
            ],
          );
          addTearDown(c.dispose);
          final sub = c.listen(notesStreamProvider, (_, _) {});
          addTearDown(sub.close);
          final debSub = c.listen(debouncedSearchQueryProvider, (_, _) {});
          addTearDown(debSub.close);
          await c.read(notesStreamProvider.future);

          final backlinks = c.read(backlinksIndexProvider);
          final backlinksUs = sw.elapsedMicroseconds;

          final allFiltered =
              c.read(filteredNotesProvider).value ?? const <Note>[];
          final allUs = sw.elapsedMicroseconds - backlinksUs;

          c.read(searchQueryProvider.notifier).set('aranan hedef');
          await Future<void>.delayed(const Duration(milliseconds: 420));
          final searchSw = Stopwatch()..start();
          final hits = c.read(filteredNotesProvider).value ?? const <Note>[];
          final searchUs = searchSw.elapsedMicroseconds;

          final candSw = Stopwatch()..start();
          final candidates = quickDropCandidates(notes, const ['n1', 'n2']);
          final candUs = candSw.elapsedMicroseconds;

          // ignore: avoid_print
          print(
            'K63_PROVIDER_$count backlinks=${backlinksUs}us '
            'filterAll=${allUs}us search=${searchUs}us '
            'candidates=${candUs}us (n=${candidates.length})',
          );

          expect(backlinks['n9'], hasLength(1));
          expect(allFiltered.length, count - (count ~/ 25));
          expect(hits.map((n) => n.id), ['n${count - 7}']);
          expect(candidates, isNotEmpty);
          expect(
            backlinksUs + allUs + searchUs + candUs,
            lessThan(2000 * 1000),
          );
        },
      );

      testWidgets(
        'DashboardScreen tembel kurulum + arama + fırlatma ($count not)',
        (tester) async {
          DashboardScrollMemory.clear();
          TipOnce.resetSession();
          tester.view.physicalSize = const Size(800, 1280);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final notes = _syntheticNotes(count);

          final router = GoRouter(
            initialLocation: '/',
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
                    ],
                  ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);

          final container = ProviderContainer(
            retry: (_, _) => null,
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              authRepositoryProvider.overrideWithValue(_NoAuth()),
              currentUidProvider.overrideWithValue(null),
              updateRequiredProvider.overrideWithValue(false),
              notesRepositoryProvider.overrideWithValue(null),
              attachmentRepositoryProvider.overrideWithValue(null),
              foldersRepositoryProvider.overrideWithValue(null),
              notesStreamProvider.overrideWith((_) => Stream.value(notes)),
            ],
          );
          addTearDown(container.dispose);

          final initSw = Stopwatch()..start();
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
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 500));
          final initMs = initSw.elapsedMilliseconds;

          final visibleInitial = find.byType(NoteCard).evaluate().length;
          expect(visibleInitial, greaterThan(0));
          expect(visibleInitial, lessThan(40));

          final counter = BuildCounter()..start();
          final scrollSw = Stopwatch()..start();
          final scrollable = find.byType(CustomScrollView).first;
          await tester.fling(scrollable, const Offset(0, -1200), 1800);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 500));
          final scrollMs = scrollSw.elapsedMilliseconds;
          final scrollCardBuilds = counter.of('NoteCard');
          counter.stop();

          container.read(searchQueryProvider.notifier).set('Aranan Hedef');
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('Aranan Hedef Not'), findsOneWidget);

          container.read(searchQueryProvider.notifier).set('');
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 200));

          // ignore: avoid_print
          print(
            'K63_UI_$count init=${initMs}ms visibleCards=$visibleInitial '
            'scroll=${scrollMs}ms scrollNoteCardBuilds=$scrollCardBuilds',
          );

          expect(initMs, lessThan(5000));
          expect(scrollMs, lessThan(3000));
          expect(scrollCardBuilds, lessThan(80));
          expect(tester.takeException(), isNull);
          await endEditor(tester);
        },
      );
    }
  });
}
