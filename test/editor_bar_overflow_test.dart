import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// U6 (kullanıcı isteği 2026-11-18): telefonda alt kapsülde 5 düğme
/// (Biçim · Ekle · Kalem · Liste↔Numaralı · Seç) kalabalıktı → 4 yuva: ilk
/// üçü yerinde, kalanlar ⋮'nin açılır menüsünde. Tablette 5 kalır.
const _note = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Liste',
  items: [
    NoteItem(id: 'a', text: 'süt'),
    NoteItem(id: 'b', text: 'ekmek'),
  ],
);

int _segments(WidgetTester tester) => find
    .descendant(
      of: find.byKey(const ValueKey('editor-tool-capsule')),
      matching: find.byType(InkWell),
    )
    .evaluate()
    .length;

void main() {
  testWidgets('telefonda 4 yuva; ⋮ kalanları menüde gösterir', (tester) async {
    await pumpEditor(tester, _note);
    final more = find.descendant(
      of: find.byKey(const ValueKey('editor-tool-capsule')),
      matching: find.byIcon(Icons.more_horiz),
    );
    expect(more, findsOneWidget);
    expect(_segments(tester), 4);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editor-bar-more-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-bar-more-1')), findsOneWidget);
    expect(find.text('Seç'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-bar-more-0')));
    await tester.pumpAndSettle();
    // Liste ↔ numaralı çalıştı (menüdeki iş düğmeninkiyle aynı).
    await endEditor(tester);
  });

  testWidgets('tablette beşi de kapsülde; ⋮ yalnız çubuktan kaldırılanlar', (
    tester,
  ) async {
    await pumpEditor(tester, _note, size: const Size(1200, 800));
    // ⋯ segmenti + beş düğme.
    expect(_segments(tester), greaterThanOrEqualTo(6));
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    // Varsayılan gizli düğmeler menüde (2026-11-19: "diğer butonlar eksik").
    expect(find.text('Paylaş'), findsOneWidget);
    expect(find.text('Seç'), findsNothing, reason: 'çubukta zaten var');
    await endEditor(tester);
  });

  testWidgets('⋮ Düzenle: menüde düğmeyi çubuğa al, yerinde düzenle', (
    tester,
  ) async {
    Personalize.prefs.value = const UiPrefs();
    await pumpEditor(tester, _note);
    final more = find.descendant(
      of: find.byKey(const ValueKey('editor-tool-capsule')),
      matching: find.byIcon(Icons.more_horiz),
    );
    await tester.tap(more);
    await tester.pumpAndSettle();
    // Gizli (eklenebilir) düğmeler de menüde.
    expect(find.text('Paylaş'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-bar-more-edit')));
    await tester.pumpAndSettle();
    // Aynı menü düzenleme listesine döndü; 📌 Paylaş'ı çubuğa alır.
    final pin = find.byKey(
      const ValueKey('editor-bar-more-pin-editor.bar.share'),
    );
    expect(pin, findsOneWidget);
    await tester.ensureVisible(pin);
    await tester.pumpAndSettle();
    await tester.tap(pin);
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.storedShows(UiItem.barShare), isTrue);
    // Seç'i menüye al.
    final select = find.byKey(
      const ValueKey('editor-bar-more-pin-editor.bar.select'),
    );
    await tester.ensureVisible(select);
    await tester.pumpAndSettle();
    await tester.tap(select);
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.storedShows(UiItem.barSelect), isFalse);
    final done = find.byKey(const ValueKey('editor-bar-more-done'));
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pumpAndSettle();
    // Bitti menüyü kapatır (düzen kipi çubuğun üstünde ayrı açılır).
    expect(find.byKey(const ValueKey('editor-bar-more-editor')), findsNothing);
    Personalize.prefs.value = const UiPrefs();
    await endEditor(tester);
  });

  for (final size in const [Size(412, 915), Size(360, 640)]) {
    testWidgets('⋯ Düzenle çubuğu örtmez, değişiklik çubukta canlı '
        '(${size.width.toInt()} dp)', (tester) async {
      Personalize.prefs.value = const UiPrefs();
      await pumpEditor(tester, _note, size: size);
      final capsule = find.byKey(const ValueKey('editor-tool-capsule'));
      await tester.tap(
        find.descendant(of: capsule, matching: find.byIcon(Icons.more_horiz)),
      );
      await tester.pumpAndSettle();
      final edit = find.byKey(const ValueKey('editor-bar-more-edit'));
      await tester.ensureVisible(edit);
      await tester.pumpAndSettle();
      await tester.tap(edit);
      await tester.pumpAndSettle();
      final editor = find.byKey(const ValueKey('editor-bar-more-editor'));
      expect(editor, findsOneWidget);
      expect(tester.takeException(), isNull);
      final bar = tester.getRect(capsule);
      expect(
        tester.getRect(editor).bottom,
        lessThanOrEqualTo(bar.top),
        reason: 'düzen listesi alt çubuğu örtmemeli',
      );
      // Çubuğun üstünde menü yok: ortasına isabet eden nokta menünün hiçbir
      // parçasına değmez (saydam engel menüyü kapatır, çubuk görünür).
      final hit = tester.hitTestOnBinding(bar.center);
      final editorBox = tester.renderObject(editor);
      expect(
        hit.path.any((e) => identical(e.target, editorBox)),
        isFalse,
        reason: 'menü çubuğu örtüyor',
      );
      // Biçim'i sağ gruba taşı → soldaki kapsülden anında çıkar.
      expect(
        find.descendant(of: capsule, matching: find.byIcon(Icons.text_format)),
        findsOneWidget,
      );
      final side = find.byKey(
        const ValueKey('editor-bar-more-side-editor.bar.format'),
      );
      await tester.ensureVisible(side);
      await tester.pumpAndSettle();
      await tester.tap(side);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: capsule, matching: find.byIcon(Icons.text_format)),
        findsNothing,
      );
      expect(find.byIcon(Icons.text_format), findsWidgets);
      Personalize.prefs.value = const UiPrefs();
      await endEditor(tester);
    });
  }
}
