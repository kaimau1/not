# DEVIR — oto/G1-ayarlar (P62 G1 = PA1+PA2+PA3+PA4, plan_tasarim_A §8)

## Yapılanlar
- PA1 [x] (14c73c46 + sonraki commit): `_GroupColumn` grup kartları, `_SettingRow.group`, l10n `settingsGroup*`,
  `_rowsTheme` (ListTileTheme + SegmentedButtonTheme), geniş ekran (arama solda, topStart, ValueNotifier seçim),
  dar geçiş belirteçleri, Güncelleme alanı satır dili. Test: `test/settings_groups_test.dart`.

- PA2 [x]: AccountIdentityCard (account_identity_card.dart), levha karoları PressScale/PopIn, Hesap sayfası
  §4 sırası (bare satır + AppBanner, Hesabı sil en altta), izin/yedek satırları, kilit segmenti tek satır.

## Ölçüm (ham)
- S30: 341 → ilk deneme 349 → Container→DecoratedBox, avatar işlev → 341.
- S36 düzenek düzeltmesi (yayma sızıntısı): 1137 → 1038 / en ağır 265.
- S29: taban 367/37/488 → 353/37/474 (ilk karede 2 satır). İlk deneme sarmalayıcılı: 369/55/547 (geri alındı).
- S36: taban 673/1875 → 266/1137. Kök neden FocusScope.of(context).unfocus() bağımlılığı (dosya settings_screen.dart openAreaId).

## Sıradaki
- PA3 öbür alanlar, PA4 yan ekranlar.

## Komutlar
- `flutter test test/perf_budget_test.dart --plain-name S29` / `S36` / `S30`
- `flutter test test/settings_groups_test.dart test/settings_*_test.dart --reporter failures-only`
- token bütçesi: `python tool/design/token_sayim.py --json > test/design_tokens/budget.json`
