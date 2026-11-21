import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';
import 'package:notlar/features/calendar/presentation/tasks_screen.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P92: Hafta görünümünde gün+saat sürükle-bırak ve görevlerde elle sıralama.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  group('snapToQuarterHour & movedToDateTime', () {
    test('çeyrek saate yuvarlar ve 00:00..23:45 aralığında sınırlar', () {
      expect(snapToQuarterHour(-20, 60), (hour: 0, minute: 0));
      expect(snapToQuarterHour(0, 60), (hour: 0, minute: 0));
      expect(snapToQuarterHour(8, 60), (hour: 0, minute: 15));
      expect(snapToQuarterHour(9 * 60 + 22, 60), (hour: 9, minute: 15));
      expect(snapToQuarterHour(9 * 60 + 38, 60), (hour: 9, minute: 45));
      expect(snapToQuarterHour(25 * 60, 60), (hour: 23, minute: 45));
    });

    test('saatli etkinliği süresini koruyarak yeni gün ve saate taşır', () {
      final event = CalendarEvent(
        id: 'e1',
        title: 'Toplantı',
        start: DateTime(2026, 11, 9, 10),
        end: DateTime(2026, 11, 9, 11, 30),
      );
      final occ = EventOccurrence(event, event.start);
      final moved =
          movedToDateTime(occ, DateTime(2026, 11, 11, 14, 15))
              as CalendarEvent?;
      expect(moved, isNotNull);
      expect(moved!.allDay, isFalse);
      expect(moved.start, DateTime(2026, 11, 11, 14, 15));
      expect(moved.end, DateTime(2026, 11, 11, 15, 45));
      // Aynı slota bırakma no-op.
      expect(movedToDateTime(occ, DateTime(2026, 11, 9, 10)), isNull);
    });

    test('tüm gün etkinliği saat ızgarasına bırakılınca 1 saatlik olur', () {
      final event = CalendarEvent(
        id: 'e2',
        title: 'Sunum',
        allDay: true,
        start: DateTime(2026, 11, 9),
        end: DateTime(2026, 11, 10),
      );
      final occ = EventOccurrence(event, event.start);
      final moved =
          movedToDateTime(occ, DateTime(2026, 11, 10, 15, 30))
              as CalendarEvent?;
      expect(moved, isNotNull);
      expect(moved!.allDay, isFalse);
      expect(moved.start, DateTime(2026, 11, 10, 15, 30));
      expect(moved.end, DateTime(2026, 11, 10, 16, 30));
    });

    test('görev ve güne bağlı not yeni gün + saatle güncellenir', () {
      const task = TaskItem(
        id: 't1',
        title: 'Rapor',
        due: '2026-11-09',
        dueTime: '09:00',
      );
      final movedTask =
          movedToDateTime(TaskEntry(task), DateTime(2026, 11, 12, 16, 45))
              as TaskItem?;
      expect(movedTask?.due, '2026-11-12');
      expect(movedTask?.dueTime, '16:45');

      const note = Note(id: 'n1', type: NoteType.text, title: 'Not');
      final link = ReminderEntry(
        note,
        DateTime(2026, 11, 9),
        linkDay: '2026-11-09',
      );
      final movedLink =
          movedToDateTime(link, DateTime(2026, 11, 10, 13, 15))
              as DayLinkMove?;
      expect(movedLink?.from, '2026-11-09');
      expect(movedLink?.to, '2026-11-10');
      expect(movedLink?.minutes, 13 * 60 + 15);
    });
  });

  group('reorderedTaskPositions', () {
    test('yalnız konumu değişen görevleri sıfır dolgulu sıralar', () {
      final list = [
        const TaskItem(id: 'a', title: 'A'),
        const TaskItem(id: 'b', title: 'B'),
        const TaskItem(id: 'c', title: 'C'),
      ];
      // a (0) -> son (hedef dizin 2)
      final down = reorderedTaskPositions(list, 0, 2);
      expect(
        {for (final t in down) t.id: t.position},
        {'b': '000001', 'c': '000002', 'a': '000003'},
      );
      // Aynı konuma sürükleme boş döner.
      expect(reorderedTaskPositions(list, 1, 1), isEmpty);

      // Yukarı taşıma: c (2) -> baş (0), konumları zaten dolu iken:
      final positioned = [
        const TaskItem(id: 'a', title: 'A', position: '000001'),
        const TaskItem(id: 'b', title: 'B', position: '000002'),
        const TaskItem(id: 'c', title: 'C', position: '000003'),
      ];
      final up = reorderedTaskPositions(positioned, 2, 0);
      expect(
        {for (final t in up) t.id: t.position},
        {'c': '000001', 'a': '000002', 'b': '000003'},
      );
    });
  });

  group('WeekPage sürükle-bırak', () {
    testWidgets('boş haftada DragTarget kurmaz (S22 bütçesi)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WeekPage(
              weekStart: DateTime(2026, 11, 9),
              data: const CalendarData(),
              today: DateTime(2026, 11, 9),
              now: DateTime(2026, 11, 9, 10),
              onSlotTap: (_) {},
              onEntryTap: (_) {},
              onDayTap: (_) {},
              onEntryMoveToTime: (_, _) {},
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('week-timed-drop-target')), findsNothing);
    });

    testWidgets('saatli etkinliği başka gün ve saate sürükler', (tester) async {
      tester.view.physicalSize = const Size(744, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final event = CalendarEvent(
        id: 'e1',
        title: 'Tasarım',
        start: DateTime(2026, 11, 9, 9),
        end: DateTime(2026, 11, 9, 10),
      );
      AgendaEntry? droppedEntry;
      DateTime? droppedAt;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WeekPage(
              weekStart: DateTime(2026, 11, 9),
              data: CalendarData(events: [event]),
              today: DateTime(2026, 11, 9),
              now: DateTime(2026, 11, 9, 8, 30),
              hourHeight: 60,
              onSlotTap: (_) {},
              onEntryTap: (_) {},
              onDayTap: (_) {},
              onEntryMoveToTime: (entry, target) {
                droppedEntry = entry;
                droppedAt = target;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final blockFinder = find.text('Tasarım');
      expect(blockFinder, findsOneWidget);
      final dropRect = tester.getRect(
        find.byKey(const ValueKey('week-timed-drop-target')),
      );
      final colW = dropRect.width / 7;
      // Hedef: 3. gün (index 2 = 2026-11-11), saat 11:30.
      final targetPoint = Offset(
        dropRect.left + colW * 2.5,
        dropRect.top + 11.5 * 60,
      );

      final gesture = await tester.startGesture(tester.getCenter(blockFinder));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 80));
      await gesture.moveTo(targetPoint);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(droppedEntry, isA<EventOccurrence>());
      expect(droppedAt, DateTime(2026, 11, 11, 11, 30));
    });
  });

  group('TasksScreen elle sıralama', () {
    testWidgets('tutamaktan sürükleyince sıra Firestore\'a yazılır ve korunur', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = FakeFirebaseFirestore();
      final repo = CalendarRepository(db, 'u1');
      repo.saveTask(
        const TaskItem(id: 'a', title: 'Birinci', due: '2026-11-06'),
      );
      repo.saveTask(
        const TaskItem(id: 'b', title: 'İkinci', due: '2026-11-07'),
      );
      repo.saveTask(const TaskItem(id: 'c', title: 'Üçüncü'));

      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            calendarRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            home: TasksScreen(now: DateTime(2026, 11, 6, 12)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Başlangıç sırası: Birinci < İkinci < Üçüncü
      expect(
        tester.getTopLeft(find.text('Birinci')).dy,
        lessThan(tester.getTopLeft(find.text('Üçüncü')).dy),
      );

      final handleA = find.byKey(const ValueKey('task-drag-a'));
      expect(handleA, findsOneWidget);
      final handleC = find.byKey(const ValueKey('task-drag-c'));

      final start = tester.getCenter(handleA);
      final bottomC = tester.getBottomLeft(
        find.byKey(const ValueKey('task-group-c')),
      );
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(Offset(start.dx, tester.getCenter(handleC).dy));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(Offset(start.dx, bottomC.dy + 40));
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.up();
      await tester.pumpAndSettle();

      final docs = await db.collection('users/u1/tasks').get();
      final positions = {
        for (final d in docs.docs) d.id: d.data()['position'] as String?,
      };
      expect(positions['b'], '000001');
      expect(positions['c'], '000002');
      expect(positions['a'], '000003');
      // Yeni sıra ekranda (farklı son tarihlerine rağmen) korunur:
      expect(
        tester.getTopLeft(find.text('İkinci')).dy,
        lessThan(tester.getTopLeft(find.text('Birinci')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Üçüncü')).dy,
        lessThan(tester.getTopLeft(find.text('Birinci')).dy),
      );
    });
  });
}
