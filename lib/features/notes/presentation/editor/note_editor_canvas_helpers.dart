part of 'note_editor_screen.dart';

typedef _EditorBuildStyle = ({
  EditorChromePalette chrome,
  Color background,
  Color? noteAccent,
  bool themed,
  bool chromeSeeThrough,
  RichTextTheme richTheme,
  ThemeData theme,
  TextStyle noteBodyStyle,
});

extension _NoteEditorCanvasHelpers on _NoteEditorScreenState {
  /// Pencereli yazıma uygun mu? Ek etiketi çipleri, sarma, not içi arama ve
  /// bekleyen biçim alanın kendi metriklerine bakar: tek alanda kalırlar.
  bool _windowAllowed(Note note) =>
      _bodyFocus.hasFocus &&
      !_readOnly &&
      _floats.isEmpty &&
      !_findOpen &&
      !note.paged &&
      !note.hasPageInk &&
      _bodyController.pendingRange == null &&
      !_bodyController.text.contains('\u{1F4CE}');

  /// Başlık üst çubukta mı: medya notun tepesine SABİTLENMİŞ ya da not
  /// balonlu belge görünümünde (belge üstte, sayfa notu altta). Balona
  /// yazılırken (sürükleyici kip) başlık zaten gizlenir.
  bool _titleInBar(Note note) {
    if (note.type.isPageNoteType) {
      final kind = note.type == NoteType.slides
          ? AttachmentKind.slide
          : AttachmentKind.pdf;
      return note.attachments.any((a) => a.kind == kind);
    }
    return note.attachments.any((a) => a.isPinnedTop);
  }

  /// Panel ↔ alt çubuk takası (kasma listesi md. 6, P46): boy TEK ADIMDA
  /// değişir, yumuşaklık yalnız boyamada ([RevealUp]: solma + kayma). Eskiden
  /// iki `AnimatedSize` 260 ms boyunca gövdeyi her karede yeniden diziyordu
  /// (bütçe S9 `govde_boy_karesi` 34 → 2).
  Widget _barReturn(Widget bar) => _barSwapped ? RevealUp(child: bar) : bar;

  RenderBox? _pageBox() {
    final box = _pageKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  /// Sayfa tuvalinin alt sınırı: gövde alanının GÖRÜLEN EN BÜYÜK yüksekliği.
  ///
  /// KÖK NEDEN (2026-08-08 kullanıcı bulgusu: "klavye açılırken titreme kasma
  /// oluyor"): burada eskiden `constraints.maxHeight + viewInsets.bottom`
  /// yazıyordu. Değer doğruydu ama `viewInsetsOf` bir BAĞIMLILIK kurar —
  /// klavye animasyonunun HER karesinde (≈15 kare) sayfa tuvali, yüzen görsel
  /// bantları ve satır ölçümleriyle birlikte yeniden kuruluyordu. Titreme
  /// buydu.
  ///
  /// Şimdi MediaQuery'ye hiç dokunulmuyor: klavye kapalıyken ölçülen en büyük
  /// yükseklik saklanıyor ve taban o. Genişlik değişirse (yönelim, pencere)
  /// taban sıfırlanıp yeniden ölçülür. Alt sınır zaten bir MİNİMUM — fazlası
  /// görünmez, eksiği tuvali sıçratır.
  double _stableCanvasHeight(BoxConstraints constraints) {
    if (constraints.maxWidth != _canvasBaseWidth) {
      _canvasBaseWidth = constraints.maxWidth;
      _canvasBaseHeight = 0;
    }
    if (constraints.maxHeight.isFinite &&
        constraints.maxHeight > _canvasBaseHeight) {
      _canvasBaseHeight = constraints.maxHeight;
    }
    return _canvasBaseHeight;
  }

  /// Serbest görsel tuvali + sayfa içeriği. [_canvasCache] ile birlikte
  /// çalışır; ayrı bir yöntem olması yalnız `build`i okunur tutmak için.
  Widget _buildCanvas({
    required double minHeight,
    required List<Attachment> imageAttachments,
    required double hintLineHeight,
    required TextStyle hintStyle,
    required bool useCanvasHint,
    required bool hasBodyField,
    required Widget pageContent,
    required AppLocalizations l10n,
    required Note note,
    required TextStyle bodyStyle,
  }) => SingleChildScrollView(
    controller: _pageScroll,
    padding: const EdgeInsets.only(bottom: 96),
    // OKUMA GENİŞLİĞİ (geniş ekran, 2026-11-02): tam ekranda 1920 px'te
    // satırlar ~250 karaktere çıkıyordu. Sayfanın TAMAMI (metin, görseller,
    // mürekkep) ortada [kReadingWidth]'te durur: görsel x'i ve mürekkep
    // koordinatları sayfa genişliğine ORANLI saklandığından hepsi birlikte
    // ölçeklenir, metinle görsel birbirinden kaymaz. Kaydırma görünümü tam
    // genişlikte kalır — kenar boşluğunda da tekerlek kaydırır. Telefonda
    // (< 760) hiçbir şey değişmez.
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kReadingWidth),
        child: _withRuledLines(note, bodyStyle, PageInkStack(
      ink: _pageInkOf(note),
      page: textPagePosition(note).index + 1,
      penActive: _penMode,
      scroll: _pageScroll,
      child: ValueListenableBuilder<double>(
      // Başlık ölçümü (bkz. [_measureBodyTop]) yalnız tuvali kurar.
      valueListenable: _bodyTopN,
      builder: (context, bodyTop, _) => NotePageCanvas(
      // KLAVYEDEN BAĞIMSIZ taban — bkz. [_stableCanvasHeight].
      minHeight: minHeight,
      placementHintId: _placementHintId,
      onPlacementHintShown: () => _placementHintId = null,
      images: imageAttachments,
      onRemove: _removeAttachment,
      onChanged: _updateAttachment,
      onTableChanged: _updateTableContent,
      readOnly: _readOnly,
      onInkChanged: _updateAttachmentInk,
      onChangedMany: _updateAttachments,
      onCrop: _cropImage,
      onRotate: _rotateImage,
      onExtractText: _ocrImage,
      onCopy: _copyAttachment,
      onCopyMany: _copyAttachments,
      onTranscribe: _openTranscript,
      onSaveAs: (a) => unawaited(AttachmentSaveAs.run(context, ref, a)),
      onShare: (a) => unawaited(shareAttachment(
          context,
          ref,
          a,
          siblings: _note?.attachments ?? const [],
        )),
      onPinTop: _pinMediaTop,
      onPinHover: _setPinHover,
      onPinDrag: _setPinDrag,
      onViewChange: _readOnly
          ? null
          : (a, view) => unawaited(_setAttachmentView(a, view)),
      // Yazıya göm kısayolu (2026-11-01): gövdesi olan notta.
      onEmbed: _readOnly || note.type.isPageNoteType
          ? null
          : _startPendingEmbed,
      topLimit: bodyTop,
      // İpucu, gövde alanının İLK METİN SATIRINA hizalanır (dikeyde iç dolgu,
      // yatayda kenar boşluğu): imleçle aynı çizgide dursun.
      textTop: _NoteEditorScreenState._kBodyTextTop,
      textLeft: _NoteEditorScreenState._kGutter,
      hintLineHeight: hintLineHeight,
      hint: useCanvasHint
          // DOLGU YOK: ipucunun yeri tuvalde, metnin ilk satırının tam
          // çizgisinde hesaplanıyor (bkz. NotePageCanvas.textTop/textLeft).
          // Buraya konan her pay o hesabı kaydırır — eskiden üstte 16 dp
          // vardı ve ipucu metnin bir tık altında duruyordu.
          //
          // İpucu, gövdenin KENDİ stiliyle çizilir (yazı tipi, punto, satır
          // aralığı): tema stiliyle çizilirse notun büyütülmüş yazısında
          // ipucu ile imleç ayrı satırlara düşer.
          ? Text(
              l10n.bodyHint,
              style: hintStyle.copyWith(color: _themeOf(context).hintColor),
            )
          : null,
      onFloats: _applyFloats,
      // Boş alana dokunmak gövdeye odaklanır — yazmaya başlamak için aşağıya
      // dokunmak yeterli. Listede gövde alanı yok.
      onTapEmpty: hasBodyField
          ? () {
              if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
            }
          : null,
      child: KeyedSubtree(key: _pageKey, child: pageContent),
    ),
      ))),
      ),
    ),
  );

  /// Hızlı satırdaki kalem: AÇ / KAPA (kullanıcı isteği 2026-11-08: "kalem
  /// butonuna tekrar basınca kalem modu kapansın").
  /// ⌨ (fiziksel klavye takılıyken): odakta alan yoksa önce gövdeye (liste
  /// notunda başlığa) odaklanır — yoksa klavye gelmiyor, yalnız simge
  /// değişiyordu (P78 KT-18).
  void _toggleSoftKeyboard() {
    final hadEditableFocus =
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorStateOfType<EditableTextState>() !=
        null;
    HardKeyboard.toggleSoft();
    if (!HardKeyboard.softWanted.value || hadEditableFocus) return;
    (_bodyFocus.context != null ? _bodyFocus : _titleFocus).requestFocus();
  }

  /// Kalem kipi açıldı (düğmeyle ya da kalem değince). Kullanıcı isteği
  /// 2026-11-09: "kalem kipi açılınca 'sadece kalemle yaz açık/kapalı'
  /// söylenmeli, ipucuna tıklayıp ayara gidilmeli, her seferinde"; "kalem
  /// kipi ile yüzen kalem senkronu doğru çalışmalı" — kip açıkken yüzen
  /// düğme "kalem dokunur"da kalırsa kalem yazmıyordu.
  void _penModeOpened() {
    if (!InkToolMemory.autoStylus) InkToolMemory.saveAutoStylus(true);
    final note = _note;
    if (note == null || !mounted) return;
    final l10n = context.l10n;
    final page = !note.type.isPageNoteType;
    final ink = page ? _pageInkOf(note) : null;
    // Kalem görülmüş ve kullanıcı seçmemişse "yalnız kalem" ilk kalem
    // dokunuşunda KENDİLİĞİNDEN açılır (bkz. InkController.pointerDown) —
    // ipucu o andan önce okununca "parmak da yazar" diyordu ama parmak
    // yazmıyordu (cihazda görüldü 2026-11-10).
    final penOnly =
        (ink?.penOnly ?? InkToolMemory.penOnly) ||
        (InkToolMemory.stylusEver && !InkToolMemory.penOnlyChosen);
    final fingerTool = effectivePenModeFingerTool(penOnly: penOnly);
    // SÜREKLİ ÇIKMASIN (P49 (d), kullanıcı 2026-11-12; K34 Siler desteği):
    // parmak durumu oturumda DEĞİŞMEDİYSE aynı ipucu yinelenmez.
    if (InkToolMemory.lastPenOnlyHint == fingerTool) return;
    InkToolMemory.lastPenOnlyHint = fingerTool;
    // KARE SONRA (P78 KT-16, tablet turu 2026-11-18: bildirim kalem
    // tepsisini örtüyordu): bildirim engel yüksekliğini KURULURKEN okur
    // (bkz. snackBarBottomObstacle); kipi açan karede tepsi henüz
    // dizilmemişti, engel 0 okunuyordu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showMessage(
          penModeHintText(l10n, fingerTool),
          duration: const Duration(seconds: 3),
          action: ink == null
              ? null
              : SnackBarAction(
                  label: l10n.penModeSettings,
                  onPressed: () => showInkSettings(context, ink),
                ),
        );
      // TELEFONDA ELLE YAZMA (F63.5, KALEM K5): parmak çiziyorsa sayfayı
      // kaydırmanın yolu iki parmak — Siler kipinde yanlışlıkla "parmak
      // çizer" demez (K34).
      if (page && fingerTool == FingerTool.draw) {
        TipOnce.show(
          context,
          ref.read(sharedPreferencesProvider),
          TipOnce.penTwoFinger,
          l10n.inkTwoFingerHint,
          sessionLimit: false,
        );
      }
    });
  }

  /// Sayfa çizimi değişti: 2. çizgide "bekletince şekle oturur", 5.de
  /// "çizgiye basılı tut = silgi" (her biri cihazda bir kez).
  void _penTipAfterStroke() {
    _penStrokes++;
    final (String, String)? tip = switch (_penStrokes) {
      2 => (TipOnce.penShapeHold, context.l10n.tipPenShapeHold),
      5 => (TipOnce.penEraserHold, context.l10n.tipPenEraserHold),
      _ => null,
    };
    if (tip == null || !mounted) return;
    // KW-12: fareyle "bir an beklet" uygulanamaz; ipucu kalem/parmak
    // çizgisine kalır (gösterilmiş SAYILMAZ).
    if (tip.$1 == TipOnce.penShapeHold && lastPointerIsMouse()) return;
    TipOnce.show(
      context,
      ref.read(sharedPreferencesProvider),
      tip.$1,
      tip.$2,
      sessionLimit: false,
    );
  }

  /// Alt çubuğun SİLGİSİ (K-S1): kalem kipini silgi seçili açar.
  void _openEraser(Note note) {
    _pageInkOf(note).setEraser(true);
    if (!_penMode) _openPen();
  }

  /// **TEK MİKROFON** (K32 A6): öbür bölmede dikte/ses kaydı sürerken bu
  /// editör mikrofonu ALMAZ (bildirim). Aynı editörde kural ayrı: son açan
  /// alır (bkz. `_recordAudio`).
  bool _micBusyElsewhere() {
    final busy = _NoteEditorScreenState._live.any(
      (e) =>
          !identical(e, this) &&
          (e._dictating || e._voiceRecorder != null),
    );
    if (busy) _showSnack(context.l10n.micBusySideNote);
    return busy;
  }

  /// **TEK KAPANIŞ HUNİSİ** (K32): editörün KENDİNİ kapattığı her yer buradan
  /// geçer. Yandaki bölmede `context.pop()` BİRİNCİL notu kapatırdı — orada
  /// yalnız bölme kapanır. [routeClose] verilmezse rota `pop` edilir. Yeni
  /// kapanış yolu ekleyen bunu kullanır.
  void _closeEditor([VoidCallback? routeClose]) {
    final pane = SecondNotePane.maybeOf(context);
    if (pane != null) {
      pane.close();
      return;
    }
    if (routeClose != null) {
      routeClose();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  /// Tablette tam ekran düğmesi.
  Widget _fullscreenButton(AppLocalizations l10n) {
    final on = ref.watch(noteFullscreenProvider);
    return IconButton(
      key: const ValueKey('note-fullscreen'),
      tooltip: on ? l10n.noteFullscreenExit : l10n.noteFullscreen,
      icon: Icon(on ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
      onPressed: () => ref.read(noteFullscreenProvider.notifier).set(!on),
    );
  }

  /// Geniş ekranda not listesi şu an gizli mi (tam ekran ya da odak modu)?
  bool _listHidden(BuildContext context) =>
      SplitScope.maybeOf(context)?.listHidden ?? false;

  /// Tam ekrandan ve odak modundan çıkar: solda tek sütunluk liste görünür.
  void _showNoteList() {
    ref.read(noteFullscreenProvider.notifier).set(false);
    ref.read(listPaneCollapsedProvider.notifier).set(false);
    if (SplitScope.maybeOf(context)?.listAutoHides ?? false) {
      ref
          .read(listPeekLocationProvider.notifier)
          .set(currentLocation(GoRouter.of(context)));
    }
  }

  /// ☰ — gizli listeyi geri getirir (bkz. [_listHidden]).
  Widget _showListButton(AppLocalizations l10n) => IconButton(
    key: const ValueKey('note-show-list'),
    tooltip: l10n.showNoteList,
    icon: const Icon(Icons.menu_rounded),
    onPressed: _showNoteList,
  );

  /// Çubuğun sol yuvası: gizli liste ☰; dikey tablette açılmış liste kapanır.
  Widget? _listLeading(AppLocalizations l10n) {
    // Yandaki bölme (K32): ☰ yok, kendi kapatması ✕.
    if (_secondary) {
      return IconButton(
        key: const ValueKey('second-note-close'),
        tooltip: l10n.noteCloseSide,
        icon: const Icon(Icons.close_rounded),
        onPressed: _closeEditor,
      );
    }
    if (_listHidden(context)) return _showListButton(l10n);
    if (!(SplitScope.maybeOf(context)?.listAutoHides ?? false)) return null;
    return IconButton(
      key: const ValueKey('note-hide-list'),
      tooltip: l10n.listPaneHide,
      icon: const Icon(Icons.menu_open_rounded),
      onPressed: () => ref.read(listPeekLocationProvider.notifier).set(null),
    );
  }

  /// Klavye açıkken üst çubuğun başlık yuvası: hızlı işlev satırı
  /// (2026-11-08); kapalıyken [idle] (tarih + etiketler).
  ///
  /// [bar]: başlık üst çubukta (belge/PDF notu, bkz. [_barTitle]). Hızlı satır
  /// orada da gelir (kullanıcı isteği 2026-11-14: "sabitli notlarda üst hızlı
  /// satır oluşmuyor") ama YALNIZ gövde alanı (ör. "Not al") odaktayken —
  /// çubuktaki başlığı düzenlerken başlık alanı yerinde kalır.
  Widget? _typingTitle(
    Note note,
    Widget? idle, {
    Widget? bar,
    required double paneWidth,
  }) {
    if (_readOnly) return bar ?? idle;
    final pen = !note.type.isPageNoteType;
    // GENİŞ WEB'DE HEP AÇIK (kullanıcı isteği 2026-11-09: "webte hızlı menü
    // yok, kalemi açamıyorum"): web'de klavye boşluğu hiç oluşmadığından
    // satır hiç görünmüyordu. Geniş alanda düğmeler tarihin yanında sürekli;
    // sığmayanlar ⋮ menüsünde. Bölünmüş pencerede pencere değil editör
    // bölmesi ölçülür.
    final wide =
        (kIsWeb || debugWideWebQuickRow) && paneWidth >= kRailBreakpoint;
    // Paket grubu (F60.2): satıra dokunmak açık paketi kapatmaz.
    final row = TapRegion(
      groupId: kNotePackageTapGroup,
      child: EditorQuickRow(
          fit: wide,
          target: _formatTargetN,
          onBold: () => _applyFormat(RichFormat.bold),
          onBullet: () => _runOnTarget(applyLineBullet),
          // HIZLI SATIRDA ☑ HER NOT TÜRÜNDE (kullanıcı bulgusu 2026-11-19:
          // liste notunda menüye eklenen "Onay kutusu" sessizce yoktu):
          // metin notunda satır ↔ madde, liste notunda odaktaki maddeyi
          // işaretler, numaralı listede onay kutulu listeye çevirir.
          onCheckbox: note.type.isPageNoteType ? null : _quickRowCheckbox,
          onHeading: () => _runOnTarget((c) {
            final next = switch (activeRichHeading(c)) {
              RichHeading.normal => RichHeading.h1,
              RichHeading.h1 => RichHeading.h2,
              RichHeading.h2 => RichHeading.normal,
            };
            return applyRichHeading(c, next);
          }),
          onPhoto: () {
            _rememberCaret();
            unawaited(_pickImage());
          },
          onFile: () => unawaited(_attachAnyFile()),
          onPen: pen ? _togglePen : null,
          penOn: _penMode,
          onPenSettings: pen
              ? () => showInkSettings(context, _pageInkOf(note))
              : null,
          onReminder: () => unawaited(_pickReminder()),
          // Ara başlık: satırı doğrudan alt başlık yapar (metin modu).
          onSubheading: note.type == NoteType.text
              ? () => _runOnTarget(
                  (c) => applyRichHeading(
                    c,
                    activeRichHeading(c) == RichHeading.h2
                        ? RichHeading.normal
                        : RichHeading.h2,
                  ),
                )
              : null,
          onSpell: () {
            AutoSpell.toggle();
            unawaited(_seedSpell());
          },
          onSpellSettings: () => showSpellSettings(
            context,
            onReviewNote: _readOnly || note.type.isPageNoteType
                ? null
                : () => unawaited(_reviewSpelling()),
          ),
          onPackage: () => _packageFromQuickRow(note),
          packageHint:
              note.type == NoteType.text && suggestsPackage(note.body),
          onItalic: () => _applyFormat(RichFormat.italic),
          onUnderline: () => _applyFormat(RichFormat.underline),
          onHighlight: () => _applyFormat(RichFormat.highlight),
          onDictation: () => unawaited(_toggleDictation()),
          onCamera: kIsWeb
              ? null
              : () {
                  _rememberCaret();
                  unawaited(_takePhoto());
                },
          onScan: kIsWeb ? null : () => unawaited(_scanDocument()),
          onDate: () => _insertAtCaretOrCell(
            DateFormat.yMMMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).add_Hm().format(DateTime.now()),
          ),
          onDay: _insertDay,
          onTable: note.type.isPageNoteType ? null : _insertTable,
          onCalculator: () => unawaited(_openCalculator()),
          onFind: () => unawaited(_openNoteSearch()),
          onListen: () => unawaited(_listen()),
          onStats: () {
            _flushPending(_bodyController);
            unawaited(showNoteStatsSheet(context, _note ?? note));
          },
          onAttach: () => unawaited(_showAttachMenu()),
          onColor: () => _applyFormat(
            RichFormat.color,
            colorIndex: NoteFormatMemory.favoriteColor,
          ),
          onColorPick: () => unawaited(_pickFavoriteColor()),
          favoriteColor: _NoteEditorScreenState._favoriteColorValue(),
          // Nota her girişte bir kez (durum örneği nota bağlı); setState
          // YOK — yalnız bir sonraki açılışta vurgulanmasın diye.
          hint: !_quickRowHinted,
          onHinted: () => _quickRowHinted = true,
      ),
    );
    final Widget styledRow = _chrome.topBarPills
        ? EditorTopPill(
            fill: _chrome.topPillFill,
            border: _chrome.topPillBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
              child: row,
            ),
          )
        : row;
    final Widget? styledBar = bar != null && _chrome.topBarPills
        ? EditorTopPill(
            fill: _chrome.topPillFill,
            border: _chrome.topPillBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
              child: bar,
            ),
          )
        : bar;
    if (styledBar != null) {
      if (wide) {
        return LayoutBuilder(
          builder: (context, box) {
            final quickMax = (box.maxWidth * 0.48).clamp(96.0, 440.0);
            return Row(
              children: [
                Expanded(child: styledBar),
                const SizedBox(width: AppSpace.m),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: quickMax),
                  child: styledRow,
                ),
              ],
            );
          },
        );
      }
      return KeyboardSwitch(
        closed: styledBar,
        editing: _fieldFocusedN,
        onlyWhileEditing: true,
        pauseHidden: true,
        open: styledRow,
      );
    }
    if (wide) {
      return Row(
        children: [
          if (idle != null) Flexible(child: idle),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Align(alignment: AlignmentDirectional.centerStart, child: styledRow)),
        ],
      );
    }
    return KeyboardSwitch(
      closed: idle,
      editing: _fieldFocusedN,
      pauseHidden: true,
      open: styledRow,
    );
  }

  /// Yazarken (klavye açık) üst çubukta yalnız hızlı satır + geri al/yinele
  /// kalır (kullanıcı isteği 2026-11-08): öbür düğmeler klavye açıkken
  /// gizlenir. Yaprak düzeyde ([KeyboardSwitch]) — ekran yeniden kurulmaz.
  Widget _hideWhileTyping(Note note, Widget child) =>
      _readOnly
      ? child
      : KeyboardSwitch(open: const SizedBox.shrink(), closed: child);

  // Keep tarzı sesli not (`_startVoiceCapture`: Google'ın tanıma EKRANI,
  // metin + Google'ın kaydettiği AMR ses) 2026-10-19 sadeleştirmesinde
  // kaldırıldı. Dördüncü bir arayüzdü ve tek getirisi düşük kaliteli ses
  // dosyasıydı; `?voice=1` artık ortak levhayı açar. (Kotlin'deki
  // `voiceInputWithAudio` köprüsü kullanılmıyor; bir sonraki APK turunda
  // derlenerek sökülecek.)

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(message);
  }

  /// Belge notunun (PDF / sunum) gövdesi: başlık + iki bölmeli sayfa/not
  /// ekranı.
  ///
  /// Belge notun İÇİNDE yaşar (görseller gibi), sayfa geçişi notun içinde
  /// yapılır — ek şeridine gidip tam ekran açmak gerekmez. Not tipi belge olup
  /// da belgesi olmayan tek durum, dosya seçicinin iptal edilmesidir; o zaman
  /// da ekran kilitlenmez, "seç" düğmesi durur (not zaten boşsa çıkışta
  /// kendiliğinden silinir).
  Widget _buildPageNoteBodyContent(
    Note note,
    Widget header,
    RichTextTheme richTheme,
    TextStyle textStyle, {
    required ValueChanged<bool> onPenModeChanged,
  }) {
    final isSlides = note.type == NoteType.slides;
    final wanted = isSlides ? AttachmentKind.slide : AttachmentKind.pdf;
    Attachment? document;
    for (final a in note.attachments) {
      if (a.kind == wanted) {
        document = a;
        break;
      }
    }
    if (document == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSlides
                        ? Icons.slideshow_outlined
                        : Icons.picture_as_pdf_outlined,
                    size: 40,
                    color: _themeOf(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSlides
                        ? context.l10n.slidesNoDocument
                        : context.l10n.pdfNoDocument,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: isSlides ? _pickSlide : _pickPdf,
                    child: Text(
                      isSlides
                          ? context.l10n.slidesChooseDocument
                          : context.l10n.pdfChooseDocument,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    final doc = document;
    // Anahtar EK KİMLİĞİ: belge değiştirilirse pano durumu (sayfa numarası,
    // alandaki metin) sıfırdan kurulmalı, yoksa eski belgenin 7. sayfasının
    // notu yeni belgenin 7. sayfasına yazılırdı.
    //
    // `noteOf`: anlık görüntü değil CANLI okuyucu — sayfa notuna yazmak "saf
    // yazım" sayıldığı için ekran geneli setState atlanır ve buraya geçirilen
    // bir `Note` bayat kalırdı (bkz. PageNotePane.noteOf).
    // Web: Drive'daki belge önce iner (bkz. [WebDriveGate]); blob adresi
    // buluta yazılmaz (`Attachment.toMap`).
    final pane = WebDriveGate(
      attachment: doc,
      builder: (context, doc) => isSlides
        ? SlideNotePane(
            key: ValueKey('slide-pane-${doc.id}'),
            noteOf: () => _note ?? note,
            attachment: doc,
            textStyle: textStyle,
            richTheme: richTheme,
            onPageNoteChanged: (page, text) =>
                _mutate((n) => n.withPageNote(doc, page, text)),
            onAttachmentChanged: _updateAttachment,
            onFieldFocused: _setFormatTarget,
            onFieldDisposed: _clearFormatTargetFor,
            onImmersiveChanged: _setImmersiveBubble,
            penMode: _penMode,
            onPenModeChanged: onPenModeChanged,
          )
        : PdfNotePane(
            key: ValueKey('pdf-pane-${doc.id}'),
            noteOf: () => _note ?? note,
            onEditPages: (pageCount) => _editPdfPages(doc, pageCount),
            attachment: doc,
            textStyle: textStyle,
            richTheme: richTheme,
            onPageNoteChanged: (page, text) =>
                _mutate((n) => n.withPageNote(doc, page, text)),
            onAttachmentChanged: _updateAttachment,
            onFieldFocused: _setFormatTarget,
            onFieldDisposed: _clearFormatTargetFor,
            onImmersiveChanged: _setImmersiveBubble,
            penMode: _penMode,
            onPenModeChanged: onPenModeChanged,
          ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balona yazılırken not başlığı da gizlenir: klavye ekranın yarısını
        // alıyor, o alan belgeye ve balon kartına lazım (kullanıcı isteği
        // 2026-08-08 — ekran görüntüsünde işaretlenen bölge).
        if (!_immersiveBubble) header,
        Expanded(child: pane),
      ],
    );
  }

  _EditorBuildStyle _prepareBuildStyle(
    BuildContext context,
    Note note,
    Attachment? bgImage,
  ) {
    // ÜST ALAN, SAYFA ÇUBUĞU VE ALT PANEL SAYFAYLA BİR BÜTÜN (kullanıcı
    // isteği 2026-11-22): her tema, renk, defter kâğıdı ve arka plan
    // görselinde tek kaynaklı renk uyumu ve WCAG AA okunurluk garantisi.
    // `Theme.of` BURADA bilerek dış tema: okunurluk kararı dış temaya göre.
    final chrome = EditorChromePalette.resolve(
      outerTheme: Theme.of(context),
      note: note,
      hasBgImage: bgImage != null,
      bgTone: bgImage == null ? null : _bgTone,
    );
    _chrome = chrome;
    final background = chrome.pageSurface;
    _editorInk[context] = chrome.inkTheme;
    // NOTUN VURGUSU — kartla AYNI (bkz. [NoteAccent]): kutucuk, "Yeni madde",
    // etiket/klasör/hatırlatıcı hapları ve raptiye bu tondan.
    final noteAccent = chrome.noteAccent;
    _barInk = chrome.barInk;
    _barPage = chrome.barPage;
    // Çizilmiş tema varsa sayfa ve üst çubuk saydam: süsleme arkadan görünür
    // (bkz. NoteThemeBackdrop).
    final themed = NoteThemes.byId(note.theme) != null;
    final chromeSeeThrough = chrome.chromeSeeThrough;
    // Satır içi biçimlendirmenin çizim ayarları: gövde ve maddeler AYNI
    // paleti kullanır (metindeki 1..5 indeksi her ikisinde aynı rengi verir).
    final richTheme = RichTextTheme(
      palette: NoteColors.richPalette,
      markerColor: _themeOf(
        context,
      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
      // Renkli yazı notun zeminine göre okunur hâle getirilir.
      background: background,
    );
    _bodyController.richTheme = richTheme;
    _titleController.richTheme = richTheme;
    // Metne gömülü ek etiketleri (bkz. attachment_tag.dart) buradan
    // beslenir: ek silinip eklendikçe etiketin kırmızı çizilip çizilmeyeceği
    // değişir. Yalnız GÖVDE — başlığa ek etiketi konmaz.
    // Etiket adları: hem SEÇİLİ METİNDEN kurulan bağlar (kullanıcı isteği
    // 2026-08-16 — "o yazıya PDF gömülür") hem de dosya adıyla eklenen
    // etiketler. İkisi de aynı çizim yolundan geçer.
    // Denetleyici beslemeleri YALNIZ not ya da tema parlaklığı değişince
    // (F2.7): build başka nedenlerle de koşuyor (odak, klavye, biçim
    // çubuğu) ve her seferinde ad listesi + çip görünümleri baştan
    // kuruluyordu.
    final dark = _themeOf(context).brightness == Brightness.dark;
    if (!identical(note, _fedNote) || dark != _fedDark) {
      _fedNote = note;
      _fedDark = dark;
      _bodyController.attachmentNames = [
        // Eki silinmiş bağ etiket sayılmaz (çip görünümü kalmasın).
        for (final link in note.tagLinks)
          if (link.label.isNotEmpty && tagLinkAlive(note, link)) link.label,
        for (final a in note.attachments) a.fileName,
      ];
      // Gömülü yazının ÇİP görünümü: ekin türüne göre renk ve rozet (bkz.
      // AttachmentTagChips). Denetleyici renkleri yalnız değişince alır.
      // Not bağlantısı (F18.16): hedef silinmiş/çöpteyse soluk.
      final liveIds = {
        for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
          if (n.deletedAt == null) n.id,
      };
      final tagLooks = embedTagLooks(note, dark: dark, liveNoteIds: liveIds);
      _tagLooks = tagLooks;
      _bodyController.tagChipColors = {
        for (final e in tagLooks.entries) e.key: e.value.color,
      };
      // Notta video varken "1:23" gibi damgalar bağlantı gibi çizilir ve
      // dokununca video oraya gider (bkz. video_time.dart).
      _bodyController.videoTimestamps = _NoteEditorScreenState._hasVideo(note);
    }
    // Notun kendi yazı tipi/boyutu: gövde ve maddeler `fontFamily`/`fontScale`
    // çiftinden, BAŞLIK ise kendi `titleFontFamily`/`titleFontScale`
    // değerlerinden beslenir — biçim çubuğu odaktaki alana yazar.
    final theme = _themeOf(context);
    final bodyBase = theme.textTheme.bodyLarge ?? const TextStyle();
    // Renk BURADA somutlaşır: satır içi opaklık (`&&k:...&&`) ancak var olan
    // bir rengin alfasını düşürebilir; stil rengi null bırakılırsa seçime
    // uygulanan şeffaflık hiç görünmezdi.
    final noteBodyStyle = applyNoteOpacity(
      applyNoteFont(
        bodyBase.copyWith(
          fontSize: (bodyBase.fontSize ?? 16) * note.fontScale,
          color: bodyBase.color ?? theme.colorScheme.onSurface,
          // DEFTER SATIR ARALIĞI (D1): satır yüksekliğine biner; çizgiler
          // yazıya bağlı olduğundan onlar da açılır (bkz. [_paperGap]).
          height: note.paged && note.lineSpacing != 1
              ? (bodyBase.height ?? 1.45) * note.lineSpacing
              : null,
        ),
        note.fontFamily,
      ),
      note.textOpacity,
      theme.colorScheme.onSurface,
    );
    return (
      chrome: chrome,
      background: background,
      noteAccent: noteAccent,
      themed: themed,
      chromeSeeThrough: chromeSeeThrough,
      richTheme: richTheme,
      theme: theme,
      noteBodyStyle: noteBodyStyle,
    );
  }
}
