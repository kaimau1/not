import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';
import 'package:notlar/features/smart_lists/domain/smart_item_meta.dart';
import 'package:notlar/features/smart_lists/presentation/habit_tracker_workspace.dart';
import 'package:notlar/features/smart_lists/presentation/moving_planner_workspace.dart';
import 'package:notlar/features/smart_lists/presentation/packing_planner_workspace.dart';
import 'package:notlar/features/smart_lists/presentation/smart_domain_workspace.dart';
import 'package:notlar/features/smart_lists/presentation/workout_planner_workspace.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  group('SmartItemMeta domain codecs & S16 zero-overhead rules', () {
    test(
      'HabitItemMeta toggles days, computes streaks, leaves default empty',
      () {
        const bare = NoteItem(id: '1', text: '2L su');
        final def = HabitItemMeta.fromItem(bare).applyToItem(bare);
        expect(def.extras, isEmpty);

        final today = DateTime(2026, 11, 27);
        final meta = const HabitItemMeta()
            .toggledOn(isoDayKey(today.subtract(const Duration(days: 2))))
            .toggledOn(isoDayKey(today.subtract(const Duration(days: 1))))
            .toggledOn(isoDayKey(today));
        expect(meta.currentStreak(today), 3);
        expect(meta.bestStreak(), 3);

        final saved = meta.applyToItem(bare, todayKey: isoDayKey(today));
        expect(saved.checked, isTrue);
        final roundTrip = HabitItemMeta.fromItem(saved);
        expect(roundTrip.doneDays, hasLength(3));
      },
    );

    test('WorkoutItemMeta toggles sets progressively and resets cleanly', () {
      const bare = NoteItem(id: 'w1', text: 'Bench Press');
      final m0 = WorkoutItemMeta.fromItem(bare);
      expect(m0.sets, 3);
      expect(m0.doneSets, 0);

      final m2 = m0.toggleSet(2);
      expect(m2.doneSets, 2);
      final m3 = m2.toggleSet(3);
      expect(m3.doneSets, 3);
      final applied = m3.applyToItem(bare);
      expect(applied.checked, isTrue);

      final undone = m3.toggleSet(3);
      expect(undone.doneSets, 2);
    });

    test('parseExpenseQuickInput extracts numbers cleanly', () {
      final a = parseExpenseQuickInput('Elektrik 850');
      expect(a.title, 'Elektrik');
      expect(a.amount, 850.0);

      final b = parseExpenseQuickInput('Kira 12500 tl');
      expect(b.title, 'Kira');
      expect(b.amount, 12500.0);
    });
  });

  group('Interactive smart workspaces widget tests', () {
    Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: child,
    );

    testWidgets(
      'HabitTrackerWorkspace toggles today circle and updates streak',
      (tester) async {
        List<NoteItem> items = const [NoteItem(id: 'h1', text: 'Kitap oku')];
        await tester.pumpWidget(
          wrap(
            HabitTrackerWorkspace(
              title: 'Alışkanlıklar',
              initialItems: items,
              onReplaceItems: (next) => items = next,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final todayKey = isoDayKey(DateTime.now());
        await tester.tap(find.byKey(ValueKey('habit-day-h1-$todayKey')));
        await tester.pumpAndSettle();

        expect(items.single.checked, isTrue);
        expect(HabitItemMeta.fromItem(items.single).isDoneOn(todayKey), isTrue);
      },
    );

    testWidgets('MovingPlannerWorkspace switches timeline and room views', (
      tester,
    ) async {
      List<NoteItem> items = [
        const MovingItemMeta(
          phase: 'day',
          room: 'kitchen',
          box: 'K3',
          fragile: true,
        ).applyToItem(const NoteItem(id: 'm1', text: 'Bardaklar')),
      ];
      await tester.pumpWidget(
        wrap(
          MovingPlannerWorkspace(
            title: 'Taşınma',
            initialItems: items,
            onReplaceItems: (next) => items = next,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bardaklar'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.meeting_room_outlined));
      await tester.pumpAndSettle();
      expect(find.textContaining('K3'), findsWidgets);
    });

    testWidgets('PackingPlannerWorkspace increments quantity via stepper', (
      tester,
    ) async {
      List<NoteItem> items = const [NoteItem(id: 'p1', text: 'Tişört')];
      await tester.pumpWidget(
        wrap(
          PackingPlannerWorkspace(
            title: 'Bavul',
            initialItems: items,
            onReplaceItems: (next) => items = next,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('packing-plus-p1')));
      await tester.pumpAndSettle();
      expect(items.single.text, contains('2'));
    });

    testWidgets('WorkoutPlannerWorkspace completes sets via set circles', (
      tester,
    ) async {
      List<NoteItem> items = const [NoteItem(id: 'w1', text: 'Squat')];
      await tester.pumpWidget(
        wrap(
          WorkoutPlannerWorkspace(
            title: 'Antrenman',
            initialItems: items,
            onReplaceItems: (next) => items = next,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('workout-set-w1-3')));
      await tester.pumpAndSettle();
      expect(items.single.checked, isTrue);
    });

    testWidgets('SmartDomainWorkspace expense sums amounts live', (
      tester,
    ) async {
      List<NoteItem> items = [
        const ExpenseItemMeta(
          amount: 450,
          category: 'bills',
        ).applyToItem(const NoteItem(id: 'e1', text: 'İnternet')),
        const ExpenseItemMeta(
          amount: 150,
          category: 'market',
        ).applyToItem(const NoteItem(id: 'e2', text: 'Kahve')),
      ];
      await tester.pumpWidget(
        wrap(
          SmartDomainWorkspace(
            kind: SmartListKind.expense,
            title: 'Bütçe',
            initialItems: items,
            onReplaceItems: (next) => items = next,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('600'), findsWidgets);
    });
  });
}
