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
    this.onCopy,
    this.onSelectMany,
    this.onDetach,
    this.onVideoToNote,
    this.onTranscribe,
    this.viewSwitch,
    this.copyIsLink = false,
    this.onOpenExternal,
    this.onSaveAs,
    this.onCaption,
    this.hasCaption = false,
  });

  /// Görselin altına açıklama yazar (yerinde düzenleme açılır).
  final VoidCallback? onCaption;
  final bool hasCaption;

  /// EKİ FARKLI KAYDET (2026-10-17): dosya kullanıcının seçtiği yere.
  final VoidCallback? onSaveAs;

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

  /// Görseli sayfadan alıp alt şeritte DOSYA eki yapar.
  final VoidCallback? onDetach;

  /// Videodan (görüntü + ses) AI ile not çıkarır — yalnız video ekinde dolu.
  final VoidCallback? onVideoToNote;

  /// Görselin/videonun TRANSKRİPTİ (metne dök / kayıtlıysa aç).
  final VoidCallback? onTranscribe;

  /// [onCopy] BAĞLANTI kopyalar (YouTube eki — dosyası yok, kopyalanacak şey
  /// adresi). Menüde "Bağlantıyı kopyala" olarak ÜSTTE görünür.
  final bool copyIsLink;

  /// YouTube ekini YouTube uygulamasında/tarayıcıda açar.
  final VoidCallback? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
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
        if (onExtractText != null ||
            onCopy != null ||
            onSelectMany != null ||
            onDetach != null ||
            onVideoToNote != null ||
            onTranscribe != null ||
            onOpenExternal != null ||
            onSaveAs != null)
          PopupMenuButton<String>(
            tooltip: l10n.more,
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (action) {
              switch (action) {
                case 'ocr':
                  onExtractText?.call();
                case 'copy':
                  onCopy?.call();
                case 'selectMany':
                  onSelectMany?.call();
                case 'detach':
                  onDetach?.call();
                case 'videoToNote':
                  onVideoToNote?.call();
                case 'transcribe':
                  onTranscribe?.call();
                case 'openExternal':
                  onOpenExternal?.call();
                case 'saveAs':
                  onSaveAs?.call();
              }
            },
            itemBuilder: (context) => [
              if (onCopy != null && copyIsLink)
                PopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link),
                    title: Text(l10n.copyVideoLink),
                  ),
                ),
              if (onOpenExternal != null)
                PopupMenuItem(
                  value: 'openExternal',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.open_in_new),
                    title: Text(l10n.youTubeOpenExternal),
                  ),
                ),
              if (onVideoToNote != null)
                PopupMenuItem(
                  value: 'videoToNote',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: Text(l10n.videoToNote),
                  ),
                ),
              if (onTranscribe != null)
                PopupMenuItem(
                  value: 'transcribe',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.subtitles_outlined),
                    title: Text(l10n.transcriptAction),
                  ),
                ),
              if (onExtractText != null)
                PopupMenuItem(
                  value: 'ocr',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.document_scanner_outlined),
                    title: Text(l10n.extractText),
                  ),
                ),
              if (onCopy != null && !copyIsLink)
                PopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(l10n.copy),
                  ),
                ),
              if (onSelectMany != null)
                PopupMenuItem(
                  value: 'selectMany',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.checklist),
                    title: Text(l10n.selectImages),
                  ),
                ),
              if (onSaveAs != null)
                PopupMenuItem(
                  value: 'saveAs',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.save_alt_outlined),
                    title: Text(l10n.attachmentSaveAs),
                  ),
                ),
              if (onDetach != null)
                PopupMenuItem(
                  value: 'detach',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attachment_outlined),
                    title: Text(l10n.moveImageToAttachments),
                  ),
                ),
            ],
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
                        child: viewSwitch,
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
