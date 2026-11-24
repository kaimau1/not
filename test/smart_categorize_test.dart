import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_cache.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/domain/smart_categorize.dart';
import 'package:notlar/features/ai/presentation/quiet_organize_sheet.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingGemini implements GeminiService {
  int batchCalls = 0;
  List<QuietOrganizeSuggestion> batchResult = const [];

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

class _FakeNotesRepo implements NotesRepository {
  final updated = <Note>[];

  @override
  Future<void> updateNote(Note note, {bool clientTime = false}) async {
    updated.add(note);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('smart_cat_test_');
    AiCache.overrideDir = tempDir;
  });

  tearDown(() async {
    AiCache.overrideDir = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SmartNoteCategorizer (0 kredi yerel akıllı kategorizasyon)', () {
    test('foldTurkish Türkçe karakterleri doğru katlar', () {
      expect(
        foldTurkish('İstanbul ŞİŞLİ Ğüzel Örnek Çiçek'),
        'istanbul sisli guzel ornek cicek',
      );
    });

    test('alan anahtar kelimelerini ve mevcut klasörü tanır', () {
      const note = Note(
        id: 'n-fin',
        type: NoteType.text,
        body: 'Şubat ayı elektrik fatura ödemesi ve IBAN dekontu',
      );
      final res = SmartNoteCategorizer.classify(
        note,
        existingFolders: const ['Kişisel', 'Finans Evrakları'],
      );
      expect(res.category, SmartNoteCategory.finance);
      expect(res.folderSuggestion, 'Finans Evrakları');
      expect(res.confidence, greaterThanOrEqualTo(0.86));
      expect(needsAiRefinement(res), isFalse);
      expect(res.localOnly, isTrue);
      expect(res.tags, contains('finans'));
      expect(res.suggestedTitle, isNotEmpty);

      const healthNote = Note(
        id: 'n-hlt',
        type: NoteType.text,
        body: 'Hastane randevu doktor tahlil sonuçları ve eczane reçete',
      );
      final h = SmartNoteCategorizer.classify(healthNote);
      expect(h.category, SmartNoteCategory.health);
      expect(h.confidence, greaterThanOrEqualTo(0.86));

      const obscureNote = Note(
        id: 'n-low',
        type: NoteType.text,
        body: 'Yarın akşam için kısa hatırlatma metni',
      );
      final low = SmartNoteCategorizer.classify(obscureNote);
      expect(low.category, SmartNoteCategory.personal);
      expect(needsAiRefinement(low), isTrue);
    });

    test('classifyAll arşiv/çöp/kilitli/dolu notları atlar', () {
      final results = SmartNoteCategorizer.classifyAll([
        const Note(
          id: 'n1',
          type: NoteType.text,
          body: 'Uçuş bilet ve otel rezervasyonu',
        ),
        Note(
          id: 'n-arch',
          type: NoteType.text,
          body: 'Arşivlenmiş market alışveriş listesi',
          archivedAt: DateTime(2026),
        ),
        const Note(
          id: 'n-lock',
          type: NoteType.text,
          body: 'Kilitli şifre parola',
          locked: true,
        ),
        const Note(
          id: 'n-full',
          type: NoteType.text,
          title: 'Zaten düzenli',
          body: 'İçerik',
          tags: ['hazir'],
        ),
      ]);
      expect(results.map((r) => r.noteId), ['n1']);
      expect(results.single.category, SmartNoteCategory.travel);
    });

    test('SmartNoteLearn düzeltmeyi hatırlar ve benzerlerini bulur', () async {
      final prefs = await SharedPreferences.getInstance();
      final learn = SmartNoteLearn(prefs);
      const anchor = Note(
        id: 'a1',
        type: NoteType.text,
        body: 'Kulüp aidat çizelge makbuzu',
      );
      const twin = Note(
        id: 'a2',
        type: NoteType.text,
        body: 'Kulüp aidat çizelge kontrolü',
      );
      await learn.recordCorrection(
        anchor,
        SmartNoteCategory.personal,
        SmartNoteCategory.official,
      );

      final adjusted = SmartNoteCategorizer.classify(
        twin,
        learn: SmartNoteLearn(prefs),
      );
      expect(adjusted.category, SmartNoteCategory.official);
      expect(adjusted.matchedRule, 'learned_official');

      final sims = learn.findSimilar(anchor, SmartNoteCategory.personal, [
        anchor,
        twin,
      ], currentCategoryOf: (_) => SmartNoteCategory.personal);
      expect(sims.map((n) => n.id), ['a2']);
    });
  });

  testWidgets('preferLocalFirst: 0 AI çağrısı ile çalışır ve Düzelt öğrenir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final prefs = await SharedPreferences.getInstance();
    final fakeGemini = _RecordingGemini();
    final repo = _FakeNotesRepo();
    const notes = [
      Note(
        id: 'n-fin',
        type: NoteType.text,
        body: 'Elektrik fatura ve IBAN dekontu',
      ),
      Note(
        id: 'n-amb',
        type: NoteType.text,
        body: 'Özel kulüp aidat çizelgesi',
      ),
    ];
    const folders = [NoteFolder(id: 'f-fin', name: 'Finans', ownerId: 'u1')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
          geminiServiceProvider.overrideWithValue(fakeGemini),
          notesRepositoryProvider.overrideWithValue(repo),
          notesStreamProvider.overrideWith((_) => Stream.value(notes)),
          foldersStreamProvider.overrideWith((_) => Stream.value(folders)),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () =>
                    showQuietOrganizeSheet(ctx, preferLocalFirst: true),
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

    // İlk açılışta 0 AI çağrısı; yerel eşleştirme ve klasör önerisi görünür.
    expect(fakeGemini.batchCalls, 0);
    expect(find.byKey(const ValueKey('quiet-org-refine-ai')), findsOneWidget);
    expect(find.text('Klasör: Finans'), findsOneWidget);

    // Düşük güvenli n-amb için Düzelt -> Resmî seç.
    await tester.ensureVisible(
      find.byKey(const ValueKey('quiet-org-fix-n-amb')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quiet-org-fix-n-amb')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('smart-fix-cat-official')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('smart-fix-cat-official')));
    await tester.pumpAndSettle();

    // Öğrenme diske yazıldı; artık #resmi etiketi önerilir ve Uygula klasörü de yazar.
    expect(find.text('#resmi'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quiet-org-apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final finSaved = repo.updated.firstWhere((n) => n.id == 'n-fin');
    expect(finSaved.folderId, 'f-fin');
    expect(finSaved.tags, contains('finans'));
    expect(fakeGemini.batchCalls, 0);
  });
}
