import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ekranın yenileme hızı politikası (yalnız Android).
///
/// Bazı OEM'ler Flutter'ı 60 Hz'e sabitliyor; uygulama bu yüzden açılışta
/// yüksek yenileme hızı İSTİYOR. **PİL** (kullanıcı isteği 2026-09-23: "pil ve
/// ram performans için incele"): tasarruf kipinde sistemin kendi seçimine
/// (auto) bırakılır ve karar uygulama her öne geldiğinde yeniden verilir.
///
/// **120 Hz (kullanıcı isteği 2026-11-16):** istek YEREL köprüden verilir
/// (`YenilemeHizi.kt`: pencere modu + Flutter yüzeyine kare hızı oyu, ekran
/// değişiminde yinelenir, 120 tavanı).
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
      // Köprü yoksa (eski yerel kod) yüksek hız istenir.
    }
    try {
      await _channel.invokeMethod<String>('setRefreshRate', {'high': !saving});
    } catch (_) {
      // Desteklenmeyen cihaz / yerel kanal yok: sistem varsayılanı kalır.
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

  /// Sürüm satırlarının eki: " · 120 Hz" ya da okunamazsa boş. Kullanıcının
  /// gördüğü üç satır da (Ayarlar dibi, "Güncelleme ve sürüm", Hakkında) bunu
  /// kullanır — 2026-11-16 hatası: ek yalnız görünmeyen satıra eklenmişti.
  static Future<String> hzSuffix() async {
    final hz = await activeHz();
    return hz == null ? '' : ' · ${hz.round()} Hz';
  }
}
