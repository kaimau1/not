import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/attachment_tag.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/spell_review.dart';
import 'package:notlar/features/notes/presentation/editor/spell_review_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  group('Y-5 scanNoteSpellFindings & applySpellReview', () {
    test('başlık, gövde ve maddeleri tarar; ek etiketi ve noteKeep atlanır', () {
      final m = SpellMemory();
      final findings = scanNoteSpellFindings(
        title: 'Herşey hazır',
        body: 'Bugun ${attachmentTagFor('hersey.pdf')} ile gorusuruz bende',
        items: const [
          NoteItem(id: '1', text: 'Alışveriş calisma'),
          NoteItem(id: '2', text: 'süt ve ekmek'),
        ],
        memory: m,
        noteKeep: {'gorusuruz'},
        attachmentNames: ['hersey.pdf'],
      );
      expect(findings.map((f) => (f.target, f.word)).toList(), [
        (SpellReviewTarget.title, 'Herşey'),
        (SpellReviewTarget.body, 'Bugun'),
        (SpellReviewTarget.body, 'bende'),
        (SpellReviewTarget.item, 'calisma'),
      ]);
      expect(findings[0].suggestions.first, 'Her şey');
      expect(findings[0].autoFixable, isTrue);
      expect(findings[1].suggestions.first, 'Bugün');
      expect(findings[2].hint, isTrue);
      expect(findings[2].autoFixable, isFalse);
      expect(findings[3].suggestions.first, 'çalışma');
    });

    test('birden çok düzeltme sağdan sola kaymadan uygulanır', () {
      final m = SpellMemory();
      const title = 'Herşey tamam';
      const body = 'Bugun calisma var ve yarin da hersey iyi';
      const items = [NoteItem(id: 'a', text: 'Heryerde calisma')];
      final findings = scanNoteSpellFindings(
        title: title,
        body: body,
        items: items,
        memory: m,
      );
      final replacements = {
        for (final f in findings)
          if (f.autoFixable) f.id: f.suggestions.first,
      };
      final applied = applySpellReview(
        title: title,
        body: body,
        items: items,
        findings: findings,
        replacements: replacements,
      );
      expect(applied.title, 'Her şey tamam');
      expect(applied.body, 'Bugün çalışma var ve yarın da her şey iyi');
      expect(applied.items.first.text, 'Her yerde çalışma');
      expect(applied.count, replacements.length);
    });
  });

  group('Y-5 showSpellReviewSheet widget', () {
    Widget host(
      List<SpellFinding> findings,
      void Function(Map<int, String>) onResult, {
      void Function(String)? onDict,
    }) => MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final r = await showSpellReviewSheet(
                context,
                findings: findings,
                onAddToDictionary: onDict ?? (_) {},
              );
              onResult(r);
            },
            child: const Text('Aç'),
          ),
        ),
      ),
    );

    testWidgets('hata yoksa temiz durum görünür', (tester) async {
      Map<int, String>? result;
      await tester.pumpWidget(host(const [], (r) => result = r));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(find.text('Yazım hatası bulunamadı'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sheet-close')));
      await tester.pumpAndSettle();
      expect(result, isEmpty);
    });

    testWidgets('Tümünü düzelt yalnız kesin hataları seçer, ipucuna dokunmaz', (
      tester,
    ) async {
      final findings = scanNoteSpellFindings(
        title: '',
        body: 'Bugun bende hersey tamam',
        items: const [],
        memory: SpellMemory(),
      );
      Map<int, String>? result;
      await tester.pumpWidget(host(findings, (r) => result = r));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('spell-review-fix-all')), findsOneWidget);
      expect(find.text('Tümünü düzelt (2)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('spell-review-fix-all')));
      await tester.pumpAndSettle();
      expect(result?.length, 2);
      expect(result?.values, containsAll(['Bugün', 'her şey']));
    });

    testWidgets('Sözlüğe ekle aynı kelimenin tüm tekrarlarını kaldırır', (
      tester,
    ) async {
      final findings = scanNoteSpellFindings(
        title: '',
        body: 'hersey ve yine hersey',
        items: const [],
        memory: SpellMemory(),
      );
      final added = <String>[];
      Map<int, String>? result;
      await tester.pumpWidget(
        host(findings, (r) => result = r, onDict: added.add),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(findings.length, 2);
      await tester.tap(find.byKey(ValueKey('spell-dict-${findings.first.id}')));
      await tester.pumpAndSettle();
      expect(added, ['hersey']);
      expect(find.text('Yazım hatası bulunamadı'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sheet-close')));
      await tester.pumpAndSettle();
      expect(result, isEmpty);
    });
  });
}
