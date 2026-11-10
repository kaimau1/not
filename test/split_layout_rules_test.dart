import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/split_shell.dart';

/// Tablet/katlanabilir düzen kuralları (kullanıcı isteği 2026-11-02): not
/// açıkken liste rayın yerine geçer ve daha dar pencerede de yan yana çizilir;
/// dikey menteşe varsa ayraç ona oturur.
void main() {
  test('liste sol panelde: dikey tablet ve açık katlanabilir dahil', () {
    // Dikey tablet (~800) ve açık katlanabilir (~673): liste kabukta (not
    // yokken tam genişlik, açıkken yan yana).
    expect(splitActiveFor(const Size(800, 1280), web: false), isTrue);
    expect(splitActiveFor(const Size(673, 841), web: false), isTrue);
    expect(splitActiveFor(const Size(1024, 640), web: false), isTrue);
    // Test yüzeyi 800×600 tablet sayılır (davranış değişmedi).
    expect(splitActiveFor(const Size(800, 600), web: false), isTrue);
    // Telefon / kapalı katlanabilir hiç bölünmez.
    expect(splitActiveFor(const Size(412, 915), web: false), isFalse);
  });

  test('telefon yatayda bölünmez (F66.7), web pencere genişliğiyle', () {
    expect(splitActiveFor(const Size(851, 393), web: false), isFalse);
    expect(splitActiveFor(const Size(915, 412), web: false), isFalse);
    // Web'de alçak ama geniş tarayıcı penceresi eskisi gibi bölünür.
    expect(splitActiveFor(const Size(851, 393), web: true), isTrue);
  });

  test('not konumu', () {
    expect(isNoteLocation('/note/x'), isTrue);
    expect(isNoteLocation('/notebook/x'), isTrue);
    expect(isNoteLocation('/'), isFalse);
    expect(isNoteLocation('/archive'), isFalse);
  });

  testWidgets('dikey menteşe bulunur, yatay kıvrım ve çentik sayılmaz', (
    tester,
  ) async {
    Rect? found;
    Future<void> pump(List<DisplayFeature> features) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(840, 900),
            displayFeatures: features,
          ),
          child: Builder(
            builder: (context) {
              found = verticalHingeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
    }

    await pump(const [
      DisplayFeature(
        bounds: Rect.fromLTWH(420, 0, 0, 900),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureHalfOpened,
      ),
    ]);
    expect(found?.center.dx, 420);

    await pump(const [
      DisplayFeature(
        bounds: Rect.fromLTWH(0, 450, 840, 0),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureHalfOpened,
      ),
    ]);
    expect(found, isNull);

    await pump(const [
      DisplayFeature(
        bounds: Rect.fromLTWH(400, 0, 40, 30),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ]);
    expect(found, isNull);
  });
}
