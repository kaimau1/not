import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/dashboard_wallpapers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/l10n/generated/app_localizations_en.dart';
import 'package:notlar/l10n/generated/app_localizations_tr.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    '18 hazır arka plan zemini benzersiz, varlıkları mevcut ve etiketli',
    () {
      expect(DashboardWallpapers.all.length, greaterThanOrEqualTo(18));
      final ids = <String>{};
      final tr = AppLocalizationsTr();
      final en = AppLocalizationsEn();
      for (final w in DashboardWallpapers.all) {
        expect(
          ids.add(w.id),
          isTrue,
          reason: 'Yinelenen zemin kimliği: ${w.id}',
        );
        expect(
          File(w.asset).existsSync(),
          isTrue,
          reason: 'Eksik zemin varlığı: ${w.asset}',
        );
        expect(w.label(tr), isNot(w.id), reason: 'TR etiketi eksik: ${w.id}');
        expect(w.label(en), isNot(w.id), reason: 'EN etiketi eksik: ${w.id}');
      }
    },
  );

  Future<void> pumpCalendar(WidgetTester tester, {String? preset}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'dashboard_bg_preset': ?preset});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notesStreamProvider.overrideWith((ref) => Stream.value(const <Note>[])),
        eventsStreamProvider.overrideWith((ref) => Stream.value(const [])),
        tasksStreamProvider.overrideWith((ref) => Stream.value(const [])),
        routinesStreamProvider.overrideWith((ref) => Stream.value(const [])),
        routineLogsStreamProvider.overrideWith((ref) => Stream.value(const {})),
        dayLinksStreamProvider.overrideWithValue(const AsyncValue.data({})),
        dayLinkTimesStreamProvider.overrideWithValue(const AsyncValue.data({})),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CalendarScreen(now: DateTime(2026, 11, 25)),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    'seçili zemin takvim ekranında tam ekran uygulanır, AppBar saydam',
    (tester) async {
      await pumpCalendar(tester, preset: DashboardWallpapers.sakuraBreeze);
      final wp = find.byKey(const ValueKey('preset:sakura_breeze'));
      expect(wp, findsOneWidget);
      expect(tester.getRect(wp), const Rect.fromLTWH(0, 0, 412, 915));
      final bar = tester.widget<AppBar>(find.byType(AppBar).first);
      expect(bar.backgroundColor, Colors.transparent);
      expect(bar.systemOverlayStyle?.statusBarIconBrightness, Brightness.dark);
    },
  );

  testWidgets('zemin yokken takvim AppBar varsayılan renkte kalır', (
    tester,
  ) async {
    await pumpCalendar(tester);
    final bar = tester.widget<AppBar>(find.byType(AppBar).first);
    expect(bar.backgroundColor, isNull);
    expect(bar.systemOverlayStyle, isNull);
  });
}
