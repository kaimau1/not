# DEVIR — P50 Düzenleme modu baştan + hızlı menü (dal `oto/P50-duzenleme`)

Main'de ZATEN vardı (yeniden yapılmadı): hızlı menünün kendi düzenleme levhası
(`quick_row_editor.dart`, ⋮ + Kişiselleştir), alt çubuk sırala/ekle/çıkar (P57).

## Yapılan (her biri ayrı commit)
- [x] Alt çubuk: düğme iki kapsül arasında taşınır (`UiPrefs.barSides` /
  `withBarSide`; Ayarlar → Kişiselleştir → alt çubuk satırındaki ok).
- [x] Düzenleme modu anında uygular: `Personalize.toggle` hemen yazar; şerit
  Geri al (`revert`) / Bitti (`done`); `save`/`cancel` kalktı.
- [x] Üst çubuk: Ana sayfa + Tam ekran sarıldı (`UiItem.topHome/topFullscreen`).
- [x] Belgeler: OTOMASYON, KUYRUK_AYRINTI §P50, regresyon listesi, hafıza
  (editor.md), sürüm notu TR+EN, KALANLAR L13.

Testler: `page_panel_personalize_test`, `editor_bar_customize_test`,
`editor_top_customize_test`, `jank_patterns_guard_test` (kök setState 53).

## Yapılmadı / sabah bakılacak
- Ana ekran (`dashboard_*`) sarmaları: P56 çiti — dokunulmadı.
- Üst çubuk SIRALAMA listesi: `note_editor_screen.dart` yapısı P20'nin.
- Düzenleme modunda yerinde sürükle-sırala yok (sıra Ayarlar listesinde).
- KARAR (en güvenli): "Geri al" modu kapatmaz, yalnız açılış anına döner.
- Haptik: `customizable.dart`'taki `HapticFeedback.selectionClick` duruyor
  (P38 `AppHaptics` main'de yok) — P38 birleşince göç etsin.
- Cihazda doğrulanmadı; `[apk]` öncesi A/B ölçümü (`ab_hepsi.py --altin`) yapılmadı.
