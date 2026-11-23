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

  testWidgets(
    'masaüstü geniş şeritte bugünün gün adı onPrimary renktedir ve taşma olmaz',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final theme = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F5C54)),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.25),
              ),
              child: Scaffold(
                body: HomeCalendarStripView(
                  today: DateTime(2026, 11, 23),
                  onDayTap: (_) {},
                  onCollapse: () {},
                  data: const CalendarData(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final todayPill = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == theme.colorScheme.primary,
      );
      expect(todayPill, findsOneWidget);
      final textWidget = tester.widget<Text>(
        find.descendant(of: todayPill, matching: find.byType(Text)),
      );
      final rootSpan = textWidget.textSpan! as TextSpan;
      final weekdaySpan = rootSpan.children!.first as TextSpan;
      expect(weekdaySpan.style?.color, theme.colorScheme.onPrimary);
    },
  );
}
