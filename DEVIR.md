# DEVIR — oto/keep-panel (2026-11-16)

Yapılanlar:
- İŞ 1 (ef1d1589): 120 Hz etiketi. Kök neden: " · N Hz" yalnız `_AppVersionRow`'daydı (settings_account.dart);
  görünen `_VersionLine` / `_VersionFooter` (settings_area.dart) PackageInfo'dan yalnız sürüm yazıyordu.
  `DisplayRate.hzSuffix()` ortak; `test/settings_version_hz_test.dart` eskide kırmızı (0 widget), şimdi yeşil.
  Kotlin köprüsü (MainActivity `refreshRate`/`setRefreshRate` → YenilemeHizi) bağlı; istek yolu kodda doğru, cihazda doğrulanmadı.
- İŞ 2: alt panel kip k (varsayılan). `KlavyeOngoru.kt` (API 30+, decorView, CONTINUE_ON_SUBTREE, onStart → `dev.kaimau.notlar/ime` start{open,target px,ms});
  Dart `KeyboardForecast` (+SharedPreferences yön başına bellek), `_KeepShift` boyama ötelemesi.
  Konum testleri kip c'ye sabitlendi; yeni: keyboard_snap_test "kip k" ×3, perf S47k.

Ölçüm (widget testi): S47k varış 112 ms / örtme 0 / geri 0 / varıştan sonra oynama 0 / kapanış ters 0 / kapanış 112 ms.
S45: klavye_kurulum 404→402, kapa_kurulum 1049→1025 (dizilme 174/153 aynı). S8 0/0, S17 hareket karesi ≤55 (kip c'de).
Kotlin: `flutter build apk --debug --target-platform android-arm64` başarılı.

Sıradaki: CI yeşil → yürütücü birleştirir; cihazda KONTROL_LISTEM "Alt panel kip k" + 120 Hz.
Test: flutter test test/keyboard_snap_test.dart test/perf_budget_test.dart test/settings_version_hz_test.dart
