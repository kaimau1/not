import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android **resim içinde resim** (PiP) köprüsü (bkz. MainActivity).
///
/// Video oynatıcı ekranları açılınca [setAuto] ile otomatik geçişi açar:
/// kullanıcı ana ekrana çıkınca video küçük pencerede oynamaya devam eder.
/// Pencere değişimi [active] ile duyurulur; ekran o sırada çubuklarını
/// gizleyip yalnız videoyu çizer (küçük pencerede düğme dokunulamaz).
abstract final class PictureInPicture {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  /// Etkinlik şu an küçük pencerede mi.
  static final active = ValueNotifier<bool>(false);

  static bool _listening = false;

  static bool get _android => !kIsWeb && Platform.isAndroid;

  static void _listen() {
    if (_listening || !_android) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pipChanged') active.value = call.arguments == true;
      return null;
    });
  }

  /// Cihaz PiP destekliyor mu (Android 8+ ve özellik açık).
  static Future<bool> supported() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('pipSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Hemen küçük pencereye geçer. [aspect] videonun en-boy oranı.
  static Future<bool> enter({Size aspect = const Size(16, 9)}) async {
    if (!_android) return false;
    _listen();
    try {
      return await _channel.invokeMethod<bool>('enterPip', _ratio(aspect)) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Oynatıcı açıkken (true) ana ekrana çıkmak küçük pencereye geçirir.
  /// Oynatıcı kapanırken MUTLAKA false ile çağrılmalı — yoksa not listesinde
  /// ana ekrana çıkmak da uygulamayı küçük pencereye alırdı.
  static Future<void> setAuto(
    bool enabled, {
    Size aspect = const Size(16, 9),
  }) async {
    if (!_android) return;
    _listen();
    try {
      await _channel.invokeMethod<bool>('setAutoPip', {
        'enabled': enabled,
        ..._ratio(aspect),
      });
    } on PlatformException {
      // Desteklenmeyen cihaz: oynatıcı normal çalışır.
    } on MissingPluginException {
      // Köprüsüz eski kurulum.
    }
  }

  /// Oranı tamsayı çifte çevirir (Android `Rational` ister).
  static Map<String, int> _ratio(Size aspect) {
    if (aspect.width <= 0 || aspect.height <= 0) return {'w': 16, 'h': 9};
    return {
      'w': (aspect.width * 100).round(),
      'h': (aspect.height * 100).round(),
    };
  }
}
