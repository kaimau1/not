import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı istekleri (2026-11-21):
/// 1. Takvim varsayılan olarak üstte dar ay ızgarası + altta gün paneli ile
///    açılır; aşağı çekince uzun ay görünümüne geçer.
/// 2. Gün sayıları kutuların SAĞ ÜSTÜNDE, kalan boşlukta notlar ve etiketler.
/// 3. Hücredeki ya da alt paneldeki nota dokunulunca zengin önizleme açılır.
/// 4. Alt panelde bağlı not varken "Bu gün için plan yok" yazmaz, birden
///    fazla not eklenebilir, dış FAB düğmelere binmez.
/// 5. İlgisiz not değişiklikleri takvim verisini yeniden kurmaz (kasma koruması).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });

  late SharedPreferences prefs;
  late FakeFirebaseFirestore db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'calendar_pinch_hint_v1': true});
    prefs = await SharedPreferences.getInstance();
    db = FakeFirebaseFirestore();
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildApp({
    required List<Note> notes,
    Map<String, List<String>> dayLinks = const {},
    Map<String, Map<String, int>> dayLinkTimes = const {},
    Stream<List<Note>>? notesStream,
  }) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      calendarRepositoryProvider.overrideWithValue(
        CalendarRepository(db, 'u1'),
      ),
      eventsStreamProvider.overrideWith(
        (ref) => Stream.value(const <CalendarEvent>[]),
      ),
      tasksStreamProvider.overrideWith(
        (ref) => Stream.value(const <TaskItem>[]),
      ),
      notesStreamProvider.overrideWith(
        (ref) => notesStream ?? Stream.value(notes),
      ),
      dayLinksStreamProvider.overrideWithValue(AsyncValue.data(dayLinks)),
      dayLinkTimesStreamProvider.overrideWithValue(
        AsyncValue.data(dayLinkTimes),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: CalendarScreen(now: DateTime(2026, 11, 24, 12)),
    ),
  );

  testWidgets(
    'gün numarası kutunun sağ üstünde; hücrede not + etiket görünür ve dokununca önizleme açılır',
    (tester) async {
      phone(tester);
      final note = Note(
        id: 'n-deneme',
        type: NoteType.text,
        title: 'Deneme',
        body: 'Takvim hücresinden açılan tam önizleme içeriği.',
        tags: const ['İş'],
        attachments: const [
          Attachment(
            id: 'a1',
            kind: AttachmentKind.image,
            fileName: 'foto.jpg',
            mimeType: 'image/jpeg',
          ),
        ],
      );
      await tester.pumpWidget(
        buildApp(
          notes: [note],
          dayLinks: const {
            '2026-11-24': ['n-deneme'],
          },
          dayLinkTimes: const {
            '2026-11-24': {'n-deneme': 9 * 60 + 30},
          },
        ),
      );
      await tester.pumpAndSettle();

      // 1. Gün numarası '24' kendi hücresinin sağ üst çeyreğinde.
      final day24Text = find.descendant(
        of: find.byType(MonthPage),
        matching: find.text('24'),
      );
      expect(day24Text, findsOneWidget);
      final cellMaterial = find
          .ancestor(of: day24Text, matching: find.byType(Material))
          .first;
      final cellRect = tester.getRect(cellMaterial);
      final numRect = tester.getRect(day24Text);
      expect(
        numRect.center.dx,
        greaterThan(cellRect.center.dx),
        reason: 'gün sayısı kutunun sağında olmalı',
      );
      expect(
        numRect.center.dy,
        lessThan(cellRect.center.dy),
        reason: 'gün sayısı kutunun üstünde olmalı',
      );

      // 2. Hücrenin kalan boşluğunda not başlığı (saatli) ve #İş etiketi.
      final chipInMonth = find.descendant(
        of: find.byType(MonthPage),
        matching: find.text('09:30 Deneme'),
      );
      expect(chipInMonth, findsOneWidget);
      expect(
        find.descendant(of: find.byType(MonthPage), matching: find.text('#İş')),
        findsOneWidget,
      );

      // 3. Alt panelde bağlı not varken "Bu gün için plan yok" YAZMAZ ve dış FAB gizli.
      expect(find.text('Bu gün için plan yok'), findsNothing);
      expect(find.byKey(const ValueKey('day-panel-count')), findsOneWidget);
      expect(find.byKey(const ValueKey('calendar-new-event')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('linked-note-n-deneme')),
          matching: find.text('Takvim hücresinden açılan tam önizleme içeriği.'),
        ),
        findsOneWidget,
      );

      // 4. Hücredeki not şeridine dokununca zengin önizleme levhası açılır.
      await tester.tap(chipInMonth);
      // Hücrede çift dokunuş da var: tek dokunuş bekleme süresinden sonra.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('calendar-note-preview-n-deneme')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('calendar-note-preview-open')),
        findsOneWidget,
      );
      expect(find.text('Notu aç'), findsOneWidget);
    },
  );

  testWidgets(
    'alt paneldeki liste/kilitli not kartları önizleme gösterir; karta dokununca önizleme levhası açılır',
    (tester) async {
      phone(tester);
      final checklistNote = Note(
        id: 'n-list',
        type: NoteType.checklist,
        title: 'Market',
        items: const [
          NoteItem(id: 'i1', text: 'Süt al', checked: true),
          NoteItem(id: 'i2', text: 'Ekmek al'),
        ],
        tags: const ['Ev'],
      );
      final lockedNote = Note(
        id: 'n-lock',
        type: NoteType.text,
        title: 'Özel',
        body: 'Gizli metin asla görünmemeli',
        locked: true,
      );
      await tester.pumpWidget(
        buildApp(
          notes: [checklistNote, lockedNote],
          dayLinks: const {
            '2026-11-24': ['n-list', 'n-lock'],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Liste maddeleri kart içinde önizleme olarak görünür.
      expect(find.text('Süt al'), findsOneWidget);
      expect(find.text('Ekmek al'), findsOneWidget);
      // Kilitli notun gövdesi gizlenir.
      expect(find.text('Gizli metin asla görünmemeli'), findsNothing);
      expect(find.text('Kilitli not'), findsOneWidget);

      // Alt paneldeki karta dokununca hızlı önizleme levhası açılır.
      await tester.tap(find.byKey(const ValueKey('linked-note-n-list')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('calendar-note-preview-n-list')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('calendar-note-preview-open')),
        findsOneWidget,
      );
    },
  );

  test(
    'ilgisiz not düzenlemesi calendarDayNotesProvider\'ı yeniden kurmaz',
    () async {
      final controller = StreamController<List<Note>>.broadcast();
      addTearDown(controller.close);
      final linked = Note(
        id: 'n1',
        type: NoteType.text,
        title: 'Bağlı Not',
        body: 'Sabit gövde',
      );
      final unrelated = Note(
        id: 'n2',
        type: NoteType.text,
        title: 'Başka Not',
        body: 'İlk metin',
      );
      final container = ProviderContainer(
        overrides: [
          notesStreamProvider.overrideWith((ref) => controller.stream),
          dayLinksStreamProvider.overrideWithValue(
            const AsyncValue.data({
              '2026-11-24': ['n1'],
            }),
          ),
          dayLinkTimesStreamProvider.overrideWithValue(
            const AsyncValue.data(<String, Map<String, int>>{}),
          ),
        ],
      );
      addTearDown(container.dispose);

      var builds = 0;
      final sub = container.listen(
        calendarDayNotesProvider,
        (_, _) => builds++,
      );
      addTearDown(sub.close);

      controller.add([linked, unrelated]);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(calendarDayNotesProvider)['2026-11-24'],
        hasLength(1),
      );
      final before = builds;

      // İlgisiz n2 notunu güncelle (ana ekranda/editörde otomatik kayıt senaryosu).
      controller.add([linked, unrelated.copyWith(body: 'Değişen metin')]);
      await Future<void>.delayed(Duration.zero);
      expect(
        builds,
        before,
        reason: 'ilgisiz not değişince takvim bağlı notları yeniden kurulmamalı',
      );
    },
  );

  test('aynı güne birden fazla not bağlanabilir (CalendarRepository)', () async {
    final repo = CalendarRepository(db, 'u1');
    repo.linkNoteToDay('2026-11-24', 'note-1');
    repo.linkNoteToDay('2026-11-24', 'note-2');
    repo.linkNoteToDay('2026-11-24', 'note-3');
    final map = await repo.watchDayLinks().firstWhere(
      (m) => (m['2026-11-24']?.length ?? 0) == 3,
    );
    expect(map['2026-11-24'], ['note-1', 'note-2', 'note-3']);
  });
}
