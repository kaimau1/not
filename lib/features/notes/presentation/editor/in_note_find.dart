import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';

/// **NOT İÇİ CANLI ARAMA ÇUBUĞU** (kullanıcı isteği 2026-09-26: "not içi
/// aramada sayfada canlı aranmalı, ayrı bir alanda değil; altta çıksın
/// arama alanı, aranınca orayı odaklasın veya eşleşenleri açılabilir bir
/// yarım pencerede göstersin").
///
/// Eskiden arama AYRI bir levhada açılıyordu: sonuçlar bir listede
/// okunuyor, nottaki yeri hiç gösterilmiyordu. Artık çubuk editörün alt
/// çubuğunun YERİNE geçer (klavyeyle birlikte yükselir), yazdıkça eşleşmeler
/// sayfada boyanır, oklar sayfayı eşleşmeye kaydırır; liste düğmesi aynı
/// eşleşmeleri yarım pencerede sıralar ([showFindHitsSheet]).
class NoteFindBar extends StatelessWidget {
  const NoteFindBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.count,
    required this.index,
    required this.background,
    required this.onChanged,
    required this.onNext,
    required this.onPrevious,
    required this.onList,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Toplam eşleşme; [index] odaktaki eşleşmenin sırası (-1 = yok).
  final int count;
  final int index;
  final Color background;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onList;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasQuery = controller.text.trim().isNotEmpty;
    final none = hasQuery && count == 0;
    return Material(
      color: background,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  // Enter: sonraki eşleşme; klavye açık kalır.
                  onSubmitted: (_) {
                    onNext();
                    focusNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.noteSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: none
                        ? scheme.errorContainer.withValues(alpha: 0.5)
                        : scheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: hasQuery
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(end: 12),
                            child: Text(
                              count == 0 ? '0' : '${index + 1}/$count',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: none ? scheme.error : scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.findPrevious,
                visualDensity: VisualDensity.compact,
                onPressed: count > 0 ? onPrevious : null,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: l10n.findNext,
                visualDensity: VisualDensity.compact,
                onPressed: count > 0 ? onNext : null,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                tooltip: l10n.findShowAll,
                visualDensity: VisualDensity.compact,
                onPressed: hasQuery ? onList : null,
                icon: const Icon(Icons.format_list_bulleted),
              ),
              IconButton(
                tooltip: l10n.close,
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sonuç listesinde tek satır: nerede + eşleşmenin çevresi.
typedef FindHitView = ({
  String where,
  IconData icon,
  String lead,
  String hit,
  String tail,
});

/// [showFindHitsSheet]in "eklerde ve yapay zekâ ile ara" dönüşü.
const int kFindDeepSearch = -2;

/// Eşleşmeleri YARIM PENCEREDE listeler; dokunulan eşleşmenin sırasını
/// döner (sayfa oraya kayar). Pencere yukarı çekilerek büyür.
/// [kFindDeepSearch] = kullanıcı eklerin içinde / yapay zekâ ile aramak
/// istedi (eski arama levhası).
Future<int?> showFindHitsSheet(
  BuildContext context, {
  required List<FindHitView> hits,
  required int current,
  required bool canDeepSearch,
}) {
  return showAppSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scroll) {
        final l10n = context.l10n;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.findMatchCount(hits.length),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (canDeepSearch)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(sheetContext, kFindDeepSearch),
                      icon: const Icon(Icons.manage_search, size: 18),
                      label: Text(l10n.findDeepSearch),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: hits.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.noteSearchNoHit,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: hits.length,
                      itemBuilder: (context, i) {
                        final hit = hits[i];
                        return ListTile(
                          selected: i == current,
                          leading: Icon(hit.icon, size: 20),
                          title: Text(
                            hit.where,
                            style: theme.textTheme.labelMedium,
                          ),
                          subtitle: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: hit.lead),
                                TextSpan(
                                  text: hit.hit,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    backgroundColor: Colors.amber.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                TextSpan(text: hit.tail),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(sheetContext, i),
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
