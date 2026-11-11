import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/tag_tap.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// F60.3: "📖 s.N" satırı silinemiyordu. KÖK: [linkAtPoint] PDF referansını
/// notta referansın döneceği PDF olmasa da (PDF alt şeritte — "Ek" görünümü —
/// ya da madde satırında) bağlantı sayıyordu: dokunuş klavyeyi AÇMIYOR,
/// hiçbir şey de yapmıyordu → satıra imleç konamıyor, silinemiyordu.
/// Damga (video) gibi referans da yalnız işi olan yerde bağlantıdır.
void main() {
  testWidgets('PDF yoksa referansa dokunuş klavyeyi açar', (tester) async {
    const text = 'Giris\n📖 s.11';
    final controller = TextEditingController(text: text);
    final key = GlobalKey<EditableTextState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: EditableText(
                key: key,
                controller: controller,
                focusNode: FocusNode(),
                style: const TextStyle(fontSize: 16),
                cursorColor: Colors.black,
                backgroundCursorColor: Colors.grey,
                maxLines: null,
              ),
            ),
          ),
        ),
      ),
    );
    final render = key.currentState!.renderEditable;
    final box = render
        .getBoxesForSelection(
          TextSelection(
            baseOffset: text.indexOf('s.11'),
            extentOffset: text.length,
          ),
        )
        .first
        .toRect();
    final global = render.localToGlobal(box.center);
    bool hit({required bool pdfRefs}) => linkAtPoint(
      editable: key.currentState,
      displayText: text,
      global: global,
      pdfRefs: pdfRefs,
    );
    // Notta referansın döneceği PDF var: bağlantı (belge o sayfaya döner).
    expect(hit(pdfRefs: true), isTrue);
    // Yok: düz yazı — dokunuş imleç koyar, klavye açılır.
    expect(hit(pdfRefs: false), isFalse);
  });

  test('referans satırı geri silmeyle silinir (sarma açık/kapalı)', () {
    const style = TextStyle(fontSize: 14, height: 1.4);
    for (final floats in const [
      <FloatBox>[],
      [FloatBox(top: 0, left: 0, right: 120, height: 200)],
      [FloatBox(top: 0, left: 180, right: 300, height: 200)],
    ]) {
      final c = WrapTextController();
      c.updateLayout(floats: floats, style: style, columnWidth: 300);
      c.text = 'Giris\n📖 s.11 “alinti”';
      c.selection = TextSelection.collapsed(offset: c.text.length);
      // 15 karakterlik referans satırı + satır sonu.
      for (var i = 0; i < 16; i++) {
        final v = c.value;
        final caret = v.selection.baseOffset;
        final before = v.text.substring(0, caret);
        final cut = caret - before.characters.last.length;
        c.value = TextEditingValue(
          text: v.text.replaceRange(cut, caret, ''),
          selection: TextSelection.collapsed(offset: cut),
        );
      }
      expect(stripWrapAnchors(c.text), 'Giris', reason: '$floats');
      c.dispose();
    }
  });
}
