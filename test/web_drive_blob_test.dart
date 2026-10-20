import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

void main() {
  test('web Drive eki: blob: adresi buluta yazılmaz (F4.4)', () {
    const a = Attachment(
      id: 'a',
      kind: AttachmentKind.pdf,
      fileName: 'x.pdf',
      mimeType: 'application/pdf',
      driveId: 'd1',
      downloadUrl: 'blob:https://app/1234',
    );
    final map = a.toMap();
    expect(map['downloadUrl'], '');
    expect(map['driveId'], 'd1');
    const b = Attachment(
      id: 'b',
      kind: AttachmentKind.pdf,
      fileName: 'y.pdf',
      mimeType: 'application/pdf',
      downloadUrl: 'https://firebasestorage/y',
    );
    expect(b.toMap()['downloadUrl'], 'https://firebasestorage/y');
  });
}
