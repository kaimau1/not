# DEVIR — P14 Mürekkep çizimi v2 (oto/P14-murekkep-cizim)

## Yapılanlar
- F62.1 (d8cd454c) etkin çizgi ayrı katman: `InkController.committedRev`/`activeStroke`/`strokesOf(page)` (ink_layer.dart, `notifyListeners` → `_checkCommitted`), `CommittedInkPainter` + `ActiveInkPainter`, `InkPageLayer` Stack[RepaintBoundary(committed), active]. S15 2001 → 1.
- F62.2 (d8cd454c) tek çizim yolu `viewers/ink_stroke_paint.dart` (`paintInkStroke`, Expando önbellek, orta nokta yumuşatma, basınçlı = kapsül dolgu, saveLayer yok).
- F62.5 dolma kalem: `InkPen.fountain` (alfa 0xFE, `fixedOpacity`, `inkIsFountain`), `fountainRadii`, tepside `PenTrayTool.fountain` + `pen_icons._fountain`, l10n `penFountain`.
- Testler: `test/ink_paint_v2_test.dart`, `perf_budget_test.dart` S15.

## Yapılmadı
- F62.0 cihaz ölçümü (yürütücü). F62.3 F62.0 kapısı bekliyor (sabah bakılacak).

## Açık
- Altın görüntü gözle onayı (yumuşatılmış köşeler, kapsül dolgu) ve cihazda kalem A/B.

## Komutlar
- `flutter test test/ink_paint_v2_test.dart test/perf_budget_test.dart --reporter failures-only`
