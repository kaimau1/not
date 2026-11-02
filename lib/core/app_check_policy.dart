/// App Check'in bu platformda etkinleştirilip etkinleştirilmeyeceği (F18.1).
///
/// - Android: her zaman (Play Integrity / debug sağlayıcısı).
/// - Web: yalnız reCAPTCHA site anahtarı derlemeye verildiyse; anahtarsız
///   yerel/dal derlemesi bugünkü gibi App Check'siz çalışır.
/// - Diğerleri: eklenti yok, çağrı hata verirdi.
bool appCheckSupported({
  required bool isWeb,
  required bool isAndroid,
  required String webSiteKey,
}) {
  if (isWeb) return webSiteKey.trim().isNotEmpty;
  return isAndroid;
}
