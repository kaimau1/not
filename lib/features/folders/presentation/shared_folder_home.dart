import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/app_icons.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/note_card.dart';
import '../../notes/presentation/note_grid.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../notes/presentation/screen_search.dart';
import '../data/folder_activity.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_chat_screen.dart';
import 'folder_sheets.dart' show folderRoleLabel;

/// Seçili paylaşılan klasörün aynadaki kaydı; ad, simge ve yetki buradan.
SharedFolderRef? sharedFolderRefOf(WidgetRef ref, SharedFolderKey key) => ref
    .watch(sharedFolderRefsProvider)
    .value
    ?.where((s) => s.folderId == key.folderId && s.ownerId == key.ownerId)
    .firstOrNull;

/// Yana çekişte paylaşılan klasörün durak kimliği (kendi klasör kimlikleriyle
/// çakışmaz: Firestore kimliğinde `/` olmaz).
String sharedFolderStopId(SharedFolderRef share) =>
    '${share.ownerId}/${share.folderId}';

/// **PAYLAŞILAN KLASÖR ANA EKRANDA** (TUTARLILIK K8): ızgaranın yerine çizilen
/// sliver'lar. Durum/etiket süzgeci ve arama kutusu kendi klasördeki gibi
/// işler; AI araması yok (notlar başkasının), seçim yok (kart sahibi
/// taşıyorsa seçilmez). Yetki şeritte yazar.
///
/// ponytail: liste görünümü burada yok, ızgara çizilir (Gelen ile aynı);
/// `NoteListRow` not sahibini taşımıyor, eklenince burada da açılır.
List<Widget> sharedFolderSlivers(
  BuildContext context,
  WidgetRef ref, {
  required SharedFolderKey folder,
  required int columns,
  required double cellWidth,
  required String query,
}) {
  final l10n = context.l10n;
  final share = sharedFolderRefOf(ref, folder);
  final role = share?.role ?? FolderRole.both;
  final bar = SliverToBoxAdapter(
    child: SharedFolderBar(folder: folder, name: share?.name ?? '', role: role),
  );
  // Yalnız YAZMA: kural okumayı reddeder; boş liste yerine NEDENİ yazılır.
  if (!role.canRead) {
    return [
      bar,
      SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: AppIcons.moveToFolder,
          title: l10n.folderWriteOnlyTitle,
          subtitle: l10n.folderWriteOnlyHint,
        ),
      ),
    ];
  }
  final filter = ref.watch(noteFilterProvider);
  final tag = ref.watch(selectedTagProvider);
  return [
    bar,
    ...ref
        .watch(sharedFolderNotesProvider(folder))
        .when(
          loading: () => [
            SliverToBoxAdapter(child: NoteGridSkeleton(columns: columns)),
          ],
          error: (e, _) => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(error: e),
            ),
          ],
          data: (all) {
            final filtered = [
              for (final n in all)
                if (noteMatchesFilter(n, filter) &&
                    (tag == null || n.tags.contains(tag)))
                  n,
            ];
            final result = runScreenSearch(
              ref,
              filtered,
              query,
              semantic: false,
            );
            final notes = result.notes;
            if (notes.isEmpty) {
              final untouched =
                  result.needle.isEmpty &&
                  filter == NoteFilter.all &&
                  tag == null;
              return [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: untouched
                      ? EmptyState(
                          icon: Icons.folder_open_outlined,
                          title: l10n.folderEmpty,
                          subtitle: l10n.folderEmptyHint,
                          actionLabel: role.canWrite ? l10n.newTextNote : null,
                          actionIcon: Icons.add,
                          onAction: role.canWrite
                              ? () => createInSharedFolder(
                                  context,
                                  ref,
                                  folder,
                                  role,
                                )
                              : null,
                        )
                      : EmptyState(
                          icon: Icons.search_off,
                          title: l10n.emptySearch,
                          subtitle: l10n.emptySearchHint,
                        ),
                ),
              ];
            }
            return [
              if (result.needle.isNotEmpty)
                SliverToBoxAdapter(
                  child: SearchResultHeader(
                    count: notes.length,
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: kGridInset),
                sliver: sliverBalancedNoteColumns(
                  items: notes,
                  columns: columns,
                  cellWidth: cellWidth,
                  cell: (context, index) => NoteCard(
                    key: ValueKey(notes[index].id),
                    note: notes[index],
                    ownerId: folder.ownerId,
                    readOnly: !role.canWrite,
                    highlightQuery: result.needle,
                    showFolder: false,
                  ),
                ),
              ),
            ];
          },
        ),
  ];
}

/// Izgaranın üstündeki yetki şeridi + klasör sohbeti. Salt okunurda kilit.
/// Açık kaldığı sürece gelen hareket okunmuş sayılır (rozet birikmez).
class SharedFolderBar extends ConsumerWidget {
  const SharedFolderBar({
    super.key,
    required this.folder,
    required this.name,
    required this.role,
  });

  final SharedFolderKey folder;
  final String name;
  final FolderRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    ref.listen(folderUnreadProvider(folder), (_, unread) {
      if (unread > 0) {
        ref.read(folderSeenProvider.notifier).markSeen(folder.folderId);
      }
    });
    return Padding(
      key: const ValueKey('shared-folder-bar'),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
      child: Row(
        children: [
          Icon(
            role == FolderRole.read ? Icons.lock_outline : AppIcons.shared,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.sharedFolderBar(folderRoleLabel(l10n, role)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          IconButton(
            tooltip: l10n.folderChatTitle,
            icon: const Icon(Icons.forum_outlined, size: 20),
            onPressed: () => FolderChatScreen.open(
              context,
              folderId: folder.folderId,
              folderName: name,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paylaşılan klasörde "+" yerine: yeni not SAHİBİN koleksiyonuna yazılır.
/// Salt okunurda düğme yok. Mikrofon ve "+" paneli burada çizilmez: onlar
/// notu kendi koleksiyonuma açar.
class SharedFolderFab extends ConsumerWidget {
  const SharedFolderFab({super.key, required this.folder});

  final SharedFolderKey folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = sharedFolderRefOf(ref, folder)?.role ?? FolderRole.both;
    if (!role.canWrite) return const SizedBox.shrink();
    return FloatingActionButton(
      key: const ValueKey('shared-folder-add'),
      heroTag: 'sharedFolderAdd',
      tooltip: context.l10n.newTextNote,
      onPressed: () => createInSharedFolder(context, ref, folder, role),
      child: const Icon(Icons.add),
    );
  }
}

/// Paylaşılan klasöre yeni not. YALNIZ YAZMA yetkisinde editör AÇILAMAZ (notu
/// geri okuyamaz, "yükleniyor"da kalır): tek seferlik yazma penceresi.
Future<void> createInSharedFolder(
  BuildContext context,
  WidgetRef ref,
  SharedFolderKey folder,
  FolderRole role,
) async {
  if (!role.canWrite) return;
  final repo = NotesRepository(
    FirebaseFirestore.instance,
    folder.ownerId,
    editorUid: ref.read(currentUidProvider),
  );
  if (!role.canRead) {
    await _composeWriteOnly(context, repo, folder.folderId);
    return;
  }
  final id = await repo.createNote(NoteType.text, folderId: folder.folderId);
  if (!context.mounted) return;
  await openNoteRoute(
    context,
    Note(id: id, type: NoteType.text, folderId: folder.folderId),
    ownerId: folder.ownerId,
  );
}

Future<void> _composeWriteOnly(
  BuildContext context,
  NotesRepository repo,
  String folderId,
) async {
  final l10n = context.l10n;
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  try {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.newTextNote),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.titleHint),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyController,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.bodyHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (!(saved ?? false) || (title.isEmpty && body.isEmpty)) return;
    final id = await repo.createNote(
      NoteType.text,
      folderId: folderId,
      body: body,
    );
    if (title.isNotEmpty) repo.updateFields(id, {'title': title});
  } finally {
    // finally İÇİNDE: diyalog fırlarsa denetleyiciler sızardı.
    titleController.dispose();
    bodyController.dispose();
  }
}
