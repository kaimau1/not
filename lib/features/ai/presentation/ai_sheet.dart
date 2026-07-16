import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../data/api_key_store.dart';
import '../data/gemini_service.dart';

/// Editördeki "Yapay Zeka" düğmesinin açtığı alt sayfa.
Future<void> showAiSheet(
  BuildContext context,
  Note note, {
  ValueChanged<String>? onAppendText,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AiSheet(note: note, onAppendText: onAppendText),
    );

class AiSheet extends ConsumerStatefulWidget {
  const AiSheet({super.key, required this.note, this.onAppendText});

  final Note note;

  /// Sonucu (OCR, ses dökümü vb.) nota ekleyen geri çağırma.
  final ValueChanged<String>? onAppendText;

  @override
  ConsumerState<AiSheet> createState() => _AiSheetState();
}

class _AiSheetState extends ConsumerState<AiSheet> {
  bool _loading = false;
  String? _result;
  String? _error;

  Future<void> _run(Future<String> Function(GeminiService) action,
      {bool cacheAsSummary = false}) async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });
    try {
      final service = ref.read(geminiServiceProvider);
      final text = await action(service);
      if (cacheAsSummary) {
        ref.read(notesRepositoryProvider)?.setAiSummary(
              widget.note.id,
              AiSummary(
                text: text,
                model: 'gemini',
                createdAt: DateTime.now(),
              ),
            );
      }
      if (mounted) setState(() => _result = text);
    } on GeminiException catch (e) {
      if (mounted) {
        setState(() => _error = e.isAuthError
            ? context.l10n.aiNoApiKey
            : context.l10n.aiError(e.message));
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
    final apiKey = ref.watch(geminiApiKeyProvider).value;
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
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                      Icon(Icons.auto_awesome,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aiTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (apiKey == null || apiKey.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(l10n.aiNoApiKey, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/settings');
                          },
                          child: Text(l10n.settings),
                        ),
                      ],
                    ),
                  )
                else if (_loading)
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.copied)),
                        );
                      }
                    },
                    onAppend: widget.onAppendText == null
                        ? null
                        : () {
                            widget.onAppendText!(_result!);
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
                  for (final pdf in pdfs)
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(
                        l10n.aiSummarizePdf(pdf.fileName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _run((s) => _summarizePdf(s, pdf)),
                    ),
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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Text(
                        l10n.aiSummaryTitle,
                        style: Theme.of(context).textTheme.labelMedium,
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
  const _ResultView({required this.text, required this.onCopy, this.onAppend});

  final String text;
  final VoidCallback onCopy;
  final VoidCallback? onAppend;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 16),
                label: Text(context.l10n.copy),
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
