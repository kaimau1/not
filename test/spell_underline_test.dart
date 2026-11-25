import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
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
    SpellMarks.debugReset();
  });
  tearDown(() {
    AutoSpell.mode.value = SpellMode.off;
    AutoSpell.enabled.value = false;
    SpellMarks.debugReset();
  });

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

  /// Cihaz denetçisi taklidi: [wrong] kelimelerini (önerileriyle) yanlış
  /// sayar; gelen metinler [asked]e yazılır.
  List<String> fakeNative(Map<String, List<String>> wrong) {
    final asked = <String>[];
    SpellMarks.nativeCheck = (text) async {
      asked.add(text);
      final out = <SuggestionSpan>[];
      for (final m in RegExp(r'\S+').allMatches(text)) {
        final s = wrong[m[0]];
        if (s != null) {
          out.add(SuggestionSpan(TextRange(start: m.start, end: m.end), s));
        }
      }
      return out;
    };
    return asked;
  }

  testWidgets(
    'öneri bulunamayan bilinmeyen kelime cihaz denetçisine sorulur, '
    'yanlışsa altı çizilir (kullanıcı 2026-11-25: "petnr", "nabr")',
    (tester) async {
      final asked = fakeNative({
        'petnr': ['peynir', 'Petrol'],
        'nabr': ['naber'],
      });
      final c = TextEditingController(text: 'petnr ekmek ama nabr geldi');
      final m = SpellMarks.acquire(c);
      addTearDown(m.release);
      await scan(tester);
      expect(marksOf(m), [(0, 5, 'petnr'), (16, 20, 'nabr')]);
      // Bilinen kelimeler ("ekmek", "ama", "geldi") sorulmaz; tek istek.
      expect(asked, ['petnr nabr']);
      expect(SpellMarks.suggestionsFor('petnr'), ['peynir', 'petrol']);

      // Sözlüğe eklenen kelime bir daha çizilmez (cihaz yanlış dese de).
      AutoSpell.addToDictionary('petnr');
      await scan(tester);
      expect(marksOf(m), [(16, 20, 'nabr')]);
      expect(asked, hasLength(1), reason: 'yanıt önbellekte');
      await tester.pump(const Duration(seconds: 5)); // Erteli kayıt.
    },
  );

  testWidgets(
    'yalnız büyük harf isteyen (özel ad) çizilmez; denetçi meşgulse '
    'kelime sonraki denetimde yeniden sorulur',
    (tester) async {
      var busy = true;
      final asked = <String>[];
      SpellMarks.nativeCheck = (text) async {
        asked.add(text);
        if (busy) return null;
        return [
          const SuggestionSpan(TextRange(start: 0, end: 5), ['Zeyno']),
          const SuggestionSpan(TextRange(start: 6, end: 10), ['naber']),
        ];
      };
      final c = TextEditingController(text: 'zeyno nabr');
      final m = SpellMarks.acquire(c);
      addTearDown(m.release);
      await scan(tester);
      expect(m.marks, isEmpty);
      expect(asked, ['zeyno nabr']);

      busy = false;
      c.text = 'zeyno nabr ';
      await scan(tester, SpellMarks.pause);
      expect(asked, hasLength(2));
      expect(marksOf(m), [(6, 10, 'nabr')]);
    },
  );

  testWidgets(
    'klavyenin otomatik düzeltmesi kipe bağlı: yalnız "Otomatik"te açık '
    '(kullanıcı 2026-11-25: "otomatik düzelt kapalı ama düzeliyor")',
    (tester) async {
      AutoSpell.enabled.value = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ItemsEditor(
                items: const [NoteItem(id: 'a', text: 'bir madde')],
                onChanged: (_) {},
                showCheckboxes: true,
                shrinkWrap: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      expect(field, findsWidgets);
      final state = tester.state(field.first);
      expect(tester.widget<TextField>(field.first).autocorrect, isFalse);

      AutoSpell.enabled.value = true;
      await tester.pump();
      expect(tester.widget<TextField>(field.first).autocorrect, isTrue);
      expect(
        identical(tester.state(field.first), state),
        isTrue,
        reason: 'alan yeniden kurulmaz (klavye düşmez)',
      );
    },
  );

  testWidgets('madde satırında (odaklı) dalgalı çizgi çizilir', (
    tester,
  ) async {
    fakeNative({
      'petnr': ['peynir'],
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ItemsEditor(
              items: const [NoteItem(id: 'a', text: 'petnr ekmek geldi')],
              onChanged: (_) {},
              showCheckboxes: true,
              shrinkWrap: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await scan(tester, SpellMarks.pause);
    final c = tester.widget<TextField>(find.byType(TextField).first).controller!;
    expect(SpellMarks.of(c)!.marks.map((k) => k.word), ['petnr']);
    final paint = tester.renderObject(
      find
          .descendant(
            of: find.byType(AttachmentTagChips),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(paint, paints..path(), reason: 'dalgalı çizgi çizilir');
  });

  testWidgets(
    'Elle düzeltilen yazım öğrenilir ve yenilenen menü hatalı kelime başlığını gösterir',
    (tester) async {
      fakeNative({
        'yazm': ['yaz'],
      });
      final c = WrapTextController(text: 'denetim yazm testi');
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
      expect(SpellMarks.of(c)!.marks.map((k) => k.word), ['yazm']);

      final render = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final rect = render.getLocalRectForCaret(const TextPosition(offset: 10));
      await tester.tapAt(render.localToGlobal(rect.center));
      await tester.pump();
      await tester.pump();

      // Yenilenen yazım menüsünde hatalı kelime ve durum etiketi görünür.
      expect(find.text('yazm'), findsOneWidget);
      expect(find.text('Yazım'), findsOneWidget);
      expect(find.text('Elle düzelt'), findsOneWidget);

      await tester.tap(find.text('Elle düzelt'));
      await tester.pumpAndSettle();

      // Yenilenen iletişim kutusunda öğrenme anahtarı varsayılan açık.
      expect(find.byKey(const ValueKey('spell-manual-learn-toggle')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('spell-manual-field')),
        'yazım',
      );
      await tester.pump();
      expect(find.text('yazm → yazım'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('spell-manual-ok')));
      await tester.pumpAndSettle();

      expect(c.text, 'denetim yazım testi');
      expect(AutoSpell.memory.learned('yazm'), 'yazım');
      expect(AutoSpell.memory.known('yazım'), isTrue);
      await tester.pump(const Duration(seconds: 5)); // Erteli kayıt.
    },
  );
}
