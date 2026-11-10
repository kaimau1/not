# DEVİR — P11 Bütçe testleri (kalan) + kalem A/B aracı (F59.2–F59.6)

Dal: `oto/P11-butce-testleri` (main `b2e2332c`'den).

## Yapılanlar
- F59.2/F59.3/F59.4: `test/perf_budget_test.dart`'a S1–S5, S8, S9, S11–S16 eklendi
  (S6/S7 vardı, S10 `note_package_open_test.dart`'ta). Bütçeler bugünkü ölçümle
  `test/perf_budget/budgets.json`'da (`bugun` + `hedef` + `neden`).
  `editor_harness.dart`: `pumpEditor(noteStream:)` (yankı senaryoları).
- Bozma denemesi: `_sameVisual` başına `false &&` → S1, S2, S5, S6, S7 kırmızı; geri alındı.

## Bulgular (düzeltme YOK — ilgili fazın işi)
- S8: 30 maddeli notta İLK klavye açılışında `ItemsEditor` her inset karesinde kuruluyor
  (5 kare → 5 kurulum + 2'şer satır alanı, oturmada 1); 2.–3. tur 0. Kimse onu kirletmiyor
  (ata zinciri temiz) → kendi bağımlılığı/dinleyicisi (bağımlılıklar: MediaQuery,
  _ScrollableScope…). Kök neden aranmadı. Ek A "bugün 0" kısa notta doğru.
- S2 5/15 (hedef 0/0), S3 satır 13, S4 satır 14 (hedef ≤ 2), S9 tuval 2, S14 tuval 1 (hedef 0),
  S12 Dashboard 1 / NoteCard 13 (hedef 0 / ≤ 1), S15 2001, S16 2 belge / 448 925 bayt.

## Sıradaki adım
- F59.5 `tool/perf/ab_kalem.py` + `make_dataset.py --ink 1500`; F59.6 CLAUDE.md satırı;
  plan maddeleri `[x]`, Ek A "Bugün" sütunu, HAFIZA (akicilik) tek satır.

## Komutlar
- `"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart --reporter failures-only`
