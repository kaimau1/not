import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/ghost_suggestion_engine.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/ghost_suggestions_section.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GhostSuggestionEngine (Kural 1: yalnız geçici UI katmanı)', () {
    test('NoteItem kalıcı şemasında isGhost alanı yoktur; promote gerçek NoteItem üretir', () {
      const suggestion = GhostSuggestion(
        id: 'shopping:salca',
        text: 'Salça',
        reason: GhostSuggestionReason.pairing,
        category: 'dry',
      );
      final real = suggestion.toNoteItem('real-1');
      final map = real.toMap();
      expect(map.containsKey('isGhost'), isFalse);
      expect(real.text, 'Salça');
      expect(real.category, 'dry');
      expect(NoteItem.knownKeys.contains('isGhost'), isFalse);
    });

    test('alışveriş kipinde geciken ürünler + eşleşme sözlüğü önerir, mevcutları dışlar', () {
      final now = DateTime(2026, 11, 28);
      final d1 = DateTime(2026, 11, 10);
      final d2 = DateTime(
        2026,
        11,
        17,
      ); // 7 gün aralık -> 11 gündür yok (gecikmiş)
      var memory = const QuickEntryMemory();
      memory = memory.recorded('smart:market', ['Süt'], at: d1);
      memory = memory.recorded('smart:market', ['Süt'], at: d2);

      final note = Note(
        id: 'shop-1',
        type: NoteType.checklist,
        title: 'Market',
        listMode: ListMode.shopping,
        items: const [NoteItem(id: 'i1', text: 'Makarna')],
      );

      final suggestions = GhostSuggestionEngine.generate(
        note,
        memory: memory,
        now: now,
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.length, lessThanOrEqualTo(3));
      expect(suggestions.first.text, 'Süt');
      expect(suggestions.first.reason, GhostSuggestionReason.overdue);
      expect(
        suggestions.any(
          (s) => s.text == 'Salça' && s.reason == GhostSuggestionReason.pairing,
        ),
        isTrue,
      );
      expect(
        suggestions.any((s) => s.text.toLowerCase() == 'makarna'),
        isFalse,
      );
    });

    test('kilitli notlarda ASLA hayalet öneri üretmez', () {
      final locked = Note(
        id: 'locked-1',
        type: NoteType.checklist,
        title: 'Özel',
        listMode: ListMode.shopping,
        locked: true,
        items: const [NoteItem(id: 'i1', text: 'Makarna')],
      );
      expect(
        GhostSuggestionEngine.generate(
          locked,
          memory: const QuickEntryMemory(),
        ),
        isEmpty,
      );
    });

    test('24 saatlik gizleme SharedPreferences ile kalıcı olur ve süre dolunca kalkar', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final t0 = DateTime(2026, 11, 28, 10);
      await GhostSuggestionEngine.dismiss(prefs, 'shopping:salca', now: t0);

      final activeAt12h = GhostSuggestionEngine.loadDismissed(
        prefs,
        now: t0.add(const Duration(hours: 12)),
      );
      expect(activeAt12h, contains('shopping:salca'));

      final activeAt25h = GhostSuggestionEngine.loadDismissed(
        prefs,
        now: t0.add(const Duration(hours: 25)),
      );
      expect(activeAt25h, isNot(contains('shopping:salca')));
    });

    testWidgets(
      'GhostSuggestionsSection katmansız soluklukla çizilir, dokunma & gizleme çalışır',
      (tester) async {
        GhostSuggestion? accepted;
        GhostSuggestion? dismissed;
        const list = [
          GhostSuggestion(
            id: 'shopping:salca',
            text: 'Salça',
            reason: GhostSuggestionReason.pairing,
          ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GhostSuggestionsSection(
                suggestions: list,
                mode: ListMode.shopping,
                onAccept: (s) => accepted = s,
                onDismiss: (s) => dismissed = s,
              ),
            ),
          ),
        );
        expect(find.byType(Opacity), findsNothing);
        expect(find.text('Salça'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('ghost-accept-shopping:salca')),
        );
        expect(accepted?.text, 'Salça');

        await tester.tap(
          find.byKey(const ValueKey('ghost-dismiss-shopping:salca')),
        );
        expect(dismissed?.id, 'shopping:salca');
      },
    );
  });
}
