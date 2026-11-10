import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/window_class.dart';

/// F67.1: pencere sınıfı tek yerde. Eski dağınık koşullarla yeni sınıfın
/// aynı pencere kümesini verdiğini gösterir; `lib` içinde en kısa kenar
/// karşılaştırması yalnız `window_class.dart`'ta.
void main() {
  const sizes = [
    Size(360, 640),
    Size(393, 851),
    Size(412, 915),
    Size(599, 900),
    Size(600, 600),
    Size(640, 1024),
    Size(800, 600),
    Size(800, 1280),
    Size(839, 500),
    Size(840, 900),
    Size(851, 393),
    Size(1024, 640),
    Size(1199, 800),
    Size(1200, 800),
    Size(1280, 800),
    Size(1440, 900),
  ];

  test('çeviriler eski koşullarla aynı (telefon yatay hariç)', () {
    for (final s in sizes) {
      for (final web in [false, true]) {
        final w = WindowClass.fromSize(s, web: web);
        final why = '$s web=$web';
        // items_editor: kIsWeb || shortestSide >= 600
        expect(!w.compactDevice, web || s.shortestSide >= 600, reason: why);
        // editor_quick_row: !kIsWeb && shortestSide >= 600
        expect(
          w.touchFirst && !w.compactDevice,
          !web && s.shortestSide >= 600,
          reason: why,
        );
        // dashboard / share_target: width < 600 / >= 600
        expect(w.width == WindowWidth.compact, s.width < 600, reason: why);
        expect(w.atLeast(WindowWidth.medium), s.width >= 600, reason: why);
        // login: width >= 840
        expect(w.atLeast(WindowWidth.expanded), s.width >= 840, reason: why);
        // Bölünme: eskisi width >= 640; yalnız telefon cihazı yatayda farklı.
        final phoneLandscape = !web && s.shortestSide < 600 && s.width >= 640;
        expect(
          splitActiveFor(s, web: web),
          s.width >= 640 && !phoneLandscape,
          reason: why,
        );
      }
    }
  });

  test('sınıflar (Ek C)', () {
    final mi = WindowClass.fromSize(const Size(393, 851), web: false);
    expect(
      [mi.width, mi.height, mi.compactDevice],
      [WindowWidth.compact, WindowHeight.regular, true],
    );
    final yatay = WindowClass.fromSize(const Size(851, 393), web: false);
    expect(
      [yatay.width, yatay.height, yatay.compactDevice],
      [WindowWidth.expanded, WindowHeight.short, true],
    );
    final mate = WindowClass.fromSize(const Size(1024, 640), web: false);
    expect(
      [mate.width, mate.height, mate.compactDevice],
      [WindowWidth.expanded, WindowHeight.regular, false],
    );
    final masa = WindowClass.fromSize(const Size(1440, 900), web: true);
    expect(
      [masa.width, masa.height, masa.touchFirst],
      [WindowWidth.large, WindowHeight.tall, false],
    );
  });

  test('lib: shortestSide karşılaştırması yalnız window_class.dart', () {
    final bad = <String>[];
    final re = RegExp(r'shortestSide\s*(>=|<=|>|<)');
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.replaceAll(r'\', '/').endsWith('app/window_class.dart')) {
        continue;
      }
      if (re.hasMatch(f.readAsStringSync())) bad.add(f.path);
    }
    expect(bad, isEmpty);
  });
}
