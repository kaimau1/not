# DEVIR — P49 Sabit ek baştan (dal `oto/P49-sabit-ek`)

**Yapılanlar**
- (e) klavye kasması: pencere boyu tek adımda + hareket boyamada (`Flow`, `_WindowClip`), aşama kurulumsuz (`KeyboardStageWatcher`, keyboard_snap.dart), medya/çubuk/not `build`'de bir kez. S17: PDF editör içi 11→7, dizilen 3→2, geçiş 291→289; görsel 12→8, hareket 59→55. `budgets.json` düşürüldü; bekçi `test/pinned_keyboard_test.dart` "tek adımda".
- P46'ya bulgu: sabit ekli notta ilk klavye açılışında editör alt çubuğundaki `AnimatedSize` (note_editor_screen ~4141/4205/4375) 6 kare Scaffold kutusunu dizdiriyor (S17 `RenderCustomMultiChildLayoutBox`).
- Yapılmadı (ayrı iş): geçiş karesi (289/238) — editör gövdeyi tam boya döndürürken `PinnedMediaPane`'i yeni örnekle kuruyor; medya alt ağacı önbelleği gerek.

**Şu anki adım:** çubuk (K-O6) + tek ⋮ levhası + kalem senkronu/hızlı kalem + ipuçları.

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
