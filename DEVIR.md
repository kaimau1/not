# DEVIR — oto/PA0-butce (P62 PA0, docs/plan_tasarim_A.md §8.3)

## Yapılanlar
- Boy animasyonu mandalı `test/jank_patterns_guard_test.dart` (9 dosyada `AnimatedSize(` = 2: dashboard_widgets 1, calendar_screen 1) — commit 1
- S29–S33, S35, S36 `test/perf_budget_test.dart` + `budgets.json` — commit 2. `_pumpHome`a `overrides`, `notices`; yeni yardımcılar `_pumpCalendar` (S22 düzeneği taşındı, S22 değeri aynı 1/509/508), `_settingsApp`, `_resizedFrames`.

- Tur: `/calendar` yolu + `takvim-ajanda`, `takvim-ajanda-ay` (yalnız dar ekranda dokunulur; genişte ay hep açık, sahne geçilir) — commit 3

## Ölçülen tabanlar (2026-11-14, bugünkü kod)
- S29 ilk kare 367 / sonraki en ağır 37 / toplam 488; ilk karede 2 satır (yayma çalışıyor)
- S30 kart 0 / pano 0 / en ağır kare 341
- S31 kart 0 / pano 0 / kare 28 / klavye karesi 10 (R5 doğrulandı)
- S32 ızgara boy karesi 26 / kart 0 (hipotez ~24 doğru: R1 gerçek dizilim yükü)
- S33 kart 0 / pano 0 / kare 16
- S35 liste boy karesi 28 (hipotez ~24 doğru: R2 gerçek)
- S36 en ağır kare 673 / toplam 1875 (ilk kare ai 551 / sound 673, sonraki 65 / 262) — hedef (≤ S29 en ağır karesi) TUTMUYOR

## Sıradaki
- OTURTMA Ek A satırları, plan §7.3 "beklenen bugün" sütunu, PA0 [x]

## Test
`flutter test test/perf_budget_test.dart --reporter failures-only` · `flutter test test/jank_patterns_guard_test.dart`
