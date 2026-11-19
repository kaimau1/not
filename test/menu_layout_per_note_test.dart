import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/quick_row_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart';

/// Kullanıcı istekleri 2026-11-19 (telefon ekran görüntüleri):
///  * hızlı menüye eklenen "Onay kutusu" liste notunda SESSİZCE yoktu
///    (kök neden: `onCheckbox` yalnız metin notunda verilirdi → düğme hiç
///    çizilmezdi; düzenleme levhası ise "Menüde" gösteriyordu);
///  * alt çubukta sol ↔ sağ (renkli) grup arası taşıma ⋯ Düzenle'de;
///  * menü düzeni "Tümüne uygula / Yalnız bu nota", sıfırlanabilir.
const _list = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Kanallarım',
  items: [
    NoteItem(id: 'a', text: 'süt'),
    NoteItem(id: 'b', text: 'ekmek'),
  ],
);

void main() {
  setUp(Personalize.debugReset);
  tearDown(Personalize.debugReset);

  group('not başına düzen (Personalize)', () {
    test('yalnız bu nota: genel düzen değişmez; sıfırla genel düzene döner; '
        'kayıt yeniden okunur', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await SharedPreferences.getInstance();
      Personalize.attach(store);
      final owner = Object();
      final id = UiItem.quickRow('italic');
      Personalize.enterNote('n1', owner);
      expect(Personalize.noteHasOwnLayout, isFalse);
      Personalize.setNoteOwnLayout(true);
      Personalize.updateLayout((p) => p.withVisible(id, true));
      expect(Personalize.current.shows(id), isTrue);
      expect(Personalize.prefs.value.shows(id), isFalse, reason: 'genel');
      // Başka not: genel düzen.
      Personalize.enterNote('n2', Object());
      expect(Personalize.current.shows(id), isFalse);
      // Geri dönüş ve yeniden okuma.
      Personalize.debugReset();
      Personalize.attach(store);
      Personalize.enterNote('n1', owner);
      expect(Personalize.current.shows(id), isTrue);
      // Genel değişiklik (düzen dışı alan) notta da geçerli.
      Personalize.update((p) => p.withVisible(UiItem.homeAi, false));
      expect(Personalize.current.shows(UiItem.homeAi), isFalse);
      Personalize.setNoteOwnLayout(false);
      expect(Personalize.current.shows(id), isFalse);
      expect(Personalize.noteHasOwnLayout, isFalse);
    });

    test('kalıcı silinen notun yerel düzeni de gider', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await SharedPreferences.getInstance();
      Personalize.attach(store);
      Personalize.enterNote('sil', Object());
      Personalize.setNoteOwnLayout(true);
      expect(store.getString('note_ui_layout_v1'), contains('sil'));
      Personalize.forgetNote('sil');
      expect(Personalize.noteHasOwnLayout, isFalse);
      expect(store.getString('note_ui_layout_v1'), isNot(contains('sil')));
    });

    test('eski editörün geç kapanışı yeni açılan aynı notu silmez', () {
      final a = Object(), b = Object();
      Personalize.enterNote('n', a);
      Personalize.setNoteOwnLayout(true);
      Personalize.enterNote('n', b);
      Personalize.leaveNote(a);
      expect(Personalize.activeNote, 'n');
      expect(Personalize.noteOverride.value, isNotNull);
      Personalize.leaveNote(b);
      expect(Personalize.activeNote, isNull);
      expect(Personalize.noteOverride.value, isNull);
    });
  });

  testWidgets('levha: bu notta çizilmeyen düğmeyi açıkça yazar; '
      'Yalnız bu nota seçimi', (tester) async {
    Personalize.enterNote('n', Object());
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: QuickRowEditor(unavailable: {'subheading'})),
      ),
    );
    expect(
      find.byKey(const ValueKey('quick-row-editor-not-here')),
      findsOneWidget,
    );
    expect(find.textContaining('Ara başlık'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('note-layout-scope-note')));
    await tester.pump();
    expect(Personalize.noteHasOwnLayout, isTrue);
    final id = UiItem.quickRow('italic');
    await tester.tap(find.byKey(const ValueKey('quick-row-edit-italic')));
    await tester.pump();
    expect(Personalize.current.shows(id), isTrue);
    expect(Personalize.prefs.value.shows(id), isFalse);
    await tester.ensureVisible(
      find.byKey(const ValueKey('note-layout-scope-reset')),
    );
    await tester.tap(find.byKey(const ValueKey('note-layout-scope-reset')));
    await tester.pump();
    expect(Personalize.noteHasOwnLayout, isFalse);
    expect(Personalize.current.shows(id), isFalse);
  });

  testWidgets('liste notunda hızlı satırın ☑ düğmesi görünür ve odaktaki '
      'maddeyi işaretler', (tester) async {
    Personalize.prefs.value = const UiPrefs().withVisible(
      UiItem.quickRow('checkbox'),
      true,
    );
    final repo = CountingNotesRepository();
    await pumpEditor(tester, _list, repo: repo);
    await tester.tap(find.text('süt'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    final box = find.byKey(const ValueKey('quick-row-checkbox'));
    expect(box, findsOneWidget, reason: 'liste notunda sessizce yoktu');
    await tester.tap(box);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    // İşaretli madde işaretliler bloğuna iner (kutusu dolu).
    final checks = tester
        .widgetList<Checkbox>(find.byType(Checkbox, skipOffstage: false))
        .where((c) => c.value ?? false);
    expect(checks, hasLength(1));
    tester.view.resetViewInsets();
    await endEditor(tester);
  });

  testWidgets('⋯ Düzenle: düğme sol ↔ sağ grup arasında taşınır', (
    tester,
  ) async {
    await pumpEditor(tester, _list, size: const Size(1200, 800));
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor-bar-more-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Sağ grup (renkli)'), findsOneWidget);
    final toRight = find.byKey(
      const ValueKey('editor-bar-more-side-editor.bar.format'),
    );
    await tester.ensureVisible(toRight);
    await tester.pumpAndSettle();
    await tester.tap(toRight);
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.barSides.right, contains(UiItem.barFormat));
    final back = find.byKey(
      const ValueKey('editor-bar-more-side-editor.bar.format'),
    );
    await tester.ensureVisible(back);
    await tester.pumpAndSettle();
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(
      Personalize.prefs.value.barSides.right,
      isNot(contains(UiItem.barFormat)),
    );
    expect(tester.takeException(), isNull);
    await endEditor(tester);
  });
}
