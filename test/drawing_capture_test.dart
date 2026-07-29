import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';

/// Çizimi kaydetme yolu: painter'ı yeni bir tuvale çizip PNG üret.
/// Ekrandaki katmanı yakalayan eski yol (RepaintBoundary.toImage) CanvasKit'te
/// beyaz zemini verip ÇİZGİLERİ vermiyordu — not boş bir kutu olarak geliyordu.
///
/// El yazısı ekranı artık PDF/görsel üstü çizimle AYNI modeli ([InkStroke]) ve
/// AYNI painter'ı ([InkPainter]) kullanıyor; test de o yoldan geçer.
Future<ui.Image> _render(List<InkStroke> strokes, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  InkPainter(strokes, 1).paint(canvas, size);
  return recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
}

/// Ekran konumlarını (piksel) [InkStroke]'un beklediği 0–1 oranına çevirir.
InkStroke _stroke(
  List<Offset> points, {
  required Size size,
  Color color = Colors.black,
  double width = 4,
}) => InkStroke(
  page: 1,
  color: color.toARGB32(),
  width: width / size.width,
  points: [
    for (final p in points) ...[p.dx / size.width, p.dy / size.height],
  ],
);

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
    final stroke = _stroke(const [
      Offset(10, 10),
      Offset(50, 50),
    ], size: size);

    final image = await _render([stroke], size);

    expect(await _nonWhitePixels(image), greaterThan(0));
  });

  test('Tek dokunuş (tek nokta) da iz bırakır', () async {
    // Tek noktalı fırça darbesi drawPath yerine drawCircle ile çizilir;
    // ayrı dal olduğundan ayrıca korunur.
    final dot = _stroke(const [Offset(30, 30)], size: size, width: 8);

    expect(await _nonWhitePixels(await _render([dot], size)), greaterThan(0));
  });

  test('Hiç çizgi yoksa görsel tamamen beyaz kalır', () async {
    expect(await _nonWhitePixels(await _render([], size)), 0);
  });

  test('Fosforlu çizgi SAYDAM çizilir (altındaki yazı okunur kalır)', () async {
    // Fosforlu kalem türü ayrı bir alanda saklanmaz; rengin alfası taşır.
    // Boya bunu okuyup saydam çizmezse vurgulama altındaki metni siler.
    final highlighted = _stroke(
      const [Offset(5, 30), Offset(55, 30)],
      size: size,
      color: InkPen.highlighter.apply(const Color(0xFFFB8C00)),
      width: InkPen.highlighter.defaultWidth,
    );

    final image = await _render([highlighted], size);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = data!.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    // Çizginin ortasındaki piksel: beyazla harmanlandığı için ne beyaz kalır
    // ne de düz turuncu olur.
    const center = (30 * 60 + 30) * 4;
    final rgb = [bytes[center], bytes[center + 1], bytes[center + 2]];
    expect(rgb, isNot([255, 255, 255]), reason: 'fosforlu iz bırakmadı');
    expect(rgb[2], greaterThan(0x00), reason: 'saydamlık uygulanmamış');
  });
}
