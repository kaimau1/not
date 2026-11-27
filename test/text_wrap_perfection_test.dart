import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart' show RichFormat;
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart'
    show hintPlacement;
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const style = TextStyle(fontSize: 14, height: 1.4);
  const richTheme = RichTextTheme(
    palette: [Colors.red, Colors.blue, Colors.green],
    markerColor: Colors.grey,
  );

  void expectNoOverlap(
    WrapPlan plan,
    List<FloatBox> floats,
    double columnWidth, {
    TextDirection direction = TextDirection.ltr,
    RichTextTheme? rich,
  }) {
    final painter =
        TextPainter(
          textDirection: direction,
          strutStyle: wrapStrutStyle(style),
          text: buildWrapSpan(
            plan.display,
            plan.widths,
            style,
            rich: rich,
            linkColor: Colors.blue,
          ),
        )..setPlaceholderDimensions([
          for (final w in plan.widths)
            PlaceholderDimensions(
              size: Size(w, wrapAnchorHeight(style)),
              alignment: PlaceholderAlignment.middle,
            ),
        ]);
    painter.layout(maxWidth: columnWidth);
    for (var i = 0; i < plan.display.length; i++) {
      final ch = plan.display[i];
      if (ch == kWrapAnchorChar || ch == kWrapGlueChar || ch.trim().isEmpty) {
        continue;
      }
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      for (final box in boxes) {
        if (box.right - box.left < 0.2 || box.bottom - box.top < 0.2) {
          continue;
        }
        for (final f in floats) {
          final vertical = f.top < box.bottom && box.top < f.bottom;
          final horizontal = box.right > f.left + 1 && box.left < f.right - 1;
          expect(
            vertical && horizontal,
            isFalse,
            reason:
                '"$ch" (${box.left.toStringAsFixed(1)}..'
                '${box.right.toStringAsFixed(1)} @ '
                '${box.top.toStringAsFixed(1)}) gorsel bandina girdi',
          );
        }
      }
    }
    painter.dispose();
  }

  group('biçimli metin + bağlantı + etiket sarması', () {
    test('sol ve sağ görselde çok satırlı biçimler ham işarete bozulmaz', () {
      const logical =
          '**birinci kalin sozcuk ikinci ucuncu dorduncu besinci** '
          '==2:vurgulu uzun cumle devami== '
          '%%1:renkli metin burada suruyor%% '
          'https://example.com/uzun/bir/baglanti/yolu '
          '📎 belge.pdf ve sonunda _italik uzun cumle_ ~alti cizili yazi~';
      for (final floats in const [
        [FloatBox(top: 0, left: 0, right: 120, height: 120)],
        [FloatBox(top: 0, left: 180, right: 300, height: 120)],
        [
          FloatBox(top: 0, left: 0, right: 90, height: 50),
          FloatBox(top: 60, left: 200, right: 300, height: 60),
        ],
      ]) {
        final plan = planTextWrap(
          logical: logical,
          style: style,
          columnWidth: 300,
          floats: floats,
          rich: richTheme,
        );
        expect(plan.widths, isNotEmpty);
        final span = buildWrapSpan(
          plan.display,
          plan.widths,
          style,
          linkColor: Colors.blue,
          rich: richTheme,
          attachmentNames: const ['belge.pdf'],
          videoTimestamps: true,
        );
        expect(
          span.toPlainText(includeSemanticsLabels: false),
          plan.display,
          reason: 'span düz metni tam olarak display ile eşleşmeli',
        );

        var boldPieces = 0;
        var visibleMarkerStars = false;
        var highlightPieces = 0;
        var coloredPieces = 0;
        var linkPieces = 0;
        var italicPieces = 0;
        var underlinePieces = 0;
        span.visitChildren((child) {
          if (child is TextSpan && child.text != null) {
            final t = child.text!;
            final st = child.style;
            if (t == '**' && (st?.fontSize ?? 14) > 1) {
              visibleMarkerStars = true;
            }
            if (st?.fontWeight == FontWeight.w700 &&
                (t.contains('birinci') ||
                    t.contains('besinci') ||
                    t.contains('dorduncu'))) {
              boldPieces++;
            }
            if (st?.backgroundColor != null &&
                st!.backgroundColor!.a > 0 &&
                (t.contains('vurgulu') || t.contains('devami'))) {
              highlightPieces++;
            }
            if (st?.color == Colors.red &&
                (t.contains('renkli') || t.contains('suruyor'))) {
              coloredPieces++;
            }
            if (st?.color == Colors.blue && t.contains('example.com')) {
              linkPieces++;
            }
            if (st?.fontStyle == FontStyle.italic && t.contains('italik')) {
              italicPieces++;
            }
            if (st?.decoration == TextDecoration.underline &&
                t.contains('cizili')) {
              underlinePieces++;
            }
          }
          return true;
        });
        expect(visibleMarkerStars, isFalse);
        expect(boldPieces, greaterThanOrEqualTo(2));
        expect(highlightPieces, greaterThan(0));
        expect(coloredPieces, greaterThan(0));
        expect(linkPieces, greaterThan(0));
        expect(italicPieces, greaterThan(0));
        expect(underlinePieces, greaterThan(0));
        expectNoOverlap(plan, floats, 300, rich: richTheme);
      }
    });
  });

  group('sağ kenar, iki yanlı bant ve satır sonu Enter', () {
    test('eğik çizgili/tireli uzun parça sağ görselin üstüne binmez', () {
      const token = 'NLDESB/270726/0050/01-uzun-ek-parca';
      const floats = [FloatBox(top: 0, left: 170, right: 300, height: 80)];
      final plan = planTextWrap(
        logical: token,
        style: style,
        columnWidth: 300,
        floats: floats,
      );
      expect(stripWrapAnchors(plan.display), token);
      expectNoOverlap(plan, floats, 300);
    });

    test(
      'aynı satırda sol ve sağ iki dar görsel arası daralırsa satır boşalır',
      () {
        const floats = [
          FloatBox(top: 0, left: 0, right: 110, height: 60),
          FloatBox(top: 0, left: 200, right: 300, height: 60),
        ];
        const logical = 'uzunbirlesikkelime burada devam ediyor ve akiyor';
        final plan = planTextWrap(
          logical: logical,
          style: style,
          columnWidth: 300,
          floats: floats,
        );
        expect(stripWrapAnchors(plan.display), logical);
        expectNoOverlap(plan, floats, 300);
      },
    );

    test('üst satırın sonunda Enter ile tam genişlik görselin bandına inince imleç altta kalır', () {
      const columnWidth = 300.0;
      const band = FloatBox(top: 25, left: 0, right: columnWidth, height: 100);
      const logical = 'ust satir\n';
      final plan = planTextWrap(
        logical: logical,
        style: style,
        columnWidth: columnWidth,
        floats: const [band],
      );
      expect(stripWrapAnchors(plan.display), logical);
      final painter =
          TextPainter(
            textDirection: TextDirection.ltr,
            strutStyle: wrapStrutStyle(style),
            text: buildWrapSpan(plan.display, plan.widths, style),
          )..setPlaceholderDimensions([
            for (final w in plan.widths)
              PlaceholderDimensions(
                size: Size(w, wrapAnchorHeight(style)),
                alignment: PlaceholderAlignment.middle,
              ),
          ]);
      painter.layout(maxWidth: columnWidth);
      final caret = painter.getOffsetForCaret(
        TextPosition(offset: wrapToDisplayOffset(plan.display, logical.length)),
        Rect.zero,
      );
      painter.dispose();
      expect(caret.dy, greaterThanOrEqualTo(band.bottom));
      expect(caret.dx, lessThan(4));
    });
  });

  group('denetleyici düzenleme: ileri silme ve bekleyen biçim', () {
    test('çapa önünden ileri silme sağdaki karakteri siler', () {
      final c = WrapTextController()
        ..updateLayout(
          floats: const [FloatBox(top: 0, left: 170, right: 300, height: 80)],
          style: style,
          columnWidth: 300,
        );
      c.text = 'birinci ikinci ucuncu dorduncu';
      final anchorAt = c.text.indexOf(kWrapAnchorChar);
      expect(anchorAt, greaterThan(1));
      // İmleci birleştirici/çapanın hemen önüne koy.
      final caretPos = anchorAt - 1;
      c.selection = TextSelection.collapsed(offset: caretPos);
      final beforeLogical = c.logicalText;
      final logicalAt = wrapToLogicalOffset(c.text, caretPos);
      // İleri silme (Delete) birleştiriciyi (U+2060) siler, imleç yerinde kalır.
      c.value = TextEditingValue(
        text: c.text.replaceRange(caretPos, caretPos + 1, ''),
        selection: TextSelection.collapsed(offset: caretPos),
      );
      expect(
        c.logicalText,
        beforeLogical.replaceRange(logicalAt, logicalAt + 1, ''),
      );
    });

    test(
      'görsel yanında kalın yazım açıkken satır sarılınca kalın korunur',
      () {
        final c = WrapTextController()
          ..richTheme = richTheme
          ..updateLayout(
            floats: const [FloatBox(top: 0, left: 0, right: 120, height: 120)],
            style: style,
            columnWidth: 300,
          );
        c.text = '';
        final startCaret = wrapToDisplayOffset(c.text, 0);
        c.selection = TextSelection.collapsed(offset: startCaret);
        c.togglePendingFormat(RichFormat.bold, null);

        for (final ch in 'kalin metin gorselin yaninda sariliyor'.split('')) {
          final cur = c.selection.baseOffset;
          c.value = TextEditingValue(
            text: c.text.replaceRange(cur, cur, ch),
            selection: TextSelection.collapsed(offset: cur + 1),
          );
        }
        expect(c.hasPendingFormat, isTrue);
        c.flushPendingFormat(caretOutside: true);
        expect(c.logicalText, '**kalin metin gorselin yaninda sariliyor**');
        expect(c.logicalText.contains(kWrapAnchorChar), isFalse);
      },
    );
  });

  group('ipucu ve WrapFieldMeasure', () {
    test('üst üste iki görselde üstteki tam, alttaki dar ise ipucu alttakinin yanına oturur', () {
      const columnWidth = 300.0;
      const lineHeight = 20.0;
      const floats = [
        FloatBox(top: 0, left: 0, right: columnWidth, height: 40),
        FloatBox(top: 40, left: 0, right: 120, height: 60),
      ];
      final place = hintPlacement(floats, 0, lineHeight, columnWidth);
      expect(place.top, 40.0);
      expect(place.left, 120.0);
    });

    test(
      'RTL yönde fiziksel sağdaki görsel ipucunu mantıksal başlangıçtan iter',
      () {
        const columnWidth = 300.0;
        const lineHeight = 20.0;
        const rightFloat = FloatBox(top: 0, left: 180, right: 300, height: 60);
        final place = hintPlacement(
          const [rightFloat],
          0,
          lineHeight,
          columnWidth,
          direction: TextDirection.rtl,
        );
        expect(place.top, 0.0);
        expect(place.left, 120.0);
      },
    );

    testWidgets('sağ dışındaki görsel sol alana sahte sarma eklemez', (
      tester,
    ) async {
      final pageKey = GlobalKey();
      final controller = WrapTextController(text: 'soldaki alan metni');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyedSubtree(
              key: pageKey,
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: WrapFieldMeasure(
                      controller: controller,
                      style: style,
                      floats: const [
                        FloatBox(top: 0, left: 240, right: 380, height: 100),
                      ],
                      pageBox: () {
                        final b = pageKey.currentContext?.findRenderObject();
                        return b is RenderBox && b.hasSize ? b : null;
                      },
                      child: TextField(controller: controller, style: style),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.isPlain, isTrue);
    });
  });

  group('ItemsEditor listelerde gelişmiş sarma', () {
    final pageKey = GlobalKey();

    Future<void> pumpList(
      WidgetTester tester,
      List<NoteItem> items,
      List<FloatBox> floats, {
      int columns = 1,
      bool checks = true,
    }) async {
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
                    columns: columns,
                    onChanged: (next) => setState(() => current = next),
                    showCheckboxes: checks,
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

    testWidgets(
      'art arda dizili iki blok görsel maddeyi ikisinin de altına iter',
      (tester) async {
        final items = [NoteItem(id: 'a', text: 'Ilk madde')];
        await pumpList(tester, items, const [
          FloatBox(top: 0, left: 0, right: 800, height: 60, block: true),
          FloatBox(top: 60, left: 0, right: 800, height: 70, block: true),
        ]);
        final pageTop = tester.getTopLeft(find.byKey(pageKey)).dy;
        final fieldTop =
            tester.getTopLeft(find.byType(TextField).first).dy - pageTop;
        expect(fieldTop, greaterThanOrEqualTo(130.0));
      },
    );

    testWidgets('iki sütunlu listede sol sütundaki kayma sağ sütunu itmez', (
      tester,
    ) async {
      final items = [
        NoteItem(id: 'a', text: 'Sol bir'),
        NoteItem(id: 'b', text: 'Sol iki'),
        NoteItem(id: 'c', text: 'Sag bir'),
        NoteItem(id: 'd', text: 'Sag iki'),
      ];
      await pumpList(tester, items, const [
        FloatBox(top: 0, left: 0, right: 200, height: 90, block: true),
      ], columns: 2);
      final pageTop = tester.getTopLeft(find.byKey(pageKey)).dy;
      final leftFirst = tester.getTopLeft(find.text('Sol bir')).dy - pageTop;
      final rightFirst = tester.getTopLeft(find.text('Sag bir')).dy - pageTop;
      expect(leftFirst, greaterThanOrEqualTo(90.0));
      expect(rightFirst, lessThan(40.0));
    });
  });
}
