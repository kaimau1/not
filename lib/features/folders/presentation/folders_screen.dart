import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folder_activity.dart';
import '../data/folder_order.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_screen.dart';
import 'folder_sheets.dart';
import 'folder_tile.dart';

/// **KLASÖRLER** — geniş ekran gezinme rayının bölümü (kullanıcı isteği
/// 2026-09-22: rayda "Gelen kutusu ve Klasörler de eklensin").
///
/// 2026-09-23 YENİDEN TASARIM (kullanıcı: "webteki klasör sayfası da güzel
/// değil"): ilk sürüm ana ekranın 92 px'lik karolarını ekran boyu esnetiyordu
/// — geniş pencerede 300 px'lik boş bej şeritler. Artık her klasör kendi
/// KARTI: renkli simge kutusu, ad, not sayısı ve içindeki son notların
/// başlıkları. Kart genişliği sınırlı (en çok ~320 px), sütun sayısı
/// pencereyle artar; kendi klasörlerim ve benimle paylaşılanlar ayrı
/// başlıklar altında.
///
/// Gizli klasörler ana ekrandaki kuralla aynı: yalnız o oturumda açığa
/// çıkarıldıysa görünür.
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  /// Kartın sabit yüksekliği — ızgara düzgün satırlar kursun.
  static const double cardHeight = 204;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Kullanıcının klasör SIRASI (bkz. FolderSort) — ana ekran şeridiyle
    // aynı; gizliler yalnız açığa çıkarıldıysa.
    final folders = ref.watch(visibleOrderedFoldersProvider);
    final shared = ref.watch(sharedFolderRefsProvider).value ?? const [];

    SliverGridDelegate grid() => const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 320,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: cardHeight,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.foldersTitle),
        actions: [
          IconButton(
            tooltip: l10n.folderReorder,
            icon: const Icon(Icons.swap_vert),
            onPressed: () => showFolderOrderSheet(context),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.tonalIcon(
              onPressed: () async {
                final id = await showFolderEditorDialog(context, ref);
                if (id != null && context.mounted) {
                  await FolderScreen.open(context, id);
                }
              },
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: Text(l10n.newFolder),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  height: FolderChip.stripHeight - 8,
                  child: SharedNotesChip(),
                ),
              ),
            ),
          ),
          _SectionHeader(title: l10n.foldersMine, count: folders.length),
          if (folders.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.foldersEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverGrid(
              gridDelegate: grid(),
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == folders.length) {
                  return const NewFolderTile(height: cardHeight);
                }
                final folder = folders[index];
                return _OwnFolderCard(
                  key: ValueKey('folder-card-${folder.id}'),
                  folder: folder,
                );
              }, childCount: folders.length + 1),
            ),
          ),
          if (shared.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.foldersSharedSection,
              count: shared.length,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverGrid(
                gridDelegate: grid(),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final share = shared[index];
                  return _SharedFolderCard(
                    key: ValueKey('shared-card-${share.folderId}'),
                    share: share,
                  );
                }, childCount: shared.length),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          ],
        ),
      ),
    );
  }
}

class _OwnFolderCard extends ConsumerWidget {
  const _OwnFolderCard({super.key, required this.folder});

  final NoteFolder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes =
        ref.watch(folderNotesProvider(folder.id)).value ?? const <Note>[];
    final unread = folder.isShared
        ? ref.watch(
            folderUnreadProvider((
              ownerId: folder.ownerId,
              folderId: folder.id,
            )),
          )
        : 0;
    return FolderCard(
      accent: folder.accent,
      icon: folder.iconData,
      name: folder.name,
      notes: notes,
      shared: folder.isShared,
      hidden: folder.hidden,
      unread: unread,
      onTap: () => FolderScreen.open(context, folder.id),
      onMenu: () => showFolderActionsSheet(context, ref, folder),
    );
  }
}

class _SharedFolderCard extends ConsumerWidget {
  const _SharedFolderCard({super.key, required this.share});

  final SharedFolderRef share;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Yalnız YAZMA yetkisinde notlar okunamaz (kural reddeder); kart yine
    // çizilir, önizleme boş kalır.
    final notes = share.role.canRead
        ? ref
                  .watch(
                    sharedFolderNotesProvider((
                      ownerId: share.ownerId,
                      folderId: share.folderId,
                    )),
                  )
                  .value ??
              const <Note>[]
        : const <Note>[];
    final unread = ref.watch(
      folderUnreadProvider((ownerId: share.ownerId, folderId: share.folderId)),
    );
    return FolderCard(
      accent: folderAccent(share.folderId),
      icon: share.iconData,
      name: share.name,
      notes: notes,
      shared: true,
      unread: unread,
      onTap: () =>
          FolderScreen.open(context, share.folderId, ownerId: share.ownerId),
    );
  }
}

/// Klasörler sayfasının kartı: üstte klasör renginde ince şerit, renkli
/// simge kutusu, ad + not sayısı ve içindeki EN SON üç notun başlığı —
/// klasörü açmadan ne olduğunu söyler.
class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.accent,
    required this.icon,
    required this.name,
    required this.notes,
    required this.onTap,
    this.shared = false,
    this.hidden = false,
    this.unread = 0,
    this.onMenu,
  });

  final Color accent;
  final IconData icon;
  final String name;
  final List<Note> notes;
  final bool shared;
  final bool hidden;
  final int unread;
  final VoidCallback onTap;
  final VoidCallback? onMenu;

  /// Kartın önizleme satırı: kilitli notun başlığı bile gösterilmez (ana
  /// ekran kartıyla aynı kural).
  static String previewTitle(BuildContext context, Note note) {
    if (note.locked) return context.l10n.lockedNote;
    final title = note.displayTitle.trim();
    if (title.isNotEmpty) return title;
    return note.toPlainText().trim().split('\n').first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final recent = [...notes]
      ..sort(
        (a, b) =>
            (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)),
      );
    final preview = [
      for (final n in recent.take(3)) previewTitle(context, n),
    ].where((t) => t.isNotEmpty).toList();

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        child: Stack(
          children: [
            // Klasörün rengi kartın tepesinde ince bir şerit: ızgarada
            // renkler bir bakışta sıralanır.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(height: 4, color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FolderIconBox(accent: accent, icon: icon, size: 40),
                      const Spacer(),
                      if (shared)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.people_alt_outlined,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (hidden)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.visibility_off_outlined,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (onMenu != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: l10n.editFolder,
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: onMenu,
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    l10n.folderNoteCount(notes.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (preview.isEmpty)
                    Text(
                      l10n.folderEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    )
                  else
                    for (final title in preview)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: 8,
                          bottom: 3,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            if (unread > 0) FolderUnreadBadge(count: unread),
          ],
        ),
      ),
    );
  }
}
