part of 'note_editor_screen.dart';

typedef _EditorBottomResult = ({
  Widget findSlot,
  Widget? bottomBar,
});

extension _NoteEditorBottomBarBuild on _NoteEditorScreenState {
  _EditorBottomResult _buildEditorBottomArea(
    BuildContext context, {
    required AppLocalizations l10n,
    required Note note,
    required List<Attachment> fileAttachments,
    required bool isDocumentNote,
    required EditorChromePalette chrome,
    required Color background,
    required bool chromeSeeThrough,
    required TextStyle noteBodyStyle,
    required Widget? pageBarDock,
    required bool readingColumn,
    required VoidCallback onClearPendingEmbed,
  }) {
    // NOT İÇİ ARAMA SATIRI (kullanıcı isteği 2026-11-16): üst çubuğun hemen
    // altında, gövdenin tepesinde. AYNI örnek (KeyboardSnap kurulumlarında
    // atlanır); yalnız [_findOpenN] ve eşleşmeler dinlenir — kök kurulmaz.
    final Widget findSlot = ValueListenableBuilder<bool>(
      valueListenable: _findOpenN,
      builder: (context, open, _) => !open
          ? const SizedBox.shrink()
          : RepaintBoundary(
              child: ListenableBuilder(
                listenable: _find,
                builder: (context, _) => Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: readingColumn ? kReadingWidth : double.infinity,
                    ),
                    child: NoteFindBar(
                      controller: _find.query,
                      focusNode: _find.focus,
                      count: _find.hits.length,
                      index: _find.index,
                      background: background,
                      onChanged: (_) => _runFind(),
                      onNext: () => _stepFind(1),
                      onPrevious: () => _stepFind(-1),
                      onList: () => unawaited(_openFindList()),
                      onClose: _closeFind,
                    ),
                  ),
                ),
              ),
            ),
    );
    final Widget? bottomBar = _immersiveBubble || _pagePen
        ? null
        : RepaintBoundary(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sayfada yüzmeyen ekler (PDF/sunum/ses + "ek olarak"
                // işaretli görsel/video) SAYFANIN DİBİNDE, kapanabilir bir
                // şeritte. Görseller ve videolar her not tipinde TAM SAYFA
                // serbest katmanda kalır (NotePageCanvas — yukarıda).
                // Klavye açıkken şerit gizlenir: zaten görünmüyordu (klavyenin
                // altındaydı), yukarı kaldırılsaydı yazma alanını yerdi.
                // KÖK NEDEN: burada `if (keyboard == 0)` vardı.
                // `AttachmentStrip` klavye kontrolünü ZATEN kendi içinde
                // yapıyor (SizedBox.shrink döndürüyor); dıştaki koşul
                // widget'ı ağaçtan tümüyle düşürüyor, bütün State'ler
                // (ses oynatıcısı dahil) dispose ediliyor ve klavye
                // kapanınca sıfırdan kuruluyordu — şeridin kaydırma
                // konumu sıfırlanıyor, ÇALAN SES sessizce duruyordu.
                // Sayfa üstüne yazma kipi de geri tuşuyla biter (önce kip,
                // sonra not).
                BackCloses(
                  open: _penMode,
                  onClose: () => _update(() => _penMode = false),
                  child: const SizedBox.shrink(),
                ),
                BackCloses(
                  open:
                      _stripOpenedHere &&
                      ref.watch(attachmentsExpandedProvider),
                  onClose: () {
                    _stripOpenedHere = false;
                    ref.read(attachmentsExpandedProvider.notifier).toggle();
                  },
                  child: AttachmentStrip(
                  attachments: [
                    for (final a in note.attachmentsWithoutBackground)
                      if (!a.floatsOnPage &&
                          !_inPinnedPane(note, a) &&
                          !note.hidesDerivedDocument(a))
                        a,
                  ],
                  onRemove: _removeAttachment,
                  onChanged: _updateAttachment,
                  onCopy: _copyAttachment,
                  // Belge (PDF/sunum) notunda gövde metni yok; etiket
                  // yazacak bir yer olmadığı için düğme çizilmez.
                  // Ek şeridindeki düğme artık BAĞLAMA KİPİNİ başlatır
                  // ("önce eki seç, sonra yazıyı"): dosya adını imlece
                  // yazmak yerine kullanıcı bağlanacak yazıyı seçer.
                  onInsertTag: note.type.isPageNoteType
                      ? null
                      : _startPendingEmbed,
                  // GÖRÜNÜM ANAHTARI her döşemede (Sabit / Yüzen / Balonlu
                  // / Ek). "Yüzen" belge notunda önce klasiğe döner, sonra
                  // eki sayfaya koyar — eskiden buradaki "sayfaya koy"
                  // düğmesi belge notunda eki sayfası olmayan bir yere
                  // taşıyıp KAYBEDİYORDU (bkz. _setAttachmentView).
                  viewOf: _readOnly ? null : (a) => _viewOf(note, a),
                  onSetView: _readOnly
                      ? null
                      : (a, view) => unawaited(_setAttachmentView(a, view)),
                  onTranscribe: _openTranscript,
                  foreign: widget.ownerId != null,
                  expanded: ref.watch(attachmentsExpandedProvider),
                  onToggle: () => ref
                      .read(attachmentsExpandedProvider.notifier)
                      .toggle(),
                  // Alt çubuktaki ataç kişiselleştirmede gizlendiyse şerit
                  // kapalıyken kendi ince tutamağını gösterir — açmanın
                  // yolu hiç kaybolmasın.
                  collapsedHandle: !Personalize.current.shows(
                    UiItem.barAttachments,
                  ),
                  ),
                ),
                // BAĞLAMA KİPİ şeridi: hangi dosyanın bağlanmayı
                // beklediğini söyler ve seçilen yazıya bağlar.
                // Kip görünmez olsaydı kullanıcı ne beklendiğini
                // bilemezdi (ek seçildi ama ekranda hiçbir şey
                // değişmiyor).
                if (_pendingEmbed != null)
                  _PendingEmbedBanner(
                    fileName: _pendingEmbed!.fileName,
                    lasso: _gestureMode == _GestureMode.embedLasso,
                    // Parmak şeride DEĞDİĞİ an seçim yedeklenir: sonraki
                    // karede odak düşse bile bağlanacak yazı elde kalır.
                    onPointerDown: _rememberTargetSelection,
                    onLink: _finishPendingEmbed,
                    // DAİRE İÇİNE AL (kullanıcı isteği 2026-10-30) ↔ yazıyı
                    // seçerek bağla: tek şeritte kip düğmesi.
                    onToggleLasso: () => _setGestureMode(
                      _gestureMode == _GestureMode.embedLasso
                          ? _GestureMode.off
                          : _GestureMode.embedLasso,
                    ),
                    onCancel: () {
                      _setGestureMode(_GestureMode.off);
                      onClearPendingEmbed();
                    },
                  ),
                // CANLI DİKTE şeridi: mikrofon açıkken kaçırılamayacak bir
                // gösterge (aynı gerekçe — açık kalmış mikrofon fark
                // edilmiyordu). Dokunmak dikteyi bitirir.
                // SESLİ NOT hapı: kayıt notun içinde sürer, yazmaya devam
                // edilebilir; gövdeyi yeniden dizmemek için tek adımda yer alır
                // (RevealUp yalnız boyama katmanında).
                _voiceRecorder == null
                    ? const SizedBox.shrink()
                    : RevealUp(
                        child: VoiceRecordPanel(
                          recorder: _voiceRecorder!,
                          onStop: () => unawaited(_finishVoiceRecording()),
                          onCancel: () => unawaited(
                            _finishVoiceRecording(keep: false),
                          ),
                        ),
                      ),
                if (_dictating)
                  SnackBarObstacle(
                    child: _DictationPanel(
                      controller: _dictationCtl!,
                      onStop: () => unawaited(_stopDictation()),
                    ),
                  ),
                // Dosya işleri (kopyalama/yapıştırma) için aynı şerit,
                // ayrı simge: sessiz bekleme bitti (bkz. [_busyTaskN]).
                ValueListenableBuilder<String?>(
                  valueListenable: _busyTaskN,
                  builder: (context, busy, _) => busy != null
                      // Web'de ek DOĞRUDAN yükleniyor: oran şeride yüzde
                      // olarak.
                      ? ValueListenableBuilder<double?>(
                          valueListenable:
                              AttachmentRepository.directUploadProgress,
                          builder: (context, fraction, _) => _AiBanner(
                            label: fraction == null
                                ? busy
                                : '$busy ${formatUploadPercent(context, fraction)}',
                            icon: Icons.sync,
                            progress: fraction,
                          ),
                        )
                      // Arka planda buluta çıkan ekler (kullanıcı bulgusu
                      // 2026-10-17: "ek yüklerken sessizlik var"): şerit
                      // kapalı ya da ek sayfaya gömülüyken de görünür bir iz.
                      : _NoteUploadsBanner(attachments: note.attachments),
                ),
                // WEB: Drive'daki ya da telefondan çıkmamış ekler için tek
                // şerit (kullanıcı bulgusu 2026-11-02: "ekler hâlâ webte
                // gelmiyor").
                if (kIsWeb) WebAttachmentsBanner(attachments: note.attachments),
                // Yatay ekranda klavye + çubuk ekranı aşabilir; çubuk taşmak
                // yerine kendi içinde kaydırılır (Flexible + kaydırma).
                //
                // ZIPLAMA (kullanıcı bulgusu 2026-08-21): panel eskiden
                // `if (_formatBarOpen) Flexible(...)` ile Column'a ANINDA
                // (0 ms) eklenip çıkarılıyordu — klavyenin kendi hareketiyle
                // aynı karede çakışınca "zıplama" hissi veriyordu. Panel artık
                // her zaman ağaçta, `AnimatedSize` yüksekliğini yumuşak
                // kapatıyor/açıyor; kapalıyken `SizedBox.shrink()` yer
                // kaplamıyor.
                // 2026-10-28 ("biçim menüsü daha yumuşak"): panel ile alt
                // çubuk AYNI süre ve eğriyle yer değiştirir (biri büyürken öbürü
                // küçülür — toplam boy sıçramaz), panelin içeriği hafifçe
                // yukarı süzülerek belirir.
                Flexible(
                  // Paket grubu (F60.2): biçim paneli açık paketi kapatmaz.
                  child: TapRegion(
                  groupId: kNotePackageTapGroup,
                  // Kip ve hedef dar dinlenir (P20 M5).
                  child: ListenableBuilder(
                    listenable: _formatPanelL,
                    builder: (context, _) => !_formatBarOpen || _findOpen
                        ? const SizedBox.shrink()
                        : SnackBarObstacle(
                          child: RevealUp(
                          child: SingleChildScrollView(
                            child: Center(
child: ConstrainedBox(
constraints: BoxConstraints(
maxWidth: readingColumn ? kReadingWidth : double.infinity,
),
child: ClipRRect(
// Sütunda sayfanın üstünde kart: köşesiz kutu kopuk duruyordu.
// Dar ekranda kenardan kenara, köşe yok.
clipBehavior:
readingColumn && MediaQuery.sizeOf(context).width > kReadingWidth
? Clip.antiAlias
: Clip.none,
borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
child: FormatBar(
                              target: _formatTarget,
                              onFormat: _applyFormat,
                              onClearFormat: _clearFormat,
                              onRemoveFormat: _removeFormat,
                              fontFamily: _titleIsTarget
                                  ? note.titleFontFamily
                                  : note.fontFamily,
                              fontScale: _titleIsTarget
                                  ? note.titleFontScale
                                  : note.fontScale,
                              textOpacity: _titleIsTarget
                                  ? note.titleTextOpacity
                                  : note.textOpacity,
                              hasSelection: _hasSelection,
                              onOpacityChanged: (value) => _mutate(
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleTextOpacity: value)
                                    : n.copyWith(textOpacity: value),
                              ),
                              onOpacityEnd: (value) => _applyStepOrNote(
                                RichFormat.opacity,
                                kRichOpacitySteps,
                                kRichOpacityDefault,
                                value,
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleTextOpacity: value)
                                    : n.copyWith(textOpacity: value),
                              ),
                              onFontChanged: (family) {
                                // Yalnız BU not: tip yeni notlara taşınmaz
                                // (kullanıcı kararı 2026-11-22).
                                _mutate(
                                (n) => _titleIsTarget
                                    ? (family == null
                                          ? n.copyWith(
                                              clearTitleFontFamily: true,
                                            )
                                          : n.copyWith(titleFontFamily: family))
                                    : (family == null
                                          ? n.copyWith(clearFontFamily: true)
                                          : n.copyWith(fontFamily: family)),
                                immediate: true,
                              );
                              if (family == null && !_titleIsTarget) {
                                _notesRepo?.clearFontFamily(widget.noteId);
                              }
                              },
                              // Sürüklerken yalnız yerel durum + gecikmeli kayıt: her kare
                              // Firestore'a yazmak boşuna trafik olurdu.
                              onScaleChanged: (value) => _mutate(
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleFontScale: value)
                                    : n.copyWith(fontScale: value),
                              ),
                              onScaleEnd: (value) {
                                // Notun tamamına uygulandıysa yeni notlara da
                                // (F56.3); seçili aralık ve başlık hariç.
                                if (!_titleIsTarget &&
                                    !(_formatTarget != null &&
                                        _hasSelection())) {
                                  NoteFormatMemory.rememberScale(value);
                                }
                                _applyStepOrNote(
                                RichFormat.size,
                                kRichSizeSteps,
                                kRichSizeDefault,
                                value,
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleFontScale: value)
                                    : n.copyWith(fontScale: value),
                              );
                              },
                              // Başlık yalnız GÖVDEDE ve maddelerde: notun
                              // başlık alanı zaten başlık.
                              onHeading: _titleIsTarget
                                  ? null
                                  : (h) => _runOnTarget(
                                      (c) => applyRichHeading(c, h),
                                    ),
                              onClose: () => _formatBarOpen = false,
                              // Hedef MADDEYSE alt çizgi sırası (2026-10-30:
                              // uzun basış menüsünden buraya taşındı).
                              dividerKind: _formatItemId == null
                                  ? null
                                  : _itemsEditorKey.currentState
                                        ?.dividerKindOf(_formatItemId!),
                              // Örnekler maddenin renk/kalınlığını taşır (P63).
                              dividerStyle: _formatItemId == null
                                  ? null
                                  : _itemsEditorKey.currentState
                                        ?.dividerOf(_formatItemId!),
                              onDivider: (kind) => _itemsEditorKey
                                  .currentState
                                  ?.setDividerOf(_formatItemId ?? '', kind),
                              onDividerStyle: () => unawaited(
                                _itemsEditorKey.currentState
                                    ?.editDividerStyleOf(_formatItemId ?? ''),
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
                // Alt bar: eskiden yedi ETİKETSİZ ikon yan yanaydı (palet, ataş,
                // hesap, biçim, liste, mikrofon, AI) ve hangisinin ne yaptığı
                // ancak basınca anlaşılıyordu. Şimdi üç etiketli segment tek
                // kapsülde; hesap makinesi üst bara, ek/renk seçenekleri
                // "Ekle" açılırına taşındı.
                // NOT İÇİ ARAMA artık gövdenin TEPESİNDE (bkz. [_findOpenN]);
                // alt çubuk arama açıkken de yerinde kalır.
                // BİÇİM PANELİ AÇIKKEN alt çubuk GİZLİ (kullanıcı isteği
                // 2026-10-20: "biçim paneli açılınca alttaki ses, ek vb.
                // kısımlar gizlensin, yazmaya yer kalmıyor"). Panel kendi
                // kapat (⌄) düğmesiyle kapanır.
                // Yazarken gizleme DIŞTA (2026-11-10): içte olunca
                // AnimatedSize onun tek adımlık boy değişimini de 260 ms'lik
                // kare kare yerleşime çeviriyordu.
                // Paket grubu (F60.2): alt çubuk açık paketi kapatmaz.
                // KISA PENCERE + KLAVYE (F67.4): alt çubuk gizli, hızlı satır
                // yeter. Kayıt/dikte sürerken durdur düğmesi kalsın.
                ShortKeyboardBarHide(
                keep: _voiceRecorder != null || _dictating,
                child: TapRegion(
                groupId: kNotePackageTapGroup,
                // WEB/MASAÜSTÜ (kullanıcı 2026-11-24: "tabloda biçim 1-2 sn
                // sonra uygulanıyor"): alt çubuğa fare tıklaması metin
                // alanının "dışarı tıklama"sı sayılıyor, tablo hücresi
                // odağı bırakıp düzenlemeden çıkıyordu. Dokunmatikte bu
                // kural zaten yok. YALNIZ WEBDE kurulur: telefonda ağaç aynı
                // kalsın (S45/S50 dizilme bütçesi).
                child: _webTextTapRegion(TypingBarHide(
                  hidden: _typingN,
                  enabled: ref.watch(hideBarWhileTypingProvider),
                  // Biçim kipi dar dinlenir (P20 M5).
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _formatOpenN,
                    builder: (context, formatOpen, _) => formatOpen
                      ? const SizedBox(width: double.infinity)
                      : _barReturn(
                      _withBottomRuledLines(
                      note,
                      noteBodyStyle,
                      Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // İnce ayraç: kaydırılan metnin son satırı çubuğun hemen
                // üstünde YARIM kesiliyordu ve çubuk sayfanın parçası gibi
                // görünüyordu (kullanıcının 2026-10-11'de işaretlediği alt
                // alan). Çizgili defterde [NotebookRuledBand] ilk çizgiyi
                // zaten üst kenarda çizer; diğer hâllerde sayfa tonunda ayraç.
                if (chrome.dividerColor != null)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: chrome.dividerColor,
                  ),
                if (pageBarDock != null)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: readingColumn
                            ? kReadingWidth
                            : double.infinity,
                      ),
                      child: pageBarDock,
                    ),
                  ),
                // SIKI ÇUBUK (kullanıcı isteği 2026-11-03: "telefon
                // butonları ile kendi butonlarımız arasında boşluk çok,
                // satır aralığını daraltırsak yer açılır"): 64 → 56 dp,
                // dikey dolgu 8 → 4 (düğmeler 48 dp dokunma alanında kalır).
                // %10 daha alçak (kullanıcı isteği 2026-11-08): 56 → 50 dp,
                // dikey dolgu 4 → 1 — en büyük düğme (48 dp) hâlâ sığar.
                BottomAppBar(
                  color: chromeSeeThrough ? Colors.transparent : background,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  height: 50,
                  padding: const EdgeInsets.fromLTRB(12, 1, 12, 1),
                  // KİŞİSELLEŞTİRME (kullanıcı isteği 2026-10-16): her
                  // düğme gizlenebilir; düzenleme modunda hepsi çerçeveli
                  // görünür ve dokunmak gizle/göster yapar (bkz.
                  // Customizable). Çubuk yalnız bu tercihleri dinler.
                  // Okuma sütunuyla hizalı (F44.3); çubuğun zemini tam genişlik.
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: readingColumn
                            ? kReadingWidth - 24
                            : double.infinity,
                      ),
                      child: ListenableBuilder(
                    listenable: Personalize.listenable,
                    builder: (context, _) => LayoutBuilder(
                    builder: (context, constraints) {
                      final editingUi = Personalize.editing;
                      final uiPrefs = Personalize.current;
                      bool on(String id) => editingUi || uiPrefs.shows(id);
                      final showFormat = on(UiItem.barFormat);
                      final showAdd = on(UiItem.barAdd);
                      final showSelect =
                          !note.type.isPageNoteType &&
                          note.items.isNotEmpty &&
                          on(UiItem.barSelect);
                      final showAttachments =
                          fileAttachments.isNotEmpty &&
                          on(UiItem.barAttachments);
                      // KALEM (F75.1): metin/liste notunda sayfa kalemi
                      // (salt okunurda yok — hızlı satırla aynı kural), belge
                      // notunda sayfanın üzerine yazma.
                      final wantPen =
                          (isDocumentNote || !_readOnly) &&
                          on(UiItem.barPen);
                      // SİLGİ (K-S1): metin/liste notunda, yazı kipinde,
                      // mürekkep varken (düzen modunda hep — gizlenebilsin).
                      // Canlı görünürlük [eraserGate]'te: yalnız düğme
                      // `committedRev`'i dinler, çubuk/editör kurulmaz.
                      final eraserInk =
                          !note.type.isPageNoteType &&
                              !_readOnly &&
                              !_penMode &&
                              on(UiItem.barEraser)
                          ? _pageInkOf(note)
                          : null;
                      final showEraser =
                          eraserInk != null &&
                          (editingUi || eraserInk.ink.isNotEmpty);
                      // Dikte SÜRERKEN düğme gizlenmez — durdurma yolu kalsın.
                      final showDictation =
                          _dictating || on(UiItem.barDictation);
                      // SESLİ NOT (kayıt, 2026-10-28): kayıt SÜRERKEN düğme
                      // gizlenmez — bitirme yolu kalsın.
                      final showVoiceRecord =
                          _voiceRecorder != null ||
                          (!_readOnly && on(UiItem.barVoiceRecord));
                      // Türe özgü yuva: metin notunda ☑ (satırı maddeye
                      // çevir); liste notunda LİSTE ↔ NUMARALI (2026-11-16).
                      final listKind =
                          note.type == NoteType.checklist ||
                          note.type == NoteType.ordered;
                      final showCheckbox =
                          (note.type == NoteType.text ||
                              (listKind && !_readOnly)) &&
                          on(UiItem.barCheckbox);
                      // SONRADAN EKLENEN düğmeler (kullanıcı isteği
                      // 2026-11-13: Ayarlar → Kişiselleştir → Alt çubuk).
                      // Varsayılan gizli; açılınca kapsüle sırasıyla girer.
                      final extras = <String>[
                        if (!_readOnly) UiItem.barUndo,
                        if (!_readOnly) UiItem.barRedo,
                        UiItem.barReminder,
                        if (!_readOnly) UiItem.barPhoto,
                        if (!_readOnly && !kIsWeb) UiItem.barCamera,
                        if (!_readOnly && !kIsWeb) UiItem.barScan,
                        UiItem.barColor,
                        if (!_readOnly) UiItem.barDay,
                        if (!_readOnly && !note.type.isPageNoteType)
                          UiItem.barTable,
                        UiItem.barShare,
                      ].where(on).toList();
                      // İKİ KAPSÜL ARASI TAŞIMA (P50; P57'den devir): düğmenin
                      // tarafı kullanıcının ([UiPrefs.barSides]). Plan sola
                      // düşenleri segment, sağa düşenleri AI düğmesi sayar.
                      final sides = uiPrefs.barSides;
                      final rightIds = sides.right.toSet();
                      final penRight = rightIds.contains(UiItem.barPen);
                      final searchRight = rightIds.contains(UiItem.barSearch);
                      final attachRight =
                          showAttachments &&
                          rightIds.contains(UiItem.barAttachments);
                      final wantSearch = on(UiItem.barSearch);
                      // Plana girmeyen (yer varsa da yoksa da çizilen) düğmeler.
                      final fixed = <String>{
                        if (showFormat) UiItem.barFormat,
                        if (showAdd) UiItem.barAdd,
                        if (showCheckbox) UiItem.barCheckbox,
                        if (showSelect) UiItem.barSelect,
                        if (showEraser) UiItem.barEraser,
                        ...extras,
                        if (showVoiceRecord) UiItem.barVoiceRecord,
                        if (showDictation) UiItem.barDictation,
                      };
                      final fixedRight = fixed.where(rightIds.contains).length;
                      final aiCount =
                          fixedRight +
                          (attachRight ? 1 : 0) +
                          (wantPen && penRight ? 1 : 0) +
                          (wantSearch && searchRight ? 1 : 0);
                      // Genişliğe göre plan: taşma/kesik kapsül yerine önce
                      // düğmeler küçülür, sonra ⋮ menüsünde de bulunan
                      // Ara, en son Kalem kapsülden çıkar (bkz.
                      // planEditorBar). Sağa taşınan Ara/Kalem düşürülmez.
                      final plan = planEditorBar(
                        width: constraints.maxWidth,
                        fixedSegments: fixed.length - fixedRight,
                        attachments: showAttachments && !attachRight,
                        pen: wantPen && !penRight,
                        search: !searchRight,
                        aiButtons: aiCount,
                      );
                      final showPen = wantPen && (penRight || plan.pen);
                      final showSearch =
                          wantSearch && (searchRight || plan.search);
                      final shown = <String>{
                        ...fixed,
                        if (showAttachments) UiItem.barAttachments,
                        if (showPen) UiItem.barPen,
                        if (showSearch) UiItem.barSearch,
                      };
                      // Biçim · Ekle · Kalem · Ara · Ekler · (☑ | Seç).
                      // Gerekçeler:
                      // "Metin/Liste ekle" Ekle levhasında (attach_sheet);
                      // SEÇ burada (2026-08-09), simgesi `select_all`
                      // (2026-09-01: `checklist` "liste ekle" ile
                      // karışıyordu), madde yoksa gizli; ARA alt çubukta
                      // (2026-09-01) ve ⋮ menüsünde de; PAYLAŞ'ın yerine
                      // KALEM (K-D6, 2026-11-12 — Paylaş ⋮ menüsünün hızlı
                      // satırında); EKLER şeridin aç/kapası (2026-08-08).
                      Widget tool(
                        String id,
                        IconData icon,
                        String label,
                        VoidCallback onTap, {
                        bool active = false,
                      }) => Customizable(
                        id: id,
                        child: _toolSegment(
                          icon: icon,
                          label: label,
                          active: active,
                          onTap: onTap,
                        ),
                      );
                      // Kimlik → düğme(ler). Sıra KULLANICININ
                      // ([UiPrefs.barOrder]); varsayılan sıra
                      // [UiItem.barLeftDefault] (türe özgü ☑/Seç sonda).
                      // Kimlik → (simge, ad, iş, etkin): düğme HANGİ kapsülde
                      // olursa olsun aynı işi yapar; yalnız kılığı değişir
                      // (solda araç segmenti, sağda vurgu renkli düğme).
                      (IconData, String, VoidCallback, bool) spec(String id) =>
                          switch (id) {
                            UiItem.barFormat => (
                              Icons.text_format,
                              l10n.formatTitle,
                              () {
                                // Önce yer değiştirme bayrağı: kapanınca
                                // dönen çubuk RevealUp ile gelsin.
                                final open = !_formatBarOpen;
                                _barSwapped = true;
                                _formatBarOpen = open;
                                if (open) {
                                  if (_penMode) _update(() => _penMode = false);
                                  if (_dictating) {
                                    unawaited(_stopDictation());
                                  }
                                }
                              },
                              _formatBarOpen,
                            ),
                            UiItem.barAdd => (
                              Icons.add_rounded,
                              l10n.addAttachment,
                              _showAttachMenu,
                              false,
                            ),
                            UiItem.barPen => (
                              Icons.draw_outlined,
                              !note.type.isPageNoteType
                                  ? l10n.quickRowPen
                                  : (_penMode
                                        ? l10n.annotateDone
                                        : l10n.annotate),
                              note.type.isPageNoteType
                                  ? _toggleAnnotate
                                  : _togglePen,
                              _penMode,
                            ),
                            UiItem.barEraser => (
                              Icons.auto_fix_normal_outlined,
                              l10n.editorBarEraser,
                              () => _openEraser(note),
                              false,
                            ),
                            UiItem.barSearch => (
                              Icons.search,
                              l10n.noteSearchTitle,
                              _openNoteSearch,
                              false,
                            ),
                            UiItem.barAttachments => (
                              Icons.attach_file,
                              l10n.showAttachments,
                              () => ref
                                  .read(attachmentsExpandedProvider.notifier)
                                  .toggle(),
                              ref.watch(attachmentsExpandedProvider),
                            ),
                            UiItem.barCheckbox => switch (note.type) {
                              NoteType.checklist => (
                                Icons.format_list_numbered_rounded,
                                l10n.listToNumbered,
                                _toggleListKind,
                                false,
                              ),
                              NoteType.ordered => (
                                Icons.checklist_rounded,
                                l10n.listToChecklist,
                                _toggleListKind,
                                false,
                              ),
                              _ => (
                                Icons.check_box_outlined,
                                l10n.checkboxToggle,
                                _toggleChecklistLine,
                                false,
                              ),
                            },
                            UiItem.barSelect => (
                              Icons.select_all,
                              l10n.select,
                              () => _itemsEditorKey.currentState
                                  ?.startSelection(),
                              false,
                            ),
                            UiItem.barUndo => (
                              Icons.undo,
                              l10n.undo,
                              () {
                                if (_canUndo) _undo();
                              },
                              false,
                            ),
                            UiItem.barRedo => (
                              Icons.redo,
                              l10n.redo,
                              () {
                                if (_canRedo) _redo();
                              },
                              false,
                            ),
                            UiItem.barReminder => (
                              Icons.alarm_add_outlined,
                              l10n.quickRowReminder,
                              () => unawaited(_pickReminder()),
                              false,
                            ),
                            UiItem.barPhoto => (
                              Icons.add_photo_alternate_outlined,
                              l10n.quickRowPhoto,
                              () {
                                _rememberCaret();
                                unawaited(_pickImage());
                              },
                              false,
                            ),
                            UiItem.barCamera => (
                              Icons.photo_camera_outlined,
                              l10n.quickRowCamera,
                              () {
                                _rememberCaret();
                                unawaited(_takePhoto());
                              },
                              false,
                            ),
                            UiItem.barScan => (
                              Icons.document_scanner_outlined,
                              l10n.quickRowScan,
                              () => unawaited(_scanDocument()),
                              false,
                            ),
                            UiItem.barColor => (
                              AppIcons.color,
                              l10n.color,
                              () => unawaited(_showColorSheet()),
                              false,
                            ),
                            UiItem.barDay => (
                              Icons.edit_calendar_outlined,
                              l10n.quickRowDay,
                              _insertDay,
                              false,
                            ),
                            UiItem.barTable => (
                              Icons.table_chart_outlined,
                              l10n.tableInsert,
                              _insertTable,
                              false,
                            ),
                            UiItem.barVoiceRecord => (
                              AppIcons.voiceRecord,
                              _voiceRecorder == null
                                  ? l10n.recordAudio
                                  : l10n.stopAndSave,
                              () => unawaited(
                                _voiceRecorder == null
                                    ? _recordAudio()
                                    : _finishVoiceRecording(),
                              ),
                              _voiceRecorder != null,
                            ),
                            UiItem.barDictation => (
                              _dictating ? Icons.stop : AppIcons.dictation,
                              l10n.liveDictation,
                              () => unawaited(_toggleDictation()),
                              _dictating,
                            ),
                            _ => (
                              Icons.share_outlined,
                              l10n.share,
                              () => unawaited(_share()),
                              false,
                            ),
                          };
                      // Mürekkep silinince/gelince (eşitleme, geri al) silgi
                      // kendi kendine kaybolur/belirir.
                      Widget eraserGate(Widget child) => editingUi
                          ? child
                          : ValueListenableBuilder<int>(
                              valueListenable: eraserInk!.committedRev,
                              builder: (context, _, _) => eraserInk.ink.isEmpty
                                  ? const SizedBox.shrink()
                                  : child,
                            );
                      // SOL kapsüldeki kılık: Biçim (+ imleç rozetleri),
                      // Ekle, Kalem ve Ekler'in kendi segmenti var.
                      List<Widget> leftOf(String id) {
                        final (icon, label, onTap, active) = spec(id);
                        return switch (id) {
                          UiItem.barFormat => [
                            tool(id, icon, label, onTap, active: active),
                            // Panel kapalıyken imlecin biçimleri (B/I/U, renk).
                            ActiveFormatBadges(target: _formatTargetN),
                          ],
                          UiItem.barAdd => [
                            Customizable(id: id, child: _addToolButton(l10n)),
                          ],
                          UiItem.barPen => [
                            Customizable(
                              id: id,
                              child: _penSegment(l10n, note),
                            ),
                          ],
                          // EKLER (F12.3): yalnız ekli notta; plan
                          // (planEditorBar) eki hesaba katar.
                          UiItem.barAttachments => [
                            Customizable(
                              id: id,
                              child: _attachmentsToggle(
                                l10n,
                                fileAttachments.length,
                              ),
                            ),
                          ],
                          UiItem.barEraser => [
                            eraserGate(
                              tool(id, icon, label, onTap, active: active),
                            ),
                          ],
                          _ => [tool(id, icon, label, onTap, active: active)],
                        };
                      }

                      // SAĞ kapsüldeki kılık: vurgu düğmesi.
                      Widget rightOf(String id) {
                        final (icon, label, onTap, active) = spec(id);
                        if (id == UiItem.barEraser) {
                          return eraserGate(
                            Customizable(
                              id: id,
                              child: _voiceButton(
                                size: plan.button,
                                gap: plan.gap,
                                tooltip: label,
                                icon: icon,
                                onTap: onTap,
                              ),
                            ),
                          );
                        }
                        return Customizable(
                          id: id,
                          child: _voiceButton(
                            size: plan.button,
                            gap: plan.gap,
                            tooltip: label,
                            icon: icon,
                            active: active,
                            onTap: onTap,
                          ),
                        );
                      }

                      // TELEFONDA EN ÇOK 4 YUVA (kullanıcı isteği U6,
                      // 2026-11-18: "alttaki 5 düğme 4 olsun, en sağdaki ⋮
                      // kalanları küçük pencerede göstersin"): ilk üç düğme
                      // yerinde, gerisi ⋮'de. Tablette/geniş ekranda hepsi;
                      // düzenleme kipinde hepsi (gizle/göster yapılabilsin).
                      // ⋮ MENÜSÜ HEPSİNİ TAŞIR (kullanıcı isteği 2026-11-19:
                      // "3 noktada diğer butonlar eksik"): çubuktan kaldırılmış
                      // ama bu notta çalışan her düğme de menüde; menünün
                      // "Düzenle"si hangisinin çubukta duracağını seçer.
                      final leftIds = [
                        for (final id in sides.left)
                          if (shown.contains(id)) id,
                      ];
                      bool usable(String id) =>
                          !(Personalize.aiOff.value &&
                              UiModule.ai.items.contains(id)) &&
                          switch (id) {
                            UiItem.barSelect =>
                              !note.type.isPageNoteType &&
                                  note.items.isNotEmpty,
                            UiItem.barAttachments => fileAttachments.isNotEmpty,
                            UiItem.barPen => isDocumentNote || !_readOnly,
                            UiItem.barCheckbox =>
                              note.type == NoteType.text ||
                                  (listKind && !_readOnly),
                            UiItem.barUndo ||
                            UiItem.barRedo ||
                            UiItem.barPhoto => !_readOnly,
                            UiItem.barCamera ||
                            UiItem.barScan => !_readOnly && !kIsWeb,
                            UiItem.barVoiceRecord ||
                            UiItem.barDay => !_readOnly,
                            UiItem.barTable =>
                              !_readOnly && !note.type.isPageNoteType,
                            UiItem.barFormat ||
                            UiItem.barAdd ||
                            UiItem.barSearch ||
                            UiItem.barReminder ||
                            UiItem.barColor ||
                            UiItem.barShare ||
                            UiItem.barDictation => true,
                            // Silgi yalnız mürekkep varken anlamlı (çubukta
                            // kendi kapısı var); menüye girmez.
                            _ => false,
                          };
                      final available = [
                        for (final id in [...sides.left, ...sides.right])
                          if (usable(id) || shown.contains(id)) id,
                      ];
                      final menuIds = editingUi
                          ? const <String>[]
                          : [
                              for (final id in available)
                                if (!shown.contains(id)) id,
                            ];
                      final phone = !editingUi && !PenTray.useRail(context);
                      final cap =
                          !phone
                          ? leftIds.length
                          : (leftIds.length > kEditorBarPhoneSlots ||
                                    menuIds.isNotEmpty
                                ? kEditorBarPhoneSlots - 1
                                : kEditorBarPhoneSlots);
                      final overflow = [
                        ...leftIds.skip(cap),
                        ...menuIds,
                      ];
                      // Geri al / Geri getir çubuk taşmasıyla ayrışmasın:
                      // ikisi de menüdeyse yan yana dursun.
                      final undoAt = overflow.indexOf(UiItem.barUndo);
                      final redoAt = overflow.indexOf(UiItem.barRedo);
                      if (undoAt >= 0 && redoAt > undoAt + 1) {
                        overflow
                          ..removeAt(redoAt)
                          ..insert(undoAt + 1, UiItem.barRedo);
                      }
                      final segments = <Widget>[
                        for (final id in leftIds.take(cap)) ...leftOf(id),
                        if (overflow.isNotEmpty)
                          _barOverflow(
                            l10n,
                            overflow,
                            available: available,
                            spec: spec,
                          ),
                      ];
                      return Row(
                        children: [
                          // Kapsül YATAY KAYAR ve `Expanded` içinde: segment
                          // sayısı nota göre değişiyor (Biçim + Ekle + Ekler +
                          // Seç). Segmentler Keep gibi yalnız SİMGE olduğundan
                          // dördü de en dar telefona sığar; kaydırma yalnız çok
                          // büyük sistem yazı ölçeğinde devreye giren son çare.
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              // Dolgu Row'un DIŞINDA değil içinde (F75.2):
                              // Row kapsülün tam boyunda (48 dp) olmalı ki
                              // segmentlerin dokunma payı (bkz. _barTarget)
                              // yakalansın. Görünüş aynı: çerçeve 1 + dolgu 3.
                              child: DecoratedBox(
                                key: const ValueKey('editor-tool-capsule'),
                                // Renkli/temalı/defter notta sayfa tonu (F75.3, K-D6).
                                decoration: BoxDecoration(
                                  color: chrome.toolCapsuleFill,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: chrome.toolCapsuleBorder,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: SizedBox(
                                  height: _NoteEditorScreenState._kToolSegment + 8,
                                  child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var i = 0;
                                        i < segments.length;
                                        i++) ...[
                                      if (i > 0)
                                        const SizedBox(
                                          width: kEditorBarSegmentGap,
                                        ),
                                      segments[i],
                                    ],
                                  ],
                                ),
                                ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // AI + SES TEK KAPSÜLDE (kullanıcı isteği
                          // 2026-10-11: "işaretli alanlar mantıklı biçimde
                          // düzenlenmeli"). Üç ayrı gölgeli kare düğme
                          // çubuğun yarısını kaplıyor, soldaki araç
                          // kapsülüyle iki farklı dil konuşuyordu. Şimdi
                          // çubuk İKİ GRUP: solda düzenleme araçları (yüzey
                          // renginde), sağda yapay zekâ ve ses (vurgu
                          // renginde). Parıltı = AI levhası (en üst satırı
                          // "AI ile sesli not", 2026-10-20), sade mikrofon =
                          // doğrudan yazdırma (bkz. [_toggleDictation]).
                          if (aiCount > 0)
                            _aiCapsule(
                              segment: plan.button,
                              gap: plan.gap,
                              children: [
                                for (final id in sides.right)
                                  if (shown.contains(id)) rightOf(id),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                  ),
                    ),
                  ),
                ),
                ],
                ),
                      ),
                    ),
                  ),
                ))
                ),
                ),
              ],
            ),
          );
    return (findSlot: findSlot, bottomBar: bottomBar);
  }
}
