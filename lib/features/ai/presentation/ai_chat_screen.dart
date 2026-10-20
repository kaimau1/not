import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/editor/audio_recorder_sheet.dart';
import '../data/ai_report.dart';
import '../data/gemini_service.dart';
import 'assistant_confirm.dart';
import 'chat_controller.dart';

/// Sohbetin kapsamı: neyle konuşuluyor.
enum ChatScope {
  /// Bütün notlar — araç çağrılı asistan (not ekler, hatırlatıcı kurar).
  /// Yapay Zekâ sayfasındaki sohbet kartıyla AYNI konuşma ([chatProvider]).
  all,

  /// Açık not: gövdesi + okunabilen ekleri.
  note,

  /// Notun (ya da verilen) PDF belgesi.
  document,
}

/// Sohbetin kipi. Beyin fırtınası yalnız not kapsamında: AI önce ana hat
/// çıkarır, beğenilen fikir tek dokunuşla nota eklenir.
enum ChatMode { qa, brainstorm }

/// **TEK SOHBET MOTORU** (F3.3): eskiden ayrı beş yüzey vardı (Sohbet
/// ekranı, merkez sohbet kartı, Belge sohbeti, Beyin fırtınası, AI levhası
/// sohbeti). Artık tek ekran; üstte kapsam çipi (Tüm notlar / Bu not / Bu
/// belge) ve not kapsamında kip (Soru-cevap / Beyin fırtınası). Merkez kart
/// bu ekranın "Tüm notlar" konuşmasını gösterir.
///
/// Her kapsam/kip kendi geçmişini tutar: çipler arasında gezinmek konuşmayı
/// silmez.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({
    super.key,
    this.note,
    this.document,
    this.initialScope,
    this.initialMode = ChatMode.qa,
    this.onAddToNote,
  });

  /// Not içinden açıldıysa not; null ise yalnız "Tüm notlar".
  final Note? note;

  /// Belge kapsamının PDF'i. null ise notun ilk PDF eki.
  final Attachment? document;

  final ChatScope? initialScope;
  final ChatMode initialMode;

  /// Beyin fırtınasında bir fikri nota ekler; null ise "Ekle" çizilmez.
  final ValueChanged<String>? onAddToNote;

  static Future<void> open(
    BuildContext context, {
    Note? note,
    Attachment? document,
    ChatScope? scope,
    ChatMode mode = ChatMode.qa,
    ValueChanged<String>? onAddToNote,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AiChatScreen(
        note: note,
        document: document,
        initialScope: scope,
        initialMode: mode,
        onAddToNote: onAddToNote,
      ),
    ),
  );

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  late ChatScope _scope;
  late ChatMode _mode;

  /// Not/belge kapsamlarının yerel geçmişleri ("Tüm notlar" [chatProvider]'da).
  final _histories = <(ChatScope, ChatMode), List<ChatTurn>>{};
  bool _busy = false;

  /// Not kapsamında okunabilen ekler; belge kapsamında PDF baytları.
  List<({Uint8List bytes, String mimeType, String fileName})>? _noteFiles;
  Uint8List? _docBytes;
  String? _loadError;

  /// Beyin fırtınası ana hattı.
  List<String>? _outline;
  bool _outlineLoading = false;
  String? _focusHeading;
  final _added = <String>{};

  Attachment? get _document =>
      widget.document ??
      widget.note?.attachments
          .where((a) => a.kind == AttachmentKind.pdf)
          .firstOrNull;

  List<ChatScope> get _scopes => [
    ChatScope.all,
    if (widget.note != null) ChatScope.note,
    if (_document != null) ChatScope.document,
  ];

  @override
  void initState() {
    super.initState();
    _scope =
        widget.initialScope ??
        (widget.document != null
            ? ChatScope.document
            : widget.note != null
            ? ChatScope.note
            : ChatScope.all);
    _mode = _scope == ChatScope.note ? widget.initialMode : ChatMode.qa;
    _prepare();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ChatTurn> get _turns => _scope == ChatScope.all
      ? ref.watch(chatProvider).turns
      : _histories[(_scope, _mode)] ??= <ChatTurn>[];

  bool get _isBusy =>
      _scope == ChatScope.all ? ref.watch(chatProvider).busy : _busy;

  void _setScope(ChatScope scope) {
    setState(() {
      _scope = scope;
      if (scope != ChatScope.note) _mode = ChatMode.qa;
      _loadError = null;
    });
    _prepare();
  }

  void _setMode(ChatMode mode) {
    setState(() => _mode = mode);
    _prepare();
  }

  /// Kapsamın gerektirdiği veriyi (ek baytları, ana hat) TEMBEL yükler.
  Future<void> _prepare() async {
    final repo = ref.read(attachmentRepositoryProvider);
    final note = widget.note;
    try {
      if (_scope == ChatScope.note && _noteFiles == null && note != null) {
        final files = <({Uint8List bytes, String mimeType, String fileName})>[];
        for (final a in note.attachments) {
          // Ses ve sunum Gemini'ye ham gönderilemez; büyük/web video satır
          // içi sınırı aşar (bellekte yüzlerce MB'lık sıçrama). Atlanır,
          // notun metniyle sohbet sürer.
          if (a.kind == AttachmentKind.audio ||
              a.kind == AttachmentKind.slide ||
              (a.kind == AttachmentKind.video &&
                  (a.isWebVideo ||
                      a.sizeBytes > GeminiService.maxInlineMediaBytes))) {
            continue;
          }
          final bytes = repo == null ? null : await repo.readBytes(a);
          if (bytes != null) {
            files.add((
              bytes: bytes,
              mimeType: a.mimeType,
              fileName: a.fileName,
            ));
          }
        }
        if (mounted) setState(() => _noteFiles = files);
      }
      if (_scope == ChatScope.document && _docBytes == null) {
        final doc = _document;
        final bytes = doc == null || repo == null
            ? null
            : await repo.readBytes(doc);
        if (!mounted) return;
        setState(() {
          _docBytes = bytes;
          if (bytes == null) _loadError = context.l10n.attachmentNotSynced;
        });
      }
      if (_scope == ChatScope.note &&
          _mode == ChatMode.brainstorm &&
          _outline == null &&
          !_outlineLoading &&
          note != null) {
        setState(() => _outlineLoading = true);
        final outline = await ref.read(geminiServiceProvider).outlineNote(note);
        if (mounted) setState(() => _outline = outline);
      }
    } on GeminiException catch (e) {
      if (mounted) {
        setState(
          () => _loadError = e.isAuthError
              ? context.l10n.aiNoApiKey
              : context.l10n.aiError(e.message),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = context.l10n.aiError('$e'));
    } finally {
      if (mounted && _outlineLoading) setState(() => _outlineLoading = false);
    }
  }

  Future<void> _send([String? spoken]) async {
    final text = (spoken ?? _controller.text).trim();
    final busy = _scope == ChatScope.all ? ref.read(chatProvider).busy : _busy;
    if (text.isEmpty || busy) return;
    _controller.clear();
    await _ask(text);
  }

  Future<void> _pickHeading(String heading) async {
    setState(() => _focusHeading = heading);
    await _ask(heading);
  }

  Future<void> _ask(String text) async {
    final l10n = context.l10n;
    _scrollToEnd();
    if (_scope == ChatScope.all) {
      await ref
          .read(chatProvider.notifier)
          .send(
            text,
            noApiKeyText: l10n.aiNoApiKey,
            errorText: l10n.aiError,
            historyLabel: l10n.aiHistoryQuestion,
            confirmDelete: (title) => confirmAssistantDelete(context, title),
          );
      if (mounted) _scrollToEnd();
      return;
    }
    final history = _turns;
    final scope = _scope;
    final mode = _mode;
    setState(() {
      history.add(ChatTurn(isUser: true, text: text));
      _busy = true;
    });
    String reply;
    try {
      final service = ref.read(geminiServiceProvider);
      final turns = List.of(history);
      if (scope == ChatScope.document) {
        final bytes = _docBytes;
        if (bytes == null) throw GeminiException(l10n.attachmentNotSynced);
        reply = await service.chatWithPdf(
          bytes: bytes,
          fileName: _document!.fileName,
          history: turns,
        );
      } else if (mode == ChatMode.brainstorm) {
        reply = await service.brainstormAboutNote(
          note: widget.note!,
          history: turns,
          focusHeading: _focusHeading,
        );
      } else {
        reply = await service.chatAboutNote(
          note: widget.note!,
          attachments: _noteFiles ?? const [],
          history: turns,
        );
      }
    } on GeminiException catch (e) {
      reply = e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message);
    } catch (e) {
      reply = l10n.aiError('$e');
    }
    if (!mounted) return;
    setState(() {
      history.add(ChatTurn(isUser: false, text: reply));
      _busy = false;
    });
    _scrollToEnd();
  }

  /// Sesli komut ("Tüm notlar"): kaydet → yazıya dök → gönder.
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
      if (mounted && text.trim().isNotEmpty) await _send(text);
    } catch (e) {
      if (!mounted) return;
      final message = e is GeminiException
          ? (e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message))
          : l10n.aiError('$e');
      ScaffoldMessenger.of(
        context,
      ).showMessage(message);
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

  /// Sorunlu yanıtı bildir (Play üretken AI politikası).
  Future<void> _report(ChatTurn turn) async {
    final messenger = ScaffoldMessenger.of(context);
    final thanks = context.l10n.aiReportThanks;
    await ref
        .read(aiReportServiceProvider)
        .report(content: turn.text, source: 'chat:${_scope.name}');
    messenger.showMessage(thanks);
  }

  void _addIdea(String text) {
    widget.onAddToNote?.call(text);
    setState(() => _added.add(text));
    ScaffoldMessenger.of(
      context,
    ).showMessage(context.l10n.brainstormAdded);
  }

  String _hint(AppLocalizations l10n) => switch ((_scope, _mode)) {
    (ChatScope.all, _) => l10n.chatHint,
    (ChatScope.document, _) => l10n.pdfChatHint,
    (ChatScope.note, ChatMode.brainstorm) => l10n.brainstormIntro,
    (ChatScope.note, ChatMode.qa) => l10n.noteChatIntro,
  };

  String _inputHint(AppLocalizations l10n) => switch ((_scope, _mode)) {
    (ChatScope.all, _) => l10n.chatInputHint,
    (ChatScope.document, _) => l10n.pdfChatInputHint,
    (ChatScope.note, ChatMode.brainstorm) => l10n.brainstormInputHint,
    (ChatScope.note, ChatMode.qa) => l10n.noteChatHint,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final turns = _turns;
    final busy = _isBusy;
    final brainstorm = _scope == ChatScope.note && _mode == ChatMode.brainstorm;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatTitle)),
      body: Column(
        children: [
          // KAPSAM + KİP çipleri: neyle, nasıl konuşulduğu tek bakışta.
          if (_scopes.length > 1 || widget.note != null)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in _scopes)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: ChoiceChip(
                        key: ValueKey('chat-scope-${s.name}'),
                        label: Text(switch (s) {
                          ChatScope.all => l10n.chatScopeAll,
                          ChatScope.note => l10n.chatScopeNote,
                          ChatScope.document => l10n.chatScopeDoc,
                        }),
                        selected: _scope == s,
                        onSelected: (_) => _setScope(s),
                      ),
                    ),
                  if (_scope == ChatScope.note) ...[
                    const VerticalDivider(width: 16, indent: 12, endIndent: 12),
                    for (final m in ChatMode.values)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: ChoiceChip(
                          key: ValueKey('chat-mode-${m.name}'),
                          label: Text(switch (m) {
                            ChatMode.qa => l10n.chatModeQa,
                            ChatMode.brainstorm => l10n.chatModeBrainstorm,
                          }),
                          selected: _mode == m,
                          onSelected: (_) => _setMode(m),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          if (brainstorm &&
              (_outlineLoading || (_outline?.isNotEmpty ?? false)))
            _OutlineBar(
              loading: _outlineLoading,
              headings: _outline ?? const [],
              focused: _focusHeading,
              onPick: _pickHeading,
            ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_loadError!, style: TextStyle(color: scheme.error)),
            ),
          Expanded(
            child: turns.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _hint(l10n),
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
                    itemCount: turns.length + (busy ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == turns.length) {
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(l10n.aiThinking),
                          ),
                        );
                      }
                      return _Bubble(
                        turn: turns[index],
                        onReport: _report,
                        onAdd: brainstorm && widget.onAddToNote != null
                            ? _addIdea
                            : null,
                        added: _added.contains(turns[index].text),
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
                  if (_scope == ChatScope.all) ...[
                    IconButton.filledTonal(
                      tooltip: l10n.voiceCommand,
                      onPressed: busy ? null : _voiceInput,
                      icon: const Icon(Icons.mic_none),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: _inputHint(l10n),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l10n.folderChatSend,
                    onPressed: busy ? null : _send,
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

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.turn,
    required this.onReport,
    required this.onAdd,
    required this.added,
  });

  final ChatTurn turn;
  final ValueChanged<ChatTurn> onReport;

  /// Beyin fırtınasında fikri nota ekler; null ise düğme yok.
  final ValueChanged<String>? onAdd;
  final bool added;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final add = onAdd;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
      ),
      decoration: BoxDecoration(
        color: turn.isUser
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(turn.text),
          if (!turn.isUser && add != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: added
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.brainstormAdded,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => add(turn.text),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(l10n.brainstormAddIdea),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ),
            ),
        ],
      ),
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
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  onPressed: () => onReport(turn),
                ),
              ],
            ),
    );
  }
}

/// Beyin fırtınasının ana hattı: yatay kaydırılan başlık çipleri.
class _OutlineBar extends StatelessWidget {
  const _OutlineBar({
    required this.loading,
    required this.headings,
    required this.focused,
    required this.onPick,
  });

  final bool loading;
  final List<String> headings;
  final String? focused;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              context.l10n.brainstormOutlineTitle,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final heading in headings)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(heading),
                            selected: focused == heading,
                            onSelected: (_) => onPick(heading),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
