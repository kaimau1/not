import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:notlar/features/ai/data/ai_policy.dart';
import 'package:notlar/features/ai/data/decisions/decision_flag.dart';
import 'package:notlar/features/ai/data/decisions/decision_service.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/day_key.dart';
import 'package:notlar/features/notes/data/device_speech.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_entry_bar.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements NotesRepository {
  final List<({String id, Map<String, dynamic> fields})> updates = [];
  final List<({NoteType type, String body, DateTime? reminderAt})> created = [];

  @override
  Future<void> updateFields(String noteId, Map<String, dynamic> fields) async {
    updates.add((id: noteId, fields: fields));
  }

  @override
  Future<String> createNote(
    NoteType type, {
    double? orderIndex,
    String title = '',
    String body = '',
    List<String>? items,
    String? folderId,
    DateTime? reminderAt,
    int listColumns = 1,
    String? listKind,
  }) async {
    created.add((type: type, body: body, reminderAt: reminderAt));
    return 'new-${created.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCalendar extends CalendarRepository {
  _FakeCalendar() : super(FakeFirebaseFirestore(), 'u');
  final links = <(String, String)>[];

  @override
  void linkNoteToDay(String day, String noteId) => links.add((day, noteId));
}

void main() {
  const speechEvents = EventChannel('dev.kaimau.notlar/speech');

  tearDown(() {
    QuickEntryBarState.debugClock = DateTime.now;
    DeviceSpeech.debugAvailable = null;
    DeviceSpeech.debugMicGranted = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(speechEvents, null);
  });

  group('T4 H1 sessizlik tabanlı "bitti" algısı', () {
    testWidgets(
      '"süt bitti" akıcı konuşmada kapatmaz; 0,8 sn durup "bitti" kapatır',
      (tester) async {
        MockStreamHandlerEventSink? sink;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              speechEvents,
              MockStreamHandler.inline(
                onListen: (_, s) {
                  sink = s;
                },
                onCancel: (_) {
                  sink = null;
                },
              ),
            );
        DeviceSpeech.debugAvailable = true;
        DeviceSpeech.debugMicGranted = true;

        var now = DateTime(2026, 11, 21, 10);
        QuickEntryBarState.debugClock = () => now;
        var doneCalls = 0;
        var rawText = '';

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              locale: const Locale('tr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: QuickEntryBar(
                  parser: QuickParser(QuickLexicon()),
                  raw: true,
                  autoListen: true,
                  onRawChanged: (t) => rawText = t,
                  onDoneWord: () => doneCalls++,
                  onItems: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(sink, isNotNull);

        // Akıcı konuşma (250 ms arayla): "süt" → "süt bitti" bitiş SAYILMAZ.
        sink!.success({'text': 'süt'});
        await tester.pump();
        now = now.add(const Duration(milliseconds: 250));
        sink!.success({'text': 'süt bitti'});
        await tester.pump();
        expect(doneCalls, 0);
        expect(rawText, 'süt bitti');

        // 800 ms sessizlik sonrası "bitti": bitiş sayılır.
        now = now.add(const Duration(milliseconds: 800));
        sink!.success({'text': 'süt ekmek bitti'});
        await tester.pump();
        expect(doneCalls, 1);
        expect(rawText, 'süt ekmek');

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('"bu kadar" sessizlik olmadan hemen bitirir', (tester) async {
      MockStreamHandlerEventSink? sink;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            speechEvents,
            MockStreamHandler.inline(
              onListen: (_, s) {
                sink = s;
              },
              onCancel: (_) {
                sink = null;
              },
            ),
          );
      DeviceSpeech.debugAvailable = true;
      DeviceSpeech.debugMicGranted = true;
      var now = DateTime(2026, 11, 21, 10);
      QuickEntryBarState.debugClock = () => now;
      var doneCalls = 0;

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: QuickEntryBar(
                parser: QuickParser(QuickLexicon()),
                raw: true,
                autoListen: true,
                onDoneWord: () => doneCalls++,
                onItems: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      sink!.success({'text': 'süt'});
      now = now.add(const Duration(milliseconds: 100));
      sink!.success({'text': 'süt bu kadar'});
      await tester.pump();
      expect(doneCalls, 1);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('HE-4 tek giriş + HE-5 çoklu hedef ve bağlam sıralaması', () {
    Future<MockStreamHandlerEventSink?> pumpSheet(
      WidgetTester tester, {
      required List<Note> notes,
      required _FakeRepo repo,
      CalendarRepository? calendar,
      DecisionService? decisions,
      bool autoMic = false,
      bool consentGiven = false,
    }) async {
      MockStreamHandlerEventSink? sink;
      if (autoMic) {
        DeviceSpeech.debugAvailable = true;
        DeviceSpeech.debugMicGranted = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              speechEvents,
              MockStreamHandler.inline(
                onListen: (_, s) {
                  sink = s;
                },
                onCancel: (_) {
                  sink = null;
                },
              ),
            );
      } else {
        DeviceSpeech.debugAvailable = false;
      }
      SharedPreferences.setMockInitialValues({
        'quick_drop_keyboard': false,
        'quick_drop_mic_auto': autoMic,
        if (consentGiven) AiConsentNotifier.key: true,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notesStreamProvider.overrideWith((_) => Stream.value(notes)),
            notesRepositoryProvider.overrideWithValue(repo),
            if (calendar != null)
              calendarRepositoryProvider.overrideWithValue(calendar),
            if (decisions != null)
              decisionServiceProvider.overrideWithValue(decisions),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showQuickDropSheet(context),
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aç'));
      if (autoMic) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 600));
      } else {
        await tester.pumpAndSettle();
      }
      return sink;
    }

    testWidgets(
      'HE-4: tarih/saat hatırlatıcılı yeni not oluşturur; çip dokunuşu ezer',
      (tester) async {
        final repo = _FakeRepo();
        final notes = [Note(id: 'n1', type: NoteType.text, title: 'Fikirler')];
        await pumpSheet(tester, notes: notes, repo: repo);

        await tester.enterText(find.byType(TextField), "yarın 9'da dişçi");
        await tester.pump();
        final preview = tester.widget<Text>(
          find.byKey(const ValueKey('quick-drop-preview')),
        );
        expect(preview.data, startsWith('⏰ '));

        await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
        await tester.pumpAndSettle();
        expect(repo.created, hasLength(1));
        expect(repo.created.single.reminderAt, isNotNull);
        expect(repo.created.single.reminderAt!.hour, 9);
        expect(repo.created.single.body, "yarın 9'da dişçi");
      },
    );

    testWidgets('"… yarına ekle": yeni not yarına (takvime) bağlanır', (
      tester,
    ) async {
      final repo = _FakeRepo();
      final calendar = _FakeCalendar();
      await pumpSheet(
        tester,
        notes: [Note(id: 'n1', type: NoteType.text, title: 'Fikirler')],
        repo: repo,
        calendar: calendar,
      );
      await tester.enterText(find.byType(TextField), 'dişçiyi ara yarına ekle');
      await tester.pump();
      final preview = tester.widget<Text>(
        find.byKey(const ValueKey('quick-drop-preview')),
      );
      expect(preview.data, startsWith('📅 '));
      await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
      await tester.pumpAndSettle();
      expect(repo.created.single.body, 'dişçiyi ara');
      expect(repo.created.single.reminderAt, isNull);
      final now = DateTime.now();
      expect(calendar.links, [
        (dayKey(DateTime(now.year, now.month, now.day + 1)), 'new-1'),
      ]);
      expect(repo.updates, isEmpty);
    });

    testWidgets(
      'HE-4: birkaç market ürünü otomatik market listesine yönlenir',
      (tester) async {
        final repo = _FakeRepo();
        final notes = [
          Note(
            id: 'n1',
            type: NoteType.text,
            title: 'Fikirler',
            updatedAt: DateTime(2026, 11, 21, 12),
          ),
          Note(
            id: 'm1',
            type: NoteType.checklist,
            title: 'Market listesi',
            items: const [NoteItem(id: 'i1', text: 'Elma')],
            updatedAt: DateTime(2026, 11, 20, 12),
          ),
        ];
        await pumpSheet(tester, notes: notes, repo: repo);

        await tester.enterText(find.byType(TextField), 'süt yumurta');
        await tester.pump();
        final preview = tester.widget<Text>(
          find.byKey(const ValueKey('quick-drop-preview')),
        );
        expect(preview.data, contains('Market listesi'));
        await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
        await tester.pumpAndSettle();
        expect(repo.updates, hasLength(1));
        expect(repo.updates.single.id, 'm1');
      },
    );

    testWidgets(
      'HE-5: çoklu hedef iki nota birden ekler ve tek Geri Al ikisini geri alır',
      (tester) async {
        final repo = _FakeRepo();
        final notes = [
          Note(
            id: 'm1',
            type: NoteType.checklist,
            title: 'Market',
            items: const [NoteItem(id: 'i1', text: 'Elma')],
          ),
          Note(
            id: 't1',
            type: NoteType.text,
            title: 'Yapılacaklar',
            body: 'Eski satır',
          ),
        ];
        await pumpSheet(tester, notes: notes, repo: repo);

        await tester.enterText(
          find.byType(TextField),
          'süt markete, fatura yapılacaklara',
        );
        await tester.pump();
        final preview = tester.widget<Text>(
          find.byKey(const ValueKey('quick-drop-preview')),
        );
        expect(preview.data, contains('2 not'));

        await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
        await tester.pumpAndSettle();
        expect(repo.updates.map((u) => u.id).toList(), ['m1', 't1']);
      },
    );

    test('HE-5: saat dilimi ve gün bağlamı aynı katmandaki adayı öne alır', () {
      final now = DateTime(2026, 11, 21, 9); // Cumartesi sabah (bucket 0)
      final scores = quickDropContextScores({
        'morning-note|${now.weekday}|0': 3,
        'evening-note|${now.weekday}|2': 5,
      }, now);
      expect(scores['morning-note'], 6);
      expect(scores['evening-note'], isNull);

      final ranked = quickDropCandidates(
        [
          Note(
            id: 'evening-note',
            type: NoteType.text,
            title: 'Akşam',
            updatedAt: DateTime(2026, 11, 21, 8),
          ),
          Note(
            id: 'morning-note',
            type: NoteType.text,
            title: 'Sabah',
            updatedAt: DateTime(2026, 11, 20, 8),
          ),
        ],
        const [],
        contextBoost: scores,
      );
      expect(ranked.first.id, 'morning-note');
    });

    testWidgets(
      'D3 captureRoute: shopping market notunu seçer, event/note yeni nota gider',
      (tester) async {
        final calls = <String>[];
        var intentChoice = 'b_alisveris';
        final decisions = DecisionService(
          key: () async => null,
          proxy: (body) async {
            final qs = body['questions'] as Map;
            if (qs.containsKey('hedef')) {
              calls.add('dropTarget');
              return {
                'answers': {
                  'hedef': {
                    'type': 'choice',
                    'choice': 'a_yok',
                    'confidence': 0.99,
                  },
                },
              };
            }
            calls.add('captureRoute');
            return {
              'answers': {
                'niyet': {
                  'type': 'choice',
                  'choice': intentChoice,
                  'confidence': 0.92,
                },
              },
            };
          },
        );
        AiDecisionsFlag.debugReset();
        addTearDown(AiDecisionsFlag.debugReset);

        final repo1 = _FakeRepo();
        final notes = [
          Note(
            id: 't1',
            type: NoteType.text,
            title: 'Notlarım',
            updatedAt: DateTime(2026, 11, 21, 12),
          ),
          Note(
            id: 'm1',
            type: NoteType.checklist,
            title: 'Market listesi',
            items: const [NoteItem(id: 'i1', text: 'Elma')],
            updatedAt: DateTime(2026, 11, 20, 12),
          ),
        ];
        final sink1 = await pumpSheet(
          tester,
          notes: notes,
          repo: repo1,
          decisions: decisions,
          autoMic: true,
          consentGiven: true,
        );
        expect(sink1, isNotNull);
        sink1!.success({'text': 'peynir xyznotuna ekle bu kadar'});
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(calls, containsAllInOrder(['dropTarget', 'captureRoute']));
        expect(find.byKey(const ValueKey('quick-drop-ask')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
        await tester.pumpAndSettle();
        expect(repo1.updates, hasLength(1));
        expect(repo1.updates.single.id, 'm1');
        await tester.pumpWidget(const SizedBox());

        // D2 kapalıyken doğrudan D3 event/note yönlendirmesi çalışır.
        calls.clear();
        intentChoice = 'd_etkinlik';
        AiDecisionsFlag.apply({
          AiDecisionsFlag.featuresField: [DecisionFeature.captureRoute],
        });
        final repo2 = _FakeRepo();
        final sink2 = await pumpSheet(
          tester,
          notes: notes,
          repo: repo2,
          decisions: decisions,
          autoMic: true,
          consentGiven: true,
        );
        sink2!.success({
          'text': 'yarın saat 15 randevu xyznotuna ekle bu kadar',
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(calls, ['captureRoute']);
        await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
        await tester.pumpAndSettle();
        expect(repo2.created, hasLength(1));
        expect(repo2.created.single.reminderAt, isNotNull);
        expect(repo2.created.single.reminderAt!.hour, 15);
        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
