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

## Şu anki adım
- Profil APK derleniyor (`--profile --build-number=1`, ölçüm kimliği) → T13 sonra T1 sonra T16.

## Notlar / tuzaklar
- Yatay/dikey zorlamak: `wm user-rotation lock 0|1|3` / `free` (iş bitince `free`; başlangıç: accelerometer_rotation=1).
- Ölçüm/keşif yalnız `dev.kaimau.notlar.olcum` (misafir). Asıl uygulamaya yalnız açılış kontrolü yapıldı.

## Sıradaki
T13 (evre seçicileri tablet düzeninde) → T1 (tablet altın tabanı + RAM) → T16 (tur, KT-13…) → belgeler.
