import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_share_text.dart';
import 'package:notlar/features/notes/domain/note_table.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/editor_quick_row.dart';
import 'package:notlar/features/notes/presentation/editor/table_page_box.dart';
import 'package:notlar/features/notes/presentation/editor/view_mode_switch.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

import 'support/editor_harness.dart';

/// Kullanıcı istekleri 2026-11-23: hızlı satırın ⋯'si alt panelinki gibi
/// bento ızgara (+ "Hızlı menüyü düzenle"), "Gün ekle" (22/11/2026) ve
/// 2-3-4 sütunlu, satır eklenebilen, hücreleri yazılan TABLO.
Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Attachment _tableAttachment(NoteTable table, {String id = 't1'}) =>
    table.applyTo(
      Attachment(
        id: id,
        kind: AttachmentKind.text,
        fileName: 'Tablo',
        mimeType: 'text/plain',
        createdAt: DateTime(2026, 11, 23),
        width: 1000,
        height: tableHeightUnits(table.rows),
        onPage: true,
        displayWidth: 1,
        x: 0,
        pageY: 120,
      ),
    );

void main() {
  setUp(Personalize.debugReset);
  tearDown(Personalize.debugReset);

  group('NoteTable (model)', () {
    test('boş tablo, hücre, satır ekle/sil, sütun değiştir', () {
      var t = NoteTable.blank(3);
      expect(t.rows, 3);
      expect(t.cells, hasLength(9));
      t = t.withCell(1, 2, 'x');
      expect(t.cell(1, 2), 'x');
      t = t.insertRow(1);
      expect(t.rows, 4);
      expect(t.cell(2, 2), 'x', reason: 'araya giren satır aşağı iter');
      t = t.removeRow(2);
      expect(t.rows, 3);
      expect(t.cells.where((c) => c == 'x'), isEmpty);
      t = t.withCell(0, 2, 'son');
      expect(t.dropsText(2), isTrue);
      expect(t.dropsText(3), isFalse);
      final two = t.withColumns(2);
      expect(two.columns, 2);
      expect(two.cells, hasLength(6));
      expect(two.withColumns(4).cell(0, 3), '');
      // Tek satır silinmez, temizlenir.
      final one = NoteTable(columns: 2, cells: const ['a', 'b']);
      expect(one.removeRow(0).rows, 1);
      expect(one.removeRow(0).cells, ['', '']);
    });

    test('sütun sınırı kayar, en dar oranın altına inmez, eşitlenir', () {
      var t = NoteTable.blank(2);
      expect(t.evenWidths, isTrue);
      t = t.moveBorder(1, 0.2);
      expect(t.widths[0], closeTo(0.7, 1e-9));
      expect(t.widths[1], closeTo(0.3, 1e-9));
      t = t.moveBorder(1, 0.9);
      expect(t.widths[1], closeTo(kTableMinColumnFrac, 1e-9));
      expect(t.evenWidths, isFalse);
      expect(t.evenedWidths().evenWidths, isTrue);
    });

    test('kayıt Firestore uyumlu (iç içe dizi yok) ve gidip gelir', () {
      final t = NoteTable.blank(3)
          .withCell(0, 0, 'Ad')
          .withCell(1, 1, 'a | b')
          .moveBorder(1, 0.1)
          .withHeader(false);
      final map = _tableAttachment(t).toMap();
      final raw = map[kTableExtra] as Map;
      for (final v in raw.values) {
        if (v is List) expect(v.any((e) => e is List), isFalse);
      }
      final back = Attachment.fromMap(map);
      expect(isNoteTable(back), isTrue);
      expect(NoteTable.of(back), t);
      // Metin: Markdown, ayraç satırlı, | kaçışlı.
      expect(back.text.split('\n')[1], '| --- | --- | --- |');
      expect(back.text, contains(r'a \| b'));
    });

    test('paylaşım metninde tablo satırları', () {
      final t = NoteTable.blank(2)
          .withCell(0, 0, 'Ürün')
          .withCell(0, 1, 'Fiyat')
          .withCell(1, 0, 'Süt')
          .withCell(1, 1, '30');
      final note = Note(
        id: 'n',
        type: NoteType.text,
        title: 'Alışveriş',
        attachments: [_tableAttachment(t)],
      );
      final text = noteShareText(note);
      expect(text, contains('Ürün | Fiyat\nSüt | 30'));
    });
  });

  group('TablePageBox', () {
    testWidgets('hücreye dokun = yaz; Enter sonraki hücre, sonda yeni satır', (
      tester,
    ) async {
      var saved = _tableAttachment(NoteTable.blank(2, rows: 1));
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 360,
              height: 400,
              child: TablePageBox(
                attachment: saved,
                onChanged: (a) => setState(() => saved = a),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing, reason: 'açık hücre yok');
      await tester.tap(find.byKey(const ValueKey('note-table-cell-0-0')));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      tester.testTextInput.enterText('Süt');
      await tester.pump(const Duration(seconds: 1));
      expect(NoteTable.of(saved)!.cell(0, 0), 'Süt');
      // Enter → sağdaki hücre.
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      tester.testTextInput.enterText('30');
      // Son hücrede Enter → yeni satır açılır, ilk hücresi yazılır.
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final t = NoteTable.of(saved)!;
      expect(t.rows, 2);
      expect(t.cell(0, 1), '30');
      expect(
        find.byKey(const ValueKey('note-table-field-1-0')),
        findsOneWidget,
      );
      // Boy değişince kutunun oranı da yazılır (yeni satır = daha uzun).
      expect(saved.height!, greaterThan(tableHeightUnits(1)));
    });

    testWidgets('"Satır ekle" ve seçeneklerden sütun sayısı', (tester) async {
      var saved = _tableAttachment(NoteTable.blank(2, rows: 2));
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 360,
              height: 500,
              child: TablePageBox(
                attachment: saved,
                onChanged: (a) => setState(() => saved = a),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('note-table-add-row')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(NoteTable.of(saved)!.rows, 3);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('note-table-options')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('note-table-cols-4')));
      await tester.pumpAndSettle();
      expect(NoteTable.of(saved)!.columns, 4);
    });

    testWidgets('Gün ekle açık hücreye yazar', (tester) async {
      var saved = _tableAttachment(NoteTable.blank(2, rows: 1));
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 360,
              height: 300,
              child: TablePageBox(
                attachment: saved,
                onChanged: (a) => setState(() => saved = a),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('note-table-cell-0-1')));
      await tester.pump();
      expect(NoteTableFocus.insert('22/11/2026'), isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(NoteTable.of(saved)!.cell(0, 1), '22/11/2026');
    });
  });

  group('hızlı satır ⋯', () {
    testWidgets('gizli düğmeler bento ızgarada, en altta düzenle; Gün ekle '
        'ızgaranın başında', (tester) async {
      var day = 0, italic = 0;
      await tester.pumpWidget(
        _app(
          EditorQuickRow(
            onBold: () {},
            onBullet: () {},
            onCheckbox: null,
            onHeading: () {},
            onPhoto: () {},
            onFile: () {},
            onPen: null,
            onPenSettings: null,
            onReminder: () {},
            onItalic: () => italic++,
            onDay: () => day++,
            onTable: () {},
          ),
        ),
      );
      // Satır telefonda dolu: Gün ekle ve Tablo satırda değil, ⋯'nin başında.
      expect(find.byKey(const ValueKey('quick-row-day')), findsNothing);
      expect(find.byKey(const ValueKey('quick-row-italic')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('quick-row-more')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quick-row-more-0')),
          matching: find.text('Gün ekle'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Gün ekle'));
      await tester.pumpAndSettle();
      expect(day, 1);
      await tester.tap(find.byKey(const ValueKey('quick-row-more')));
      await tester.pumpAndSettle();
      // İki sütunlu karolar (alt panelin ⋯'siyle aynı) + düzenle satırı.
      expect(find.byKey(const ValueKey('quick-row-more-0')), findsOneWidget);
      expect(find.text('İtalik'), findsOneWidget);
      expect(find.text('Tablo'), findsOneWidget);
      expect(find.text('Hızlı menüyü düzenle'), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-row-customize')), findsOneWidget);
      await tester.tap(find.text('İtalik'));
      await tester.pumpAndSettle();
      expect(italic, 1);
      // Düzenle → hızlı menü düzenleyicisi.
      await tester.tap(find.byKey(const ValueKey('quick-row-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-row-customize')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('editörde', () {
    testWidgets('Gün ekle gövdeye bugünün tarihini gg/aa/yyyy yazar', (
      tester,
    ) async {
      final repo = CountingNotesRepository();
      const note = Note(id: 'n', type: NoteType.text, title: 'T', body: 'yazı');
      await pumpEditor(tester, note, repo: repo);
      await tester.tap(find.widgetWithText(TextField, 'yazı').first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      // ⋯ ızgarası odağı alır; tarih gövdenin imlecine yine girer.
      await tester.tap(find.byKey(const ValueKey('quick-row-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gün ekle'));
      await tester.pump(const Duration(seconds: 3));
      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
      expect(repo.lastSaved!.body, contains(today));
      expect(today, matches(RegExp(r'^\d\d/\d\d/\d{4}$')));
      tester.view.resetViewInsets();
      await endEditor(tester);
    });

    testWidgets('sayfadaki tablo çizilir, hücresi yazılır ve kaydedilir', (
      tester,
    ) async {
      final repo = CountingNotesRepository();
      final note = Note(
        id: 'n',
        type: NoteType.text,
        title: 'T',
        body: 'yazı',
        attachments: [
          _tableAttachment(NoteTable.blank(3).withCell(0, 0, 'Ad')),
        ],
      );
      await pumpEditor(tester, note, repo: repo);
      expect(find.text('Ad'), findsOneWidget);
      final cell = find.byKey(const ValueKey('note-table-cell-1-1'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pump(const Duration(milliseconds: 300));
      tester.testTextInput.enterText('Mehmet');
      await tester.pump(const Duration(seconds: 4));
      final saved = repo.lastSaved!.attachments.single;
      expect(NoteTable.of(saved)!.cell(1, 1), 'Mehmet');
      expect(saved.text, contains('Mehmet'));
      // Tablo üste sabitlenemez / şeride inemez: görünüm anahtarı yok.
      await endEditor(tester);
    });
  });

  testWidgets('hücreye basılı tutup sürüklemek tabloyu taşır', (tester) async {
    final repo = CountingNotesRepository();
    final note = Note(
      id: 'n',
      type: NoteType.text,
      title: 'T',
      body: 'yazı',
      attachments: [_tableAttachment(NoteTable.blank(2))],
    );
    await pumpEditor(tester, note, repo: repo);
    final cell = find.byKey(const ValueKey('note-table-cell-0-0'));
    final start = tester.getCenter(cell);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 700));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(TextField), findsWidgets);
    final moved = repo.lastSaved!.attachments.single;
    expect(moved.pageY, greaterThan(120 + 100));
    expect(NoteTable.of(moved), NoteTable.blank(2), reason: 'hücre açılmadı');
    await endEditor(tester);
  });

  testWidgets('alt panelin ⋯ ızgarasında Gün ekle ve Tablo; tablo eklenir', (
    tester,
  ) async {
    final repo = CountingNotesRepository();
    const note = Note(id: 'n', type: NoteType.text, title: 'T', body: 'yazı');
    await pumpEditor(tester, note, repo: repo);
    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();
    expect(find.text('Gün ekle'), findsOneWidget);
    expect(find.text('Tablo'), findsOneWidget);
    await tester.tap(find.text('Tablo'));
    await tester.pumpAndSettle();
    // Sütun seçici açılır; 3 sütun → tablo sayfada, ilk hücre yazılır.
    await tester.tap(find.byKey(const ValueKey('table-pick-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('note-table-field-0-0')), findsOneWidget);
    tester.testTextInput.enterText('Ad');
    await tester.pump(const Duration(seconds: 3));
    final table = repo.lastSaved!.attachments.single;
    expect(NoteTable.of(table)!.columns, 3);
    expect(NoteTable.of(table)!.cell(0, 0), 'Ad');
    expect(table.floatsOnPage, isTrue);
    await endEditor(tester);
  });

  test('tablo yalnız sayfada (sabit/ek görünümü yok)', () {
    final a = _tableAttachment(NoteTable.blank(2));
    expect(availableViews(a), {AttachmentView.floating});
  });

  test('alt çubukta Gün ekle ve Tablo eklenebilir (varsayılan gizli)', () {
    expect(
      UiItem.barLeftDefault,
      containsAll([UiItem.barDay, UiItem.barTable]),
    );
    expect(UiItem.isOptIn(UiItem.barDay), isTrue);
    expect(UiItem.isOptIn(UiItem.barTable), isTrue);
    expect(UiItem.isOptIn(UiItem.quickRow('day')), isTrue);
    expect(UiItem.isOptIn(UiItem.quickRow('table')), isTrue);
  });
}
