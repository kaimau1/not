import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/markdown.dart';
import '../../../core/widgets/speak_button.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../data/ai_report.dart';
import '../data/gemini_service.dart';
import 'doc_chat_screen.dart';

/// "Notu değiştir" geri çağırması: AI çıktısı notun içeriğiyle değiştirilir;
/// [asType] verilirse notun çalışma modu da o tipe geçer (madde/sıralı liste).
typedef ReplaceTextCallback = void Function(String text, {NoteType? asType});

/// Editördeki "Yapay Zeka" düğmesinin açtığı alt sayfa.
Future<void> showAiSheet(
  BuildContext context,
  Note note, {
  ValueChanged<String>? onAppendText,
  ReplaceTextCallback? onReplaceText,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => AiSheet(
    note: note,
    onAppendText: onAppendText,
    onReplaceText: onReplaceText,
  ),
);

class AiSheet extends ConsumerStatefulWidget {
  const AiSheet({
    super.key,
    required this.note,
    this.onAppendText,
    this.onReplaceText,
  });

  final Note note;

  /// Sonucu (OCR, ses dökümü vb.) nota ekleyen geri çağırma.
  final ValueChanged<String>? onAppendText;

  /// Sonucu notun içeriğiyle değiştiren geri çağırma ("Geliştir" için).
  final ReplaceTextCallback? onReplaceText;

  @override
  ConsumerState<AiSheet> createState() => _AiSheetState();
}

class _AiSheetState extends ConsumerState<AiSheet> {
  bool _loading = false;
  String? _result;
  String? _error;

  Future<void> _run(
    Future<String> Function(GeminiService) action, {
    bool cacheAsSummary = false,
    bool improvement = false,
    NoteType? replaceAsType,
  }) async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
      _lastWasImprovement = improvement;
      _replaceAsType = replaceAsType;
    });
    try {
      final service = ref.read(geminiServiceProvider);
      // Notlar düz metin tuttuğundan AI çıktısındaki markdown işaretlerini
      // (**, *, #, `) tek noktada temizle: gösterim, kopyalama ve nota
      // ekleme/değiştirmenin tümü temiz metni kullanır.
      final text = stripMarkdown(await action(service)).trim();
      if (cacheAsSummary) {
        ref
            .read(notesRepositoryProvider)
            ?.setAiSummary(
              widget.note.id,
              AiSummary(text: text, model: 'gemini', createdAt: DateTime.now()),
            );
      }
      if (mounted) setState(() => _result = text);
    } on GeminiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.isAuthError
              ? context.l10n.aiNoApiKey
              : context.l10n.aiError(e.message),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.aiError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _summarizePdf(GeminiService service, Attachment pdf) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    final bytes = repo == null ? null : await repo.readBytes(pdf);
    if (bytes == null) {
      throw GeminiException(notSyncedMessage);
    }
    return service.summarizePdf(bytes, pdf.fileName);
  }

  static const _translateTargets = [
    'Türkçe',
    'İngilizce',
    'Almanca',
    'Fransızca',
    'İspanyolca',
    'Arapça',
    'Rusça',
  ];

  bool _lastWasImprovement = false;

  /// "Notu değiştir" uygulanınca notun geçeceği tip (madde/sıralı liste
  /// çevirileri için); null ise tip korunur.
  NoteType? _replaceAsType;

  /// Tek dokunuşla "notu düzelt": yazım/imla/noktalama düzeltilir, çok hafif
  /// düzenlemeyle okunaklı hale getirilir; içerik ve madde sayısı korunur.
  Future<void> _fixNote() => _run(
    (s) => s.rewriteText(
      widget.note.toPlainText(),
      'Yazım, imla, noktalama ve büyük/küçük harf hatalarını düzelt. '
      'Çok hafif düzenlemelerle notu düzenli ve okunaklı hale getir. '
      'Anlamı, içeriği ve madde/satır sayısını KORU; yeni bilgi ekleme, '
      'madde silme. Düz metin ver; hiçbir biçimlendirme işareti '
      '(yıldız, kare, alt çizgi) kullanma.',
    ),
    improvement: true,
  );

  Future<void> _pickImprovement() async {
    final l10n = context.l10n;
    // (etiket, istem, "notu değiştir" uygulanınca geçilecek tip)
    final options = <(String, String, NoteType?)>[
      (
        l10n.improveFix,
        'Yazım ve dilbilgisi hatalarını düzelt, anlamı koru',
        null,
      ),
      (
        l10n.improveFormal,
        'Daha resmî ve profesyonel bir dille yeniden yaz',
        null,
      ),
      (l10n.improveShorten, 'Anlamı koruyarak yarı uzunluğa kısalt', null),
      (
        l10n.improveBullets,
        'Düzenli bir maddeler listesine dönüştür: her satır tek bir madde '
            'olsun, başına işaret/numara koyma',
        NoteType.checklist,
      ),
      (
        l10n.improveNumbered,
        'Sıralı bir listeye dönüştür: içeriği mantıklı bir sıraya koy, '
            'her satır tek bir adım olsun, başına numara koyma',
        NoteType.ordered,
      ),
    ];
    final chosen = await showDialog<(String, NoteType?)>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.aiImprove),
        children: [
          for (final (label, prompt, type) in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, (prompt, type)),
              child: Text(label),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await _run(
      (s) => s.rewriteText(widget.note.toPlainText(), chosen.$1),
      improvement: true,
      replaceAsType: chosen.$2,
    );
  }

  Future<void> _pickLanguageAndTranslate() async {
    final language = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.aiTranslate),
        children: [
          for (final target in _translateTargets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, target),
              child: Text(target),
            ),
        ],
      ),
    );
    if (language == null) return;
    await _run((s) => s.translateText(widget.note.toPlainText(), language));
  }

  Future<String> _extractImageText(
    GeminiService service,
    Attachment image,
  ) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    final bytes = repo == null ? null : await repo.readBytes(image);
    if (bytes == null) {
      throw GeminiException(notSyncedMessage);
    }
    return service.extractTextFromImage(bytes, image.mimeType);
  }

  Future<String> _transcribeAudio(
    GeminiService service,
    Attachment audio,
  ) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    final bytes = repo == null ? null : await repo.readBytes(audio);
    if (bytes == null) {
      throw GeminiException(notSyncedMessage);
    }
    return service.transcribeAudio(bytes, audio.mimeType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pdfs = [
      for (final a in widget.note.attachments)
        if (a.kind == AttachmentKind.pdf) a,
    ];
    final images = [
      for (final a in widget.note.attachments)
        if (a.kind == AttachmentKind.image) a,
    ];
    final audios = [
      for (final a in widget.note.attachments)
        if (a.kind == AttachmentKind.audio) a,
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aiTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(l10n.aiThinking),
                      ],
                    ),
                  )
                else if (_result != null)
                  _ResultView(
                    text: _result!,
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: _result!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l10n.copied)));
                      }
                    },
                    onReport: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref
                          .read(aiReportServiceProvider)
                          .report(content: _result!, source: 'ai_sheet');
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.aiReportThanks)),
                      );
                    },
                    onAppend: widget.onAppendText == null
                        ? null
                        : () {
                            widget.onAppendText!(_result!);
                            Navigator.pop(context);
                          },
                    onReplace:
                        widget.onReplaceText == null || !_lastWasImprovement
                        ? null
                        : () {
                            widget.onReplaceText!(
                              _result!,
                              asType: _replaceAsType,
                            );
                            Navigator.pop(context);
                          },
                  )
                else ...[
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  // Hızlı erişim: tek dokunuşla yazım/düzen düzeltmesi.
                  if (widget.onReplaceText != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: FilledButton.tonalIcon(
                        onPressed: widget.note.isEmpty ? null : _fixNote,
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: Text(l10n.aiFixNote),
                      ),
                    ),
                  // Notun tamamıyla (gövde + PDF/görsel ekleri) sohbet.
                  ListTile(
                    leading: const Icon(Icons.forum_outlined),
                    title: Text(l10n.noteChatTitle),
                    subtitle: Text(
                      l10n.noteChatIntro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    enabled:
                        !widget.note.isEmpty ||
                        widget.note.attachments.isNotEmpty,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DocChatScreen(note: widget.note),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 8),
                  ListTile(
                    leading: const Icon(Icons.summarize_outlined),
                    title: Text(l10n.aiSummarize),
                    enabled: !widget.note.isEmpty,
                    onTap: () => _run(
                      (s) => s.summarizeNote(widget.note),
                      cacheAsSummary: true,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: Text(l10n.aiAnalyze),
                    enabled: !widget.note.isEmpty,
                    onTap: () => _run((s) => s.analyzeNote(widget.note)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(l10n.aiTranslate),
                    enabled: !widget.note.isEmpty,
                    onTap: _pickLanguageAndTranslate,
                  ),
                  if (widget.onReplaceText != null)
                    ListTile(
                      leading: const Icon(Icons.auto_fix_high_outlined),
                      title: Text(l10n.aiImprove),
                      enabled: !widget.note.isEmpty,
                      onTap: _pickImprovement,
                    ),
                  for (final pdf in pdfs) ...[
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(
                        l10n.aiSummarizePdf(pdf.fileName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _run((s) => _summarizePdf(s, pdf)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.question_answer_outlined),
                      title: Text(
                        l10n.aiAskPdf(pdf.fileName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DocChatScreen(attachment: pdf),
                          ),
                        );
                      },
                    ),
                  ],
                  for (final image in images)
                    ListTile(
                      leading: const Icon(Icons.document_scanner_outlined),
                      title: Text(
                        l10n.aiExtractImageText(image.fileName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _run((s) => _extractImageText(s, image)),
                    ),
                  for (final audio in audios)
                    ListTile(
                      leading: const Icon(Icons.graphic_eq),
                      title: Text(
                        l10n.aiTranscribeAudio(audio.fileName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _run((s) => _transcribeAudio(s, audio)),
                    ),
                  if (widget.note.aiSummary != null) ...[
                    const Divider(indent: 20, endIndent: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.aiSummaryTitle,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          // Sesli özet: özet zaten üretilmiş durumda,
                          // seslendirme cihazda yapılıyor — ek API çağrısı yok.
                          SpeakButton(text: widget.note.aiSummary!.text),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        widget.note.aiSummary!.text,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.text,
    required this.onCopy,
    this.onReport,
    this.onAppend,
    this.onReplace,
  });

  final String text;
  final VoidCallback onCopy;

  /// Sorunlu AI çıktısını bildirme (Play üretken AI politikası).
  final VoidCallback? onReport;
  final VoidCallback? onAppend;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          // Wrap: dar ekranda butonlar taşmaz, gerekirse alt satıra sarılır
          // ("Nota ekle" ekranın dışında kalıp dokunulamıyordu).
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onReport != null)
                IconButton(
                  tooltip: context.l10n.aiReport,
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 16),
                label: Text(context.l10n.copy),
              ),
              if (onReplace != null)
                FilledButton.icon(
                  onPressed: onReplace,
                  icon: const Icon(Icons.published_with_changes, size: 18),
                  label: Text(context.l10n.replaceNote),
                ),
              if (onAppend != null)
                FilledButton.tonalIcon(
                  onPressed: onAppend,
                  icon: const Icon(Icons.playlist_add, size: 18),
                  label: Text(context.l10n.addToNote),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
