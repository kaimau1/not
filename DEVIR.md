# DEVIR — oto/G5-duzen (G5: PB1+PB2+PB7+PA9; G3 dalı cf2eebd8 üstünde)

## Yapılanlar
- PB1 önce üret: S40 tabanı (kök 1 / aç 3 / kapa 3 / dokunuş 0 / satır 0), tur `duzen-serit` + `kisisellestir` (build/tour_p63_once, açık+koyu, telefon-kucuk + matepad-yatay; turun builder'ına CustomizeModeHost eklendi — app.dart'taki gibi), `test/customize_strip_test.dart` KIRMIZI (onReorder yok).

- PB1 bitti (f4c67acf): şerit + çerçeve; S40 değişmedi; sapma: kayma boyun çeyreği.
- PB2 bitti: customize_hub.dart + (b)(c)(d) pano; ekran yüzeyleri alt alta; (e) dönüştürülmedi (sabah bakılacak). S40 hub_govde 0.

## Şu anki adım
- PB7: editor_quick_row quickOrder, attach_sheet attachOrder, video_transport/ortak çalışan/pinned sarmaları, pinned ⋮ menuId.

## Sıradaki
- PA9 (9 showSnackBar + 3 hide → showMessage/hideMessage, notice_paths_guard 0), bitiş (OTOMASYON P63 satırı, regresyon, hafıza arayuz.md, sürüm notu, KONTROL_LISTEM).

## Komutlar
- `flutter test test/perf_budget_test.dart --plain-name S40`, `flutter test test/customize_strip_test.dart`
- Tur: `TOUR_ONLY=duzen-serit,kisisellestir TOUR_SIZES=telefon-kucuk,matepad-yatay TOUR_OUT=build/tour_p63_once flutter test tool/tour/screen_tour_test.dart`
