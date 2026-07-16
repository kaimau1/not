import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/presentation/editor/audio_recorder_sheet.dart';
import '../data/api_key_store.dart';
import '../data/assistant_service.dart';
import '../data/gemini_service.dart';

/// Notlar üzerinde yapay zeka asistanı: soru sorabilir ("geçen ay yazdığım
/// tarif neydi?") veya iş yaptırabilirsin ("yarın 9'a diş randevusu notu
/// ekle, hatırlatıcılı"). Mikrofonla sesli komut da verilebilir.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _history = <ChatTurn>[];
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? spokenText]) async {
    final text = (spokenText ?? _controller.text).trim();
    if (text.isEmpty || _busy) return;
    final l10n = context.l10n;
    setState(() {
      _history.add(ChatTurn(isUser: true, text: text));
      _busy = true;
    });
    _controller.clear();
    _scrollToEnd();
    try {
      final notes = ref.read(notesStreamProvider).value ?? const [];
      final assistant = ref.read(assistantServiceProvider);
      final reply = await ref.read(geminiServiceProvider).assistantChat(
            notesContext: assistant.buildNotesContext(notes),
            history: List.of(_history),
            onToolCall: assistant.execute,
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
        setState(() =>
            _history.add(ChatTurn(isUser: false, text: l10n.aiError('$e'))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToEnd();
      }
    }
  }

  /// Sesli komut: kaydet → yazıya dök → doğrudan gönder.
  Future<void> _voiceInput() async {
    final l10n = context.l10n;
    final result = await showAudioRecorderSheet(context);
    if (result == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await File(result.path).readAsBytes();
      File(result.path).delete().ignore();
      final text = await ref
          .read(geminiServiceProvider)
          .transcribeAudio(bytes, 'audio/mp4');
      if (!mounted) return;
      setState(() => _busy = false);
      if (text.trim().isNotEmpty) await _send(text);
    } on GeminiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.aiError('$e'))));
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
    final hasKey = (ref.watch(geminiApiKeyProvider).value ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatTitle)),
      body: !hasKey
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.aiNoApiKey),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.push('/settings'),
                    child: Text(l10n.settings),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _history.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.chatHint,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
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
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.8,
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
                        IconButton.filledTonal(
                          tooltip: l10n.voiceCommand,
                          onPressed: _busy ? null : _voiceInput,
                          icon: const Icon(Icons.mic_none),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onSubmitted: (_) => _send(),
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText: l10n.chatInputHint,
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
