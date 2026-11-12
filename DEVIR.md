# DEVIR — P36 Not ekranı alt çubuğu (DENEYIM F75.1–F75.3) · dal `oto/P36-not-alt-cubuk`

**Yapılanlar**
- F75.1 Kalem sol kapsülde (Biçim · Ekle · Kalem · Ara · Ekler · ☑|Seç); Paylaş kapsülden çıktı; belge notunun ayrı
  kalem düğmesi (`_penToolButton`, `_penWidth`) bu segmentle birleşti. `planEditorBar`: `pen`/`share` kalktı, 36 dp adımı geldi.
- F75.2 Her segment `MinTapTarget` (48 dp yüksek; yatayda segment + boşluk). `MinTapTarget`'a `minWidth` eklendi.
- F75.3 Renkli notta iki kapsül, simgeler, etkin segment, "+" rozeti notun tonunda (`_barInk`/`_barPage`).
- F73.1-2 (P34'ten devir): "+" rozeti `primaryContainer`.

**Kök neden / kanıt**
- Yatay pay 48 dp olsaydı sonraki segmentin alanı öncekinin görünen kutusuna 1 dp taşardı (segment 40, boşluk 3; Row
  çocukları tersten dener) → `min_tap_target.dart` `minWidth`; bekçi `test/accessibility_test.dart` "not alt çubuğu".
- Çubuk bağlamı `NoteAccent`'in ÜSTÜNDE (`maybeOf` bulamaz) → renk build'de alana yazılır: `note_editor_screen.dart`
  `_barInk = noteAccent; _barPage = background`.

**Kapsam çiti dışına taşan (zorunlu sonuç, sabah bakılacak)**
- `lib/core/a11y/min_tap_target.dart` (`minWidth`), `lib/core/personalize.dart` (`UiItem.barPen`),
  `personalize_screen.dart` (Paylaş satırı → Kalem), `note_editor_actions.dart` (`_barHasShare` kalktı).
- Tur sahnesi `n4-paylas` artık "dokunulacak öğe yok" (Paylaş çubukta değil) — P37 turundan önce sahne ⋮ üzerinden açılmalı.
- 360 dp + ekli METİN notu (Biçim·Ekle·Kalem·☑·Ekler): 24 dp sığmıyor, kapsül kendi içinde kayar (eski son çare).

**Açık**
- Cihazda A/B (`tool/perf/ab_klavye.py`) YAPILMADI — yürütücünün işi; `[apk]` öncesi şart.

**Komutlar**
- `flutter test test/editor_bar_layout_test.dart test/note_accent_consistency_test.dart test/accessibility_test.dart
  test/page_panel_personalize_test.dart test/keyboard_jank_guard_test.dart test/perf_budget_test.dart --reporter failures-only`
- Tur: `TOUR_COMPARE=build/tour-once flutter test tool/tour/screen_tour_test.dart`
