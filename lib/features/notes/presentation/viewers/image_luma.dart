import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../../core/utils/local_file.dart';
import '../../domain/attachment.dart';

/// Görsel ekin YEREL kaynağı; yerel kopya yoksa null (ağdan ayrıca
/// indirilmez — parlaklık yalnız bir kolaylık, varsayılan renk kalır).
ImageProvider? attachmentImageProvider(Attachment a) {
  if (a.localPath.isNotEmpty && localFileExists(a.localPath)) {
    return FileImage(File(a.localPath));
  }
  return null;
}

/// **GÖRSELİN KABA PARLAKLIK HARİTASI** (kullanıcı bulgusu 2026-11-22:
/// "siyah ekranda metin ekle görülmüyor, arka plana göre renk almalı metin
/// ekleme ve balon ekleme"). Görsel 24 px genişliğe küçültülüp BİR KEZ
/// çözülür (arka planda, birkaç ms); yeni açık metin / balon bırakılırken
/// noktanın çevresindeki ortalama parlaklık okunur.
class ImageLuma {
  ImageLuma._(this._w, this._h, this._luma);

  final int _w;
  final int _h;
  final Float32List _luma;

  /// [provider]'ı küçük boyda çözer; başarısızsa null.
  static Future<ImageLuma?> load(ImageProvider provider) async {
    try {
      final small = ResizeImage(provider, width: 24);
      final stream = small.resolve(ImageConfiguration.empty);
      final completer = Completer<ui.Image?>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) completer.complete(info.image.clone());
          stream.removeListener(listener);
        },
        onError: (_, _) {
          if (!completer.isCompleted) completer.complete(null);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      final image = await completer.future;
      if (image == null) return null;
      final data = await image.toByteData();
      final w = image.width;
      final h = image.height;
      image.dispose();
      if (data == null || w == 0 || h == 0) return null;
      final luma = Float32List(w * h);
      for (var i = 0; i < w * h; i++) {
        final r = data.getUint8(i * 4) / 255;
        final g = data.getUint8(i * 4 + 1) / 255;
        final b = data.getUint8(i * 4 + 2) / 255;
        luma[i] = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      }
      return ImageLuma._(w, h, luma);
    } catch (_) {
      return null;
    }
  }

  /// Oranlı noktanın ([x], [y] 0..1) çevresindeki ortalama parlaklık (0..1).
  double at(double x, double y) {
    final cx = (x.clamp(0.0, 1.0) * (_w - 1)).round();
    final cy = (y.clamp(0.0, 1.0) * (_h - 1)).round();
    var sum = 0.0;
    var n = 0;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -2; dx <= 3; dx++) {
        final px = cx + dx;
        final py = cy + dy;
        if (px < 0 || py < 0 || px >= _w || py >= _h) continue;
        sum += _luma[py * _w + px];
        n++;
      }
    }
    return n == 0 ? 1 : sum / n;
  }
}
