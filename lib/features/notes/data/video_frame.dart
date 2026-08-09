import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Videodan **kapak karesi** çıkarır (Android; `MediaMetadataRetriever`).
///
/// Balonlu görüntülü not için: balon, vurgu ve el yazısı bir SAYFANIN üzerinde
/// yaşıyor (bkz. `PageBubble` — konum sayfa oranı). Videonun sayfası yok, bu
/// yüzden balonlu kipte videonun bir karesi belge sayfasına dönüştürülür;
/// video da nota ek olarak bağlı kalır, yani hiçbir şey kaybolmaz.
///
/// Çıkaramazsa (desteklenmeyen kodlayıcı, masaüstü, köprüsüz eski kurulum)
/// null döner — çağıran klasik yola düşer.
abstract final class VideoFrame {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static Future<Uint8List?> cover(String path) async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('videoFrame', {
        'path': path,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
