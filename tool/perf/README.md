# tool/perf — telefonda akıcılık ölçümü

`docs/arsiv/planlar/AKICILIK_PLANI.md`'deki sayılar bu araçlarla alındı. Python 3 + Pillow, `adb`
(yol `ADB` ortam değişkeniyle), USB hata ayıklaması açık telefon. Çıktılar
`PERF_OUT` (yoksa sistem geçici klasörü `notlar_perf/`) altına — depoya düşmez.

| Dosya | Ne yapar |
|---|---|
| `perf.py` | adb yardımcıları (`wake`, `tap`, `swipe`, `text`, `front`, `find`/`tap_label` uiautomator), SurfaceFlinger kare toplayıcı (`SF`, `analyze`), atrace (`atrace_start/stop`, `parse_sched`, `burst_stats`, `sections`), içe aktarma (`open_import`, `wait_import`) |
| `scen.py` | release senaryoları: `scroll` (12 fırlatma), `open_close` (not aç/kapa ×3), `typing`, `measure_sections` |
| `hitch.py` | SF karelerini atrace saatine hizalar (`deliverInputEvent eventTimeNano`), her takılmada ana iş parçacığı meşguliyeti |
| `vmsvc.py` | profil derlemesinin Dart VM servisi (HTTP GET): zaman çizelgesi, CPU örnekleri, widget build profili, platform kanalı sayacı (`VM.channels(reset=True)` — F27.1) |
| `prof_oc.py`, `prof_scroll.py`, `prof_type.py` | profil uygulamasında aç/kapa, kaydırma, yazma + kök neden dökümü |
| `taban.py` | **duman testi / Ek B satırı** (F20.4, F27.4): açılış, kaydırma, 4 not aç/kapa, yazma; sıcaklık yazar |
| `prof_cold.py` | soğuk açılış profili (start-paused): kareler, kanallar, CPU |
| `prof_new.py` | **"Yeni not" süresi** (DENEYIM F78.2): "+" → "Metin notu" dokunuşundan klavye görünene dek, telefon saatiyle; 5 koşu ortanca, hedef ≤ 450 ms |
| `prof_sizes.py` | metin boyutuna göre tuş maliyeti (F24.1; `make_dataset.py boyut`) |
| `prof_save.py` | kayıt başına Firestore olayı + Dart bloğu (F22.1) |
| `prof_a11y.py` | erişilebilirlik istemcisi açıkken SEMANTICS maliyeti (F27.2) |
| `video.py` | ekran videosu, kare farkıyla flaş/zıplama (F26.1, ffmpeg) |
| `jest.py`, `Pinch.java` | iki parmak zoom + yana kaydırma kareleri (F39); `Pinch` `app_process` ile gerçek çoklu dokunuş enjekte eder |
| `ab_hepsi.py` | **TAM A/B KAPISI** (HIZ F81, 2026-11-12): iki profil APK'sı A,B ×3 sırayla kurulur; 13 evre (açılış ilk kare, liste, ⋮, arama, klasör, yeni not, not aç, klavye, yazma, kapanış, sabit PDF aç/kaydır/klavye); ortanca + otomatik karar (`KARAR:`), `--altin` altın tabana karşı %15, `--altin-yaz` tabanı yalnız iyileşmeyle günceller; `docs/perf/gecmis.csv`'ye yazar. Hazırlık docstring'de |
| `ab_klavye.py` | **A/B kapısı** (2026-11-10): klavye aç/kapa ×3, yazma ×4, not kapanışı — evre başına UI kare/ms/LAYOUT; taban = önceki `[apk]`'nın profil derlemesi (CLAUDE.md ÖLÇÜM KAPISI) |
| `ab_kalem.py` | **A/B kapısı, kalem** (F59.5): kalem kipi açık, parmakla 30 çizgi + kayıt + kapanış — evre başına UI ve raster kare/ms/>16,7, kayıt anında en uzun UI bloğu; `hazirla N` sayfayı N çizgiyle doldurur (dolu sayfa hâli). Kapı: UI ya da raster +%20 → birleştirme yok |
| `ab_liste.py` | ana ekran 8 fırlatma — UI kare/ms, BUILD/LAYOUT toplamı |
| `prof_kb2.py` | klavye döngüsü + kapanış, SF kareleriyle; `w` = evre başına widget build dökümü |
| `make_dataset.py` | Keep Takeout zip'leri: 240 not + 4 adlı stres notu (`OLCUM …`); `--ink 1500` → `olcum_kalem.notyedek` (boş not + 1500 çizgili sabit PDF, tam yedek biçimi) |

## Hazırlık

```bash
python tool/perf/make_dataset.py            # keep_olcum.zip + olcum_ozel.zip
adb push "$TMP/keep_olcum.zip" /sdcard/Download/
adb push "$TMP/olcum_ozel.zip" /sdcard/Download/
```
Uygulamada: Ayarlar → Senkronizasyon → "Başka uygulamadan içe aktar" (ya da
`python -c "from perf import *; open_import('keep_olcum.zip'); wait_import()"`).
240 not ~4 dk sürer.

## Profil derlemesi yan yana ("Notlar Ölçüm")

F20.2 (2026-11-04) sonrası KENDİLİĞİNDEN: `profile` derleme türü
`applicationIdSuffix = ".olcum"` + etiket "Notlar Ölçüm" + kendi
`android/app/src/profile/google-services.json`'ı ile derlenir.
1. `C:/src/flutter/bin/flutter.bat build apk --profile --target-platform android-arm64 --build-number=1`
2. `adb install -r build/app/outputs/flutter-apk/app-profile.apk` → telefonda
   "USB üzerinden yükle" onayı (Xiaomi). Release'e dokunmaz.
Bilinen sınır: uygulama kısayolları sabit paket adıyla release'i açar.

Varsayılan kimlikle `flutter run/drive/install` test telefonunda **ASLA**: imza
uyuşmazlığında araç uygulamayı kaldırıp kurar → telefondaki veri silinir.

## Koşturma

```bash
cd tool/perf
python -u scen.py scroll taban                 # release, Impeller
python -u scen.py scroll skia skia             # aynı senaryo Skia ile (A/B)
python -u -c "from scen import *; front(); open_close('kisa', 281, 1365)"
```
Profil uygulamasında (önce VM servisine bağlan):
```bash
python -u -c "from perf import *; from vmsvc import *; launch_profile()"
python -u prof_scroll.py kaydirma
python -u prof_oc.py kisa 281 1374             # kart koordinatı: find('OLCUM')
python -u prof_type.py uzun 281 1784 700 560 yenikelime
```
Kart koordinatları liste sırasıyla değişir: `find('OLCUM')` ile bul.

## Tuzaklar

- Ekran zaman aşımı 60 sn: `find()` her dökümden önce Shift gönderir; uzun
  beklemede `wait_import` gibi tuş gönder.
- `uiautomator dump` Flutter semantiğini açar: ölçüm penceresinde döküm yapma.
- Arka arkaya geri tuşu uygulamayı kapatabilir: senaryodan önce `front()`.
- Release'te Dart zaman çizelgesi yok; Java tarafı işler profil zaman
  çizelgesinde görünmez → ikisini birlikte oku (atrace + VM servisi).
- SF aralıklarında boşta bekleme boşlukları da var (`idle_ms` eşiği); yazma
  senaryolarında güvenilir sayı `hitch.py`'nin "ana meşgul" sütunu.

## Alt panel kipleri (S47, `panel_kayit.py`)

Üç profil APK'sı (ölçüm uygulaması kimliği; her derlemeden sonra APK'yı kopyala,
aynı yolu ezer):

```bash
F="C:/src/flutter/bin/flutter.bat"
for k in a b c; do
  "$F" build apk --profile --target-platform android-arm64 --dart-define-from-file=env.json \
      --dart-define=ALT_PANEL_KIP=$k --build-number=<N>
  cp build/app/outputs/flutter-apk/app-profile.apk "$TMP/panel_$k.apk"
done
```

Her kip için: `adb install -r "$TMP/panel_<k>.apk"` → uygulamada bir metin notu aç
(klavye kapalı) → `adb exec-out screencap -p > s.png` ile panelin üst kenarını (ayraç)
bir kez oku → `python -u tool/perf/panel_kayit.py <k> <alan_x> <alan_y> --panel-y <px>`
(10× aç/kapa; `--tekrar`, `--video` ile yeniden çözümleme). Son satır `TOPLAM <k>:`
geri sıçrama / takılma / gizli / ort-maks sapma. Ham kareler `PERF_OUT/panel_<k>.csv`.

## Tablet (MatePad 11, T13/T1, 2026-11-18)

`ab_hepsi.py` tableti kendi düzeninde ölçer (kısa kenar >= 1400 px → tablet; kayıt `docs/perf/gecmis_tablet.csv`,
taban `altin_taban_tablet.json`; telefonla KARŞILAŞTIRILMAZ). Ölçüm APK'sı (profil) manifestte DİKEY kilitli
(`android/app/src/profile/AndroidManifest.xml`) → ölçüm 1600x2560 (640x1024 dp): ray + 2 sütun liste; yatay/bölünmüş
görünüm için APK'yı yatay derle (TP-F, 2026-11-19): `NOTLAR_OLCUM_YON=landscape "$F" build apk --profile ...`
(değerler: portrait (varsayılan) | landscape | sensor | unspecified | fullSensor; `-PolcumYon=` da olur). `--yon yatay`
dikey kilitli APK'yı açılışta görür ve DURUR (eskiden sessizce dikeyde ölçerdi). Yatay evre seçicileri (ray + liste +
sağ editör) ve yatay altın taban henüz YOK — ilk yatay koşu cihazda yapılacak.

- **Semantik tuzak:** UiAutomation ~1 sn bağlanır; boşta uygulamada Flutter ana ekranın semantik ağacını o pencerede
  göndermiyor → tablet ana ekranı dökümde BOŞ (3,4 KB). Levha/editör/ayarlar DOLU. Bu yüzden `home_locate` tablet ana
  ekranı için 1600 px'lik piksel tablosu (`GEO_1600`) kullanır ve `⋮` levhasıyla doğrular. `dump()` artık boyuta değil
  etiketli düğüm sayısına bakar (boş ağaç da 3,4 KB tutuyordu).
- **Varsayımlar:** "Notların yedeklenmiyor" bandı küçültülmüş ("Sonra" bir kez), ilk kart sabit not, "OLCUM kalem pdf"
  ve "OLCUM cizgi" notları var (yedek bir kez elle yüklenir: `make_dataset.py --ink 40` → Download → Ayarlar →
  Senkronizasyon → Yedekten geri yükle → Diğer → Kök dizinleri göster → İndirilenler; `--hazirlik` bunu betiğe yaptırır).
- **Fiziksel klavye:** tablet "klavye takılı" sanıyor → alana dokunmak sanal klavyeyi AÇMAZ; editör üst çubuğundaki ⌨
  ("Sanal klavyeyi aç") AÇ/KAPA anahtarıdır (açıkken dokunmak kapatır); bir kez açıldıktan sonra alana dokunmak da açar.
  `ensure_ime` bunu halleder; IME kapalıyken BACK notu kapatır → `back_note()`.
- **Huawei kurulum onayı:** `adb install` iki pencere çıkarır ("DEVAM ET", "YÜKLE"); `install()` yalnız ölçüm uygulaması
  için bunları kendisi geçer.
- **Arama → not:** ana ekran aramasından açılan notta başlık eşleşirse not-içi arama çubuğu açılır ve alt araç
  çubuğunu gizler (`close_note_search`).
- **Yön:** `--yon dikey|yatay|mevcut` (`wm user-rotation lock`, bitince `free`); sensörlü döndürme ölçümü bozar.
