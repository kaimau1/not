import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note_table.dart';
import 'package:notlar/features/notes/presentation/editor/table_page_box.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child, {double width = 800}) => MaterialApp(
  locale: const Locale('tr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

Attachment _sampleAttachment() {
  final t = NoteTable(
    columns: 3,
    cells: const [
      'Ad',
      'Şehir',
      'Puan',
      'Ali',
      'Çankaya',
      '10',
      'Veli',
      'Adana',
      '2',
    ],
  );
  return newNoteTable(
    name: 'Tablo',
    height: tableHeightUnits(3),
    columns: 3,
  ).copyWith(extras: {kTableExtra: t.toMap()}, text: t.toMarkdown());
}

void main() {
  group('NoteTable model enhancements', () {
    test('striped roundtrips through toMap and affects equality', () {
      final base = NoteTable.blank(2);
      expect(base.striped, isFalse);
      final zebra = base.withStriped(true);
      expect(zebra.striped, isTrue);
      expect(zebra == base, isFalse);
      final rebuilt = NoteTable.of(
        zebra.applyTo(newNoteTable(name: 'T', height: 500)),
      );
      expect(rebuilt, zebra);
      expect(rebuilt!.striped, isTrue);
    });

    test(
      'insertColAt and deleteColAt preserve aligns and keep >= 2 columns',
      () {
        var t = NoteTable(
          columns: 2,
          cells: const ['A', 'B', '1', '2'],
          aligns: 'crll',
        );
        t = t.insertColAt(1);
        expect(t.columns, 3);
        expect(t.cell(0, 0), 'A');
        expect(t.cell(0, 1), '');
        expect(t.cell(0, 2), 'B');
        expect(t.alignOf(0, 0), CellAlign.center);
        expect(t.alignOf(0, 2), CellAlign.end);
        expect(t.widths.reduce((a, b) => a + b), closeTo(1.0, 0.001));

        t = t.deleteColAt(1);
        expect(t.columns, 2);
        expect(t.cell(0, 1), 'B');
        // Minimum 2 columns retained.
        expect(t.deleteColAt(0).columns, 2);
      },
    );

    test('sortByColumn keeps header and sorts Turkish strings and numbers', () {
      final t = NoteTable(
        columns: 3,
        cells: const [
          'Ad', 'Şehir', 'Puan', //
          'R1', 'Şişli', '10', //
          'R2', '', '', //
          'R3', 'Çankaya', '2', //
          'R4', 'Adana', '1,5', //
        ],
      );
      final byCity = t.sortByColumn(1);
      expect(byCity.cell(0, 1), 'Şehir');
      expect(byCity.cell(1, 1), 'Adana');
      expect(byCity.cell(2, 1), 'Çankaya');
      expect(byCity.cell(3, 1), 'Şişli');
      expect(byCity.cell(4, 1), '');

      final byScoreDesc = t.sortByColumn(2, ascending: false);
      expect(byScoreDesc.cell(1, 2), '10');
      expect(byScoreDesc.cell(2, 2), '2');
      expect(byScoreDesc.cell(3, 2), '1,5');
      expect(byScoreDesc.cell(4, 2), '');
    });

    test(
      'toCsv and fromDelimited handle TSV, quoted CSV, and reject plain text',
      () {
        final t = NoteTable(
          columns: 2,
          cells: const ['Başlık, 1', 'Değer "A"', 'satır1\nsatır2', '42'],
        );
        final csv = t.toCsv();
        final reparsed = NoteTable.fromDelimited(csv);
        expect(reparsed, isNotNull);
        expect(reparsed!.columns, 2);
        expect(reparsed.rows, 2);
        expect(reparsed.cell(0, 0), 'Başlık, 1');
        expect(reparsed.cell(0, 1), 'Değer "A"');
        expect(reparsed.cell(1, 0), 'satır1\nsatır2');

        final tsv = NoteTable.fromDelimited('Ad\tPuan\nAyşe\t95\nMehmet\t88');
        expect(tsv, isNotNull);
        expect(tsv!.columns, 2);
        expect(tsv.rows, 3);
        expect(tsv.cell(1, 0), 'Ayşe');

        final semi = NoteTable.fromDelimited('Ürün;Fiyat\nDefter;120');
        expect(semi?.cell(1, 1), '120');

        expect(
          NoteTable.fromDelimited('yalnızca düz metin\nikinci satır'),
          isNull,
        );
      },
    );
  });

  group('TablePageBox layout and interaction', () {
    testWidgets('wide container renders 1:1 without FittedBox upscale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(TablePageBox(attachment: _sampleAttachment(), onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(TablePageBox),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      final size = tester.getSize(find.byType(TablePageBox));
      expect(size.width, 800);
      // Native 1:1 height (no ~2.35x Web upscale).
      expect(size.height, lessThan(220));
    });

    testWidgets('narrow container scales down smoothly without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TablePageBox(attachment: _sampleAttachment(), onChanged: (_) {}),
          width: 240,
        ),
      );
      await tester.pumpAndSettle();

      final fitted = tester.widget<FittedBox>(
        find.descendant(
          of: find.byType(TablePageBox),
          matching: find.byType(FittedBox),
        ),
      );
      expect(fitted.fit, BoxFit.scaleDown);
      expect(tester.getSize(find.byType(TablePageBox)).width, 240);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'onAspect fires when width widens even if row height is unchanged',
      (tester) async {
        final aspects = <double>[];
        final att = _sampleAttachment();
        await tester.pumpWidget(
          _wrap(
            TablePageBox(
              attachment: att,
              onChanged: (_) {},
              onAspect: aspects.add,
            ),
            width: 360,
          ),
        );
        await tester.pumpAndSettle();
        expect(aspects, isNotEmpty);
        final narrowAspect = aspects.last;

        await tester.pumpWidget(
          _wrap(
            TablePageBox(
              attachment: att,
              onChanged: (_) {},
              onAspect: aspects.add,
            ),
            width: 720,
          ),
        );
        await tester.pumpAndSettle();
        expect(aspects.last, greaterThan(narrowAspect * 1.5));
      },
    );

    testWidgets('Tab, Shift+Tab, and Escape navigate table cells cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TablePageBox(attachment: _sampleAttachment(), onChanged: (_) {}),
          width: 600,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('note-table-cell-0-0')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('note-table-field-0-0')),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('note-table-field-0-1')),
        findsOneWidget,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('note-table-field-0-0')),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('note-table-field-0-0')), findsNothing);
    });
  });
}
