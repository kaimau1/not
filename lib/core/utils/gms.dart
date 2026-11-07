import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Google Play Hizmetleri bu cihazda var mı (Huawei/HarmonyOS'ta yok;
/// GBox gibi kaplar uygulamanın kendisine GMS vermez). Yoksa Google
/// girişi ve kapsam yetkileri (Drive, Gmail, Takvim) doğrudan Firebase'in
/// tarayıcı akışından alınır — GMS yolu orada hiç çalışmaz.
///
/// Web ve testte true (GMS yolu zaten kullanılmaz / sahte).
Future<bool> gmsInstalled() => _cached ??= _probe();

Future<bool>? _cached;

Future<bool> _probe() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
  try {
    return await const MethodChannel(
          'dev.kaimau.notlar/system',
        ).invokeMethod<bool>('gmsInstalled') ??
        true;
  } on PlatformException {
    return true;
  } on MissingPluginException {
    return true;
  }
}

/// Firebase'in tarayıcı (Custom Tabs) akışını çalıştırır, bitince uygulamayı
/// öne alır: Huawei tarayıcısı sekmeyi ayrı görevde açıyor, dönüşte
/// kullanıcı boş "about:blank" sayfasında kalıyordu (tablet 2026-11-07).
Future<T> browserFlow<T>(Future<T> Function() run) async {
  try {
    return await run();
  } finally {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await const MethodChannel(
          'dev.kaimau.notlar/system',
        ).invokeMethod<void>('bringToFront');
      } catch (_) {}
    }
  }
}
