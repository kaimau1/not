part of 'note_editor_screen.dart';

/// Sayfalar, görünüm kipleri (Sabit/Yüzen/Balonlu), sabit medya bölmesi ve video sarma.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorMediaView on _NoteEditorScreenState {
  // ── NOTUN SAYFALARI (bkz. Note.textPages / note_pages.dart) ───────────

  /// Sayfa geçişi notun İÇERİĞİNİ değiştirir: metin alanının denetleyicisi
  /// nottan beslenmediği için (geri al ile aynı) elle yazılır. Geri al
  /// yığınına GİRER: silinen sayfa "Geri al" ile döner; geri alınan anlık
  /// görüntü sayfa bilgisini de taşıdığı için içerik hep tutarlı kalır.
  void _applyPageChange(Note next) {
    _bodyController.text = next.body;
    _mutate((_) => next, immediate: true);
    // Yeni sayfa tepeden başlar.
    if (_pageScroll.hasClients) _pageScroll.jumpTo(0);
  }

  /// Etkin sayfanın arkasına boş sayfa ekler ve ona geçer (kullanıcı isteği
  /// 2026-10-11: "bir nota yeni sayfa ekleme").
  void _addPage() {
    final note = _note;
    if (note == null || note.type.isPageNoteType) return;
    _dismissKeyboard();
    _applyPageChange(addTextPage(note, const Uuid().v4()));
    final pos = textPagePosition(_note!);
    _showSnack(context.l10n.pageAdded(pos.index + 1));
  }

  void _goToPage(String id) {
    final note = _note;
    if (note == null || id == note.activePage) return;
    _dismissKeyboard();
    _applyPageChange(switchTextPage(note, id));
  }

  /// Komşu sayfaya geçer ([delta] -1 / +1).
  void _stepPage(int delta) {
    final note = _note;
    if (note == null) return;
    final pages = resolvedTextPages(note);
    final i = textPagePosition(note).index + delta;
    if (i < 0 || i >= pages.length) return;
    _goToPage(pages[i].id);
  }

  /// Yana çekiş (bkz. [PageSwipeDetector]): komşu sayfaya geçer; uçta
  /// hafif titreşimle "son sayfa" der.
  void _swipePage(int delta) {
    final note = _note;
    if (note == null) return;
    final pos = textPagePosition(note);
    final next = pos.index + delta;
    if (next < 0 || next >= pos.count) {
      unawaited(HapticFeedback.lightImpact());
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    _stepPage(delta);
  }

  /// Maddeyi başka sayfaya taşır (madde menüsü → "Başka sayfaya taşı").
  Future<void> _moveItemToPage(NoteItem item) async {
    final note = _note;
    if (note == null) return;
    final l10n = context.l10n;
    final pages = resolvedTextPages(note);
    final target = await showAppSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.itemMoveToPage,
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
            ),
            for (final (i, page) in pages.indexed)
              if (page.id != note.activePage)
                ListTile(
                  key: ValueKey('move-to-page-${page.id}'),
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.pageOf(i + 1, pages.length)),
                  subtitle: Text(
                    _pagePreview(page),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(sheetContext, page.id),
                ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    final current = _note;
    if (current == null) return;
    _mutate((n) => moveItemToPage(n, item.id, target), immediate: true);
    final index = pages.indexWhere((p) => p.id == target);
    _showSnack(l10n.itemMovedToPage(index + 1));
  }

  /// Sayfa seçicide sayfanın ilk satırı (boşsa ilk madde).
  String _pagePreview(ResolvedTextPage page) {
    final body = stripRichMarkers(page.body).trim();
    if (body.isNotEmpty) return body.split('\n').first;
    final item = page.items.where((i) => i.text.trim().isNotEmpty).firstOrNull;
    return item == null ? '' : stripRichMarkers(item.text).trim();
  }

  /// Etkin sayfayı siler (onaylı). Görselleri komşu sayfaya taşınır; yazı
  /// "Geri al" ile döner.
  Future<void> _deleteActivePage() async {
    final note = _note;
    if (note == null || note.textPages.length < 2) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.archiveDeletePage),
        content: Text(l10n.deletePageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.archiveDeletePage),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final current = _note;
    if (current == null) return;
    _applyPageChange(deleteTextPage(current, current.activePage));
  }

  /// Başlığın altındaki SAYFA ÇUBUĞU: ‹ Sayfa 2 / 3 › · yeni sayfa · ⋮.
  /// Yalnız sayfalı notta görünür (tek sayfalı notta yer kaplamaz).
  Widget _pageBar(Note note) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pos = textPagePosition(note);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _NoteEditorScreenState._kGutter - 8,
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('page-prev'),
            tooltip: l10n.archivePrevPage,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left),
            onPressed: pos.index > 0 ? () => _stepPage(-1) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.pageOf(pos.index + 1, pos.count),
              key: const ValueKey('page-label'),
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('page-next'),
            tooltip: l10n.archiveNextPage,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right),
            onPressed: pos.index < pos.count - 1 ? () => _stepPage(1) : null,
          ),
          const Spacer(),
          IconButton(
            tooltip: l10n.archiveNewPage,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.note_add_outlined),
            onPressed: _addPage,
          ),
          IconButton(
            tooltip: l10n.archiveDeletePage,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _deleteActivePage,
          ),
        ],
      ),
    );
  }

  void _toggleDocumentView() {
    final note = _note;
    if (note == null) return;
    if (note.type.isPageNoteType) {
      _switchToClassic();
    } else {
      _switchToBubbles();
    }
  }

  /// KLASİK → BALONLU: belge notun kendisi olur (üstte sayfa, altta sayfa
  /// notu; üzerine balon/vurgu/kalem). [document] verilmezse ilk belge.
  void _switchToBubbles([Attachment? document]) {
    final note = _note;
    if (note == null || note.type.isPageNoteType || _readOnly) return;
    final doc = document ?? _NoteEditorScreenState._switchableDocument(note);
    if (doc == null) return;
    if (_pinHover) _update(() => _pinHover = false);
    _dismissKeyboard();
    final hadText =
        note.body.trim().isNotEmpty ||
        note.items.any((i) => i.text.trim().isNotEmpty);
    // Sabit bölmeden balonluya geçen belge (ya da kaynağı olan görsel)
    // sabitlikten çıkar: balonlu görünümde bölme yok, klasiğe dönünce
    // kendiliğinden yeniden sabitlenmiş görünmesin. Bölme yüksekliği
    // hatırlanır (işaret negatif — bkz. Attachment.pinHeight).
    Attachment released(Attachment a) =>
        (a.id == doc.id || a.id == doc.sourceId) && a.pinHeight > 0
        ? a.copyWith(pinHeight: -a.pinHeight)
        : a;
    _mutate(
      (n) => n.copyWith(
        type: doc.kind == AttachmentKind.slide ? NoteType.slides : NoteType.pdf,
        classicDocument: false,
        // Belge bölmesi türünün İLK ekini gösterir: seçilen belge öne alınır
        // (sıra dışında hiçbir alan değişmez — klasik düzen ekte kalır).
        attachments: [
          for (final a in n.attachments)
            if (a.id == doc.id) released(a),
          for (final a in n.attachments)
            if (a.id != doc.id) released(a),
        ],
      ),
      immediate: true,
    );
    HapticFeedback.mediumImpact();
    final l10n = context.l10n;
    _showSnack(
      hadText
          ? '${l10n.docViewSwitchedBubbles} ${l10n.docViewTextKept}'
          : l10n.docViewSwitchedBubbles,
    );
  }

  /// BALONLU → KLASİK: not yeniden metin notu olur, belge sayfada (ya da
  /// önceden durduğu şeritte) bir ek olarak görünür.
  void _switchToClassic({bool announce = true}) {
    final note = _note;
    if (note == null || !note.type.isPageNoteType || _readOnly) return;
    final kind = note.type == NoteType.slides
        ? AttachmentKind.slide
        : AttachmentKind.pdf;
    final doc = note.attachments.where((a) => a.kind == kind).firstOrNull;
    _dismissKeyboard();
    _mutate((n) {
      final asText = n.copyWith(type: NoteType.text, classicDocument: true);
      return asText.copyWith(
        attachments: [
          for (final a in n.attachments)
            // Balonlu doğmuş (sayfada hiç yeri olmamış) PDF sayfaya yerleşir;
            // klasikte bir yeri olan belge KENDİ yerine döner — sayfada ya da
            // şeritte (kullanıcı oraya koyduysa) olduğu gibi.
            // Görselden üretilmiş belge (bkz. Attachment.sourceId) sayfaya
            // KONMAZ: klasikte görselin kendisi görünür, belge gizlenir.
            if (doc != null &&
                a.id == doc.id &&
                a.kind == AttachmentKind.pdf &&
                a.sourceId.isEmpty &&
                a.x == null &&
                a.pageY == null)
              _placePdf(a, asText)
            else
              a,
        ],
      );
    }, immediate: true);
    HapticFeedback.mediumImpact();
    if (announce) _showSnack(context.l10n.docViewSwitchedClassic);
  }

  /// Görseli/videoyu notun üstündeki sabit bölmeye alır. Bölmede TEK medya
  /// olur: önceden sabitlenmiş olan sayfaya geri döner. Daha önce
  /// sabitlenmişse bölme ESKİ yüksekliğiyle açılır.
  void _pinMediaTop(Attachment media) {
    if (_pinHover) _update(() => _pinHover = false);
    // PDF de GERÇEKTEN sabitlenir (kullanıcı bulgusu 2026-10-16: "PDF'lerde
    // üste sabitleme yapamıyorum"). Eskiden PDF'i tepeye sürüklemek balonlu
    // görünüme geçiriyordu; balonlu artık görünüm anahtarının ayrı kipi.
    final height =
        media.rememberedPinHeight ??
        defaultPinnedHeight(media, MediaQuery.sizeOf(context));
    _dismissKeyboard();
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == media.id)
              a.copyWith(pinHeight: height, asFile: false)
            else if (a.pinHeight > 0)
              a.copyWith(pinHeight: -a.pinHeight)
            else
              a,
        ],
      ),
      immediate: true,
    );
    HapticFeedback.mediumImpact();
  }

  /// Sabit medyayı sayfaya geri koyar: sayfadaki ESKİ yeri ve genişliği
  /// sabitlerken silinmediği için olduğu gibi döner; bölme yüksekliği de bir
  /// sonraki sabitleme için saklanır (işaret negatife çevrilir).
  void _unpinMedia(Attachment media) {
    final current = _note?.attachments.where((a) => a.id == media.id);
    final latest = current == null || current.isEmpty ? media : current.first;
    if (latest.pinHeight <= 0) return;
    _updateAttachment(latest.copyWith(pinHeight: -latest.pinHeight));
  }

  /// Ek üstteki sabit bölmede mi çiziliyor (o zaman şeritte gösterilmez).
  /// Belge notunda bölme yok — sabitli ek orada şeritte görünmeye devam eder.
  /// İki cihazda aynı anda sabitlenmiş (çakışan) ikinci medya bölmede
  /// gösterilmez; o da şeritte kalır, kaybolmaz.
  bool _inPinnedPane(Note note, Attachment a) =>
      a.isPinnedTop &&
      !note.type.isPageNoteType &&
      note.attachments.firstWhere((x) => x.isPinnedTop).id == a.id;

  void _setPinHover(bool value) {
    if (_pinHover != value && mounted) _update(() => _pinHover = value);
  }

  void _setPinDrag(bool value) {
    if (_pinDrag != value && mounted) _update(() => _pinDrag = value);
  }

  // ── GÖRÜNÜM: SABİT / YÜZEN / BALONLU ──────────────────────────────────
  //
  // Kullanıcı isteği 2026-10-16: "sabitleme, yüzen ve balonlu arasında
  // kolay geçiş TÜM ekler için olmalı; geçişin yeri ve düzeni iyi değil".
  // Üç kip tek anahtarda (bkz. view_mode_switch.dart) ve anahtar ekin
  // YANINDA: sayfada seçilince araç panelinde, sabit bölmenin çubuğunda,
  // balonlu görünümde sayfa çubuğunda.

  /// [a] şu an hangi görünümde.
  AttachmentView _viewOf(Note note, Attachment a) {
    if (note.type.isPageNoteType) {
      final kind = note.type == NoteType.slides
          ? AttachmentKind.slide
          : AttachmentKind.pdf;
      final doc = note.attachments.where((x) => x.kind == kind).firstOrNull;
      if (doc != null && (doc.id == a.id || doc.sourceId == a.id)) {
        return AttachmentView.bubbles;
      }
    }
    if (a.isPinnedTop) return AttachmentView.pinned;
    // Belge notunda (balonlu) her ek şeritte durur; klasikte şeritteki ek
    // "Ek" kipindedir.
    if (note.type.isPageNoteType || a.offPage) {
      return AttachmentView.attached;
    }
    return AttachmentView.floating;
  }

  /// [a]'nın görünüm anahtarı; salt okunurda ya da tek seçenekte null.
  Widget? _viewSwitchFor(Note note, Attachment a, {bool dense = false}) {
    if (_readOnly) return null;
    final available = availableViews(a);
    if (available.length < 2) return null;
    return AttachmentViewSwitch(
      current: _viewOf(note, a),
      available: available,
      dense: dense,
      onChanged: (view) => unawaited(_setAttachmentView(a, view)),
    );
  }

  /// Anahtardan gelen geçiş.
  Future<void> _setAttachmentView(Attachment a, AttachmentView view) async {
    final note = _note;
    if (note == null || _readOnly) return;
    if (_viewOf(note, a) == view) return;
    switch (view) {
      case AttachmentView.attached:
        // → ALT ŞERİT: balonluysa önce klasik; sabitse bölmeden iner;
        // sayfadaysa şeride taşınır (yeri/boyu hatırlanır).
        var target = a;
        if (note.type.isPageNoteType) {
          if (a.sourceId.isNotEmpty) {
            target =
                note.attachments.where((x) => x.id == a.sourceId).firstOrNull ??
                a;
          }
          _switchToClassic(announce: false);
        }
        final latest =
            _note?.attachments.where((x) => x.id == target.id).firstOrNull ??
            target;
        var next = latest.pinHeight > 0
            ? latest.copyWith(pinHeight: -latest.pinHeight)
            : latest;
        if (!next.offPage) next = next.placedOnPage(false);
        if (!identical(next, latest)) {
          _updateAttachment(next);
          unawaited(HapticFeedback.selectionClick());
        }
        // Şerit kapalıysa açılır: ek nereye gitti diye aranmasın.
        if (!ref.read(attachmentsExpandedProvider)) {
          ref.read(attachmentsExpandedProvider.notifier).toggle();
        }
      case AttachmentView.bubbles:
        if (a.kind == AttachmentKind.image) {
          await _imageToBubbles(a);
        } else if (a.kind == AttachmentKind.text) {
          await _textToBubbles(a);
        } else if (a.kind == AttachmentKind.pdf ||
            a.kind == AttachmentKind.slide) {
          _switchToBubbles(a);
        }
      case AttachmentView.floating:
        if (note.type.isPageNoteType) {
          // Balonlu → yüzen: not klasiğe döner. Görselden üretilmiş belgede
          // görselin kendisi sayfasına döner (belge gizlenir).
          _switchToClassic(announce: false);
          final source = a.sourceId.isEmpty
              ? null
              : _note?.attachments.where((x) => x.id == a.sourceId).firstOrNull;
          _floatOnPage(source ?? a);
          _showSnack(context.l10n.viewModeSwitchedFloating);
          return;
        }
        _floatOnPage(a);
      case AttachmentView.pinned:
        var target = a;
        if (note.type.isPageNoteType) {
          // Balonlu → sabit: önce klasik, sonra sabit bölme. Görselden
          // üretilmiş belgede sabitlenen GÖRSELİN kendisi.
          if (a.sourceId.isNotEmpty) {
            target =
                note.attachments.where((x) => x.id == a.sourceId).firstOrNull ??
                a;
          }
          _switchToClassic(announce: false);
        }
        final latest =
            _note?.attachments.where((x) => x.id == target.id).firstOrNull ??
            target;
        _pinMediaTop(latest);
    }
  }

  /// Eki SAYFAYA (yüzen) alır: sabitse bölmeden iner, şeritteyse sayfaya
  /// konur. Sayfada önceden bir yeri varsa oraya döner.
  void _floatOnPage(Attachment a) {
    final note = _note;
    if (note == null) return;
    final latest = note.attachments.where((x) => x.id == a.id).firstOrNull ?? a;
    var next = latest.pinHeight > 0
        ? latest.copyWith(pinHeight: -latest.pinHeight)
        : latest;
    if (next.offPage) {
      final moved = next.placedOnPage(true);
      next = moved.x != null || moved.pageY != null
          ? moved
          : _placeNewImage(moved, note);
    }
    if (identical(next, latest)) return;
    _updateAttachment(next);
    HapticFeedback.selectionClick();
  }

  /// GÖRSEL → BALONLU: görsel tek sayfalık bir belgeye çevrilir (yakalama
  /// levhasındaki "balonlu" kipin yolu — bkz. `ScanPdf`), üstündeki çizim
  /// ve balonlar belgeye taşınır. Belge görsele bağlıdır
  /// ([Attachment.sourceId]): klasiğe dönünce gizlenir, yeniden balonluya
  /// alınınca AYNI belge (balonlarıyla) geri gelir.
  Future<void> _imageToBubbles(Attachment image) async {
    final note = _note;
    if (note == null) return;
    final existing = note.attachments
        .where((a) => a.kind == AttachmentKind.pdf && a.sourceId == image.id)
        .firstOrNull;
    if (existing != null) {
      _switchToBubbles(existing);
      return;
    }
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    _showSnack(l10n.imageNotePreparing);
    File? temp;
    try {
      var path = image.localPath;
      if (!localFileExists(path)) {
        final bytes = await repo.readBytes(image);
        if (bytes == null) {
          if (mounted) _showSnack(l10n.attachmentNotSynced);
          return;
        }
        final dir = await getTemporaryDirectory();
        temp = File(
          '${dir.path}${Platform.pathSeparator}balon_'
          '${DateTime.now().microsecondsSinceEpoch}.img',
        );
        await temp.writeAsBytes(bytes);
        path = temp.path;
      }
      final pdfBytes = await ScanPdf.build([path]);
      if (!mounted) return;
      final dot = image.fileName.lastIndexOf('.');
      final base = dot > 0 ? image.fileName.substring(0, dot) : image.fileName;
      final pdf = await repo.preparePdf(
        noteId: widget.noteId,
        bytes: pdfBytes,
        fileName: '${base.isEmpty ? 'gorsel' : base}.pdf',
      );
      if (!mounted) return;
      final w = image.width ?? 0;
      final h = image.height ?? 0;
      final frame = ScanPdf.imageFrameOnPage(w, h);
      final hasFrame = w > 0 && h > 0;
      final derived = pdf.copyWith(
        sourceId: image.id,
        ink: hasFrame ? placeInk(image.ink, frame) : const [],
        bubbles: hasFrame ? placeBubbles(image.bubbles, frame) : const [],
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, derived]),
        immediate: true,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _switchToBubbles(derived);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError(friendlyError(l10n, e)));
    } finally {
      temp?.delete().ignore();
    }
  }

  /// METİN → BALONLU (kullanıcı isteği 2026-10-17: "txt dosyaları da ...
  /// balonlu mod geçişi"): metin ekinden A4 sayfalı bir belge üretilir
  /// (notun PDF dışa aktarımıyla aynı dizgi — Türkçe yazı tipi gömülü) ve
  /// görseldeki gibi kaynağa bağlanır ([Attachment.sourceId]): klasikte
  /// gizlenir, yeniden balonluya alınınca AYNI belge balonlarıyla gelir.
  /// Metin sonradan düzenlendiyse ([Attachment.sourceDigest] tutmuyor) belge
  /// aynı kimlikle YENİDEN dizilir — balonlar ve sayfa notları korunur.
  Future<void> _textToBubbles(Attachment textAttachment) async {
    final note = _note;
    if (note == null) return;
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    final existing = note.attachments
        .where(
          (a) =>
              a.kind == AttachmentKind.pdf && a.sourceId == textAttachment.id,
        )
        .firstOrNull;
    final digest = Attachment.digestOf(textAttachment.text);
    if (existing != null && existing.sourceDigest == digest) {
      _switchToBubbles(existing);
      return;
    }
    _showSnack(l10n.textToBubblesPreparing);
    try {
      final dot = textAttachment.fileName.lastIndexOf('.');
      final base = dot > 0
          ? textAttachment.fileName.substring(0, dot)
          : textAttachment.fileName;
      final pdfBytes = await NotePdf.build(
        title: base,
        content: textAttachment.text,
      );
      if (!mounted) return;
      final Attachment derived;
      if (existing == null) {
        final pdf = await repo.preparePdf(
          noteId: widget.noteId,
          bytes: pdfBytes,
          fileName: '${base.isEmpty ? 'metin' : base}.pdf',
        );
        derived = pdf.copyWith(
          sourceId: textAttachment.id,
          sourceDigest: digest,
        );
      } else {
        final replaced = await repo.replaceDocumentBytes(
          noteId: widget.noteId,
          attachment: existing,
          bytes: pdfBytes,
        );
        derived = replaced.copyWith(sourceDigest: digest);
      }
      if (!mounted) return;
      _mutate(
        (n) => n.copyWith(
          attachments: existing == null
              ? [...n.attachments, derived]
              : [
                  for (final a in n.attachments)
                    if (a.id == existing.id) derived else a,
                ],
        ),
        immediate: true,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _switchToBubbles(derived);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError(friendlyError(l10n, e)));
    }
  }

  /// Sabit bölmedeki videonun "Bu ana not al" düğmesi.
  /// Sabit videonun ⤢ düğmesi: GERÇEK tam ekran, KALDIĞI YERDEN.
  ///
  /// Kullanıcı bulgusu 2026-10-19: "video sabitken tam ekran yapma seçeneği
  /// yok". Düğme oynatıcı ekranını açıyordu ama video baştan başlıyor, ekran
  /// dikey ve çubuklu kalıyordu. Artık küçük oynatıcının konumu okunur, o
  /// durdurulur, tam ekran o andan açılır; kapanınca küçük oynatıcı tam
  /// ekranda kalınan yere sarılır ve oynuyorsa oynamayı sürdürür.
  Future<void> _openPinnedVideoFullscreen(Attachment video) async {
    // Dosyası henüz bu cihazda olmayan video için eski yol (indirme/uyarı).
    if (!video.isWebVideo && !localFileExists(video.localPath)) {
      _openAttachmentTag(video, editing: true);
      return;
    }
    final source = _videoHub.sourceFor(video.id);
    final wasPlaying = source?.isPlaying ?? false;
    final at = await source?.position();
    await source?.pause();
    if (!mounted) return;
    Duration? end;
    await Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => VideoViewerScreen(
          attachment: video,
          start: at,
          fullscreen: true,
          onClose: (position) => end = position,
        ),
      ),
    );
    final back = end;
    // Küçük oynatıcı tam ekran açıkken yeniden kurulmuş olabilir: güncelini al.
    final latest = _videoHub.sourceFor(video.id);
    if (!mounted || latest == null) return;
    if (back != null) await latest.seekTo(back);
    if (wasPlaying) await latest.play();
  }

  Future<void> _noteAtPinned(Attachment video) async {
    final source = _videoHub.sourceFor(video.id);
    if (source == null || !await _videoHub.noteAt(source)) {
      if (mounted) _showSnack(context.l10n.videoTimeUnknown);
    }
  }

  /// Damgaya dokunuldu: video oraya sarılır. Oynatıcısı açık olan video
  /// (son oynatılan, yoksa sabitli olan) önce gelir; hiçbiri açık değilse
  /// sabit/sayfadaki YouTube kutusu o saniyeden başlar, o da yoksa video
  /// tam ekranda o andan açılır.
  void _seekVideoTo(int seconds) {
    final note = _note;
    if (note == null) return;
    final media = [
      for (final a in note.attachments)
        if (a.kind == AttachmentKind.video || a.kind == AttachmentKind.audio) a,
    ];
    if (media.isEmpty) return;
    HapticFeedback.selectionClick();
    final pinned = media.where((a) => _inPinnedPane(note, a)).firstOrNull;
    final source = _videoHub.target(preferId: pinned?.id);
    if (source != null) {
      _videoHub.touch(source);
      unawaited(source.seekTo(Duration(seconds: seconds)));
      return;
    }
    final videos = [
      for (final a in media)
        if (a.kind == AttachmentKind.video) a,
    ];
    // Yalnız ŞERİTTE duran ses var (oynatıcı kartı çizili değil): ses
    // tepeye sabitlenir ve kart kurulunca o saniyeye sarılır — damgaya
    // dokunan dinlemek ister, sesin nerede çalacağını aramasın.
    if (videos.isEmpty) {
      final audio = media.first;
      if (_readOnly || note.type.isPageNoteType) return;
      _pinMediaTop(audio);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pinnedSource = _videoHub.sourceFor(audio.id);
        if (pinnedSource == null) return;
        _videoHub.touch(pinnedSource);
        unawaited(pinnedSource.seekTo(Duration(seconds: seconds)));
      });
      return;
    }
    final pinnedVideo = pinned?.kind == AttachmentKind.video ? pinned : null;
    final inPage =
        pinnedVideo ??
        videos.where((a) => a.isWebVideo && a.floatsOnPage).firstOrNull;
    if (inPage != null && inPage.isWebVideo) {
      _videoHub.requestStart(inPage.id, seconds);
      return;
    }
    final video = pinnedVideo ?? videos.first;
    Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => VideoViewerScreen(
          attachment: video,
          start: Duration(seconds: seconds),
          onNoteAt: _readOnly
              ? null
              : (position) => _noteAtVideoTime(video.id, position),
        ),
      ),
    );
  }

  /// "Bu ana not al": liste notunda (ya da odak bir maddedeyken) damgalı
  /// YENİ MADDE açılır; metinde imlecin satırına (boşsa) ya da altına yeni
  /// satıra damga yazılır. Her iki durumda odak oraya gider, klavye açılır.
  void _noteAtVideoTime(String attachmentId, Duration position) {
    final note = _note;
    if (note == null || _readOnly) return;
    final stamp = formatVideoTimestamp(position);
    HapticFeedback.selectionClick();
    final target = _formatTarget?.controller;
    final itemsState = _itemsEditorKey.currentState;
    final isList =
        note.type == NoteType.checklist || note.type == NoteType.ordered;
    final focusedItem =
        target != null &&
        target != _bodyController &&
        target != _titleController;
    if (itemsState != null && (focusedItem || (isList && !_listBodyOpen))) {
      itemsState.addItemWithText('$stamp ', after: focusedItem ? target : null);
      return;
    }
    final logical = _bodyController.logicalText;
    final selection = _bodyController.selection;
    final caret = selection.isValid
        ? wrapToLogicalOffset(_bodyController.text, selection.extentOffset)
        : -1;
    final result = insertTimestampLine(logical, caret, stamp);
    _bodyController.setLogical(result.text, result.caret);
    _mutate((n) => n.copyWith(body: result.text), immediate: true);
    if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
    _revealCaretSoon();
  }

  /// Gövdede dokunulan damga (saniye); yoksa null.
  int? _tappedTimestamp(EditableTextState? editable) {
    final note = _note;
    if (note == null || !_NoteEditorScreenState._hasVideo(note)) return null;
    return tappedVideoTimestamp(
      displayText: _bodyController.text,
      selection: _bodyController.selection,
      editable: editable,
      tapGlobal: _bodyTapPoint.last,
    );
  }

  /// Gövdeyi (sayfa notu değilse) sabit medya bölmesi ve sürükleme sırasında
  /// tepede beliren "Bırak: üste sabitle" şeridiyle sarar.
  Widget _withPinnedMedia(Note note, Widget body) {
    if (note.type.isPageNoteType) return body;
    final pinned = note.attachments.where((a) => a.isPinnedTop).firstOrNull;
    final content = pinned == null
        ? body
        : PinnedMediaPane(
            media: pinned,
            onHeightChanged: (h) =>
                _updateAttachment(pinned.copyWith(pinHeight: h)),
            // Bölmeden çıkış (ayracı tepeye çekmek, ⋮ → Sayfaya göm) eki
            // SAYFAYA koyar — şeritten sabitlenmiş belge/metin/ses de dahil.
            onUnpin: () =>
                unawaited(_setAttachmentView(pinned, AttachmentView.floating)),
            onOpen: pinned.kind == AttachmentKind.video
                ? () => unawaited(_openPinnedVideoFullscreen(pinned))
                : () => _openAttachmentTag(pinned, editing: true),
            onCopyLink: () => _copyAttachment(pinned),
            onChanged: _updateAttachment,
            viewSwitch: _viewSwitchFor(note, pinned, dense: true),
            onNoteAt:
                (pinned.kind == AttachmentKind.video ||
                        pinned.kind == AttachmentKind.audio) &&
                    !_readOnly
                ? () => _noteAtPinned(pinned)
                : null,
            // Sabit bölmenin ⋮ menüsü (kullanıcı bulgusu 2026-10-16: "video
            // sabitken kaldırmak yok, gömülü hale getirmek gerekiyor").
            onRemove: _readOnly
                ? null
                : () {
                    _removeAttachment(pinned);
                    final l10n = context.l10n;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        timedSnackBar(
                          content: Text(l10n.attachmentRemoved),
                          action: SnackBarAction(
                            label: l10n.undo,
                            onPressed: _undo,
                          ),
                        ),
                      );
                  },
            // PDF'in seçilebilir metni var; transkript ses/video/görselde.
            onTranscribe: Transcripts.canTranscribe(pinned)
                ? () => unawaited(_openTranscript(pinned))
                : null,
            onSaveAs: pinned.isWebVideo
                ? null
                : () => unawaited(AttachmentSaveAs.run(context, ref, pinned)),
            onDetach: _readOnly || pinned.isWebVideo
                ? null
                : () {
                    _unpinMedia(pinned);
                    final latest =
                        _note?.attachments
                            .where((a) => a.id == pinned.id)
                            .firstOrNull ??
                        pinned;
                    _setImageAsFile(latest, true);
                  },
            // Görsel balonlu görünümden sabite alındıysa balonları onun
            // türetilmiş belgesinde (bkz. Attachment.sourceId).
            bubbleDoc: pinned.kind == AttachmentKind.image
                ? note.attachments
                      .where(
                        (a) =>
                            a.sourceId == pinned.id &&
                            a.kind == AttachmentKind.pdf,
                      )
                      .firstOrNull
                : null,
            child: body,
          );
    return Stack(
      children: [
        Positioned.fill(child: content),
        // HEDEF ŞERİT (F13.6, 2026-10-31): taşıma başlayınca tepede SOLUK
        // belirir (jest görünür olsun), parmak bölgeye girince dolar.
        // Taşıma yokken şerit AĞAÇTA YOK: eskiden ekran dışına kaydırılmış
        // hâliyle hep kuruluydu ve ekran okuyucu her açılışta "Bırak: üste
        // sabitle" okuyordu.
        if (_pinDrag || _pinHover)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  final fg = _pinHover ? scheme.onPrimary : scheme.primary;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _pinHover
                          ? scheme.primary
                          : scheme.primaryContainer.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.primary, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vertical_align_top, size: 18, color: fg),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.l10n.pinMediaRelease,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
