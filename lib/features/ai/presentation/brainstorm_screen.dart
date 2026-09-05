import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/domain/note.dart';
import '../data/gemini_service.dart';

/// **AI İLE BERABER DÜŞÜN.**
///
/// Kullanıcı isteği 2026-08-18: "ai ile beraber düşün modu" — notun yanında
/// açılan bir beyin fırtınası paneli; AI önce bir PLAN/ANA HAT çıkarır,
/// sonra başlık başlık birlikte ilerlenir; beğenilen fikir tek dokunuşla
/// nota eklenir.
///
/// [DocChatScreen]'den bilerek AYRI bir ekran: o notun içeriğine SIKI SIKIYA
/// bağlı bir soru-cevaptır ("olmayanı uydurma"); burası GENERATİF bir
/// beyin fırtınasıdır (bkz. [GeminiService.brainstormAboutNote]) — AI yeni
/// fikir üretir, kullanıcı beğendiğini seçip nota taşır.
///
/// Telefonda tam ekran açılır (Navigator.push — notun İÇİNDEN gelinir, geri
/// tuşu nota döner); geniş ekranda [SplitShell] zaten listeyi ve notu YAN
/// YANA gösterdiği için bu ekran o düzenin üçüncü sütunu gibi okunur.
class BrainstormScreen extends ConsumerStatefulWidget {
  const BrainstormScreen({super.key, required this.note, this.onAddToNote});

  final Note note;

  /// Bir fikri doğrudan nota ekleyen geri çağırma. null ise "Ekle" düğmesi
  /// çizilmez (ör. not henüz kaydedilmemiş bir önizlemeyse).
  final ValueChanged<String>? onAddToNote;

  static Future<void> open(
    BuildContext context,
    Note note, {
    ValueChanged<String>? onAddToNote,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BrainstormScreen(note: note, onAddToNote: onAddToNote),
    ),
  );

  @override
  ConsumerState<BrainstormScreen> createState() => _BrainstormScreenState();
}

class _BrainstormScreenState extends ConsumerState<BrainstormScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _history = <ChatTurn>[];

  /// Az önce eklenen fikirler: "Ekle" düğmesi bir kez basıldıktan sonra
  /// "Eklendi" olarak donsun — kullanıcı aynı fikri iki kez eklediğini
  /// sanmasın.
  final _added = <int>{};

  List<String>? _outline;
  String? _focusHeading;
  bool _busy = false;
  bool _outlineLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOutline();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOutline() async {
    try {
      final service = ref.read(geminiServiceProvider);
      final outline = await service.outlineNote(widget.note);
      if (mounted) setState(() => _outline = outline);
    } on GeminiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.isAuthError
              ? context.l10n.aiNoApiKey
              : context.l10n.aiError(e.message),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.aiError('$e'));
    } finally {
      if (mounted) setState(() => _outlineLoading = false);
    }
  }

  /// Ana hattaki bir başlığa dokunmak: sohbeti o başlıkla başlatır/odaklar.
  /// İkinci dokunuş yalnız odağı değiştirir, geçmiş sohbeti silmez — kullanıcı
  /// başlıklar arasında gezinip hepsinin birikimini görebilir.
  Future<void> _pickHeading(String heading) async {
    setState(() {
      _focusHeading = heading;
      _history.add(ChatTurn(isUser: true, text: heading));
    });
    await _ask();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() => _history.add(ChatTurn(isUser: true, text: text)));
    await _ask();
  }

  Future<void> _ask() async {
    setState(() => _busy = true);
    _scrollToEnd();
    final l10n = context.l10n;
    try {
      final service = ref.read(geminiServiceProvider);
      final reply = await service.brainstormAboutNote(
        note: widget.note,
        history: List.of(_history),
        focusHeading: _focusHeading,
      );
      if (mounted) {
        setState(() => _history.add(ChatTurn(isUser: false, text: reply)));
      }
    } on GeminiException catch (e) {
      if (mounted) {
        setState(
          () => _history.add(
            ChatTurn(
              isUser: false,
              text: e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _history.add(ChatTurn(isUser: false, text: l10n.aiError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
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

  void _addIdea(int index, String text) {
    widget.onAddToNote?.call(text);
    setState(() => _added.add(index));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.brainstormAdded)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.brainstormTitle, style: const TextStyle(fontSize: 15)),
      ),
      body: Column(
        children: [
          // ANA HAT: AI'nin ilk adımı, çip barı olarak durur. Sohbet
          // başladıktan sonra da görünür kalır — kullanıcı başlıklar
          // arasında gezinebilsin.
          if (_outlineLoading || (_outline?.isNotEmpty ?? false))
            _OutlineBar(
              loading: _outlineLoading,
              headings: _outline ?? const [],
              focused: _focusHeading,
              onPick: _pickHeading,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            ),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.brainstormIntro,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
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
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(l10n.aiThinking),
                          ),
                        );
                      }
                      final turn = _history[index];
                      return Align(
                        alignment: turn.isUser
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
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
                              // AI fikri: tek dokunuşla nota taşınır. Kullanıcı
                              // isteği: "beğendiğin fikri tek dokunuşla nota
                              // ekle".
                              if (!turn.isUser && widget.onAddToNote != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: _added.contains(index)
                                        ? Text(
                                            l10n.brainstormAdded,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : TextButton.icon(
                                            onPressed: () =>
                                                _addIdea(index, turn.text),
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 16,
                                            ),
                                            label: Text(l10n.brainstormAddIdea),
                                            style: TextButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ),
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
                        hintText: l10n.brainstormInputHint,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l10n.folderChatSend,
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

/// AI'nin çıkardığı ana hat: yatay kaydırılan başlık çipleri.
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
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          padding: const EdgeInsets.only(right: 8),
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
