import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/search_fold.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../domain/attachment.dart';
import '../../domain/note_share_text.dart';
import '../viewers/bubble_layer.dart';

/// Belgedeki BÜTÜN not balonlarının tek listesi: arama, yıldız süzgeci,
/// "balona git", düzenleme ve silme.
///
/// Neden ayrı bir ekran: balonlar sayfaya dağılmış durumda ve asıl çalışma
/// aracı onlar. Dört sayfada bıraktığın altı notu görmek için sayfa sayfa
/// dolaşmak gerekiyordu; burada hepsi bir arada, hangi sayfada oldukları
/// yazıyor ve dokununca o sayfaya gidilip balon açılıyor.
///
/// Dönen değer: gidilecek balon (null = kullanıcı yalnız baktı/düzenledi).
/// Düzenleme ve silme ANINDA [BubbleController] üzerinden uygulanır — liste
/// denetleyiciyi dinlediği için ekran kendiliğinden tazelenir.
///
/// **Dışarı çıkarma (F13.1, 2026-10-31):** üst çubukta "Tümünü kopyala"
/// (görünen — aranmış/süzülmüş — balonlar, "Sayfa N — yazı" satırlarıyla)
/// ve [onAddToNote] verilmişse "Nota aktar" (editör bölmesi: her balon kendi
/// sayfasının sayfa notuna). Eskiden balon yazısı hiçbir yoldan dışarı
/// çıkmıyordu.
Future<PageBubble?> showBubblesOverview(
  BuildContext context,
  BubbleController controller, {
  ValueChanged<List<PageBubble>>? onAddToNote,
}) => Navigator.of(context).push<PageBubble>(
  MaterialPageRoute<PageBubble>(
    builder: (_) => _BubblesOverviewScreen(
      controller: controller,
      onAddToNote: onAddToNote,
    ),
  ),
);

class _BubblesOverviewScreen extends StatefulWidget {
  const _BubblesOverviewScreen({required this.controller, this.onAddToNote});

  final BubbleController controller;
  final ValueChanged<List<PageBubble>>? onAddToNote;

  @override
  State<_BubblesOverviewScreen> createState() => _BubblesOverviewScreenState();
}

class _BubblesOverviewScreenState extends State<_BubblesOverviewScreen> {
  final _search = TextEditingController();
  bool _onlyStarred = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Süzülmüş ve sıralanmış liste. Sıra: önce YILDIZLILAR (önem), sonra sayfa
  /// numarası, sonra sayfa içindeki dikey konum — yani belgeyi okurken
  /// karşılaşacağın sıra.
  List<PageBubble> _visible() {
    final query = foldForSearch(_search.text.trim());
    final out = [
      for (final b in widget.controller.bubbles)
        if (!_onlyStarred || b.starred)
          if (query.isEmpty || foldForSearch(b.text).contains(query)) b,
    ];
    out.sort((a, b) {
      if (a.starred != b.starred) return a.starred ? -1 : 1;
      if (a.page != b.page) return a.page.compareTo(b.page);
      return a.y.compareTo(b.y);
    });
    return out;
  }

  Future<void> _edit(PageBubble bubble) async {
    final controller = TextEditingController(text: bubble.text);
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.bubbleEdit),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(hintText: context.l10n.bubbleHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.l10n.bubbleSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null) return;
    widget.controller
      ..update(bubble.copyWith(text: saved))
      ..save();
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showMessage(message);

  Future<void> _copyAll() async {
    final l10n = context.l10n;
    final text = bubblesShareText(_visible(), pageLabel: l10n.pageLabel);
    if (text.isEmpty) {
      _snack(l10n.bubblesEmpty);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack(l10n.copied);
  }

  void _addToNote() {
    final l10n = context.l10n;
    final bubbles = orderedTextBubbles(_visible());
    if (bubbles.isEmpty) {
      _snack(l10n.bubblesEmpty);
      return;
    }
    widget.onAddToNote!(bubbles);
    _snack(l10n.bubblesToNoteDone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bubblesOverviewTitle),
        actions: [
          IconButton(
            key: const ValueKey('bubbles-copy-all'),
            tooltip: l10n.bubblesCopyAll,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copyAll,
          ),
          if (widget.onAddToNote != null)
            IconButton(
              key: const ValueKey('bubbles-to-note'),
              tooltip: l10n.bubblesToNote,
              icon: const Icon(Icons.note_add_outlined),
              onPressed: _addToNote,
            ),
          IconButton(
            tooltip: l10n.bubbleStarredOnly,
            isSelected: _onlyStarred,
            icon: Icon(_onlyStarred ? Icons.star : Icons.star_border),
            onPressed: () => setState(() => _onlyStarred = !_onlyStarred),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final items = _visible();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.bubbleSearchHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.clearSearch,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        widget.controller.bubbles.isEmpty
                            ? l10n.bubblesEmpty
                            : l10n.bubblesNoMatch,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bubble = items[index];
                      final text = bubble.text.trim();
                      return ListTile(
                        // "Balona git": ekran kapanır, çağıran o sayfaya gidip
                        // balonu açar (bkz. showBubblesOverview dönüş değeri).
                        onTap: () => Navigator.pop(context, bubble),
                        leading: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: BubbleController.displayColor(bubble),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            bubble.isHighlight
                                ? Icons.format_color_text
                                : Icons.chat_bubble_outline,
                            size: 16,
                            // Koyu (premium) palette beyaz, fosforlu vurguda
                            // koyu simge.
                            color:
                                BubbleController.displayColor(
                                      bubble,
                                    ).computeLuminance() >
                                    0.36
                                ? Colors.black87
                                : Colors.white,
                          ),
                        ),
                        title: Text(
                          text.isEmpty ? l10n.bubbleNoText : text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontStyle: text.isEmpty ? FontStyle.italic : null,
                            color: text.isEmpty ? scheme.onSurfaceVariant : null,
                          ),
                        ),
                        subtitle: Text(l10n.pdfPage(bubble.page)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.bubbleStar,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                bubble.starred ? Icons.star : Icons.star_border,
                                color: bubble.starred ? Colors.amber : null,
                              ),
                              onPressed: () =>
                                  widget.controller.toggleStar(bubble.id),
                            ),
                            IconButton(
                              tooltip: l10n.bubbleEdit,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(bubble),
                            ),
                            IconButton(
                              tooltip: l10n.delete,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  widget.controller.remove(bubble.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
