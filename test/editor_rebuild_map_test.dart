import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';

import 'support/editor_harness.dart';

/// KÖK KURULUM HARİTASI (OTURTMA F64.1, P20 adım 1). Sayı yazdırır, bütçe
/// tutmaz: `expect` yalnız "eylem gerçekleşti" için. Tablo OTURTMA_PLANI.md
/// Ek A altında ("F64.1 haritası"). Bütçeler `perf_budget_test.dart`'ta.
void main() {
  const types = [
    'NoteEditorScreen',
    'NotePageCanvas',
    'ItemsEditor',
    '_LazyItemField',
  ];
  const text = Note(id: 'n', type: NoteType.text, title: 'Kısa', body: 'yazı');
  final list30 = Note(
    id: 'n',
    type: NoteType.checklist,
    title: 'Liste',
    items: [for (var i = 0; i < 30; i++) NoteItem(id: 'i$i', text: 'madde $i')],
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> measure(
    WidgetTester tester,
    String name,
    Future<void> Function() body,
  ) async {
    final counter = BuildCounter()..start();
    try {
      await body();
      await tester.pump(const Duration(seconds: 3));
    } finally {
      counter.stop();
    }
    // ignore: avoid_print
    print(
      'HARITA $name: ${[for (final t in types) '$t=${counter.of(t)}'].join(' ')}',
    );
  }

  Future<void> menu(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(const ValueKey('editor-more')));
    await settle(tester);
    final quick = find.byKey(ValueKey('menu-quick-$id'));
    final tile = find.byKey(ValueKey('menu-tile-$id'));
    final target = quick.evaluate().isNotEmpty ? quick : tile;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  testWidgets('ilk değişiklik (gövdeye 1 harf)', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, text, repo: repo);
    await tester.tap(find.widgetWithText(TextField, 'yazı').first);
    await tester.pump(const Duration(milliseconds: 400));
    await measure(tester, 'ilk_degisiklik', () async {
      tester.testTextInput.enterText('yazıa');
      await tester.pump(const Duration(milliseconds: 50));
    });
    expect(repo.lastSaved!.body, 'yazıa');
    await endEditor(tester);
  });

  testWidgets('işaretle (30 madde, 8. kutucuk)', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, list30, repo: repo);
    await settle(tester);
    await measure(tester, 'isaretle', () async {
      await tester.tap(find.byType(Checkbox).at(7));
    });
    expect(repo.lastSaved!.items.where((i) => i.checked), hasLength(1));
    await endEditor(tester);
  });

  testWidgets('madde ekle (Enter)', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, list30, repo: repo);
    await settle(tester);
    await tester.tap(find.text('madde 7'));
    await tester.pump(const Duration(milliseconds: 400));
    await measure(tester, 'enter', () async {
      tester.testTextInput.enterText('madde 7\n');
    });
    expect(repo.lastSaved!.items, hasLength(31));
    await endEditor(tester);
  });

  testWidgets('sabitle (üst çubuk iğnesi)', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, text, repo: repo);
    await measure(tester, 'sabitle', () async {
      await tester.tap(find.byTooltip('Sabitle'));
      await settle(tester);
    });
    expect(repo.lastSaved!.pinned, isTrue);
    await endEditor(tester);
  });

  testWidgets('yıldız (⋮ levhası)', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, text, repo: repo);
    await measure(tester, 'yildiz', () => menu(tester, 'star'));
    expect(repo.lastSaved!.starred, isTrue);
    await endEditor(tester);
  });

  testWidgets('biçim paneli aç → kapat', (tester) async {
    await pumpEditor(tester, text);
    await measure(tester, 'bicim_paneli', () async {
      await tester.tap(find.byTooltip('Biçim'));
      await settle(tester);
      expect(find.byType(FormatBar), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('format-close')));
      await settle(tester);
    });
    expect(find.byType(FormatBar), findsNothing);
    await endEditor(tester);
  });

  testWidgets('geri al → yinele', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, text, repo: repo);
    await tester.tap(find.widgetWithText(TextField, 'yazı').first);
    await tester.pump(const Duration(milliseconds: 400));
    tester.testTextInput.enterText('yazıa');
    await tester.pump(const Duration(seconds: 3));
    await measure(tester, 'geri_al', () async {
      await tester.tap(find.byTooltip('Geri al'));
      await settle(tester);
    });
    expect(find.widgetWithText(TextField, 'yazı'), findsWidgets);
    final redo = tester.widget<IconButton>(
      find.byKey(const ValueKey('editor-redo')),
    );
    // P20 adım 3: metin geri alınınca kök kurulmuyordu, yinele bayat
    // `onPressed: null` kalıyordu — artık `_undoN`'u dinliyor.
    expect(redo.onPressed, isNotNull, reason: 'geri al → yinele etkin');
    await measure(tester, 'yinele', () async {
      await tester.tap(find.byKey(const ValueKey('editor-redo')));
      await settle(tester);
    });
    expect(find.widgetWithText(TextField, 'yazıa'), findsWidgets);
    await endEditor(tester);
  });

  testWidgets('arama aç (alt çubuk → Notta ara)', (tester) async {
    await pumpEditor(tester, text);
    final fields = find.byType(TextField).evaluate().length;
    await measure(tester, 'arama_ac', () async {
      await tester.tap(find.byTooltip('Notta ara'));
      await settle(tester);
    });
    expect(find.byType(TextField).evaluate().length, greaterThan(fields));
    await endEditor(tester);
  });
}
