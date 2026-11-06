/// Google API 403 yanıtının nedeni (kullanıcı 2026-11-06: "Google Takvim
/// bağlanamadı" — sebep söylenmiyordu). 403 hep "yetki yok" sayılınca konsolda
/// API'si etkin olmayan proje (F19.B10) sessizce "bağlanamadı" diyordu.
library;

/// Google Cloud projesinde bu API etkin değil (`SERVICE_DISABLED` /
/// `accessNotConfigured`). Yeniden izin istemek çözmez; konsolda etkinleştirilir.
bool googleServiceDisabled(int status, String body) =>
    status == 403 &&
    (body.contains('SERVICE_DISABLED') ||
        body.contains('accessNotConfigured') ||
        body.contains('has not been used in project') ||
        body.contains('is disabled'));

/// Jetonun kapsamı yetmiyor (onay ekranında kapsam yok ya da kullanıcı
/// kutuyu işaretlemedi).
bool googleScopeInsufficient(int status, String body) =>
    status == 403 &&
    (body.contains('insufficientPermissions') ||
        body.contains('ACCESS_TOKEN_SCOPE_INSUFFICIENT') ||
        body.contains('insufficient authentication scopes'));

final _activation = RegExp(
  r'https://console\.(?:developers|cloud)\.google\.com/apis/[^\s"\\]+',
);

/// Hata gövdesindeki "etkinleştir" adresi; yoksa [fallbackApi] kütüphane
/// sayfası (ör. `calendar-json.googleapis.com`).
String googleActivationUrl(String body, String fallbackApi) =>
    _activation.firstMatch(body)?.group(0) ??
    'https://console.cloud.google.com/apis/library/$fallbackApi';
