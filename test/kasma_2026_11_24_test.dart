import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_table.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart'
    show debugEagerItemFields;

import 'support/editor_harness.dart';

/// Kullanıcı bulgusu 2026-11-24: "notlar açılıp kapanırken, klavye açılıp
/// kapanırken kasma, donma" — ekran görüntüsündeki not: yüzen tablo + 374
/// işaretli madde. Kanıt (masaüstü kıyası, v1.2.128 → düzeltme):
/// açılışın 2. karesi 1959 kurulum/121 ms → < 4 ms; açılış sonrası kuyruk
/// 7998 → 6 kurulum; klavye ve kapanış sayıları değişmedi.
Note _bigNote({bool table = true, int open = 6}) => Note(
  id: 'big',
  type: NoteType.checklist,
  title: 'Notlar',
  items: [
    for (var k = 0; k < open; k++)
      NoteItem(id: 'u$k', text: 'Madde $k biraz uzun bir yazı'),
    for (var k = 0; k < 374; k++)
      NoteItem(id: 'c$k', text: 'İşaretli madde $k', checked: true),
  ],
  attachments: [
    if (table)
      newNoteTable(
        name: 'Tablo',
        height: 600,
        rows: 5,
        columns: 3,
      ).copyWith(displayWidth: 1, x: 0, pageY: 170),
  ],
);

int _total(BuildCounter c) => c.counts.values.fold(0, (a, b) => a + b);

void main() {
  testWidgets('tablo uzayınca (bant değişir) satırlar ve kök kurulmaz', (
    tester,
  ) async {
    await pumpEditor(tester, _bigNote());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final add = find.byKey(const ValueKey('note-table-add-row'));
    await tester.ensureVisible(add);
    await tester.pump(const Duration(milliseconds: 300));
    final counter = BuildCounter()..start();
    await tester.tap(add);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    counter.stop();
    // Eskiden bant değişimi `setState` → editörün kökü + bütün satırlar.
    expect(counter.of('NoteEditorScreen'), 0, reason: 'kök kurulmadı');
    expect(counter.of('_RowSlot'), 0, reason: 'satırlar kurulmadı');
    expect(counter.of('Checkbox'), 0);
    await endEditor(tester);
  });

  // Tablosuz notta kaç gerçek alan kuruluyor (aşağıdaki testin tabanı).
  var plainFields = -1;
  Future<int> realFields(WidgetTester tester, Note note) async {
    await pumpEditor(tester, note);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final n = find.byType(EditableText).evaluate().length;
    await endEditor(tester);
    return n;
  }

  testWidgets('taban: tablosuz notun gerçek alanları', (tester) async {
    debugEagerItemFields = false;
    addTearDown(() => debugEagerItemFields = true);
    plainFields = await realFields(tester, _bigNote(table: false, open: 40));
    expect(plainFields, greaterThan(0));
  });

  testWidgets('tam genişlik tablo maddeleri gerçek alana çevirmez', (
    tester,
  ) async {
    // Eskiden yüzen her kutu (tablo dahil) görünen bütün maddeleri gerçek
    // TextField yapıyordu; tablo BLOK bant — satır bütünüyle itilir.
    debugEagerItemFields = false;
    addTearDown(() => debugEagerItemFields = true);
    expect(await realFields(tester, _bigNote(open: 40)), plainFields);
  });

  testWidgets('gizli işaretliler için büyüme döngüsü dönmez', (tester) async {
    await pumpEditor(tester, _bigNote(table: false));
    await tester.pump(const Duration(milliseconds: 600));
    final counter = BuildCounter()..start();
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    counter.stop();
    // Eskiden: işaretliler 10'ar gösterildiği hâlde bütçe 380'e doğru büyüyor,
    // liste ~45 kare boyunca her karede kuruluyordu (kare başı ~150).
    expect(counter.of('ItemsEditor'), lessThanOrEqualTo(2));
    expect(_total(counter), lessThan(800));
    await endEditor(tester);
  });
}
