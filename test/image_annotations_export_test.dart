import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/image_annotations.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

/// F18.13: görsele çizilen kalem izi ve açık metin dışa aktarılan görselde.
void main() {
  Future<Uint8List> whitePng(int w, int h) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    final img = await recorder.endRecording().toImage(w, h);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<List<int>> pixels(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData();
    return data!.buffer.asUint8List();
  }

  const base = Attachment(
    id: 'g',
    kind: AttachmentKind.image,
    fileName: 'foto.jpg',
    mimeType: 'image/jpeg',
  );

  test('katmansız görsel olduğu gibi kalır', () async {
    expect(hasImageAnnotations(base), isFalse);
    expect(await burnImageAnnotations(Uint8List(0), base), isNull);
  });

  testWidgets('çizim ve açık metin basılır', (tester) async {
    await tester.runAsync(() async {
      final png = await whitePng(200, 100);
      final annotated = base.copyWith(
        ink: const [
          InkStroke(
            page: 1,
            color: 0xFFFF0000,
            width: 0.05,
            points: [0.1, 0.5, 0.9, 0.5],
          ),
        ],
        bubbles: const [
          PageBubble(
            id: 'b',
            page: 1,
            x: 0.1,
            y: 0.1,
            text: 'tarih',
            plain: true,
            color: 0xFF0000FF,
          ),
        ],
      );
      expect(hasImageAnnotations(annotated), isTrue);
      final out = await burnImageAnnotations(png, annotated);
      expect(out, isNotNull);
      final before = await pixels(png);
      final after = await pixels(out!);
      expect(after.length, before.length);
      // Ortadaki satırda kırmızı çizgi: piksel artık beyaz değil.
      final mid = (50 * 200 + 100) * 4;
      expect(after[mid], greaterThan(200)); // R
      expect(after[mid + 1], lessThan(100)); // G
      final exported = await exportImageBytes(png, annotated);
      expect(exported.mimeType, 'image/png');
      expect(exported.width, 200);
    });
  });
}
