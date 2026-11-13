# DEVIR — P49 Sabit ek baştan (dal `oto/P49-sabit-ek`)

**Yapılanlar**
- (e) klavye kasması: pencere boyu tek adımda + hareket boyamada (`Flow`, `_WindowClip`), aşama kurulumsuz (`KeyboardStageWatcher`, keyboard_snap.dart), medya/çubuk/not `build`'de bir kez. S17: PDF editör içi 11→7, dizilen 3→2, geçiş 291→289; görsel 12→8, hareket 59→55. `budgets.json` düşürüldü; bekçi `test/pinned_keyboard_test.dart` "tek adımda".
- P46'ya bulgu: sabit ekli notta ilk klavye açılışında editör alt çubuğundaki `AnimatedSize` (note_editor_screen ~4141/4205/4375) 6 kare Scaffold kutusunu dizdiriyor (S17 `RenderCustomMultiChildLayoutBox`).
- Yapılmadı (ayrı iş): geçiş karesi (289/238) — editör gövdeyi tam boya döndürürken `PinnedMediaPane`'i yeni örnekle kuruyor; medya alt ağacı önbelleği gerek.

- YARIM (analiz temiz, TESTLER KOŞULMADI): çubuk K-O6 + tek ⋮ levhası (`_openSheet`/`_sheet`, `PdfBoxBar.menuActions`, pdf_page_box `_menuActions`), ✏ hep görünür + `_togglePen` senkronu + `onPenOff`, hızlı kalem (`_penQuickTools`: silgi/geri al/yinele/ayar), 1,3× yazı eşiği (`room`), editör bağlantısı `_sheetViewSwitch` (note_editor_media_view; `_showViewSheet` kalktı, `onShowViews` parametresi kalktı).

**Şu anki adım:** YARIM commit'in testleri. Dar çubukta (<600 dp) balon/anahtar artık ⋮ levhasında → şu testler güncellenecek: `test/pinned_bubbles_test.dart` ve `view_mode_switch_test.dart` (`pinned-add-bubble` yerine önce `pinned-media-menu`, sonra `pinned-add-bubble-note/plain` karosu), `page_panel_personalize_test.dart` (⋮ artık levha; metinler aynı), `pinned_pdf_bar_test.dart` (dizgi bekçisi duruyor olmalı), `menus_youtube_test.dart`.

**Sıradaki:** (1) yukarıdaki testleri koş/düzelt + yeni testler: 360/393 dp × 1,3 yazıda PDF çubuğu taşmaz (g); ✏ penActive iken görünür ve `onPenOff` çağırır (b); `_ownPen` iken `pinned-pen-eraser` var (c); levhada `pinned-pdf-pages`. (2) (d) ipuçları: `undo_snackbar.dart`'a `snackBarBottomObstacle` (PenTray dock açıkken bildirim tepsinin üstünde), `stylus_toggle.dart` SnackBar → oturumda durum başına bir kez, `_penModeOpened` (note_editor_screen ~2343) yalnız mesaj değişince. (3) `test/design_tokens_guard_test.dart` koş, `test/design_tokens/budget.json`'ı düşür. (4) tam `flutter analyze`. (5) belgeler: OTOMASYON Kuyruk P49, KUYRUK_AYRINTI durum (K-O7/K-O8 en güvenli = dokunulmadı, "sabah bakılacak"; plandaki kullanıcı kararı K-O7 "yanda" — çelişki not edilsin), OTURTMA F65.1 [x], docs/regresyon_listesi.md, docs/hafiza/ekler_pdf.md + akicilik.md, sürüm notu 13 Kasım (tr+en). (6) CI izle.

**Kök neden / kanıt**
- (e) Klavye kasması: `KeyboardClipWindow` (keyboard_snap.dart:463) `SizedBox(height: shown)`'ı 260 ms `TweenAnimationBuilder` ile kare kare değiştiriyor → bölmenin Column'u ve alttaki editör gövdesi her karede diziliyor (kasma listesi §6). Taban: `flutter test test/keyboard_jank_guard_test.dart --plain-name sabit` → PDF ilk 74 / geçiş 291 / hareket 70 (editör içi 11) / dizilen 3; görsel 63 / 240 / 59 (12) / 2.
- (b) `pinned-pen` düğmesi `!widget.penActive` iken çiziliyor (pane:1263) → yüzen düğme kalem kipini açınca kayboluyor; `_ownPen` yerel, `InkToolMemory.autoStylus`'a yazmıyor.
- (d) `stylus_toggle.dart:125` her dokunuşta SnackBar; `_penModeOpened` (note_editor_screen:2343) her açılışta; alttaki `PenTray dock`'u örtüyor.
- Ölü kod: çubuktaki salt okunur `pinned-bubbles-toggle` IconButton (koşulu hiç sağlanmaz).

**Tasarım (uygulanacak)**
- Pencere: boy yalnız klavye görününce (kare 0) ve bitince değişir; aradaki hareket `Flow` (boyama) + `ClipRect(reclip)`; alt parça (çubuk+not) `Flow` ile kayar. Medya ve çubuk `build()`'de bir kez kurulur (LayoutBuilder yeniden koşunca aynı örnek).
- Çubuk (K-O6): dar (<600) `⛶ · [oynatma] · tutamak · Not al · ✏ · ⋮`; geniş: + yer imi, balon, görünüm anahtarı. TEK ⋮ = bizim levha (`SheetHeader`/`SectionLabel`/`SheetTile`/`DestructiveRow`): Görünüm anahtarı · Balonlar (Balon/Açık metin/gizle-göster) · PDF (sayfalara göz at, yer imi…) · ek işleri · Kaldır. `PdfBoxBar.menuActions` eklenecek.
- ✏ hep görünür, açık = `_policy.layerActive`; aç/kapa `InkToolMemory.saveAutoStylus` + yeni `onPenOff` (editör kalem kipini kapatır). `_ownPen && !penActive` iken çubukta hızlı kalem: silgi · geri al · yinele · ayarlar.
- İpuçları: `snackBarBottomObstacle` (kalem tepsisi açıkken bildirim üstüne çıkar); yüzen düğme ve kalem kipi ipucu oturumda durum değişince bir kez.
- K-O7/K-O8: en güvenli (dokunma / tek sabit ek) + "sabah bakılacak".

**İşe yaramayanlar:** yok (henüz).

**Sıradaki adım:** pane yeniden yazımı → testler (pinned_*, view_mode_switch, page_panel_personalize, menus_youtube, keyboard_jank_guard, design_tokens_guard) → budgets.json S17 `sabit_*` düşür → belgeler + sürüm notu → CI.

**Test:** `"C:/src/flutter/bin/flutter.bat" test test/keyboard_jank_guard_test.dart --plain-name sabit` · `flutter analyze`
