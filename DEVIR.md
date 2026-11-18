# DEVIR — oto/T16-tablet-turu (başlangıç 2026-11-18)

Cihaz: MatePad 11 `5VLBB21A27203178`, 1600x2560 @400dpi (2,5x), panel 60/120 Hz (uygulama Ayarlar→Hakkında "120 Hz" yazıyor; liste fırlatmada ~135 kare/sn),
ekran zaman aşımı 5 dk, sistem karanlık, OTOMATİK DÖNER (başlangıç accelerometer_rotation=1; ölçüm/tur `wm user-rotation lock`, İŞ BİTİNCE `wm user-rotation free`).
Aşağıdaki "geçici dosyalar" iş bitince SİLİNİR; commit'e girmez.

## Yapılanlar (commit'ler yerelde, push YOK)
- [x] Adım 0 GÜNCELLEME: `dev.kaimau.notlar` 1.2.66 (code 1102) → 1.2.91 (1392) → (coordinator isteğiyle) 1.2.92 (1393, `--obfuscate --split-debug-info`, main birleştirilmiş),
  imza aynı (`93d4f3e0`), Huawei "DEVAM ET"+"YÜKLE" onayı. Obfuscate'li sürüm: açılış + 7 ray hedefi (Notlar/Klasörler/Yapay zekâ/Takvim/Arşiv/Çöp/Ayarlar) gezildi,
  logcat'te FATAL/ANR/E-flutter YOK, süreç canlı. (İçerik özel: ekran görüntüleri depoya girmedi.)
- [x] T13 araç (ab_hepsi.py): tablet algısı (kısa kenar>=1400 px → `gecmis_tablet.csv`/`altin_taban_tablet.json`), döndürülmüş ekran boyutu (`perf.screen_size`),
  `--yon`, Huawei kurulum onayı + "Yükleme başarılı/BİTTİ" kapatma, `dump()` etiket sayımı, tablet ana ekran geometrisi (yalnız ESKİ derleme; yeni derlemede semantik yol),
  ⌨/IME (`ensure_ime`, `back_note`), arama→not (`find_note`, `close_note_search`), sablon etiketi, duzen ⚙ menüsü, `acilis` tampon düzeltmesi doğrulandı (kare 2→18-20).
- [x] `tool/perf/ram_taban.py` (PL11), `tool/perf/tur.py` (keşif yardımcısı), README tablet bölümü.

## Kanıtlı bulgular
- **TABLET ANA EKRAN + RAY erişilebilirlik ağacı BOŞ** (d822538f derlemesi; uiautomator 3,4 KB): KÖK `Navigator BlockSemantics sınırı` — main'de PW-A KW-1 (b2d9a878) ile DÜZELTİLDİ;
  birleştirilmiş derlemede (dd55fb09) ana ekran 49 etiket + EditText, ray "Notlar | Sekme 1 / 7". (Bulgu KT-13 olarak yazılacak: eski derlemede.)
- Profil manifest `screenOrientation=portrait`: ölçüm/tur için GEÇİCİ `unspecified` (ÇALIŞMA AĞACINDA, commit YOK; `git checkout android/app/src/profile/AndroidManifest.xml`). Ölçüm `--yon dikey` kilidiyle.
- Fiziksel klavye algısı: alana dokunmak sanal klavyeyi açmaz; ⌨ AÇ/KAPA anahtarı (açıkken dokunmak kapatır).
- Ana ekran aramasından açılan notta başlık eşleşirse not-içi arama çubuğu açılıp alt araç çubuğunu gizler.
- "Ekranı düzenle" artık not menüsü başlığındaki ⚙ içinde (⋮ → ⚙ → Ekranı düzenle).
- Güncelleme bandı ("Yeni sürüm var: v1.2.91") ve yedek bandı ana ekran yerleşimini kaydırır → piksel geometrisi kırılgan (eski derlemede başarısız koşunun nedeni).
- Boş ana ekranda BACK klasör geçiş menüsünü açabiliyor (gözlem; tur sırasında doğrula).

## Şu anki adım
- T1: `ab_hepsi.py <APK> <APK> --kosu 3 --teyit 0 --altin-yaz` (APK `scratchpad/olcum_profil_main2.apk`, dd55fb09 + manifest unspecified), log `scratchpad/t1_kosu.log`.

## Sıradaki
T1 sonucu → `docs/perf/tablet_taban.md` + RAM (`ram_taban.py`) → T16 turu (dikey+yatay: serbest APK zaten kurulu; yatay `wm user-rotation lock 1`) → docs/kesif_turu (KT-13…), kesif_tablet görüntüleri,
KONTROL "Tablette bak" notları, PLAN/OTOMASYON → imza/env.json/manifest geçici dosyalarını SİL + `wm user-rotation free` + ekranı uyut.
