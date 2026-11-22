import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';
import 'package:notlar/features/calendar/presentation/home_calendar_strip.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı isteği 2026-11-22: telefonda (7 dar hücre) kayıtlı günde yalnız
/// nokta değil, kaydın İLK KELİMESİ görünür.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  testWidgets('dar hücrede kaydın ilk kelimesi yazılır', (tester) async {
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeCalendarStripView(
            today: DateTime(2026, 11, 22),
            onDayTap: (_) {},
            onCollapse: () {},
            data: CalendarData(
              reminders: [
                Note(
                  id: 'r',
                  type: NoteType.text,
                  title: 'Doktor randevusu',
                  reminderAt: DateTime(2026, 11, 27, 9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Doktor'), findsOneWidget);
    expect(find.text('Doktor randevusu'), findsNothing);
  });
}
