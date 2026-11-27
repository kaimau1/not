part of 'note_editor_screen.dart';

extension _NoteEditorScaffoldBuild on _NoteEditorScreenState {
  Widget _buildLoadingScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: _loadFailed
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 40,
                      color: _themeOf(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noteNotFound,
                      textAlign: TextAlign.center,
                      style: _themeOf(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _closeEditor,
                      child: Text(l10n.back),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  PreferredSizeWidget _buildEditorTopBar(
    BuildContext context, {
    required AppLocalizations l10n,
    required Note note,
    required EditorChromePalette chrome,
    required Color? noteAccent,
    required double toolbarHeight,
    required bool readingColumn,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(toolbarHeight),
      // Bölmenin genişliği: tarih okuma sütunuyla hizalı (F38.2).
      // `_`: `_themeOf` ekranın kendi bağlamından okur.
      child: LayoutBuilder(
        builder: (_, box) {
          final rawLeading = _listLeading(l10n);
          final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
          final leadingWidget =
              rawLeading ??
              (chrome.topBarPills && canPop ? const BackButton() : null);
          final appBarLeading = leadingWidget != null && chrome.topBarPills
              ? EditorTopPill(
                  key: const ValueKey('editor-top-leading-pill'),
                  fill: chrome.topPillFill,
                  border: chrome.topPillBorder,
                  circle: true,
                  child: leadingWidget,
                )
              : leadingWidget;
          final Widget idleMeta = note.updatedAt == null && note.tags.isEmpty
              ? _bareStatusBadges
              : Customizable(
                  id: UiItem.editorDate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ETİKETLER TARİHİN SOLUNDA (kullanıcı isteği
                      // 2026-11-05): gövdedeki çip şeridi yalnız etiket
                      // için bir satır harcıyordu. Çok etiket yana kayar;
                      // dokununca "Etiketi kaldır".
                      if (note.tags.isNotEmpty)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: EditorBarTags(
                              tags: note.tags,
                              accent: chrome.topBarPills
                                  ? chrome.topPillInk
                                  : noteAccent,
                              removeLabel: l10n.tagRemove,
                              onRemove: _removeTag,
                            ),
                          ),
                        ),
                      // Tarih kısa (bkz. [editorBarDate]); etiketler
                      // yer isteyince o kesilmesin diye esnek değil, tavanlı.
                      if (note.updatedAt != null)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 96),
                          child: Text(
                            editorBarDate(note.updatedAt!, DateTime.now()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: AppWeight.medium,
                              color: chrome.topBarPills
                                  ? chrome.topPillInk.withValues(
                                      alpha: AppAlpha.strong,
                                    )
                                  : _themeOf(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                            ),
                          ),
                        ),
                      _starBadge,
                      _urgentBadge,
                    ],
                  ),
                );
          final Widget styledIdle = !chrome.topBarPills
              ? idleMeta
              : EditorTopPill(
                  key: const ValueKey('editor-top-title-pill'),
                  fill: chrome.topPillFill,
                  border: chrome.topPillBorder,
                  child: note.updatedAt != null || note.tags.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.m,
                            vertical: AppSpace.xs,
                          ),
                          child: idleMeta,
                        )
                      : idleMeta,
                );
          final actionItems = <Widget>[
            // SIRA kullanıcının (P20 M8, [UiPrefs.topOrder]); sabit olanlar:
            // ⌨ ve ortak düzenleyen Ana sayfa yuvasının ardında, ⋮ en sonda.
            for (final id in UiPrefs.orderOf(UiItem.topDefault, _topOrder))
              ...switch (id) {
                UiItem.topHome => [
                  // ANA SAYFAYA DÖN (F28.3): geniş ekranda/web'de ray bu sırada
                  // çekmece ya da gizli; tek dokunuşla `/`. Telefonda yok.
                  if (MediaQuery.sizeOf(context).width >= kRailBreakpoint &&
                      !_secondary)
                    _hideWhileTyping(
                      note,
                      Customizable(
                        id: UiItem.topHome,
                        child: IconButton(
                          key: const ValueKey('editor-home'),
                          tooltip: '${l10n.goHome} (Alt+Home)',
                          icon: const Icon(Icons.home_outlined),
                          onPressed: () => goHome(ref, GoRouter.of(context)),
                        ),
                      ),
                    ),
                  // ⌨ SANAL KLAVYE: yalnız fiziksel klavye takılıyken (tablet
                  // bulgusu 2026-11-07); o sırada sanal klavye kendiliğinden
                  // açılmaz (bkz. [HardKeyboard]).
                  ValueListenableBuilder<bool>(
                    valueListenable: HardKeyboard.present,
                    builder: (context, present, _) => !present
                        ? const SizedBox.shrink()
                        : ValueListenableBuilder<bool>(
                            valueListenable: HardKeyboard.softWanted,
                            builder: (context, soft, _) => IconButton(
                              key: const ValueKey('editor-soft-keyboard'),
                              tooltip: soft
                                  ? l10n.softKeyboardHide
                                  : l10n.softKeyboardShow,
                              isSelected: soft,
                              icon: const Icon(Icons.keyboard_outlined),
                              selectedIcon: const Icon(
                                Icons.keyboard_hide_outlined,
                              ),
                              onPressed: _toggleSoftKeyboard,
                            ),
                          ),
                  ),
                  // Ortak notta başka biri düzenliyorsa (F4.1).
                  NotePresenceIndicator(
                    noteId: widget.noteId,
                    ownerId: widget.ownerId,
                  ),
                ],
                UiItem.topSync => [
                  // KÖK NEDEN (kasma): bu akış `build`'in en başında izleniyordu.
                  // `pendingWrites` her kayıtta false→true→false gidiyor, yani
                  // yazarken (debounce 0,5 sn / en geç 3 sn) düzenli aralıklarla
                  // 4000 satırlık editör build'i BAŞTAN koşuyordu — üstelik
                  // tetikleyici Riverpod olduğu için `_mutate`'in "saf yazım"
                  // kısayolu ve akış yankısı koruması ikisi de devreye giremiyordu.
                  // Abonelik artık yalnız BU İKONA ait.
                  Customizable(
                    id: UiItem.topSync,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final owner = widget.ownerId;
                          final pending =
                              ref
                                  .watch(
                                    owner == null
                                        ? pendingWritesProvider(widget.noteId)
                                        : ownedPendingWritesProvider((
                                            ownerId: owner,
                                            noteId: widget.noteId,
                                          )),
                                  )
                                  .value ??
                              false;
                          // Yalnız bu cihazdaki not: bulut simgesi yerine telefon.
                          // Misafir hesabın notu da (F60.4): ana ekran ve hesap
                          // levhası "yalnız bu cihazda" diyor, burada
                          // "Senkronize" yazıyordu.
                          if (owner == null &&
                              (ref.watch(isAnonymousProvider) ||
                                  (ref
                                          .read(notesRepositoryProvider)
                                          ?.isLocal(widget.noteId) ??
                                      false))) {
                            return Tooltip(
                              message: l10n.localOnlyBadge,
                              child: Icon(
                                Icons.cloud_off_outlined,
                                size: AppIconSize.s,
                                color: _editorTertiary(context),
                              ),
                            );
                          }
                          // LITE: değişiklik aralıklı buluta gider; simge bunu
                          // söyler, dokunuş "şimdi eşitle" (bkz. [_syncNowLite]).
                          if (owner == null && ref.watch(liteSyncProvider)) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: _liteHeldN,
                              builder: (context, held, _) => IconButton(
                                key: const ValueKey('editor-lite-sync'),
                                tooltip: held
                                    ? l10n.liteSyncHeld
                                    : pending
                                    ? l10n.syncPending
                                    : l10n.synced,
                                iconSize: AppIconSize.s,
                                visualDensity: VisualDensity.compact,
                                onPressed: held ? _syncNowLite : null,
                                disabledColor: _themeOf(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(
                                      alpha: pending
                                          ? AppAlpha.strong
                                          : AppAlpha.muted,
                                    ),
                                color: _themeOf(context).colorScheme.primary,
                                icon: Icon(
                                  held || pending
                                      ? Icons.cloud_upload_outlined
                                      : Icons.cloud_done_outlined,
                                ),
                              ),
                            );
                          }
                          return Tooltip(
                            message: pending ? l10n.syncPending : l10n.synced,
                            child: Icon(
                              pending
                                  ? Icons.cloud_upload_outlined
                                  : Icons.cloud_done_outlined,
                              size: AppIconSize.s,
                              color: _themeOf(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: pending ? 0.9 : 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                UiItem.topUndo => [
                  // Geri al: son değişikliği (yazma dizisi, madde işaretleme, görsel
                  // taşıma, AI ile değiştirme...) tek dokunuşta iptal eder. Yığın
                  // boşken pasif durur — düğmenin yerini korur ki araç çubuğu
                  // oynamasın.
                  // SABİTLEME üst barda, AÇIK düğme olarak (kullanıcı isteği:
                  // "sabitleme butonunu açığa koy görülsün"). ⋯ menüsündeyken hem
                  // bulunması hem durumunun okunması iki dokunuş istiyordu;
                  // başlıktaki küçük raptiye göstergesi yalnız DURUMU söylüyor,
                  // dokunulabilir değil.
                  // **ORTAK ÇALIŞAN** (kullanıcı isteği 2026-09-22: "ortak not
                  // butonu keepteki gibi"). Keep'teki yeri: notun kendi
                  // araçlarının yanında, tek dokunuşla. Paylaşılmışsa simge
                  // doluya döner ve kişi sayısını rozetle gösterir — notun
                  // başkalarına açık olduğu, menüye girmeden görünsün.
                  // Abonelik yalnız bu düğmede (bkz. yukarıdaki kasma notu).
                  // SIRA (2026-10-11 düzeni): önce DÜZENLEME geçmişi (geri al /
                  // yinele, yan yana), sonra notun durumu (sabitle, ortak
                  // çalışan), en sağda ⋮. Eskiden geri al, raptiye ile hesap
                  // makinesinin arasına sıkışmıştı.
                  // GERİ GETİR (yinele) HEP GÖRÜNÜR (kullanıcı isteği 2026-10-30:
                  // "geri al gibi geri getir de olsun"): eskiden yalnız
                  // kullanılabilirken beliriyordu, kullanıcı varlığını bilmiyordu.
                  // İkisi tek kişiselleştirme öğesi; boşken ikisi de soluk.
                  // ÜST ALANDA SADELEŞME (kullanıcı isteği 2026-11-05): geri al /
                  // yinele yalnız bu oturumda geri alınacak bir şey olunca
                  // belirir (ikisi birlikte — yinele hâlâ geri alın yanında
                  // görünür); not yalnız açılıp okunurken çubukta iki soluk
                  // düğme durmaz.
                  // Yazarken geri al / yinele HEP görünür (2026-11-08); okurken
                  // yalnız geri alınacak bir şey varken.
                  // Yığın durumu [_undoN]'dan: geri al/yinele kökü kurmaz (P20 M3).
                  ValueListenableBuilder<(bool, bool)>(
                    valueListenable: _undoN,
                    builder: (context, undoState, _) {
                      final (canUndo, canRedo) = undoState;
                      final undo = Customizable(
                        id: UiItem.topUndo,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // SIKI İKİLİ (kullanıcı isteği 2026-11-08: "geri al
                            // ileri al çok yer kaplıyor, arası boş"): 48 → 36 dp
                            // genişlik, aralarında boşluk yok; yükseklik 48 kalır.
                            IconButton(
                              tooltip: l10n.undo,
                              icon: const Icon(Icons.undo),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 48,
                              ),
                              onPressed: canUndo ? _undo : null,
                            ),
                            // YİNELE YALNIZ KULLANILABİLİRKEN (kullanıcı isteği
                            // 2026-11-19: "ileri al, geri alınmadıysa görülmesine
                            // gerek yok"): soluk düğme hızlı satırı daraltıyordu.
                            if (canRedo)
                              IconButton(
                                key: const ValueKey('editor-redo'),
                                tooltip: l10n.redo,
                                icon: const Icon(Icons.redo),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 48,
                                ),
                                onPressed: canRedo ? _redo : null,
                              ),
                          ],
                        ),
                      );
                      return KeyboardSwitch(
                        open: undo,
                        closed: (canUndo || canRedo) ? undo : null,
                      );
                    },
                  ),
                ],
                UiItem.topPin => [
                  // SABİTLEME + NOTTA ARA: başlık üst çubuktayken de (sabit medya
                  // veya belge notu) aynı sırada görünür; tüm not tiplerinde yeri
                  // değişmez.
                  _hideWhileTyping(note, _topPinAndSearch),
                ],
                UiItem.topFullscreen => [
                  // HESAP MAKİNESİ ⋮ menüsünün hızlı satırında (2026-10-11):
                  // üst çubuk notun DURUMUNA ayrıldı — geri al/yinele, sabitle,
                  // ortak çalışan. Araçlar ⋮'te ve alt çubukta.
                  // Yıldız ve sabitleme düğmeleri ⋯ menüsüne taşındı; durumları üst
                  // barın başlık alanındaki göstergelerden okunuyor.
                  // ⋮ artık açılır menü değil, iki sütunlu levha açar
                  // (bkz. [noteMenuModel] — kullanıcı isteği 2026-08-09).
                  if (PenTray.useRail(context) && !_secondary)
                    _hideWhileTyping(
                      note,
                      // Tam ekran AÇIKKEN düğme gizlenmez — çıkış yolu kalsın
                      // (dikte/ses kaydı düğmeleriyle aynı kural).
                      ref.watch(noteFullscreenProvider)
                          ? _fullscreenButton(l10n)
                          : Customizable(
                              id: UiItem.topFullscreen,
                              child: _fullscreenButton(l10n),
                            ),
                    ),
                ],
                _ => const <Widget>[],
              },
            // ⋮ yazarken de görünür: hızlı satırın en sağında (kullanıcı
            // isteği 2026-11-08 — "3 nokta geri gelsin").
            IconButton(
              key: const ValueKey('editor-more'),
              tooltip: l10n.noteMenu,
              icon: const Icon(Icons.more_vert),
              onPressed: _openNoteMenu,
            ),
          ];
          final titleSpacing = editorTitleSpacing(
            readingColumn ? box.maxWidth : 0,
            hasLeading: rawLeading != null || canPop,
          );
          final titleInset = titleSpacing > 16;
          final title = _typingTitle(
            note,
            bar: _barTitle,
            styledIdle,
            paneWidth: box.maxWidth,
          );
          return AppBar(
            // SIKI ÜST ÇUBUK (kullanıcı isteği 2026-11-03): 56 → 48 dp —
            // durum çubuğu ile düğmeler arasındaki boşluk yer harcıyordu;
            // simge düğmeleri 48 dp dokunma alanını korur.
            toolbarHeight: toolbarHeight,
            // Liste gizliyken (tam ekran / odak modu) geri okunun yerinde ☰:
            // tek dokunuşla liste geri gelir (kullanıcı isteği 2026-11-02:
            // "tam ekrandan çıkmak çok zor").
            leading: appBarLeading,
            backgroundColor: Colors.transparent,
            foregroundColor: chrome.topBarIconColor,
            iconTheme: IconThemeData(color: chrome.topBarIconColor),
            actionsIconTheme: IconThemeData(color: chrome.topBarIconColor),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            // Düğmeler okuma sütununun sağ kenarında biter (F44.3).
            actionsPadding: EdgeInsetsDirectional.only(
              end: readingColumn
                  ? readingMargin(box.maxWidth)
                  : (chrome.topBarPills ? AppSpace.xs : 0),
            ),
            // Saydam çubukta Flutter simge rengini zeminden çıkaramaz (çizilmiş
            // temalı notta beyaz simge kalıyordu): üst bant rengine göre (F30.6).
            systemOverlayStyle: _statusBarFor(chrome.statusBarGround),
            scrolledUnderElevation: 0,
            // BAŞLIK BOŞLUĞU YALNIZ SOLDA (kullanıcı bulgusu 2026-11-27:
            // "webte üst hızlı menü yok"): `titleSpacing` NavigationToolbar'da
            // başlığın İKİ yanına sayılır; geniş bölmede okuma payı (~500 dp)
            // iki kez düşülünce başlığa 0 dp kalıyor, hızlı satırın bütün
            // düğmeleri ⋯'ye düşüyor, ⋯ tarihin üstüne biniyordu. Pay artık
            // başlığın içinde, yalnız başta; sonda en çok 16 dp.
            // Telefonda (pay yok) eski yol: sarmalayıcı eklenmez (bütçe S45/S50).
            titleSpacing: titleInset ? 0 : titleSpacing,
            title: titleInset ? _titleWithSpacing(titleSpacing, title) : title,
            actions: chrome.topBarPills
                ? [
                    EditorTopPill(
                      key: const ValueKey('editor-top-actions-pill'),
                      fill: chrome.topPillFill,
                      border: chrome.topPillBorder,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppSpace.s,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actionItems,
                        ),
                      ),
                    ),
                  ]
                : actionItems,
          );
        },
      ),
    );
  }

  Widget _buildEditorScaffold(
    BuildContext context, {
    required AppLocalizations l10n,
    required Note note,
    required Attachment? bgImage,
    required EditorChromePalette chrome,
    required Color background,
    required Color? noteAccent,
    required bool themed,
    required String effectiveThemeId,
    required DashboardBackground dashBg,
    required TextStyle noteBodyStyle,
    required Widget body,
    required bool readingColumn,
    required double toolbarHeight,
    required Widget findSlot,
    required Widget? bottomBar,
    required bool fullscreenNow,
    required PreferredSizeWidget? appBar,
  }) {
    // Bağımlılık YOK: odak her değiştiğinde ekran yeniden kurulmasın.
    _routeScope = Focus.maybeOf(
      context,
      scopeOk: true,
      createDependency: false,
    )?.nearestScope;
    return Actions(
      actions: {
        // Klavyeden Kopyala/Kes (Ctrl+C / Ctrl+X): EditableText bu eylemleri
        // `Action.overridable` ile kaydettiğinden buradaki üst-ağaç eylemi
        // onları devralır ve panoya TEMİZ metin yazar (biçim işaretsiz,
        // çapasız). Uymayan durumlar varsayılana devredilir (callingAction).
        CopySelectionTextIntent: _CleanCopySelectionAction(this),
      },
      child: CallbackShortcuts(
        bindings: {
          // Ctrl+Z: metin alanı odaktayken Flutter'ın kendi metin geri alması
          // önce davranır (yazılan harfleri geri alır); alan odakta değilken
          // buraya düşer ve NOTUN son değişikliği geri alınır.
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: true,
            shift: true,
          ): _redo,
          // Esc BURADA BAĞLANMAZ (tablet bulgusu 2026-11-09: "fiziksel
          // klavyede Esc geri yapmıyor"). KÖK NEDEN: `Navigator.maybePop`
          // bölünmüş ekranda kabuğun iç gezginine gidiyordu — tek sayfa,
          // kapanacak bir şey yok — ama tuş "işlendi" sayıldığı için
          // uygulamanın [EscBackAction]'ı (geri tuşu yolu: PopScope sırası →
          // tam ekran, arama, not) hiç çalışmıyordu.
          if (PenTray.useRail(context) && !_secondary)
            const SingleActivator(
              LogicalKeyboardKey.keyF,
              control: true,
              shift: true,
            ): () => ref
                .read(noteFullscreenProvider.notifier)
                .set(!ref.read(noteFullscreenProvider)),
        },
        // Geri tuşu önce CANLI ARAMAYI kapatır, notu değil.
        // Biçim kipi dar dinlenir (P20 M5): alt ağaç `child` olarak yerinde.
        child: ListenableBuilder(
          listenable: _popL,
          builder: (context, child) => PopScope(
            // Geri tuşu sırayla: tam ekran → kayıt → biçim paneli → canlı
            // arama → not.
            // Yandaki bölme geri tuşunu hiç ENGELLEMEZ (K32 karar 5): kabuk
            // sayfasına kayıtlı; `false` kalsaydı uygulamadan çıkış kilitlenirdi.
            canPop:
                _secondary ||
                (!_findOpen &&
                    !_formatBarOpen &&
                    _voiceRecorder == null &&
                    !fullscreenNow),
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              // Açık bir alt panel (ek şeridi, kalem/biçim tepsisi…) varsa geri
              // ONUN — ekranın kendi kipleri sonra.
              if (BackCloses.handling(context)) return;
              if (ref.read(noteFullscreenProvider)) {
                _showNoteList();
                return;
              }
              // Kayıt sürerken geri = kaydı BİTİR ve ekle, sonra çık (eski
              // kayıt levhasının "geri kaydeder" kuralı — kayıt kaybolmasın).
              if (_voiceRecorder != null) {
                final navigator = Navigator.of(context);
                unawaited(
                  _finishVoiceRecording().whenComplete(() {
                    if (mounted) _closeEditor(navigator.maybePop);
                  }),
                );
                return;
              }
              // Biçim paneli açıkken geri PANELİ kapatır (kullanıcı isteği
              // 2026-10-28), notu değil.
              if (_formatBarOpen) {
                _formatBarOpen = false;
                return;
              }
              if (_findOpen) _closeFind();
            },
            child: child!,
          ),
          // NOT TEMASI (2026-10-28): çizilmiş zemin üst çubuğun da
          // arkasında; sayfa ve üst çubuk saydamlaşır.
          child: NoteThemeBackdrop(
            themeId: effectiveThemeId,
            // Notun vurgusu alt ağaca (madde kutucukları, "Yeni madde") —
            // kartla aynı kaynak (bkz. [NoteAccent]).
            child: NoteAccent(
              accent: noteAccent,
              background: background,
              // Ağaç şekli hep aynı (Theme her zaman var): renk eşiği aşılınca
              // editörün alt ağacı yeniden kurulmasın (odak/kaydırma korunur).
              child: Theme(
                data: _themeOf(context),
                // Sayfa rengi Scaffold'un ARKASINDA, 200 ms'de değişir (F34.4):
                // editörün dev ağacı her karede yeniden kurulmaz. Üst çubuk saydam.
                child: ColorFade(
                  color: themed ? Colors.transparent : chrome.baseBackground,
                  identity: (note.id, Theme.of(context).brightness),
                  // Zemin görseli bütün ekranın (üst çubuk + alt panel dahil)
                  // arkasında; eskiden yalnız gövdenin arkasındaydı.
                  builder: (context, color, child) => ColoredBox(
                    color: color,
                    child: bgImage != null
                        ? _withBackground(note, bgImage, child)
                        : wrapWithInheritedHomeBg(
                            context,
                            note: note,
                            dashBg: dashBg,
                            expand: true,
                            child: child,
                          ),
                  ),
                  // Scaffold ve altı klavyenin karelerini GÖRMEZ (F60.S5): kararlı
                  // MediaQuery; canlı değer yalnız [KeyboardInset.liveOf] okuyan
                  // yapraklarda (bkz. [KeyboardInsetScope]).
                  child: KeyboardInsetScope(
                    // Defter kâğıdı (çizgi, kenar çizgisi, cilt gölgesi, sarı bloknot
                    // tonu) bütün ekranın (üst alan + gövde + alt panel) arkasında tek
                    // kez çizilir — üst/alt şeritlerde dikiş ve eksik çizgi kalmaz.
                    child: _withPaper(
                      note,
                      noteBodyStyle,
                      topChromeHeight: _pagePen && !_secondary && fullscreenNow
                          ? 0
                          : toolbarHeight,
                      Scaffold(
                        backgroundColor: Colors.transparent,
                        // **KASMA — klavye boşluğu artık KARARLI** (bkz. [KeyboardSnap]).
                        // Scaffold gövdeyi klavye animasyonunun HER karesinde kısaltıyordu;
                        // görselli/uzun notlarda ve PDF bölmesinde yalnızca bu yeniden
                        // ölçüm bile takılma yaratıyor. Boşluk aşağıda, gövdenin
                        // dolgusundan veriliyor ve bir açılış/kapanışta EN ÇOK BİR KEZ
                        // değişiyor; çubuğun klavyeyle birlikte akan hareketi ise
                        // [KeyboardSlide] ile yalnız boyama katmanında yapılıyor.
                        resizeToAvoidBottomInset: false,
                        // Kalem + tam ekran: üst de sayfa olur (çıkış sütunda).
                        appBar: appBar,
                        // Renkli çerçeve: seçiliyse editör içeriğini saran ince renkli kenarlık.
                        //
                        // ALT ÇUBUK GÖVDENİN İÇİNDE (bkz. aşağıdaki `_bottomBar` yorumu):
                        // `bottomNavigationBar` yuvasındayken yüksekliği klavyeyle
                        // büyüyordu ve bu, Scaffold'ı her animasyon karesinde yeniden
                        // yerleştiriyordu.
                        //
                        // `SafeArea(bottom: false)`: alt güvenli alanı BİLEREK uygulanmaz.
                        // Çubuk `bottomNavigationBar` yuvasındayken Scaffold gövdeden alt
                        // dolguyu zaten kaldırıyordu (çubuk aşağıda duruyordu); yuva
                        // boşalınca dolgu geri gelir ve sayfa alanı sebepsiz kısalırdı.
                        // Görünüm birebir korunur.
                        body: StylusToggleOverlay(
                          visible:
                              !_readOnly &&
                              _penPolicy(PenSurface.page).showFloatingToggle,
                          child: KeyboardSnap(
                            // Klavye durup gövde oturduktan sonra odaklı alanı görünür kıl —
                            // gövde animasyon boyunca bilerek kısaltılmadığı için Flutter'ın
                            // kendi imleç kaydırması bu işi yapamaz (bkz. [KeyboardSnap]).
                            onSettled: (inset) {
                              _keyboardInset = inset;
                              if (inset <= 0) return;
                              _keyboardMemory = inset;
                              // Tahmin tuttuysa bu geçiş hiçbir şey yapmaz (imleç zaten
                              // görünür); tutmadıysa farkı burada kapatır.
                              _revealCaret();
                            },
                            builder: (context, keyboardInset) {
                              // Klavye KAPANDI (onSettled kapanışta gelmez, bkz. HAFIZA):
                              // yazarken gizlenen alt çubuk hemen gelsin.
                              if (keyboardInset <= 0 && _typingN.value) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) _showBarNow();
                                });
                              }
                              return Padding(
                                padding: EdgeInsets.only(bottom: keyboardInset),
                                child: Column(
                                  children: [
                                    findSlot,
                                    Expanded(
                                      // Sütun yokken de Row: kaleme geçişte sayfa yeniden kurulmaz.
                                      child: Row(
                                        children: [
                                          // Eski kalem sütununun yuvası (ağaç şekli sabit
                                          // kalsın; kalemler artık alttaki çekmecede).
                                          const SizedBox.shrink(),
                                          Expanded(
                                            // KALEMİ OTOMATİK ALGILA (bkz. [_onContentPointerDown]).
                                            child: Listener(
                                              onPointerDown:
                                                  _onContentPointerDown,
                                              onPointerMove:
                                                  _onContentPointerMove,
                                              onPointerUp: _onContentPointerUp,
                                              onPointerCancel:
                                                  _onContentPointerCancel,
                                              // JEST KİPİ örtüsü içeriğin ÜSTÜNDE; ağacın şekli kiple
                                              // değişmesin diye yığın koşulsuz (ilk çocuk sabit).
                                              child: Stack(
                                                children: [
                                                  SafeArea(
                                                    bottom: false,
                                                    // ÇERÇEVE EDİTÖRDE ÇİZİLMEZ (kullanıcı isteği
                                                    // 2026-10-20: "çerçeve sadece dashboarda görünsün"):
                                                    // notun içi sade kalır, renk kartta görünür.
                                                    // Defter kâğıdı ve zemin görseli artık ekranın tamamının
                                                    // (üst alan + gövde + alt panel) arkasında.
                                                    child: PageSwipeDetector(
                                                      enabled:
                                                          !note
                                                              .type
                                                              .isPageNoteType &&
                                                          !_penMode &&
                                                          textPagePosition(note)
                                                                  .count >
                                                              1,
                                                      onSwipe: _swipePage,
                                                      child: PageTurn(
                                                        index: textPagePosition(
                                                          note,
                                                        ).index,
                                                        count:
                                                            note
                                                                .type
                                                                .isPageNoteType
                                                            ? 1
                                                            : textPagePosition(
                                                                note,
                                                              ).count,
                                                        child: body,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_gestureMode !=
                                                      _GestureMode.off)
                                                    Positioned.fill(
                                                      child: InkGestureLayer(
                                                        key: const ValueKey(
                                                          'ink-gesture-layer',
                                                        ),
                                                        color: _themeOf(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                        scrollPosition:
                                                            _gestureScrollPosition,
                                                        onStroke:
                                                            _onGestureStroke,
                                                      ),
                                                    ),
                                                  if (_pagePen)
                                                    Positioned(
                                                      left: 0,
                                                      right: 0,
                                                      bottom: 0,
                                                      // Kalem kipi geri tuşuyla kapanır — tepsinin
                                                      // kendi panelleri önce (LIFO). Eskiden bu kayıt
                                                      // alt çubuktaydı; kalem kipinde alt çubuk yok,
                                                      // geri doğrudan ana ekrana atlıyordu.
                                                      child: BackCloses(
                                                        open: true,
                                                        onClose: () => _update(
                                                          () =>
                                                              _penMode = false,
                                                        ),
                                                        // Paket grubu (F60.2): tepsi açık paketi
                                                        // kapatmaz.
                                                        child: TapRegion(
                                                          groupId:
                                                              kNotePackageTapGroup,
                                                          // P49 (d): bildirimler tepsinin ÜSTÜNDE.
                                                          child: SnackBarObstacle(
                                                            child: PenTray(
                                                              key: const ValueKey(
                                                                'page-pen-dock',
                                                              ),
                                                              controller:
                                                                  _pageInkOf(
                                                                    note,
                                                                  ),
                                                              dock: true,
                                                              followActive:
                                                                  true,
                                                              // Üst çubuk varken geri al orada.
                                                              showUndo:
                                                                  !_secondary &&
                                                                  ref.watch(
                                                                    noteFullscreenProvider,
                                                                  ),
                                                              actions: [
                                                                // Kalem + tam ekranda üst çubuk yok: listeye
                                                                // dönüş tepside (yandaki bölme hariç).
                                                                if (!_secondary &&
                                                                    _listHidden(
                                                                      context,
                                                                    ))
                                                                  _showListButton(
                                                                    l10n,
                                                                  ),
                                                                if (!_secondary &&
                                                                    PenTray.useRail(
                                                                      context,
                                                                    ))
                                                                  _fullscreenButton(
                                                                    l10n,
                                                                  ),
                                                                _penCloseButton(
                                                                  l10n,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // KLAVYE: Scaffold yalnız GÖVDEYİ klavyeye göre kısaltır, alt
                                    // çubuğu ekranın dibinde bırakır — yani klavye açıkken alt
                                    // çubuğun tamamı (biçim çubuğu dahil) klavyenin ALTINDA
                                    // kalıyordu ve kullanılamıyordu ("düzenleme alanı güzel ama
                                    // altta olduğu için klavyenin altında kalıyor"). Çubuk klavye
                                    // kadar yukarı kaldırılır; böylece "Aa" düğmesi de yazarken
                                    // erişilebilir olur — biçim çubuğunu açmak için klavyeyi
                                    // kapatmak, kapatınca da seçimi kaybetmek gerekmez.
                                    //
                                    // ZIPLAMA + KASMA — HAREKET İLE YERLEŞİM AYRILDI (kullanıcı
                                    // bulgusu 2026-08-22: "klavye açılıp kapanırken bu alan
                                    // kayıyor"). Çubuk klavyeyle birlikte KARE KARE kayar ama
                                    // yalnız BOYAMA katmanında ([KeyboardSlide] → `Transform`);
                                    // gövdenin yerleşimi ise animasyon boyunca hiç değişmez,
                                    // klavye durunca TEK SEFERDE oturur (bkz. [KeyboardSnap]).
                                    // Eskiden ikisi de aynı kademeli değerden besleniyordu:
                                    // yerleşim azalmıştı ama çubuk 96 dp'lik sıçramalarla
                                    // yukarı çıkıyordu — kullanıcının gördüğü zıplama buydu.
                                    if (bottomBar != null)
                                      KeyboardSlide(
                                        inset: keyboardInset,
                                        child: bottomBar,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
