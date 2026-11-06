import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/share_intake.dart';

void main() {
  test('zip imzalı dosya (ör. .notyedek) metin sayılmaz; düz metin sayılır',
      () async {
    final dir = await Directory.systemTemp.createTemp('zip_sniff');
    addTearDown(() => dir.delete(recursive: true));
    final zip = File('${dir.path}/notlar-yedek.notyedek')
      ..writeAsBytesSync([0x50, 0x4B, 0x03, 0x04, 1, 2, 3]);
    final txt = File('${dir.path}/a.txt')..writeAsStringSync('PK değil');
    expect(looksLikeZip(zip.path), isTrue);
    expect(looksLikeZip(txt.path), isFalse);
    expect(looksLikeZip('${dir.path}/yok.bin'), isFalse);
  });
}
