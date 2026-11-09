# DEVIR — P01 (F59.1 + F60.1), dal `oto/P01-ek-cizgi`

**Yapılanlar**
- `ccf9d27a` F59.1: `test/support/editor_harness.dart` (`pumpEditor`, `endEditor`, `BuildCounter`,
  `CountingNotesRepository`); `test/note_screen_chrome_test.dart` ona taşındı.
- (bu commit) F60.1: kanıt + düzeltme + belgeler. `test/perf_budget_test.dart` +
  `test/perf_budget/budgets.json` (yalnız S6/S7; P11 kalanları ekler).
  S6 ve S7: kök kurulum 10 → 1, `updateNote` 10 → 1.

**Kök neden / kanıt**
- `note_editor_attachments.dart` `_updateAttachment` → `_mutate(immediate: true)` (çizgi başına kayıt);
  `note_editor_screen.dart` `_sameVisual` `identical(a.attachments, …)` → her çizgide `setState`.
- Düzeltme: `onInkChanged` (`pinned_media_pane.dart` `_inkFor`, `note_images.dart` `_docInkFor`) →
  `_updateAttachmentInk` → `_mutate(inkOnly: true)` (kök yok, debounce'lu).
- Ek tuzak (testte): bayat kutudan gelen sayfa çevirme eski çizgi listesini geri yazıyordu →
  `_withLiveInk` + `_staleInk` (kök build'inde boşalır); gömülü belgede `_docInkSeen`.

**Denenip tutmayan / sapma**
- PDF testte çizilemez (pdfium yok): çizgi `PdfPageBox.ink` denetleyicisine doğrudan işleniyor.
- Planın genel `_sameAttachmentsVisually`'si yazılmadı: geri al / tam ekrandan dönen mürekkep kökü
  kurmaz, bölme bayat kalırdı. Gevşeme yalnız mürekkep yolunda.
- Not paketi (kapanışta tek `onSave`) ve önizleme levhası (`showEmbedPreview`) eski yolda.

**Sıradaki adım**
- Paket bitti. Yürütücü: cihaz A/B (PDF'e yazma), CI sonucu. P11: F59.2'nin kalan senaryoları.

**Açık komut**
- `"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart --reporter failures-only`
