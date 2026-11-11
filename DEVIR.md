# DEVIR — P29 uzun bas (F60.S11)

Dal: `oto/P29-uzun-bas` (taban origin/main 80c7528d). Durum: kod + test bitti, CI bekleniyor.

- `_HoldToSelect` (items_editor_widgets.dart): iki aşama + dolum halkası
  (AnimationController → CustomPaint, RepaintBoundary; ağaç şekli sabit, editör setState yok).
  650 ms → `_holdSelectText` (hafif titreşim + tüm yazı seçili), 1250 ms → `_holdSelect` (titreşim + madde seç).
  Halka 150 ms basılı kalmadan çizilmez (kısa dokunuşta yanıp sönmesin). Seçim kipinde kapalı (`enabled`).
- Test: `test/items_editor_hold_select_test.dart` 10/10 (iki aşama, titreşim sayısı, halka çizimi, diğer satırlar `identical`).
- perf_budget, keyboard_jank_guard, items_editor_* yeşil; `flutter analyze` temiz.
- Kalan: cihaz A/B (`tool/perf/ab_klavye.py`) yürütücüde; cihazda doğrulanmadı.
