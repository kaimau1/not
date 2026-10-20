part of 'note_editor_screen.dart';

/// Not eylemleri: hatırlatıcı, etiket, klasör, paylaş, ⋮ menüsü, çoğalt, dönüştür, sırala, dışa aktar, kilit, arşiv, metin değiştir, geçmiş.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorActions on _NoteEditorScreenState {
  // ---- Diğer eylemler -------------------------------------------------

  Future<void> _pickReminder() async {
    final note = _note;
    if (note == null) return;
    final now = DateTime.now();
    final initial = note.reminderAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final reminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    // Bugünün geçmiş bir saati: bildirim hiç planlanmaz (reminder_service
    // yalnız geleceği kurar) — sessizce kurmuş gibi görünmek yerine uyar.
    if (!reminder.isAfter(DateTime.now())) {
      if (mounted) _showSnack(context.l10n.reminderInPast);
      return;
    }
    _mutate((n) => n.copyWith(reminderAt: reminder), immediate: true);
  }

  void _clearReminder() =>
      _mutate((n) => n.copyWith(clearReminderAt: true), immediate: true);

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final l10n = context.l10n;
    // Daha önce kullanılmış, bu notta OLMAYAN etiketler diyalogda çip olarak
    // sunulur — kullanıcı yeniden yazmak yerine dokunup ekler.
    final note = _note;
    final existing = [
      for (final t in ref.read(allTagsProvider))
        if (note == null || !note.tags.contains(t)) t,
    ];
    final tag = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addTag),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.tagHint),
              onSubmitted: (value) => Navigator.pop(dialogContext, value),
            ),
            if (existing.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.existingTagsLabel,
                style: Theme.of(dialogContext).textTheme.labelMedium?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // Çok etiket varsa diyalog taşmasın: sınırlı yükseklikte kaydırılır.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final t in existing)
                        ActionChip(
                          label: Text('#$t'),
                          onPressed: () {
                            // Çipe dokununca doğrudan eklenir (metin kutusuna
                            // yazmaya gerek yok), diyalog kapanır.
                            Navigator.pop(dialogContext);
                            _applyTag(t);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    controller.dispose();
    if (tag != null) _applyTag(_cleanTag(tag));
  }

  void _removeTag(String tag) => _mutate(
    (n) => n.copyWith(
      tags: [
        for (final t in n.tags)
          if (t != tag) t,
      ],
    ),
    immediate: true,
  );

  /// Notu bir klasöre taşır (ya da klasörden çıkarır).
  Future<void> _pickFolder() async {
    final note = _note;
    if (note == null) return;
    final picked = await showFolderPickSheet(
      context,
      ref,
      currentFolderId: note.folderId,
    );
    if (picked == null) return;
    _mutate(
      (n) => picked.isEmpty
          ? n.copyWith(clearFolderId: true)
          : n.copyWith(folderId: picked),
      immediate: true,
    );
  }

  /// Paylaş levhası: düz metin / not paketi (`.notpaket`) / balonlu PDF.
  ///
  /// Eskiden menüdeki "Paylaş" doğrudan düz metni gönderiyordu; PDF notunun
  /// düz metni çoğu zaman boş olduğu için düğme sessizce hiçbir şey yapmıyor,
  /// belgenin üzerindeki balonlar da hiçbir yoldan karşı tarafa gitmiyordu
  /// (kullanıcı bulgusu 2026-08-08). Bekleyen yazım önce kesinleşir: paylaşılan
  /// paket/PDF son hâli taşımalı.
  Future<void> _share() async {
    final note = _note;
    if (note == null) return;
    _flushPending(_titleController);
    _flushPending(_bodyController);
    if (!mounted) return;
    final current = _note ?? note;
    await showNoteShareSheet(
      context,
      ref,
      current,
      ownerId: widget.ownerId,
      // PDF/Word satırı editörün sayfa ölçüleriyle açılsın (görseller
      // nottaki yerlerinde çıksın — bkz. [_openNotesExport]).
      onExport: () => _openNotesExport(current),
    );
  }

  /// Notun metnini PAYLAŞIM biçimiyle panoya kopyalar (bkz. [noteShareText]):
  /// ⋮ menüsündeki "Kopyala". Seçip kopyalamaya gerek kalmadan tüm not.
  Future<void> _copyNoteText() async {
    final note = _note;
    if (note == null) return;
    _flushPending(_titleController);
    _flushPending(_bodyController);
    final text = noteShareText(
      _note ?? note,
      pageLabel: context.l10n.pageLabel,
    );
    if (text.trim().isEmpty) {
      _showSnack(context.l10n.shareAsTextEmpty);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showSnack(context.l10n.copied);
  }

  /// Üst bardaki ⋮ — iki sütunlu levha (bkz. note_menu_sheet.dart).
  Future<void> _openNoteMenu() async {
    final note = _note;
    if (note == null) return;
    // Levha metin alanı taşımıyor; klavye açık kalırsa levhanın yarısını
    // örter (alt bardaki diğer levhalarla aynı kural).
    _dismissKeyboard();
    final action = await showNoteEditorMenu(
      context,
      pinned: note.pinned,
      starred: note.starred,
      paged: note.paged,
      locked: note.locked,
      archived: note.archivedAt != null,
      isList: note.type == NoteType.checklist || note.type == NoteType.ordered,
      twoColumns: note.listColumns == 2,
      hasFloatingImages: note.attachments.any((a) => a.floatsOnPage),
      hasAttachments: note.attachments.isNotEmpty,
      bubbleView:
          _readOnly || _NoteEditorScreenState._switchableDocument(note) == null
          ? null
          : note.type.isPageNoteType,
      canTemplate: canSaveAsTemplate(note),
      canRemoveParts: !_readOnly && _hasBothParts(note),
      // Yalnız KENDİ notum (başkasının notu yerel yapılamaz) ve özellik
      // destekleniyorsa (web'de yok).
      localOnly: widget.ownerId == null && localOnlySupported(ref)
          ? ref.read(notesRepositoryProvider)?.isLocal(note.id) ?? false
          : null,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'docView':
        _toggleDocumentView();
      case 'pin':
        _mutate((n) => n.copyWith(pinned: !n.pinned), immediate: true);
      case 'star':
        _mutate((n) => n.copyWith(starred: !n.starred), immediate: true);
      case 'paged':
        _mutate((n) => n.copyWith(paged: !n.paged), immediate: true);
      case 'paper':
        await _pickPaper();
      case 'search':
        await _openNoteSearch();
      case 'history':
        await _openHistory();
      case 'stats':
        // Bekleyen yazım önce diske insin: sayaç yazılan son cümleyi de
        // saysın (aramada da aynı sıra).
        _flushPending(_bodyController);
        if (mounted) await showNoteStatsSheet(context, _note ?? note);
      case 'saveTemplate':
        // Son yazılan satır da şablona girsin.
        _flushPending(_titleController);
        _flushPending(_bodyController);
        if (mounted) await saveNoteAsTemplate(context, ref, _note ?? note);
      case 'share':
        await _share();
      case 'copyText':
        await _copyNoteText();
      case 'localOnly':
        // Son yazım önce nota insin: yerel kopya en güncel hâli taşısın.
        _flushPending(_titleController);
        _flushPending(_bodyController);
        if (!mounted) return;
        final changed = await toggleNoteLocalOnly(context, ref, _note ?? note);
        if (changed != null && mounted) _update(() {});
      case 'export':
        await _export();
      case 'listen':
        await _listen();
      case 'lock':
        await _toggleLock();
      case 'archive':
        _toggleArchive();
      case 'clear':
        await _clearContent();
      case 'removeList':
        _removeListPart();
      case 'removeText':
        _removeTextPart();
      case 'toText':
        _convertToText();
      case 'toList':
        _convertToList();
      case 'sortItems':
        await _sortItems();
      case 'imagesToFiles':
        _allImagesToFiles();
      case 'toArchive':
        await _copyToArchive();
      case 'columns':
        _mutate(
          (n) => n.copyWith(listColumns: n.listColumns == 2 ? 1 : 2),
          immediate: true,
        );
      case 'settings':
        if (mounted) unawaited(context.push('/settings'));
      case 'customize':
        // Düzenleme modu: alt/üst çubuktaki öğelere dokunarak gizle/göster,
        // üstteki şeritten Kaydet (bkz. Personalize).
        FocusManager.instance.primaryFocus?.unfocus();
        Personalize.startEditing();
      case 'calculator':
        unawaited(_openCalculator());
      case 'sendToFriend':
        _flushPending(_titleController);
        _flushPending(_bodyController);
        if (mounted) {
          await showSendNoteToFriendSheet(context, ref, _note ?? note);
        }
      case 'duplicate':
        await _duplicateNote();
      case 'delete':
        _delete();
    }
  }

  /// Notu çoğaltır (ana ekrandaki kart menüsüyle aynı iş — editörün ⋮
  /// menüsünde yoktu, 2026-10-11 menü taramasında eklendi). Kopya açılmaz;
  /// geri al onu kalıcı siler.
  Future<void> _duplicateNote() async {
    _flushPending(_titleController);
    _flushPending(_bodyController);
    final note = _note;
    final repo = ref.read(notesRepositoryProvider);
    if (note == null || repo == null) return;
    final l10n = context.l10n;
    final id = await repo.duplicateNote(note);
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: note.attachments.isEmpty
          ? l10n.noteDuplicated
          : l10n.noteDuplicatedNoAttachments,
      undoLabel: l10n.undo,
      onUndo: () => repo.hardDelete(id),
    );
  }

  /// Notun eklerini bir ARŞİV DEFTERİNE fiziksel kopya olarak taşır.
  ///
  /// Hangi deftere gideceği sorulur; hiç defter yoksa kullanıcı önce bir
  /// tane oluşturmalı (defteri buradan sessizce yaratmak, kullanıcının
  /// haberi olmayan bir not üretirdi).
  Future<void> _copyToArchive() async {
    final note = _note;
    final notes = ref.read(notesRepositoryProvider);
    final attachments = ref.read(attachmentRepositoryProvider);
    if (note == null || notes == null || attachments == null) return;
    if (note.attachments.isEmpty) {
      _showSnack(context.l10n.archiveNothingToCopy);
      return;
    }
    final notebooks = [
      for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
        if ((n.paged || n.type == NoteType.archive) &&
            n.deletedAt == null &&
            n.id != note.id)
          n,
    ];
    if (notebooks.isEmpty) {
      _showSnack(context.l10n.archiveNoNotebook);
      return;
    }
    final chosen = await showAppSheet<Note>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final notebook in notebooks)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(
                  notebook.displayTitle.trim().isEmpty
                      ? sheetContext.l10n.archiveNotebook
                      : notebook.displayTitle,
                ),
                onTap: () => Navigator.pop(sheetContext, notebook),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    _showSnack(context.l10n.generating);
    final count = await copyAttachmentsToArchive(
      source: note,
      archive: chosen,
      attachments: attachments,
      notes: notes,
    );
    if (!mounted) return;
    _showSnack(context.l10n.archiveCopied(count));
  }

  /// Sayfada YÜZEN bütün görselleri ek şeridine indirir (tek işlemde).
  ///
  /// Görselin kendi menüsündeki "Ek yap" ([_setImageAsFile]) aynı işi tek
  /// görsel için yapıyor; buradaki toplu sürüm kullanıcı isteği 2026-08-16
  /// ("metin içi görselleri eke dönüştürme butonu"). Tek `_mutate` çağrısı:
  /// görsel başına ayrı yazım hem Firestore'a on ayrı güncelleme gönderir
  /// hem de geri alma yığınını on adımla doldururdu.
  void _allImagesToFiles() {
    final note = _note;
    if (note == null) return;
    final count = note.attachments.where((a) => a.floatsOnPage).length;
    if (count == 0) return;
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.floatsOnPage)
              // PDF/metin/sesin yerini `onPage` söylüyor (bkz.
              // Attachment.placedOnPage); onlara `asFile` yazmak kutuyu
              // sayfada bırakırdı.
              a.placedOnPage(false)
            else
              a,
        ],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.imagesToAttachmentsDone(count));
  }

  /// Liste notunu DÜZ METİN notuna çevirir — model çağırmadan.
  ///
  /// Maddeler gövdenin SONUNA eklenir (gövdede zaten bir açıklama olabilir)
  /// ve liste boşaltılır. Geri alınabilir: "- [x] süt" biçimindeki satırlar
  /// [itemsFromText] tarafından okunuyor, yani "metne çevir → listeye çevir"
  /// hem maddeleri hem işaretleri geri getirir.
  void _convertToText() {
    final note = _note;
    if (note == null || note.items.isEmpty) return;
    _flushPending(_bodyController);
    final converted = textFromItems(
      note.items,
      numbered: note.type == NoteType.ordered,
    );
    // `logicalText` — HAM `text` DEĞİL. KÖK NEDEN (kullanıcı 2026-08-16,
    // ekran görüntüsü): denetleyicinin metni görünmez SARMA ÇAPALARI (￼) ve
    // kelime birleştiricileri (⁠) taşıyor; ham metin gövdeye yazılınca o
    // karakterler nota kalıcı olarak girdi. Listeye geri dönüştürürken de
    // satır "￼- [x] ..." diye başladığı için madde işareti kalıbı eşleşmedi
    // ve maddelerde "OBJ- [x] ..." diye ham metin göründü.
    final existing = _bodyController.logicalText.trim();
    final body = existing.isEmpty ? converted : '$existing\n$converted';
    // `text =` değil `setLogical`: sarma planı yeni gövdeye göre yeniden
    // kurulsun, yoksa eski çapalar imleci kaydırır.
    _bodyController.setLogical(body, body.length);
    _mutate(
      (n) => n.copyWith(type: NoteType.text, body: body, items: const []),
      immediate: true,
    );
    _showSnack(context.l10n.convertedToText);
  }

  // ── KARIŞIK İÇERİKTE BÖLÜM KALDIRMA ───────────────────────────────────
  //
  // Kullanıcı isteği 2026-10-16: "liste veya metin notu kısımlarını
  // kaldırabilme, her ikisi de varken". Metin notunun altına madde listesi,
  // liste notunun başına serbest metin eklenebiliyordu ama bir bölümü
  // toptan kaldırmanın yolu yoktu (maddeleri tek tek silmek, metni seçip
  // silmek gerekiyordu). "Metne çevir/Listeye çevir" DÖNÜŞTÜRÜR; bunlar
  // bölümü SİLER. İkisi de geri alınabilir (snackbar + üst çubukta geri al).

  /// Notta hem serbest metin bölümü hem madde listesi var mı?
  bool _hasBothParts(Note note) {
    if (note.type.isPageNoteType || note.items.isEmpty) return false;
    // Metin notunda gövde alanı HEP görünür (boş olsa da bir bölümdür);
    // liste notunda ancak doluysa ya da elle açıldıysa.
    return note.type == NoteType.text ||
        note.body.trim().isNotEmpty ||
        _listBodyOpen;
  }

  /// Madde listesini kaldırır; not saf metin notu olur.
  void _removeListPart() {
    final note = _note;
    if (note == null || note.items.isEmpty) return;
    _flushPending(_bodyController);
    FocusManager.instance.primaryFocus?.unfocus();
    _mutate(
      (n) => n.copyWith(type: NoteType.text, items: const []),
      immediate: true,
    );
    _showUndoSnack(context.l10n.listPartRemoved);
  }

  /// Serbest metni kaldırır; not saf liste notu olur (sıralı liste sıralı
  /// kalır).
  void _removeTextPart() {
    final note = _note;
    if (note == null || note.items.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _bodyController.setLogical('', 0);
    _update(() => _listBodyOpen = false);
    _mutate(
      (n) => n.copyWith(
        type: n.type == NoteType.text ? NoteType.checklist : n.type,
        body: '',
      ),
      immediate: true,
    );
    _showUndoSnack(context.l10n.textPartRemoved);
  }

  void _showUndoSnack(String message) {
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        timedSnackBar(
          content: Text(message),
          action: SnackBarAction(label: l10n.undo, onPressed: _undo),
        ),
      );
  }

  /// "+ Yeni öğe" satırının sağındaki BÖLÜMLER menüsü (yalnız iki bölüm
  /// birden varken).
  Widget? _partsMenu(Note note) {
    if (_readOnly || !_hasBothParts(note)) return null;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      key: const ValueKey('note-parts-menu'),
      tooltip: l10n.notePartsMenu,
      icon: Icon(
        Icons.splitscreen_outlined,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      onSelected: (v) => v == 'list' ? _removeListPart() : _removeTextPart(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'list',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.playlist_remove_rounded),
            title: Text(l10n.removeListPart),
          ),
        ),
        PopupMenuItem(
          value: 'text',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.format_clear_rounded),
            title: Text(l10n.removeTextPart),
          ),
        ),
      ],
    );
  }

  /// Düz metin notunu LİSTE notuna çevirir — model çağırmadan.
  /// Her boş olmayan satır bir madde olur, gövde boşalır.
  void _convertToList() {
    final note = _note;
    if (note == null) return;
    _flushPending(_bodyController);
    // Yine `logicalText` (bkz. [_convertToText]'teki kök neden).
    final items = itemsFromText(
      _bodyController.logicalText,
      newId: () => const Uuid().v4(),
    );
    if (items.isEmpty) {
      _showSnack(context.l10n.convertToListEmpty);
      return;
    }
    _bodyController.setLogical('', 0);
    _mutate(
      (n) => n.copyWith(
        type: NoteType.checklist,
        body: '',
        // Metin notunda zaten madde varsa (karışık içerik) onlar korunur ve
        // yeni maddeler ARKALARINA eklenir — dönüşüm hiçbir şey silmemeli.
        items: [...n.items, ...items],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.convertedToList);
  }

  /// Maddeleri seçilen ölçüte göre sıralar (yerel, geri alınabilir bir
  /// düzenleme olarak kaydedilir).
  Future<void> _sortItems() async {
    final note = _note;
    if (note == null || note.items.isEmpty) return;
    final l10n = context.l10n;
    final choice = await showAppSheet<ItemSort>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (sort, label, icon) in <(ItemSort, String, IconData)>[
              (ItemSort.starredFirst, l10n.sortStarredFirst, Icons.star),
              (
                ItemSort.uncheckedFirst,
                l10n.sortUncheckedFirst,
                Icons.check_box_outline_blank,
              ),
              (
                ItemSort.alphabetical,
                l10n.sortAlphabetical,
                Icons.sort_by_alpha,
              ),
              (
                ItemSort.alphabeticalDesc,
                l10n.sortAlphabeticalDesc,
                Icons.sort_by_alpha,
              ),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(sheetContext, sort),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    _mutate(
      (n) => n.copyWith(items: sortItems(n.items, choice)),
      immediate: true,
    );
  }

  /// **Dışa aktarma** — eski "PDF olarak dışa aktar" maddesinin yerini alır.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "PDF olarak dışa aktar eskide
  /// kaldı"): madde her not tipinde tek bir ekrana, `PdfExportScreen`e
  /// gidiyordu. O ekran BELGE (balonlu) notunda yalnız sayfa notlarının
  /// METNİNİ yazıyor; belgenin kendisini, üzerindeki balonları, vurguları ve
  /// el yazısını hiç almıyordu. Yani PDF notunu "PDF olarak dışa aktar"mak
  /// çoğu zaman boş ya da yarım bir dosya üretiyordu — oysa balonları belgeye
  /// basan yol (bkz. NoteShare.shareAnnotatedPdfs) ZATEN vardı, sadece
  /// Paylaş levhasının içine gömülüydü.
  ///
  /// Artık: notta balonlu/çizimli bir belge varsa hangi çıktının istendiği
  /// SORULUR; yoksa doğrudan metin/görsel dışa aktarma ekranı açılır.
  Future<void> _export() async {
    final note = _note;
    if (note == null) return;
    // Bekleyen yazım önce kesinleşsin: çıktı son hâli taşımalı.
    _flushPending(_titleController);
    _flushPending(_bodyController);
    if (!mounted) return;
    final current = _note ?? note;

    if (countStampablePdfs(current) == 0) {
      _openNotesExport(current);
      return;
    }
    final choice = await showExportChoiceSheet(context);
    if (choice == null || !mounted) return;
    if (choice == 'notes') {
      _openNotesExport(current);
      return;
    }
    await runNoteShare(context, ref, current, 'pdf');
  }

  /// Not metnini (+ görselleri) PDF/Word'e aktarma ekranı.
  void _openNotesExport(Note current) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfExportScreen(
          note: current,
          // Sayfa ölçüleri: görseller dışa aktarmada da nottaki yerlerinde
          // çıksın.
          layout: () {
            final box = _pageBox();
            if (box == null) return null;
            return (
              bodyTop: _bodyTop,
              pageWidth: box.size.width,
              pageHeight: box.size.height,
            );
          }(),
        ),
      ),
    );
  }

  /// Notu sesli okur. Kilitli notta ayrıca doğrulama yok — editör zaten
  /// açılırken doğruluyor.
  ///
  /// **BELGE notunda notun kendi metni yetmez** (kullanıcı bulgusu
  /// 2026-08-08: "PDF sesli oku çalışmıyor"): PDF/sunum notunun düz metni
  /// SAYFA NOTLARIDIR ve çoğu notta boştur — okuma ekranı "okunabilir metin
  /// çıkmadı" diyip duruyordu. Artık belgenin KENDİ metni de okunuyor; sayfa
  /// notları varsa önce onlar gider (kullanıcının kendi yazdığı önce).
  Future<void> _listen() async {
    final note = _note;
    if (note == null) return;
    final title = note.title.trim();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenScreen(
          title: title.isEmpty ? context.l10n.appName : title,
          // Kilitli notun podcast metni de diske yazılmasın.
          allowCache: !note.locked,
          // toPlainText değil: başlık ve `- [x]` işaretleri okunmasın.
          loadText: () =>
              noteSpeechText(note, ref.read(attachmentRepositoryProvider)),
        ),
      ),
    );
  }

  /// Not kilidi: kilitlemek serbest, kilidi kaldırmak kimlik doğrulaması
  /// ister (kart zaten açarken doğruluyor ama menüden de korunmalı).
  Future<void> _toggleLock() async {
    final note = _note;
    if (note == null) return;
    if (note.locked) {
      final ok = await authenticateForNote(context.l10n.unlockAuthReason);
      if (!ok) return;
    }
    _mutate((n) => n.copyWith(locked: !n.locked), immediate: true);
  }

  void _toggleArchive() {
    final note = _note;
    if (note == null) return;
    final archived = note.archivedAt != null;
    _mutate(
      (n) => archived
          ? n.copyWith(clearArchivedAt: true)
          : n.copyWith(archivedAt: DateTime.now()),
      immediate: true,
    );
    if (!archived) Navigator.of(context).pop();
  }

  /// AI çıktısıyla notun içeriğini değiştirir ("Geliştir" sonuçları için).
  /// [asType] verilirse not o çalışma moduna da geçirilir: "maddelere çevir"
  /// sonucu yalnızca metni değil notun tipini de checklist/sıralı yapar.
  void _replaceText(String raw, {NoteType? asType, bool keepChecked = false}) {
    final note = _note;
    // Model istenmese de ** / * / # üretebiliyor; not düz metin tuttuğundan
    // temizle.
    final text = stripMarkdown(raw);
    if (note == null || text.trim().isEmpty) return;
    // Değişiklik öncesi anlık görüntü: "Geri al" bununla eski hâle döner.
    final before = note;
    final targetType = asType ?? note.type;
    // İşaretli maddeler AI'a hiç gönderilmemişti (ayar açık): sonuç yalnız
    // işaretsizlerin yerine geçer, işaretli (tamamlanmış) maddeler metni ve
    // işaretiyle AYNEN korunur — sonlarına eklenir (uygulamanın "işaretliler
    // altta" düzeni). Kullanıcının "işaretlilere karışma" isteği.
    if (keepChecked && targetType == NoteType.checklist) {
      const uuid = Uuid();
      final newUnchecked = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty)
            NoteItem(id: uuid.v4(), text: _parseListLine(line).text),
      ];
      final preservedChecked = [
        for (final item in note.items)
          if (item.checked) item,
      ];
      _mutate(
        (n) => n.copyWith(items: [...newUnchecked, ...preservedChecked]),
        immediate: true,
      );
      _offerReplaceUndo(before);
      return;
    }
    if (targetType == NoteType.text) {
      _bodyController.text = text.trim();
      _mutate(
        (n) => n.copyWith(type: targetType, body: text.trim()),
        immediate: true,
      );
    } else {
      const uuid = Uuid();
      final parsed = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty) _parseListLine(line),
      ];
      // Tip korunuyor ve öğe sayısı birebir aynıysa (düzeltme sırayı bozmaz)
      // mevcut kimlikler ve işaretli/işaretsiz durum korunur — kullanıcının
      // işaretlediği maddeler düzeltme sonrası işaretli kalır.
      final keepState =
          targetType == note.type && parsed.length == note.items.length;
      // Sayı/sıra değişse de (kısaltma, yeniden sıralama) işaret durumu
      // kaybolmasın: eski öğelerin normalize metni → işaret eşlemesi kurulur,
      // yeni satır eskisiyle (yazım düzeltilmiş de olsa birebir eşleşen)
      // bulunursa işareti devralır.
      String norm(String s) => s.trim().toLowerCase();
      final oldChecked = {
        for (final item in note.items) norm(item.text): item.checked,
      };
      _mutate(
        (n) => n.copyWith(
          type: targetType,
          // Tip değişiyorsa eski gövde temizlenir; içerik artık öğelerde.
          body: targetType == note.type ? null : '',
          items: [
            for (var i = 0; i < parsed.length; i++)
              NoteItem(
                id: keepState ? n.items[i].id : uuid.v4(),
                text: parsed[i].text,
                // Sıralı listede işaret anlamsız; checklist'te korunur/okunur.
                checked: targetType != NoteType.checklist
                    ? false
                    : keepState
                    ? n.items[i].checked
                    : (oldChecked[norm(parsed[i].text)] ?? parsed[i].checked),
              ),
          ],
        ),
        immediate: true,
      );
      if (targetType != note.type) _bodyController.clear();
    }
    _offerReplaceUndo(before);
  }

  /// Sürüm geçmişi (F4.2): seçilen sürüme dönmeden önce bugünkü hâl de
  /// sürüm olarak saklanır — dönüş de geri alınabilir.
  Future<void> _openHistory() async {
    final repo = _notesRepo;
    final note = _note;
    if (repo == null || note == null) return;
    _flushPending(_titleController);
    _flushPending(_bodyController);
    final version = await showNoteHistorySheet(context, repo, note.id);
    if (version == null || !mounted) return;
    final current = _note ?? note;
    await repo.saveVersion(current, reason: 'restore');
    if (!mounted) return;
    final restored = version.applyTo(current);
    _titleController.text = restored.title;
    _bodyController.text = restored.body;
    _mutate((_) => restored, immediate: true);
    _showSnack(context.l10n.versionRestored);
  }

  /// "Notu değiştir" sonrası geri alma: eski not anlık görüntüsüne (metin,
  /// öğeler, tip, başlık) tek dokunuşla döner.
  void _offerReplaceUndo(Note before) {
    // AI değiştirmeden önceki hâl sürüm geçmişinde de kalır (F4.2): geri
    // alma 4 sn sonra kaybolur, sürüm kalır.
    unawaited(_notesRepo?.saveVersion(before, reason: 'ai'));
    if (!mounted) return;
    // Snackbar KÖK messenger'da yaşar ve editör kapandıktan sonra da 4 sn
    // ekranda kalır: depo şimdiden yakalanır ki geri alma editörsüz de
    // çalışsın; unmount SONRASI dokunuşta denetleyici/ref/setState'e
    // dokunulmaz (dispose edilmiş controller'a yazmak çökertiyordu).
    // AÇIK OLAN notun deposu (`_notesRepo`): paylaşılan bir notta geri alma
    // sahibin koleksiyonuna yazmalı, benimkine değil.
    final repo = _notesRepo;
    showUndoSnackBar(
      context,
      message: context.l10n.noteUpdatedUndo,
      undoLabel: context.l10n.undo,
      onUndo: () {
        repo?.updateNote(before);
        if (!mounted) return;
        _titleController.text = before.title;
        _bodyController.text = before.body;
        _update(() => _note = before);
      },
    );
  }

  /// AI çıktısını ORİJİNAL notu değiştirmeden YENİ bir notta açar (madde 1-2).
  /// Böylece kullanıcıda hem "değiştirmeden" orijinal hem de "düzeltilmiş"
  /// sürüm ayrı notlar olarak kalır. Başlık ve klasör yeni nota taşınır;
  /// [asType] verilirse (liste dönüşümü) yeni not o tipte oluşturulur.
  Future<void> _createNoteFromText(
    String raw, {
    NoteType? asType,
    bool keepChecked = false,
  }) async {
    final note = _note;
    final text = stripMarkdown(raw);
    if (note == null || text.trim().isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final type = asType ?? note.type;
    final id = await repo.createNote(type);
    final fields = <String, dynamic>{};
    if (note.title.trim().isNotEmpty) fields['title'] = note.title;
    if (note.folderId != null) fields['folderId'] = note.folderId;
    if (type == NoteType.text) {
      fields['body'] = text.trim();
      // Karışık not (metin + checklist): AI yalnız gövdeyi düzeltti; maddeler
      // yeni notta da olduğu gibi korunur (düz metne dönüşmez).
      final items = [
        for (final i in note.items)
          if (i.text.trim().isNotEmpty) i,
      ];
      if (items.isNotEmpty) {
        fields['items'] = [for (final i in items) i.toMap()];
      }
    } else {
      const uuid = Uuid();
      final items = <NoteItem>[];
      for (final line in text.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parsed = _parseListLine(line);
        items.add(
          NoteItem(
            id: uuid.v4(),
            text: parsed.text,
            checked: type == NoteType.checklist ? parsed.checked : false,
          ),
        );
      }
      // İşaretliler kapsam dışıydı: korunan (tamamlanmış) maddeler yeni notta
      // da işaretli olarak sona eklenir (işaretsiz düzeltilmişlerin ardına).
      if (keepChecked && type == NoteType.checklist) {
        for (final item in note.items) {
          if (item.checked) {
            items.add(NoteItem(id: uuid.v4(), text: item.text, checked: true));
          }
        }
      }
      fields['items'] = [for (final it in items) it.toMap()];
      // createNote liste tipini bir boş öğeyle tohumlar; gövde artık öğelerde.
      fields['body'] = '';
    }
    repo.updateFields(id, fields);
    if (mounted) unawaited(context.pushNote(noteRoutePath(id)));
  }

  /// AI çıktısını (OCR/döküm) notun gövdesine ya da liste öğelerine ekler.
  /// Markdown işaretleri temizlenir — model istenmese de **kalın**/# üretiyor.
  void _appendText(String raw) => _appendPlainText(stripMarkdown(raw));

  /// Metni OLDUĞU GİBİ (Markdown temizliği yapmadan) nota ekler. QR içeriği
  /// gibi makine verisinde temizlik zararlı: `#` ile başlayan bir satır ya da
  /// `*` taşıyan bir adres bozulurdu.
  void _appendPlainText(String text) {
    final note = _note;
    if (note == null || text.trim().isEmpty) return;
    if (note.type == NoteType.text) {
      final combined = note.body.trim().isEmpty
          ? text.trim()
          : '${note.body}\n\n${text.trim()}';
      _bodyController.text = combined;
      _mutate((n) => n.copyWith(body: combined), immediate: true);
    } else {
      const uuid = Uuid();
      final lines = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty) _parseListLine(line).text,
      ];
      _mutate((n) {
        // Listede sonda hep boş bir "yeni öğe" satırı bekler. Yeni maddeler
        // onun ARKASINA eklenince o boş satır ortada kalıyordu; eklemeden
        // önce sondaki boşlar atılır. Dikte ve AI ekleme aynı yoldan
        // geçtiğinden ikisi de düzelir.
        final kept = [...n.items];
        while (kept.isNotEmpty && kept.last.text.trim().isEmpty) {
          kept.removeLast();
        }
        return n.copyWith(
          items: [
            ...kept,
            for (final line in lines) NoteItem(id: uuid.v4(), text: line),
          ],
        );
      }, immediate: true);
    }
  }
}
