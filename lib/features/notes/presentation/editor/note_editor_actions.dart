part of 'note_editor_screen.dart';

/// Not eylemleri: hatırlatıcı, etiket, klasör, paylaş, ⋮ menüsü, çoğalt, dönüştür, sırala, dışa aktar, kilit, arşiv, metin değiştir, geçmiş.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorActions on _NoteEditorScreenState {
  // ---- Diğer eylemler -------------------------------------------------

  /// "+" düğmesinin yanındaki PAYLAŞIM durumu: yalnız paylaşılmış notta kişi
  /// simgesi + sayı; dokununca ortak çalışanlar. Abonelik yalnız bu küçük
  /// parçada — paylaşım akışı editörün tamamını yeniden kurmasın.
  Widget _collabMarker(ThemeData theme) {
    return Consumer(
      builder: (context, ref, _) {
        final owner = widget.ownerId;
        // Benim dışımdaki kişi sayısı. Bana paylaşılan notta da aynı sayı
        // (sharedWith beni içerir, sahip sayılmaz). Paylaşılan klasördeki
        // notta ortak not kaydı yok: yalnız simge.
        final count = owner == null
            ? ref.watch(
                myNoteSharesProvider.select(
                  (m) => m.value?[widget.noteId]?.sharedWith.length ?? 0,
                ),
              )
            : ref.watch(
                sharedNotesWithMeProvider.select(
                  (s) =>
                      s.value
                          ?.where(
                            (e) =>
                                e.ownerId == owner && e.noteId == widget.noteId,
                          )
                          .firstOrNull
                          ?.sharedWith
                          .length ??
                      0,
                ),
              );
        if (owner == null && count == 0) return const SizedBox.shrink();
        final accent =
            NoteAccent.maybeOf(context)?.accent ?? theme.colorScheme.primary;
        return Tooltip(
          message: context.l10n.collaborators,
          child: InkWell(
            key: const ValueKey('note-meta-collab'),
            borderRadius: BorderRadius.circular(AppRadius.m),
            onTap: _openCollaborators,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.shared, size: 15, color: accent),
                  if (count > 0) ...[
                    const SizedBox(width: 2),
                    Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCollaborators() => unawaited(
    showCollaboratorsSheet(
      context,
      ref,
      noteId: widget.noteId,
      ownerId: widget.ownerId,
    ),
  );

  /// Başlıktaki "+": notun kendisine dair ekleme ve öneriler (F38.3). Çok
  /// işlemli olduğu için levha (F38.6 kuralı).
  Future<void> _openMetaMenu(
    Note note,
    IconData? folderIcon, {
    required bool canCollab,
  }) async {
    final l10n = context.l10n;
    _dismissKeyboard();
    final canAi = !note.isEmpty && !note.locked && !_readOnly;
    final action = await showActionMenuSheet(
      context,
      ActionMenu(
        menuId: 'note.add',
        title: note.displayTitle,
        quick: [
          MenuAction('add-tag', l10n.addTag, Icons.new_label_outlined),
          MenuAction('reminder', l10n.addReminder, Icons.alarm_add_outlined),
          // Takvime ekle (kullanıcı isteği 2026-11-06): gün + saat seçilir,
          // not bağlı etkinlik açılır.
          if (!_readOnly)
            MenuAction(
              'calendar-add',
              l10n.calendarSuggestAction,
              Icons.event_available_outlined,
            ),
          if (canCollab)
            MenuAction(
              'collaborators',
              l10n.collaborators,
              Icons.person_add_alt_1_outlined,
              badge: ref.read(isAnonymousProvider)
                  ? const AccountLockBadge(size: 14)
                  : null,
            ),
          MenuAction(
            'folder',
            l10n.folder,
            folderIcon ?? Icons.create_new_folder_outlined,
          ),
        ],
        sections: [
          MenuSection(l10n.menuSectionOrganize, [
            // Sayfa notun İÇERİĞİ değil YAPISI (kullanıcı isteği 2026-10-11).
            if (!note.type.isPageNoteType)
              MenuAction(
                'new-page',
                l10n.archiveNewPage,
                Icons.note_add_outlined,
              ),
            // ZAMANLI NOT (kullanıcı isteği 2026-11-16): süre dolunca arşive.
            if (!_readOnly)
              MenuAction(
                'expiry',
                l10n.noteExpiry,
                Icons.hourglass_bottom,
                selected: note.expiresAt != null,
              ),
            if (PlaceReminderService.supported)
              MenuAction(
                'place-reminder',
                l10n.placeReminder,
                Icons.add_location_alt_outlined,
              ),
          ]),
          MenuSection(l10n.menuSectionTools, [
            if (!note.isEmpty)
              MenuAction('suggest-tags', l10n.suggestTags, Icons.auto_awesome),
            // İlgili notlar (yerel, 0 kredi): kilitli notta yok.
            if (canAi)
              MenuAction(
                'related-notes',
                l10n.relatedNotesTitle,
                Icons.hub_outlined,
              ),
          ]),
        ],
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'new-page':
        _addPage();
      case 'reminder':
        await _pickReminder();
      case 'calendar-add':
        await _addToCalendar(note);
      case 'expiry':
        await _pickExpiry();
      case 'place-reminder':
        unawaited(showPlaceReminderSheet(context, ref, note));
      case 'folder':
        await _pickFolder();
      case 'collaborators':
        _openCollaborators();
      case 'add-tag':
        await _addTag();
      case 'suggest-tags':
        await _suggestTags();
      case 'related-notes':
        unawaited(
          showRelatedNotesSheet(
            context,
            noteId: note.id,
            onLink: _linkNoteAtEnd,
          ),
        );
    }
  }

  /// TEK LEVHA (2026-11-06): zaman, tekrar ve kaldırma aynı yerde.
  Future<void> _pickReminder() async {
    final note = _note;
    if (note == null) return;
    final choice = await showReminderSheet(
      context,
      current: note.reminderAt,
      repeat: note.reminderRepeat,
      level: note.reminderLevel,
    );
    if (choice == null || !mounted) return;
    applyReminderChoice(
      context,
      choice: choice,
      previousAt: note.reminderAt,
      previousRepeat: note.reminderRepeat,
      previousLevel: note.reminderLevel,
      write: (at, repeat, level) => _mutate(
        (n) => at == null
            ? n.copyWith(clearReminderAt: true)
            : n.copyWith(
                reminderAt: at,
                reminderRepeat: repeat,
                reminderLevel: level,
              ),
        immediate: true,
      ),
    );
    if (choice.at != null && mounted) {
      unawaited(maybeShowAutoStartHint(context));
    }
  }

  /// ZAMANLI NOT: süre seç / kaldır (kart ⋮ ile aynı levha).
  Future<void> _pickExpiry() async {
    final note = _note;
    if (note == null) return;
    final choice = await pickNoteExpiry(context, current: note.expiresAt);
    if (choice == null || !mounted) return;
    final at = choice.at;
    if (at == null) return _clearExpiry();
    _mutate((n) => n.copyWith(expiresAt: at), immediate: true);
  }

  /// Not.toMap boş süreyi YAZMAZ (merge'de silinmez): kaldırma açık yazım.
  void _clearExpiry() {
    _mutate((n) => n.copyWith(clearExpiresAt: true), immediate: true);
    _notesRepo?.updateFields(widget.noteId, {'expiresAt': null});
  }

  void _clearReminder() =>
      _mutate((n) => n.copyWith(clearReminderAt: true), immediate: true);

  /// ACİL aç/kapa. `toMap` alanı yalnız açıkken yazar (her nota bayt eklemez,
  /// S16 bütçesi); birleştirme yazımı eksik alanı silmediği için kapatmak
  /// açıkça `false` yazar.
  void _setUrgent(bool on) {
    _mutate((n) => n.copyWith(urgent: on), immediate: true);
    if (!on) _notesRepo?.setUrgent(widget.noteId, false);
  }

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
                        actionChip(
                          ActionChip(
                            label: Text('#$t'),
                            onPressed: () {
                              // Çipe dokununca doğrudan eklenir (metin kutusuna
                              // yazmaya gerek yok), diyalog kapanır.
                              Navigator.pop(dialogContext);
                              _applyTag(t);
                            },
                          ),
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

  /// Üst bardaki ⋮: kart ⋮ ile tek katalog (bkz. [noteMenuModel]).
  Future<void> _openNoteMenu() async {
    final note = _note;
    if (note == null) return;
    // Levha metin alanı taşımıyor; klavye açık kalırsa levhanın yarısını
    // örter (alt bardaki diğer levhalarla aynı kural).
    final sheetFocus = _dismissKeyboardAfterSheet();
    final action = await showActionMenuSheet(
      requestFocus: sheetFocus,
      context,
      noteMenuModel(
        context.l10n,
        note,
        surface: NoteMenuSurface.editor,
        readOnly: _readOnly,
        // Bu ekranda başka yerde AÇIKÇA duranlar (raptiye ve notta ara);
        // kullanıcı kişiselleştirmede gizlediyse menüye geri gelir.
        visibleElsewhere: {
          if (Customizable.shows(UiItem.topPin)) 'pin',
          // Notta ara üst çubukta (⋮'nin solunda) hep duruyor.
          'search',
        },
        // bubbleView verilmez: balonlu görünüm kalktı (2026-11-05).
        canRemoveParts: !_readOnly && _hasBothParts(note),
        canPinHome: NoteShortcut.supported && widget.ownerId == null,
        // Yalnız KENDİ notum (başkasının notu yerel yapılamaz) ve özellik
        // destekleniyorsa (web'de yok).
        localOnlyAvailable: widget.ownerId == null && localOnlySupported(ref),
        localOnly: ref.read(notesRepositoryProvider)?.isLocal(note.id) ?? false,
        historyLocked: !ref.read(proFeatureProvider(ProFeature.versionHistory)),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'pinHome':
        await pinNoteToHome(context, note);
      case 'color':
        await _showColorSheet();
      case 'frame':
        await _pickNoteColor(frame: true);
      case 'cardMedia':
        _mutate(
          (n) => n.copyWith(cardMediaHidden: !n.cardMediaHidden),
          immediate: true,
        );
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
      case 'folder':
        await _pickFolder();
      case 'calendar':
        await showLinkNoteToCalendarSheet(context, _note ?? note);
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
      case 'spellCheck':
        await _reviewSpelling();
      case 'clear':
        await _clearContent();
      case 'removeList':
        _removeListPart();
      case 'removeText':
        _removeTextPart();
      case 'listMode':
        await _openListModePicker();
      case 'extractText':
        await _openTextExtract();
      case 'toText':
        _convertToText();
      case 'toList':
        _convertToList();
      case 'sortItems':
        await _sortItems();
      case 'finishShopping':
        _finishShoppingList();
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
      case 'duplicate':
        await _duplicateNote();
      case 'delete':
        _delete();
    }
  }

  /// Y-5: bütün notun toplu yazım denetimi — tüm seçilen düzeltmeler tek
  /// Geri Al adımında uygulanır.
  Future<void> _reviewSpelling() async {
    final note = _note;
    if (note == null || _readOnly) return;
    _flushPending(_titleController);
    _flushPending(_bodyController);
    await AutoSpell.load();
    if (!mounted) return;
    final current = _note ?? note;
    final findings = scanNoteSpellFindings(
      title: _titleController.logicalText,
      body: _bodyController.logicalText,
      items: current.items,
      memory: AutoSpell.memory,
      noteKeep: AutoSpell.noteKeep,
      attachmentNames: _bodyController.attachmentNames,
    );
    final chosen = await showSpellReviewSheet(context, findings: findings);
    if (chosen.isEmpty || !mounted) return;
    final applied = applySpellReview(
      title: _titleController.logicalText,
      body: _bodyController.logicalText,
      items: current.items,
      findings: findings,
      replacements: chosen,
    );
    if (applied.count == 0) return;
    if (applied.title != _titleController.logicalText) {
      _titleController.setLogical(applied.title, applied.title.length);
    }
    if (applied.body != _bodyController.logicalText) {
      _bodyController.setLogical(applied.body, applied.body.length);
    }
    _mutate(
      (n) => n.copyWith(
        title: applied.title,
        body: applied.body,
        items: applied.items,
      ),
      immediate: true,
    );
    _showUndoSnack(context.l10n.spellReviewFixed(applied.count));
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
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final notebook in notebooks)
              ListTile(
                leading: const Icon(Icons.book_outlined),
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
  /// Görselin görünüm anahtarındaki "Ek" aynı işi tek görsel için yapıyor;
  /// buradaki toplu sürüm kullanıcı isteği 2026-08-16
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

  /// **LİSTE ↔ NUMARALI** (kullanıcı isteği 2026-11-16: "madde notlarında
  /// numaralıya geçiş, numaralıda maddeye geçiş olsun alt panelde"). Alt
  /// çubuğun türe özgü yuvası ([UiItem.barCheckbox]; metin notunda ☑).
  /// Maddeler, işaretler ve sıra aynen kalır; üst çubuktan geri alınır.
  void _toggleListKind() {
    final note = _note;
    if (note == null) return;
    final next = switch (note.type) {
      NoteType.checklist => NoteType.ordered,
      NoteType.ordered => NoteType.checklist,
      _ => null,
    };
    if (next == null) return;
    _mutate((n) => n.copyWith(type: next), immediate: true);
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
    ScaffoldMessenger.of(context).showMessage(
      message,
      action: SnackBarAction(label: l10n.undo, onPressed: _undo),
    );
  }

  /// "+ Yeni öğe" satırının sağındaki BÖLÜMLER menüsü (yalnız iki bölüm
  /// birden varken).
  Widget? _partsMenu(Note note) {
    if (_readOnly || !_hasBothParts(note)) return null;
    final l10n = context.l10n;
    final scheme = _themeOf(context).colorScheme;
    return PopupMenuButton<String>(
      key: const ValueKey('note-parts-menu'),
      tooltip: l10n.notePartsMenu,
      icon: Icon(
        Icons.splitscreen_outlined,
        size: AppIconSize.m,
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
              (ItemSort.byGroup, l10n.sortByGroup, Icons.category_outlined),
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
    if (choice == ItemSort.byGroup) {
      final kind = detectNoteListKind(note, locale: l10n.localeName);
      final learned = ref.read(quickEntryMemoryProvider).itemGroups;
      _mutate(
        (n) => n.copyWith(
          items: sortItemsBySmartGroup(
            n.items,
            kind: kind,
            locale: l10n.localeName,
            learnedGroups: learned,
          ),
        ),
        immediate: true,
      );
      return;
    }
    _mutate(
      (n) => n.copyWith(items: sortItems(n.items, choice)),
      immediate: true,
    );
  }

  /// AL-2 "Alınanları tamamla": işaretli maddeleri sıklık + tarih hafızasına
  /// (AL-4 tahmin) işleyip listeden kaldırır; "Yoktu/Sonraya" işaretliler dahil
  /// kalanlar durur, tek Geri Al.
  void _finishShoppingList() {
    final note = _note;
    if (note == null || _readOnly) return;
    final checked = [
      for (final i in note.items)
        if (!i.header && i.checked) i,
    ];
    if (checked.isEmpty) return;
    final l10n = context.l10n;
    final kind = detectNoteListKind(note, locale: l10n.localeName);
    final memKind = switch (kind) {
      SmartListKind.shopping => 'smart:market',
      SmartListKind.packing => 'smart:bavul',
      SmartListKind.generic => 'smart',
      _ => 'smart:${kind.name}',
    };
    ref.read(quickEntryMemoryProvider.notifier).record(memKind, [
      for (final i in checked) stripRichMarkers(i.text),
    ]);
    final shopMem = ref.read(shopMemoryProvider.notifier);
    for (final item in checked) {
      final meta = ShopItemMeta.fromItem(item);
      if (meta.unitPrice != null && meta.unitPrice! > 0) {
        shopMem.recordPrice(
          item.text,
          meta.unitPrice!,
          store: meta.store,
          unit: meta.unit,
        );
      }
    }
    _mutate(
      (n) => n.copyWith(
        items: [
          for (final i in n.items)
            if (i.header || !i.checked) i,
        ],
      ),
      immediate: true,
    );
    _showUndoSnack(l10n.finishShoppingDone(checked.length));
  }

  /// Liste kipini (`general | shopping | routine | template | project`)
  /// doğrudan not üzerinde değiştirir.
  void _setListMode(ListMode mode) {
    final note = _note;
    if (note == null || _readOnly) return;
    _projectFocusN.value = false;
    _projectFocusIdsN.value = const {};
    _mutate((n) {
      final nextSchedule = mode == ListMode.routine &&
              n.resetSchedule == ResetSchedule.none
          ? ResetSchedule.daily
          : (mode != ListMode.routine ? ResetSchedule.none : n.resetSchedule);
      final nextKind = switch (mode) {
        ListMode.shopping => 'shopping',
        ListMode.routine => n.listKind ?? 'habits',
        ListMode.template => n.listKind ?? 'packing',
        ListMode.project => n.listKind ?? 'project',
        ListMode.general => null,
      };
      return n.copyWith(
        listMode: mode,
        resetSchedule: nextSchedule,
        listKind: nextKind,
        clearListKind: mode == ListMode.general,
      );
    }, immediate: true);
    _notesRepo?.setListMode(widget.noteId, mode);
    if (mode == ListMode.routine && note.resetSchedule == ResetSchedule.none) {
      _notesRepo?.setResetSchedule(widget.noteId, ResetSchedule.daily);
    } else if (mode != ListMode.routine &&
        note.resetSchedule != ResetSchedule.none) {
      _notesRepo?.setResetSchedule(widget.noteId, ResetSchedule.none);
    }
  }

  /// Rutin sıfırlama takvimini günceller.
  void _setResetSchedule(ResetSchedule schedule, List<int> customDays) {
    if (_note == null || _readOnly) return;
    _mutate(
      (n) => n.copyWith(
        resetSchedule: schedule,
        resetCustomDays: schedule == ResetSchedule.customDays
            ? customDays
            : const [],
      ),
      immediate: true,
    );
    _notesRepo?.setResetSchedule(
      widget.noteId,
      schedule,
      customDays: schedule == ResetSchedule.customDays ? customDays : const [],
    );
  }

  /// Bağlamsal zaman dilimini günceller (`morning | evening | weekend | any`).
  void _setContextTimeSlot(ContextTimeSlot slot) {
    if (_note == null || _readOnly) return;
    _mutate((n) => n.copyWith(contextTimeSlot: slot), immediate: true);
    _notesRepo?.setContextTimeSlot(widget.noteId, slot);
  }

  /// Şablon kipi: tek dokunuşla tüm tikleri sıfırlar (+ Geri Al).
  void _resetTemplateItems() {
    final note = _note;
    if (note == null || _readOnly) return;
    if (!note.items.any((i) => !i.header && i.checked)) return;
    unawaited(AppHaptics.tick());
    _mutate(
      (n) => n.copyWith(
        items: [
          for (final i in n.items)
            i.header ? i : i.copyWith(checked: false),
        ],
      ),
      immediate: true,
    );
    _showUndoSnack(context.l10n.templateResetDone);
  }

  /// Şablon kipi: tüm tikleri temizlenmiş yeni bir liste kopyası oluşturur.
  Future<void> _copyTemplateAsNewList() async {
    final note = _note;
    final repo = ref.read(notesRepositoryProvider);
    if (note == null || repo == null) return;
    final l10n = context.l10n;
    final id = await repo.duplicateNote(note, resetChecked: true);
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.noteDuplicated,
      undoLabel: l10n.undo,
      onUndo: () => repo.hardDelete(id),
    );
  }

  /// Canlı doğal dil ayrıştırıcıdan gelen yapılandırılmış maddeyi ekler.
  void _addParsedItem(NoteItem item) {
    final note = _note;
    if (note == null || _readOnly) return;
    final l10n = context.l10n;
    final learned = ref.read(quickEntryMemoryProvider).itemGroups;
    _mutate((n) {
      if (n.listMode == ListMode.shopping) {
        final next = insertItemsBySmartGroup(
          n.items,
          [item],
          kind: SmartListKind.shopping,
          locale: l10n.localeName,
          learnedGroups: learned,
        );
        return n.copyWith(items: next);
      }
      if (n.listMode == ListMode.routine) {
        return n.copyWith(items: [...n.items, item]);
      }
      final unchecked = [
        for (final i in n.items)
          if (!i.checked) i,
      ];
      final checked = [
        for (final i in n.items)
          if (i.checked) i,
      ];
      return n.copyWith(items: [...unchecked, item, ...checked]);
    }, immediate: true);
  }

  /// Alışveriş / genel satır için hızlı fiyat + reyon levhası (Kural 3 & 5).
  Future<void> _openItemPriceSheet(NoteItem item) async {
    final note = _note;
    if (note == null || _readOnly) return;
    final l10n = context.l10n;
    final learned = ref.read(quickEntryMemoryProvider).itemGroups;
    final curAisle = resolveItemAisle(
      item,
      locale: l10n.localeName,
      learnedGroups: learned,
    );
    final res = await showShopPriceSheet(
      context,
      item: item,
      currentAisle: curAisle,
      memory: ref.read(shopMemoryProvider),
    );
    if (res == null || !mounted) return;
    final updated = ShopItemMeta.fromItem(item)
        .copyWith(
          unitPrice: res.price,
          clearPrice: res.price == null,
          store: res.store,
          aisle: res.aisle,
        )
        .applyToItem(item);
    _mutate(
      (n) => n.copyWith(
        items: [
          for (final i in n.items)
            if (i.id == item.id) updated else i,
        ],
      ),
      immediate: true,
    );
    if (res.aisle != curAisle && res.aisle >= 0) {
      ref
          .read(quickEntryMemoryProvider.notifier)
          .learnGroup(item.text, res.aisle);
    }
    if (res.price != null && res.price! > 0) {
      ref.read(shopMemoryProvider.notifier).recordPrice(
        item.text,
        res.price!,
        store: res.store,
        unit: updated.unit,
      );
    }
  }

  /// Alışveriş kipi barkod tarama (doğrudan not üzerine ekler).
  Future<void> _openShoppingBarcode() async {
    final note = _note;
    if (note == null || _readOnly) return;
    final code = await openQrScanner(context);
    if (code == null || code.trim().isEmpty || !mounted) return;
    final memory = ref.read(shopMemoryProvider);
    final product = await lookupBarcodeProduct(code, memory: memory);
    if (!mounted) return;
    final name = product?.name.trim().isNotEmpty == true
        ? product!.name.trim()
        : code.trim();
    if (product != null) {
      ref.read(shopMemoryProvider.notifier).saveBarcode(product);
    }
    final aisle = product?.aisle;
    _addParsedItem(
      NoteItem(
        id: const Uuid().v4(),
        text: name,
        category: aisle != null && aisle >= 0
            ? (aisleCategoryKey(aisle) ?? '')
            : '',
      ),
    );
  }

  /// Alışveriş kipi fiş OCR fiyat güncellemesi (doğrudan not üzerinde).
  Future<void> _openShoppingReceipt() async {
    final note = _note;
    if (note == null || _readOnly) return;
    final res = await showShopReceiptSheet(context, items: note.items);
    if (res == null || res.matches.isEmpty || !mounted) return;
    final priceById = <String, double>{
      for (final m in res.matches) m.itemId: m.receiptLine.price,
    };
    final unitById = <String, String>{
      for (final i in note.items) i.id: i.unit,
    };
    _mutate(
      (n) => n.copyWith(
        items: [
          for (final i in n.items)
            if (priceById.containsKey(i.id))
              ShopItemMeta.fromItem(i)
                  .copyWith(
                    unitPrice: priceById[i.id],
                    store: res.storeId,
                  )
                  .applyToItem(i)
            else
              i,
        ],
      ),
      immediate: true,
    );
    final shopMem = ref.read(shopMemoryProvider.notifier);
    for (final m in res.matches) {
      shopMem.recordPrice(
        m.itemText,
        m.receiptLine.price,
        store: res.storeId,
        unit: unitById[m.itemId] ?? '',
      );
    }
  }

  /// Alışveriş kipi tarif malzemelerini doğrudan nota ekler.
  Future<void> _openShoppingRecipes() async {
    final note = _note;
    if (note == null || _readOnly) return;
    final l10n = context.l10n;
    final shopMem = ref.read(shopMemoryProvider);
    final outcome = await showShopRecipesSheet(
      context,
      customRecipes: shopMem.customRecipes,
      onSaveCustomRecipe: (r) =>
          ref.read(shopMemoryProvider.notifier).saveCustomRecipe(r),
      onDeleteCustomRecipe: (id) =>
          ref.read(shopMemoryProvider.notifier).deleteCustomRecipe(id),
    );
    if (outcome == null ||
        outcome.selectedIngredients.isEmpty ||
        !mounted) {
      return;
    }
    final learned = ref.read(quickEntryMemoryProvider).itemGroups;
    _mutate(
      (n) => n.copyWith(
        items: mergeRecipeIntoItems(
          n.items,
          outcome.selectedIngredients,
          locale: l10n.localeName,
          learnedGroups: learned,
        ),
      ),
      immediate: true,
    );
  }

  /// Alışveriş kipi reyon yürüyüş sırasını düzenler.
  Future<void> _openShoppingAisleOrder() async {
    final l10n = context.l10n;
    final cur = ref.read(shopMemoryProvider).aisleOrderFor('');
    final order = await showShopAisleOrderSheet(
      context,
      storeLabel: l10n.listModeShopping,
      currentOrder: cur,
    );
    if (order == null || !mounted) return;
    ref.read(shopMemoryProvider.notifier).saveStoreAisleOrder('', order);
    _update(() {});
  }

  /// Şablon (bavul) sihirbazını notun üzerinde hafif levha olarak açar.
  Future<void> _openPackingWizard() async {
    final note = _note;
    if (note == null || _readOnly) return;
    final generated = await showTripPackingWizardSheet(context);
    if (generated == null || generated.isEmpty || !mounted) return;
    final existingKeys = {
      for (final i in note.items) quickItemKey(i.text),
    };
    final toAdd = <NoteItem>[
      for (final g in generated)
        if (!existingKeys.contains(quickItemKey(g.text)))
          NoteItem.fromMap({
            'id': const Uuid().v4(),
            'text': g.text,
            ...g.extras,
          }),
    ];
    if (toAdd.isEmpty) return;
    _mutate((n) => n.copyWith(items: [...n.items, ...toAdd]), immediate: true);
  }

  /// Proje kipi: odaklanılacak en fazla 3 maddeyi seçer.
  Future<void> _pickProjectFocusItems() async {
    final note = _note;
    if (note == null) return;
    final chosen = await showProjectFocusPickerSheet(
      context,
      items: note.items,
      selectedIds: _projectFocusIdsN.value,
    );
    if (chosen == null || !mounted) return;
    _projectFocusIdsN.value = chosen;
    if (chosen.isNotEmpty) _projectFocusN.value = true;
  }

  /// Proje kipi: tek maddeyi odak kümesine ekler / çıkarır (en çok 3).
  void _toggleProjectFocusItem(NoteItem item) {
    final next = {..._projectFocusIdsN.value};
    if (!next.remove(item.id)) {
      if (next.length >= 3) next.remove(next.first);
      next.add(item.id);
    }
    _projectFocusIdsN.value = next;
  }

  /// Liste kipi seçim levhasını ⋮ menüsünden açar (düz `general` listelerde de
  /// tek dokunuşla Alışveriş / Rutin / Şablon / Proje kipine geçiş sağlar).
  Future<void> _openListModePicker() async {
    final note = _note;
    if (note == null || _readOnly) return;
    final picked = await SmartListModeHeader.pickMode(
      context,
      current: note.listMode,
    );
    if (picked != null && picked != note.listMode && mounted) {
      _setListMode(picked);
    }
  }

  /// Faz 3: Yapıştırılan uzun metin / WhatsApp mesajı / tariften temiz madde
  /// ayıklama alt levhasını açar ve seçilen maddeleri nota ekler.
  Future<void> _openTextExtract({String initialText = ''}) async {
    final note = _note;
    if (note == null || _readOnly) return;
    final learnedGroups = ref.read(quickEntryMemoryProvider).itemGroups;
    final extracted = await showTextExtractSheet(
      context,
      ref,
      initialText: initialText,
      mode: note.listMode,
      learnedGroups: learnedGroups,
      noteLocked: note.locked,
    );
    if (extracted == null || extracted.isEmpty || !mounted) return;
    _mutate(
      (n) => n.copyWith(items: [...n.items, ...extracted]),
      immediate: true,
    );
    if (!note.locked) {
      final memKind = note.listMode == ListMode.shopping
          ? 'smart:market'
          : 'mode:${note.listMode.name}';
      ref.read(quickEntryMemoryProvider.notifier).record(
        memKind,
        [for (final i in extracted) i.text],
        at: DateTime.now(),
      );
    }
  }

  /// Faz 3: Proje kipinde tek bir görevi kota kontrollü AI (veya çevrimdışı
  /// 0-kredi yerel yedek) ile 3–5 alt adıma böler; onaylanan alt adımlar
  /// `extras['parentId']` ile doğrudan ana görevin altına eklenir.
  Future<void> _breakdownProjectItem(NoteItem parent) async {
    final note = _note;
    if (note == null || _readOnly || note.locked) return;
    final l10n = context.l10n;
    final res = await ref
        .read(listAiServiceProvider)
        .breakdownTask(
          parent.text,
          locale: l10n.localeName,
          listTitle: note.title,
          noteLocked: note.locked,
        );
    if (!mounted) return;
    if (res.quotaReached) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showMessage(l10n.listAiQuotaReached);
    }
    final chosen = await showTaskBreakdownSheet(
      context,
      parentTaskText: parent.text,
      initialSteps: res.items,
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    const uuid = Uuid();
    final subItems = [
      for (final step in chosen)
        NoteItem(
          id: uuid.v4(),
          text: step,
          extras: {'parentId': parent.id},
        ),
    ];
    _mutate((n) {
      final idx = n.items.indexWhere((i) => i.id == parent.id);
      if (idx < 0) {
        return n.copyWith(items: [...n.items, ...subItems]);
      }
      final next = [...n.items]..insertAll(idx + 1, subItems);
      return n.copyWith(items: next);
    }, immediate: true);
  }

  /// Kural 1: Geçici hayalet öneriye dokunulduğunda gerçek kalıcı [NoteItem]
  /// oluşturup nota ekler.
  void _acceptGhostSuggestion(GhostSuggestion suggestion) {
    final item = suggestion.toNoteItem(const Uuid().v4());
    _addParsedItem(item);
  }

  /// Kural 1: Hayalet öneriyi 24 saatliğine gizler (yalnız SharedPreferences).
  Future<void> _dismissGhostSuggestion(GhostSuggestion suggestion) async {
    await GhostSuggestionEngine.dismiss(
      ref.read(sharedPreferencesProvider),
      suggestion.id,
    );
    if (!mounted) return;
    _ghostDismissedN.value = {..._ghostDismissedN.value, suggestion.id};
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
}
