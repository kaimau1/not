import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// SARMA PLANI ÖNBELLEĞİ (2026-08-07 / 15. tur).
///
/// KÖK NEDEN: `planTextWrap` satır satır ilerlerken her turda TAM bir
/// `TextPainter.layout` + tam biçim ayrıştırması yapıyor — maliyeti
/// O(satır × metin). Bu, `set value`yu tetikleyen HER ŞEYDE koşuyordu:
/// yazmak, metne dokunmak, imleci taşımak, seçim yapmak. Oysa plan yalnız
/// METİN ya da yerleşim girdileri (sütun genişliği, bantlar, stil, ölçek)
/// değişince değişir.
///
/// Bu dosya iki şeyi kilitler: (a) plan gereksiz yere yeniden hesaplanmıyor,
/// (b) gerektiğinde MUTLAKA yeniden hesaplanıyor — bayat plan imleç konumunu
/// kaydırır, o yüzden yanlış tarafta hata yapmak serbest değil.
void main() {
  const style = TextStyle(fontSize: 16);
  const floats = [FloatBox(top: 0, left: 0, right: 80, height: 60)];

  WrapTextController controllerWithFloat() {
    final c = WrapTextController(text: 'bir iki uc dort bes alti yedi sekiz')
      ..selection = const TextSelection.collapsed(offset: 0);
    c.updateLayout(
      style: style,
      columnWidth: 200,
      floats: floats,
      textScaleFactor: 1,
    );
    return c;
  }

  testWidgets('aynı girdilerle plan YENİDEN hesaplanmaz', (tester) async {
    final c = controllerWithFloat();
    final display = c.text;
    // Aynı yerleşimi ikinci kez bildirmek dizgiyi değiştirmemeli.
    c.updateLayout(
      style: style,
      columnWidth: 200,
      floats: floats,
      textScaleFactor: 1,
    );
    expect(c.text, display);
  });

  testWidgets('imleci taşımak dizgiyi bozmaz', (tester) async {
    final c = controllerWithFloat();
    final display = c.text;
    c.selection = const TextSelection.collapsed(offset: 5);
    expect(c.text, display);
    c.selection = const TextSelection(baseOffset: 2, extentOffset: 7);
    expect(c.text, display);
  });

  testWidgets('metin değişince plan YENİDEN hesaplanır', (tester) async {
    final c = controllerWithFloat();
    final before = c.text;
    c.setLogical('${c.logicalText} dokuz on onbir oniki', 4);
    expect(c.text, isNot(before));
    // Çapalar hâlâ metnin İÇİNDE: sarma sürüyor.
    expect(c.text.contains(kWrapAnchorChar), isTrue);
  });

  testWidgets('bantlar değişince plan YENİDEN hesaplanır', (tester) async {
    final c = controllerWithFloat();
    final before = c.text;
    c.updateLayout(
      style: style,
      columnWidth: 200,
      // Görsel büyüdü: kesilen satırlar ve dolgu genişlikleri değişmeli.
      floats: const [FloatBox(top: 0, left: 0, right: 150, height: 140)],
      textScaleFactor: 1,
    );
    expect(c.text, isNot(before));
  });

  testWidgets('sütun genişliği değişince plan YENİDEN hesaplanır', (
    tester,
  ) async {
    final c = controllerWithFloat();
    final before = c.text;
    c.updateLayout(
      style: style,
      columnWidth: 400,
      floats: floats,
      textScaleFactor: 1,
    );
    expect(c.text, isNot(before));
  });

  testWidgets('mantıksal metin çapalardan arınmış kalır', (tester) async {
    final c = controllerWithFloat();
    expect(c.logicalText, 'bir iki uc dort bes alti yedi sekiz');
  });
}
