import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const style = TextStyle(fontSize: 14, height: 1.4);
  const long =
      'Bir iki uc dort bes alti yedi sekiz dokuz on onbir oniki onuc '
      'ondort onbes onalti onyedi onsekiz ondokuz yirmi yirmibir '
      'yirmiiki yirmiuc yirmidort yirmibes yirmialti yirmiyedi';

  test('gorsel yokken plan kimliktir', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [],
    );
    expect(plan.display, long);
    expect(plan.widths, isEmpty);
  });

  test('ust satirlar gorselin yanindan akar, alt satirlar tam genislikte', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, width: 120, height: 40)],
    );
    // Kesilen satirlarin basina dolgu konur; metnin kendisi degismez.
    expect(plan.widths, isNotEmpty);
    expect(stripWrapAnchors(plan.display), long);
    // Dolgu yalnizca gorselin bandindaki satirlara girer, her satira degil.
    expect(plan.widths.length, lessThan('\n'.allMatches(long).length + 12));
    expect(plan.widths.every((w) => w == 120), isTrue);
  });

  test('bloklayan gorsel metni altina iter, yanina sikistirmaz', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [
        FloatBox(top: 0, width: 300, height: 30, blocking: true),
      ],
    );
    // Dolgu satirin tamamini yer -> o satirlara kelime sigmaz, metin altta.
    expect(plan.widths, isNotEmpty);
    expect(plan.widths.every((w) => w == 300), isTrue);
    expect(stripWrapAnchors(plan.display), long);
    // Sonsuz dongu korumasi: gorsel yuksekligi kadar satir, daha fazlasi degil.
    expect(plan.widths.length, lessThanOrEqualTo(4));
  });

  test('dar gorselin yanina metin akar (gercek sarma)', () {
    final wrapped = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, width: 100, height: 60)],
    );
    // Kesilen satirlar dar, altindakiler tam genislikte -> metin yandan akiyor.
    expect(wrapped.widths.every((w) => w == 100), isTrue);
    expect(stripWrapAnchors(wrapped.display), long);
  });

  test('imlec konumu capalar arasinda gidip gelirken korunur', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, width: 120, height: 40)],
    );
    for (final logicalOffset in [0, 1, 25, 60, long.length]) {
      final d = wrapToDisplayOffset(plan.display, logicalOffset);
      expect(
        wrapToLogicalOffset(plan.display, d),
        logicalOffset,
        reason: 'offset $logicalOffset gidis-donus bozuldu',
      );
    }
  });

  test('capa temizleme nota giden govdeyi bozmadan birakir', () {
    const withAnchors = 'a${kWrapAnchorChar}bc${kWrapAnchorChar}d';
    expect(stripWrapAnchors(withAnchors), 'abcd');
    expect(stripWrapAnchors('temiz metin'), 'temiz metin');
  });
}
