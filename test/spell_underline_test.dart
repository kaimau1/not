import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/spell_underline.dart';
import 'package:notlar/features/notes/presentation/editor/tag_chips.dart';
import 'package:notlar/features/notes/presentation/editor/tag_tap.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yazım v3 Y-4: altı çizili denetim (işaretler, menü, kip).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AutoSpell.memory = SpellMemory();
    AutoSpell.mode.value = SpellMode.show;
    AutoSpell.beginNote();
  });
  tearDown(() => AutoSpell.mode.value = SpellMode.off);

  /// Tarama 4 ms'lik dilimlere bölünür (soğuk başlangıçta birkaç dilim).
  Future<void> scan(
    WidgetTester tester, [
    Duration first = Duration.zero,
  ]) async {
    await tester.pump(first);
    for (var i = 0; i < 20; i++) {
      await tester.pump(Duration.zero);
    }
  }

  List<(int, int, String)> marksOf(SpellMarks m) => [
    for (final k in m.marks) (k.start, k.end, k.word),
  ];

  test('kayıtlı kip: yoksa eski anahtar açıksa otomatik, değilse göster', () {
    expect(AutoSpell.savedMode(null, null), SpellMode.show);
    expect(AutoSpell.savedMode(null, false), SpellMode.show);
    expect(AutoSpell.savedMode(null, true), SpellMode.auto);
    expect(AutoSpell.savedMode(0, true), SpellMode.off);
    expect(AutoSpell.savedMode(1, true), SpellMode.show);
    expect(AutoSpell.savedMode(9, false), SpellMode.show);
  });

  testWidgets('duraklamada denetlenir; yazımda işaret kayar, değen düşer', (
    tester,
  ) async {
    final c = TextEditingController(text: 'kalwm geldi');
    final m = SpellMarks.acquire(c);
    addTearDown(m.release);
    await scan(tester);
    expect(marksOf(m), [(0, 5, 'kalwm')]);

    // Önüne yazı: hemen kayar (çizgi kelimenin altında kalır).
    c.value = const TextEditingValue(
      text: 've kalwm geldi',
      selection: TextSelection.collapsed(offset: 3),
    );
    expect(marksOf(m), [(3, 8, 'kalwm')]);
    expect(m.editAt, 3);

    // Kelimeye değen yazım: işaret düşer, duraklamada yeniden denetlenir.
    c.value = const TextEditingValue(
      text: 've kalwmm geldi',
      selection: TextSelection.collapsed(offset: 9),
    );
    expect(m.marks, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(m.marks, isEmpty, reason: 'her tuşta değil');
    await scan(tester, SpellMarks.pause);
    expect(marksOf(m), [(3, 9, 'kalwmm')]);

    AutoSpell.mode.value = SpellMode.off;
    await tester.pump(Duration.zero);
    expect(m.marks, isEmpty);
  });

  testWidgets(
    'bağlama bağlı ipucu; "bu notta dokunma" ve sözlük çizgiyi kaldırır',
    (tester) async {
      final c = TextEditingController(text: 'bende kalwm\nhersey');
      final m = SpellMarks.acquire(c);
      addTearDown(m.release);
      await scan(tester);
      expect(marksOf(m), [
        (0, 5, 'bende'),
        (6, 11, 'kalwm'),
        (12, 18, 'hersey'),
      ]);
      expect(m.marks.first.hint, isTrue);
      expect(m.marks[1].hint, isFalse);

      AutoSpell.keepInNote('bende', null);
      AutoSpell.addToDictionary('kalwm');
      await scan(tester);
      expect(marksOf(m), [(12, 18, 'hersey')]);
      expect(AutoSpell.memory.keep, contains('kalwm'));
      await tester.pump(const Duration(seconds: 5)); // Erteli kayıt.
    },
  );

  testWidgets('altı çizili kelimeye dokununca menü; öneri ve "hep böyle"', (
    tester,
  ) async {
    final c = WrapTextController(text: 'bir kalwm aldım');
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => AttachmentTagChips(
              controller: c,
              looks: const {},
              child: TextField(
                controller: c,
                contextMenuBuilder: (menuContext, state) =>
                    spellContextMenu(menuContext, state) ??
                    AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: state,
                    ),
                onTap: () => showSpellMenuAfterTap(editableTextBelow(context)),
              ),
            ),
          ),
        ),
      ),
    );
    await scan(tester);
    expect(SpellMarks.of(c)!.marks.single.word, 'kalwm');
    final chips = tester.renderObject(
      find
          .descendant(
            of: find.byType(AttachmentTagChips),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(chips, paints..path(), reason: 'dalgalı çizgi çizilir');

    Offset inWord() {
      final render = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final r = render.getLocalRectForCaret(const TextPosition(offset: 6));
      return render.localToGlobal(r.center);
    }

    await tester.tapAt(inWord());
    await tester.pump();
    await tester.pump();
    expect(find.text('kalem'), findsOneWidget);
    expect(find.text('Sözlüğe ekle'), findsOneWidget);
    // Eylemler önerilerden sonra; dar araç çubuğunda "⋮" altında.
    Future<void> tapItem(String label) async {
      if (find.text(label).evaluate().isEmpty) {
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(label));
      await tester.pump();
    }

    await tapItem('kalem');
    expect(c.text, 'bir kalem aldım');

    // "Hep böyle düzelt": düzeltir ve öğretir.
    c.text = 'bir kalwm daha';
    await scan(tester, SpellMarks.pause);
    await tester.tapAt(inWord());
    await tester.pump();
    await tester.pump();
    await tapItem('Hep böyle düzelt: kalem');
    expect(c.text, 'bir kalem daha');
    expect(AutoSpell.memory.learned('kalwm'), 'kalem');
    await tester.pump(const Duration(seconds: 5)); // Erteli kayıt.
  });
}
