import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/utils/feature_search.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/notes/data/table_export.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_table.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/quick_row_editor.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

import 'support/editor_harness.dart';

/// Kullanıcı istekleri 2026-11-23 (akşam): tabloda biçim paneli hücre hücre
/// çalışsın + Sola/Ortala/Sağa; tablo maddeleri bölmesin/üstüne binmesin;
/// hesap makinesi vb. hızlı panelde; menülerde işlev sözlüklü iç arama.
Attachment _tableAttachment(NoteTable table) => table.applyTo(
  Attachment(
    id: 't1',
    kind: AttachmentKind.text,
    fileName: 'Tablo',
    mimeType: 'text/plain',
    createdAt: DateTime(2026, 11, 23),
    width: 1000,
    height: tableHeightUnitsForTest(table.rows),
    onPage: true,
    displayWidth: 1,
    x: 0,
    pageY: 120,
  ),
);

int tableHeightUnitsForTest(int rows) => (1000 * (rows * 33 + 35) / 340).round();

void main() {
  setUp(Personalize.debugReset);
  tearDown(Personalize.debugReset);
  group('blok bant', blockFloatTests);

  group('tablo hücre hizası (model)', () {
    test('hiza satır/sütun işlerinde hücresiyle kayar, kayda girer', () {
      var t = NoteTable.blank(2, rows: 2);
      expect(t.aligns, '', reason: 'hepsi sola = kayda yazılmaz');
      expect(t.toMap().containsKey('align'), isFalse);
      t = t.withAlign(1, 1, CellAlign.center);
      expect(t.alignOf(1, 1), CellAlign.center);
      expect(t.alignOf(0, 0), CellAlign.start);
      t = t.insertRow(0);
      expect(t.alignOf(2, 1), CellAlign.center, reason: 'üste satır eklendi');
      t = t.removeRow(0);
      expect(t.alignOf(1, 1), CellAlign.center);
      t = t.withColumns(3);
      expect(t.alignOf(1, 1), CellAlign.center);
      expect(t.alignOf(1, 2), CellAlign.start);
      t = t.withAlign(0, 2, CellAlign.end).withRows(1);
      expect(t.alignOf(0, 2), CellAlign.end);
      final back = NoteTable.of(t.applyTo(_tableAttachment(t)))!;
      expect(back, t);
      expect(back.alignOf(0, 2), CellAlign.end);
      expect(t.withAlign(0, 2, CellAlign.start).aligns, '');
    });

    test('biçimli hücre: Markdown, paylaşım ve Word işaretsiz', () {
      final t = NoteTable.blank(2, rows: 1)
          .withCell(0, 0, '**Ad**')
          .withAlign(0, 1, CellAlign.center)
          .withCell(0, 1, 'x');
      expect(t.plainCell(0, 0), 'Ad');
      expect(t.toMarkdown(), isNot(contains('**')));
      expect(t.toShareText(), 'Ad | x');
      final xml = TableExport.docxTableXml(t);
      expect(xml, contains('<w:jc w:val="center"/>'));
      expect(xml, isNot(contains('**')));
      final doc = ZipDecoder().decodeBytes(TableExport.docx(t));
      final body = utf8.decode(
        doc.files.firstWhere((f) => f.name == 'word/document.xml').content
            as List<int>,
      );
      expect(body, contains('Ad'));
    });
  });

  group('işlev sözlüklü arama', () {
    bool hit(String q, String id, String label) =>
        featureMatches(q, id: id, label: label);

    test('ad, işlev ve diğer dillerle bulunur', () {
      expect(hit('hes', 'calculator', 'Hesap makinesi'), isTrue);
      expect(hit('topla', 'calculator', 'Hesap makinesi'), isTrue);
      expect(hit('calculator', 'calculator', 'Hesap makinesi'), isTrue);
      expect(hit('rechner', 'calculator', 'Hesap makinesi'), isTrue);
      expect(hit('calculadora', 'calculator', 'Hesap makinesi'), isTrue);
      expect(hit('калькулятор', 'calculator', 'Hesap makinesi'), isTrue);
      // Kimliği bilinmese de adındaki çapa sözcükle bağlanır.
      expect(hit('kdv', 'x-unknown', 'Hesap makinesi'), isTrue);
      // Aksan/harf duyarsız + tek harf yazım hatası.
      expect(hit('paylas', 'share', 'Paylaş'), isTrue);
      expect(hit('whatsapp', 'share', 'Paylaş'), isTrue);
      expect(hit('makinasi', 'calculator', 'Hesap makinesi'), isTrue);
      expect(hit('çöp', 'delete', 'Sil'), isTrue);
      expect(hit('password', 'lock', 'Kilitle'), isTrue);
      expect(hit('kelime sayısı', 'stats', 'Not istatistikleri'), isTrue);
      expect(hit('read aloud', 'listen', 'Sesli dinle'), isTrue);
      // İlgisiz sözcük eşleşmez.
      expect(hit('zzqx', 'calculator', 'Hesap makinesi'), isFalse);
      expect(hit('kilit', 'calculator', 'Hesap makinesi'), isFalse);
    });

    test('adın başı sözlükten önce gelir', () {
      final label = featureMatchScore('sil', id: 'delete', label: 'Sil');
      final dict = featureMatchScore('sil', id: 'x', label: 'Çöp kutusu');
      expect(label, greaterThan(dict));
    });

    testWidgets('menü levhasında arama süzer, Enter ilkini seçer', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => picked = await showActionMenuSheet(
                  context,
                  const ActionMenu(
                    title: 'Notlar',
                    quick: [
                      MenuAction('share', 'Paylaş', Icons.share),
                      MenuAction('star', 'Yıldızla', Icons.star),
                    ],
                    sections: [
                      MenuSection('Araçlar', [
                        MenuAction('calculator', 'Hesap makinesi', Icons.calculate),
                        MenuAction('listen', 'Sesli dinle', Icons.headphones),
                        MenuAction('stats', 'Not istatistikleri', Icons.insights),
                      ]),
                      MenuSection('Koruma', [
                        MenuAction('lock', 'Kilitle', Icons.lock),
                        MenuAction('archive', 'Arşivle', Icons.archive),
                        MenuAction('history', 'Sürüm geçmişi', Icons.history),
                      ]),
                    ],
                    danger: MenuAction('delete', 'Sil', Icons.delete),
                  ),
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      // Başlıklı menüde arama başlıktaki 🔍'de (levha uzamaz).
      expect(find.byKey(const ValueKey('menu-search')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('menu-search-open')));
      await tester.pump();
      expect(find.byKey(const ValueKey('menu-search')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('menu-search')), 'topla');
      await tester.pump();
      expect(find.text('Hesap makinesi'), findsOneWidget);
      expect(find.text('Kilitle'), findsNothing);
      expect(find.text('Sesli dinle'), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('menu-search')), 'qqzz');
      await tester.pump();
      expect(find.byKey(const ValueKey('menu-search-empty')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('menu-search')),
        'password',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(picked, 'lock');
    });
  });

  test('hızlı satır kataloğunda araçlar; varsayılan gizli', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final keys = {for (final e in quickRowCatalog(l10n)) e.key};
    for (final k in ['calculator', 'find', 'listen', 'stats']) {
      expect(keys, contains(k));
      expect(Personalize.current.storedShows(UiItem.quickRow(k)), isFalse);
    }
  });

  test('tam genişlik kutu BLOK bant, dar kutu değil', () {
    // Blok bant sameFloatList'te ayrı sayılır (değişince yeniden dizilir).
    const a = FloatBox(top: 0, left: 0, right: 10, height: 10);
    const b = FloatBox(top: 0, left: 0, right: 10, height: 10, block: true);
    expect(sameFloatList([a], [b]), isFalse);
  });

  testWidgets('tabloda biçim paneli hücreye yazar; hiza hücre hücre', (
    tester,
  ) async {
    final repo = CountingNotesRepository();
    final note = Note(
      id: 'n',
      type: NoteType.text,
      title: 'T',
      body: 'yazı',
      attachments: [
        _tableAttachment(NoteTable.blank(2).withCell(1, 0, 'abc')),
      ],
    );
    await pumpEditor(tester, note, repo: repo);
    final cell = find.byKey(const ValueKey('note-table-cell-1-0'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Biçim'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FormatBar), findsOneWidget);
    // Hücre hedefken panelde hiza düğmeleri var.
    final center = find.byKey(const ValueKey('format-align-center'));
    expect(center, findsOneWidget);
    await tester.tap(center);
    await tester.pump(const Duration(milliseconds: 300));
    // Tümünü kalın yap (kapsam: Tümü).
    for (var i = 0; i < 4 && find.text('Tümü').evaluate().isEmpty; i++) {
      await tester.tap(find.byKey(const ValueKey('format-scope-menu')));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.byKey(const ValueKey('format-bold')));
    await tester.pump(const Duration(seconds: 2));
    final t = NoteTable.of(repo.lastSaved!.attachments.single)!;
    expect(t.alignOf(1, 0), CellAlign.center);
    expect(t.alignOf(0, 0), CellAlign.start, reason: 'yalnız o hücre');
    expect(t.cell(1, 0), contains('**'), reason: 'kalın işareti hücrede');
    expect(t.plainCell(1, 0), 'abc');
    await endEditor(tester);
  });
}

/// Liste satırları + yüzen BLOK bant (tam genişlik tablo): madde bölünmez,
/// paket özeti de altına iner; alttaki satırlar fazladan itilmez.
void blockFloatTests() {
  final pageKey = GlobalKey();

  Future<void> pumpList(
    WidgetTester tester,
    List<NoteItem> items,
    List<FloatBox> floats,
  ) async {
    var current = items;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: KeyedSubtree(
                key: pageKey,
                child: ItemsEditor(
                  items: current,
                  onChanged: (next) => setState(() => current = next),
                  showCheckboxes: false,
                  shrinkWrap: true,
                  floats: floats,
                  pageBox: () {
                    final box = pageKey.currentContext?.findRenderObject();
                    return box is RenderBox && box.hasSize ? box : null;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final items = [
    NoteItem(id: 'a', text: 'Birinci'),
    NoteItem(
      id: 'b',
      text: 'Ikinci madde uzun bir yazi ve iki ya da uc satira kirilacak '
          'kadar uzun olmali ki bolunme gorulsun',
    ),
    NoteItem(id: 'c', text: 'Ucuncu'),
    NoteItem(id: 'p1', text: 'Paketli bir', package: 'g'),
    NoteItem(id: 'p2', text: 'Paketli iki', package: 'g'),
    NoteItem(id: 'd', text: 'Dorduncu'),
  ];
  Finder text(String s) => find.textContaining(s, findRichText: true);

  testWidgets('blok bant maddeyi bölmez, bütünüyle altına iter', (
    tester,
  ) async {
    await pumpList(tester, items, const []);
    final page = tester.getTopLeft(find.byKey(pageKey));
    final b0 = tester.getRect(text('Ikinci')).shift(-page);
    final c0 = tester.getRect(text('Ucuncu')).shift(-page);
    // Bant maddenin İKİNCİ satırında başlar (eski davranış: ilk satır
    // üstte kalır, kalanı altta — madde bölünürdü).
    final band = FloatBox(
      top: b0.top + 22,
      left: -12,
      right: 900,
      height: 100,
      block: true,
    );
    await pumpList(tester, items, [band]);
    final b1 = tester.getRect(text('Ikinci')).shift(-page);
    final c1 = tester.getRect(text('Ucuncu')).shift(-page);
    expect(b1.top, greaterThanOrEqualTo(band.bottom - 1), reason: 'bölünmedi');
    // Alttaki madde yalnız üstündekiyle birlikte kayar (fazladan itme yok).
    expect(
      (c1.top - b1.bottom) - (c0.top - b0.bottom),
      closeTo(0, 2),
    );
  });

  testWidgets('kapalı paket özeti blok bandın altına iner', (tester) async {
    await pumpList(tester, items, const []);
    final page = tester.getTopLeft(find.byKey(pageKey));
    final pill = find.byKey(const ValueKey('note-package-pill'));
    final p0 = tester.getRect(pill).shift(-page);
    final band = FloatBox(
      top: p0.top + 10,
      left: -12,
      right: 900,
      height: 80,
      block: true,
    );
    await pumpList(tester, items, [band]);
    final p1 = tester.getRect(pill).shift(-page);
    expect(p1.top, greaterThanOrEqualTo(band.bottom - 1));
  });
}
