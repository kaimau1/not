import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/presentation/briefing_screen.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/data/google_calendar_sync.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBriefingGemini implements GeminiService {
  final calls = <String>[];

  @override
  Future<String> composeBriefing(String rawData) async {
    calls.add('daily');
    return 'Günaydın, bugünün kısa özeti.';
  }

  @override
  Future<String> composeWeeklyBriefing(String rawData) async {
    calls.add('weekly:$rawData');
    return 'Bu hafta harika ilerledin, gelecek hafta sakin görünüyor.';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('P96 buildWeeklyBriefingInput', () {
    test('son 7 gün notları, tamamlanan/açık görevleri ve gelecek 7 günü toplar; kilitli notu sızdırmaz', () {
      final now = DateTime(2026, 11, 21, 18);
      final notes = [
        Note(
          id: 'n1',
          type: NoteType.text,
          title: 'Proje notu',
          body: 'Yeni ekran tasarlandı',
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        Note(
          id: 'nLocked',
          type: NoteType.text,
          title: 'Gizli kasa',
          body: 'COK_GIZLI_SIFRE_999',
          locked: true,
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        Note(
          id: 'nOld',
          type: NoteType.text,
          title: 'Eski not',
          body: 'Bir ay önce',
          updatedAt: now.subtract(const Duration(days: 30)),
        ),
      ];
      final tasks = [
        TaskItem(
          id: 't1',
          title: 'Bütçe raporu',
          completed: true,
          completedAt: now.subtract(const Duration(days: 1)),
        ),
        const TaskItem(id: 't2', title: 'Dişçi randevusu', due: '2026-11-24'),
      ];
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Ekip toplantısı',
          start: DateTime(2026, 11, 23, 10),
          end: DateTime(2026, 11, 23, 11),
        ),
      ];

      final raw = buildWeeklyBriefingInput(
        now: now,
        notes: notes,
        events: events,
        tasks: tasks,
      );
      expect(raw, contains('Yeni ekran tasarlandı'));
      expect(raw, isNot(contains('COK_GIZLI_SIFRE_999')));
      expect(raw, isNot(contains('Bir ay önce')));
      expect(raw, contains('Bütçe raporu'));
      expect(raw, contains('Dişçi randevusu (2026-11-24)'));
      expect(raw, contains('Ekip toplantısı'));
    });
  });

  group('P96 BriefingScreen Günlük / Haftalık geçişi', () {
    testWidgets('tek ekranda Günlük ve Haftalık özet arasında geçer ve üretir', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeBriefingGemini();
      final notes = [
        Note(
          id: 'n1',
          type: NoteType.text,
          title: 'Hafta notu',
          body: 'Toplantı özeti',
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiUnlimitedProvider.overrideWithValue(true),
            notesStreamProvider.overrideWithValue(AsyncData(notes)),
            calendarRepositoryProvider.overrideWithValue(null),
            googleCalendarEventsProvider.overrideWithValue(const []),
            geminiServiceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BriefingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('briefing-mode-daily')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('briefing-mode-weekly')),
        findsOneWidget,
      );
      expect(find.text('Günaydın, bugünün kısa özeti.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('briefing-mode-weekly')));
      await tester.pumpAndSettle();

      expect(
        find.text('Bu hafta harika ilerledin, gelecek hafta sakin görünüyor.'),
        findsOneWidget,
      );
      expect(fake.calls.any((c) => c.startsWith('weekly:')), isTrue);
    });
  });
}
