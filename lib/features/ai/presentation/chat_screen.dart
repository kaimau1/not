import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/presentation/editor/audio_recorder_sheet.dart';
import '../data/ai_report.dart';
import 'chat_controller.dart';
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

  // Geçmiş ve "meşgul" durumu artık chatProvider'da: Yapay Zeka sayfasındaki
  // sohbet kartıyla AYNI konuşma sürüyor, tam ekrana geçince baştan başlamıyor.
  List<ChatTurn> get _history => ref.watch(chatProvider).turns;
  bool get _busy => ref.watch(chatProvider).busy;

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
    _controller.clear();
    _scrollToEnd();
    await ref
        .read(chatProvider.notifier)
        .send(
          text,
          noApiKeyText: l10n.aiNoApiKey,
          errorText: l10n.aiError,
        );
    if (mounted) _scrollToEnd();
  }

  // _ensureReminder chat_controller.dart'a taşındı: hatırlatıcı güvenlik ağı
  // sohbetin nereden başlatıldığından bağımsız çalışmalı.

  /// Sesli komut: kaydet → yazıya dök → doğrudan gönder.
  Future<void> _voiceInput() async {
    final l10n = context.l10n;
    final result = await showAudioRecorderSheet(context);
    if (result == null) return;
    try {
      final bytes = await File(result.path).readAsBytes();
      File(result.path).delete().ignore();
      final text = await ref
          .read(geminiServiceProvider)
          .transcribeAudio(bytes, 'audio/mp4');
      if (!mounted) return;
      if (text.trim().isNotEmpty) await _send(text);
    } on GeminiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.aiError('$e'))));
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

  /// Sorunlu asistan yanıtını bildir (Play üretken AI politikası).
  Future<void> _reportTurn(ChatTurn turn) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(aiReportServiceProvider)
        .report(content: turn.text, source: 'chat');
    messenger.showSnackBar(SnackBar(content: Text(l10n.aiReportThanks)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    // Anahtar zorunluluğu kalktı: anahtarsız kullanıcı dahili AI ile sohbet
    // eder; kota/hata durumları yanıt balonunda gösterilir.
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatTitle)),
      body: Column(
        children: [
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.chatHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(l10n.aiThinking),
                          ),
                        );
                      }
                      final turn = _history[index];
                      final bubble = Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                        ),
                        decoration: BoxDecoration(
                          color: turn.isUser
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SelectableText(turn.text),
                      );
                      return Align(
                        alignment: turn.isUser
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: turn.isUser
                            ? bubble
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(child: bubble),
                                  IconButton(
                                    tooltip: l10n.aiReport,
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.flag_outlined,
                                      size: 16,
                                      color: scheme.onSurfaceVariant.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    onPressed: () => _reportTurn(turn),
                                  ),
                                ],
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
