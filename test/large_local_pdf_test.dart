import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/local_file.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

class _NoStorage extends Fake implements FirebaseStorage {}

/// OTURTMA F65.9: bulut tavanını aşan PDF reddedilmez, belleğe okunmadan
/// yalnız bu cihaza kopyalanır.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('f659_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('akışla kopya: içerik birebir, yüzde seyrek ve 1,0 ile biter', () async {
    final data = Uint8List.fromList(
      List.generate(3 * 1024 * 1024 + 17, (i) => i % 251),
    );
    final src = File('${tmp.path}/a.pdf')..writeAsBytesSync(data);
    final dst = File('${tmp.path}/b.pdf');
    final seen = <double>[];
    await copyFileStreamed(src, dst, onProgress: seen.add);
    expect(dst.readAsBytesSync(), data);
    expect(seen.last, 1.0);
    expect(seen.length, lessThanOrEqualTo(101));
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], greaterThan(seen[i - 1]));
    }
  });

  test('kaynak okunamazsa yarım hedef kalmaz', () async {
    final dst = File('${tmp.path}/b.pdf');
    await expectLater(
      copyFileStreamed(File('${tmp.path}/yok.pdf'), dst),
      throwsA(isA<FileSystemException>()),
    );
    expect(dst.existsSync(), isFalse);
  });

  test('yer yok hatası tanınır', () {
    expect(
      isNoSpaceError(
        const FileSystemException('w', 'p', OSError('No space', 28)),
      ),
      isTrue,
    );
    expect(isNoSpaceError(const FileSystemException('w', 'p')), isFalse);
  });

  test('yalnız-cihaz eki bütün baytı isteyen yola belleğe alınmaz', () async {
    final file = File('${tmp.path}/mr.pdf')..writeAsBytesSync([1, 2, 3]);
    final repo = AttachmentRepository(_NoStorage(), 'u', 10);
    final a = Attachment(
      id: 'a',
      kind: AttachmentKind.pdf,
      fileName: 'mr.pdf',
      mimeType: 'application/pdf',
      localPath: file.path,
      localOnly: true,
    );
    await expectLater(repo.readBytes(a), throwsA(isA<FileTooLargeException>()));
    expect(await repo.readBytes(a.copyWith(localOnly: false)), [1, 2, 3]);
    // Yükleme kapısı da kapalı.
    expect(await repo.upload('n', a), isNull);
  });
}
