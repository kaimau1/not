import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Yaygın görsel biçimlerini dosya imzasından çözer.
///
/// Genel `img.decodeImage` PSD/EXR/PVR/TGA/PNM çözücülerini de derlemeye
/// bağlar; mobil ve web akışlarında gereken beş yaygın biçim (JPEG, PNG, WebP,
/// GIF, BMP) doğrudan seçilir.
img.Decoder? findCommonDecoderForData(List<int> data) {
  final bytes = data is Uint8List ? data : Uint8List.fromList(data);

  final jpg = img.JpegDecoder();
  if (jpg.isValidFile(bytes)) return jpg;

  final png = img.PngDecoder();
  if (png.isValidFile(bytes)) return png;

  final webp = img.WebPDecoder();
  if (webp.isValidFile(bytes)) return webp;

  final gif = img.GifDecoder();
  if (gif.isValidFile(bytes)) return gif;

  final bmp = img.BmpDecoder();
  if (bmp.isValidFile(bytes)) return bmp;

  return null;
}

/// [data] baytlarından JPEG, PNG, WebP, GIF veya BMP görseli çözer.
img.Image? decodeCommonImage(Uint8List data, {int? frame}) =>
    findCommonDecoderForData(data)?.decode(data, frame: frame);
