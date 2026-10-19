import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_search.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// Not içi CANLI arama (kullanıcı isteği 2026-09-26: "not içi aramada
/// sayfada canlı aranmalı … aranınca orayı odaklasın").
void main() {
  test('katlama uzunluğu korur, Türkçe I/İ/ı/i ve aksanlar eşit sayılır', () {
    const text = 'İSTANBUL Ilık ıŞIK';
    final folded = foldForSearch(text);
    expect(folded.length, text.length);
    // F1.8 (2026-10-19): ş/ğ/ü/ö/ç da katlanır — "isik" "ışık"ı bulur.
    expect(folded, 'istanbul ilik isik');
  });

  test('düz metinde bütün eşleşmeler, tampon konumlarıyla', () {
    final index = TextSearchIndex('Süt al, sonra SÜT iç');
    final hits = index.find('süt');
    expect([for (final h in hits) (h.start, h.end)], [(0, 3), (14, 17)]);
  });

  test('biçim işaretlerinin ARASINDAN bulunur, aralık tamponda', () {
    // "**sü**t": ekranda "süt" okunur.
    const buffer = 'a **sü**t b';
    final hits = TextSearchIndex(buffer).find('süt');
    expect(hits, hasLength(1));
    // Aralık görünen ilk harften görünen son harfe: 's' (5) … 't' (8).
    expect(buffer.substring(hits.single.start, hits.single.end), 'sü**t');
  });

  test('sarma çapaları atlanır', () {
    final buffer = 'ka${kWrapAnchorChar}lem';
    final hits = TextSearchIndex(buffer).find('kalem');
    expect(hits.single.start, 0);
    expect(hits.single.end, buffer.length);
  });

  test('parça eşleşmenin çevresini tek satırda verir', () {
    final index = TextSearchIndex('birinci satır\nikinci satırda kalem var');
    final hit = index.find('kalem').single;
    final s = index.snippet(hit, 5, before: 8, after: 4);
    expect(s.hit, 'kalem');
    expect(s.lead, '…satırda ');
    expect(s.tail, ' var');
  });

  testWidgets('vurgu yalnız ÇİZİMİ değiştirir, odaktaki koyu', (tester) async {
    final controller = WrapTextController(text: 'bir iki bir');
    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: TextField(controller: controller)),
      ),
    );
    const hit = Color(0x11000000);
    const current = Color(0x22000000);
    controller.setSearchHighlights(
      [(0, 3), (8, 11)],
      current: 1,
      hitColor: hit,
      currentColor: current,
    );
    await tester.pump();
    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      withComposing: false,
    );
    final colors = <(String, Color?)>[];
    span.visitChildren((child) {
      if (child is TextSpan && (child.text ?? '').isNotEmpty) {
        colors.add((child.text!, child.style?.backgroundColor));
      }
      return true;
    });
    expect(controller.text, 'bir iki bir');
    expect(span.toPlainText(), 'bir iki bir');
    expect(colors, containsAll([('bir', hit), ('bir', current)]));
    expect(colors.where((c) => c.$2 != null), hasLength(2));

    controller.clearSearchHighlights();
    final plain = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      withComposing: false,
    );
    var any = false;
    plain.visitChildren((child) {
      if (child is TextSpan && child.style?.backgroundColor != null) any = true;
      return true;
    });
    expect(any, isFalse);
  });
}
