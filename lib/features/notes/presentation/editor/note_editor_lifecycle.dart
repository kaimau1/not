part of 'note_editor_screen.dart';

extension _NoteEditorLifecycle on _NoteEditorScreenState {
  void _pulseAttachBadge(int count) {
    final previous = _lastAttachmentCount;
    _lastAttachmentCount = count;
    // İlk çizim referans alınır: notu AÇMAK yanıp sönmeyi tetiklemesin.
    if (previous == null || count <= previous) return;
    // Sistemde "hareketi azalt" açıksa animasyon yok.
    if (MediaQuery.disableAnimationsOf(context)) return;
    _attachPulse
      ..reset()
      ..repeat(reverse: true, count: 4);
  }

  void _scheduleBodyTopMeasure() {
    if (_bodyTopScheduled) return;
    _bodyTopScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bodyTopScheduled = false;
      if (mounted) _measureBodyTop();
    });
  }

  void _measureBodyTop() {
    final box = _bodyTopKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final h = box.size.height;
    if ((h - _bodyTop).abs() < 0.5) return;
    _bodyTopN.value = h;
  }

  /// KÖK NEDEN (kullanıcı bulgusu 2026-11-24: "notlar açılıp kapanırken,
  /// klavye açılıp kapanırken kasma, donma"): burası `setState` idi — yüzen
  /// kutulu (tablo) notta açılışta ve kutu boyu oturunca editörün tamamı ve
  /// bütün madde satırları baştan kuruluyordu (380 maddede kare başına ~2000
  /// kurulum, masaüstünde bile 140 ms). Bantlar artık [_floatsN] ile yalnız
  /// ölçen katmanlara gider.
  void _applyFloats(List<FloatBox> floats) {
    if (sameFloatList(_floats, floats)) return;
    _floats = floats;
    _floatsN.value = floats;
  }

  /// Metin alanını sarma ölçümüne bağlar (görsel yoksa maliyetsiz geçer).
  Widget _wrapped(WrapTextController controller, Widget field) {
    // Ölçüm, çizimle AYNI stili kullanmalı (notun yazı tipi/boyutu dahil);
    // ayrışırsa satırlar farklı kırılır ve imleç kayar.
    final style = _noteTextStyle();
    if (style == null) return field;
    return WrapFieldMeasure(
      controller: controller,
      style: style,
      floats: const [],
      // Bant değişince yalnız ölçer; editör kurulmaz.
      floatsListenable: _floatsN,
      pageBox: _pageBox,
      // Bantlar alanın KUTUSUNA göre ölçülüyor, plan ise METİN uzayında
      // çalışıyor: aradaki iç dolgu düşülmezse metin görselin altına bir
      // dolgu boyu FAZLA iniyor (bkz. WrapFieldMeasure.textTop).
      textTop: _NoteEditorScreenState._kBodyTextTop,
      child: field,
    );
  }

  /// Klavye açıkken her metin değişiminde çağrılır; durunca çubuk geri gelir.
  /// Süreler AYARLANABİLİR (F60.S7): gizlenme gecikmesi (varsayılan 0) ve
  /// yeniden görünme gecikmesi (varsayılan 1,1 sn) — Ayarlar → Kartlar.
  void _noteTyping() {
    if (_keyboardInset <= 0 || !ref.read(hideBarWhileTypingProvider)) return;
    // DİKTE YAZMA DEĞİL (kullanıcı bulgusu 2026-11-15, S46): tanıyıcının
    // metni de `_mutate`'ten geçiyor; sayılınca alt çubuk (Bitir düğmesi ve
    // üstündeki ses kartıyla) her konuşma patlamasında iniyor, duraklamada
    // kalkıyordu — kart zıplıyor, gövde her seferinde yeniden diziliyordu.
    if (_dictating) return;
    // ÜÇ HARF KURALI (kullanıcı isteği 2026-11-08 üçüncü tur): çubuk tek
    // harflik düzeltmede / tek dokunuşta gitmesin; ancak duraklamasız art
    // arda 3 değişiklikten sonra (gerçekten yazılıyorsa) gizlenir. Sayaç,
    // duraklama zamanlayıcısı dolunca ([_showBarNow]) sıfırlanır.
    _typedBurst++;
    _typingTimer?.cancel();
    _recentKey?.cancel();
    _recentKey = Timer(_NoteEditorScreenState._kStillTyping, () {});
    if (_typingN.value) {
      // Gizli: son tuştan "yeniden görünme gecikmesi" kadar sonra gelir.
      _typingTimer = Timer(
        _NoteEditorScreenState._tenths(ref.read(typingBarShowDelayProvider)),
        _showBarNow,
      );
      return;
    }
    // Görünür: duraklama sayacı sıfırlar (ve bekleyen gizlemeyi iptal eder).
    _typingTimer = Timer(_NoteEditorScreenState._kTypingPause, _showBarNow);
    if (_typedBurst < 3) return;
    final delay = _NoteEditorScreenState._tenths(
      ref.read(typingBarHideDelayProvider),
    );
    if (delay == Duration.zero) {
      _hideBarNow();
    } else {
      // Gecikme 3. değişiklikten sayılır; sonraki tuşlar uzatmaz.
      _hideTimer ??= Timer(delay, _hideBarNow);
    }
  }

  void _hideBarNow() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!mounted || _typingN.value) return;
    // Bu arada klavye kapandıysa ya da ayar kapatıldıysa gizlenmez.
    if (_keyboardInset <= 0 || !ref.read(hideBarWhileTypingProvider)) return;
    // Gecikme doldu ama yazma durmuş: gizleme; sonraki tuş yeniden sayar.
    if (_recentKey?.isActive != true) return;
    _typingN.value = true;
    final prefs = ref.read(sharedPreferencesProvider);
    if (TipOnce.due(prefs, TipOnce.typingBarHide, sessionLimit: false)) {
      TipOnce.show(
        context,
        prefs,
        TipOnce.typingBarHide,
        context.l10n.tipHideBarTyping,
        sessionLimit: false,
      );
    }
    // Gizlendiği andan itibaren yeniden görünme gecikmesi işler.
    _typingTimer?.cancel();
    _typingTimer = Timer(
      _NoteEditorScreenState._tenths(ref.read(typingBarShowDelayProvider)),
      _showBarNow,
    );
  }

  /// Alt çubuk HEMEN geri gelir: yeni maddeye/alana geçince ve klavye
  /// kapanınca (kullanıcı isteği 2026-11-08) — beklemeden.
  void _showBarNow() {
    _typingTimer?.cancel();
    _typingTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    _typedBurst = 0;
    if (_typingN.value) _typingN.value = false;
  }

  void _clearFormatTargetFor(WrapTextController controller) {
    AutoSpell.detach(controller);
    // Alan yok oluyor: hem dinleyicisi hem de ondan hatırlanan seçim düşer,
    // yoksa [_finishPendingEmbed] ölü bir denetleyiciye yazmayı denerdi.
    controller.removeListener(_onTargetSelection);
    if (_lastSelectionTarget?.controller == controller) {
      _lastSelectionTarget = null;
      _lastSelection = null;
    }
    if (_formatTarget?.controller != controller) return;
    _formatTarget = null;
    // Bildirim build'den sonra (bu kapanış build sırasında da gelebilir).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formatTargetN.value = _formatTarget;
    });
    // Açık panel bu bildirimi [_formatPanelL] ile dinler (P20 M5): kök
    // setState yok. Bildirim kareye ertelendi (KÖK NEDEN çökme: kapanış
    // alanın build fazındaki dispose'undan da gelebiliyor).
  }

  void _setFormatTarget(
    WrapTextController controller,
    FocusNode focusNode,
    VoidCallback commit, {
    ValueNotifier<TextAlign>? align,
  }) {
    final changed = _formatTarget?.controller != controller;
    if (changed) {
      // SON DOLU SEÇİM dinleyicisi hep ETKİN alanda durur (bkz.
      // [_lastSelection]): madde satırına geçen kullanıcı orada seçtiği
      // yazıya da ek bağlayabilsin. Önce kaldır-sonra ekle: aynı dinleyici
      // iki kez kayıtlı kalmasın (gövde initState'te de kaydediliyor).
      _formatTarget?.controller.removeListener(_onTargetSelection);
      controller
        ..removeListener(_onTargetSelection)
        ..addListener(_onTargetSelection);
    }
    _formatTarget = FormatTarget(
      controller: controller,
      focusNode: focusNode,
      commit: commit,
      align: align,
    );
    // Yazım düzelt (hızlı satır): her alan; başlıkta kelime başları büyür
    // (2026-11-08).
    AutoSpell.attach(controller, commit, title: controller == _titleController);
    if (changed) {
      _formatTargetN.value = _formatTarget;
      // Yeni maddeye/alana geçildi: gizlenmiş alt çubuk hemen gelir. Bildirim
      // odak dinleyicisinden (build dışı) geliyor; yine de kareye ertelenir.
      if (_typingN.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showBarNow();
        });
      }
    }
    _onAnyFocusChange();
    // Alan yeni odaklandı: imleci klavyenin üstüne al. Bu kapanış gövde,
    // başlık ve madde satırlarının HEPSİNDEN geçtiği için tek yer yeter.
    _revealCaretSoon();
    // Çubuk AÇIKKEN hedef değişmesi çizimi etkiler: panel [_formatTargetN]'i
    // dinliyor (yukarıda güncellendi) — kök setState yok (P20 M5).
  }

  /// Seçimdeki tüm biçimleri siler.
  void _clearFormat() => _runOnTarget(clearRichFormat);

  /// Biçim çubuğunun hedefinde SEÇİLİ metin var mı?
  bool _hasSelection() {
    final selection = _formatTarget?.controller.selection;
    return selection != null && selection.isValid && !selection.isCollapsed;
  }

  /// Notun kendi yazı tipi/boyutu uygulanmış gövde stili (ölçüm ve çizim
  /// ortak kaynağı).
  TextStyle? _noteTextStyle() {
    final base = _themeOf(context).textTheme.bodyLarge;
    final note = _note;
    if (base == null || note == null) return base;
    return applyNoteFont(
      base.copyWith(fontSize: (base.fontSize ?? 16) * note.fontScale),
      note.fontFamily,
    );
  }

  void _setBase(Note note) {
    _baseTitle = note.title;
    _baseBody = note.body;
    _baseItems = note.items;
  }

  /// Başlıkta klavyenin "İleri" tuşu: odak çip satırına değil İÇERİĞE geçer
  /// (gövde; gövde alanı yoksa ilk madde). Varsayılan `nextFocus` odağı metin
  /// dışına taşıyıp klavyeyi kapatıyordu.
  void _focusAfterTitle() {
    final note = _note;
    if (note == null) return;
    final hasBody =
        note.type == NoteType.text ||
        note.body.trim().isNotEmpty ||
        _listBodyOpen;
    if (hasBody) {
      _bodyFocus.requestFocus();
    } else {
      _itemsEditorKey.currentState?.focusFirstItem();
    }
  }

  /// F22.3: oturumda istemci saatli kayıt olduysa `updatedAt`i bir kez
  /// sunucu zamanıyla yazar ([_saveNow] zaten sunucu zamanıyla yazdıysa
  /// bayrak inmiş olur, ikinci yazım yok).
  void _stampServerTimeOnExit() {
    if (!_clientStamped || _deleted) return;
    _clientStamped = false;
    _notesRepo?.updateFields(widget.noteId, const {});
  }

  /// F23.3: not karttan küçülerek kapanırken bekleyen otomatik kayıt
  /// zamanlayıcısı DURUR — yazım + ardından gelen koleksiyon olayının
  /// kodlaması (K3) kapanış karelerine binmesin. Kayıt kaybolmaz: rota
  /// kalkınca [dispose] içindeki [_saveNow] yazar; geri çekme jesti
  /// vazgeçilirse zamanlayıcı yeniden kurulur.
  ///
  /// **KAPANIŞ KASMASI (2026-11-08):** sıralama tutması burada BIRAKILMAZ —
  /// eskiden kapanışın ilk karesinde (mikro görev) bırakılıyordu: o karede
  /// zaten panonun duraklatılmış abonelikleri sürüp `filteredNotesProvider`
  /// yeniden hesaplanıyor (F23.2 ölçümü ~3-4 ms) ve tutma bırakılınca İKİNCİ
  /// kez hesaplanıp pano ekranı yeniden kuruluyordu. Görünür faydası da yoktu:
  /// pano kapanış boyunca `FreezeWhenHidden` ile DONUK, küçülen not kartın
  /// donuk (eski) yerine iner. Bırakma rota kalkınca ([dispose]); yeni sıra
  /// panonun kapanış sonrası yetişmesine (+120 ms) katılır.
  void _handleHoldSaveWhileClosing() {
    if (noteRouteClosing.value) {
      _debouncer.pause();
    } else {
      _debouncer.resume();
    }
  }

  /// **NOTTA TARİH ÖNERİSİ** (TAKVIM F52.3): az önce düzenlenmiş notun son
  /// satırlarında zaman ifadesi varsa ve notun hatırlatıcısı yoksa, kapanışta
  /// tek bildirim: "Takvime ekle?". Yazarken hiçbir şey çalışmaz (tuş
  /// başına iş yok — akıcılık bütçesi); yalnız çıkışta bir kez ayrıştırılır.
  void _suggestCalendar(bool readOnly) {
    final note = _note;
    // `_readOnly` değil: ref atılırken okunamaz.
    if (note == null || readOnly || note.locked || note.reminderAt != null) {
      return;
    }
    final edited = note.updatedAt;
    if (edited == null ||
        DateTime.now().difference(edited) > const Duration(minutes: 3)) {
      return;
    }
    final text = note.toPlainText();
    final hit = noteDateSuggestion(
      text.length > 2000 ? text.substring(text.length - 2000) : text,
      parseSpokenDateTimeNow,
    );
    if (hit == null ||
        !_NoteEditorScreenState._suggested.add('${note.id}|${hit.at}')) {
      return;
    }
    final messenger = rootScaffoldMessengerKey.currentState;
    final navigator = _rootNavigator;
    if (messenger == null || navigator == null || !navigator.mounted) return;
    final navContext = navigator.context;
    final l10n = AppLocalizations.of(navContext);
    final title = note.displayTitle.trim().isEmpty
        ? hit.line
        : note.displayTitle.trim();
    final noteId = note.id;
    unawaited(
      Future.microtask(
        () => messenger.showMessage(
          l10n.calendarSuggest(DateFormat.MMMEd().add_Hm().format(hit.at)),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: l10n.calendarSuggestAction,
            onPressed: () {
              if (!navigator.mounted) return;
              unawaited(
                showEventEditor(
                  navigator.context,
                  start: hit.at,
                  linkNoteId: noteId,
                  initialTitle: title,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Dashboard akışında zaten yüklü olan notu senkron döndürür (varsa).
  /// İlk kareyi dolu kurup açılış kasmasını önlemek için kullanılır.
  Note? _cachedNote() {
    // Paylaşılan not BENİM akışımda yok (sahibinin koleksiyonunda yaşıyor);
    // önbelleğe bakmak en iyi ihtimalle boşuna, en kötüsünde yanlış notu
    // gösterir.
    if (widget.ownerId != null) return null;
    final notes = ref.read(notesStreamProvider).value;
    if (notes == null) return null;
    for (final n in notes) {
      if (n.id == widget.noteId) return n;
    }
    return null;
  }

  /// Son değişikliği geri alır (araç çubuğundaki düğme ve Ctrl+Z).
  void _undo() {
    final note = _note;
    if (note == null) return;
    final previous = _undoStack.undo(note);
    if (previous == null) return;
    _restoring = true;
    // Metin alanları nottan beslenmiyor (kendi denetleyicileri var); geri
    // alınan gövde/başlık elle yazılmazsa ekranda eski metin kalırdı.
    _titleController.text = previous.title;
    _bodyController.text = previous.body;
    _mutate((_) => previous, immediate: true);
    _restoring = false;
    _syncPageInk(previous);
    _syncUndoN();
    _showSnack(context.l10n.undone);
  }

  /// Geri alınan değişikliği yineler (düğme + Ctrl+Y / Ctrl+Shift+Z).
  void _redo() {
    final note = _note;
    if (note == null) return;
    if (note.type.isPageNoteType) FocusManager.instance.primaryFocus?.unfocus();
    final next = _undoStack.redoStep(note);
    if (next == null) return;
    _restoring = true;
    _titleController.text = next.title;
    _bodyController.text = next.body;
    _mutate((_) => next, immediate: true);
    _restoring = false;
    _syncPageInk(next);
    _syncUndoN();
  }

  /// Geri alınan/yinelenen sayfa çizgileri canlı denetleyiciye (KW-11).
  /// KÖK NEDEN: çizgi değişimi "saf yazım" sayılır ([_sameVisual] çizgiye
  /// bakmaz — her çizgide ekran kurulmasın), ekran yeniden kurulmadığı için
  /// [_pageInkOf]'un eşitlemesi de çalışmıyor; "Geri alındı" denip çizgiler
  /// ekranda kalıyordu.
  void _syncPageInk(Note restored) {
    final ink = _pageInkCtl;
    if (ink != null && !identical(ink.ink, restored.pageInk)) {
      ink.replaceAll(restored.pageInk);
    }
  }

  /// Açılışta belgesiz belge notu onarılır — "PDF/sunum ekle" niyetiyle
  /// açılan boş not HARİÇ (belge seçiciden birazdan gelecek).
  Note _repairOrphanDocumentMode(Note n) {
    if (widget.startPdf || widget.startSlides) return n;
    return _NoteEditorScreenState._withoutOrphanDocumentMode(n);
  }

  /// Bu editörün otomatik kaydı Lite aralığıyla mı yazılmalı
  /// ([liteHoldsCloudWrite]).
  bool _liteHolds() {
    final note = _note;
    final repo = _notesRepo;
    if (note == null || repo == null || !ref.read(liteSyncProvider)) {
      return false;
    }
    return liteHoldsCloudWrite(
      lite: true,
      ownNote: widget.ownerId == null,
      sharedByMe: noteSharedByMe(ref, note),
      deviceOnly: repo.isLocal(note.id),
      journalReady: repo.canJournal,
    );
  }

  /// Günlük tiki: buluta henüz gitmemiş en son hâl diske (çökmeye karşı).
  void _journalPending() {
    final note = _note;
    if (note == null || _deleted || !_debouncer.hasPending) return;
    _notesRepo?.journalNote(note);
  }

  /// Lite'ta "şimdi eşitle" (editördeki bulut simgesine dokunuş).
  void _syncNowLite() {
    _saveNow();
    _showSnack(context.l10n.liteSyncSending);
  }

  /// İmlecin yerini görsel eklenmeden önce saklar (bkz. [_caretPageY]).
  void _rememberCaret() {
    final top = _caretPageTop();
    if (top != null) _caretPageY = top;
  }

  /// Alt bardaki bir düğme (görünüm/renk, ek, hesap makinesi) alt sayfa/menü
  /// açmadan önce klavyeyi kesin kapatır. Klavye elle kapatılmış olsa bile bir
  /// metin alanı odakta kalabiliyor; alt sayfa kapanınca odak geri gelip
  /// klavye kendiliğinden açılıyordu (madde 10). Odağı düşürüp sonraki karede
  /// tekrar düşürerek bu geri açılmayı engelliyoruz.
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  /// Klavye açıkken LEVHA açılışı (kullanıcı bulgusu 2026-11-16: "klavye
  /// açıkken + ve ⋮ menüsü kasarak açılıyor"). Levhanın ilk karesi (tüm
  /// karolar: ~500 dizilme) klavyenin iniş animasyonunun ilk karesiyle aynı
  /// kareye düşüyordu: odak kaybı + klavye kareleri + levha kurulumu üst üste.
  /// Şimdi levha odağı ALMADAN açılır (`requestFocus: false`), klavye levhanın
  /// ilk karesi çizildikten SONRA iner — ağır kare durgun ekranda, iniş
  /// kareleri hafif. Klavye kapalıysa eski yol. Döndürülen değer levhaya
  /// verilecek `requestFocus`tur.
  bool? _dismissKeyboardAfterSheet() {
    final keyboardUp =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .viewInsets
            .bottom >
        0;
    if (!keyboardUp) {
      _dismissKeyboard();
      return null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _dismissKeyboard());
    return false;
  }

  /// Öğrenen yazım düzeltmenin ve altı çizili denetimin kişisel sözlüğü:
  /// notların metni (arka planda, oturumda bir kez; yazım kapalıyken hiç).
  Future<void> _seedSpell() async {
    if (!mounted || AutoSpell.mode.value == SpellMode.off) return;
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    await AutoSpell.seedFrom(
      () => [
        for (final n in notes.take(600)) ...[
          n.title,
          n.body,
          for (final i in n.items) i.text,
        ],
      ],
    );
  }

  void _handleAnyFocusChange() {
    if (!mounted) return;
    final node = _formatTarget?.focusNode;
    final on =
        node != null &&
        node.hasFocus &&
        _formatTarget?.controller != _titleController;
    if (_fieldFocusedN.value != on) _fieldFocusedN.value = on;
  }

  /// **ODAKSIZ KISAYOL** (KW-11, web keşfi 2026-11-18: "kalem kipinde
  /// Ctrl+Z çizgiyi geri almıyor"). KÖK NEDEN: metin alanı bırakılınca
  /// (kalem kipi, çizim, açılış) odak ROTANIN kapsamında kalıyor; editörün
  /// [CallbackShortcuts]'ı onun ALTINDA olduğundan Ctrl+Z/Y hiç ulaşmıyordu.
  /// Odaklı kimse yokken (birincil odak bu rotanın kapsamı) tuş burada
  /// yakalanır. Ağaca yeni odak düğümü EKLENMEDİ: kapanan editörün odaklı
  /// düğümü yeni editörün kurulumunda atılmış bağlama bakılmasına yol
  /// açıyordu (S12b). Yan bölme ana editörle yarışmasın diye yalnız ana.
  bool _handleHardKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted || _secondary) return false;
    final scope = _routeScope;
    if (scope == null ||
        !identical(FocusManager.instance.primaryFocus, scope)) {
      return false;
    }
    final keys = HardwareKeyboard.instance;
    if (!keys.isControlPressed && !keys.isMetaPressed) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyZ) {
      keys.isShiftPressed ? _redo() : _undo();
      return true;
    }
    if (key == LogicalKeyboardKey.keyY) {
      _redo();
      return true;
    }
    return false;
  }

  void _initNoteServices() {
    // Yazım v2: "bu notta dokunma" listesi her not için baştan (Faz 70).
    AutoSpell.beginNote();
    unawaited(AutoSpell.load().then((_) => _seedSpell()));
    FocusManager.instance.addListener(_onAnyFocusChange);
    HardwareKeyboard.instance.addHandler(_onHardKey);
    // Tablo hücresi biçim panelinin hedefi olur (2026-11-23).
    NoteTableFocus.cellFocused = _tableCellFocused;
    NoteTableFocus.cellDisposed = _tableCellDisposed;
    InkToolMemory.autoStylusListenable.addListener(_onStylusToggle);
    // Not başına menü düzeni (2026-11-19): bu notun kendi düzeni geçerli.
    Personalize.enterNote(widget.noteId, this);
    _topOrder = Personalize.current.topOrder;
    Personalize.listenable.addListener(_onTopOrder);
    // Kök gezgin: kapanış önerisi (F52.3) editör atıldıktan sonra açılır.
    _rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
    // Uygulama arka plana alınırken/kapatılırken bekleyen kaydı zorlamak için
    // (bkz. [_saveNow] — "kapatınca not kayboluyor" kök nedeni).
    WidgetsBinding.instance.addObserver(this);
    noteRouteClosing.addListener(_holdSaveWhileClosing);
    // Arka plandaki boş not temizliği bu notu ATLASIN (bkz. cleanupEmptyNotes):
    // kullanıcı yazmaya yeni başladığında doküman kısa bir süre boş görünür.
    openEditorNoteIds.add(widget.noteId);
    _NoteEditorScreenState._live.add(this);
    // Listede açık not vurgusu (geniş ekran). Ağaç kurulurken sağlayıcı
    // yazılamaz → mikro görev; dispose'da `ref` yok → notifier saklanır.
    final openNotes = _openNotes = ref.read(openNoteIdsProvider.notifier);
    _focusNote = ref.read(focusedNoteProvider.notifier);
    final openId = widget.noteId;
    unawaited(Future.microtask(() => openNotes.open(openId)));
    // F26.3: açıkken listede yerinde dursun (kapanış başlayınca bırakılır).
    final sortHold = ref.read(sortHeldNoteIdsProvider.notifier);
    _sortHold = sortHold;
    unawaited(Future.microtask(() => sortHold.hold(openId)));
    _previewHold = ref.read(heldNotePreviewProvider.notifier);
    // Notu AÇMAK da bir çalışma izidir ("en çok çalışılan" sıralaması).
    // GEÇİŞ BİTİNCE (kullanıcı bulgusu 2026-10-20: "notu açarken ufak
    // donma"): ilk kareden hemen sonra yazılınca "en çok çalışılan"
    // sıralamasındaki ana ekran, editör kayarak gelirken bütün ızgarasını
    // yeniden kuruyordu. Sayaç beklesin; kimse bunu o anda görmüyor.
    Timer(const Duration(milliseconds: 650), () {
      if (mounted) ref.read(noteActivityProvider.notifier).touch(widget.noteId);
    });
    // dispose'da `ref` kullanılamadığından (bkz. yukarıdaki KÖK NEDEN notu)
    // depo/ayar bağımlılıkları ilk build'den ÖNCE de elde olmalı: yaşam
    // döngüsü kaydı ilk kare çizilmeden gelebilir.
    _cacheDeps();
    _fullscreenNotifier = ref.read(noteFullscreenProvider.notifier);
    // İlk açılış kasması (madde 3): editör başlangıçta _note null olduğu için
    // bir kare boyunca CircularProgressIndicator gösterip ardından tüm editörü
    // kuruyordu; bu geçiş, sayfa animasyonuyla aynı anda büyük bir yerleşim
    // sıçraması yaratıyordu. Not zaten dashboard akışında yüklü olduğundan
    // (kullanıcı oradan geldi) onu SENKRON okuyup ilk kareyi dolu kur —
    // spinner→editör takası ve onunla gelen kasma ortadan kalkar.
    // Uzun basışla seçilen kelime, içinde bulunduğu CÜMLEYE genişletilir —
    // notta seçim neredeyse hep bir cümleyi taşımak/silmek için yapılıyor.
    attachSentenceSelection(_bodyController);
    attachSentenceSelection(_bodyWindow.win);
    attachSentenceSelection(_titleController);
    // Etkin alandaki SON DOLU seçimi sakla (bkz. [_lastSelection]). Gövde
    // açılışta zaten varsayılan hedef; madde satırları odaklanınca
    // [_setFormatTarget] dinleyiciyi oraya taşır.
    _bodyController.addListener(_onTargetSelection);
    // Biçim çubuğu son odaklanan alana yazar; gövde odağı burada bildirilir
    // (maddeler ItemsEditor'dan bildirir).
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) {
        // KÖK NEDEN ("kalın butonuna basıp kalın yazamıyorum"): bekleyen biçim
        // koşu bitince metne yazılır ve koşuyu bitiren en yaygın olay ODAK
        // KAYBIDIR. Bu kapanış yalnız liste satırlarında (ItemsEditor) vardı;
        // gövde ve başlıkta "kalın"a basıp yazan, sonra başka yere dokunan
        // kullanıcının biçmi SESSİZCE kayboluyordu.
        _flushPending(_titleController);
        return;
      }
      _setFormatTarget(
        _titleController,
        _titleFocus,
        () => _mutate(
          (n) => n.copyWith(title: _titleController.logicalText),
          immediate: true,
        ),
      );
    });
    _bodyFocus.addListener(() {
      if (!_bodyFocus.hasFocus) {
        _flushPending(_bodyController);
        // Kapanışta yerleşim yinelenmesin: sayfa zaten gidiyor.
        if (!noteRouteClosing.value) _bodyWindow.exit();
        return;
      }
      _setFormatTarget(
        _bodyController,
        _bodyFocus,
        () => _mutate(
          (n) => n.copyWith(body: _bodyController.logicalText),
          immediate: true,
        ),
      );
    });
    final cached = _cachedNote();
    if (cached != null) {
      _note = _repairOrphanDocumentMode(cached);
      _titleController.text = cached.title;
      _bodyController.text = cached.body;
    }
  }

  void _initPendingIntents() {
    _videoHub.onNoteAt = _noteAtVideoTime;
    _pendingDraw = widget.startDrawing;
    _pendingSeparateDrawing = widget.startSeparateDrawing;
    _placementHintId = widget.placementHintAttachmentId;
    // Web: not açıkken bırakılan/yapıştırılan dosya BU nota girer (F41.4).
    if (!_readOnly) {
      _stopFileDrops = addFileDropHandler(
        (files) => unawaited(_attachFiles(files)),
      );
    }
    _pendingVoice = widget.startVoiceCapture;
    _pendingDictation = widget.startDictation;
    _pendingVideo = widget.startVideo;
    _pendingPhoto = widget.startPhoto;
    _pendingScan = widget.startScan;
    _pendingPdf = widget.startPdf;
    _pendingSlides = widget.startSlides;
    _pendingGalleryVideo = widget.startGalleryVideo;
    _pendingYouTube = widget.startYouTube;
    _pendingTranscribe = widget.startTranscribe;
    _pendingAudioFile = widget.startAudioFile;
    _pendingRevealItem = widget.revealItemId;
    _pendingFind = widget.initialFind;
    _pendingWorkspace = widget.startWorkspace;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPendingIntents());
  }

  void _onIncomingNoteSnapshot(
    Note incoming, {
    required String? owner,
    required void Function(Note loaded) onFirstLoad,
  }) {
    // Paylaşılan notu açık tutmak = bakıyorum: gelen her değişiklik
    // okunmuş sayılır (bkz. sharedNoteUnreadProvider — ana ekran rozeti
    // ve bildirim bu damgaya bakar).
    if (owner != null) {
      ref
          .read(sharedNoteSeenProvider.notifier)
          .markSeen(sharedNoteKey(owner, widget.noteId));
    }
    if (_note == null) {
      // ESKİ DEFTER (F3.5): açılışta sayfalı nota çevrilir ve yazılır.
      final loaded = incoming.type == NoteType.archive
          ? notebookToPagedNote(incoming, pageId: (_) => const Uuid().v4())
          : _repairOrphanDocumentMode(incoming);
      onFirstLoad(loaded);
      // Açıldığı hâl ilk değişiklikte sürüm olur (F4.2).
      if (!_readOnly) _notesRepo?.rememberVersionBase(loaded);
      _setBase(incoming);
      if (!identical(loaded, incoming) && !_readOnly) {
        unawaited(_notesRepo?.updateNote(loaded));
      }
      // Not eline geçti: bekleyen sesli not/çizim niyeti şimdi çalışır.
      _runPendingIntents();
    } else {
      // Not BAŞKA yerden çöpe atıldı (geniş ekranda soldaki kartın menüsü
      // ya da ikinci cihaz). Editör tam dokümanı `deletedAt: null` ile
      // yazdığından, kalan tek harflik bir yazım bile notu çöpten sessizce
      // DİRİLTİYORDU. Kayıt durdurulur ve editör kapatılır — kart menüsünün
      // "Geri al" snackbar'ı zaten ekranda.
      // `!_deleted` ŞART: editörün KENDİ silmesi de (softDelete + pop)
      // gecikme telafisiyle buraya bir snapshot düşürür; bayrak olmadan
      // dal ikinci kez tetiklenir ve context.pop() yığının tepesindeki
      // ALTTAKİ rotayı (örn. Arşiv ekranını) düşürürdü.
      if (incoming.deletedAt != null && _note!.deletedAt == null && !_deleted) {
        _deleted = true;
        _debouncer.cancel();
        _liteHeldN.value = false;
        if (mounted) _closeEditor();
        return;
      }
      if (_deleted) return;
      // Editör açıkken YAZILAN alanlar (başlık/gövde/maddeler) yerel esastır;
      // gerisi uzaktan benimsenir:
      //  - ekler: yükleme/AI alanları düzen korunarak birleştirilir,
      //  - meta (sabit/yıldız/kilit/arşiv/klasör/etiket/renk/hatırlatıcı):
      //    karttan ya da ikinci cihazdan yapılan değişiklik, editörün
      //    tam-doküman kaydıyla sessizce GERİ ALINMASIN. Yereldeki meta
      //    değişikliği kaybolmaz: Firestore gecikme telafisi yerel yazımı
      //    akışa anında yansıtır, bayat snapshot gelmez.
      final localTitle = _titleController.logicalText;
      final localBody = _bodyController.logicalText;
      // Kullanıcı bu oturumda HİÇ yazmadıysa içerik de benimsenir: notu
      // yalnızca açıp bakan tarafta ikinci cihazın düzenlemesi canlı akar
      // ve bayat taban tam-doküman kaydıyla onu ezemez.
      final pristine =
          !_undoStack.canUndo &&
          !_debouncer.hasPending &&
          localTitle == _note!.title &&
          localBody == _note!.body;
      // KÖK NEDEN (kasma): burada KOŞULSUZ `setState` vardı. Firestore
      // gecikme telafisi yüzünden editörün KENDİ kaydı da anında bir
      // anlık görüntü olarak geri düşer; yani yazarken (debounce 0,5 sn,
      // en geç 3 sn) düzenli aralıklarla 4000 satırlık editör build'i —
      // sayfa tuvali, sarma ölçümü, bütün madde satırları — boşuna
      // yeniden koşuyordu. Oysa o yankıda çizimi değiştiren HİÇBİR ŞEY
      // yok: alanlar zaten yerelden geldiği gibi. Artık yeni not nesnesi
      // kurulur, çizimi etkileyen bir fark yoksa `setState` ATLANIR
      // (denetleyiciler ve `_note` yine güncel kalır).
      final previous = _note!;
      // AĞIR BELGE İLK KEZ GELDİ (F3.13): ekler olduğu gibi benimsenir —
      // yereldeki hafif kopyanın düzen alanları (PDF işaretleri dahil)
      // boş; birleştirme onları ağır veriye tercih ederdi. Kaydedilmemiş yerel
      // ek değişikliği varsa liste yerel kalır (F5.6, `hydrateAttachments`).
      final hydrating = incoming.heavyLoaded && !previous.heavyLoaded;
      Note merged;
      {
        merged = previous.copyWith(
          heavyRef: incoming.heavyRef,
          heavyLoaded: previous.heavyLoaded || incoming.heavyLoaded,
          // Bizim çizgilerimiz henüz yazılmadıysa onlar kalır; yoksa gelen
          // (başka cihaz ya da ağır belgenin geç gelen çizimi).
          pageInk: _debouncer.hasPending || incoming.heavyMissing
              ? null
              : incoming.pageInk,
          attachments: hydrating
              ? hydrateAttachments(
                  local: previous.attachments,
                  incoming: incoming.attachments,
                  localPending: _debouncer.hasPending,
                )
              : mergeAttachmentLayout(
                  local: _note!.attachments,
                  incoming: incoming.attachments,
                ),
          aiSummary: incoming.aiSummary,
          pinned: incoming.pinned,
          starred: incoming.starred,
          urgent: incoming.urgent,
          locked: incoming.locked,
          tags: incoming.tags,
          color: incoming.color,
          frameColor: incoming.frameColor,
          customColor: incoming.customColor,
          clearCustomColor: incoming.customColor == null,
          customFrameColor: incoming.customFrameColor,
          clearCustomFrameColor: incoming.customFrameColor == null,
          folderId: incoming.folderId,
          clearFolderId: incoming.folderId == null,
          archivedAt: incoming.archivedAt,
          clearArchivedAt: incoming.archivedAt == null,
          expiresAt: incoming.expiresAt,
          clearExpiresAt: incoming.expiresAt == null,
          reminderAt: incoming.reminderAt,
          clearReminderAt: incoming.reminderAt == null,
          // Sıra ve görünüm ayarları da uzaktan benimsenir: geniş ekranda
          // solda sürükle-sırala yapıldığında editörün tam-doküman kaydı
          // orderIndex'i geri almasın.
          orderIndex: incoming.orderIndex,
          fontFamily: incoming.fontFamily,
          clearFontFamily: incoming.fontFamily == null,
          fontScale: incoming.fontScale,
          textOpacity: incoming.textOpacity,
          titleFontFamily: incoming.titleFontFamily,
          clearTitleFontFamily: incoming.titleFontFamily == null,
          titleFontScale: incoming.titleFontScale,
          titleTextOpacity: incoming.titleTextOpacity,
          backgroundImageId: incoming.backgroundImageId,
          clearBackgroundImage: incoming.backgroundImageId == null,
          backgroundOpacity: incoming.backgroundOpacity,
          paged: incoming.paged,
          archivePaper: incoming.archivePaper,
          lineSpacing: incoming.lineSpacing,
          extras: incoming.extras,
        );
        if (pristine) {
          merged = merged.copyWith(
            title: incoming.title,
            body: incoming.body,
            items: incoming.items,
            // Sayfa notları da içerik: bu oturumda hiç yazılmadıysa ikinci
            // cihazın yazdığı sayfa notu canlı görünür. Yazılmışsa YEREL
            // esastır (pristine false) — yankı gelen bayat harita, henüz
            // kaydedilmemiş tuş vuruşlarını geri almasın.
            pageNotes: incoming.pageNotes,
          );
          if (incoming.title != localTitle) {
            _titleController.text = incoming.title;
          }
          if (incoming.body != localBody) {
            _bodyController.text = incoming.body;
          }
          _setBase(incoming);
        } else {
          merged = _mergeConcurrent(merged, incoming, localTitle, localBody);
        }
      }
      _note = merged;
      if (!sameRenderedNote(previous, merged)) _setStateAfterOpening();
    }
  }

  void _handleMetricsChanged() {
    // Panel kapalıyken hiçbir iş yok (klavye karelerinde ucuz kalsın).
    if (!_formatBarOpen) {
      _imeHide.reset();
      return;
    }
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final inset = view.viewInsets.bottom / view.devicePixelRatio;
    if (!_imeHide.onInset(inset)) return;
    // Odak yazı alanında KALDI → geri tuşu (ya da klavyenin kendi gizle
    // düğmesi). Önce panel kapanır, klavye geri gelir; ikinci geri klavyeyi
    // kapatır. Alan dışına dokunulduysa odak çoktan gitmiştir: dokunma.
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus == null ||
        focus.findAncestorStateOfType<EditableTextState>() == null) {
      return;
    }
    _formatBarOpen = false;
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
  }

  void _handleLifecycleChanged(AppLifecycleState state) {
    // `resumed` dışındaki her evre bir "çıkış" olabilir: Android'de görev
    // listesi açılınca `inactive`, arka plana geçince `hidden`/`paused`,
    // öldürülmeden hemen önce `detached` gelir. Kayıt hepsinde zorlanır —
    // fazladan yazımın maliyeti yok (Firestore merge, aynı içerik).
    if (state != AppLifecycleState.resumed) _saveNow();
    // Arka plana geçiş gerçek bir çıkış olabilir (öldürülürse dispose yok):
    // istemci saatli son kayıt sunucu zamanıyla mühürlenir. `inactive`
    // (bildirim perdesi vb.) sık gelir — orada damgalanmaz.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stampServerTimeOnExit();
    }
  }

  void _syncSecureScreen(bool locked) {
    if (locked == _secureHeld) return;
    _secureHeld = locked;
    if (locked) {
      AppLockSecureScope.acquireNote();
    } else {
      AppLockSecureScope.releaseNote();
    }
  }

  void _disposeEditorState() {
    _syncSecureScreen(false);
    if (NoteTableFocus.cellFocused == _tableCellFocused) {
      NoteTableFocus.cellFocused = null;
      NoteTableFocus.cellDisposed = null;
    }
    _stopFileDrops();
    _typingTimer?.cancel();
    _hideTimer?.cancel();
    _recentKey?.cancel();
    _typingN.dispose();
    _floatsN.dispose();
    FocusManager.instance.removeListener(_onAnyFocusChange);
    HardwareKeyboard.instance.removeHandler(_onHardKey);
    InkToolMemory.autoStylusListenable.removeListener(_onStylusToggle);
    Personalize.listenable.removeListener(_onTopOrder);
    _fieldFocusedN.dispose();
    WidgetsBinding.instance.removeObserver(this);
    noteRouteClosing.removeListener(_holdSaveWhileClosing);
    openEditorNoteIds.remove(widget.noteId);
    _NoteEditorScreenState._live.remove(this);
    Personalize.leaveNote(this);
    final openNotes = _openNotes;
    final openId = widget.noteId;
    unawaited(Future.microtask(() => openNotes.close(openId)));
    final sortHold = _sortHold;
    unawaited(Future.microtask(() => sortHold?.release(openId)));
    final previewHold = _previewHold;
    unawaited(Future.microtask(() => previewHold?.release(openId)));
    _pageInkCtl?.dispose();
    // Tam ekran nota bağlı; ağaç kilitliyken durum yazılamaz. Başka bir nota
    // GEÇİLDİYSE (yeni editör çoktan açık) tam ekran sürer.
    final fullscreen = _fullscreenNotifier;
    if (fullscreen != null) {
      unawaited(
        Future.microtask(() {
          if (openEditorNoteIds.isEmpty) fullscreen.set(false);
        }),
      );
    }
    // Dikte açıkken editörden çıkılabiliyor: mikrofon ekranla birlikte
    // kapanmazsa arka planda dinlemeye devam ederdi.
    _dictationCtl?.cancelImmediate();
    // Kayıt sürerken ekran beklenmedik biçimde kapandıysa (geri tuşu kaydı
    // önce bitirir — bkz. PopScope) mikrofon açık kalmasın.
    final recorder = _voiceRecorder;
    if (recorder != null) {
      _voiceRecorder = null;
      unawaited(recorder.cancel().whenComplete(recorder.dispose));
    }
    // Yalnız `_debouncer.flush()` DEĞİL: denetleyici metni nottan sapmış ama
    // bekleyen debounce yoksa (IME'nin odak düşerken onChanged üretmeden
    // commit ettiği otomatik düzeltme, alan içi Ctrl+Z) flush hiçbir şey
    // yazmazdı — _saveNow aynı drift ağını çıkış yolunda da kurar.
    _saveNow();
    _stampServerTimeOnExit();
    // Tarih ayrıştırma (2000 karakter, düzenli ifadeler) rota kalkış karesine
    // binmesin: panonun yetişmesinden (+120 ms) de sonra.
    final readOnly = widget.readOnly;
    Timer(const Duration(milliseconds: 700), () => _suggestCalendar(readOnly));
    // Silinen eklerin baytları burada gider: "Geri al" ile geri gelenler
    // dosyalarını korur (bkz. _flushAttachmentDeletes).
    _flushAttachmentDeletes();
    final note = _note;
    if (!_deleted &&
        note != null &&
        !note.locked &&
        !note.extras.containsKey('e2ee') &&
        note.isEmpty) {
      // İçi boş kalan not çıkarken sessizce silinir.
      _notesRepo?.hardDelete(note.id);
    } else if (!_deleted && note != null) {
      // YENİ NOT hangi yoldan doğmuş olursa olsun (bkz.
      // [NotesRepository.lastCreatedId]): ana ekrana dönünce kartı görünür
      // alana gelip kısa süre yanıp söner. Boş atılan notta (üst dal) yok.
      _focusNote.focusCreated(note.id);
    }
    // Kapanıştaki son kayıttan SONRA: depodaki oturum kayıtları (F6.2).
    _notesRepo?.releaseNote(widget.noteId);
    _loadGuard?.cancel();
    _debouncer.dispose();
    _journalDebouncer.dispose();
    _liteHeldN.dispose();
    // Geç geri çağrılar yazmaya devam edebilir: LateSafeValue sessiz saklar.
    _noteN.dispose();
    _undoN.dispose();
    _sub?.close();
    _titleController.dispose();
    _formatTargetN.dispose();
    _formatOpenN.dispose();
    _dictationCtl?.dispose();
    _findOpenN.dispose();
    _titleFocus.dispose();
    _bodyWindow.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    _pageScroll.dispose();
    _find.dispose();
    _attachPulse.dispose();
    _videoHub.dispose();
    _busyTaskN.dispose();
    _bodyTopN.dispose();
    _titleGeneratingN.dispose();
  }

  Note _prepareMutateNext(
    Note note,
    Note Function(Note) transform, {
    required bool immediate,
    required bool inkOnly,
  }) {
    if (!immediate && !inkOnly) _noteTyping();
    // F68.1: yazım/çizim sürerken listedeki kart beklesin; anında kayıt
    // (yıldız, sabitle, renk) kartta hemen görünsün.
    if (immediate) {
      _previewHold?.release(widget.noteId);
    } else {
      _previewHold?.touch(widget.noteId);
    }
    // Tek boğaz noktası: sarma çapaları düzenleme tamponunda yaşar, nota
    // asla yazılmaz. Gövde hangi yoldan gelirse gelsin burada temizlenir —
    // her çağrı yerine ayrı koruma koymak yerine tek yerde.
    // Belgeyi SİLEN değişiklik belge kipini de kaldırır (boş "PDF ekle"
    // notunda belge henüz gelmedi — o yüzden yalnız kaybolunca).
    final raw = transform(note);
    final transformed = note.hasModeDocument
        ? _NoteEditorScreenState._withoutOrphanDocumentMode(raw)
        : raw;
    final clean = stripWrapAnchors(transformed.body);
    final next = clean == transformed.body
        ? transformed
        : transformed.copyWith(body: clean);
    if (!_restoring) {
      _undoStack.push(note, next, now: DateTime.now());
      _syncUndoN();
      // YENİ EK (kullanıcının eklediği; akıştan gelen değil — o _mutate'ten
      // geçmez): sayfada yüzüyorsa yerleşim ipucu açılır.
      if (next.attachments.length > note.attachments.length) {
        final known = {for (final a in note.attachments) a.id};
        final added = next.attachments
            .where(
              (a) =>
                  !known.contains(a.id) &&
                  a.floatsOnPage &&
                  a.sourceId.isEmpty &&
                  a.id != next.backgroundImageId,
            )
            .lastOrNull;
        if (added != null) _placementHintId = added.id;
      }
    }
    return next;
  }

  void _applyPureTypingMutate(
    Note note,
    Note next, {
    required bool inkOnly,
    required bool tableOnly,
  }) {
    if (inkOnly) {
      for (final a in note.attachments) {
        _staleInk.putIfAbsent(a.id, () => a.ink);
      }
    }
    if (tableOnly) {
      for (final a in note.attachments) {
        if (isNoteTable(a)) _staleTable.putIfAbsent(a.id, () => a);
      }
    }
    _note = next;
  }

  void _finishMutateSave({required bool immediate}) {
    // Arama açıkken metin değiştiyse eşleşme konumları kaydı: vurgular bir
    // sonraki karede yeniden hesaplanır.
    if (_findOpen) _queueFindRefresh();
    // KÖK NEDEN (bekleyen son kayıt yutuluyordu): bu kapanış `ref.read` ile
    // depoyu okuyordu, oysa `dispose()` içindeki `_debouncer.flush()` de aynı
    // kapanışı çalıştırır — ve `dispose` sırasında `ref` kullanmak istisna
    // atar (bkz. sınıfın başındaki not). Yani editörden çıkarken bekleyen
    // yazım kaydedilmediği gibi, atılan istisna dispose'un GERİ KALANINI da
    // (ek silme flush'ı, boş not temizliği, otomatik başlık) iptal ediyordu.
    // Depo artık her build'de tazelenen alandan okunur.
    // "En çok çalışılan" sıralamasının ölçüsü (bkz. noteActivityProvider):
    // oturumda İLK gerçek değişiklikte bir puan. Her tuş vuruşunda saymak
    // sayacı yazma hızına bağlardı — uzun bir nota bir cümle eklemek, kısa
    // bir notu baştan yazmaktan daha çok "çalışma" sayılmamalı.
    if (!_workCounted) {
      _workCounted = true;
      ref.read(noteActivityProvider.notifier).touch(widget.noteId);
    }

    void save() {
      _liteHeldN.value = false;
      final current = _note;
      if (current != null && !_deleted) {
        _clientStamped = true;
        _notesRepo?.updateNote(current, clientTime: true);
      }
    }

    if (immediate) {
      _debouncer.cancel();
      save();
    } else {
      // LITE (PLAN §1.5): `instantSync` yoksa bulut yazımı SaveCadence
      // .liteInterval aralıkla; bu arada içerik diskteki günlüğe düşer.
      // Kişisel APK / web / Pro / paylaşılan not: bu dal hiç çalışmaz.
      final lite = _liteHolds();
      if (lite) {
        _debouncer.delay = _debouncer.maxWait = SaveCadence.liteInterval;
        _liteArmed = true;
        _liteHeldN.value = true;
        _journalDebouncer(_journalPending);
      } else if (_liteArmed) {
        // Paylaşıma geçildi / Pro açıldı: eski sıklığa dön, bekleyen yazı
        // hemen (bu çağrının debounce'u) gider.
        _liteArmed = false;
        _debouncer.delay = SaveCadence.delay;
        _debouncer.maxWait = SaveCadence.maxWait;
        _journalDebouncer.cancel();
      }
      _debouncer(save);
    }
  }
}
