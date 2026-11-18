import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/day_key.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';
import 'package:notlar/features/calendar/presentation/home_calendar_strip.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// U4 (kullanıcı isteği 2026-11-18): zamana bağlı notlar (hatırlatıcı +
/// zamanlı not `expiresAt`) takvimde ve ana ekran şeridinde görünür.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  final timed = Note(
    id: 't',
    type: NoteType.text,
    title: 'Kira',
    expiresAt: DateTime(2026, 11, 20, 18),
  );

  test('zamanlı not arşivlenme gününde ajandada', () {
    final agenda = buildAgenda(
      from: DateTime(2026, 11, 18),
      to: DateTime(2026, 11, 25),
      timedNotes: [
        timed,
        // Arşivlenmiş/silinmiş olan görünmez.
        timed.copyWith(archivedAt: DateTime(2026, 11, 1)),
        Note(
          id: 'd',
          type: NoteType.text,
          expiresAt: DateTime(2026, 11, 21),
          deletedAt: DateTime(2026, 11, 1),
        ),
      ],
    );
    expect(agenda.keys, [dayKey(DateTime(2026, 11, 20))]);
    final e = agenda.values.single.single as ReminderEntry;
    expect(e.expiry, isTrue);
    expect(e.at, DateTime(2026, 11, 20, 18));
  });

  test('zamanlı not sürüklenince expiresAt kayar, hatırlatıcı değişmez', () {
    expect(
      canMoveEntry(ReminderEntry(timed, timed.expiresAt!, expiry: true)),
      isTrue,
    );
    final moved = movedToDay(
      ReminderEntry(timed, timed.expiresAt!, expiry: true),
      DateTime(2026, 11, 22),
    ) as Note;
    expect(moved.expiresAt, DateTime(2026, 11, 22, 18));
    expect(moved.reminderAt, isNull);
  });

  testWidgets('ana ekran şeridinde hatırlatıcı ve zamanlı not görünür', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeCalendarStripView(
            today: DateTime(2026, 11, 18),
            onDayTap: (_) {},
            data: CalendarData(
              timedNotes: [timed],
              reminders: [
                Note(
                  id: 'r',
                  type: NoteType.text,
                  title: 'İlaç',
                  reminderAt: DateTime(2026, 11, 19, 9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Kira'), findsOneWidget);
    expect(find.text('İlaç'), findsOneWidget);
  });
}
