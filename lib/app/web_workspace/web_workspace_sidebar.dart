import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_icons.dart';
import '../../core/l10n_ext.dart';
import '../../features/ai/data/ai_gate.dart';
import '../../features/auth/presentation/account_required.dart';
import '../../features/auth/presentation/account_sheet.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/folders/data/folder_activity.dart';
import '../../features/folders/data/folder_order.dart';
import '../../features/folders/data/folders_repository.dart'
    show SharedFolderRef, sharedFolderRefsProvider;
import '../../features/folders/domain/note_folder.dart';
import '../../features/folders/presentation/folder_sheets.dart'
    show showFolderActionsSheet, showFolderEditorDialog;
import '../../features/folders/presentation/shared_folder_home.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/notes/data/notes_repository.dart';
import '../../features/notes/domain/note_type.dart';
import '../../features/notes/presentation/filter_sheet.dart' show resetFilters;
import '../../features/notes/presentation/notes_providers.dart';
import '../../features/notes/presentation/quick_add_fab.dart';
import '../app_commands.dart';
import '../router.dart';
import '../split_shell.dart';
import '../theme/app_tokens.dart';
import 'web_drive_status_pill.dart';
import 'web_workspace_scope.dart';

/// Masaüstü web çalışma alanı kenar çubuğu: marka + hesap başlığı, oluşturma
/// kapıları, bölümler, canlı klasör ağacı ve alt kısımda Drive/senkron durumu.
class WebWorkspaceSidebar extends ConsumerStatefulWidget {
  const WebWorkspaceSidebar({
    super.key,
    required this.extended,
    required this.showListToggle,
    required this.forceExtended,
    this.onNavigate,
    this.onToggleExtended,
  });

  final bool extended;
  final bool showListToggle;
  final bool forceExtended;
  final VoidCallback? onNavigate;
  final VoidCallback? onToggleExtended;

  @override
  ConsumerState<WebWorkspaceSidebar> createState() =>
      _WebWorkspaceSidebarState();
}

class _WebWorkspaceSidebarState extends ConsumerState<WebWorkspaceSidebar> {
  final _addLink = LayerLink();

  void _atHome(void Function(HomeDoors doors) action) {
    openSection(GoRouter.of(context), AppSection.notes);
    final doors = homeDoors;
    if (doors != null) return action(doors);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final late = homeDoors;
      if (late != null) action(late);
    });
  }

  void _go(VoidCallback action) {
    widget.onNavigate?.call();
    action();
  }

  void _openRootNotes(GoRouter router) {
    _go(() {
      resetFilters(ref);
      goHome(ref, router);
    });
  }

  void _toggleAllNotes(GoRouter router, {required bool currentlyAllAtRoot}) {
    _go(() {
      if (currentlyAllAtRoot) {
        ref.read(showAllNotesProvider.notifier).set(false);
        return;
      }
      resetFilters(ref);
      ref.read(showAllNotesProvider.notifier).set(true);
      if (currentLocation(router) != '/') {
        goHome(ref, router);
      }
    });
  }

  void _openFolder(GoRouter router, String folderId) {
    _go(() {
      ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
      ref.read(selectedTagProvider.notifier).set(null);
      ref.read(selectedSharedFolderProvider.notifier).set(null);
      ref.read(sharedHubOnHomeProvider.notifier).set(false);
      ref.read(selectedFolderProvider.notifier).set(folderId);
      openSection(router, AppSection.notes);
    });
  }

  void _openSharedFolder(GoRouter router, SharedFolderRef share) {
    _go(() {
      ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
      ref.read(selectedTagProvider.notifier).set(null);
      ref.read(selectedFolderProvider.notifier).set(null);
      ref.read(sharedHubOnHomeProvider.notifier).set(false);
      ref.read(selectedSharedFolderProvider.notifier).set((
        ownerId: share.ownerId,
        folderId: share.folderId,
      ));
      openSection(router, AppSection.notes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);
    final router = GoRouter.of(context);
    final width = widget.extended
        ? kWebSidebarExpandedWidth
        : kWebSidebarCompactWidth;

    final shared = ref.watch(selectedSharedFolderProvider);
    final selectedFolder = ref.watch(selectedFolderProvider);
    final hubOnHome = ref.watch(sharedHubOnHomeProvider);
    final showAllNotes = ref.watch(showAllNotesProvider);
    final allNotesCount = ref.watch(allNotesCountProvider);
    final folderNoteCounts = ref.watch(folderNoteCountsProvider);
    final folders = ref.watch(visibleOrderedFoldersProvider);
    final sharedFolders =
        ref.watch(sharedFolderRefsProvider).value ?? const <SharedFolderRef>[];
    final sharedUnread = ref.watch(sharedUnreadTotalProvider);
    final aiLocked = ref.watch(aiAvailabilityProvider).looksLocked;
    final collapsed = ref.watch(listPaneCollapsedProvider);
    final anonymous = ref.watch(isAnonymousProvider);
    final canWrite =
        shared == null ||
        (sharedFolderRefOf(ref, shared)?.role ?? FolderRole.both).canWrite;

    return Material(
      key: const ValueKey('web-workspace-sidebar'),
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBrandHeader(
                context,
                l10n: l10n,
                scheme: scheme,
                text: text,
              ),
              _buildComposeBlock(
                context,
                l10n: l10n,
                scheme: scheme,
                router: router,
                canWrite: canWrite,
                inSharedFolder: shared != null,
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: router.routerDelegate,
                  builder: (context, _) {
                    final section = AppSection.of(currentLocation(router));
                    final atNotesSection = section == AppSection.notes;
                    final atRootNotes =
                        atNotesSection &&
                        selectedFolder == null &&
                        shared == null &&
                        !hubOnHome;
                    final allSelected = atRootNotes && showAllNotes;
                    return ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.extended ? AppSpace.s : AppSpace.xs,
                        vertical: AppSpace.s,
                      ),
                      children: [
                        if (widget.extended)
                          _SectionHeader(label: l10n.webWorkspaceSection),
                        _NavRow(
                          key: const ValueKey('web-nav-notes'),
                          extended: widget.extended,
                          icon: AppSection.notes.icon,
                          selectedIcon: AppSection.notes.selectedIcon,
                          label: AppSection.notes.label(context),
                          selected: atRootNotes,
                          onTap: () => _openRootNotes(router),
                        ),
                        _NavRow(
                          extended: widget.extended,
                          icon: AppSection.inbox.icon,
                          selectedIcon: AppSection.inbox.selectedIcon,
                          label: AppSection.inbox.label(context),
                          selected: section == AppSection.inbox,
                          badgeCount: sharedUnread,
                          onTap: () =>
                              _go(() => openSection(router, AppSection.inbox)),
                        ),
                        _NavRow(
                          extended: widget.extended,
                          icon: AppSection.calendar.icon,
                          selectedIcon: AppSection.calendar.selectedIcon,
                          label: AppSection.calendar.label(context),
                          selected: section == AppSection.calendar,
                          onTap: () => _go(
                            () => openSection(router, AppSection.calendar),
                          ),
                        ),
                        _NavRow(
                          extended: widget.extended,
                          icon: AppSection.ai.icon,
                          selectedIcon: AppSection.ai.selectedIcon,
                          label: AppSection.ai.label(context),
                          selected: section == AppSection.ai,
                          trailingIcon: aiLocked ? Icons.lock_outline : null,
                          trailingKey: aiLocked
                              ? const ValueKey('rail-ai-locked')
                              : null,
                          onTap: () =>
                              _go(() => openSection(router, AppSection.ai)),
                        ),
                        if (widget.extended) ...[
                          const SizedBox(height: AppSpace.m),
                          _FolderTreeHeader(
                            title: l10n.foldersTitle,
                            onNewFolder: () =>
                                unawaited(showFolderEditorDialog(context, ref)),
                            tooltip: l10n.newFolder,
                          ),
                          _FolderTreeRow(
                            key: const ValueKey('web-sidebar-all-notes'),
                            icon: Icons.folder_copy_outlined,
                            label: l10n.allNotesChip,
                            count: allNotesCount,
                            selected: allSelected,
                            onTap: () => _toggleAllNotes(
                              router,
                              currentlyAllAtRoot: allSelected,
                            ),
                          ),
                          for (final folder in folders)
                            _FolderTreeRow(
                              key: ValueKey('web-sidebar-folder-${folder.id}'),
                              icon: folder.iconData,
                              iconColor: folder.accent,
                              label: folder.name,
                              count: (folderNoteCounts[folder.id] ?? 0) > 0
                                  ? folderNoteCounts[folder.id]
                                  : null,
                              selected:
                                  atNotesSection && selectedFolder == folder.id,
                              onTap: () => _openFolder(router, folder.id),
                              onNewNote: () async {
                                final repo = ref.read(notesRepositoryProvider);
                                if (repo == null) return;
                                final id = await repo.createNote(
                                  NoteType.text,
                                  folderId: folder.id,
                                );
                                if (!context.mounted) return;
                                _openFolder(router, folder.id);
                                await router.pushNote(noteRoutePath(id));
                              },
                              onMore: () => unawaited(
                                showFolderActionsSheet(context, ref, folder),
                              ),
                            ),
                          for (final share in sharedFolders)
                            _FolderTreeRow(
                              key: ValueKey(
                                'web-sidebar-shared-${share.folderId}',
                              ),
                              icon: AppIcons.shared,
                              label: share.name,
                              selected:
                                  atNotesSection &&
                                  shared?.folderId == share.folderId &&
                                  shared?.ownerId == share.ownerId,
                              onTap: () => _openSharedFolder(router, share),
                            ),
                          const SizedBox(height: AppSpace.m),
                          _SectionHeader(label: l10n.webOrganizeSection),
                          _NavRow(
                            extended: true,
                            icon: AppSection.folders.icon,
                            selectedIcon: AppSection.folders.selectedIcon,
                            label: AppSection.folders.label(context),
                            selected: section == AppSection.folders,
                            onTap: () => _go(
                              () => openSection(router, AppSection.folders),
                            ),
                          ),
                        ] else ...[
                          _NavRow(
                            extended: false,
                            icon: AppSection.folders.icon,
                            selectedIcon: AppSection.folders.selectedIcon,
                            label: AppSection.folders.label(context),
                            selected: section == AppSection.folders,
                            badgeCount: sharedUnread,
                            onTap: () => _go(
                              () => openSection(router, AppSection.folders),
                            ),
                          ),
                        ],
                        _NavRow(
                          extended: widget.extended,
                          icon: AppSection.archive.icon,
                          selectedIcon: AppSection.archive.selectedIcon,
                          label: AppSection.archive.label(context),
                          selected: section == AppSection.archive,
                          onTap: () => _go(
                            () => openSection(router, AppSection.archive),
                          ),
                        ),
                        _NavRow(
                          extended: widget.extended,
                          icon: AppSection.trash.icon,
                          selectedIcon: AppSection.trash.selectedIcon,
                          label: AppSection.trash.label(context),
                          selected: section == AppSection.trash,
                          onTap: () =>
                              _go(() => openSection(router, AppSection.trash)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: tokens.hairline)),
                ),
                padding: EdgeInsets.all(
                  widget.extended ? AppSpace.s : AppSpace.xs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: WebDriveStatusPill(compact: !widget.extended),
                    ),
                    const SizedBox(height: AppSpace.s),
                    _NavRow(
                      extended: widget.extended,
                      icon: AppIcons.friends,
                      selectedIcon: AppIcons.friends,
                      label: l10n.friendsTitle,
                      selected: false,
                      locked: anonymous,
                      onTap: () =>
                          _go(() => openFriendsScreenOrExplain(context, ref)),
                    ),
                    _NavRow(
                      extended: widget.extended,
                      icon: Icons.keyboard_outlined,
                      selectedIcon: Icons.keyboard_outlined,
                      label: l10n.keyboardShortcuts,
                      tooltip: '${l10n.keyboardShortcuts} (Ctrl+/)',
                      selected: false,
                      onTap: () => unawaited(showShortcutsHelp(context)),
                    ),
                    if (widget.showListToggle)
                      _NavRow(
                        extended: widget.extended,
                        icon: collapsed
                            ? Icons.view_sidebar
                            : Icons.view_sidebar_outlined,
                        selectedIcon: Icons.view_sidebar,
                        label: collapsed
                            ? l10n.listPaneShow
                            : l10n.listPaneHide,
                        tooltip:
                            '${collapsed ? l10n.listPaneShow : l10n.listPaneHide} (Ctrl+\\)',
                        selected: collapsed,
                        onTap: () => ref
                            .read(listPaneCollapsedProvider.notifier)
                            .toggle(),
                      ),
                    ListenableBuilder(
                      listenable: router.routerDelegate,
                      builder: (context, _) {
                        final section = AppSection.of(currentLocation(router));
                        return _NavRow(
                          extended: widget.extended,
                          icon: AppSection.settings.icon,
                          selectedIcon: AppSection.settings.selectedIcon,
                          label: AppSection.settings.label(context),
                          tooltip:
                              '${AppSection.settings.label(context)} (Ctrl+,)',
                          selected: section == AppSection.settings,
                          onTap: () => _go(
                            () => openSection(router, AppSection.settings),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(
    BuildContext context, {
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required AppText text,
  }) {
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s),
        child: Icon(
          Icons.edit_note_rounded,
          size: AppIconSize.s,
          color: scheme.onPrimary,
        ),
      ),
    );

    if (!widget.extended) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xs,
          AppSpace.m,
          AppSpace.xs,
          AppSpace.s,
        ),
        child: Column(
          children: [
            badge,
            const SizedBox(height: AppSpace.xs),
            if (!widget.forceExtended && widget.onToggleExtended != null)
              IconButton(
                key: const ValueKey('web-sidebar-toggle'),
                tooltip: l10n.railExpand,
                icon: const Icon(Icons.menu, size: AppIconSize.m),
                onPressed: widget.onToggleExtended,
              ),
            const AccountAvatarButton(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.m,
        AppSpace.m,
        AppSpace.xs,
        AppSpace.s,
      ),
      child: Row(
        children: [
          badge,
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Text(
              l10n.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.rowTitle.copyWith(fontWeight: AppWeight.strong),
            ),
          ),
          const AccountAvatarButton(),
          if (!widget.forceExtended && widget.onToggleExtended != null)
            IconButton(
              key: const ValueKey('web-sidebar-toggle'),
              tooltip: l10n.railCollapse,
              icon: const Icon(Icons.menu_open, size: AppIconSize.m),
              onPressed: widget.onToggleExtended,
            ),
        ],
      ),
    );
  }

  Widget _buildComposeBlock(
    BuildContext context, {
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required GoRouter router,
    required bool canWrite,
    required bool inSharedFolder,
  }) {
    if (!canWrite) return const SizedBox.shrink();
    void newNote() {
      widget.onNavigate?.call();
      unawaited(createAndOpenNote(context, ref, router));
    }

    final showExtras = !widget.forceExtended && !inSharedFolder;
    if (!widget.extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xs,
        ),
        child: Column(
          children: [
            Tooltip(
              message: '${l10n.newNoteShort} (Ctrl+N)',
              child: FilledButton(
                key: const ValueKey('rail-new-note'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.l),
                  ),
                ),
                onPressed: newNote,
                child: const Icon(Icons.edit_outlined, size: AppIconSize.l),
              ),
            ),
            if (showExtras) ...[
              const SizedBox(height: AppSpace.s),
              _QuickActionButton(
                key: const ValueKey('home-mic'),
                tooltip: l10n.voiceMicTooltipDictate,
                icon: AppIcons.dictation,
                onTap: () => _atHome((d) => d.dictateNote()),
                onLongPress: () => _atHome((d) => d.captureVoiceNote()),
              ),
              const SizedBox(height: AppSpace.s),
              _QuickActionButton(
                key: const ValueKey('rail-quick-drop'),
                tooltip: l10n.quickDropTitle,
                icon: Icons.bolt,
                onTap: () => _atHome((d) => d.quickAddActions.openQuickDrop()),
              ),
              const SizedBox(height: AppSpace.s),
              CompositedTransformTarget(
                link: _addLink,
                child: QuickAddFab(
                  anchor: _addLink,
                  actions: () => homeDoors?.quickAddActions,
                  inRail: true,
                  beforeAction: () => openSection(router, AppSection.notes),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.m,
        vertical: AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Tooltip(
            message: '${l10n.newNoteShort} (Ctrl+N)',
            child: FilledButton.icon(
              key: const ValueKey('rail-new-note'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
              ),
              onPressed: newNote,
              icon: const Icon(Icons.edit_outlined, size: AppIconSize.m),
              label: Text(l10n.newNoteShort),
            ),
          ),
          if (showExtras) ...[
            const SizedBox(height: AppSpace.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _QuickActionButton(
                    key: const ValueKey('home-mic'),
                    tooltip: l10n.voiceMicTooltipDictate,
                    icon: AppIcons.dictation,
                    onTap: () => _atHome((d) => d.dictateNote()),
                    onLongPress: () => _atHome((d) => d.captureVoiceNote()),
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: _QuickActionButton(
                    key: const ValueKey('rail-quick-drop'),
                    tooltip: l10n.quickDropTitle,
                    icon: Icons.bolt,
                    onTap: () =>
                        _atHome((d) => d.quickAddActions.openQuickDrop()),
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                CompositedTransformTarget(
                  link: _addLink,
                  child: QuickAddFab(
                    anchor: _addLink,
                    actions: () => homeDoors?.quickAddActions,
                    inRail: true,
                    beforeAction: () => openSection(router, AppSection.notes),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.onLongPress,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.m),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 48,
            height: 44,
            child: Center(
              child: Icon(icon, size: AppIconSize.m, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(Theme.of(context));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s,
        AppSpace.s,
        AppSpace.s,
        AppSpace.xs,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.meta.copyWith(fontWeight: AppWeight.strong),
      ),
    );
  }
}

class _FolderTreeHeader extends StatelessWidget {
  const _FolderTreeHeader({
    required this.title,
    required this.onNewFolder,
    required this.tooltip,
  });

  final String title;
  final VoidCallback onNewFolder;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(Theme.of(context));
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpace.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.meta.copyWith(fontWeight: AppWeight.strong),
            ),
          ),
          IconButton(
            key: const ValueKey('web-sidebar-new-folder'),
            tooltip: tooltip,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.create_new_folder_outlined,
              size: AppIconSize.s,
            ),
            onPressed: onNewFolder,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    super.key,
    required this.extended,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltip,
    this.badgeCount = 0,
    this.locked = false,
    this.trailingIcon,
    this.trailingKey,
  });

  final bool extended;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? tooltip;
  final bool selected;
  final int badgeCount;
  final bool locked;
  final IconData? trailingIcon;
  final Key? trailingKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final bg = selected ? scheme.primaryContainer : Colors.transparent;
    final baseGlyph = Badge(
      isLabelVisible: badgeCount > 0,
      label: Text(
        badgeCount > kFolderBadgeMax ? '$kFolderBadgeMax+' : '$badgeCount',
      ),
      child: Icon(
        selected ? selectedIcon : icon,
        size: AppIconSize.m,
        color: fg,
      ),
    );
    final glyph = (locked || trailingIcon != null)
        ? Stack(
            key: trailingKey,
            clipBehavior: Clip.none,
            children: [
              baseGlyph,
              if (locked)
                const Positioned(
                  right: -6,
                  top: -4,
                  child: AccountLockBadge(size: AppIconSize.xs),
                )
              else if (trailingIcon != null)
                PositionedDirectional(
                  end: -6,
                  top: -4,
                  child: Icon(
                    trailingIcon,
                    size: AppIconSize.xs,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          )
        : baseGlyph;

    if (!extended) {
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: tooltip ?? label,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
            child: Center(
              child: Material(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.m),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  onTap: onTap,
                  child: SizedBox(
                    width: 48,
                    height: 44,
                    child: Center(child: glyph),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final row = Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.m),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.m,
                vertical: AppSpace.s,
              ),
              child: Row(
                children: [
                  glyph,
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.label.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                        fontWeight: selected
                            ? AppWeight.strong
                            : AppWeight.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return row;
    return Tooltip(message: tooltip!, child: row);
  }
}

class _FolderTreeRow extends StatefulWidget {
  const _FolderTreeRow({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconColor,
    this.count,
    this.onNewNote,
    this.onMore,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onNewNote;
  final VoidCallback? onMore;

  @override
  State<_FolderTreeRow> createState() => _FolderTreeRowState();
}

class _FolderTreeRowState extends State<_FolderTreeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final accent = widget.iconColor;
    final hasActions = widget.onNewNote != null || widget.onMore != null;
    final showActions = _hovered && hasActions;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: widget.selected
              ? scheme.primaryContainer
              : _hovered
              ? scheme.surfaceContainerHigh.withValues(alpha: AppAlpha.muted)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.m),
            onTap: widget.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 38),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.s,
                  AppSpace.xs,
                  AppSpace.s,
                  AppSpace.xs,
                ),
                child: Row(
                  children: [
                    if (accent != null && !widget.selected)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: AppAlpha.pressed),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.xs),
                          child: Icon(
                            widget.icon,
                            size: AppIconSize.xs,
                            color: accent,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(AppSpace.xs),
                        child: Icon(
                          widget.icon,
                          size: AppIconSize.s,
                          color: widget.selected
                              ? scheme.onPrimaryContainer
                              : (accent ?? scheme.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.label.copyWith(
                          color: widget.selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                          fontWeight: widget.selected
                              ? AppWeight.strong
                              : AppWeight.regular,
                        ),
                      ),
                    ),
                    if (showActions) ...[
                      if (widget.onNewNote != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 26,
                            minHeight: 26,
                          ),
                          tooltip: l10n.folderNewNote,
                          icon: Icon(
                            Icons.add_rounded,
                            size: AppIconSize.xs,
                            color: widget.selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                          onPressed: widget.onNewNote,
                        ),
                      if (widget.onMore != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 26,
                            minHeight: 26,
                          ),
                          tooltip: l10n.more,
                          icon: Icon(
                            Icons.more_horiz,
                            size: AppIconSize.xs,
                            color: widget.selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                          onPressed: widget.onMore,
                        ),
                    ] else if (widget.count != null)
                      Text(
                        '${widget.count}',
                        style: text.meta.copyWith(
                          color: widget.selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
