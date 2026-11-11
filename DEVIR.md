# DEVIR — P14 Mürekkep çizimi v2 (oto/P14-murekkep-cizim)

## Yapılanlar
- F62.1 etkin çizgi ayrı katman: `InkController.committedRev`/`activeStroke`/`strokesOf(page)` (ink_layer.dart, `notifyListeners` → `_checkCommitted`), `CommittedInkPainter` + `ActiveInkPainter` (eski `_InkOverlayPainter`/`_HoverLook` kalktı), `InkPageLayer` ListenableBuilder yerine Stack[RepaintBoundary(committed), active].
- F62.2 tek çizim yolu `viewers/ink_stroke_paint.dart` (`paintInkStroke`, Expando önbellek, orta nokta yumuşatma, basınçlı = kapsül dolgu, saveLayer yok). `InkPainter.paint` buna gider.
- S15 bütçesi 2001 → 1 (`test/perf_budget/budgets.json`), test `perf_budget_test.dart` S15 artık denetleyici + iki boyayıcıyla ölçer.
- Yeni test: `test/ink_paint_v2_test.dart`.

## Sırada
- F62.5 dolma kalem (InkPen.fountain, tepside 5. kalem, l10n, sürüm notu).
- F62.0 cihaz ölçümü (yürütücü), F62.3 yapılmadı: F62.0 kapısı ölçülmedi (sabah bakılacak).

## Komutlar
- `flutter test test/ink_paint_v2_test.dart test/perf_budget_test.dart --reporter failures-only`
