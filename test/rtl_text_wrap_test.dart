import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// Sarma dolgusu SAĞDAN SOLA dillerde doğru tarafa gidiyor mu.
///
/// Görselin yeri FİZİKSELdir (ölçülen x), dolgu ise MANTIKSAL satır başına ya
/// da sonuna konan bir karakterdir. LTR'de satır başı fiziksel solda, RTL'de
/// fiziksel sağdadır — eşleme çevrilmezse dolgu görselin BULUNMADIĞI tarafa
/// konur ve metin görselin üstüne biner. Bu, ancak Arapça'ya geçip ekrana
/// bakınca fark edilir; kod incelemesinde kaçar.
///
/// Beklenti basit: aynı görsel için RTL sonucu LTR sonucunun AYNASI olmalı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const style = TextStyle(fontSize: 14, height: 1.4);
  const long =
      'Bir iki uc dort bes alti yedi sekiz dokuz on onbir oniki onuc '
      'ondort onbes onalti onyedi onsekiz ondokuz yirmi yirmibir '
      'yirmiiki yirmiuc yirmidort yirmibes yirmialti yirmiyedi';

  /// Satır BAŞI dolgusu: çapanın önünde birleştirici yoktur.
  int startAnchors(String display) {
    var n = 0;
    for (var i = 0; i < display.length; i++) {
      if (display[i] == kWrapAnchorChar &&
          (i == 0 || display[i - 1] != kWrapGlueChar)) {
        n++;
      }
    }
    return n;
  }

  /// Satır SONU dolgusu birleştiriciyle işaretlenir.
  int endAnchors(String display) => kWrapGlueChar.allMatches(display).length;

  WrapPlan plan(FloatBox float, TextDirection direction) => planTextWrap(
    logical: long,
    style: style,
    columnWidth: 300,
    floats: [float],
    direction: direction,
  );

  // Fiziksel olarak SOL kenardaki görsel.
  const leftFloat = FloatBox(top: 0, left: 0, right: 120, height: 40);
  // Fiziksel olarak SAĞ kenardaki görsel.
  const rightFloat = FloatBox(top: 0, left: 180, right: 300, height: 40);

  test('RTL: fiziksel SOLdaki gorsel satir SONUNA dolgu koydurur', () {
    final ltr = plan(leftFloat, TextDirection.ltr);
    final rtl = plan(leftFloat, TextDirection.rtl);

    // LTR'de sol kenar satirin BASIdir.
    expect(startAnchors(ltr.display), greaterThan(0));
    expect(endAnchors(ltr.display), 0);

    // RTL'de ayni kenar satirin SONUdur — dolgu taraf degistirmeli.
    expect(
      endAnchors(rtl.display),
      greaterThan(0),
      reason: 'RTL"de soldaki gorsel satir sonuna dolgu koymali',
    );
    expect(startAnchors(rtl.display), 0);
  });

  test('RTL: fiziksel SAGdaki gorsel satir BASINA dolgu koydurur', () {
    final ltr = plan(rightFloat, TextDirection.ltr);
    final rtl = plan(rightFloat, TextDirection.rtl);

    // LTR'de sag kenar satirin SONUdur.
    expect(endAnchors(ltr.display), greaterThan(0));
    expect(startAnchors(ltr.display), 0);

    // RTL'de ayni kenar satirin BASIdir.
    expect(
      startAnchors(rtl.display),
      greaterThan(0),
      reason: 'RTL"de sagdaki gorsel satir basina dolgu koymali',
    );
    expect(endAnchors(rtl.display), 0);
  });

  test('dolgu genisligi gorselin kapladigi yer kadar, yonden bagimsiz', () {
    // Sol kenardaki 120dp genisligindeki gorsel, hangi yonde olursa olsun
    // 120dp dolgu urretmeli: degisen dolgunun TARAFI, MIKTARI degil.
    final rtl = plan(leftFloat, TextDirection.rtl);
    expect(rtl.widths, isNotEmpty);
    expect(rtl.widths.every((w) => w == 120), isTrue);

    final ltr = plan(leftFloat, TextDirection.ltr);
    expect(ltr.widths.every((w) => w == 120), isTrue);
  });

  test('metnin kendisi her iki yonde de degismez', () {
    for (final float in [leftFloat, rightFloat]) {
      for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
        expect(
          stripWrapAnchors(plan(float, dir).display),
          long,
          reason: 'dolgu nota giden govdeyi bozmamali',
        );
      }
    }
  });

  test('gorsel yoksa yon hicbir sey degistirmez', () {
    final rtl = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [],
      direction: TextDirection.rtl,
    );
    expect(rtl.display, long);
    expect(rtl.widths, isEmpty);
  });
}
