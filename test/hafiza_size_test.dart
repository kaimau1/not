import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HAFIZA.md 30 KB tavanını aşmaz (F58.2)', () {
    expect(File('HAFIZA.md').lengthSync(), lessThanOrEqualTo(30 * 1024));
  });
}
