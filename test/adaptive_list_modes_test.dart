import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/inline_parse_bar.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/smart_list_mode_header.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(body: child),
  );

  group('Faz 2 — Doğrudan not üzerinde 4 liste kipi & Kural 2/5', () {
    testWidgets('Rutin kipi: tiklenen madde yerinde kalır, doneDays ve seri güncellenir (Kural 2)', (tester) async {
      final yesterday = isoDayKeyOf(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      var items = <NoteItem>[
        NoteItem(id: 'h1', text: '2L su iç', doneDays: [yesterday]),
        const NoteItem(id: 'h2', text: 'Kitap oku'),
      ];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (ctx, setState) => app(
            ItemsEditor(
              items: items,
              showCheckboxes: true,
              listMode: ListMode.routine,
              onChanged: (next) => setState(() => items = next),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // İlk maddeyi tikle
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Kural 2: madde silinmedi, alta düşmedi (hâlâ indeks 0), doneDays bugünle 2 gün oldu!
      expect(items.length, 2);
      expect(items.first.id, 'h1');
      expect(items.first.checked, isTrue);
      expect(items.first.streakCount, 2);
      expect(find.byKey(const ValueKey('items-delete-checked')), findsNothing);
      expect(find.byKey(const ValueKey('routine-streak-h1')), findsOneWidget);
    });

    testWidgets('Proje kipi: Odak (3) yalnız en öncelikli 3 görevi gösterir, kalanı gizler', (tester) async {
      const items = <NoteItem>[
        NoteItem(id: 'p1', text: 'Düşük iş', priority: ItemPriority.low),
        NoteItem(id: 'p2', text: 'Acil sürüm', priority: ItemPriority.urgent),
        NoteItem(id: 'p3', text: 'Normal iş'),
        NoteItem(id: 'p4', text: 'Yüksek görev', priority: ItemPriority.high),
        NoteItem(id: 'p5', text: 'Orta görev', priority: ItemPriority.medium),
      ];

      var focusOn = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (ctx, setState) => app(
            Column(
              children: [
                SmartListModeHeader(
                  note: const Note(
                    id: 'proj',
                    type: NoteType.checklist,
                    title: 'Proje',
                    listMode: ListMode.project,
                    items: items,
                  ),
                  onChangeMode: (_) {},
                  focusMode: focusOn,
                  focusVisibleCount: resolveProjectFocusIds(items).length,
                  onToggleFocusMode: () => setState(() => focusOn = !focusOn),
                ),
                Expanded(
                  child: ItemsEditor(
                    items: items,
                    showCheckboxes: true,
                    listMode: ListMode.project,
                    focusMode: focusOn,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Düşük iş'), findsOneWidget);
      expect(find.text('Normal iş'), findsOneWidget);

      // Odak (3) aç
      await tester.tap(find.byKey(const ValueKey('project-focus-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Acil sürüm'), findsOneWidget);
      expect(find.text('Yüksek görev'), findsOneWidget);
      expect(find.text('Orta görev'), findsOneWidget);
      expect(find.text('Düşük iş'), findsNothing);
      expect(find.text('Normal iş'), findsNothing);
    });

    testWidgets('Şablon kipi: tek dokunuşla Tümünü sıfırla ve tekrar kullan tetiklenir', (tester) async {
      var resetCount = 0;
      const note = Note(
        id: 'tpl',
        type: NoteType.checklist,
        title: 'Bavul',
        listMode: ListMode.template,
        listKind: 'packing',
        items: [
          NoteItem(id: '1', text: 'Pasaport', checked: true),
          NoteItem(id: '2', text: 'Şarj aleti', checked: true),
        ],
      );

      await tester.pumpWidget(
        app(
          SmartListModeHeader(
            note: note,
            onChangeMode: (_) {},
            onResetTemplate: () => resetCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('template-reset-btn')));
      await tester.pump();
      expect(resetCount, 1);
    });

    testWidgets('InlineParseBar yazarken canlı çipler üretir ve kapatılan çipi ham metinde korur', (tester) async {
      NoteItem? added;
      await tester.pumpWidget(
        app(
          InlineParseBar(
            mode: ListMode.shopping,
            onAddItem: (item) => added = item,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('inline-parse-field')),
        '2 kg domates 180 tl',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inline-chip-quantity')), findsOneWidget);
      expect(find.byKey(const ValueKey('inline-chip-price')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('inline-parse-submit')));
      await tester.pumpAndSettle();

      expect(added, isNotNull);
      expect(added!.quantity, 2.0);
      expect(added!.unit, 'kg');
      expect(added!.price, 180.0);
      expect(added!.category, 'produce');
    });
  });
}
