import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/domain/attachment.dart';
import '../data/gemini_service.dart';

/// Ekli PDF'e soru sorma ekranı ("bu sözleşmede cezai şart var mı?").
class PdfChatScreen extends ConsumerStatefulWidget {
  const PdfChatScreen({super.key, required this.attachment});

  final Attachment attachment;

  @override
  ConsumerState<PdfChatScreen> createState() => _PdfChatScreenState();
}

class _PdfChatScreenState extends ConsumerState<PdfChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _history = <ChatTurn>[];
  Uint8List? _bytes;
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final repo = ref.read(attachmentRepositoryProvider);
    try {
      final bytes = repo == null ? null : await repo.readBytes(widget.attachment);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          if (bytes == null) _loadError = context.l10n.attachmentNotSynced;
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
    if (text.isEmpty || _busy || bytes == null) return;
    final l10n = context.l10n;
    setState(() {
      _history.add(ChatTurn(isUser: true, text: text));
      _busy = true;
    });
    _controller.clear();
    _scrollToEnd();
    try {
      final reply = await ref.read(geminiServiceProvider).chatWithPdf(
            bytes: bytes,
            fileName: widget.attachment.fileName,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.attachment.fileName,
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: _loadError != null
          ? Center(child: Text(_loadError!))
          : _bytes == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: _history.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  l10n.pdfChatHint,
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
                                  hintText: l10n.pdfChatInputHint,
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
