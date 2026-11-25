import 'sync/cloudflare_config.dart';

/// **PLAY DERLEMESİ BAYRAĞI** (PLAN §1.5 PL1, Faz 1).
///
/// `--dart-define=NOTLAR_PLAY=true` ile derlenen sürüm Google Play'e gider;
/// bayraksız derleme (kişisel APK, web) kendi güncellemesini yapar ve kapıları
/// açık tutar. Bütün Play kapıları YALNIZ burada; özellik dosyaları bu
/// sabitleri okur. Değerler `const` olduğundan Play derlemesinde kapalı dallar
/// Dart ağacından düşer.
abstract final class PlayBuild {
  /// Play derlemesi mi.
  static const bool enabled = bool.fromEnvironment('NOTLAR_PLAY');

  /// E1: GitHub Release'ten kendini güncelleme (Play dışı kurulum yönlendirmesi
  /// Play politikasına aykırı). Play'de güncellemeyi mağaza yapar.
  static const bool selfUpdate = !enabled;

  /// E3: konum hatırlatıcısı (arka plan konumu beyanı + video ister).
  static const bool placeReminders = !enabled;

  /// §2.6: Antalia cihaz içi Türkçe ses (ONNX, ~11 MB yerel kütüphane + model).
  static const bool antaliaVoice = !enabled;

  /// §4.5: YouTube oynatıcısından çıkınca kendiliğinden küçük pencere (PiP).
  /// Elle PiP düğmesi kalır.
  static const bool youtubeAutoPip = !enabled;

  /// İlk akıllı karar kullanımında rıza ekranı (PL3). Play'de zorunlu;
  /// kişisel APK'da ve web'de sorulmaz.
  static const bool aiConsent = enabled;

  /// Faz 2: Cloudflare Worker + D1 + R2 senkron arka ucu etkin mi
  /// (`--dart-define=CLOUDFLARE_API_BASE=https://...`). Kişisel APK'da boş
  /// bırakıldığından Firestore bozulmadan çalışır.
  static bool get cloudflareSync => CloudflareConfig.enabled;
}
