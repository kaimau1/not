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
