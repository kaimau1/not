import 'package:flutter/material.dart';

import '../../../../core/widgets/tag_pill.dart';

/// Üst çubukta, düzenleme tarihinin SOLUNDA duran etiketler (kullanıcı
/// isteği 2026-11-05: "etiketlerin üst satırdaki tarih saatin solunda
/// görülmesi"). Gövdedeki çip şeridi yalnız etiket için bir satır
/// harcıyordu; burada küçük hap, sığmayan yana kayar. Dokununca küçük menü:
/// "Etiketi kaldır" (eski çipin × işi).
class EditorBarTags extends StatelessWidget {
  const EditorBarTags({
    super.key,
    required this.tags,
    this.accent,
    required this.removeLabel,
    required this.onRemove,
  });

  final List<String> tags;

  /// Renkli notta notun koyu tonu; null = temanın etiket hapı.
  final Color? accent;
  final String removeLabel;
  final ValueChanged<String> onRemove;

  Future<void> _menu(BuildContext context, String tag) async {
    final box = context.findRenderObject();
    final overlay = Overlay.of(context).context.findRenderObject();
    if (box is! RenderBox || overlay is! RenderBox) return;
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    final picked = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(rect.left, rect.bottom, rect.width, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            children: [
              const Icon(Icons.close, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '$removeLabel · #$tag',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (picked == true) onRemove(tag);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('editor-bar-tags'),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, tag) in tags.indexed)
            Padding(
              padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 4),
              child: Builder(
                builder: (pillContext) => Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    key: ValueKey('editor-bar-tag-$tag'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _menu(pillContext, tag),
                    // Kartla aynı dolu hap (bkz. [tagPillColors]).
                    child: TagPill(tag: tag, accent: accent, fontSize: 11.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
