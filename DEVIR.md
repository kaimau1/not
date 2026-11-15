# DEVIR — oto/G5-duzen (G5: PB1+PB2+PB7+PA9; G3 dalı cf2eebd8 üstünde)

## Yapılanlar
- PB1 önce üret: S40 tabanı (kök 1 / aç 3 / kapa 3 / dokunuş 0 / satır 0), tur `duzen-serit` + `kisisellestir` (build/tour_p63_once, açık+koyu, telefon-kucuk + matepad-yatay; turun builder'ına CustomizeModeHost eklendi — app.dart'taki gibi), `test/customize_strip_test.dart` KIRMIZI (onReorder yok).

## Şu anki adım
- PB1 uygulama (customizable.dart: şerit tek satır + Sırala + hap + giriş/çıkış; çerçeve belirteçli + kesikli).

## Sıradaki
- PB2 hub (customize_hub.dart), PB7 sarmalar/sıralar, PA9 (9 showSnackBar + 3 hide → showMessage/hideMessage, notice_paths_guard 0).

## Komutlar
- `flutter test test/perf_budget_test.dart --plain-name S40`, `flutter test test/customize_strip_test.dart`
- Tur: `TOUR_ONLY=duzen-serit,kisisellestir TOUR_SIZES=telefon-kucuk,matepad-yatay TOUR_OUT=build/tour_p63_once flutter test tool/tour/screen_tour_test.dart`
