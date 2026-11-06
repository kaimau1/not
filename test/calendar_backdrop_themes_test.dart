import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/presentation/calendar_backdrop.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('sola çekiş yalnız Tümü görünümünde ve ayar açıkken takvimi açar', () {
    expect(
      swipeOpensCalendar(enabled: true, direction: 1, atAllNotes: true),
      isTrue,
    );
    // Sağa çekiş durak gezer.
    expect(
      swipeOpensCalendar(enabled: true, direction: -1, atAllNotes: true),
      isFalse,
    );
    // Klasör/süzgeç içinde sola çekiş sonraki durağa gider.
    expect(
      swipeOpensCalendar(enabled: true, direction: 1, atAllNotes: false),
      isFalse,
    );
    expect(
      swipeOpensCalendar(enabled: false, direction: 1, atAllNotes: true),
      isFalse,
    );
  });

  group('Takvim zemini', () {
    testWidgets('ayın ızgarası: gün, bugün ve kayıt adı çizilir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CalendarBackdropGrid(
              today: DateTime(2026, 11, 6),
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
      expect(find.text('Kasım 2026'), findsOneWidget);
      expect(find.text('Diş hekimi'), findsOneWidget);
      expect(find.text('6'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kartta başlık net, gövde saydam; kipsiz kart değişmez', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const note = Note(
        id: 'n',
        type: NoteType.text,
        title: 'Başlık',
        body: 'gövde yazısı',
      );
      Future<void> pump(bool seeThrough) async {
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentUidProvider.overrideWithValue(null),
              updateRequiredProvider.overrideWithValue(false),
              notesRepositoryProvider.overrideWithValue(null),
              attachmentRepositoryProvider.overrideWithValue(null),
              foldersRepositoryProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              theme: AppTheme.of(ThemeFamily.sage, Brightness.light),
              locale: const Locale('tr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: CardSeeThrough(
                  enabled: seeThrough,
                  child: const Center(
                    child: SizedBox(width: 300, child: NoteCard(note: note)),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }

      double? bodyOpacityOf(String text) => tester
          .widgetList<Opacity>(
            find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
          )
          .map((o) => o.opacity)
          .where((o) => o < 1)
          .firstOrNull;

      await pump(false);
      expect(bodyOpacityOf('gövde yazısı'), isNull);

      await pump(true);
      expect(bodyOpacityOf('gövde yazısı'), CardSeeThrough.bodyOpacity);
      expect(bodyOpacityOf('Başlık'), isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
