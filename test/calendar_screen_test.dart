import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_alarms.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
import 'package:notlar/features/calendar/presentation/event_editor.dart';
import 'package:notlar/features/calendar/presentation/month_grid.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TAKVIM_PLANI Faz 47: ajanda, ay ızgarası, etkinlik levhası, bildirim planı.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  final meeting = CalendarEvent(
    id: 'm',
    title: 'Toplantı',
    start: DateTime(2026, 11, 6, 14),
    end: DateTime(2026, 11, 6, 15),
    reminders: const [10],
  );
  final trip = CalendarEvent(
    id: 't',
    title: 'Gezi',
    allDay: true,
    start: DateTime(2026, 11, 7),
    end: DateTime(2026, 11, 9),
  );
  final note = Note(
    id: 'n',
    type: NoteType.text,
    title: 'İlaç',
    reminderAt: DateTime(2026, 11, 6, 9),
    reminderRepeat: 'daily',
  );

  group('buildAgenda', () {
    test('etkinlik, görev, hatırlatıcı aynı günde sıralı; tüm gün önce', () {
      final a = buildAgenda(
        from: DateTime(2026, 11, 6),
        to: DateTime(2026, 11, 7),
        events: [meeting],
        tasks: const [TaskItem(id: 'k', title: 'Fatura', due: '2026-11-06')],
        reminderNotes: [note],
      );
      final day = a['2026-11-06']!;
      expect(day.first, isA<TaskEntry>()); // saatsiz görev = gün boyu
      expect(day[1], isA<ReminderEntry>()); // 09:00
      expect(day[2], isA<EventOccurrence>()); // 14:00
    });

    test(
      'çok günlü tüm gün etkinliği her günde; tekrarlı hatırlatıcı açılır',
      () {
        final a = buildAgenda(
          from: DateTime(2026, 11, 6),
          to: DateTime(2026, 11, 10),
          events: [trip],
          reminderNotes: [note],
        );
        expect(a.keys, [
          '2026-11-06',
          '2026-11-07',
          '2026-11-08',
          '2026-11-09',
        ]);
        expect(a['2026-11-07']!.whereType<EventOccurrence>(), hasLength(1));
        expect(a['2026-11-08']!.whereType<EventOccurrence>(), hasLength(1));
        expect(a['2026-11-09']!.whereType<EventOccurrence>(), isEmpty);
        expect(a['2026-11-09']!.whereType<ReminderEntry>(), hasLength(1));
      },
    );
  });

  group('calendarAlarms', () {
    test('ufuktaki hatırlatmalar; geçmiş ve tamamlanmış atlanır', () {
      final alarms = calendarAlarms(
        events: [
          meeting,
          CalendarEvent(
            id: 'w',
            title: 'Spor',
            start: DateTime(2026, 11, 2, 18),
            end: DateTime(2026, 11, 2, 19),
            repeat: 'weekly:1',
            reminders: const [60],
          ),
        ],
        tasks: const [
          TaskItem(id: 'a', title: 'Ara', due: '2026-11-07', reminders: [0]),
          TaskItem(id: 'b', due: '2026-11-07', reminders: [0], completed: true),
        ],
        now: DateTime(2026, 11, 6, 12),
      );
      expect(alarms.map((a) => a.at), [
        DateTime(2026, 11, 6, 13, 50),
        DateTime(2026, 11, 7, 9),
        DateTime(2026, 11, 9, 17),
        DateTime(2026, 11, 16, 17),
      ]);
      expect(alarms.first.payload, 'cal:event:m');
      expect(alarms[1].payload, 'cal:task:a');
      expect(alarms.map((a) => a.notificationId).toSet(), hasLength(4));
    });

    test('tüm gün etkinliği o gün 09:00 sayılır', () {
      final alarms = calendarAlarms(
        events: [
          trip.copyWith(reminders: const [0, 1440]),
        ],
        tasks: const [],
        now: DateTime(2026, 11, 6, 8),
      );
      expect(alarms.map((a) => a.at), [
        DateTime(2026, 11, 6, 9),
        DateTime(2026, 11, 7, 9),
      ]);
    });
  });

  test('ay ızgarası Pazartesiyle başlar', () {
    // Kasım 2026: 1'i Pazar → ızgara 26 Ekim Pazartesi.
    expect(gridStartFor(DateTime(2026, 11), 1), DateTime(2026, 10, 26));
    expect(gridStartFor(DateTime(2026, 11), 0), DateTime(2026, 11));
  });

  test('yeni etkinliğin varsayılan başı', () {
    final now = DateTime(2026, 11, 6, 13, 20);
    expect(defaultEventStart(now, now), DateTime(2026, 11, 6, 14));
    expect(
      defaultEventStart(DateTime(2026, 11, 8), now),
      DateTime(2026, 11, 8, 9),
    );
  });

  group('ekran', () {
    late SharedPreferences prefs;
    late FakeFirebaseFirestore db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = FakeFirebaseFirestore();
    });

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Widget app({
      List<CalendarEvent> events = const [],
      List<Note> reminders = const [],
    }) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        calendarRepositoryProvider.overrideWithValue(
          CalendarRepository(db, 'u1'),
        ),
        eventsStreamProvider.overrideWith((ref) => Stream.value(events)),
        tasksStreamProvider.overrideWith(
          (ref) => Stream.value(const <TaskItem>[]),
        ),
        calendarReminderNotesProvider.overrideWithValue(reminders),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalendarScreen(now: DateTime(2026, 11, 6, 12)),
      ),
    );

    testWidgets('boşken boş durum, düğmeyle yeni etkinlik levhası', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Takvim boş'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.text('Yeni etkinlik'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-title')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('event-title')),
        'Dişçi',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('event-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('event-save')));
      await tester.pumpAndSettle();
      final docs = await db.collection('users/u1/events').get();
      expect(docs.docs.single.data()['title'], 'Dişçi');
      expect(docs.docs.single.data()['reminders'], [10]);
    });

    testWidgets('ajanda: bugün başlığı, etkinlik ve hatırlatıcı', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(app(events: [meeting, trip], reminders: [note]));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bugün ·'), findsOneWidget);
      expect(find.text('Toplantı'), findsOneWidget);
      expect(find.text('14:00 – 15:00'), findsOneWidget);
      expect(find.text('İlaç'), findsWidgets);
      expect(find.text('Gezi'), findsNWidgets(2));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets(
      'telefonda ay ızgarası başlıktan açılır, güne dokununca kapanır',
      (tester) async {
        phone(tester);
        await tester.pumpWidget(app(events: [meeting]));
        await tester.pumpAndSettle();
        expect(find.byType(MonthGrid), findsNothing);
        await tester.tap(find.byKey(const ValueKey('calendar-month-toggle')));
        await tester.pumpAndSettle();
        expect(find.byType(MonthGrid), findsOneWidget);
        await tester.tap(find.text('20'));
        await tester.pumpAndSettle();
        expect(find.byType(MonthGrid), findsNothing);
        expect(find.text('Bu gün için plan yok'), findsOneWidget);
      },
    );

    testWidgets('genişte ay ızgarası hep görünür', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();
      expect(find.byType(MonthGrid), findsOneWidget);
      expect(find.text('Kasım 2026'), findsOneWidget);
    });
  });
}
