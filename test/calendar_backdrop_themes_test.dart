import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/presentation/home_calendar_strip.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı isteği 2026-11-06: klasik beyaz + saman kâğıdı temaları ve
/// ana ekranda takvim zemini (başlık net, kartın gerisi saydam).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  group('Beyaz ve Saman temaları', () {
    test('seçim aileye eşlenir; eski kayıt adları değişmedi', () {
      expect(AppThemeChoice.white.family, ThemeFamily.white);
      expect(AppThemeChoice.straw.family, ThemeFamily.straw);
      expect(AppThemeChoice.fromStored('white'), AppThemeChoice.white);
      expect(AppThemeChoice.fromStored('straw'), AppThemeChoice.straw);
      // Eski "beyaz" (light) ve "kağıt" (paper) kayıtları göçte kalır.
      expect(AppThemeChoice.fromStored('light'), AppThemeChoice.porcelain);
      expect(AppThemeChoice.fromStored('paper'), AppThemeChoice.clay);
    });

    test('beyazın kâğıdı bembeyaz, samanın masası sarı-sıcak', () {
      final white = AppTheme.of(ThemeFamily.white, Brightness.light);
      expect(AppTokens.fromTheme(white).card, const Color(0xFFFFFFFF));
      final straw = AppTheme.of(ThemeFamily.straw, Brightness.light);
      final hue = HSLColor.fromColor(straw.colorScheme.surface).hue;
      expect(hue, inInclusiveRange(35, 55));
    });
  });

  test('sağa çekiş yalnız Tümü görünümünde ve ayar açıkken takvimi açar', () {
    expect(
      swipeOpensCalendar(enabled: true, direction: -1, atAllNotes: true),
      isTrue,
    );
    // Sola çekiş durak gezer.
    expect(
      swipeOpensCalendar(enabled: true, direction: 1, atAllNotes: true),
      isFalse,
    );
    // Klasör/süzgeç içinde sağa çekiş önceki durağa gider.
    expect(
      swipeOpensCalendar(enabled: true, direction: -1, atAllNotes: false),
      isFalse,
    );
    expect(
      swipeOpensCalendar(enabled: false, direction: -1, atAllNotes: true),
      isFalse,
    );
  });

  group('Takvim şeridi / saydam kart', () {
    testWidgets('ana ekran şeridi: 10 gün, kayıt adı, dokununca gün', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DateTime? tapped;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeCalendarStripView(
              today: DateTime(2026, 11, 6),
              onDayTap: (d) => tapped = d,
              data: CalendarData(
                events: [
                  CalendarEvent(
                    id: 'e',
                    title: 'Diş hekimi',
                    start: DateTime(2026, 11, 12, 14),
                    end: DateTime(2026, 11, 12, 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Diş hekimi'), findsOneWidget);
      // 6–15 Kasım: 10 gün; 16 yok.
      expect(find.textContaining('15'), findsOneWidget);
      expect(find.textContaining('16'), findsNothing);
      await tester.tap(find.text('Diş hekimi'));
      expect(tapped, DateTime(2026, 11, 12));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dar telefonda (360 dp) taşma yok, kayıt nokta olur', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeCalendarStripView(
              today: DateTime(2026, 11, 6),
              onDayTap: (_) {},
              onCollapse: () {},
              data: CalendarData(
                events: [
                  CalendarEvent(
                    id: 'e',
                    title: 'Diş hekimi',
                    start: DateTime(2026, 11, 12, 14),
                    end: DateTime(2026, 11, 12, 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Diş hekimi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
