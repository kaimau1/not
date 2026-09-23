import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

/// Ekranın yenileme hızı politikası (yalnız Android).
///
/// Bazı OEM'ler Flutter'ı 60 Hz'e sabitliyor; uygulama bu yüzden açılışta
/// yüksek yenileme hızı İSTİYOR. **PİL** (kullanıcı isteği 2026-09-23: "pil ve
/// ram performans için incele"): istek eskiden koşulsuzdu — sistemin pil
/// tasarrufu kipi açıkken de ekran 90/120 Hz'e kilitleniyordu, üstelik kipi
/// sonradan açan kullanıcı uygulamayı yeniden başlatana kadar yüksek hızda
/// kalıyordu. Artık tasarruf kipinde sistemin kendi seçimine (auto) bırakılır
/// ve karar uygulama her öne geldiğinde yeniden verilir.
abstract final class DisplayRate {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static Future<void> apply() async {
    if (kIsWeb || !Platform.isAndroid) return;
    var saving = false;
    try {
      saving = await _channel.invokeMethod<bool>('powerSaveMode') ?? false;
    } catch (_) {
      // Köprü yoksa (eski yerel kod) eski davranış: yüksek hız.
    }
    try {
      if (saving) {
        await FlutterDisplayMode.setPreferredMode(DisplayMode.auto);
      } else {
        await FlutterDisplayMode.setHighRefreshRate();
      }
    } catch (_) {
      // Desteklenmeyen cihaz: sistem varsayılanı kalır.
    }
  }
}
