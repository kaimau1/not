import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/domain/smart_categorize.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
}
