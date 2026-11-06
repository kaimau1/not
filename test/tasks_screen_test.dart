import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/tasks_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TAKVIM_PLANI F50.1: görevler ekranı gerçek (sahte Firestore) depoyla.
void main() {
  late FakeFirebaseFirestore db;
  late CalendarRepository repo;
  late SharedPreferences prefs;

  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = FakeFirebaseFirestore();
    repo = CalendarRepository(db, 'u1');
  });

  Future<void> pump(WidgetTester tester) async {
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
  }

  testWidgets('görev ekle, tamamla, tamamlananlarda görün', (tester) async {
    await pump(tester);
    expect(find.text('Görev yok'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tasks-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('task-title')), 'Süt al');
    await tester.ensureVisible(find.byKey(const ValueKey('task-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-save')));
    await tester.pumpAndSettle();
    expect(find.text('Süt al'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Süt al'), findsNothing);
    expect(find.text('Tamamlananlar (1)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tasks-completed-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Süt al'), findsOneWidget);
  });

  testWidgets('yeni liste çipi listeyi açar; görev o listeye düşer', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Yeni liste'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'İş');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'İş'), findsOneWidget);
    final selected = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'İş'),
    );
    expect(selected.selected, isTrue);

    await tester.tap(find.byKey(const ValueKey('tasks-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('task-title')), 'Rapor');
    await tester.ensureVisible(find.byKey(const ValueKey('task-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-save')));
    await tester.pumpAndSettle();
    final tasks = await db.collection('users/u1/tasks').get();
    final lists = await db.collection('users/u1/taskLists').get();
    expect(tasks.docs.single.data()['listId'], lists.docs.single.id);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Görevlerim'));
    await tester.pumpAndSettle();
    expect(find.text('Rapor'), findsNothing);
  });

  testWidgets('alt görev girintili, gecikmiş görev işaretli', (tester) async {
    repo.saveTask(const TaskItem(id: 'p', title: 'Taşınma', due: '2026-11-01'));
    await pump(tester);
    expect(find.text('Taşınma'), findsOneWidget);
    expect(find.textContaining('Gecikti'), findsOneWidget);
    await tester.tap(find.byTooltip('Alt görev ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('task-title')), 'Kutu');
    await tester.ensureVisible(find.byKey(const ValueKey('task-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-save')));
    await tester.pumpAndSettle();
    final parentX = tester.getTopLeft(find.text('Taşınma')).dx;
    final childX = tester.getTopLeft(find.text('Kutu')).dx;
    expect(childX, greaterThan(parentX));
  });
}
