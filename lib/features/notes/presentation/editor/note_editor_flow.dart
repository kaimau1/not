part of 'note_editor_screen.dart';

/// Editörün akış yardımcıları (F18.23'te ana dosyadan taşındı): bekleyen açılış niyetleri, eşzamanlı birleştirme, kayıt, imleç görünürlüğü, biçim hedefi, liste/hesap makinesi, sayfa kalemi.
extension _EditorFlowX on _NoteEditorScreenState {
  void _runPendingIntents() {
    if (!mounted || _note == null) return;
    if (_pendingDraw) {
      _pendingDraw = false;
      _openPen();
    }
    if (_pendingSeparateDrawing) {
      _pendingSeparateDrawing = false;
      unawaited(_addDrawing());
    }
    if (_pendingVoice) {
      _pendingVoice = false;
      // Sesli not, uygulamanın her yerinde AYNI levhayla (bkz. _captureVoice).
      unawaited(_captureVoice());
    }
    if (_pendingDictation) {
      _pendingDictation = false;
      // Gövde odaklanır ki imleç görünür bir yerde olsun; dikte de oraya
      // yazsın (odaksız alanda hedef bulunamazdı).
      _bodyFocus.requestFocus();
      unawaited(_toggleDictation());
    }
    if (_pendingVideo) {
      _pendingVideo = false;
      _addVideo();
    }
    if (_pendingPhoto) {
      _pendingPhoto = false;
      _takePhoto();
    }
    if (_pendingScan) {
      _pendingScan = false;
      _scanDocument();
    }
    if (_pendingPdf) {
      _pendingPdf = false;
      _pickPdf();
    }
    if (_pendingSlides) {
      _pendingSlides = false;
      _pickSlide();
    }
    // Videodan doğan not "üstte video, altta not" düzeniyle açılır: video
    // sabit bölmede oynarken not altında yazılır (kullanıcının kendi
    // kurduğu düzen; elle sürükleyip sabitlemek gerekmesin).
    if (_pendingGalleryVideo) {
      _pendingGalleryVideo = false;
      unawaited(() async {
        final added = await _addVideoFromGallery();
        if (added != null && mounted) _pinMediaTop(added);
      }());
    }
    if (_pendingYouTube) {
      _pendingYouTube = false;
      unawaited(() async {
        final added = await _addYouTube();
        if (added != null && mounted) _pinMediaTop(added);
      }());
    }
    if (_pendingTranscribe) {
      _pendingTranscribe = false;
      unawaited(_transcribeFile());
    }
    if (_pendingAudioFile) {
      _pendingAudioFile = false;
      unawaited(_pickAudioFile());
    }
  }

  void _cacheDeps() {
    // Paylaşılan not SAHİBİNİN koleksiyonuna yazılır (bkz.
    // [NoteEditorScreen.ownerId]); kendi notlarımda eski yol aynen sürer.
    final owner = widget.ownerId;
    _notesRepo = _readOnly
        ? null
        : owner == null
        ? ref.read(notesRepositoryProvider)
        : NotesRepository(
            FirebaseFirestore.instance,
            owner,
            editorUid: ref.read(currentUidProvider),
          );
    // Paylaşılan notun ekleri SAHİBİNİN Storage yoluna yüklenir (bkz.
    // AttachmentRepository.forOwner — ortak nottaki görsel kök nedeni).
    final attachments = ref.read(attachmentRepositoryProvider);
    _attachmentRepo = owner == null
        ? attachments
        : attachments?.forOwner(owner);
    _gemini = ref.read(geminiServiceProvider);
    _autoTagEnabled = ref.read(autoTagProvider);
    _autoTitleEnabled = ref.read(autoTitleProvider);
  }

  /// **EŞZAMANLI DÜZENLEME** (F4.1): kullanıcı yazarken başka biri (ya da
  /// ikinci cihaz) aynı notu değiştirdi. Eskiden uzaktaki içerik yok
  /// sayılıyor, editörün sonraki tam-doküman kaydı onu SİLİYORDU. Artık
  /// tabana göre üç yönlü birleştirilir ve sonuç kaydedilir; aynı paragraf
  /// iki tarafta farklı değiştiyse ikisi de tutulur ve kullanıcıya söylenir.
  /// Kendi yazımımızın yankısı birleştirilmez, yalnız tabanı ilerletir.
  Note _mergeConcurrent(
    Note merged,
    Note incoming,
    String localTitle,
    String localBody,
  ) {
    final remoteChanged =
        incoming.title != _baseTitle ||
        incoming.body != _baseBody ||
        !sameItems(incoming.items, _baseItems);
    if (!remoteChanged) return merged;
    final repo = _notesRepo;
    if (repo == null || repo.isOwnEcho(incoming)) {
      _setBase(incoming);
      return merged;
    }
    final body = mergeText3(_baseBody, localBody, incoming.body);
    final title = localTitle != _baseTitle ? localTitle : incoming.title;
    final items = mergeItems3(_baseItems, _note!.items, incoming.items);
    _setBase(incoming);
    if (title != localTitle) _titleController.text = title;
    if (body.text != localBody) {
      final caret = _bodyController.selection;
      _bodyController.text = body.text;
      if (caret.isValid) {
        final at = caret.baseOffset.clamp(0, body.text.length);
        _bodyController.selection = TextSelection.collapsed(offset: at);
      }
    }
    final result = merged.copyWith(title: title, body: body.text, items: items);
    // Birleşik hâl hemen yazılır: öbür taraf da görsün, taban ilerlesin.
    _debouncer.cancel();
    _notesRepo?.updateNote(result);
    if (body.conflict) _showSnack(context.l10n.mergeConflictKept);
    return result;
  }

  /// Bekleyen kaydı ERTELEMEDEN yazar; metin alanlarındaki en güncel içerik
  /// nota işlenir.
  ///
  /// KÖK NEDEN ("not düzenlerken dashboard'a dönmeden uygulamayı tamamen
  /// kapatınca not bazen kaydolmuyor, kayboluyor"): kayıt yalnız iki yerde
  /// kesinleşiyordu — debounce zamanlayıcısı dolduğunda ve `dispose()`
  /// içindeki flush'ta. Uygulama görev listesinden kapatıldığında (ya da
  /// sistem onu öldürdüğünde) rota pop EDİLMEZ, dolayısıyla `dispose()` hiç
  /// çalışmaz ve o an bekleyen yazım onunla birlikte kaybolur. Yeni açılmış
  /// bir notta bu, notun Firestore'da BOŞ kalması demektir; boş notlar arka
  /// planda temizlendiği için not tümüyle yok olur — "kayboluyor" şikâyeti
  /// tam olarak budur. Bu yüzden kayıt artık her çıkış kapısında zorlanır:
  /// arka plana alma (`inactive`/`paused`/`hidden`/`detached`) ve masaüstünde
  /// pencere kapatma isteği (`didRequestAppExit`).
  Future<void>? _saveNow() {
    final note = _note;
    if (note == null || _deleted) return null;
    // Denetleyicilerdeki metin nota işlenir: son tuş vuruşunun `onChanged`'i
    // gelmemiş olabilir. Gövde/başlık için tek gerçek kaynak denetleyicidir —
    // nota dışarıdan yazan her yol (dikte, AI, yapıştırma) denetleyiciyi de
    // günceller, o yüzden burada geri alma riski yok.
    // Bekleyen biçim koşusu de burada kesinleşir: işaretler tampona ancak koşu
    // bitince giriyor, uygulama arka plana alınıp öldürülürse koşu hiç
    // bitmeyecekti ve kullanıcının "kalın" yazdığı satır düz kaydedilirdi.
    _titleController.flushPendingFormat();
    _bodyController.flushPendingFormat();
    // Odaktaki alan madde satırı ya da sayfa notu olabilir; biçim çubuğunun
    // hedefi tam olarak o alandır. Yoksa "kalın"a basıp bir madde satırına
    // yazan ve uygulamayı görev listesinden kapatan kullanıcı biçmi
    // kaybediyordu (gövde/başlık için kapatılan deliğin aynısı).
    final target = _formatTarget;
    if (target != null && target.controller.hasPendingFormat) {
      target.controller.flushPendingFormat();
      target.commit();
    }
    final title = _titleController.logicalText;
    final body = _bodyController.logicalText;
    final drifted = title != note.title || body != note.body;
    // Yazılacak yeni bir şey yoksa hiç dokunma: `inactive` evresi (bildirim
    // perdesi, kamera/galeri açılışı, izin diyaloğu) sık gelir ve her
    // seferinde boş yere `updatedAt` tazelemek notu listede öne fırlatırdı.
    if (!drifted && !_debouncer.hasPending) return null;
    final current = drifted ? note.copyWith(title: title, body: body) : note;
    _note = current;
    // setState YOK: denetleyiciler bu metni zaten gösteriyor, yeniden çizime
    // gerek yok — üstelik `detached` evresinde setState çağırmak güvensiz.
    _debouncer.cancel();
    // Sunucu zamanıyla yazılıyor: istemci saatli damga burada düzelir.
    _clientStamped = false;
    return _notesRepo?.updateNote(current);
  }

  /// Odaklı alanın İMLECİNİ klavyenin üstüne kaydırır.
  ///
  /// KÖK NEDEN — 1: **ALANIN TAMAMI DEĞİL, İMLEÇ** (kullanıcı bulgusu
  /// 2026-08-30: "uzun notlarda bir yere yazmak istediğimde klavye açılıp
  /// oraya odaklama hem geç kalıyor hem de güzel değil"). Burada eskiden
  /// `Scrollable.ensureVisible` ile ALANIN kendisi görünür kılınıyordu. Gövde
  /// TEK bir dev `TextField`tir: uzun bir notta o kutu ekrandan metrelerce
  /// uzundur ve `keepVisibleAtEnd` onun ALT KENARINI hizalar — kullanıcı
  /// notun ortasına dokunuyor, ekran notun SONUNA atlıyordu.
  ///
  /// KÖK NEDEN — 2: **GEÇ KALIYOR**. Kaydırma yalnız [KeyboardSnap] boşluğu
  /// oturttuğunda (klavye animasyonu + 140 ms) yapılıyordu. Artık odak
  /// alındığı ANDA, klavyenin bilinen yüksekliği ([_keyboardMemory])
  /// düşülerek kaydırılıyor; oturma anındaki ikinci geçiş yalnız tahmin
  /// tutmadıysa iş yapar.
  ///
  /// [hidden] sayfanın yerleşiminde HENÜZ olmayan, ama ekranı örtecek olan
  /// yükseklik (açılmakta olan klavye).
  void _revealCaret({double hidden = 0}) {
    if (!_pageScroll.hasClients) return;
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null || !focused.mounted) return;
    final editable = _NoteEditorScreenState._findEditable(
      focused.findRenderObject(),
    );
    final position = _pageScroll.position;
    final viewport = position.context.notificationContext?.findRenderObject();
    if (editable == null ||
        !editable.attached ||
        !editable.hasSize ||
        viewport is! RenderBox ||
        !viewport.hasSize ||
        !_NoteEditorScreenState._isDescendantOf(editable, viewport)) {
      // Ölçemedik (odak başka bir katmanda, alan henüz yerleşmemiş): eski
      // davranışa düş — hiç kaydırmamaktan iyidir.
      if (focused.mounted) {
        Scrollable.ensureVisible(
          focused,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
      return;
    }
    final offset = editable.selection?.extentOffset ?? -1;
    final caret = offset < 0
        ? (Offset.zero & Size(1, editable.preferredLineHeight))
        : editable.getLocalRectForCaret(TextPosition(offset: offset));
    final top = editable.localToGlobal(caret.topLeft, ancestor: viewport).dy;
    final bottom = top + math.max(caret.height, editable.preferredLineHeight);
    // İmleç kenara yapışmasın: bir-iki satırlık nefes payı.
    const margin = 28.0;
    final visibleBottom = viewport.size.height - hidden;
    var delta = 0.0;
    if (bottom + margin > visibleBottom) {
      delta = bottom + margin - visibleBottom;
    } else if (top - margin < 0) {
      delta = top - margin;
    }
    if (delta.abs() < 1) return;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < 1) return;
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  /// Bir alan ODAK ALDIĞI anda imleci görünür kılar — klavyenin açılmasını
  /// beklemeden (bkz. [_revealCaret] kök neden 2). Kaydırma bir kare
  /// ertelenir: odak olayı yerleşimden önce gelebiliyor.
  void _revealCaretSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Klavye yerleşime girmişse (oturmuş) ekranı örten fazladan bir şey
      // yok; girmemişse açılacak klavyenin yüksekliği düşülür.
      _revealCaret(hidden: _keyboardInset > 0 ? 0 : _keyboardMemory);
    });
  }

  /// Dahili hesap makinesi: sonucu metin notunda imlecin bulunduğu yere,
  /// listelerde yeni öğe olarak ekler.
  Future<void> _openCalculator() async {
    // Gövde odağını bırak: alt sayfa kapanınca klavye kendiliğinden geri
    // açılmasın (odaklı alan kalırsa Flutter klavyeyi yeniden gösterir).
    _dismissKeyboard();
    final result = await showCalculatorSheet(context);
    // Sonuç metne/öğeye programatik eklenir; kullanıcı yazmıyordu, klavye
    // kapalı kalsın (sonuç eklendikten sonra alan odaklanmaz).
    _dismissKeyboard();
    if (result == null || result.isEmpty) return;
    final note = _note;
    if (note == null) return;
    if (note.type == NoteType.text) {
      final body = _bodyController.text;
      final selection = _bodyController.selection;
      final start = selection.isValid ? selection.start : body.length;
      final end = selection.isValid ? selection.end : body.length;
      final updated = body.replaceRange(start, end, result);
      _bodyController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + result.length),
      );
      _mutate((n) => n.copyWith(body: updated), immediate: true);
    } else {
      // _appendText liste öğelerinde satır başındaki rakamları madde
      // numarası sanıp kırpar; sonuç sayı içerdiğinden öğe doğrudan eklenir.
      const uuid = Uuid();
      _mutate(
        (n) => n.copyWith(
          items: [
            ...n.items,
            NoteItem(id: uuid.v4(), text: result),
          ],
        ),
        immediate: true,
      );
    }
  }

  /// **☑ ONAY KUTUSU — KOLAY EKLE / KALDIR** (kullanıcı isteği 2026-10-28,
  /// örnek uygulamadaki alt çubuk): imleç GÖVDEDEYSE bulunduğu satır kutulu
  /// madde olur (listenin başına — gövde maddelerin hemen üstünde durduğu
  /// için son satır yerinden kımıldamaz); imleç bir MADDEDEYSE kutusu kalkar
  /// ve metni gövdenin sonuna döner (ilk maddede bu tam tersi işlemdir).
  /// Hiçbir yer odakta değilse boş bir kutulu madde açılır.
  void _toggleChecklistLine() {
    final note = _note;
    if (note == null || note.type != NoteType.text) return;
    unawaited(HapticFeedback.selectionClick());
    final items = _itemsEditorKey.currentState;
    final focused = items?.focusedItemId;
    if (items != null && focused != null) {
      final text = items.takeItem(focused);
      if (text == null) return;
      final body = _bodyController.logicalText;
      final next = body.trim().isEmpty
          ? text
          : (body.endsWith('\n') ? '$body$text' : '$body\n$text');
      _bodyController.setLogical(next, next.length);
      _mutate((n) => n.copyWith(body: next), immediate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bodyFocus.requestFocus();
        _bodyController.selection = TextSelection.collapsed(
          offset: _bodyController.text.length,
        );
      });
      return;
    }
    final body = _bodyController.logicalText;
    var line = '';
    var rest = body;
    if (_bodyFocus.hasFocus && body.isNotEmpty) {
      final selection = _bodyController.selection;
      final caret = selection.isValid
          ? wrapToLogicalOffset(
              _bodyController.text,
              selection.baseOffset,
            ).clamp(0, body.length)
          : body.length;
      final start = caret == 0 ? 0 : body.lastIndexOf('\n', caret - 1) + 1;
      var end = body.indexOf('\n', caret);
      if (end < 0) end = body.length;
      line = body.substring(start, end);
      rest = end < body.length
          ? body.substring(0, start) + body.substring(end + 1)
          : (start > 0 ? body.substring(0, start - 1) : '');
    }
    const uuid = Uuid();
    final item = NoteItem(id: uuid.v4(), text: line.trim());
    if (rest != body) _bodyController.setLogical(rest, rest.length);
    _mutate(
      (n) => n.copyWith(body: rest, items: [item, ...n.items]),
      immediate: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _itemsEditorKey.currentState?.focusItem(item.id);
    });
  }

  /// Metin notuna boş bir checklist maddesi ekler (karışık içerik). İlk madde
  /// eklenince gövde otomatik ItemsEditor'a geçer; sonrakiler onun "Yeni öğe"
  /// düğmesinden eklenir. Tüm maddeler silinince gövde saf metne döner.
  void _addChecklistItem() {
    const uuid = Uuid();
    _mutate(
      (n) => n.copyWith(
        items: [
          ...n.items,
          NoteItem(id: uuid.v4(), text: ''),
        ],
      ),
      immediate: true,
    );
  }

  /// Ek sınırı mesajı. İki ayrı sınır var ve ikisi de aynı istisna ağacından
  /// geliyor: TEK dosya boyutu (premium 50 MB / ücretsiz 10 MB) ve TOPLAM
  /// depolama tavanı ([StorageFullException]). [error] verilmezse dosya
  /// boyutu mesajı döner.
  String _tooLargeMessage([FileTooLargeException? error]) {
    if (error is StorageFullException) {
      return context.l10n.storageFull(formatBytes(error.quotaBytes));
    }
    final premium = ref.read(premiumProvider).value ?? false;
    final limitMb =
        (premium
            ? AppConstants.maxPremiumAttachmentBytes
            : AppConstants.maxFreeAttachmentBytes) ~/
        (1024 * 1024);
    return context.l10n.attachmentTooLarge(limitMb);
  }

  /// Odaktaki metin alanındaki imlecin SAYFA (tuval) uzayındaki üst kenarı.
  double? _caretPageTop() {
    final page = _pageBox();
    final focused = FocusManager.instance.primaryFocus?.context;
    if (page == null || focused == null) return null;
    final editable = _NoteEditorScreenState._findEditable(
      focused.findRenderObject(),
    );
    if (editable == null || !editable.attached || !editable.hasSize) {
      return null;
    }
    // Odak başka bir katmanda olabilir (alt sayfa, tam ekran görüntüleyici);
    // o zaman ölçüm sayfa uzayına çevrilemez.
    if (!_NoteEditorScreenState._isDescendantOf(editable, page)) return null;
    final offset = editable.selection?.baseOffset ?? -1;
    final caret = offset < 0
        ? Rect.zero
        : editable.getLocalRectForCaret(TextPosition(offset: offset));
    return editable.localToGlobal(Offset(0, caret.top), ancestor: page).dy;
  }

  /// Boyut/şeffaflık kaydırıcısı bırakıldı: SEÇİM VARSA yalnız ona (satır içi
  /// kademe olarak), yoksa TÜM NOTA uygulanır. Kullanıcı isteği birebir buydu.
  ///
  /// Kaydırıcı sürekli, kademeler ayrık: en yakın kademeye yuvarlanır.
  /// Kademe notun kendi değeriyle aynıysa işaret hiç yazılmaz (metin yine
  /// notu izler) — gereksiz işaret metni kirletmesin.
  void _applyStepOrNote(
    RichFormat format,
    List<double> steps,
    int defaultIndex,
    double value,
    Note Function(Note note) noteWide,
  ) {
    final target = _formatTarget;
    if (target != null && _hasSelection()) {
      final index = richStepIndex(steps, value);
      if (applyRichStep(
        target.controller,
        format,
        index == defaultIndex ? null : index,
      )) {
        target.commit();
        if (!target.focusNode.hasFocus) target.focusNode.requestFocus();
      }
      return;
    }
    _mutate(noteWide, immediate: true);
  }

  void _runOnTarget(bool Function(WrapTextController controller) action) {
    final target = _formatTarget;
    if (target == null) return;
    if (!action(target.controller)) return;
    target.commit();
    // Odak (ve klavye) alana geri verilir: biçim uygulanan metin seçili
    // kaldığı için kullanıcı üstüne ikinci bir biçim koyabilir ya da yazmaya
    // devam edebilir. Çubuğun kendisi odak istemez (bkz. FormatBar).
    if (!target.focusNode.hasFocus) target.focusNode.requestFocus();
  }

  /// Silinen madde satırının denetleyicisi hedefteyse hedef bırakılır —
  /// biçim çubuğu dispose edilmiş denetleyiciye yazmasın.
  /// Alan odaktan çıkarken bekleyen biçmi metne yazar ve sonucu nota işler.
  ///
  /// Bekleyen biçim tampona koşu boyunca DOKUNMAZ (IME yarışının kök nedeni,
  /// bkz. `WrapTextController._wrapRun`); işaretler ancak burada girdiği için
  /// yazımın nota işlenmesi de burada zorlanır.
  void _flushPending(WrapTextController controller) {
    if (!controller.hasPendingFormat) return;
    controller.flushPendingFormat();
    if (!mounted) return;
    if (controller == _titleController) {
      _mutate(
        (n) => n.copyWith(title: _titleController.logicalText),
        immediate: true,
      );
    } else if (controller == _bodyController) {
      _mutate(
        (n) => n.copyWith(body: _bodyController.logicalText),
        immediate: true,
      );
    }
  }

  /// Çubuktaki biçim düğmesi: seçime uygula, seçim yoksa imlece kutu aç.
  void _applyFormat(RichFormat format, {int? colorIndex}) =>
      _runOnTarget((c) => applyRichFormat(c, format, colorIndex: colorIndex));

  /// Renk/vurgu paletindeki "Kaldır": yalnız o biçmi düşürür (bkz.
  /// [removeRichFormat] — geri dönüşün keşfedilebilir tek yolu).
  void _removeFormat(RichFormat format) =>
      _runOnTarget((c) => removeRichFormat(c, format));

  /// Notun türüne göre İLK KEZ mümkün olan gizli jest için tek satırlık
  /// ipucu (F14.6): liste → madde jestleri, belge (Balonlu) → basılı tut,
  /// sayfada görsel → yukarı sürükle. Oturumda en fazla bir ipucu.
  void _maybeShowTip() {
    final note = _note;
    if (!mounted || note == null || _readOnly) return;
    final l10n = context.l10n;
    final prefs = ref.read(sharedPreferencesProvider);
    final (String, String)? tip = switch (note.type) {
      NoteType.checklist || NoteType.ordered
          when note.items.isNotEmpty && ref.read(itemGesturesProvider) =>
        (TipOnce.listGestures, l10n.tipListGestures),
      _
          when note.attachments.any(
            (a) => a.kind == AttachmentKind.pdf && a.isPinnedTop,
          ) =>
        (TipOnce.pdfReadNote, l10n.tipPdfReadNote),
      _ when note.attachments.any((a) => a.floatsOnPage) => (
        TipOnce.mediaPin,
        l10n.tipMediaPin,
      ),
      _ => null,
    };
    if (tip == null) return;
    TipOnce.show(context, prefs, tip.$1, tip.$2);
  }

  /// Son kez nota yazılan çizgi listesi: nottan gelen başka değer (geri al,
  /// başka cihaz) denetleyiciye bununla anlaşılır.
  InkController _pageInkOf(Note note) {
    final existing = _pageInkCtl;
    if (existing != null) {
      if (!identical(existing.ink, note.pageInk) && !existing.drawing) {
        // Derleme sırasında bildirim yapılamaz; bir kare sonra.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final current = _note?.pageInk;
          if (mounted && current != null && !identical(existing.ink, current)) {
            existing.replaceAll(current);
          }
        });
      }
      _syncPageInkKinds(existing);
      return existing;
    }
    final created = InkController(
      initial: note.pageInk,
      onChanged: (strokes) => _mutate((n) => n.copyWith(pageInk: strokes)),
    )..setEditing(!_readOnly);
    _pageInkCtl = created;
    _syncPageInkKinds(created);
    return created;
  }

  /// Kalem kipi kapalıyken yalnız kalem yazar (ayar açıksa); parmak ve fare
  /// metne, kaydırmaya gider.
  void _syncPageInkKinds(InkController ink) {
    // Daire çizerek gömerken kalem örtüye çizer, sayfaya yazmaz.
    if (_gestureMode != _GestureMode.off) {
      ink.allowedKinds = const {};
      return;
    }
    ink.allowedKinds = {
      if (_penMode || InkToolMemory.autoStylus) ...const [
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      ],
      if (_penMode) ...const [PointerDeviceKind.touch, PointerDeviceKind.mouse],
    };
  }
}
