import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// 2026-11-15 madde kasması: `ItemsEditor`'dan gelen madde değişikliği
/// editörün KÖKÜNÜ kurmaz (`_mutate(itemsShown: true)`). Kökün yeniden
/// kurulumunun eskiden "bedavaya" getirdiği şeyler kaybolmasın.
void main() {
  testWidgets('boş maddeye yazınca kutusu etkinleşir (kök kurulmadan)', (
    tester,
  ) async {
    final repo = CountingNotesRepository();
    await pumpEditor(
      tester,
      const Note(
        id: 'n',
        type: NoteType.checklist,
        title: 'Liste',
        items: [NoteItem(id: 'a', text: 'bir')],
      ),
      repo: repo,
    );
    await tester.tap(find.text('bir'));
    await tester.pump(const Duration(milliseconds: 400));
    tester.testTextInput.enterText('bir\n');
    await tester.pump(const Duration(milliseconds: 400));
    Checkbox box(int i) => tester.widget<Checkbox>(find.byType(Checkbox).at(i));
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(box(1).onChanged, isNull, reason: 'boş maddenin kutusu pasif');

    final counter = BuildCounter()..start();
    tester.testTextInput.enterText('x');
    await tester.pump();
    counter.stop();
    expect(box(1).onChanged, isNotNull, reason: 'dolu maddenin kutusu etkin');
    expect(counter.of('NoteEditorScreen'), 0, reason: 'kök kurulmamalı');

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump(const Duration(seconds: 3));
    expect(repo.lastSaved!.items.map((i) => (i.text, i.checked)), [
      ('bir', false),
      ('x', true),
    ]);
    await endEditor(tester);
  });
}
