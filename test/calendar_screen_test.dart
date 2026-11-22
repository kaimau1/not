import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/data/google_calendar_sync.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_alarms.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';
import 'package:notlar/features/calendar/presentation/week_board.dart';
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

    Future<void> usePrefs(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues({
        'calendar_pinch_hint_v1': true,
        ...values,
      });
      prefs = await SharedPreferences.getInstance();
    }

    setUp(() async {
      await usePrefs({'calendar_view': 'agenda'});
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
      bool googleConnected = false,
    }) => ProviderScope(
      overrides: [
        if (googleConnected)
          googleCalendarProvider.overrideWith(_ConnectedGoogle.new),
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
      // Gün sayfası yönlendirici rotası (2026-11-22; eskiden sayfasız
      // `Navigator.push`).
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => CalendarScreen(now: DateTime(2026, 11, 6, 12)),
            ),
            GoRoute(
              path: '/calendar-day',
              builder: (_, state) => CalendarDayScreen(
                day: DateTime.parse(state.uri.queryParameters['d']!),
                today: DateTime(2026, 11, 6),
              ),
            ),
          ],
        ),
      ),
    );

    testWidgets('boşken boş durum, düğmeyle yeni etkinlik levhası', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Burada henüz etkinlik yok'), findsOneWidget);
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

    // F79.1 (DENEYIM D16): ajanda satırı ölçü birliği — iki satırlı kayıt
    // 64 dp, başlık 16, alt satır 12; çöp düğmesi KALIR (§4 Y11), 48 dp
    // hedef, simge 18.
    testWidgets('ajanda satırı: 64 dp, başlık 16 / alt 12, çöp 48 dp', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();
      final title = tester.widget<Text>(find.text('Toplantı'));
      expect(title.style?.fontSize, 16);
      final sub = tester.widget<Text>(find.text('14:00 – 15:00'));
      expect(sub.style?.fontSize, 12);
      final row = find
          .ancestor(of: find.text('Toplantı'), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(row).height, 64);
      final delete = find.byKey(const ValueKey('calendar-entry-delete')).first;
      expect(tester.getSize(delete).width, greaterThanOrEqualTo(48));
      expect(tester.widget<IconButton>(delete).iconSize, 18);
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

    // P62 PA8 (plan_tasarim_A §6.2): mini ay parmağı izleyen sayfa.
    Finder monthPages() =>
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_MonthPage');
    MonthGrid grid(WidgetTester t) =>
        t.widget<MonthGrid>(find.byType(MonthGrid));
    Future<void> openMonth(WidgetTester tester) async {
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-month-toggle')));
      await tester.pumpAndSettle();
    }

    testWidgets('mini ay parmağı izler: çekerken komşu ay da görünür', (
      tester,
    ) async {
      await openMonth(tester);
      expect(monthPages(), findsOneWidget);
      final g = await tester.startGesture(
        tester.getCenter(find.byType(MonthGrid)),
      );
      await g.moveBy(const Offset(-20, 0));
      await tester.pump();
      await g.moveBy(const Offset(-80, 0));
      await tester.pump();
      expect(monthPages(), findsNWidgets(2), reason: 'komşu ay kuruldu');
      // Yarıdan az çekip bırakınca aynı ay.
      await tester.pump(const Duration(seconds: 1));
      await g.up();
      await tester.pumpAndSettle();
      expect(grid(tester).month, DateTime(2026, 11));
    });

    testWidgets('mini ay fiske: sonraki ay, seçim DEĞİŞMEZ', (tester) async {
      await openMonth(tester);
      final selected = grid(tester).selected;
      await tester.fling(find.byType(MonthGrid), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(grid(tester).month, DateTime(2026, 12));
      expect(grid(tester).selected, selected);
    });

    testWidgets('kaydırma ayarı kapalıyken mini ay kaymaz', (tester) async {
      await usePrefs({'calendar_view': 'agenda', 'calendar_swipe': false});
      await openMonth(tester);
      await tester.fling(find.byType(MonthGrid), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(grid(tester).month, DateTime(2026, 11));
    });

    testWidgets('genişte ‹ › ay ızgarasını animasyonla çevirir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sonraki ay').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(monthPages(), findsNWidgets(2), reason: 'geçiş sürüyor');
      await tester.pumpAndSettle();
      expect(grid(tester).month, DateTime(2026, 12));
      expect(find.text('Aralık 2026'), findsWidgets);
    });

    testWidgets('genişte ay ızgarası hep görünür', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();
      expect(find.byType(MonthGrid), findsOneWidget);
      expect(find.text('Kasım 2026'), findsWidgets);
    });

    /// İki parmağı [center] çevresinde açar (yakınlaştır) ya da kapatır.
    Future<void> pinch(
      WidgetTester tester,
      Offset center, {
      required bool zoomIn,
    }) async {
      final from = zoomIn ? 20.0 : 90.0;
      final to = zoomIn ? 90.0 : 20.0;
      final a = await tester.startGesture(center - Offset(from, 0));
      final b = await tester.startGesture(center + Offset(from, 0));
      for (var i = 1; i <= 6; i++) {
        final d = from + (to - from) * i / 6;
        await a.moveTo(center - Offset(d, 0));
        await b.moveTo(center + Offset(d, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
    }

    testWidgets('varsayılan ay görünümü: etkinlik hücrede ve alt panel açık', (
      tester,
    ) async {
      await usePrefs({});
      phone(tester);
      await tester.pumpWidget(app(events: [meeting, trip]));
      await tester.pumpAndSettle();
      expect(find.byType(MonthPage), findsOneWidget);
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsOneWidget);
      expect(find.text('Kasım 2026'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MonthPage),
          matching: find.text('Toplantı'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MonthPage),
          matching: find.text('Gezi'),
        ),
        findsNWidgets(2),
      );
    });

    // Kullanıcı bulgusu 2026-11-06: "takvimde hangi ay olduğu görülmüyor" —
    // yedi simge telefonda başlığı sıfıra sıkıştırıyordu.
    testWidgets('telefonda ay başlığı okunur genişlikte; ikincil işler ⋮te', (
      tester,
    ) async {
      await usePrefs({});
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final title = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Kasım 2026'),
      );
      expect(title, findsOneWidget);
      expect(tester.getSize(title).width, greaterThan(90));
      expect(find.byKey(const ValueKey('calendar-routines')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('calendar-more')));
      await tester.pumpAndSettle();
      expect(find.text('Rutinler'), findsOneWidget);
      expect(find.text('Görevler'), findsOneWidget);
    });

    // Kullanıcı isteği 2026-11-21: telefonda ay görünümü varsayılan olarak
    // üstte dar takvim + altta gün paneli ile açılır; tutamakla daha da
    // daralır; ✕ veya aşağı çekiş ile uzun takvime geçer; güne dokununca geri açılır.
    testWidgets('telefonda varsayılan gün paneli açık, aşağı çekince uzun takvim', (
      tester,
    ) async {
      await usePrefs({});
      phone(tester);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsOneWidget);
      final half = tester.getSize(find.byType(MonthPage)).height;
      // Kullanıcı isteği 2026-11-21: takvim panelin üstünde ayrıca daralmaz.
      expect(find.byKey(const ValueKey('day-panel-compact')), findsNothing);
      await tester.fling(
        find.byKey(const ValueKey('calendar-month-drag-zone')),
        const Offset(0, -140),
        900,
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(MonthPage)).height, closeTo(half, 1));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('day-panel-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsNothing);
      final full = tester.getSize(find.byType(MonthPage)).height;
      expect(full, greaterThan(half * 1.5));
      // Uzun takvimde güne dokununca panel geri açılır.
      await tester.tap(
        find.descendant(of: find.byType(MonthPage), matching: find.text('18')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsOneWidget);
      expect(tester.getSize(find.byType(MonthPage)).height, closeTo(half, 1));
      // Kullanıcı isteği 2026-11-22: tam sayfaya YALNIZ düğmeyle geçilir;
      // aşağı çekiş paneli kapatmaz.
      await tester.fling(
        find.byKey(const ValueKey('calendar-month-drag-zone')),
        const Offset(0, 140),
        900,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsOneWidget);
      expect(tester.getSize(find.byType(MonthPage)).height, closeTo(half, 1));
    });

    // Kullanıcı isteği 2026-11-22: "bugüne git bulması çok zor, bugünde
    // olmadığımı anlamıyorum" — BUGÜN hapı hep görünür; başka aydayken
    // bugünün yönünü ok ile gösterir, dokununca bugüne döner.
    testWidgets('BUGÜN hapı: başka ayda okla vurgulanır, dokunuş bugüne döner', (
      tester,
    ) async {
      await usePrefs({});
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final pill = find.byKey(const ValueKey('calendar-today'));
      Finder inPill(Finder f) => find.descendant(of: pill, matching: f);
      expect(inPill(find.text('6')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-step-right')));
      await tester.pumpAndSettle();
      expect(find.text('Aralık 2026'), findsOneWidget);
      expect(inPill(find.byIcon(Icons.arrow_back_rounded)), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('calendar-step-left')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Ekim 2026'), findsOneWidget);
      expect(inPill(find.byIcon(Icons.arrow_forward_rounded)), findsOneWidget);
      await tester.tap(pill);
      await tester.pumpAndSettle();
      expect(find.text('Kasım 2026'), findsOneWidget);
      expect(inPill(find.text('6')), findsOneWidget);
      // Gün paneli eylemleri TEK satır.
      final tops = {
        for (final k in ['day-new-event', 'day-new-task', 'day-note'])
          tester.getTopLeft(find.byKey(ValueKey(k))).dy,
      };
      expect(tops, hasLength(1));
    });

    // Kullanıcı isteği 2026-11-07: telefonda da ileri/geri. 2026-11-21: güne
    // çift dokununca o günün HAFTASI (büyük karolu pano); karo başlığı gün
    // sayfasını açar.
    testWidgets('telefonda ileri/geri ay; çift dokunuş hafta panosu', (
      tester,
    ) async {
      await usePrefs({});
      phone(tester);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-step-right')));
      await tester.pumpAndSettle();
      expect(find.text('Aralık 2026'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-step-left')));
      await tester.pumpAndSettle();
      expect(find.text('Kasım 2026'), findsOneWidget);

      final cell = find.descendant(
        of: find.byType(MonthPage),
        matching: find.text('12'),
      );
      await tester.tap(cell);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cell);
      await tester.pumpAndSettle();
      final board = tester.widget<WeekBoardPage>(find.byType(WeekBoardPage));
      expect(board.weekStart, DateTime(2026, 11, 9));
      expect(board.selected, DateTime(2026, 11, 12));
      expect(find.byKey(const ValueKey('week-board-summary')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(const ValueKey('week-board-open-2026-11-12')),
      );
      // Karoda çift dokunuş var: başlığın tek dokunuşu süre dolunca.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDayScreen), findsOneWidget);
      // Ayrıntılı başlık (2026-11-22): büyük "12 Kasım", altında haftanın
      // günü · göreli gün · yılın haftası; özet satırı; "+" yok.
      final dayTitle = DateFormat.MMMMd();
      expect(
        find.text(dayTitle.format(DateTime(2026, 11, 12))),
        findsOneWidget,
      );
      expect(find.text('Perşembe · 6 gün sonra · 46. hafta'), findsOneWidget);
      expect(find.byKey(const ValueKey('day-page-summary')), findsOneWidget);
      expect(find.byKey(const ValueKey('day-page-event')), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.byKey(const ValueKey('day-page-next')));
      await tester.pumpAndSettle();
      expect(
        find.text(dayTitle.format(DateTime(2026, 11, 13))),
        findsOneWidget,
      );
    });

    // Kullanıcı isteği 2026-11-07: tatiller görünür; haftada üstteki güne
    // dokununca gün sayfası; kısa hafta başlığı.
    testWidgets('tatil ay hücresinde; hafta başlığı gün sayfasını açar', (
      tester,
    ) async {
      await usePrefs({});
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-step-left')));
      await tester.pumpAndSettle();
      expect(find.text('29 Ekim Bayramı'), findsOneWidget);
      expect(find.text('Arife'), findsOneWidget);

      // Görünüm düğmeleri hep açık (kullanıcı isteği 2026-11-21).
      await tester.tap(find.byKey(const ValueKey('calendar-view-week')));
      await tester.pumpAndSettle();
      expect(find.byType(WeekBoardPage), findsOneWidget);
      expect(find.textContaining('–'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('week-board-open-2026-09-28')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDayScreen), findsOneWidget);
    });

    testWidgets('tatiller ⋮ menüsünden kapanır', (tester) async {
      await usePrefs({});
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-step-left')));
      await tester.pumpAndSettle();
      expect(find.text('29 Ekim Bayramı'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-holidays-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('29 Ekim Bayramı'), findsNothing);
    });

    // P48 (kullanıcı 2026-11-12): "telefonda eklediğim etkinlikler tablette
    // görülmüyor". Google Takvim bağlantısı CİHAZA özgü (SharedPreferences);
    // bağlı telefonda yeni etkinlik varsayılan Google'a gidiyordu → bağlı
    // olmayan tablet/web görmüyordu. Varsayılan: bütün cihazlarda görünen depo.
    testWidgets('Google bağlıyken de yeni etkinlik bütün cihazlara yazılır', (
      tester,
    ) async {
      phone(tester);
      await prefs.setString('calendar_add_action', 'event');
      await tester.pumpWidget(app(googleConnected: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-new-event')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-target')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('event-title')), 'Yoga');
      await tester.ensureVisible(find.byKey(const ValueKey('event-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('event-save')));
      await tester.pumpAndSettle();
      final docs = await db.collection('users/u1/events').get();
      expect(docs.docs.single.data()['title'], 'Yoga');
    });

    // "Yeni etkinlik açılırken ciddi kasma": klavye levha açıldıktan SONRA.
    testWidgets('yeni etkinlik: başlık odağı açılış animasyonu bitince', (
      tester,
    ) async {
      phone(tester);
      await prefs.setString('calendar_add_action', 'event');
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-new-event')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      EditableText field() => tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('event-title')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field().focusNode.hasFocus, isFalse);
      await tester.pumpAndSettle();
      expect(field().focusNode.hasFocus, isTrue);
    });

    testWidgets('iki parmakla: dokunulan hafta açılır, geri ay ve yıl', (
      tester,
    ) async {
      await usePrefs({});
      phone(tester);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();

      // İçinde bulunulan ayda yakınlaşma BU HAFTAYA gider (kullanıcı isteği
      // 2026-11-22): 18 Kasım'ın üstünde de olsa 2–8 Kasım (bugün 6 Kasım).
      await pinch(tester, tester.getCenter(find.text('18')), zoomIn: true);
      expect(find.byType(MonthPage), findsNothing);
      final week = tester.widget<WeekBoardPage>(find.byType(WeekBoardPage));
      expect(week.weekStart, DateTime(2026, 11, 2));
      expect(prefs.getString('calendar_view'), 'week');

      // Uzaklaştır → Kasım; bir daha → 2026 yılı.
      await pinch(tester, const Offset(206, 500), zoomIn: false);
      expect(
        tester.widget<MonthPage>(find.byType(MonthPage)).month,
        DateTime(2026, 11),
      );
      await pinch(tester, const Offset(206, 500), zoomIn: false);
      expect(find.byType(YearPage), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);

      // Yılda Mart'ın üstünde yakınlaştır → Mart ayı.
      await pinch(tester, tester.getCenter(find.text('Mart')), zoomIn: true);
      expect(
        tester.widget<MonthPage>(find.byType(MonthPage)).month,
        DateTime(2026, 3),
      );
      expect(find.text('Mart 2026'), findsOneWidget);
    });

    // Kullanıcı isteği 2026-11-21: geri sırayla — hafta → ay; açık panel
    // seçimle birlikte kapanır; seçim yoksa ekran kapanır.
    testWidgets('geri: hafta aya döner; panel seçimi bırakarak kapanır', (
      tester,
    ) async {
      await usePrefs({'calendar_view': 'week'});
      phone(tester);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();
      expect(find.byType(WeekBoardPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(WeekBoardPage), findsNothing);
      expect(find.byType(MonthPage), findsOneWidget);
      expect(prefs.getString('calendar_view'), 'month');

      // Başka güne dokun → panel o günle açık.
      await tester.tap(
        find.descendant(of: find.byType(MonthPage), matching: find.text('18')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsOneWidget);
      // Geri: panel KAPANMAZ (tam sayfa yalnız düğmeyle, 2026-11-22),
      // seçim bugüne döner.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsOneWidget);
      expect(
        tester.widget<MonthPage>(find.byType(MonthPage)).selected,
        DateTime(2026, 11, 6),
      );
      // Tam sayfadayken geri paneli geri açar.
      await tester.tap(find.byKey(const ValueKey('day-panel-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-day-panel')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hafta panosu: etkinlik karoda, dokununca düzenleyici', (
      tester,
    ) async {
      await usePrefs({'calendar_view': 'week'});
      phone(tester);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();
      expect(
        tester.widget<WeekBoardPage>(find.byType(WeekBoardPage)).weekStart,
        DateTime(2026, 11, 2),
      );
      expect(find.text('Toplantı'), findsOneWidget);
      // Bağlı olmayan, o hafta yazılmış notlar karoda YOK (2026-11-22).
      await tester.tap(find.text('Toplantı'));
      // Karoda çift dokunuş var (gün sayfası): tek dokunuş süre sonunda.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Etkinliği düzenle'), findsOneWidget);
    });

    testWidgets('hafta panosu: karoya çift dokunuş gün sayfasını açar', (
      tester,
    ) async {
      await usePrefs({'calendar_view': 'week'});
      phone(tester);
      await tester.pumpWidget(app(events: [meeting]));
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('week-board-tile-2026-11-04'));
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDayScreen), findsOneWidget);
    });

    testWidgets('+ varsayılan NOT: tarih levhası açılır', (tester) async {
      await usePrefs({'calendar_view': 'week'});
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-new-event')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('new-day-note-date')), findsOneWidget);
      expect(
        find.text(DateFormat.yMMMMEEEEd().format(DateTime(2026, 11, 6))),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('new-day-note-open')), findsOneWidget);
    });

    testWidgets('yılda aya dokunmak o ayı açar; görünüm menüsü', (
      tester,
    ) async {
      await usePrefs({'calendar_view': 'year'});
      phone(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(YearPage), findsOneWidget);
      await tester.tap(find.text('Haziran'));
      await tester.pumpAndSettle();
      expect(find.text('Haziran 2026'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('calendar-view-agenda')));
      await tester.pumpAndSettle();
      expect(find.byType(MonthPage), findsNothing);
      expect(find.text('Burada henüz etkinlik yok'), findsOneWidget);
    });

    test('çakışan bloklar yan yana', () {
      DateTime t(int h, [int m = 0]) => DateTime(2026, 11, 6, h, m);
      final blocks = layoutTimedBlocks([
        TimedBlock(EventOccurrence(meeting, t(9)), t(9), t(10)),
        TimedBlock(EventOccurrence(meeting, t(9, 30)), t(9, 30), t(11)),
        TimedBlock(EventOccurrence(meeting, t(10)), t(10), t(10, 30)),
        TimedBlock(EventOccurrence(meeting, t(12)), t(12), t(13)),
      ]);
      expect(
        [for (final b in blocks) (b.column, b.columns)],
        [(0, 2), (1, 2), (0, 2), (0, 1)],
      );
    });
  });
}

/// Google Takvim'e bağlı cihaz (yazma izni yok — Google yoluna düşerse
/// kayıt hiç yapılmaz).
class _ConnectedGoogle extends GoogleCalendarController {
  @override
  GoogleCalendarState build() => const GoogleCalendarState(connected: true);

  @override
  Future<bool> connectWrite() async => false;
}
