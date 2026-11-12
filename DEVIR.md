# DEVIR — P39 Hız hissi (DENEYIM F78.1–F78.5) · dal `oto/P39-hiz-hissi`

## Yapılanlar
- F78.1 (K-D8) açılış: `core-splashscreen` 1.0.1; `LaunchTheme` = `Theme.SplashScreen`
  (zemin `launch_bg`, simge `ic_launcher`, sonrası `NormalTheme`); `MainActivity`
  `installSplashScreen()` + ilk Flutter karesine dek tut (3 sn emniyet). Debug APK derlendi.
  **Yazıldı, cihazda doğrulanmadı.**

## Şu an
- F78.3 yükleme hâlleri (DelayedSpinner göçü, `MediaLoadingCover`).

## Kök neden / kanıt
- Beyaz açılış: `docs/hafiza/arayuz.md:18` (MIUI 13, ~0,6 sn; ilk Flutter karesi elenmedi).
  Flutter zaten `RenderMode.surface`'te ilk Android çizimini geciktiriyor; fark MIUI'de
  ancak cihazda görülür.

## Sıradaki
- F78.2 `tool/perf/prof_new.py` · F78.4 dokunuş dökümü · F78.5 iyimser işlem testi.

## Cihazda ölçülecek (yürütücü)
- F78.1: soğuk açılış `adb shell screenrecord` + ffmpeg kare kare beyaz kare sayısı
  (önce/sonra; `tool/perf/video.py`). Beyaz kare kalıyorsa F78.1 commit'ini GERİ AL.
  Güncelleme sonrası açılışı (`GuncellemeSonrasiAc`) ve kişisel + `.olcum` kimliklerini de dene.

## Kullanıcıya görünen
- Açılışta uygulama simgeli açılış ekranı (beyaz parlama yerine).
