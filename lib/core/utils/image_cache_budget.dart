import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Donanım belleği sınıfı (düşük 2–3 GB / orta 4 GB / yüksek 6 GB+ telefon).
enum DeviceRamTier { low, mid, high }

/// Saf sınıflandırma: sistem bayrağı, RAM (MB) ve CPU çekirdeğinden bütçe seçer.
DeviceRamTier classifyDeviceRam({
  int totalRamMb = 0,
  bool lowRam = false,
  int cores = 0,
}) {
  if (lowRam) return DeviceRamTier.low;
  if (totalRamMb > 0 && totalRamMb <= 3200) return DeviceRamTier.low;
  if (cores > 0 && cores <= 4) return DeviceRamTier.low;
  if (totalRamMb >= 5800 && cores >= 8) return DeviceRamTier.high;
  return DeviceRamTier.mid;
}

/// Flutter görsel önbelleğinin, PDF DPI ve duvar kâğıdı tavanının 3 kademeli
/// donanım bütçesi.
abstract final class ImageCacheBudget {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static const lowMemoryBytes = 24 << 20;
  static const lowMemoryCount = 48;
  static const midMemoryBytes = 40 << 20;
  static const midMemoryCount = 72;
  static const highMemoryBytes = 64 << 20;
  static const highMemoryCount = 110;

  static DeviceRamTier _tier = DeviceRamTier.mid;

  static DeviceRamTier get tier => _tier;
  static bool get isLowRam => _tier == DeviceRamTier.low;

  static double get maxPdfDpi => switch (_tier) {
    DeviceRamTier.low => 144.0,
    DeviceRamTier.mid => 200.0,
    DeviceRamTier.high => 260.0,
  };

  static int get maxWallpaperWidth => _tier == DeviceRamTier.low ? 1080 : 1600;

  @visibleForTesting
  static void setTierForTest(DeviceRamTier tier) => _tier = tier;

  static Future<void> apply() async {
    if (kIsWeb || !Platform.isAndroid) {
      applyTier(PaintingBinding.instance.imageCache, DeviceRamTier.mid);
      return;
    }
    var resolved = DeviceRamTier.mid;
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>(
        'deviceMemoryInfo',
      );
      if (info != null && info.isNotEmpty) {
        final totalMb = (info['totalRamMb'] as num?)?.toInt() ?? 0;
        final lowRam = info['lowRam'] == true;
        final cores = (info['cores'] as num?)?.toInt() ?? 0;
        resolved = classifyDeviceRam(
          totalRamMb: totalMb,
          lowRam: lowRam,
          cores: cores,
        );
      } else {
        final low = await _channel.invokeMethod<bool>('lowMemoryDevice') ?? false;
        if (low) resolved = DeviceRamTier.low;
      }
    } catch (_) {
      try {
        final low = await _channel.invokeMethod<bool>('lowMemoryDevice') ?? false;
        if (low) resolved = DeviceRamTier.low;
      } catch (_) {}
    }
    _tier = resolved;
    applyTier(PaintingBinding.instance.imageCache, resolved);
  }

  static void applyTier(ImageCache cache, DeviceRamTier tier) {
    _tier = tier;
    final (count, bytes) = switch (tier) {
      DeviceRamTier.low => (lowMemoryCount, lowMemoryBytes),
      DeviceRamTier.mid => (midMemoryCount, midMemoryBytes),
      DeviceRamTier.high => (highMemoryCount, highMemoryBytes),
    };
    cache
      ..maximumSizeBytes = bytes
      ..maximumSize = count;
  }

  @visibleForTesting
  static void applyTo(ImageCache cache, {required bool lowMemory}) {
    applyTier(cache, lowMemory ? DeviceRamTier.low : DeviceRamTier.high);
  }
}
