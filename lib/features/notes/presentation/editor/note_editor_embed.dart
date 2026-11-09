part of 'note_editor_screen.dart';

/// Ek etiketleri, gömme ve not bağlantıları (F18.23'te note_editor_attachments.dart'tan taşındı).
extension _EditorEmbed on _NoteEditorScreenState {
  /// Gövdede dokunulan NOT BAĞLANTISI etiketinin hedefi (F18.16).
  String? _tappedNoteLink(EditableTextState? editable) {
    final note = _note;
    final selection = _bodyController.selection;
    if (note == null || !selection.isValid || !selection.isCollapsed) {
      return null;
    }
    final tag = tappedAttachmentTag(
      logicalText: _bodyController.logicalText,
      logicalCaret: wrapToLogicalOffset(
        _bodyController.text,
        selection.baseOffset,
      ),
      displayText: _bodyField.text,
      selection: selection,
      names: _bodyController.attachmentNames,
      editable: editable,
      tapGlobal: _bodyTapPoint.last,
    );
    return tag == null ? null : noteLinkTarget(note, tag.fileName);
  }

  /// Metne gömülü ek etiketini AÇAR.
  ///
  /// [editing] false ise ÖNİZLEME: görsel/belge salt okunur açılır (çizim,
  /// kırpma, döndürme düğmeleri çizilmez). true ise DÜZENLEME: aynı ekranlar
  /// düzenleme geri çağrılarıyla açılır. Kullanıcının istediği ayrım tam
  /// olarak bu — "tıklayınca önizlemesi açılır, bir butonla da düzenleme".
  /// Ekin nottaki GÜNCEL hâli (çağıranın elindeki kopya eski olabilir:
  /// sayfa çevrildikçe `pdfPage` yazılır).
  Attachment _currentAttachment(Attachment a) {
    for (final x in _note?.attachments ?? const <Attachment>[]) {
      if (x.id == a.id) return x;
    }
    return a;
  }

  void _openAttachmentTag(Attachment attachment, {required bool editing}) {
    if (attachment.isUnsupported) {
      showUnsupportedAttachmentDialog(context);
      return;
    }
    // NOT PAKETİ: önizlemede okunur/yazılır/çizilir (2026-11-08).
    if (isNotePackage(attachment)) {
      _openPackage(attachment);
      return;
    }
    // Metin eki (transkript) dosyasız: okuma ekranında açılır.
    if (attachment.kind == AttachmentKind.text) {
      unawaited(_openTranscript(attachment));
      return;
    }
    // Drive'daki ek bu cihaza henüz inmediyse ŞİMDİ indirilir, sonra açılır
    // (bkz. drive_ui.dart — arka plan kuyruğunu beklemesin).
    if (!localFileExists(attachment.localPath) &&
        attachment.isInDrive &&
        !attachment.isUploaded) {
      if (kIsWeb) {
        // Web: Drive'dan belleğe (F4.4) — `blob:` adresiyle yeniden açılır.
        resolveWebDriveAttachment(context, ref, attachment).then((resolved) {
          if (resolved != null && mounted) {
            _openAttachmentTag(resolved, editing: editing);
          }
        });
        return;
      }
      fetchAttachmentNow(context, ref, attachment).then((ok) {
        if (ok && mounted) _openAttachmentTag(attachment, editing: editing);
      });
      return;
    }
    if (!localFileExists(attachment.localPath) &&
        !attachment.isUploaded &&
        !attachment.isWebVideo) {
      _showSnack(context.l10n.attachmentNotSynced);
      return;
    }
    if (attachment.kind == AttachmentKind.image) {
      openImageViewer(
        context,
        attachment,
        editing ? _updateAttachment : (_) {},
        onCrop: editing ? _cropImage : null,
        onRotate: editing ? _rotateImage : null,
        // Nottaki BÜTÜN görseller (sayfadakiler + şerittekiler) galeri olur:
        // tam ekranda yana kaydırarak hepsinde gezilir.
        gallery: [
          for (final a in (_note?.attachments ?? const <Attachment>[]))
            if (a.kind == AttachmentKind.image) a,
        ],
      );
      return;
    }
    Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => switch (attachment.kind) {
          // TAM EKRAN KALDIĞI SAYFADAN (kullanıcı bulgusu 2026-11-10, cihazda
          // doğrulandı: sabit PDF 13. sayfadayken ⛶ 1. sayfadan açılıyordu):
          // kutu sayfayı `pdfPage`e yazıyor ama görüntüleyiciye verilmiyordu.
          // Dönüşte tam ekranda gelinen sayfa sabite/kutuya yansır.
          AttachmentKind.pdf => PdfViewerScreen(
            attachment: attachment,
            initialPage: _currentAttachment(attachment).pdfPage,
            onPageChanged: editing
                ? (page) {
                    final now = _currentAttachment(attachment);
                    if (now.pdfPage != page) {
                      _updateAttachment(now.copyWith(pdfPage: page));
                    }
                  }
                : null,
            onChanged: editing ? _updateAttachment : null,
          ),
          AttachmentKind.slide => SlideViewerScreen(
            attachment: attachment,
            onChanged: editing ? _updateAttachment : null,
          ),
          AttachmentKind.video => VideoViewerScreen(attachment: attachment),
          // Ses ekinin görüntüleyicisi yok; şeritteki oynatıcıdan çalınır.
          // Metin eki yukarıda kendi ekranına gider; dal yalnız bütünlük için.
          AttachmentKind.audio ||
          AttachmentKind.text ||
          AttachmentKind.unknown => ImageViewerScreen(attachment: attachment),
          AttachmentKind.image => ImageViewerScreen(attachment: attachment),
        },
      ),
    );
  }

  /// Ada göre eki bulup ÖNİZLEMEDE açar (madde satırından gelen dokunuş).
  /// Ad hem bağ etiketi hem dosya adı olabilir — çözüm [_NoteEditorScreenState._attachmentForTag]'te.
  void _openTagByName(String name) {
    final note = _note;
    if (note == null) return;
    final linked = noteLinkTarget(note, name);
    if (linked != null) {
      _openLinkedNote(linked, editing: false);
      return;
    }
    final attachment = _NoteEditorScreenState._attachmentForTag(note, name);
    if (attachment != null) _showEmbedPreviewFor(attachment, name);
  }

  /// "+ Ekle" levhasından gelen gömme akışı.
  ///
  /// Seçim VARSA seçici o yazı için açılır ve sonuç doğrudan ona gömülür.
  /// Seçim yoksa önce NE gömüleceği seçilir, sonra bağlama kipine geçilir
  /// (kullanıcı yazıyı sonra seçer — istenen "ters" yön).
  Future<void> _embedAttachmentFlow() async {
    final note = _note;
    if (note == null) return;
    // Levha açılırken alınan anlık görüntü: klavye kapanınca seçim daralmış
    // olabilir (bkz. [_showAttachMenu]).
    final snapshot = _selectionSnapshot;
    final logical = _bodyController.logicalText;
    if (snapshot != null && snapshot.isValid && !snapshot.isCollapsed) {
      final start = wrapToLogicalOffset(
        _bodyController.text,
        snapshot.start,
      ).clamp(0, logical.length);
      final end = wrapToLogicalOffset(
        _bodyController.text,
        snapshot.end,
      ).clamp(start, logical.length);
      final range = trimmedRange(logical, start, end);
      if (range != null) {
        await _embedRange(range.start, range.end);
        return;
      }
    }
    final chosen = await _pickEmbedTarget(label: '');
    if (chosen == null || !mounted) return;
    _startPendingEmbed(chosen);
  }

  /// Gömme seçicisi + gerekiyorsa YENİ eki oluşturma. Yeni ek şeride girer
  /// (gömülü dosya sayfayı kalabalıklaştırmasın); seçilen/oluşan eki döner.
  Future<Attachment?> _pickEmbedTarget({required String label}) async {
    final note = _note;
    if (note == null) return null;
    final pick = await showEmbedPicker(
      context,
      label: label,
      attachments: note.attachments,
    );
    if (pick == null || !mounted) return null;
    if (pick.attachment != null) return pick.attachment;
    switch (pick.create) {
      case 'pdf':
        const group = XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
          mimeTypes: ['application/pdf'],
        );
        final files = await DocPicker.pickMany(
          group,
          chooserTitle: context.l10n.pickPdfTitle,
        );
        if (files.isEmpty || !mounted) return null;
        return _addPdfFile(files.first, asFile: true);
      case 'image':
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 2400,
          maxHeight: 2400,
        );
        if (file == null || !mounted) return null;
        return _addImageBytes(
          await file.readAsBytes(),
          file.name,
          asFile: true,
        );
      case 'video':
        return _addVideoFromGallery(asFile: true);
      case 'youtube':
        return _addYouTube(asFile: true);
    }
    return null;
  }

  /// Gövdedeki [start]–[end] aralığına (mantıksal metin) gömer: önce seçici.
  Future<void> _embedRange(int start, int end) async {
    final logical = _bodyController.logicalText;
    final range = trimmedRange(logical, start, end);
    if (range == null) return;
    final label = logical.substring(range.start, range.end);
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    // Seçici açıkken metin değişmiş olabilir (dikte, eşitleme): aralık hâlâ
    // AYNI yazıyı gösteriyorsa gömülür, yoksa imlece dosya adıyla.
    final now = _bodyController.logicalText;
    if (range.end <= now.length &&
        now.substring(range.start, range.end) == label) {
      _applyEmbed(
        label: label,
        attachment: chosen,
        start: range.start,
        end: range.end,
      );
    } else {
      _insertTagAtCaret(chosen);
    }
  }

  /// Gömülü yazıya dokununca: YERİNDE önizleme kartı (tam ekrana atlamaz).
  void _showEmbedPreviewFor(Attachment attachment, String label) {
    _dismissKeyboard();
    final editable =
        attachment.kind == AttachmentKind.pdf ||
        attachment.kind == AttachmentKind.image;
    showEmbedPreview(
      context,
      attachment: attachment,
      label: label,
      onOpen: () => _openAttachmentTag(attachment, editing: false),
      onEdit: editable
          ? () => _openAttachmentTag(attachment, editing: true)
          : null,
      onChanged: _updateAttachment,
      onCopy: () => unawaited(_copyAttachment(attachment)),
      onShare: () => unawaited(shareAttachment(context, ref, attachment)),
      onReplace: () => unawaited(_replaceEmbed(label)),
      onUnlink: () => _unlinkEmbed(label),
      viewSwitch: _embedViewSwitch(attachment),
    );
  }

  /// Önizlemedeki görünüm anahtarı: seçince levha kapanır, ek yeni yerine geçer
  /// (bağ durur; çözmek ayrı iş, "Gömmeyi kaldır").
  Widget? _embedViewSwitch(Attachment attachment) {
    final note = _note;
    if (note == null || _readOnly) return null;
    final available = availableViews(attachment);
    if (available.length < 2) return null;
    return AttachmentViewSwitch(
      current: _viewOf(note, attachment),
      available: available,
      onChanged: (view) {
        Navigator.pop(context);
        unawaited(_setAttachmentView(attachment, view));
      },
    );
  }

  /// Gömülü yazının bağladığı eki DEĞİŞTİRİR (yazı aynı kalır).
  Future<void> _replaceEmbed(String label) async {
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    _mutate(
      (n) => n.copyWith(
        tagLinks: [
          for (final l in n.tagLinks)
            if (l.label != label) l,
          NoteTagLink(label: label, attachmentId: chosen.id),
        ],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.attachmentTagInserted);
  }

  /// GÖMMEYİ KALDIRIR: yazı kalır, ataç ve bağ gider (gövde + maddeler).
  void _unlinkEmbed(String label, {bool announce = true}) {
    final body = removeAttachmentTags(_bodyController.logicalText, label);
    if (body != _bodyController.logicalText) {
      _bodyController.setLogical(body, body.length);
    }
    _mutate(
      (n) => n.copyWith(
        body: body,
        items: [
          for (final i in n.items)
            i.text.contains(attachmentTagFor(label))
                ? i.copyWith(text: removeAttachmentTags(i.text, label))
                : i,
        ],
        tagLinks: [
          for (final l in n.tagLinks)
            if (l.label != label) l,
        ],
      ),
      immediate: true,
    );
    if (announce) _showSnack(context.l10n.embedRemoved);
  }

  /// Seçili aralığı etikete çevirir ve bağı nota yazar.
  ///
  /// [target] verilirse etiket O ALANA yazılır (madde satırı, başlık); alanın
  /// metni nota kendi `commit`'iyle geçer. Verilmezse gövdeye yazılır ve metin
  /// ile bağ TEK yazımda kaydedilir.
  void _applyEmbed({
    required String label,
    Attachment? attachment,
    String? noteId,
    required int start,
    required int end,
    FormatTarget? target,
  }) {
    // Bağın hedefi: ek ya da (F18.16) not — `note:<kimlik>`.
    final linkId = noteId != null ? '$kNoteLinkPrefix$noteId' : attachment!.id;
    final controller = target?.controller ?? _bodyController;
    final logical = controller.logicalText;
    // Aralığın iki ucundaki boşluklar etikete girmez ve YUTULMAZ (bkz.
    // [trimmedRange]); etiketin kendisi de kırpılmış hâlidir.
    final range = trimmedRange(logical, start, end);
    if (range != null) {
      start = range.start;
      end = range.end;
      label = logical.substring(start, end);
    }
    // Yazı ZATEN bir etiketse (yeniden gömme) ikinci ataç eklenmez, yalnız
    // bağ değişir.
    final alreadyTagged =
        start >= kAttachmentTagPrefix.length &&
        logical.substring(start - kAttachmentTagPrefix.length, start) ==
            kAttachmentTagPrefix;
    // Metne yalnız ATAÇ eklenir; seçilen yazı olduğu gibi kalır.
    final tagged = alreadyTagged ? label : '$kAttachmentTagPrefix$label';
    final text = logical.replaceRange(start, end, tagged);
    controller.setLogical(text, start + tagged.length);
    // Aynı etiket ikinci kez bağlanırsa eskisi değişir, çoğalmaz.
    List<NoteTagLink> links(Note note) => [
      for (final l in note.tagLinks)
        if (l.label != label) l,
      NoteTagLink(label: label, attachmentId: linkId),
    ];
    if (identical(controller, _bodyController)) {
      _mutate(
        (n) => n.copyWith(body: text, tagLinks: links(n)),
        immediate: true,
      );
    } else {
      // Alanın kendi kaydı önce koşar (madde metnini nota yazan tek yol o),
      // bağ ondan sonra eklenir.
      target!.commit();
      _mutate((n) => n.copyWith(tagLinks: links(n)), immediate: true);
    }
    // GÖMÜLEN EK EKRANDAN KALKAR (kullanıcı isteği 2026-11-02): artık yazıdan
    // açılıyor; sayfada ya da sabit bölmede ikinci kez yer kaplamasın.
    if (attachment != null && !(_note?.type.isPageNoteType ?? true)) {
      unawaited(_setAttachmentView(attachment, AttachmentView.attached));
    }
    _showSnack(
      noteId != null
          ? context.l10n.noteLinkInserted
          : context.l10n.attachmentTagInserted,
    );
  }

  /// SEÇİLİ YAZIYI BİR NOTA BAĞLA (F18.16). Seçim yoksa imlece hedefin
  /// başlığı etiket olarak yazılır.
  Future<void> _linkToNote(
    WrapTextController controller, {
    FormatTarget? target,
  }) async {
    final note = _note;
    if (note == null) return;
    final selection = controller.selection;
    final logical = controller.logicalText;
    final start = selection.isValid
        ? wrapToLogicalOffset(
            controller.text,
            selection.start,
          ).clamp(0, logical.length)
        : logical.length;
    final end = selection.isValid
        ? wrapToLogicalOffset(
            controller.text,
            selection.end,
          ).clamp(start, logical.length)
        : start;
    final picked = await showNotePicker(
      context,
      notes: ref.read(notesStreamProvider).value ?? const <Note>[],
      excludeId: note.id,
    );
    if (picked == null || !mounted) return;
    final now = controller.logicalText;
    if (end > start &&
        end <= now.length &&
        now.substring(start, end) == logical.substring(start, end)) {
      _applyEmbed(
        label: logical.substring(start, end),
        noteId: picked.id,
        start: start,
        end: end,
        target: target,
      );
      return;
    }
    // Seçim yok: başlık imlece yazılır, sonra etikete çevrilir.
    final title = noteLinkLabel(picked, context.l10n.remindersUntitled);
    final at = start.clamp(0, now.length);
    final needsSpace = at > 0 && !RegExp(r'\s').hasMatch(now[at - 1]);
    final inserted = '${needsSpace ? ' ' : ''}$title';
    controller.setLogical(
      now.replaceRange(at, at, inserted),
      at + inserted.length,
    );
    if (target != null) target.commit();
    _applyEmbed(
      label: title,
      noteId: picked.id,
      start: at + inserted.length - title.length,
      end: at + inserted.length,
      target: target,
    );
  }

  /// Öneriden bağlantı (F18.17): hedefin başlığı gövdenin SONUNA etiket
  /// olarak eklenir.
  void _linkNoteAtEnd(Note target) {
    final title = noteLinkLabel(target, context.l10n.remindersUntitled);
    final now = _bodyController.logicalText;
    final prefix = now.trim().isEmpty ? '' : (now.endsWith('\n') ? '' : '\n');
    final text = '$now$prefix$title';
    _bodyController.setLogical(text, text.length);
    _applyEmbed(
      label: title,
      noteId: target.id,
      start: text.length - title.length,
      end: text.length,
    );
  }

  /// Gövdeye TEK karakter eklenip imlecin solu `[[` olduysa not seçici açılır.
  void _maybeLinkTrigger(String before, String after) {
    if (_readOnly || after.length != before.length + 1) return;
    final sel = _bodyController.selection;
    if (!sel.isValid || !sel.isCollapsed) return;
    final caret = wrapToLogicalOffset(
      _bodyController.text,
      sel.baseOffset,
    ).clamp(0, after.length);
    if (caret < 2 || after.substring(caret - 2, caret) != '[[') return;
    final text = after.replaceRange(caret - 2, caret, '');
    _bodyController.setLogical(text, caret - 2);
    _mutate((n) => n.copyWith(body: text));
    unawaited(_linkToNote(_bodyController));
  }

  /// Bağlı notu açar (okurken doğrudan, yazarken "Aç" önerisiyle).
  void _openLinkedNote(String noteId, {required bool editing}) {
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    final target = notes.where((n) => n.id == noteId).firstOrNull;
    if (target == null) {
      _showSnack(context.l10n.noteLinkMissing);
      return;
    }
    void open() => openNoteRoute(context, target);
    if (!editing) {
      open();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(
        noteLinkLabel(target, context.l10n.remindersUntitled),
        action: SnackBarAction(label: context.l10n.openLink, onPressed: open),
      );
  }

  void _rememberTargetSelection() {
    final target = _formatTarget;
    if (target == null) return;
    final selection = target.controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      _lastSelection = selection;
      _lastSelectionTarget = target;
    }
  }

  /// Bağlama kipini başlatır (ek seçildi, yazı bekleniyor).
  void _startPendingEmbed(Attachment attachment) {
    _update(() => _pendingEmbed = attachment);
    // ELLE DAİRE EN BAŞTAN AÇIK (kullanıcı isteği 2026-11-02): ipucu örtünün
    // şeridinde; ✕ ile metin seçerek bağlamaya dönülür.
    _setGestureMode(_GestureMode.embedLasso);
  }

  /// Bağlama kipini o anki SEÇİMLE bitirir.
  ///
  /// Seçim üç kaynaktan sırayla aranır ve hiçbiri tutmazsa BİLE bir sonuç
  /// üretilir (bkz. [_lastSelection] — "basıyorum hiçbir şey olmuyor" kök
  /// nedeni):
  /// 1. **Etkin alanın canlı seçimi** — şerit [TextFieldTapRegion] içinde
  ///    olduğu için dokunmak odağı düşürmez, seçim çoğu zaman burada durur.
  /// 2. **Hatırlanan son dolu seçim** — odak yine de düştüyse (donanım
  ///    klavyesi, sistem geri jesti, alanın yeniden kurulması) yedek devreye
  ///    girer; hangi alandan geldiği de saklandığı için madde satırları da
  ///    çalışır.
  /// 3. **İmleç** — seçim yoksa etiket imlecin yerine dosya adıyla yazılır.
  ///
  /// Her üç yolda da kip KAPANIR: şeritte asılı kalan bir "bağla" yazısı,
  /// kullanıcının gördüğü asıl hataydı.
  ///
  /// [forcedTarget]/[forcedSelection]: daire içine alma (jest) seçimi —
  /// canlı seçimden önce gelir.
  void _finishPendingEmbed({
    FormatTarget? forcedTarget,
    TextSelection? forcedSelection,
  }) {
    final attachment = _pendingEmbed;
    if (attachment == null) return;
    var target = forcedTarget ?? _formatTarget;
    var selection = forcedSelection ?? target?.controller.selection;
    final liveIsUsable =
        selection != null && selection.isValid && !selection.isCollapsed;
    if (!liveIsUsable) {
      target = _lastSelectionTarget;
      selection = _lastSelection;
    }
    final controller = target?.controller;
    var label = '';
    var start = 0;
    var end = 0;
    if (controller != null &&
        selection != null &&
        selection.isValid &&
        !selection.isCollapsed) {
      final logical = controller.logicalText;
      start = wrapToLogicalOffset(
        controller.text,
        selection.start,
      ).clamp(0, logical.length);
      end = wrapToLogicalOffset(
        controller.text,
        selection.end,
      ).clamp(start, logical.length);
      label = logical.substring(start, end).trim();
    }
    _update(() => _pendingEmbed = null);
    // Bağlandı: yedek seçim tüketildi, ikinci bir "Buraya bağla" aynı yazıyı
    // yeniden bağlamasın.
    _lastSelection = null;
    _lastSelectionTarget = null;
    if (label.isEmpty) {
      _insertTagAtCaret(attachment);
      return;
    }
    _applyEmbed(
      label: label,
      attachment: attachment,
      start: start,
      end: end,
      target: target,
    );
  }

  /// Seçim bulunamadığında bağlama kipinin ÇIKIŞI: etiket gövdedeki imlecin
  /// yerine (imleç de yoksa metnin sonuna) dosya adıyla yazılır.
  ///
  /// Bu, "Metne ekle"nin ilk günkü davranışı — yani kullanıcının bildiği bir
  /// sonuç. Sessizce hiçbir şey yapmamaktan her koşulda iyidir.
  void _insertTagAtCaret(Attachment attachment) {
    final logical = _bodyController.logicalText;
    final live = _bodyController.selection;
    final caret = live.isValid
        ? wrapToLogicalOffset(
            _bodyController.text,
            live.baseOffset,
          ).clamp(0, logical.length)
        : logical.length;
    _applyEmbed(
      label: attachment.fileName,
      attachment: attachment,
      start: caret,
      end: caret,
    );
  }

  /// SEÇİLİ METNE bir ek gömer (kullanıcı isteği 2026-08-16: "o yazıya PDF
  /// gömülür, o yazının altı çizilir kırmızı vurgulanır, tıklayınca PDF
  /// önizlemede açılır").
  ///
  /// Seçilen kelimenin başına ataç konur ve metnin kendisi etiket olur;
  /// hangi eke gittiği nota [Note.tagLinks] olarak yazılır. Metne gizli
  /// kimlik GÖMÜLMEZ — gerekçesi orada.
  ///
  /// [target] verilirse seçim O ALANDA (madde satırı); verilmezse gövdede.
  Future<void> _embedIntoSelection(
    WrapTextController controller, {
    FormatTarget? target,
  }) async {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final logical = controller.logicalText;
    final start = wrapToLogicalOffset(
      controller.text,
      selection.start,
    ).clamp(0, logical.length);
    final end = wrapToLogicalOffset(
      controller.text,
      selection.end,
    ).clamp(start, logical.length);
    if (target == null) {
      await _embedRange(start, end);
      return;
    }
    final range = trimmedRange(logical, start, end);
    if (range == null) return;
    final label = logical.substring(range.start, range.end);
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    // Seçici açıkken satırın metni değiştiyse (silindi, eşitlendi) gömülmez.
    final now = controller.logicalText;
    if (range.end <= now.length &&
        now.substring(range.start, range.end) == label) {
      _applyEmbed(
        label: label,
        attachment: chosen,
        start: range.start,
        end: range.end,
        target: target,
      );
    }
  }
}
