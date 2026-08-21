import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/image_stamp.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

/// Görselin üstüne yapılan çizim ve açık metin, dışa aktarılan/paylaşılan
/// BAYTA basılıyor mu (KALANLAR 2026-08-16: "görsele yazılan metin dışa
/// aktarmada YOK").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Attachment image({List<InkStroke> ink = const [], List<PageBubble> bubbles = const []}) =>
      Attachment(
        id: 'img1',
        kind: AttachmentKind.image,
        fileName: 'foto.png',
        mimeType: 'image/png',
        sizeBytes: 10,
        width: 40,
        height: 40,
        ink: ink,
        bubbles: bubbles,
      );

  const stroke = InkStroke(
    page: 1,
    color: 0xFFFF0000,
    width: 0.1,
    points: [0.1, 0.1, 0.9, 0.9],
  );
  const plain = PageBubble(
    id: 'b1',
    page: 1,
    x: 0.1,
    y: 0.1,
    text: 'merhaba',
    plain: true,
  );

  /// Düz beyaz bir PNG üretir (damganın kaynağı).
  Future<Uint8List> white(int side) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..drawRect(
        ui.Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF),
      );
    final picture = recorder.endRecording();
    final img = await picture.toImage(side, side);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  test('damgalanacak sey yoksa needed false', () {
    expect(ImageStamp.needed(image()), isFalse);
    // Yalnız BOŞ bir balon da damgalanmaz (çizilecek bir şey yok).
    expect(
      ImageStamp.needed(
        image(bubbles: const [PageBubble(id: 'b', page: 1, x: 0.5, y: 0.5)]),
      ),
      isFalse,
    );
    expect(ImageStamp.needed(image(ink: const [stroke])), isTrue);
    expect(ImageStamp.needed(image(bubbles: const [plain])), isTrue);
  });

  test('damgasiz ek ozgun baytlari aynen dondurur', () async {
    final bytes = await white(20);
    expect(identical(await ImageStamp.burn(bytes, image()), bytes), isTrue);
  });

  test('cizim ve acik metin baytlara basilir, olculer korunur', () async {
    final bytes = await white(40);
    final out = await ImageStamp.burn(
      bytes,
      image(ink: const [stroke], bubbles: const [plain]),
    );
    expect(out, isNot(same(bytes)), reason: 'damga uygulanmadi');

    final codec = await ui.instantiateImageCodec(out);
    final frame = await codec.getNextFrame();
    final stamped = frame.image;
    addTearDown(() {
      stamped.dispose();
      codec.dispose();
    });
    expect(stamped.width, 40);
    expect(stamped.height, 40);

    // Çizgi köşegen geçtiği için ortadaki piksel artık beyaz DEĞİL.
    final data = await stamped.toByteData();
    final pixels = data!.buffer.asUint8List();
    int at(int x, int y) => (y * stamped.width + x) * 4;
    final center = at(20, 20);
    expect(
      pixels[center] == 0xFF && pixels[center + 1] == 0xFF && pixels[center + 2] == 0xFF,
      isFalse,
      reason: 'cizgi goruntuye basilmadi',
    );
  });
}
