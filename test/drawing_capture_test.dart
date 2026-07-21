import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/drawing_screen.dart';

/// Çizimi kaydetme yolu: painter'ı yeni bir tuvale çizip PNG üret.
/// Ekrandaki katmanı yakalayan eski yol (RepaintBoundary.toImage) CanvasKit'te
/// beyaz zemini verip ÇİZGİLERİ vermiyordu — not boş bir kutu olarak geliyordu.
Future<ui.Image> _render(List<Stroke> strokes, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  DrawingPainter(strokes).paint(canvas, size);
  return recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
}

/// Beyaz olmayan piksel sayısı. Sıfırsa çizim "boş kutu" demektir.
Future<int> _nonWhitePixels(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  var count = 0;
  for (var i = 0; i < bytes.length; i += 4) {
    if (bytes[i] != 255 || bytes[i + 1] != 255 || bytes[i + 2] != 255) count++;
  }
  return count;
}

void main() {
  const size = Size(60, 60);

  test('Çizilen çizgi üretilen görselde GERÇEKTEN yer alır', () async {
    final stroke = Stroke(Colors.black, 4)
      ..points.addAll(const [Offset(10, 10), Offset(50, 50)]);

    final image = await _render([stroke], size);

    expect(await _nonWhitePixels(image), greaterThan(0));
  });

  test('Tek dokunuş (tek nokta) da iz bırakır', () async {
    // Tek noktalı fırça darbesi drawPath yerine drawCircle ile çizilir;
    // ayrı dal olduğundan ayrıca korunur.
    final dot = Stroke(Colors.black, 8)..points.add(const Offset(30, 30));

    expect(await _nonWhitePixels(await _render([dot], size)), greaterThan(0));
  });

  test('Hiç çizgi yoksa görsel tamamen beyaz kalır', () async {
    expect(await _nonWhitePixels(await _render([], size)), 0);
  });
}
