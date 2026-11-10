import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';

import 'support/editor_harness.dart';

/// F60.2 / S10 (OTURTMA Ek A, KALANLAR I1 "paket kasması"): açık paketin
/// maddesine odaklanıp editörün çubuğuna (Biçim) dokunmak paketi
/// KAPATMAMALI, odak yerinde kalmalı.
/// Bütçe `perf_budget/budgets.json` S10 (mandal: yalnız düşer).
int _budget(String key) =>
    ((jsonDecode(File('test/perf_budget/budgets.json').readAsStringSync())
                as Map<String, dynamic>)['S10']
            as Map<String, dynamic>)[key]
        as int;

void main() {
  const note = Note(
    id: 'n',
    type: NoteType.checklist,
    title: 'Paketli',
    items: [
      NoteItem(id: 'a', text: 'önce'),
      NoteItem(id: 'p1', text: 'bir', package: 'pk'),
      NoteItem(id: 'p2', text: 'iki', package: 'pk'),
      NoteItem(id: 'p3', text: 'üç', package: 'pk'),
      NoteItem(id: 'p4', text: 'dört', package: 'pk'),
      NoteItem(id: 'p5', text: 'beş', package: 'pk'),
      NoteItem(id: 'p6', text: 'altı', package: 'pk'),
      NoteItem(id: 'z', text: 'sonra'),
    ],
  );

  final pill = find.byKey(const ValueKey('note-package-pill'));

  testWidgets('S10: açık pakette Biçim\'e dokunmak paketi kapatmaz', (
    tester,
  ) async {
    await pumpEditor(tester, note);
    expect(pill, findsOneWidget);

    await tester.tap(pill);
    await tester.pump(const Duration(milliseconds: 300));
    expect(pill, findsNothing, reason: 'paket açıldı');

    await tester.tap(find.text('üç'));
    await tester.pump(const Duration(milliseconds: 300));
    final focused = FocusManager.instance.primaryFocus;
    expect(focused, isNotNull);
    expect(pill, findsNothing);

    await tester.tap(find.byTooltip('Biçim'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(pill, findsNothing, reason: 'Biçim paketi kapatmamalı');
    expect(FocusManager.instance.primaryFocus, same(focused));

    // Paket dışına (başka maddeye) dokunmak yine kapatır.
    await tester.tap(find.text('sonra'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(pill, findsOneWidget, reason: 'dışarı dokununca kapanır');

    expect(
      tester.state<ItemsEditorState>(find.byType(ItemsEditor)).debugItems,
      hasLength(8),
    );
    await endEditor(tester);
  });

  testWidgets('aç/kapa ve paketle/çöz: paket dışı satır yeniden kurulmaz', (
    tester,
  ) async {
    debugEagerItemFields = false;
    addTearDown(() => debugEagerItemFields = true);
    final items = [
      for (var i = 0; i < 12; i++) NoteItem(id: 'a$i', text: 'önce $i'),
      for (var i = 0; i < 6; i++)
        NoteItem(id: 'p$i', text: 'üye $i', package: 'pk'),
      for (var i = 0; i < 12; i++) NoteItem(id: 'z$i', text: 'sonra $i'),
    ];
    await pumpEditor(
      tester,
      Note(id: 'n', type: NoteType.checklist, title: 'Uzun', items: items),
    );
    final fields = find.byType(TextField, skipOffstage: false);

    // Madde satırının metin yuvası: ilk kurulum (yeni görünen satır) ile
    // YENİDEN kurulum (var olan satır) ayrı sayılır.
    var mounted = 0;
    var rebuilt = 0;
    Future<void> measure(Future<void> Function() action) async {
      mounted = 0;
      rebuilt = 0;
      debugOnRebuildDirtyWidget = (e, builtOnce) {
        if (e.widget.runtimeType.toString() != '_LazyItemField') return;
        builtOnce ? rebuilt++ : mounted++;
      };
      try {
        await action();
        await tester.pump(const Duration(milliseconds: 300));
      } finally {
        debugOnRebuildDirtyWidget = null;
      }
    }

    final before = fields.evaluate().length;
    await measure(() => tester.tap(pill));
    final openFields = fields.evaluate().length - before;
    // ignore: avoid_print
    print(
      'aç: kurulan $mounted, yeniden kurulan $rebuilt, TextField +$openFields',
    );
    expect(pill, findsNothing);
    expect(
      openFields,
      lessThanOrEqualTo(_budget('acilis_textfield')),
      reason: 'üyeler düz çizimle',
    );
    expect(
      rebuilt,
      lessThanOrEqualTo(_budget('acilis_yeniden_kurulan_satir')),
      reason: 'paket dışı satır yeniden kurulmaz',
    );
    expect(mounted, greaterThanOrEqualTo(6));

    // Bir üyeye odaklan, çöz (tek madde) → yeniden paketle.
    await tester.tap(find.text('üye 2', findRichText: true));
    await tester.pump(const Duration(milliseconds: 300));
    final state = tester.state<ItemsEditorState>(find.byType(ItemsEditor));
    await measure(() async => expect(state.togglePackage(), isTrue));
    final unpack = (mounted, rebuilt);
    expect(state.debugItems.firstWhere((i) => i.id == 'p2').package, isEmpty);
    await measure(() async => expect(state.togglePackage(), isTrue));
    final pack = (mounted, rebuilt);
    // ignore: avoid_print
    print('çöz: (kurulan, yeniden) $unpack, paketle: $pack');
    // Önbellek temizlenirken görünen bütün satırlar (19/20) kuruluyordu;
    // şimdi değişen madde + paket hapı çevresi.
    expect(
      unpack.$1 + unpack.$2,
      lessThanOrEqualTo(_budget('paketle_coz_kurulan_satir')),
    );
    expect(
      pack.$1 + pack.$2,
      lessThanOrEqualTo(_budget('paketle_coz_kurulan_satir')),
    );
    expect(state.debugItems, hasLength(30));
    await endEditor(tester);
  });
}
