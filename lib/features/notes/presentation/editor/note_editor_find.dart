part of 'note_editor_screen.dart';

/// Not içi canlı arama (durum: [NoteFindController]).
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorFind on _NoteEditorScreenState {
  /// Alt çubuktaki büyüteç ve ⋮ → "Notta ara": CANLI arama çubuğunu açar
  /// (kullanıcı isteği 2026-09-26: "sayfada canlı aranmalı, ayrı bir alanda
  /// değil; altta çıksın").
  Future<void> _openNoteSearch() async {
    if (_note == null) return;
    // Bekleyen biçim metne insin: aranan kelime az önce yazıldıysa tampon
    // son hâlini taşısın.
    _flushPending(_bodyController);
    if (!mounted) return;
    _update(() {
      _findOpen = true;
      _formatBarOpen = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_findOpen) return;
      _find.focus.requestFocus();
      if (_find.text.isNotEmpty) _runFind();
    });
  }

  void _closeFind() {
    _find.reset();
    _update(() => _findOpen = false);
  }

  void _queueFindRefresh() {
    if (_findRefreshQueued) return;
    _findRefreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findRefreshQueued = false;
      if (mounted && _findOpen) _runFind(keepIndex: true, reveal: false);
    });
  }

  /// Sayfadaki alanlarda arar (sırayla başlık, gövde, maddeler), vurgular ve
  /// (istenirse) odaktaki eşleşmeye kaydırır. Alanların TAMPONU taranır
  /// (bkz. TextSearchIndex): vurgu ve kaydırma aynı konumlarla çalışır.
  void _runFind({bool keepIndex = false, bool reveal = true}) {
    final l10n = context.l10n;
    final note = _note;
    final items = _itemsEditorKey.currentState?.searchFields() ?? const [];
    _find.search([
      (
        controller: _titleController,
        focus: _titleFocus,
        where: l10n.noteTitleLabel,
        icon: Icons.title,
      ),
      if (note != null && !note.type.isPageNoteType)
        (
          controller: _bodyController,
          focus: _bodyFocus,
          where: l10n.noteBodyLabel,
          icon: Icons.notes_outlined,
        ),
      for (var i = 0; i < items.length; i++)
        (
          controller: items[i].controller,
          focus: items[i].focus,
          where: '${l10n.itemLabel} ${i + 1}',
          icon: Icons.check_box_outlined,
        ),
    ], keepIndex: keepIndex);
    _paintFind();
    if (reveal) _revealFindHit();
  }

  void _paintFind() =>
      _find.paint(dark: Theme.of(context).brightness == Brightness.dark);

  void _stepFind(int delta) {
    if (_find.hits.isEmpty) return;
    _find.step(delta);
    _paintFind();
    _revealFindHit();
  }

  /// Odaktaki eşleşmeyi sayfanın üst üçte birine kaydırır; zaten rahat
  /// görünüyorsa kıpırdatmaz.
  void _revealFindHit() {
    final hit = _find.current;
    if (hit == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fieldContext = hit.focus.context;
      if (fieldContext == null || !fieldContext.mounted) return;
      final editable = _NoteEditorScreenState._findEditable(
        fieldContext.findRenderObject(),
      );
      if (editable == null ||
          !editable.attached ||
          !editable.hasSize ||
          !_pageScroll.hasClients) {
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      final position = _pageScroll.position;
      final viewport = position.context.notificationContext?.findRenderObject();
      if (viewport is! RenderBox ||
          !viewport.hasSize ||
          !_NoteEditorScreenState._isDescendantOf(editable, viewport)) {
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      final length = editable.text?.toPlainText().length ?? 0;
      final start = hit.match.start.clamp(0, length);
      final end = hit.match.end.clamp(start, length);
      final boxes = editable.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      final rect = boxes.isEmpty
          ? editable.getLocalRectForCaret(TextPosition(offset: start))
          : boxes.first.toRect();
      final top = editable.localToGlobal(rect.topLeft, ancestor: viewport).dy;
      final height = viewport.size.height;
      if (top >= height * 0.12 && top + rect.height <= height * 0.8) return;
      final target = (position.pixels + top - height * 0.3).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((target - position.pixels).abs() < 1) return;
      position.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Eşleşmeleri yarım pencerede listeler (bkz. showFindHitsSheet).
  Future<void> _openFindList() async {
    final note = _note;
    if (note == null) return;
    final query = _find.text;
    final views = <FindHitView>[
      for (final h in _find.hits)
        () {
          final s = h.index.snippet(h.match, query.length);
          return (
            where: h.where,
            icon: h.icon,
            lead: s.lead,
            hit: s.hit,
            tail: s.tail,
          );
        }(),
    ];
    _dismissKeyboard();
    final picked = await showFindHitsSheet(
      context,
      hits: views,
      current: _find.index,
      canDeepSearch: true,
    );
    if (picked == null || !mounted) return;
    if (picked == kFindDeepSearch) {
      await showNoteSearchSheet(
        context,
        ref,
        _note ?? note,
        initialQuery: query,
      );
      return;
    }
    if (picked < 0 || picked >= _find.hits.length) return;
    _find.select(picked);
    _paintFind();
    _revealFindHit();
  }
}
