import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_cache.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/presentation/ai_chat_screen.dart';
import 'package:notlar/features/ai/presentation/ai_sheet.dart';
import 'package:notlar/features/ai/presentation/quiet_organize_sheet.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGemini implements GeminiService {
  final calls = <String>[];
  int outlineCalls = 0;
  int batchCalls = 0;
  List<QuietOrganizeSuggestion> batchResult = const [];

  @override
  Future<String> chatAboutNote({
    required Note note,
    required List<({Uint8List bytes, String mimeType, String fileName})>
    attachments,
    required List<ChatTurn> history,
  }) async {
    calls.add('qa:${history.last.text}');
    return 'qa yanıtı';
  }

  @override
  Future<String> brainstormAboutNote({
    required Note note,
    required List<ChatTurn> history,
    String? focusHeading,
  }) async {
    calls.add('bs:${history.last.text}');
    return 'yeni fikir önerisi';
  }

  @override
  Future<List<String>> outlineNote(Note note) async {
    outlineCalls++;
    return const ['Eski başlık'];
  }

  @override
  Future<String> summarizeNote(Note note, {bool detailed = false}) async {
    calls.add(detailed ? 'summary:detailed' : 'summary:short');
    return detailed ? 'Ayrıntılı not özeti metni' : 'Kısa not özeti metni';
  }

  @override
  Future<List<QuietOrganizeSuggestion>> batchQuietOrganize(
    List<Note> notes, {
    bool suggestTitles = true,
    bool suggestTags = true,
    int maxNotes = 15,
  }) async {
    batchCalls++;
    return batchResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepo implements NotesRepository {
  final updated = <Note>[];

  @override
  Future<void> updateNote(Note note, {bool clientTime = false}) async {
    updated.add(note);
  }

  @override
  Future<void> setAiSummary(String noteId, AiSummary summary) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('ai_p89_test_');
    AiCache.overrideDir = tempDir;
  });

  tearDown(() async {
    AiCache.overrideDir = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AI-S3: eski kip çipleri ve _OutlineBar kalktı', () {
    testWidgets('notla sohbette kip çipleri yok ve outlineNote çağrılmaz', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeGemini();
      String? added;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(fake),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AiChatScreen(
              note: const Note(
                id: 'n1',
                type: NoteType.text,
                title: 'Proje notu',
                body: 'Toplantı hedefleri',
              ),
              onAddToNote: (text) => added = text,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Eski kip çipleri kaldırıldı.
      expect(find.byKey(const ValueKey('chat-mode-qa')), findsNothing);
      expect(find.byKey(const ValueKey('chat-mode-brainstorm')), findsNothing);
      // Kapsam çipleri (Tüm notlar / Bu not) durur.
      expect(find.byKey(const ValueKey('chat-scope-note')), findsOneWidget);
      expect(fake.outlineCalls, 0);

      // "Fikir ver" beyin fırtınasında sorar, outlineNote çağırmaz ve Nota ekle çalışır.
      await tester.tap(find.byKey(const ValueKey('chat-suggest-ideas')));
      await tester.pumpAndSettle();
      expect(fake.outlineCalls, 0);
      expect(fake.calls.single, startsWith('bs:'));
      expect(find.text('yeni fikir önerisi'), findsOneWidget);

      await tester.tap(find.text('Nota ekle'));
      await tester.pumpAndSettle();
      expect(added, 'yeni fikir önerisi');
    });

    testWidgets('tek kapsamlı (not yok) sohbette kapsam çubuğu gizlenir', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeGemini();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AiChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-scope-all')), findsNothing);
    });
  });

  group('A7: not özeti kısa/ayrıntılı anahtarı ve içerik özeti önbelleği', () {
    testWidgets('kısa → ayrıntılı → kısa dönüşünde ikinci kısa önbellekten gelir', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeGemini();
      final repo = _FakeRepo();
      const note = Note(
        id: 'n-sum',
        type: NoteType.text,
        title: 'Yıllık plan',
        body: 'İlk çeyrekte hedef büyüme, ikinci çeyrekte yeni ürünler.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(fake),
            notesRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AiSheet(note: note)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Özetle karosunu bulup dokun (kısa özet başlar).
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.scrollUntilVisible(
        find.text(l10n.aiSummarize),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      Future<void> flushIo() async {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 20));
          if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
        }
      }

      await tester.tap(find.text(l10n.aiSummarize));
      await flushIo();

      expect(fake.calls, ['summary:short']);
      expect(
        find.text('Kısa not özeti metni', findRichText: true),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ai-summary-short')), findsOneWidget);
      expect(find.byKey(const ValueKey('ai-summary-detailed')), findsOneWidget);

      // Ayrıntılıya geç → 2. çağrı.
      await tester.tap(find.byKey(const ValueKey('ai-summary-detailed')));
      await flushIo();
      expect(fake.calls, ['summary:short', 'summary:detailed']);
      expect(
        find.text('Ayrıntılı not özeti metni', findRichText: true),
        findsOneWidget,
      );

      // Kısaya geri dön → önbellekten, YENİ API çağrısı 0!
      await tester.tap(find.byKey(const ValueKey('ai-summary-short')));
      await flushIo();
      expect(fake.calls, ['summary:short', 'summary:detailed']);
      expect(
        find.text('Kısa not özeti metni', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('A8: Sessiz düzen — toplu tek istek, ayrıştırıcı ve geri al', () {
    test('parseBatchOrganize kod çiti, sarmalayıcı ve geçersiz kimlikleri temizler', () {
      const raw = '''
```json
[
  {"id": "n1", "title": "\\"Haftalık market alışverişi\\".", "tags": ["Alisveris", "#ev", "ev"]},
  {"id": "n2", "title": null, "tags": "is, finans"},
  {"id": "unknown", "title": "Atlanmalı", "tags": ["x"]},
  {"id": "n1", "title": "Tekrar", "tags": ["dup"]}
]
```''';
      final parsed = GeminiService.parseBatchOrganize(
        raw,
        validIds: {'n1', 'n2'},
      );
      expect(parsed, hasLength(2));
      expect(parsed[0].noteId, 'n1');
      expect(parsed[0].title, 'Haftalık market alışverişi');
      expect(parsed[0].tags, ['alisveris', 'ev']);
      expect(parsed[1].noteId, 'n2');
      expect(parsed[1].title, isNull);
      expect(parsed[1].tags, ['is', 'finans']);
    });

    testWidgets('tek istekte toplu uygular ve tek Geri Al ile hepsini döndürür', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeGemini()
        ..batchResult = const [
          QuietOrganizeSuggestion(
            noteId: 'n1',
            title: 'Elektrik faturası',
            tags: ['finans', 'ev'],
          ),
          QuietOrganizeSuggestion(
            noteId: 'n2',
            title: 'Koşu programı',
            tags: ['spor'],
          ),
        ];
      final repo = _FakeRepo();
      const notes = [
        Note(id: 'n1', type: NoteType.text, body: 'Elektrik faturasını öde'),
        Note(id: 'n2', type: NoteType.text, body: 'Haftada 3 gün 5 km koşu'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(fake),
            notesRepositoryProvider.overrideWithValue(repo),
            notesStreamProvider.overrideWith((_) => Stream.value(notes)),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showQuietOrganizeSheet(ctx),
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

      // Tek toplu istek.
      expect(fake.batchCalls, 1);
      expect(find.text('Elektrik faturası'), findsOneWidget);
      expect(find.text('Koşu programı'), findsOneWidget);

      // İkinci notun işaretini kaldır.
      await tester.ensureVisible(
        find.byKey(const ValueKey('quiet-org-check-n2')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quiet-org-check-n2')));
      await tester.pumpAndSettle();

      // Uygula → yalnız n1 güncellenir; 4 sn'lik geri sayım bitmeden Geri al görünür.
      await tester.tap(find.byKey(const ValueKey('quiet-org-apply')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.id, 'n1');
      expect(repo.updated.single.title, 'Elektrik faturası');
      expect(repo.updated.single.tags, ['finans', 'ev']);

      // Tek Geri Al → önceki boş başlık ve etiketlere döner.
      await tester.tap(find.text('Geri al'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.updated, hasLength(2));
      expect(repo.updated.last.id, 'n1');
      expect(repo.updated.last.title, '');
      expect(repo.updated.last.tags, isEmpty);
    });
  });
}
