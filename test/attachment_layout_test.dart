import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

Attachment _image(
  String id, {
  double? displayWidth,
  double? pageY,
  double? x,
  bool asFile = false,
  String downloadUrl = '',
  String storagePath = '',
  String localPath = '',
}) => Attachment(
  id: id,
  kind: AttachmentKind.image,
  fileName: '$id.jpg',
  mimeType: 'image/jpeg',
  displayWidth: displayWidth,
  pageY: pageY,
  x: x,
  asFile: asFile,
  downloadUrl: downloadUrl,
  storagePath: storagePath,
  localPath: localPath,
);

void main() {
  group('withUploadOf', () {
    test('yukleme alanlarini alir, DUZENI korur', () {
      // Kullanici yukleme surerken gorseli tasiyip buyuttu.
      final current = _image(
        'a',
        displayWidth: 0.8,
        pageY: 420,
        x: 0.3,
        localPath: '/tmp/a.jpg',
      );
      // Kuyrugun yuklemeye BASLADIGI andaki kopya: eski duzen.
      final uploaded = _image(
        'a',
        displayWidth: 0.32,
        pageY: 60,
        x: 0.06,
        localPath: '/tmp/a.jpg',
        storagePath: 'users/u/notes/n/a.jpg',
        downloadUrl: 'https://example.test/a.jpg',
      );

      final merged = current.withUploadOf(uploaded);

      expect(merged.downloadUrl, 'https://example.test/a.jpg');
      expect(merged.storagePath, 'users/u/notes/n/a.jpg');
      expect(merged.displayWidth, 0.8, reason: 'boyut yuklemeyle geri alindi');
      expect(merged.pageY, 420, reason: 'konum yuklemeyle geri alindi');
      expect(merged.x, 0.3);
    });
  });

  group('mergeAttachmentLayout', () {
    test('gelen listeye YEREL duzen giydirilir', () {
      final local = [_image('a', displayWidth: 0.75, pageY: 300, asFile: false)];
      final incoming = [
        _image(
          'a',
          displayWidth: 0.32,
          pageY: 40,
          downloadUrl: 'https://example.test/a.jpg',
        ),
      ];

      final merged = mergeAttachmentLayout(local: local, incoming: incoming);

      expect(merged.single.displayWidth, 0.75);
      expect(merged.single.pageY, 300);
      // Yukleme durumu SUNUCUdan gelir.
      expect(merged.single.isUploaded, isTrue);
    });

    test('yerelde olmayan ek oldugu gibi girer, silinen ek dusar', () {
      final local = [_image('a', displayWidth: 0.75)];
      final incoming = [_image('b', displayWidth: 0.5)];

      final merged = mergeAttachmentLayout(local: local, incoming: incoming);

      expect(merged.map((a) => a.id), ['b']);
      expect(merged.single.displayWidth, 0.5);
    });

    test('sayfa/serit tercihi yerelden korunur', () {
      final local = [_image('a', asFile: true)];
      final incoming = [_image('a')];

      final merged = mergeAttachmentLayout(local: local, incoming: incoming);

      expect(merged.single.asFile, isTrue);
      expect(merged.single.floatsOnPage, isFalse);
    });
  });

  test('asFile yalniz true iken yazilir, geri okunur', () {
    expect(_image('a').toMap().containsKey('asFile'), isFalse);
    final map = _image('a', asFile: true).toMap();
    expect(map['asFile'], isTrue);
    // createdAt bos ekte sunucu zaman damgasidir (Firestore'a ozel); geri
    // okuma testinde disarida birakilir.
    expect(Attachment.fromMap({...map}..remove('createdAt')).asFile, isTrue);
  });

  test('floatsOnPage: gorsel olmayan ek sayfada yuzmez', () {
    const pdf = Attachment(
      id: 'p',
      kind: AttachmentKind.pdf,
      fileName: 'a.pdf',
      mimeType: 'application/pdf',
    );
    expect(pdf.floatsOnPage, isFalse);
    expect(_image('a').floatsOnPage, isTrue);
  });
}
