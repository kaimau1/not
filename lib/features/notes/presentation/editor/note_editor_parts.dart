part of 'note_editor_screen.dart';

/// Klavyeden Kopyala/Kes'in temiz-metin sürümü.
///
/// EditableText, [CopySelectionTextIntent] eylemini `Action.overridable`
/// olarak kaydeder: odaklı alanın üst ağacında aynı Intent için bir eylem
/// varsa ONUN çalışmasına izin verir. Buradaki eylem, biçim çubuğunun zaten
/// izlediği son odaklı alanı ([FormatTarget]) kullanır; hedef odaklı değilse
/// ya da seçim yoksa varsayılan davranışa ([Action.callingAction]) devreder.
class _CleanCopySelectionAction extends Action<CopySelectionTextIntent> {
  _CleanCopySelectionAction(this.owner);

  final _NoteEditorScreenState owner;

  @override
  Object? invoke(CopySelectionTextIntent intent) {
    final target = owner._formatTarget;
    if (target == null || !target.focusNode.hasFocus) {
      return callingAction?.invoke(intent);
    }
    final controller = target.controller;
    final value = controller.value;
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return callingAction?.invoke(intent);
    }
    final text = clipboardTextOf(value);
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
    }
    if (intent.collapseSelection) {
      // Kes: seçilen ham aralık alandan silinir ve kayıt olağan yoldan akar.
      controller.value = TextEditingValue(
        text: value.text.replaceRange(selection.start, selection.end, ''),
        selection: TextSelection.collapsed(offset: selection.start),
      );
      target.commit();
    }
    return null;
  }
}

/// Dikte sürerken alt çubuğun üstünde duran uyarı şeridi. Amacı tek:
/// mikrofonun açık olduğu gözden kaçmasın.
/// Süren AI işini gösteren şerit: iş bitene kadar ekranda durur. Tek bir
/// SnackBar yeterli değildi — kayboluyor, kullanıcı "çalışıyor mu, dondu mu"
/// bilemiyordu.
/// BAĞLAMA KİPİ şeridi: seçilmiş ek + "bağlanacak yazıyı seç" yönergesi.
///
/// Kullanıcı isteği 2026-08-16 ("önce eki seçip sonra metni seçme de
/// olmalı"). Şerit alt çubuğun içinde durur; düğmeye basmak metin alanının
/// odağını düşürse bile seçim denetleyicide korunuyor (bkz.
/// `_finishPendingEmbed`).
/// YouTube bağlantısı sorusu. Bağlantı geçerli bir VİDEO değilse "Ekle"
/// kapalı kalır (kanal/oynatma listesi bağlantısı ek olamaz).
class _YouTubeLinkDialog extends StatefulWidget {
  const _YouTubeLinkDialog({required this.initial});

  final String initial;

  @override
  State<_YouTubeLinkDialog> createState() => _YouTubeLinkDialogState();
}

class _YouTubeLinkDialogState extends State<_YouTubeLinkDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _url => firstYouTubeUrl(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = _url;
    return AlertDialog(
      title: Text(l10n.addYouTubeVideo),
      content: TextField(
        controller: _controller,
        autofocus: widget.initial.isEmpty,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: 'https://youtu.be/…',
          helperText: l10n.youTubeLinkHelp,
          helperMaxLines: 3,
          prefixIcon: const Icon(Icons.smart_display_outlined),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (_url != null) Navigator.pop(context, _url);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: url == null ? null : () => Navigator.pop(context, url),
          child: Text(l10n.addAttachment),
        ),
      ],
    );
  }
}

class _PendingEmbedBanner extends StatelessWidget {
  const _PendingEmbedBanner({
    required this.fileName,
    required this.onPointerDown,
    required this.onLink,
    required this.onLasso,
    required this.onCancel,
  });

  final String fileName;
  final VoidCallback onLasso;

  /// Şeride PARMAK DEĞER DEĞMEZ (dokunuşun işlenmesinden, dolayısıyla olası
  /// odak/seçim kaybından ÖNCE) çağrılır — bkz. `_lastSelection`.
  final VoidCallback onPointerDown;
  final VoidCallback onLink;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // TextFieldTapRegion + ExcludeFocus: şeride dokunmak gövdenin odağını
    // DÜŞÜRMEZ, dolayısıyla seçim imlece çökmez (bkz. `_lastSelection`
    // kök nedeni). Aynı kural notta metin yazılırken açılan her yardımcı
    // arayüz için geçerli — bkz. balon kartındaki eylemler.
    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: Listener(
          // `Listener` jest arenasına GİRMEZ: düğmelerin kendi dokunuşlarını
          // hiç etkilemez, yalnız haber verir.
          onPointerDown: (_) => onPointerDown(),
          child: Material(
            color: scheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              child: Row(
                children: [
                  Icon(Icons.link, size: 18, color: scheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.attachmentTagPendingBanner(fileName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onTertiaryContainer),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('embed-lasso'),
                    tooltip: l10n.embedLasso,
                    icon: const Icon(Icons.gesture, size: 20),
                    color: scheme.onTertiaryContainer,
                    onPressed: onLasso,
                  ),
                  TextButton(
                    onPressed: onLink,
                    child: Text(l10n.attachmentTagLinkHere),
                  ),
                  IconButton(
                    tooltip: l10n.cancel,
                    icon: const Icon(Icons.close, size: 18),
                    color: scheme.onTertiaryContainer,
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bu notun SÜREN ek yüklemeleri (bkz. [uploadProgressProvider]): yalnız
/// yükleme varken çizilir, oran biliniyorsa çubuk dolar.
class _NoteUploadsBanner extends ConsumerWidget {
  const _NoteUploadsBanner({required this.attachments});

  final List<Attachment> attachments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = uploadSummaryFor(
      attachments,
      ref.watch(uploadProgressProvider),
    );
    if (summary.count == 0) return const SizedBox.shrink();
    final fraction = summary.fraction;
    final l10n = context.l10n;
    return _AiBanner(
      label: fraction == null
          ? l10n.attachmentsUploadingCount(summary.count)
          : '${l10n.attachmentsUploadingCount(summary.count)} · '
                '${formatUploadPercent(context, fraction)}',
      icon: Icons.cloud_upload_outlined,
      progress: fraction,
    );
  }
}

/// CANLI DİKTE alanı: mikrofon açıkken kaçırılamayacak gösterge (açık kalmış
/// mikrofon fark edilmiyordu) ve durdurma düğmesi.
///
/// Sesli yakalama levhasıyla AYNI KART (kullanıcı isteği 2026-10-20 —
/// bkz. [ListeningCard]): eskiden tek satırlık bir şeritti, dalga 40 px'e
/// sıkışmış, durdurma küçük bir simgeydi; yapay zekâ levhası ise ekranın
/// yarısını kaplıyordu. Artık ikisi aynı orta boy kart; fark kip rengi,
/// rozet ve etiket — burada döküm alanı yok, yazı notun içine akıyor.
class _DictationPanel extends StatelessWidget {
  const _DictationPanel({required this.start, required this.onStop});

  final DateTime start;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      key: const ValueKey('dictation-panel'),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: ListeningCard(
        mode: ListeningMode.dictation,
        active: true,
        title: l10n.voiceListening,
        subtitle: l10n.dictationPanelHint,
        clock: ListeningClock(
          start: start,
          active: true,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.error,
          ),
        ),
        action: ListeningActionButton(
          key: const ValueKey('dictation-stop'),
          listening: true,
          label: l10n.voiceFinish,
          onPressed: onStop,
        ),
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  const _AiBanner({
    required this.label,
    this.icon = Icons.auto_awesome,
    this.progress,
  });

  final String label;

  /// Dolu ise çubuk BELİRLİ (0..1) dolar; null = belirsiz akış.
  final double? progress;

  /// Şeridin simgesi: AI işlerinde yıldız, dosya işlerinde eşitleme oku.
  /// (Canlı dikte kendi alanında — bkz. [_DictationPanel].)
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: InkWell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              minHeight: 2,
              value: progress,
              backgroundColor: scheme.secondaryContainer,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
