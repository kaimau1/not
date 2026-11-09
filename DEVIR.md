# DEVIR — P01 (F59.1 + F60.1), dal `oto/P01-ek-cizgi`

**Yapılanlar**
- F59.1: `test/support/editor_harness.dart` (`pumpEditor`, `endEditor`, `BuildCounter`,
  `CountingNotesRepository`); `test/note_screen_chrome_test.dart` ona taşındı (8 test yeşil).

**Şu anki adım**
- F60.1 (a) kanıt ÜRETİLDİ (commit'lenmedi, çalışma ağacında): `test/perf_budget_test.dart` +
  `test/perf_budget/budgets.json` — bugünkü kodda S6 = kök kurulum 10 / updateNote 10,
  S7 = 10 / 10 (hedef ≤ 1 / ≤ 1, kırmızı).
- Sırada (b): düzeltme.

**Kök neden / kanıt**
- `note_editor_attachments.dart:1070` `_updateAttachment` → `_mutate(immediate: true)` (çizgi başına kayıt).
- `note_editor_screen.dart:1762` `_sameVisual` `identical(a.attachments, b.attachments)` → her çizgide `setState`.
- Mürekkep bildirenler: `pinned_media_pane.dart:320` (`_inkFor`), `note_images.dart:391` (`_docInkFor`).

**Plan (b)**
- `_updateAttachmentInk` (debounce'lu, `_mutate(..., inkOnly: true)`); `_sameVisual` mürekkep-dışı ek
  karşılaştırması YALNIZ bu yoldan (geri al / tam ekrandan dönüş kökü kurmaya devam etsin, yoksa bölme bayat kalır).
- `PinnedMediaPane.onInkChanged`, `NotePageCanvas.onInkChanged` (yoksa `onChanged`).
- `note_images.dart` `_docInkFor`: `_inkSeen` benzeri kimlik denetimi (bayat `a.ink` ile `replace` çizgileri silmesin).
- Not paketi: çizgi başına bildirmiyor (yalnız kapanışta `onSave`) — dokunulmayacak.

**Denenip tutmayan**
- PDF testte çizilemez (pdfium yok): çizgi `PdfPageBox.ink` denetleyicisine doğrudan işleniyor.

**Açık komut**
- `"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart --reporter failures-only`
