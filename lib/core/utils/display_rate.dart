import 'package:flutter/foundation.dart';
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
///
/// **120 Hz (kullanıcı isteği 2026-11-16):** istek önce YEREL köprüden verilir
/// (`YenilemeHizi.kt`: pencere modu + Flutter yüzeyine kare hızı oyu, ekran
/// değişiminde yinelenir, 120 tavanı). Köprü yoksa/hata verirse eski yol:
/// `flutter_displaymode`.
abstract final class DisplayRate {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> apply() async {
    if (!_android) return;
    var saving = false;
    try {
      saving = await _channel.invokeMethod<bool>('powerSaveMode') ?? false;
    } catch (_) {
      // Köprü yoksa (eski yerel kod) eski davranış: yüksek hız.
    }
    try {
      await _channel.invokeMethod<String>('setRefreshRate', {'high': !saving});
      return;
    } catch (_) {
      // Yerel yol yok: eklentiye düş.
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

  /// Ekranın o anki gerçek yenileme hızı (Ayarlar'daki sürüm satırında
  /// gösterilir — kullanıcı 120 Hz'i telefonda doğrulayabilsin). Android
  /// dışında ya da okunamazsa null.
  static Future<double?> activeHz() async {
    if (!_android) return null;
    try {
      return await _channel.invokeMethod<double>('refreshRate');
    } catch (_) {
      return null;
    }
  }
}
