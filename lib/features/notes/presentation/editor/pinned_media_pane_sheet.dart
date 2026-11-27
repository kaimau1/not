part of 'pinned_media_pane.dart';

/// Bölmenin en büyük yüksekliği.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-19: "video sabitken klavye
/// açıldığında video yukarı itiliyor biraz"): sınır, O ANKİ yüksekliğin
/// %70'iydi. Klavye oturunca gövde klavye kadar kısalıyor, sınır da onunla
/// birlikte düşüyordu — bölme büzülüyor, video küçülüp yukarı kayıyor, çubuk
/// zıplıyordu. Artık oran klavyesiz (en büyük görülen) yükseklikten alınır;
/// klavye açıkken bölme YERİNDE kalır, yalnız not satırına
/// [kPinnedNoteMinHeight] kalmayacaksa küçülür.
double pinnedMaxHeight({required double available, required double stable}) {
  final byFraction = stable * kPinnedMaxFraction;
  final byRoom = available - kPinnedBarHeight - kPinnedNoteMinHeight;
  final max = byFraction < byRoom ? byFraction : byRoom;
  return max < kPinnedMinHeight ? kPinnedMinHeight : max;
}

/// Yeni sabitlenen medyanın ilk yüksekliği: ekran genişliğinde medyanın kendi
/// oranı, ekranın %45'ini geçmeden. Oranı bilinmeyen video 16:9 sayılır.
double defaultPinnedHeight(Attachment media, Size screen) {
  // Ses: oynatıcı kartı kadar; metin: okunacak kadar (ekranın %40'ı).
  if (media.kind == AttachmentKind.audio) return 104;
  if (media.kind == AttachmentKind.text) {
    return (screen.height * 0.4).clamp(kPinnedMinHeight, screen.height * 0.5);
  }
  final w = (media.width ?? 0).toDouble();
  final h = (media.height ?? 0).toDouble();
  final pdf = media.kind == AttachmentKind.pdf;
  final ratio = w > 0 && h > 0
      ? (pdf ? 1 / pdfBoxAspect(w, h, media.pdfTurns) : h / w)
      : (media.kind == AttachmentKind.video ||
                media.kind == AttachmentKind.slide
            ? 9 / 16
            : pdf
            ? 1.41
            : 3 / 4);
  final natural = screen.width * ratio;
  // Belge okunacak kadar uzun açılır (A4 sayfa ekranın yarısında bile
  // okunur); görsel/video ekranın %45'ini geçmez.
  // 2026-11-21: görsel de ekranın yarısına kadar (kullanıcı: "fazla
  // daraltmasın").
  final max = screen.height * (pdf || media.kind == AttachmentKind.image
      ? 0.5
      : 0.45);
  return natural.clamp(
    kPinnedMinHeight,
    max < kPinnedMinHeight ? kPinnedMinHeight : max,
  );
}


extension _PinnedMediaPaneSheet on _PinnedMediaPaneState {
  /// bırakma kipi açılır, tür (Balon | Metin) kipin araç kartında seçilir;
  /// kip açıkken düğme ✓ olur ve kipi kapatır. Dar çubukta aynısı ⋮
  /// levhasının "Balonlar" bölümünde.
  Widget _addBubbleButton(BuildContext context, {required bool active}) {
    final l10n = context.l10n;
    if (active) {
      return PinnedBarButton(
        key: const ValueKey('pinned-add-bubble'),
        tooltip: l10n.bubbleAddDone,
        icon: Icons.check,
        selected: true,
        tonal: true,
        onPressed: _stopAdding,
      );
    }
    // TEK DOKUNUŞ = BIRAKMA KİPİ (kullanıcı bulgusu 2026-11-19: "balona
    // tıklıyorum, önce Balon mu metin mi diye soruyor; içeride yine
    // soruyor — baştaki soru gereksiz"). Tür seçimi yalnız bırakma kipinin
    // araç kartında (Balon | Metin bölmesi); kip son seçilen türle açılır.
    // Gizle/göster balon varken yanındaki göz düğmesinde (görüntüleyici
    // balon çubuğuyla aynı).
    final toggle = _bubbleToggle();
    // Doğrudan IconButton (ara `PinnedBarButton` yok): klavye açılış karesinin
    // kurulum bütçesi (S17 sabit görsel/PDF) eski menü düğmesiyle aynı kalsın.
    final add = IconButton(
      key: const ValueKey('pinned-add-bubble'),
      tooltip: l10n.bubbleAdd,
      visualDensity: VisualDensity.compact,
      iconSize: AppIconSize.m,
      icon: const Icon(Icons.add_comment_outlined),
      onPressed: () => _startAdding(plain: _lastPlain),
    );
    if (toggle == null) return add;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        add,
        PinnedBarButton(
          key: const ValueKey('pinned-bubbles-toggle'),
          tooltip: toggle.hidden ? l10n.bubblesShow : l10n.bubblesHide,
          icon: toggle.hidden
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          selected: toggle.hidden,
          onPressed: toggle.flip,
        ),
      ],
    );
  }

  /// Bırakma kipinin son türü (araç kartında değişebilir).
  bool get _lastPlain => _canEditBubbles
      ? _ownController().plainMode
      : _pdfPlain.value;

  /// Ek işleri verilmiş mi (salt okunurda kaldır/paylaş yok).
  bool get hasMenu =>
      widget.onRemove != null ||
      widget.onTranscribe != null ||
      widget.onSaveAs != null ||
      widget.onShare != null;

  /// ⋮ levhasında gösterilecek bir şey var mı.
  bool get _hasSheet =>
      hasMenu ||
      _hasSmartActions ||
      widget.media.kind == AttachmentKind.pdf ||
      widget.viewSwitch != null ||
      widget.sheetViewSwitch != null ||
      widget.onSelectSide != null ||
      (!_wideBar && (_canEditBubbles || _canEditPdfBubbles)) ||
      (_tinyBar &&
          (widget.media.kind != AttachmentKind.audio ||
              widget.onNoteAt != null));

  void _run(AttachmentAction action) {
    switch (action) {
      case AttachmentAction.open:
        widget.onOpen();
      case AttachmentAction.rotate:
        VideoHubScope.maybeOf(context)?.rotate(widget.media.id);
      case AttachmentAction.caption:
        widget.onCaption?.call();
      case AttachmentAction.copyLink:
        widget.onCopyLink?.call();
      case AttachmentAction.copy:
        widget.onCopy?.call();
      case AttachmentAction.extractText:
        widget.onExtractText?.call();
      case AttachmentAction.transcribe:
        widget.onTranscribe?.call();
      case AttachmentAction.share:
        widget.onShare?.call();
      case AttachmentAction.saveAs:
        widget.onSaveAs?.call();
      case AttachmentAction.remove:
        widget.onRemove?.call();
      case _:
        break;
    }
  }

  /// Eke sağ tık (masaüstü, F40.8): aynı liste, imlecin yanında.
  Future<void> _showContextMenu(Offset global) async {
    final action = await showAttachmentContextMenu(
      context,
      global,
      _actions(AttachmentSurface.contextMenu),
    );
    if (action != null && mounted) _run(action);
  }

  Future<void> _openSheet() async {
    final run = await showAppSheet<VoidCallback>(
      context: context,
      isScrollControlled: true,
      // Tutup aşağı çekerek kapatılır (kullanıcı isteği 2026-11-14).
      showDragHandle: true,
      builder: _sheet,
    );
    if (run != null && mounted) run();
  }

  Widget _sheet(BuildContext sheet) {
    final theme = Theme.of(sheet);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final l10n = sheet.l10n;
    final media = widget.media;
    final wide = _wideBar;
    void pick(VoidCallback run) => Navigator.pop(sheet, run);
    Widget tile(String key, IconData icon, String label, VoidCallback run) =>
        SheetTile.tile(
          key: ValueKey(key),
          icon: icon,
          label: label,
          onTap: () => pick(run),
        );
    Widget section(String label) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.l, bottom: AppSpace.s),
      child: SectionLabel(label),
    );

    final kindIcon = switch (media.kind) {
      AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
      AttachmentKind.image => Icons.image_outlined,
      AttachmentKind.video => Icons.play_circle_outline,
      AttachmentKind.audio => Icons.audiotrack_outlined,
      AttachmentKind.slide => Icons.slideshow_outlined,
      AttachmentKind.text => Icons.description_outlined,
      AttachmentKind.unknown => Icons.attach_file_outlined,
    };
    final subtitle = switch (media.kind) {
      AttachmentKind.pdf when _pdfBar.ready && _pdfBar.pageCount > 0 =>
        '${l10n.cardKindPdf} · ${_pdfBar.page} / ${_pdfBar.pageCount}',
      AttachmentKind.pdf => l10n.cardKindPdf,
      AttachmentKind.image
          when (media.width ?? 0) > 0 && (media.height ?? 0) > 0 =>
        '${media.width} × ${media.height}',
      _ => null,
    };

    final viewSwitch = widget.sheetViewSwitch?.call(sheet) ?? widget.viewSwitch;
    final canShrink =
        widget.onShrinkToFitChanged != null &&
        !widget.fill &&
        (media.kind == AttachmentKind.image ||
            media.kind == AttachmentKind.pdf);
    final bubbles = !wide && (_canEditBubbles || _canEditPdfBubbles);
    final toggle = _bubbleToggle();
    final document = media.kind == AttachmentKind.pdf
        ? _pdfBar.menuActions(sheet)
        : const <PdfMenuAction>[];
    final actions = _actions(AttachmentSurface.pinned);
    final others = [
      // En dar bölmede çubuktan inenler.
      if (_tinyBar && media.kind != AttachmentKind.audio)
        tile(
          'pinned-action-open',
          Icons.fullscreen,
          l10n.fullscreen,
          widget.onOpen,
        ),
      if (_tinyBar && widget.onNoteAt != null)
        tile(
          'pinned-action-note-at',
          media.kind == AttachmentKind.pdf ? Icons.edit_note : Icons.more_time,
          media.kind == AttachmentKind.pdf
              ? l10n.pdfNoteAtPage
              : l10n.videoNoteAtTime,
          widget.onNoteAt!,
        ),
      for (final action in actions)
        if (action != AttachmentAction.remove)
          Builder(
            key: ValueKey('pinned-action-${action.name}'),
            builder: (context) {
              final look = attachmentActionLook(context, action);
              return SheetTile.tile(
                icon: look.icon,
                label: look.label,
                onTap: () => pick(() => _run(action)),
              );
            },
          ),
    ];
    final grouped =
        _hasSmartActions ||
        viewSwitch != null ||
        widget.onSelectSide != null ||
        canShrink ||
        bubbles ||
        document.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    kindIcon,
                    size: AppIconSize.m,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      media.fileName.isEmpty ? l10n.more : media.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.sheetTitle,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.meta,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (viewSwitch != null) ...[
            const SizedBox(height: AppSpace.l),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.card,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: tokens.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.viewModeTitle),
                    const SizedBox(height: AppSpace.s),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: viewSwitch,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.onSelectSide != null) ...[
            const SizedBox(height: AppSpace.s),
            DecoratedBox(
              key: const ValueKey('pinned-sheet-side'),
              decoration: BoxDecoration(
                color: tokens.card,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: tokens.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.pinnedSideTitle),
                    const SizedBox(height: AppSpace.s),
                    Row(
                      children: [
                        for (final (i, target) in PinnedSide.values.indexed) ...[
                          if (i > 0) const SizedBox(width: AppSpace.s),
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: target == widget.side,
                              label: _PinnedMediaPaneState._sideLabel(l10n, target),
                              child: Material(
                                key: ValueKey(
                                  'pinned-side-pick-${target.name}',
                                ),
                                color: target == widget.side
                                    ? scheme.primaryContainer
                                    : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.m,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.m,
                                  ),
                                  onTap: () =>
                                      pick(() => widget.onSelectSide!(target)),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: kMinInteractiveDimension,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpace.xs,
                                        vertical: AppSpace.xs,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _PinnedMediaPaneState._sideIcon(target),
                                            size: AppIconSize.s,
                                            color: target == widget.side
                                                ? scheme.onPrimaryContainer
                                                : scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: AppSpace.xs),
                                          Flexible(
                                            child: Text(
                                              _PinnedMediaPaneState._sideLabel(l10n, target),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: text.label.copyWith(
                                                color: target == widget.side
                                                    ? scheme.onPrimaryContainer
                                                    : scheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Düğme çubukta (solda); levhada yalnız çubuk ona yer vermezse.
          if (canShrink && _tinyBar) ...[
            const SizedBox(height: AppSpace.s),
            Material(
              color: tokens.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.m),
                side: BorderSide(color: tokens.hairline),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('pinned-action-shrink'),
                onTap: () => pick(_toggleShrink),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.m,
                    vertical: AppSpace.s,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _shrinkActive
                            ? Icons.fit_screen
                            : Icons.fit_screen_outlined,
                        size: AppIconSize.m,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: AppSpace.m),
                      Expanded(
                        child: Text(
                          l10n.pinnedShrinkToFit,
                          style: text.label,
                        ),
                      ),
                      IgnorePointer(
                        child: Switch(
                          value: _shrinkActive,
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (_hasSmartActions) ...[
            section(l10n.pinnedSmartActions),
            SheetTileGrid(
              children: [
                if (widget.onExtractText != null)
                  tile(
                    'pinned-sheet-smart-ocr',
                    Icons.document_scanner_outlined,
                    l10n.pinnedSmartOcr,
                    widget.onExtractText!,
                  ),
                if (widget.onSmartSummarize != null)
                  tile(
                    'pinned-sheet-smart-summarize',
                    Icons.summarize_outlined,
                    l10n.pinnedSmartSummarize,
                    widget.onSmartSummarize!,
                  ),
                if (widget.onSmartTasks != null)
                  tile(
                    'pinned-sheet-smart-tasks',
                    Icons.checklist_rtl_outlined,
                    l10n.pinnedSmartTasks,
                    widget.onSmartTasks!,
                  ),
                if (_effectiveAreaAsk != null)
                  tile(
                    'pinned-sheet-smart-area-ask',
                    Icons.crop_free_outlined,
                    l10n.pinnedSmartAreaAsk,
                    _effectiveAreaAsk!,
                  ),
              ],
            ),
          ],
          if (bubbles) ...[
            section(l10n.bubblesOverviewTitle),
            SheetTileGrid(
              children: [
                // Tür (Balon | Metin) bırakma kipinin araç kartında —
                // burada ikinci kez sorulmaz (kullanıcı bulgusu 2026-11-19).
                tile(
                  'pinned-add-bubble-note',
                  Icons.add_comment_outlined,
                  l10n.bubbleAdd,
                  () => _startAdding(plain: _lastPlain),
                ),
                if (toggle != null)
                  tile(
                    'pinned-bubbles-toggle',
                    toggle.hidden
                        ? Icons.speaker_notes_off_outlined
                        : Icons.chat_bubble_outline,
                    toggle.hidden ? l10n.bubblesShow : l10n.bubblesHide,
                    toggle.flip,
                  ),
              ],
            ),
          ],
          if (document.isNotEmpty) ...[
            section(l10n.cardKindPdf),
            SheetTileGrid(
              children: [
                for (final a in document)
                  tile('pinned-pdf-${a.id}', a.icon, a.label, a.run),
              ],
            ),
          ],
          if (others.isNotEmpty) ...[
            if (grouped)
              section(l10n.more)
            else
              const SizedBox(height: AppSpace.m),
            SheetTileGrid(children: others),
          ],
          if (actions.contains(AttachmentAction.remove)) ...[
            const SizedBox(height: AppSpace.l),
            Builder(
              builder: (context) {
                final look = attachmentActionLook(
                  context,
                  AttachmentAction.remove,
                );
                return DestructiveRow(
                  key: const ValueKey('pinned-action-remove'),
                  icon: look.icon,
                  label: look.label,
                  onTap: () => pick(() => _run(AttachmentAction.remove)),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Alt parçayı (çubuk + not) [dy] kadar aşağıda boyar — yerleşim yok.
class _ShiftFlow extends FlowDelegate {
  _ShiftFlow(this.dy) : super(repaint: dy);

  final ValueListenable<double> dy;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(constraints.biggest);

  @override
  void paintChildren(FlowPaintingContext context) => context.paintChild(
    0,
    transform: Matrix4.translationValues(0, dy.value, 0),
  );

  @override
  bool shouldRepaint(_ShiftFlow oldDelegate) => oldDelegate.dy != dy;
}

/// Medyayı tam boyunda ([full]) yerleştirir; [shrink] ise görünen boya
/// (`laid + dy`) sığacak kadar küçülterek boyar (üst ortadan).
class _FitFlow extends FlowDelegate {
  _FitFlow({
    required this.laid,
    required this.full,
    required this.dy,
    required this.shrink,
  }) : super(repaint: dy);

  final double laid;
  final double full;
  final ValueListenable<double> dy;
  final bool shrink;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(constraints.biggest);

  @override
  void paintChildren(FlowPaintingContext context) {
    final scale = !shrink || full <= 0
        ? 1.0
        : ((laid + dy.value) / full).clamp(0.0, 1.0);
    final width = context.size.width;
    context.paintChild(
      0,
      transform: Matrix4.identity()
        ..translateByDouble(width * (1 - scale) / 2, 0, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1),
    );
  }

  @override
  bool shouldRepaint(_FitFlow oldDelegate) =>
      oldDelegate.laid != laid ||
      oldDelegate.full != full ||
      oldDelegate.shrink != shrink ||
      oldDelegate.dy != dy;
}

/// Pencerenin görünen kısmı: üstten `laid + dy` (boyama; [dy] değişince
/// yeniden kırpılır, yerleşim yok).
class _WindowClip extends CustomClipper<Rect> {
  _WindowClip(this.laid, this.dy) : super(reclip: dy);

  final double laid;
  final ValueListenable<double> dy;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    0,
    0,
    size.width,
    (laid + dy.value).clamp(0.0, size.height),
  );

  @override
  bool shouldReclip(_WindowClip oldClipper) =>
      oldClipper.laid != laid || oldClipper.dy != dy;
}
