import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

/// PDF sayfasını çizmenin TEK yolu (kart kapağı, sayfa görüntüsü, PNG
/// dışa aktarma, OCR). pdfrx'in `PdfImage`i yerel bellekte durur: her yol
/// `dispose`u burada, tek sırayla yapar.

/// [page]i [width] piksel genişlikte (yükseklik orandan ya da [height])
/// `ui.Image` olarak çizer. Çizim başarısızsa ya da iptal edildiyse null.
Future<ui.Image?> renderPdfPageImage(
  PdfPage page, {
  required double width,
  double? height,
  int background = 0xFFFFFFFF,
  PdfPageRenderCancellationToken? cancellationToken,
}) async {
  final rendered = await _render(
    page,
    width: width,
    height: height,
    background: background,
    cancellationToken: cancellationToken,
  );
  if (rendered == null) return null;
  try {
    return await rendered.createImage();
  } finally {
    rendered.dispose();
  }
}

/// [page]i [width] piksel genişlikte PNG baytı olarak çizer.
Future<Uint8List?> renderPdfPagePng(
  PdfPage page, {
  required double width,
  int background = 0xFFFFFFFF,
}) async {
  final image = await renderPdfPageImage(
    page,
    width: width,
    background: background,
  );
  if (image == null) return null;
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// [page]i [width] piksel genişlikte JPEG baytı olarak çizer; kodlama
/// izolede. Kart kapağında PNG'nin birkaç katı küçük (F7.1).
Future<Uint8List?> renderPdfPageJpeg(
  PdfPage page, {
  required double width,
  int background = 0xFFFFFFFF,
  int quality = 82,
}) async {
  final rendered = await _render(page, width: width, background: background);
  if (rendered == null) return null;
  try {
    return await compute(encodeBgraJpeg, (
      pixels: Uint8List.fromList(rendered.pixels),
      width: rendered.width,
      height: rendered.height,
      quality: quality,
    ));
  } finally {
    rendered.dispose();
  }
}

/// BGRA piksellerini JPEG'e kodlar (izolede çağrılır; testte doğrudan).
Uint8List encodeBgraJpeg(
  ({Uint8List pixels, int width, int height, int quality}) input,
) {
  final image = img.Image.fromBytes(
    width: input.width,
    height: input.height,
    bytes: input.pixels.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
  return img.encodeJpg(image, quality: input.quality);
}

Future<PdfImage?> _render(
  PdfPage page, {
  required double width,
  double? height,
  required int background,
  PdfPageRenderCancellationToken? cancellationToken,
}) async {
  if (page.width <= 0 || page.height <= 0 || width <= 0) return null;
  return page.render(
    fullWidth: width,
    fullHeight: height ?? page.height * width / page.width,
    backgroundColor: background,
    cancellationToken: cancellationToken,
  );
}
