# DEVIR — P39 Hız hissi (DENEYIM F78.1–F78.5) · dal `oto/P39-hiz-hissi`

## Yapılanlar
- F78.1 (K-D8, `0144b28f`, TEK commit — geri alınabilir): `core-splashscreen`; `LaunchTheme` =
  `Theme.SplashScreen`; `MainActivity` ilk Flutter karesine dek tutar (3 sn emniyet).
  Debug APK derlendi. **Cihazda doğrulanmadı.**
- F78.3 (`f7f6f65a`): 20 içerik halkası `DelayedSpinner`; `MediaLoadingCover` (sabit/gömülü
  PDF, sabit video); yerel görsel `fadeInFrame`. Döküm `docs/deneyim/yukleme.md`.
- F78.5 (`4161052d`): kanıt yeşil, kod yok; `test/optimistic_actions_test.dart`.
- F78.2: `tool/perf/prof_new.py` yazıldı (ölçülmedi). F78.4: `docs/deneyim/dokunus.md` +
  3 yüzeye `PressScale`.

## Kök neden / kanıt
- Beyaz açılış: `docs/hafiza/arayuz.md` "Beyaz açılış (ÇÖZÜLMEDİ)". Flutter zaten ilk Android
  çizimini geciktiriyor; kazanç MIUI'de ancak cihazda görülür.
- İyimserlik: UI yolları `updateFields`/`batchUpdate`'i beklemiyor (`dashboard_selection.dart`,
  `note_actions_sheet.dart`); gri kutu `pdf_page_box.dart` `_document(null)` + sabit bölme
  `AfterRouteTransition` yer tutucusuydu.

## Denenip bırakılan
- Editör kökündeki 2 halka ve editör içi dokunuş yüzeyleri: Ek D çiti (P20/P36), dokunulmadı.

## Cihazda ölçülecek (yürütücü) — KALANLAR §2 K1–K4
- F78.1: soğuk açılış `screenrecord` + `tool/perf/video.py` beyaz kare sayısı (önce/sonra);
  kalıyorsa `git revert 0144b28f`. Güncelleme sonrası açılış + `.olcum` kimliği.
- F78.2: `cd tool/perf && python -u prof_new.py taban` (hedef ortanca ≤ 450 ms) → sayıyı plana yaz.
- A/B: `ab_liste.py` (kart görseli solması), `ab_klavye.py`.

## Kullanıcıya görünen (sürüm notu için)
- Açılışta beyaz parlama yerine uygulama simgeli açılış ekranı.
- Kısa süren yüklemelerde dönen halka artık görünmüyor (0,3 sn'den uzun sürerse belirir).
- Sabit PDF/video açılırken gri kutu yerine belgenin küçük resmi.
- Kart ve görüntüleyicide görseller yumuşakça belirir.
