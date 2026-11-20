import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// "Alışverişi bitir" (2026-11-20, 17K AL-2; KARAR PLAN 1.0b P1): alışveriş
/// listesinde işaretliler başlığındaki "Sil" alınanları kaldırır, sık
/// aldıkların hafızasını günceller, Geri al ikisini de geri getirir.
void main() {
  const market = Note(
    id: 'm',
    type: NoteType.checklist,
    title: 'Market listesi',
    items: [
      NoteItem(id: 'a', text: 'Süt', checked: true),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta', checked: true),
    ],
  );

  testWidgets('alışveriş listesinde alınanlar kalkar, hafıza öğrenir, geri '
      'alınır', (tester) async {
    final container = await pumpEditor(tester, market);
    expect(find.byKey(const ValueKey('items-delete-checked')), findsNothing);
    final finish = find.byKey(const ValueKey('items-finish-shopping'));
    expect(finish, findsOneWidget);
    expect(find.text('Alışverişi bitir'), findsOneWidget);

    await tester.tap(finish);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Alışveriş bitti: 2 madde listeden kaldırıldı'),
      findsOneWidget,
    );
    expect(find.text('Süt'), findsNothing);
    expect(find.text('Yumurta'), findsNothing);
    expect(find.text('Ekmek'), findsOneWidget);
    final memory = container.read(quickEntryMemoryProvider);
    expect(memory.top('smart:market'), containsAll(['Süt', 'Yumurta']));
    expect(memory.top('b:shopping'), containsAll(['Süt', 'Yumurta']));

    await tester.tap(find.text('Geri al'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Süt'), findsOneWidget);
    expect(find.text('Yumurta'), findsOneWidget);
    expect(
      container.read(quickEntryMemoryProvider).top('smart:market'),
      isEmpty,
    );
    await endEditor(tester);
  });

  testWidgets('alışveriş listesi olmayanda "Sil" kalır', (tester) async {
    await pumpEditor(
      tester,
      market.copyWith(
        title: 'Yapılacaklar',
        items: const [
          NoteItem(id: 'a', text: 'Faturayı öde', checked: true),
          NoteItem(id: 'b', text: 'Anneyi ara'),
        ],
      ),
    );
    expect(find.byKey(const ValueKey('items-delete-checked')), findsOneWidget);
    expect(find.byKey(const ValueKey('items-finish-shopping')), findsNothing);
    await endEditor(tester);
  });
}
