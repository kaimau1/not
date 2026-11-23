import '../../../app/theme/app_tokens.dart';
import '../../../app/app_frame.dart';
import '../../notes/presentation/note_link_ui.dart' show noteLinkLabel;
import '../../notes/presentation/note_card.dart' show openNoteRoute;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/media_transcriber.dart' show audioMimeOf;
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../../notes/data/notes_repository.dart' show notesStreamProvider;
import '../../notes/presentation/editor/audio_recorder_sheet.dart';
import '../data/ai_report.dart';
import 'ai_result_note.dart';
import '../data/gemini_service.dart';
import 'assistant_confirm.dart';
import 'chat_controller.dart';
import '../../../core/friendly_error.dart';
import '../../../core/a11y/chip_roles.dart';
import '../../../core/app_icons.dart';
import '../../auth/presentation/account_required.dart';

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

  /// Kapsamın gerektirdiği veriyi (ek baytları) TEMBEL yükler.
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
    } on GeminiException catch (e) {
      if (mounted) {
        setState(
          () => _loadError = aiErrorText(context.l10n, e),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = aiErrorText(context.l10n, e));
    }
  }

  Future<void> _send([String? spoken]) async {
    if (!ensureAiReady(context, ref)) return;
    final text = (spoken ?? _controller.text).trim();
    final busy = _scope == ChatScope.all ? ref.read(chatProvider).busy : _busy;
    if (text.isEmpty || busy) return;
    _controller.clear();
    await _ask(text);
  }

  /// Öneri çipi: kipi gerekiyorsa değiştirip hazır soruyu sorar.
  Future<void> _suggest(ChatMode mode, String prompt) async {
    if (!ensureAiReady(context, ref)) return;
    if (_isBusy) return;
    if (_mode != mode) setState(() => _mode = mode);
    await _ask(prompt);
  }

  Future<void> _ask(String text) async {
    final l10n = context.l10n;
    _scrollToEnd();
    if (_scope == ChatScope.all) {
      await ref
          .read(chatProvider.notifier)
          .send(
            text,
            describeError: (e) => aiErrorText(l10n, e),
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
        );
      } else {
        reply = await service.chatAboutNote(
          note: widget.note!,
          attachments: _noteFiles ?? const [],
          history: turns,
        );
      }
    } on GeminiException catch (e) {
      reply = aiErrorText(l10n, e);
    } catch (e) {
      reply = aiErrorText(l10n, e);
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
    if (!ensureAiReady(context, ref)) return;
    final l10n = context.l10n;
    final result = await showAudioRecorderSheet(context);
    if (result == null) return;
    try {
      final bytes =
          result.bytes ?? await File(result.path).readAsBytes();
      if (!kIsWeb && result.path.isNotEmpty) {
        File(result.path).delete().ignore();
      }
      final mime = audioMimeOf(bytes, result.mimeType ?? 'audio/mp4');
      final text = await ref
          .read(geminiServiceProvider)
          .transcribeAudio(bytes, mime);
      if (mounted && text.trim().isNotEmpty) await _send(text);
    } catch (e) {
      if (!mounted) return;
      final message = e is GeminiException
          ? aiErrorText(l10n, e)
          : aiErrorText(l10n, e);
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
          duration: AppMotion.of(context, AppMotion.short),
          curve: AppMotion.curveOf(context, AppMotion.standard),
        );
      }
    });
  }

  /// Sorunlu yanıtı bildir (Play üretken AI politikası; PL3 b): yalnız
  /// yerel günlük, metin gönderilmez ([AiReportService]).
  void _report(ChatTurn turn) {
    ref
        .read(aiReportServiceProvider)
        .report(content: turn.text, source: 'chat:${_scope.name}');
    ScaffoldMessenger.of(context).showMessage(context.l10n.aiReportThanks);
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
      appBar: HomeInBar(appBar: AppBar(title: Text(l10n.chatTitle))),
      body: Column(
        children: [
          // KAPSAM çipleri (AI-S3): neyle konuşulduğu tek bakışta.
          // Eski Soru-cevap/Beyin fırtınası çipleri ve _OutlineBar kalktı;
          // notla sohbette doğrudan _NoteSuggestions öneri düğmeleri kullanılır.
          if (_scopes.length > 1)
            SizedBox(
              height: kMinInteractiveDimension,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
                children: [
                  for (final s in _scopes)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                      child: radioChip(ChoiceChip(
                        key: ValueKey('chat-scope-${s.name}'),
                        label: Text(switch (s) {
                          ChatScope.all => l10n.chatScopeAll,
                          ChatScope.note => l10n.chatScopeNote,
                          ChatScope.document => l10n.chatScopeDoc,
                        }),
                        selected: _scope == s,
                        onSelected: (_) => _setScope(s),
                      )),
                    ),
                ],
              ),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _hint(l10n),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          // ÖNERİ ÇİPLERİ (AI-S2 eki, PLAN §1.6 A1): "ana hat"
                          // ve "beyin fırtınası" ayrı yetenekler yerine bu
                          // notla sohbetin ilk adımı. Yalnız sohbet boşken.
                          if (_scope == ChatScope.note && !busy) ...[
                            const SizedBox(height: AppSpace.l),
                            _NoteSuggestions(onPick: _suggest),
                          ],
                          // BELGEYE SOR (PLAN §1.6 A4): Özet = ilk önerilen
                          // soru; ardından ana noktalar ve tarih/görevler.
                          if (_scope == ChatScope.document &&
                              !busy &&
                              _loadError == null) ...[
                            const SizedBox(height: AppSpace.l),
                            _DocumentSuggestions(onPick: _send),
                          ],
                        ],
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
                        showPageCitations: _scope == ChatScope.document,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PL3 (b): yanıt geldiyse "AI yanılabilir" (bildir düğmesi
                  // her yanıtın yanında).
                  if (turns.any((t) => !t.isUser))
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpace.xs),
                      child: AiResultNote(),
                    ),
                  Row(
                children: [
                  if (_scope == ChatScope.all) ...[
                    IconButton.filledTonal(
                      tooltip: l10n.voiceCommand,
                      onPressed: busy ? null : _voiceInput,
                      icon: const Icon(AppIcons.voiceCommand),
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
    this.showPageCitations = false,
  });

  final ChatTurn turn;
  final ValueChanged<ChatTurn> onReport;

  /// Beyin fırtınasında fikri nota ekler; null ise düğme yok.
  final ValueChanged<String>? onAdd;
  final bool added;
  final bool showPageCitations;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final add = onAdd;
    final pages = !turn.isUser && showPageCitations
        ? extractPdfPageCitations(turn.text)
        : const <int>[];
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
          // KAYNAK NOTLAR (F18.18): yanıtın dayandığı notlar, dokununca açılır.
          if (!turn.isUser && turn.sources.isNotEmpty)
            _SourceChips(ids: turn.sources),
          // BELGE SAYFA KAYNAKLARI (PLAN §1.6 A4): yanıtta geçen sayfa atıfları.
          if (pages.isNotEmpty) _PageCitationChips(pages: pages),
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
                    color: scheme.onSurfaceVariant.withValues(alpha: AppAlpha.muted),
                  ),
                  onPressed: () => onReport(turn),
                ),
              ],
            ),
    );
  }
}

class _SourceChips extends ConsumerWidget {
  const _SourceChips({required this.ids});
  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
    final byId = {for (final n in notes) n.id: n};
    final found = [for (final id in ids) ?byId[id]];
    if (found.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final n in found)
            ActionChip(
              avatar: const Icon(Icons.sticky_note_2_outlined, size: 14),
              label: Text(
                noteLinkLabel(n, l10n.remindersUntitled),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () => openNoteRoute(context, n),
            ),
        ],
      ),
    );
  }
}

/// Notla sohbetin öneri çipleri (AI-S2/S3): Ana hat · Fikir ver · Eksikleri
/// bul. "Fikir ver" beyin fırtınası kipinde sorulur (yeni fikir üretir); öteki
/// ikisi notun kendisinden yanıtlanır.
class _NoteSuggestions extends StatelessWidget {
  const _NoteSuggestions({required this.onPick});

  final void Function(ChatMode mode, String prompt) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpace.s,
      runSpacing: AppSpace.s,
      children: [
        for (final (key, icon, label, mode, prompt) in [
          (
            'outline',
            Icons.format_list_bulleted,
            l10n.chatSuggestOutline,
            ChatMode.qa,
            l10n.chatPromptOutline,
          ),
          (
            'ideas',
            Icons.lightbulb_outline,
            l10n.chatSuggestIdeas,
            ChatMode.brainstorm,
            l10n.chatPromptIdeas,
          ),
          (
            'gaps',
            Icons.rule,
            l10n.chatSuggestGaps,
            ChatMode.qa,
            l10n.chatPromptGaps,
          ),
        ])
          // Düğme rolü (F14.3): öneri bir eylemdir, seçim değil.
          OutlinedButton.icon(
            key: ValueKey('chat-suggest-$key'),
            icon: Icon(icon, size: AppIconSize.xs, color: scheme.primary),
            label: Text(label),
            onPressed: () => onPick(mode, prompt),
          ),
      ],
    );
  }
}

/// Belgeye sor öneri düğmeleri (PLAN §1.6 A4): Özet = ilk önerilen soru.
class _DocumentSuggestions extends StatelessWidget {
  const _DocumentSuggestions({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpace.s,
      runSpacing: AppSpace.s,
      children: [
        for (final (key, icon, label, prompt) in [
          (
            'summary',
            Icons.summarize_outlined,
            l10n.docSuggestSummary,
            l10n.docPromptSummary,
          ),
          (
            'keypoints',
            Icons.format_list_bulleted,
            l10n.docSuggestKeyPoints,
            l10n.docPromptKeyPoints,
          ),
          (
            'actions',
            Icons.event_note_outlined,
            l10n.docSuggestActions,
            l10n.docPromptActions,
          ),
        ])
          OutlinedButton.icon(
            key: ValueKey('chat-doc-suggest-$key'),
            icon: Icon(icon, size: AppIconSize.xs, color: scheme.primary),
            label: Text(label),
            onPressed: () => onPick(prompt),
          ),
      ],
    );
  }
}

/// PDF yanıtındaki sayfa numaralarını kompakt kaynak rozeti olarak gösterir (A4).
class _PageCitationChips extends StatelessWidget {
  const _PageCitationChips({required this.pages});

  final List<int> pages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s),
      child: Wrap(
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xs,
        children: [
          for (final page in pages.take(8))
            Container(
              key: ValueKey('chat-page-citation-$page'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.xxs,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: AppIconSize.xs,
                    color: scheme.primary,
                  ),
                  Text(
                    l10n.docPageCitation(page),
                    style: AppText.of(theme).badge.copyWith(
                      color: scheme.onSurfaceVariant,
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
