# DEVIR — oto/T16-tablet-turu (başlangıç 2026-11-18 13:15)

Cihaz: MatePad 11 `5VLBB21A27203178`, 1600x2560 @400dpi (2,5x), panel 60/120 Hz (etkin mod 60: `primaryRefreshRateRange=[0 60]`),
ekran zaman aşımı 5 dk, sistem karanlık, OTOMATİK DÖNER (şu an fiziksel yatay = ROTATION_90, `wm size` yine 1600x2560 verir!).

## Yapılanlar
- [x] Adım 0 GÜNCELLEME: `dev.kaimau.notlar` 1.2.66 (code 1102) → 1.2.91 (code 1392), aynı imza (`93d4f3e0`), `adb install -r` Success
  (Huawei: "DEVAM ET" + "YÜKLE" iki onay), açıldı (Yenilikler v1.2.91 toast'ı, ana ekran tablet yatay). Derleme: release arm64,
  `NOTLAR_KISISEL=1`, `--build-number=1392` (son Actions koşusu 1389), env.json = `Desktop\Yazılımlar\not\env.json` (ana depoda yok),
  geçici imza dosyaları worktree'de (`android/app/notlar-release.jks`, `android/key.properties`, `env.json`): İŞ BİTİNCE SİL.
- Araç: `tool/perf/perf.py` `screen_size()` (yatayda W,H ters: `wm size` fiziksel dikey verir) + `wake()` kaydırması oranla;
  `ab_hepsi.py`/`ab_liste.py` bunu kullanır; `tool/perf/tur.py` keşif yardımcısı (snap/dump/tap/rot/crash).

## Bulgular (14:45, kanıtlı)
- **TABLET ANA EKRAN erişilebilirlik ağacı BOŞ** (uiautomator dump 3401 bayt, yalnız boş `View` zinciri; ray de yok): olcum (profil) ve asıl (release) APK'da,
  dikey+yatay. Aynı APK'da `wm size 1080x2400; wm density 420` (telefon düzeni) → 28 KB dolu ağaç; not editörü (31 KB), ayarlar (12 KB), levhalar (7 KB) tablette DOLU.
  => ab_hepsi seçicileri (nodes) tablet ana ekranında çalışamaz; olası kök `lib/app/split_shell.dart` ~545-575 (kabuk içi `DashboardScreen`: FadeTransition/SlideTransition/Offstage/ClipRect) ya da ray.
- Profil manifest (`android/app/src/profile/AndroidManifest.xml`) `screenOrientation=portrait` → ölçüm uygulaması YATAY döndürülemez (wm user-rotation işe yaramaz). Tur için GEÇİCİ `unspecified` ile ayrı profil APK derleniyor
  (`olcum_profil_serbest.apk`); manifest değişikliği COMMIT EDİLMEZ (`git checkout android/app/src/profile/AndroidManifest.xml`).
- Tablet fiziksel klavye algılıyor (editör araç çubuğunda "Sanal klavyeyi aç (fiziksel klavye takılı)" ⌨): sanal klavye alana dokununca açılmaz → ab_hepsi `kb/yaz` evreleri ⌨ düğmesiyle açmalı; IME kapalıyken BACK notu kapatır.
- Tablet sistemi karanlık tema, ekran zaman aşımı 5 dk; yönlendirme sensörle (fiziksel duruşa göre) ve ara sıra değişiyor.
- Huawei `adb install` onayı: `ab_hepsi.install()` artık paket yükleyici pencerelerini ("DEVAM ET"/"YÜKLE", yalnız ölçüm uygulaması) kendisi geçiyor.
- 2. profil derlemesi 1. denemede "Gradle daemon stopped" ile düştü (başka ajan `gradle --stop`?), tekrar denenince geçti.

## Şu anki adım
- T13: tablet (dikey, yerleşim = ray + 2 sütun liste) için ana ekran geometrisi (dp) + arama ile kart bulma; `kb` evresi ⌨ ile; sonra T1 koşusu.

## Notlar / tuzaklar
- Yatay/dikey zorlamak: `wm user-rotation lock 0|1|3` / `free` (iş bitince `free`; başlangıç: accelerometer_rotation=1).
- Ölçüm/keşif yalnız `dev.kaimau.notlar.olcum` (misafir). Asıl uygulamaya yalnız açılış kontrolü yapıldı.

## Sıradaki
T13 → T1 (tablet altın tabanı + RAM, dikey) → T16 (tur; yatay için serbest-yönlü geçici APK, KT-13…) → belgeler → imza/env.json/manifest geçici dosyalarını SİL.
