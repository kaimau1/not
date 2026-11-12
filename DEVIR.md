# DEVIR — P43 (oto/P43-hiz-olcum) · LİMİT %95'te durdu

## Yapılanlar
- F82.1–F82.3 bitti (commit 1–3; CI yeşil 8f38bcaf). Bulgular KUYRUK_AYRINTI §P46/§P49.
- main birleşti (580e40b1).
- F81.1–F81.4 `tool/perf/ab_hepsi.py` yazıldı (13 evre, A,B ×3, ortanca, KARAR, `--altin`, `--altin-yaz`, `docs/perf/gecmis.csv`).
- F81.5 CLAUDE.md ÖLÇÜM KAPISI + OTOMASYON 6. adım + README → ab_hepsi.py.

## Nerede kaldım
- Tam A/B koşusu başlatıldı, sonuç ÇIKMADAN durduruldu (telefon 43,5 °C, AC şarjda; betik soğumayı bekliyordu).
  `docs/perf/altin_taban.json` ve `gecmis.csv` HENÜZ YOK. HIZ_PLANI F81 maddeleri `[x]` yapılmadı.
- Telefonda hazırlık yapıldı: ölçüm uygulamasına "OLCUM kalem pdf" (sabit PDF) + "OLCUM kalem bos" geri yüklendi.

## Ham deneme (tek koşu, kurulu olan APK, 40,4 °C — GEÇERSİZ sıcaklık; yalnız betiğin çalıştığının kanıtı)
UI ms / LAYOUT ms / kare: acilis 306.6/267.6/18 (ilk kare 61 ms) · liste 1447/826/293 · menu 318/148/52 ·
arama 591/434/17 · klasor 288/123/51 · yeni_not 468/133/91 · not_ac 217/134/26 · kb 424/79/120 ·
yaz 975/244/199 · not_kapa 255/120/41 · sabit_ac 1084/249/163 · sabit_kay 974/134/221 · sabit_kb 2431/341/372

## İşe yaramayanlar / tuzaklar
- Aramadan açılan not, not içi aramayı açar → ölçüm ana listeden (ilk kart) + sabit PDF kaydırarak bulunur.
- `notlar://note/<id>`: geri yüklenen notun kimliği değişiyor ("Not bulunamadı").
- Ekran ~30 sn'de kilitleniyor: her dokunuştan önce `ready()`. Git Bash'te `adb push` için `MSYS_NO_PATHCONV=1`.
- "Sayfa 1 / 1" etiketi her zaman gelmiyor → bölme "Tam ekran" çubuğundan bulunur.

## Sıradaki adım
Telefon < 37 °C iken (tercihen şarjdan çıkarılmış):
`cd tool/perf && PYTHONIOENCODING=utf-8 python -u ab_hepsi.py C:/Users/sena/Desktop/ab_A_9c837495.apk C:/Users/sena/Desktop/ab_B_P39_02ebd989.apk --etiket-a altin_9c837495 --etiket-b P39_02ebd989 --commit 9c837495/02ebd989 --altin-yaz --altin`
(~40 dk) → altin_taban.json + gecmis.csv commit, HIZ_PLANI F81.1–F81.5 `[x]`, kabul testi (aynı APK A=B → GEÇTİ).

## Test
`C:/src/flutter/bin/flutter.bat test test/perf_budget_test.dart test/jank_patterns_guard_test.dart test/keyboard_jank_guard_test.dart test/editor_leak_test.dart --reporter failures-only`
