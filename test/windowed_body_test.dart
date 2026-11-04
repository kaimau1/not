import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_window.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/features/notes/presentation/editor/windowed_body.dart';

String _longText([int paragraphs = 400]) => [
  for (var i = 0; i < paragraphs; i++)
    i % 17 == 0
        ? ''
        : 'paragraf $i uzun bir satır ki kırılsın ${'kelime ' * (i % 9)}',
].join('\n');

/// F24.2: pencereli yazımda tam metin hep doğru; yerleşim tek alanla aynı.
void main() {
  group('eşleme', () {
    late WrapTextController full;
    late BodyWindow window;

    setUp(() {
      full = WrapTextController(text: _longText());
      full.selection = TextSelection.collapsed(offset: full.text.length ~/ 2);
      window = BodyWindow(full)..enter();
    });
    tearDown(() {
      window.dispose();
      full.dispose();
    });

    void typeAtCaret(String s) {
      final v = window.win.value;
      window.win.value = TextEditingValue(
        text:
            v.selection.textBefore(v.text) + s + v.selection.textAfter(v.text),
        selection: TextSelection.collapsed(
          offset: v.selection.start + s.length,
        ),
      );
    }

    test('kısa metinde pencere açılmaz', () {
      final short = WrapTextController(text: 'kısa');
      final w = BodyWindow(short)..enter();
      expect(w.active, isFalse);
      w.dispose();
      short.dispose();
    });

    test('pencere + parçalar tam metni bire bir kurar', () {
      expect(window.active, isTrue);
      expect(window.win.text.length, lessThan(full.text.length));
      final rebuilt = [
        ...window.before.map((t) => t.text),
        window.win.text,
        ...window.after.map((t) => t.text),
      ].join('\n');
      expect(rebuilt, full.text);
    });

    test('yazım tam metne, seçim tam metin ofsetine yazılır', () {
      final caret = full.selection.extentOffset;
      final expected = full.text.replaceRange(caret, caret, 'abc');
      typeAtCaret('abc');
      expect(full.text, expected);
      expect(full.selection.extentOffset, caret + 3);
    });

    test('binlerce tuş + yeniden pencereleme: metin kaybolmaz', () {
      final buffer = StringBuffer();
      var expected = full.text;
      var caret = full.selection.extentOffset;
      for (var i = 0; i < 6000; i++) {
        final ch = i % 50 == 49 ? '\n' : 'x';
        buffer.write(ch);
        typeAtCaret(ch);
        expected = expected.replaceRange(caret, caret, ch);
        caret++;
        if (i % 200 == 0) window.moveCaretTo(caret);
      }
      expect(full.text, expected);
      final rebuilt = [
        ...window.before.map((t) => t.text),
        window.win.text,
        ...window.after.map((t) => t.text),
      ].join('\n');
      expect(rebuilt, expected);
    });

    test('yazınca alt parçanın kimliği sabit, tam metin yeri doğru', () {
      final tile = window.after.first;
      typeAtCaret('abcdef');
      final start = tile.startIn(full.text.length);
      expect(full.text.substring(start, start + tile.text.length), tile.text);
      expect(window.after.first, tile);
    });

    test('dışarıdan yazım pencereye yansır', () {
      final next = 'BAŞ\n${full.text}';
      full.value = TextEditingValue(
        text: next,
        selection: const TextSelection.collapsed(offset: 2),
      );
      expect(window.active, isTrue);
      expect(window.window!.start, 0);
      expect(window.win.text.startsWith('BAŞ\n'), isTrue);
      expect(window.win.selection.extentOffset, 2);
    });

    test('tümünü seç notu seçer ve tek alana döner', () {
      window.win.selection = TextSelection(
        baseOffset: 0,
        extentOffset: window.win.text.length,
      );
      expect(window.active, isFalse);
      expect(full.selection.start, 0);
      expect(full.selection.end, full.text.length);
    });

    test('pencere dışına taşan seçim tek alana döndürür', () {
      full.selection = TextSelection(
        baseOffset: 0,
        extentOffset: full.text.length,
      );
      expect(window.active, isFalse);
    });

    test('kaymadan önceki pencereye ait klavye durumu YAZILMAZ', () {
      final oldWindowText = window.win.text;
      final before = full.text;
      // Pencereyi çok uzağa taşı (imleç başa).
      window.moveCaretTo(0);
      final moved = full.text;
      expect(moved, before);
      expect(window.win.text, isNot(oldWindowText));
      // Klavyenin yoldaki durumu: ESKİ pencere + bir harf.
      window.win.value = TextEditingValue(
        text: '${oldWindowText}x',
        selection: TextSelection.collapsed(offset: oldWindowText.length + 1),
      );
      expect(full.text, before, reason: 'paragraflar çoğalmamalı');
    });

    test('dev tek paragrafta da komşu paragraf pencerede', () {
      final text = 'üst\n${'x' * 8000}\nalt';
      final w = windowAround(text, 5);
      expect(w.start, 0);
      expect(w.end, text.length);
    });
  });

  testWidgets('parçalı yerleşim tek alanla aynı boyda', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const style = TextStyle(fontSize: 15, height: 1.4);
    final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);
    final text = _longText(120);
    final full = WrapTextController(text: text);
    full.selection = TextSelection.collapsed(offset: text.length ~/ 2);
    final window = BodyWindow(full);
    addTearDown(() {
      window.dispose();
      full.dispose();
    });
    final key = GlobalKey();
    Widget app(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(key: key, width: 360, child: child),
        ),
      ),
    );

    Widget field(
      TextEditingController c, {
      bool top = true,
      bool bottom = true,
    }) => TextField(
      controller: c,
      style: style,
      strutStyle: strut,
      maxLines: null,
      decoration: InputDecoration(
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.only(
          top: top ? 8 : 0,
          bottom: bottom ? 8 : 0,
        ),
      ),
    );

    await tester.pumpWidget(app(field(full)));
    final single = tester.getSize(find.byKey(key)).height;

    window.enter();
    expect(window.active, isTrue);
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => WindowedBodyField(
            window: window,
            style: windowedFieldStyle(context, style),
            strut: strut,
            linkColor: Colors.blue,
            topPadding: 8,
            field: (top, bottom) => field(window.win, top: top, bottom: bottom),
            onTileTap: (_, _) {},
            onTileLongPress: (_, _) {},
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(key)).height, single);
    expect(find.byType(BodyTileView), findsWidgets);
  });
}
