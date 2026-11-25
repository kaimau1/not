import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mağaza Kipi açıkken Android ekranının kapanmasını engeller (`FLAG_KEEP_SCREEN_ON`).
/// Web/masaüstü/test ortamlarında sessizce yok sayılır.
class KeepScreenOn {
  const KeepScreenOn._();

  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  @visibleForTesting
  static bool? debugLastEnabled;

  static Future<void> set(bool enabled) async {
    debugLastEnabled = enabled;
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', {
        'enabled': enabled,
      });
    } on PlatformException {
      // Eski yerel katman veya test kanalı: sessizce yok say.
    } on MissingPluginException {
      // Widget testlerinde kanal kayıtlı değil.
    }
  }
}
