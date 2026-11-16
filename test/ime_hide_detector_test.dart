import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/ime_hide_detector.dart';

void main() {
  test('klavye kapanışı başlayınca bir kez true', () {
    final d = ImeHideDetector();
    for (final v in const <double>[0, 120, 260, 300]) {
      expect(d.onInset(v), isFalse);
    }
    expect(d.onInset(280), isFalse);
    expect(d.onInset(120), isTrue);
    expect(d.onInset(40), isFalse);
    expect(d.onInset(0), isFalse);
  });

  test('öneri şeridi gibi küçük boy değişimi sayılmaz', () {
    final d = ImeHideDetector();
    d.onInset(300);
    expect(d.onInset(260), isFalse);
    expect(d.onInset(300), isFalse);
  });

  test('klavye hiç açık değilken tetiklenmez', () {
    final d = ImeHideDetector();
    expect(d.onInset(0), isFalse);
    d.reset();
    expect(d.onInset(0), isFalse);
  });
}
