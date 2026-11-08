import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/format_menu.dart';

void main() {
  test('madde imi: koyar, imleç kayar; ikinci kez kaldırır', () {
    final on = toggleLineBullet('a\nbc\nd', 3, 3);
    expect(on.text, 'a\n• bc\nd');
    expect(on.start, 5);
    final off = toggleLineBullet(on.text, on.start, on.end);
    expect(off.text, 'a\nbc\nd');
    expect(off.start, 3);
  });

  test('seçili satırların hepsine', () {
    final r = toggleLineBullet('x\ny\nz', 0, 3);
    expect(r.text, '• x\n• y\nz');
    expect(r.end, 7);
  });
}
