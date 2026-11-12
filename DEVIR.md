# DEVIR — P36 Not ekranı alt çubuğu (DENEYIM F75.1–F75.3) · dal `oto/P36-not-alt-cubuk`

**Yapılanlar**
- F75.1 Kalem sol kapsülde (Biçim · Ekle · Kalem · Ara · Ekler · ☑|Seç); Paylaş kapsülden çıktı; belge notunun ayrı
  kalem düğmesi (`_penToolButton`, `_penWidth`) bu segmentle birleşti. `planEditorBar`: `share` kalktı, 36 dp adımı geldi.
- F75.2 Her segment `MinTapTarget` (48 dp yüksek; yatayda segment + boşluk). `MinTapTarget`'a `minWidth` eklendi.
  İşe yaramayan: kapsül `Container(padding: 3)` iken pay yakalanmadı (Row 40 dp, ata kutu keser) → dolgu Row'un içine.
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
- YENİ KARAR (en güvenli): 360 dp + ekli METİN notunda Kalem sığmıyor (24 dp; ilk turda ☑ kesik çıktı) →
  `planEditorBar` son adımda Kalem'i düşürür (`plan.pen`), ☑/Ekler kalır. Kalem klavye açıkken hızlı satırda.
**Durum:** bitti; commit 95f65b71 (iş), e52670a1 (Kalem düşer + plan), 102d6b1a (AppAlpha + bütçe) — CI yeşil (102d6b1a).
İlk CI kırmızısı: `design_tokens_guard_test` (elle saydamlık; radius/iconSize bütçesi düşmeliydi) → belirteç + bütçe.
Tur (önce/sonra, 266 PNG): değişen yalnız not sahneleri (n1, n2, n4, n1/n4-menu, n4-ekle, n4-ai, e-*); `n4-paylas` çekilmedi.
**Açık:** cihazda A/B (`tool/perf/ab_klavye.py`) YAPILMADI — yürütücünün işi, `[apk]` öncesi şart. Sürüm notu eklenmedi (birleştirmede).
**Komutlar:** `flutter test test/editor_bar_layout_test.dart test/note_accent_consistency_test.dart test/accessibility_test.dart
test/design_tokens_guard_test.dart test/keyboard_jank_guard_test.dart test/perf_budget_test.dart --reporter failures-only` ·
tur: `TOUR_COMPARE=build/tour-once flutter test tool/tour/screen_tour_test.dart`
