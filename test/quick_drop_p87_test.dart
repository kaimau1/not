import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  }) async {
    created.add((type: type, body: body, reminderAt: reminderAt));
    return 'new-${created.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
    testWidgets('"süt bitti" akıcı konuşmada kapatmaz; 0,8 sn durup "bitti" kapatır', (
      tester,
    ) async {
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
    });

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
    Future<void> pumpSheet(
      WidgetTester tester, {
      required List<Note> notes,
      required _FakeRepo repo,
    }) async {
      DeviceSpeech.debugAvailable = false;
      SharedPreferences.setMockInitialValues({
        'quick_drop_keyboard': false,
        'quick_drop_mic_auto': false,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notesStreamProvider.overrideWith((_) => Stream.value(notes)),
            notesRepositoryProvider.overrideWithValue(repo),
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
      await tester.pumpAndSettle();
    }

    testWidgets('HE-4: tarih/saat hatırlatıcılı yeni not oluşturur; çip dokunuşu ezer', (
      tester,
    ) async {
      final repo = _FakeRepo();
      final notes = [
        Note(id: 'n1', type: NoteType.text, title: 'Fikirler'),
      ];
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
    });

    testWidgets('HE-4: birkaç market ürünü otomatik market listesine yönlenir', (
      tester,
    ) async {
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
    });

    testWidgets('HE-5: çoklu hedef iki nota birden ekler ve tek Geri Al ikisini geri alır', (
      tester,
    ) async {
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
    });

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
  });
}
