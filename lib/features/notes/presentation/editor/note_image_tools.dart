part of 'note_images.dart';

/// Seçili görselin işlem çubuğu içeriği (genişlik kaydırıcısı + OCR + tam
/// ekran + sil): küçük tuval ve tam sayfa katmanı ortak kullanır.
class _ImageTools extends StatelessWidget {
  const _ImageTools({
    super.key,
    required this.wFrac,
    required this.minWidthFrac,
    required this.onWidthChanged,
    required this.onWidthEnd,
    required this.onFullscreen,
    required this.onRemove,
    this.onExtractText,
    this.onAddText,
    this.onCopy,
    this.onSelectMany,
    this.onVideoToNote,
    this.onTranscribe,
    this.viewSwitch,
    required this.attachment,
    this.onOpenExternal,
    this.onSaveAs,
    this.onShare,
    this.onCaption,
    this.hasCaption = false,
    this.placementHint = false,
  });

  /// Ek AZ ÖNCE eklendi: görünüm anahtarı parlayan çerçeveyle ve "nerede
  /// dursun?" açıklamasıyla öne çıkar (bkz. NotePageCanvas.placementHintId).
  final bool placementHint;

  /// Görselin altına açıklama yazar (yerinde düzenleme açılır).
  final VoidCallback? onCaption;
  final bool hasCaption;

  /// EKİ FARKLI KAYDET (2026-10-17): dosya kullanıcının seçtiği yere.
  final VoidCallback? onSaveAs;

  /// Eki sistem paylaşımıyla gönderir (2026-11-03).
  final VoidCallback? onShare;

  /// Üst satırdaki görünüm anahtarı (Sabit / Yüzen / Balonlu).
  final Widget? viewSwitch;

  final double wFrac;
  final double minWidthFrac;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onWidthEnd;
  final VoidCallback? onFullscreen;
  final VoidCallback onRemove;
  final VoidCallback? onExtractText;

  /// Görseli panoya kopyalar (uygulama içi ek panosu + sistem panosu).
  final VoidCallback? onCopy;

  /// ÇOKLU seçim kipini açar (birden çok görseli birlikte kopyala/sil).
  /// Sayfada tek görsel varsa gösterilmez — seçecek ikinci bir şey yok.
  final VoidCallback? onSelectMany;

  /// Videodan (görüntü + ses) AI ile not çıkarır — yalnız video ekinde dolu.
  final VoidCallback? onVideoToNote;

  /// Görselin/videonun TRANSKRİPTİ (metne dök / kayıtlıysa aç).
  final VoidCallback? onTranscribe;

  /// Üstüne açık metin yaz (tam ekran yazı kipinde açılır).
  final VoidCallback? onAddText;

  /// Menüdeki işler ekin türüne göre (bkz. [attachmentActionsFor]).
  final Attachment attachment;

  /// YouTube ekini YouTube uygulamasında/tarayıcıda açar.
  final VoidCallback? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final menuActions = attachmentActionsFor(
      attachment,
      AttachmentSurface.floating,
      AttachmentCaps(
        transcribe: onTranscribe != null,
        extractText: onExtractText != null,
        videoToNote: onVideoToNote != null,
        copy: onCopy != null,
        selectMany: onSelectMany != null,
        share: onShare != null,
        saveAs: onSaveAs != null,
        openExternal: onOpenExternal != null,
      ),
    );
    final tools = Row(
      children: [
        Icon(Icons.photo_size_select_large, size: 18, color: scheme.primary),
        Expanded(
          child: Slider(
            value: wFrac,
            min: minWidthFrac,
            onChanged: onWidthChanged,
            onChangeEnd: onWidthEnd,
          ),
        ),
        if (onAddText != null)
          IconButton(
            key: const ValueKey('floating-add-text'),
            tooltip: l10n.attachmentAddText,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.title, size: 20),
            onPressed: onAddText,
          ),
        if (onCaption != null)
          IconButton(
            tooltip: hasCaption ? l10n.imageCaptionEdit : l10n.imageCaptionAdd,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.short_text_rounded, size: 20),
            onPressed: onCaption,
          ),
        if (onFullscreen != null)
          IconButton(
            tooltip: l10n.fullscreen,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.fullscreen, size: 20),
            onPressed: onFullscreen,
          ),
        IconButton(
          tooltip: l10n.removeAttachment,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete_outline, size: 20),
          color: scheme.error,
          onPressed: onRemove,
        ),
        // Seyrek kullanılan işlemler menüde: hepsi ayrı düğme olsaydı
        // çubuk dar ekranda kaydırıcıya yer bırakmazdı. Hiçbiri
        // verilmemişse düğme de çizilmez (boş menü açılışta patlar).
        if (menuActions.isNotEmpty)
          PopupMenuButton<AttachmentAction>(
            tooltip: l10n.more,
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (action) {
              switch (action) {
                case AttachmentAction.extractText:
                  onExtractText?.call();
                case AttachmentAction.copy || AttachmentAction.copyLink:
                  onCopy?.call();
                case AttachmentAction.selectMany:
                  onSelectMany?.call();
                case AttachmentAction.videoToNote:
                  onVideoToNote?.call();
                case AttachmentAction.transcribe:
                  onTranscribe?.call();
                case AttachmentAction.openExternal:
                  onOpenExternal?.call();
                case AttachmentAction.saveAs:
                  onSaveAs?.call();
                case AttachmentAction.share:
                  onShare?.call();
                case _:
                  break;
              }
            },
            itemBuilder: (context) =>
                attachmentPopupItems(context, menuActions),
          ),
      ],
    );
    final viewSwitch = this.viewSwitch;
    return Material(
      color: scheme.surfaceContainerHighest,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // GÖRÜNÜM satırı: ekin nasıl duracağı tek dokunuşla değişir
            // (kullanıcı isteği 2026-10-16 — "kolay geçişin yeri ve düzeni").
            if (viewSwitch != null && placementHint)
              Padding(
                key: const ValueKey('placement-hint'),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${l10n.placementHintTitle} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: l10n.placementHintBody),
                          ],
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (viewSwitch != null)
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    const SizedBox(width: 8),
                    if (constraints.maxWidth >= 380) ...[
                      Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.viewModeTitle,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    // Anahtar kalan genişliği alır: sığmazsa kendisi
                    // simgelere iner (bkz. AttachmentViewSwitch).
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: placementHint
                            ? _PlacementPulse(child: viewSwitch)
                            : viewSwitch,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            tools,
          ],
        ),
      ),
    );
  }
}

/// Yeni ekin görünüm anahtarının çevresinde birkaç kez nabız gibi atan
/// çerçeve — göz panele değil SEÇİME gitsin (bkz. `placementHint`).
/// Hareket azaltıldıysa çerçeve sabit durur.
class _PlacementPulse extends StatefulWidget {
  const _PlacementPulse({required this.child});

  final Widget child;

  @override
  State<_PlacementPulse> createState() => _PlacementPulseState();
}

class _PlacementPulseState extends State<_PlacementPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 1;
    } else if (!_pulse.isAnimating && _pulse.value == 0) {
      // Üç nabız, sonra çerçeve yerinde kalır.
      unawaited(
        _pulse
            .repeat(reverse: true, count: 3)
            .whenComplete(() {
              if (mounted) _pulse.value = 1;
            }),
      );
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.15 + 0.35 * t),
                blurRadius: 4 + 10 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: Padding(padding: const EdgeInsets.all(2), child: child),
        );
      },
      child: widget.child,
    );
  }
}
