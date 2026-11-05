import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:notlar/features/notes/data/attachment_thumb.dart';

void main() {
  test('büyük, gürültülü görsel ≤ 40 KB JPEG olur, oran korunur', () {
    final rnd = Random(1);
    final src = img.Image(width: 2000, height: 1000);
    for (final p in src) {
      p
        ..r = rnd.nextInt(256)
        ..g = rnd.nextInt(256)
        ..b = rnd.nextInt(256);
    }
    final thumb = makeThumbnail(Uint8List.fromList(img.encodePng(src)));
    expect(thumb, isNotNull);
    expect(thumb!.lengthInBytes, lessThanOrEqualTo(kThumbMaxBytes));
    final back = img.decodeJpg(thumb)!;
    expect(back.width, lessThanOrEqualTo(320));
    expect((back.width / back.height).round(), 2);
  });

  test('görsel olmayan veri → null', () {
    expect(makeThumbnail(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}
