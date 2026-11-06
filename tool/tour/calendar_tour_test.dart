// Takvim görsel turu (TAKVIM_PLANI F47.7): yıl / ay / hafta / ajanda,
// telefon ve tablet, Firebase'siz sahte verilerle → build/tour/takvim-*.png.
// Kullanım: flutter test tool/tour/calendar_tour_test.dart
// (koyu: TOUR_DARK=1, çıktı: TOUR_OUT=...). CI'da koşmaz (test/ dışında).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final icons = File(
    '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
  for (final w in ['Regular', 'Medium', 'Bold']) {
    final f = File('$sdk/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
    if (!f.existsSync()) continue;
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }
}

DateTime _d(int day, [int h = 0, int m = 0]) => DateTime(2026, 11, day, h, m);

final _events = [
  CalendarEvent(
    id: '1',
    title: 'Proje toplantısı',
    start: _d(6, 10),
    end: _d(6, 11, 30),
    reminders: const [10],
  ),
  CalendarEvent(
    id: '2',
    title: 'Diş hekimi',
    start: _d(6, 10, 30),
    end: _d(6, 11),
    color: 0xFFB5651D,
  ),
  CalendarEvent(
    id: '3',
    title: 'Spor',
    start: _d(2, 18),
    end: _d(2, 19),
    repeat: 'weekly:1,3',
    color: 0xFF4E8C6A,
  ),
  CalendarEvent(
    id: '4',
    title: 'İzmir gezisi',
    allDay: true,
    start: _d(13),
    end: _d(16),
    color: 0xFF5B6EAE,
  ),
  CalendarEvent(
    id: '5',
    title: 'Annemin doğum günü',
    allDay: true,
    start: _d(21),
    end: _d(22),
    repeat: 'yearly',
  ),
  CalendarEvent(
    id: '6',
    title: 'Öğle yemeği · Ayşe',
    start: _d(4, 12, 30),
    end: _d(4, 13, 30),
  ),
];

const _tasks = [
  TaskItem(id: 't1', title: 'Faturayı öde', due: '2026-11-06'),
  TaskItem(
    id: 't2',
    title: 'Rapor taslağı',
    due: '2026-11-05',
    dueTime: '17:00',
  ),
  TaskItem(id: 't3', title: 'Kitap iade', due: '2026-11-10'),
];

final _reminders = [
  Note(
    id: 'n1',
    type: NoteType.text,
    title: 'İlaç',
    reminderAt: _d(6, 9),
    reminderRepeat: 'daily',
  ),
];

void main() {
  setUpAll(() async {
    await _loadFonts();
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  final dark = Platform.environment['TOUR_DARK'] == '1';
  final out = Platform.environment['TOUR_OUT'] ?? 'build/tour';

  for (final size in const [Size(412, 915), Size(1280, 800)]) {
    for (final view in ['year', 'month', 'week', 'agenda']) {
      final name =
          'takvim-${size.width < 600 ? 'telefon' : 'tablet'}-$view'
          '${dark ? '-koyu' : ''}';
      testWidgets(name, (tester) async {
        SharedPreferences.setMockInitialValues({
          'calendar_view': view,
          'calendar_pinch_hint_v1': true,
        });
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                calendarRepositoryProvider.overrideWithValue(
                  CalendarRepository(FakeFirebaseFirestore(), 'u'),
                ),
                eventsStreamProvider.overrideWith(
                  (ref) => Stream.value(_events),
                ),
                tasksStreamProvider.overrideWith((ref) => Stream.value(_tasks)),
                calendarReminderNotesProvider.overrideWithValue(_reminders),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.of(
                  ThemeFamily.sage,
                  dark ? Brightness.dark : Brightness.light,
                ),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                locale: const Locale('tr'),
                supportedLocales: AppLocalizations.supportedLocales,
                home: CalendarScreen(now: _d(6, 14, 20)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$out/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
