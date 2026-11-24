import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_commands.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/app_icons.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../notes/presentation/filter_sheet.dart' show showFilterSheet;
import '../../notes/presentation/notes_providers.dart';
import '../data/folder_order.dart';
import '../domain/note_folder.dart';
import 'folder_sheets.dart' show showFolderActionsSheet;
import 'folder_tile.dart' show FolderIconBox;

/// Etkin kişisel klasör seçiliyken listenin tepesinde açılan Bento üst panel.
///
/// Yumuşak geçiş için yalnızca solma + hafif kayma (`AnimatedSwitcher`)
/// kullanır; ana ekranda boy animasyonu yasaktır.
class FolderHeaderPanel extends ConsumerWidget {
  const FolderHeaderPanel({super.key, this.onCreateNote});

  /// Seçili klasörde hemen yeni not açma kapısı (verilmezse ortak yönlendirici
  /// üzerinden oluşturur).
  final VoidCallback? onCreateNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderId = ref.watch(selectedFolderProvider);
    final folders = ref.watch(visibleOrderedFoldersProvider);
    NoteFolder? active;
    if (folderId != null) {
      for (final f in folders) {
        if (f.id == folderId) {
          active = f;
          break;
        }
      }
    }
    final duration = AppMotion.of(context, AppMotion.medium);
    final enter = AppMotion.curveOf(context, AppMotion.enter);
    final exit = AppMotion.curveOf(context, AppMotion.exit);

    final Widget content;
    if (active == null) {
      content = const SizedBox.shrink(key: ValueKey('folder-header-none'));
    } else {
      final totalCount = ref.watch(
        folderNoteCountsProvider.select((m) => m[active!.id] ?? 0),
      );
      final pinnedCount = ref.watch(
        filteredNotesProvider.select((asyncNotes) {
          final list = asyncNotes.value;
          if (list == null) return 0;
          var count = 0;
          for (final n in list) {
            if (n.pinned) count++;
          }
          return count;
        }),
      );
      content = _ActiveFolderCard(
        key: ValueKey('folder-header-${active.id}'),
        folder: active,
        totalCount: totalCount,
        pinnedCount: pinnedCount,
        onCreateNote: onCreateNote,
      );
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: enter,
      switchOutCurve: exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.05),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: content,
    );
  }
}

class _ActiveFolderCard extends ConsumerWidget {
  const _ActiveFolderCard({
    super.key,
    required this.folder,
    required this.totalCount,
    required this.pinnedCount,
    this.onCreateNote,
  });

  final NoteFolder folder;
  final int totalCount;
  final int pinnedCount;
  final VoidCallback? onCreateNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);
    final accent = folder.accent;
    final bg = Color.alphaBlend(
      accent.withValues(alpha: AppAlpha.hairline),
      tokens.card,
    );
    final border = accent.withValues(alpha: AppAlpha.soft);

    void createInFolder() {
      unawaited(AppHaptics.tick());
      if (onCreateNote != null) {
        onCreateNote!();
        return;
      }
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        unawaited(createAndOpenNote(context, ref, router));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kGridInset,
        AppSpace.xs,
        kGridInset,
        AppSpace.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  FolderIconBox(
                    accent: accent,
                    icon: folder.iconData,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                folder.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.rowTitle.copyWith(
                                  fontWeight: AppWeight.strong,
                                ),
                              ),
                            ),
                            if (folder.isShared) ...[
                              const SizedBox(width: AppSpace.xs),
                              Icon(
                                AppIcons.shared,
                                size: AppIconSize.xs,
                                color: accent,
                              ),
                            ],
                            if (folder.hidden) ...[
                              const SizedBox(width: AppSpace.xs),
                              Icon(
                                Icons.visibility_off_outlined,
                                size: AppIconSize.xs,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Wrap(
                          spacing: AppSpace.s,
                          runSpacing: AppSpace.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.folderNoteCount(totalCount),
                              style: text.meta.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (pinnedCount > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.push_pin_outlined,
                                    size: AppIconSize.xs,
                                    color: accent,
                                  ),
                                  const SizedBox(width: AppSpace.xxs),
                                  Text(
                                    l10n.folderHeaderPinnedCount(pinnedCount),
                                    style: text.meta.copyWith(color: accent),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('folder-header-more'),
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.more,
                    icon: const Icon(Icons.more_vert, size: AppIconSize.m),
                    onPressed: () =>
                        unawaited(showFolderActionsSheet(context, ref, folder)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s),
              Wrap(
                spacing: AppSpace.s,
                runSpacing: AppSpace.xs,
                children: [
                  _HeaderActionPill(
                    key: const ValueKey('folder-header-new-note'),
                    icon: Icons.add_rounded,
                    label: l10n.folderNewNote,
                    accent: accent,
                    filled: true,
                    onTap: createInFolder,
                  ),
                  _HeaderActionPill(
                    key: const ValueKey('folder-header-sort'),
                    icon: Icons.tune_rounded,
                    label: l10n.folderFilterSort,
                    accent: accent,
                    onTap: () => unawaited(showFilterSheet(context)),
                  ),
                  _HeaderActionPill(
                    key: const ValueKey('folder-header-all'),
                    icon: Icons.layers_outlined,
                    label: l10n.allNotesChip,
                    accent: accent,
                    onTap: () {
                      unawaited(AppHaptics.tick());
                      ref.read(selectedFolderProvider.notifier).set(null);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionPill extends StatelessWidget {
  const _HeaderActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final bg = filled
        ? accent.withValues(alpha: AppAlpha.pressed)
        : scheme.surfaceContainerHighest.withValues(alpha: AppAlpha.soft);
    final fg = filled ? accent : scheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.xs + AppSpace.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.xs, color: fg),
              const SizedBox(width: AppSpace.xs),
              Text(
                label,
                style: text.meta.copyWith(
                  color: fg,
                  fontWeight: AppWeight.strong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
