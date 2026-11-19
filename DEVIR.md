# DEVIR — oto/T16-tablet-turu (2026-11-18/19) — BİTTİ (yerel, push yok)

Cihaz: MatePad 11 `5VLBB21A27203178`; ekran uykuda, `wm user-rotation free` (accelerometer_rotation=1 geri), `wm size/density` varsayılan.
Geçici dosyalar (imza jks/key.properties, env.json, profil manifest değişikliği) SİLİNDİ/geri alındı; commit'e girmedi.
Ölçüm uygulamasında bırakılanlar: "Listeyi tepeden aşağı çekince" = Hiçbiri, yedek bandı "Sonra" (küçük), tema Adaçayı, OLCUM kalem/cizgi notları yüklü (+3 işaretli madde "OLCUM cizgi"de, deneme yazısı ek metni "Kitap bilet"te).

## Yapılanlar
- Güncelleme: `dev.kaimau.notlar` 1.2.66 (1102) → 1.2.91 (1392) → 1.2.92 (1393, `--obfuscate --split-debug-info`, main dd55fb09 birleşik), aynı imza, açılış + 7 ray hedefi temiz (logcat FATAL/ANR/E-flutter yok).
- T13: `tool/perf/ab_hepsi.py` tablette 17 evrenin hepsi (README "Tablet"); kök nedenler `docs/hafiza/akicilik.md` 2026-11-19.
- T1/PL11: `docs/perf/tablet_taban.md` + `altin_taban_tablet.json` + `gecmis_tablet.csv` (APK: scratchpad `olcum_profil_main2.apk`; komut README).
- T16: `docs/kesif_turu_2026-11-14.md` KT-13…24 (+öneriler, paket kümeleme TP-A…F), `docs/kesif_tablet_2026-11-18/` 19 PNG, KONTROL_LISTEM notları, PLAN/OTOMASYON durumları.

## Kalan / sıradaki
- KT düzeltme paketleri TP-A (KT-13 yatay kart dokunuşu `moveTaskToBack`, ÖNCE), TP-B…E; yatay ölçüm anahtarı (profil manifest); 120 Hz kipi, 1000/3000 not, YouTube RAM durumu; M-Pencil/1 GB PDF/TalkBack/K32 kontrolleri; web turu başka ajanda.
- Yeniden üretme: `tool/perf/tur_gez.py dikey|yatay`, `tool/perf/ram_taban.py`, `tool/perf/ab_hepsi.py A B --kosu 3 --teyit 0 --altin` (tablet tabanına karşı).
- Yürütücü birleştirmeden önce bu dosyayı SİLER; push yapılmadı.
