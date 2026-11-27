import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/l10n_ext.dart';
import '../../features/notes/presentation/notes_providers.dart';
import '../theme/app_tokens.dart';

/// Masaüstü web çalışma alanı üst başlığı: bölüm adı ve not sayısı, ortada
/// Ctrl+K ipuçlu komut arama çubuğu, sağda ızgara/liste, sütun yoğunluğu,
/// süzgeç ve ek menü. Hesap düğmesi soldaki kenar çubuğundadır.
class WebDashboardHeader extends ConsumerWidget {
  const WebDashboardHeader({
    super.key,
    required this.title,
    required this.noteCount,
    required this.scrolled,
    required this.searchController,
    required this.searchFocus,
    required this.filterButton,
    required this.onOpenMenu,
    required this.showGridControls,
  });

  final String title;
  final int? noteCount;
  final ValueListenable<bool> scrolled;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final Widget filterButton;
  final VoidCallback onOpenMenu;
  final bool showGridControls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);
    final query = ref.watch(searchQueryProvider);
    final isList = ref.watch(noteListViewProvider);
    final manualColumns = ref.watch(gridColumnsProvider);

    return ValueListenableBuilder<bool>(
      valueListenable: scrolled,
      builder: (context, isScrolled, child) => Container(
        key: const ValueKey('web-dashboard-header'),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: isScrolled
              ? Border(bottom: BorderSide(color: tokens.hairline))
              : null,
        ),
        child: child,
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    key: const ValueKey('web-dashboard-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.screenTitle,
                  ),
                ),
                if (noteCount != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpace.s,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s,
                          vertical: AppSpace.xs,
                        ),
                        child: Text(
                          l10n.webNoteCount(noteCount!),
                          style: text.meta,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.l),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LayoutBuilder(
                  builder: (context, box) => ListenableBuilder(
                  listenable: searchFocus,
                  builder: (context, _) {
                    final focused = searchFocus.hasFocus;
                    // DAR SAYFA (kullanıcı 2026-11-24): Ctrl+K rozeti dar
                    // alanda yazı alanını sıfıra indirmesin.
                    final showKbd = box.maxWidth >= 300;
                    return Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: tokens.card,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                        border: Border.all(
                          color: focused ? scheme.primary : tokens.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: searchFocus.requestFocus,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpace.m,
                                end: AppSpace.s,
                              ),
                              child: Icon(
                                AppIcons.search,
                                size: AppIconSize.s,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              focusNode: searchFocus,
                              textAlignVertical: TextAlignVertical.center,
                              style: text.body,
                              textInputAction: TextInputAction.search,
                              onChanged: (value) => ref
                                  .read(searchQueryProvider.notifier)
                                  .set(value),
                              onTapOutside: (_) {
                                ref
                                    .read(searchHistoryProvider.notifier)
                                    .remember(query);
                                searchFocus.unfocus();
                              },
                              onSubmitted: (value) => ref
                                  .read(searchHistoryProvider.notifier)
                                  .remember(value),
                              decoration: InputDecoration(
                                filled: false,
                                hintText: l10n.searchHint,
                                hintStyle: text.label.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppSpace.s,
                                ),
                              ),
                            ),
                          ),
                          if (query.isNotEmpty)
                            IconButton(
                              tooltip: l10n.close,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.close,
                                size: AppIconSize.s,
                              ),
                              onPressed: () {
                                searchController.clear();
                                ref.read(searchQueryProvider.notifier).set('');
                              },
                            )
                          else if (!focused && showKbd)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpace.xs,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.xs,
                                  ),
                                  border: Border.all(color: tokens.hairline),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.s,
                                    vertical: AppSpace.xxs,
                                  ),
                                  child: Text(
                                    'Ctrl+K',
                                    style: text.badge.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.l),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showGridControls) ...[
                IconButton(
                  key: const ValueKey('web-view-toggle'),
                  tooltip: isList ? l10n.webViewGrid : l10n.webViewList,
                  icon: Icon(
                    isList
                        ? Icons.grid_view_outlined
                        : Icons.view_agenda_outlined,
                    size: AppIconSize.m,
                  ),
                  onPressed: () =>
                      ref.read(noteListViewProvider.notifier).toggle(),
                ),
                if (!isList)
                  PopupMenuButton<int>(
                    key: const ValueKey('web-columns-menu'),
                    tooltip: l10n.webColumnsMenu,
                    icon: const Icon(
                      Icons.view_column_outlined,
                      size: AppIconSize.m,
                    ),
                    initialValue: manualColumns,
                    onSelected: (value) =>
                        ref.read(gridColumnsProvider.notifier).set(value),
                    itemBuilder: (context) => [
                      CheckedPopupMenuItem<int>(
                        value: 0,
                        checked: manualColumns == 0,
                        child: Text(l10n.webColumnsAuto),
                      ),
                      for (final count in const [2, 3, 4])
                        CheckedPopupMenuItem<int>(
                          value: count,
                          checked: manualColumns == count,
                          child: Text(l10n.webColumnsCount(count)),
                        ),
                    ],
                  ),
                const SizedBox(width: AppSpace.xs),
              ],
              filterButton,
              const SizedBox(width: AppSpace.xs),
              IconButton(
                tooltip: l10n.more,
                icon: const Icon(Icons.more_vert, size: AppIconSize.m),
                onPressed: onOpenMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
