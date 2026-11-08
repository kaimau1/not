import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/due_items.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/due_banner.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ana ekran şeridi + simge rozeti (2026-11-08).
void main() {
  final now = DateTime(2026, 11, 8, 15);
  final past = Note(
    id: 'a',
    type: NoteType.text,
    title: 'Süt al',
    reminderAt: DateTime(2026, 11, 8, 14),
  );
  final future = Note(
    id: 'b',
    type: NoteType.text,
    title: 'Toplantı',
    reminderAt: DateTime(2026, 11, 8, 18),
  );
  const lateTask = TaskItem(
    id: 't1',
    title: 'Ara',
    due: '2026-11-08',
    dueTime: '13:00',
    noteId: 'a',
    noteItemId: 'i1',
  );
  const todayLater = TaskItem(
    id: 't2',
    title: 'Yürüyüş',
    due: '2026-11-08',
    dueTime: '20:00',
  );
  const done = TaskItem(
    id: 't3',
    title: 'Bitti',
    due: '2026-11-08',
    dueTime: '09:00',
    completed: true,
  );

  List<DueItem> items({Set<String> dismissed = const {}}) => dueItems(
    notes: [past, future],
    tasks: const [lateTask, todayLater, done],
    now: now,
    dismissed: dismissed,
    lockedTitle: '🔒',
  );

  test('zamanı gelenler eskisi önce; gelecektekiler ve bitenler yok', () {
    final l = items();
    expect(l.map((e) => e.title), ['Ara', 'Süt al']);
    expect(l.first.itemId, 'i1');
  });

  test('kapatılan anahtar gizlenir; hatırlatıcı yeniden kurulunca döner', () {
    final key = items().last.key;
    expect(items(dismissed: {key}).map((e) => e.title), ['Ara']);
    final moved = past.copyWith(reminderAt: DateTime(2026, 11, 8, 14, 30));
    final again = dueItems(
      notes: [moved],
      tasks: const [],
      now: now,
      dismissed: {key},
      lockedTitle: '',
    );
    expect(again, hasLength(1));
  });

  test('bir sonraki an: gelecekteki en yakın', () {
    expect(
      nextDueAfter(notes: [past, future], tasks: const [todayLater], now: now),
      DateTime(2026, 11, 8, 18),
    );
  });

  test('rozet: zamanı gelenler + bugünün tamamlanmamış görevleri', () {
    expect(
      badgeCount(
        due: items(),
        tasks: const [lateTask, todayLater, done],
        now: now,
      ),
      3,
    );
  });

  testWidgets('şerit: başlık, +N; ✕ kapatır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final n = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notesStreamProvider.overrideWith(
            (ref) => Stream.value([
              past.copyWith(reminderAt: n.subtract(const Duration(hours: 1))),
              future.copyWith(
                reminderAt: n.subtract(const Duration(minutes: 5)),
              ),
            ]),
          ),
          tasksStreamProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('tr'),
          home: Scaffold(body: DueBanner()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('due-banner')), findsOneWidget);
    expect(find.textContaining('Süt al'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('due-banner-close')));
    await tester.pump();
    expect(find.byKey(const ValueKey('due-banner')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
