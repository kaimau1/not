# DEVIR — oto/120hz (2026-11-16)

Yapılanlar:
- `android/.../YenilemeHizi.kt` (yeni): pencere `preferredDisplayModeId` (aynı çözünürlük, <=120 Hz) + Flutter yüzeyine `Surface.setFrameRate` (API 30+); DisplayListener + surfaceCreated ile yinelenir.
- `MainActivity.kt`: kanal `setRefreshRate {high}` / `refreshRate`; onDestroy'da `birak()`.
- `lib/core/utils/display_rate.dart`: önce yerel köprü, hata olursa `flutter_displaymode`; `activeHz()`.
- Ayarlar sürüm satırı sonuna "· N Hz" (`settings_account.dart`).
- Test: `test/display_rate_test.dart` (5 yeşil); `flutter analyze` temiz.
- Belgeler: akicilik.md, sürüm notları (16 Kasım), KONTROL_LISTEM "Telefonda bak", regresyon listesi.

Şu anki adım: push + CI (Kotlin derlemesi yalnız CI'da doğrulanır; yerelde gradle koşulmadı).
Kanıt: Android belgesi developer.android.com/media/optimize/performance/frame-rate.
Cihazda doğrulanmadı (telefon yok). Main'e BİRLEŞTİRİLMEDİ.
Sıradaki: CI yeşilse yürütücü karar verir; cihazda Ayarlar → sürüm satırı ve `adb logcat -s NotlarEkran`.
Test komutu: `flutter test test/display_rate_test.dart --reporter failures-only`
