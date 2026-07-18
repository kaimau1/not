import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../data/gemini_service.dart';

/// Belge sohbeti: ya tek bir ekli PDF'e ([attachment]) ya da bir notun
/// tamamına ([note] — gövdesi + PDF/görsel ekleri) soru sorulur.
/// İkisinden yalnız biri verilir.
class DocChatScreen extends ConsumerStatefulWidget {
  const DocChatScreen({super.key, this.attachment, this.note})
      : assert(attachment != null || note != null,
            'Sohbet için ek ya da not gerekir');

  final Attachment? attachment;
  final Note? note;

  @override
  ConsumerState<DocChatScreen> createState() => _DocChatScreenState();
}

class _DocChatScreenState extends ConsumerState<DocChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _history = <ChatTurn>[];

  /// PDF modunda tek belge; not modunda notun okunabilen ekleri.
  Uint8List? _bytes;
  final _noteAttachments =
      <({Uint8List bytes, String mimeType, String fileName})>[];
  bool _busy = false;
  bool _ready = false;
  String? _loadError;

  bool get _noteMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(attachmentRepositoryProvider);
    final notSynced = context.l10n.attachmentNotSynced;
    try {
      if (_noteMode) {
        // Notun ekleri bağlama katılır; okunamayan ek sessizce atlanır —
        // notun metniyle sohbet yine de çalışır.
        for (final a in widget.note!.attachments) {
          if (a.kind == AttachmentKind.audio) continue;
          final bytes = repo == null ? null : await repo.readBytes(a);
          if (bytes != null) {
            _noteAttachments.add((
              bytes: bytes,
              mimeType: a.mimeType,
              fileName: a.fileName,
            ));
          }
        }
        if (mounted) setState(() => _ready = true);
        return;
      }
      final bytes =
          repo == null ? null : await repo.readBytes(widget.attachment!);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _ready = true;
          if (bytes == null) _loadError = notSynced;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final bytes = _bytes;
    if (text.isEmpty || _busy || (!_noteMode && bytes == null)) return;
    final l10n = context.l10n;
    setState(() {
      _history.add(ChatTurn(isUser: true, text: text));
      _busy = true;
    });
    _controller.clear();
    _scrollToEnd();
    try {
      final service = ref.read(geminiServiceProvider);
      final reply = _noteMode
          ? await service.chatAboutNote(
              note: widget.note!,
              attachments: _noteAttachments,
              history: List.of(_history),
            )
          : await service.chatWithPdf(
              bytes: bytes!,
              fileName: widget.attachment!.fileName,
              history: List.of(_history),
            );
      if (mounted) {
        setState(() => _history.add(ChatTurn(isUser: false, text: reply)));
      }
    } on GeminiException catch (e) {
      if (mounted) {
        setState(() => _history.add(ChatTurn(
              isUser: false,
              text: e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
            )));
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _history.add(ChatTurn(isUser: false, text: l10n.aiError('$e'))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final title = _noteMode
        ? (widget.note!.title.trim().isEmpty
            ? l10n.noteChatTitle
            : widget.note!.title.trim())
        : widget.attachment!.fileName;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 15)),
      ),
      body: _loadError != null
          ? Center(child: Text(_loadError!))
          : !_ready
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: _history.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _noteMode
                                      ? l10n.noteChatIntro
                                      : l10n.pdfChatHint,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: scheme.onSurfaceVariant),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: _history.length + (_busy ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _history.length) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(l10n.aiThinking),
                                    ),
                                  );
                                }
                                final turn = _history[index];
                                return Align(
                                  alignment: turn.isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.sizeOf(context).width *
                                              0.8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: turn.isUser
                                          ? scheme.primaryContainer
                                          : scheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: SelectableText(turn.text),
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                onSubmitted: (_) => _send(),
                                textInputAction: TextInputAction.send,
                                decoration: InputDecoration(
                                  hintText: _noteMode
                                      ? l10n.noteChatHint
                                      : l10n.pdfChatInputHint,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _busy ? null : _send,
                              icon: const Icon(Icons.arrow_upward),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
