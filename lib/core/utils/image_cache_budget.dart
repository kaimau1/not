import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Flutter görsel önbelleğinin bütçesi (F7.6). Varsayılan 100 MB / 1000
/// görsel; düşük RAM'li Android cihazda (sistem bayrağı ya da ≤ 4 GB) yarıya
/// çekilir.
abstract final class ImageCacheBudget {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static const lowMemoryBytes = 50 << 20;
  static const lowMemoryCount = 500;

  static Future<void> apply() async {
    if (kIsWeb || !Platform.isAndroid) return;
    var low = false;
    try {
      low = await _channel.invokeMethod<bool>('lowMemoryDevice') ?? false;
    } catch (_) {
      // Köprü yoksa varsayılan bütçe kalır.
    }
    if (low) applyTo(PaintingBinding.instance.imageCache, lowMemory: true);
  }

  @visibleForTesting
  static void applyTo(ImageCache cache, {required bool lowMemory}) {
    if (!lowMemory) return;
    cache
      ..maximumSizeBytes = lowMemoryBytes
      ..maximumSize = lowMemoryCount;
  }
}
