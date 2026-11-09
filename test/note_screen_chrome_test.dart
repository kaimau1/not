import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';

import 'support/editor_harness.dart';

/// Not ekranının kabuğu (TUTARLILIK Faz 38): üst çubuk, "+", işaretli blok,
/// klavye turu. Kurulum ortak düzenekte (`support/editor_harness.dart`).
const _list = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Başlık',
  items: [
    NoteItem(id: 'a', text: 'açık'),
    NoteItem(id: 'b', text: 'bitti bir', checked: true),
    NoteItem(id: 'c', text: 'bitti iki', checked: true),
  ],
);

final _dated = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Başlık',
  updatedAt: DateTime(2026, 11, 5),
);

void main() {
  testWidgets('üst çubuk sade: düzenleme yokken geri al/yinele/palet yok', (
    tester,
  ) async {
    // Kullanıcı isteği 2026-11-05 "üst alanda sadeleşme": açılışta çubukta
    // yalnız tarih · senkron · sabitle · ⋮ (palet ⋮ menüsünde).
    await pumpEditor(tester, _dated);
    Finder inBar(IconData icon) =>
        find.descendant(of: find.byType(AppBar), matching: find.byIcon(icon));
    expect(inBar(Icons.undo), findsNothing);
    expect(inBar(Icons.redo), findsNothing);
    expect(inBar(Icons.palette_outlined), findsNothing);
    expect(
      tester.getCenter(inBar(Icons.push_pin_outlined)).dx,
      lessThan(tester.getCenter(inBar(Icons.more_vert)).dx),
    );
    await endEditor(tester);
  });

  test('üst çubuk tarihi kısa', () {
    final now = DateTime(2026, 11, 5, 15);
    expect(editorBarDate(DateTime(2026, 11, 5, 13, 7), now), '13:07');
    expect(editorBarDate(DateTime(2026, 3, 2, 9, 5), now), contains('09:05'));
    expect(editorBarDate(DateTime(2025, 3, 2, 9, 5), now), contains('2025'));
    expect(
      editorBarDate(DateTime(2025, 3, 2, 9, 5), now),
      isNot(contains('09:05')),
    );
  });

  testWidgets('geri yokken tarih kenara yapışmaz (F38.2)', (tester) async {
    await pumpEditor(tester, _dated);
    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.titleSpacing, 16);
    await endEditor(tester);
  });

  testWidgets('başlıkta tek "+": levha açar, başlık alanı genişler (F38.3)', (
    tester,
  ) async {
    await pumpEditor(tester, _list);
    final plus = find.byKey(const ValueKey('note-meta-chip'));
    expect(tester.widget(plus), isA<IconButton>());
    expect(tester.getSize(plus).width, lessThanOrEqualTo(48));
    await tester.tap(plus);
    await tester.pumpAndSettle();
    for (final id in ['add-tag', 'reminder', 'folder']) {
      expect(
        find.byKey(ValueKey('menu-quick-$id')),
        findsOneWidget,
        reason: id,
      );
    }
    expect(find.byKey(const ValueKey('sheet-close')), findsOneWidget);
    await endEditor(tester);
  });

  testWidgets('işaretlileri sil bloğun başında (F38.4)', (tester) async {
    await pumpEditor(tester, _list);
    expect(find.text('İşaretliler (2)'), findsOneWidget);
    final delete = tester.getTopLeft(
      find.byKey(const ValueKey('items-delete-checked')),
    );
    final firstChecked = tester.getTopLeft(find.text('bitti bir'));
    expect(delete.dy, lessThan(firstChecked.dy));
    await endEditor(tester);
  });

  testWidgets('klavye turları birikmez, editör gövdesi kurulmaz (F38.7)', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      _list.copyWith(body: List.generate(30, (i) => 'Satır $i').join('\n')),
    );
    final counter = BuildCounter()..start();
    addTearDown(counter.stop);
    final counts = counter.counts;

    Future<void> frame(double inset) async {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      tester.view.padding = FakeViewPadding(
        top: 30,
        bottom: (48 - inset).clamp(0.0, 48.0),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    Future<Map<String, int>> cycle() async {
      counts.clear();
      for (final i in [20.0, 60.0, 120.0, 200.0, 300.0]) {
        await frame(i);
      }
      // Hareket sırasında gövde kurulmaz (oturma kurulumu aşağıda, ayrı).
      final moving = Map<String, int>.of(counts);
      await tester.pump(const Duration(milliseconds: 300));
      for (final i in [200.0, 120.0, 60.0, 20.0, 0.0]) {
        await frame(i);
      }
      await tester.pump(const Duration(milliseconds: 300));
      return moving;
    }

    final first = await cycle();
    expect(first, isNot(contains('NoteEditorScreen')));
    expect(first, isNot(contains('EditableText')));
    expect(first, isNot(contains('ItemsEditor')));
    // Kullanıcı bildirimi: "her açılışta artarak". 20. tur 1. turla aynı.
    // Isınma 3 tur (2026-11-10): hızlı satır artık klavye kapanınca
    // sökülmüyor; ilk açılıştaki tek seferlik parlama animasyonu (1,4 sn +
    // 0,6 sn) 3. tura kadar sürüyor.
    await cycle();
    await cycle();
    await cycle();
    final baseline = await cycle();
    for (var i = 0; i < 15; i++) {
      final later = await cycle();
      expect(later, baseline, reason: 'tur ${i + 6}');
    }
    expect(tester.binding.transientCallbackCount, 0);
    await endEditor(tester);
  });

  testWidgets('klavye açıkken üstte hızlı işlev satırı, kapanınca tarih', (
    tester,
  ) async {
    await pumpEditor(tester, _dated);
    expect(find.byKey(const ValueKey('editor-quick-row')), findsNothing);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byKey(const ValueKey('editor-quick-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-bold')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-pen')), findsOneWidget);
    // Yazarken üst çubuk: hızlı satır + geri al/yinele + en sağda ⋮
    // (kullanıcı isteği 2026-11-08: "3 nokta geri gelsin").
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-spell')), findsOneWidget);
    // Düzenle artık hızlı satırın ⋮ menüsünde (2026-11-09).
    expect(find.byKey(const ValueKey('quick-row-customize')), findsNothing);
    expect(find.byKey(const ValueKey('quick-row-more')), findsOneWidget);
    // SADE VARSAYILAN (2026-11-09): kalem · yazım · paket · ekle · kalın ·
    // renk; gerisi düzenleme alanından eklenir.
    expect(find.byKey(const ValueKey('quick-row-package')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-attach')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-color')), findsOneWidget);
    for (final k in ['italic', 'bullet', 'photo', 'reminder', 'heading']) {
      expect(find.byKey(ValueKey('quick-row-$k')), findsNothing, reason: k);
    }
    expect(find.byIcon(Icons.undo), findsOneWidget);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byKey(const ValueKey('editor-quick-row')), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsWidgets);
    await endEditor(tester);
  });
}
