# tool/perf — telefonda akıcılık ölçümü

`AKICILIK_PLANI.md`'deki sayılar bu araçlarla alındı. Python 3 + Pillow, `adb`
(yol `ADB` ortam değişkeniyle), USB hata ayıklaması açık telefon. Çıktılar
`PERF_OUT` (yoksa sistem geçici klasörü `notlar_perf/`) altına — depoya düşmez.

| Dosya | Ne yapar |
|---|---|
| `perf.py` | adb yardımcıları (`wake`, `tap`, `swipe`, `text`, `front`, `find`/`tap_label` uiautomator), SurfaceFlinger kare toplayıcı (`SF`, `analyze`), atrace (`atrace_start/stop`, `parse_sched`, `burst_stats`, `sections`), içe aktarma (`open_import`, `wait_import`) |
| `scen.py` | release senaryoları: `scroll` (12 fırlatma), `open_close` (not aç/kapa ×3), `typing`, `measure_sections` |
| `hitch.py` | SF karelerini atrace saatine hizalar (`deliverInputEvent eventTimeNano`), her takılmada ana iş parçacığı meşguliyeti |
| `vmsvc.py` | profil derlemesinin Dart VM servisi (HTTP GET): zaman çizelgesi, CPU örnekleri, widget build profili |
| `prof_oc.py`, `prof_scroll.py`, `prof_type.py` | profil uygulamasında aç/kapa, kaydırma, yazma + kök neden dökümü |
| `make_dataset.py` | Keep Takeout zip'leri: 240 not + 4 adlı stres notu (`OLCUM …`) |

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
