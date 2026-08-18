import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/note_card.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_sheets.dart';

/// **KLASÖRÜN KENDİ SAYFASI.**
///
/// Kullanıcı isteği 2026-08-18: "şu an etiketle klasör aynı şey; klasör
/// mantığı şu olsun: klasör dashboard'ta bir not gibi yer kaplar ama görüntüsü
/// klasör gibidir, basılınca kendi içerisindeki notlar görülür AYRI BİR
/// SAYFADA."
///
/// Eskiden klasör yalnızca bir SÜZGEÇTİ: ana ekranın çip barından seçiliyor,
/// aynı ızgara daralıyordu — yani etiketin yaptığı işin aynısı. Klasör artık
/// bir YER: ana ekranda karosu var, içine girilir, içinden çıkılır.
///
/// **PAYLAŞILAN klasörler de AYNI ekranı kullanır** (kullanıcı isteği
/// 2026-08-18: "ortak notlar klasörü kişiler bağlanır notları ortak görür").
/// [ownerId] verilmezse (ya da kendi uid'imse) BENİM klasörümdür — eski yol.
/// Başka bir uid verilirse bir arkadaşın PAYLAŞTIĞI klasördür: klasör ve
/// notlar SAHİBİNİN koleksiyonundan okunur/yazılır (bkz.
/// `sharedFolderNotesProvider`), kopyalanmaz.
///
/// Rota DEĞİL, `Navigator.push` ile açılır: geniş ekranda GoRouter kabuğu
/// (SplitShell) sağ paneli not editörüne ayırıyor; klasör listesi oraya
/// sıkışmamalı, tam sayfa açılmalı.
class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key, required this.folderId, this.ownerId});

  final String folderId;

  /// null = kendi klasörüm. Dolu ve benden farklıysa paylaşılan bir klasör.
  final String? ownerId;

  static Future<void> open(
    BuildContext context,
    String folderId, {
    String? ownerId,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FolderScreen(folderId: folderId, ownerId: ownerId),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final myUid = ref.watch(currentUidProvider);
    final shared = ownerId != null && ownerId != myUid;

    if (shared) return _SharedFolderView(folderId: folderId, ownerId: ownerId!);

    final folders = ref.watch(foldersStreamProvider).value;
    final folder = folders?.where((f) => f.id == folderId).firstOrNull;
    final notesAsync = ref.watch(folderNotesProvider(folderId));

    // Klasör silinmiş olabilir (başka cihazdan): sayfa boş bir kabuk olarak
    // kalmaz, kendiliğinden kapanır.
    if (folders != null && folder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: _FolderTitle(icon: folder?.iconData, name: folder?.name),
        actions: [
          if (folder != null)
            IconButton(
              tooltip: l10n.folderManage,
              icon: const Icon(Icons.more_vert),
              onPressed: () => showFolderActionsSheet(context, ref, folder),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newTextNote,
        onPressed: () => _createNote(context, ref),
        child: const Icon(Icons.add),
      ),
      body: _NotesGrid(async: notesAsync),
    );
  }

  /// Klasörün içinde yeni not: `folderId` doğrudan yazılır, kullanıcı notu
  /// oluşturduktan sonra ayrıca "klasöre taşı" adımı yapmasın.
  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text, folderId: folderId);
    if (!context.mounted) return;
    await openNoteRoute(
      context,
      Note(id: id, type: NoteType.text, folderId: folderId),
    );
  }
}

class _FolderTitle extends StatelessWidget {
  const _FolderTitle({required this.icon, required this.name});

  final IconData? icon;
  final String? name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon ?? Icons.folder_outlined, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          name ?? context.l10n.filterSectionFolder,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.async});

  final AsyncValue<List<Note>> async;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          EmptyState(icon: Icons.error_outline, title: l10n.genericError('$e')),
      data: (notes) => notes.isEmpty
          ? EmptyState(
              icon: Icons.folder_open_outlined,
              title: l10n.folderEmpty,
              subtitle: l10n.folderEmptyHint,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 220).floor().clamp(
                  2,
                  6,
                );
                return MasonryGridView.count(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: notes.length,
                  itemBuilder: (context, index) => NoteCard(note: notes[index]),
                );
              },
            ),
    );
  }
}

/// Paylaşılan klasörün gövdesi: klasör dokümanı da notlar da SAHİBİNİN
/// koleksiyonundan canlı okunur (bkz. sınıf açıklaması).
class _SharedFolderView extends ConsumerWidget {
  const _SharedFolderView({required this.folderId, required this.ownerId});

  final String folderId;
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return StreamBuilder<NoteFolder?>(
      stream: FoldersRepository.watchSharedFolder(
        FirebaseFirestore.instance,
        ownerId,
        folderId,
      ),
      builder: (context, snapshot) {
        final folder = snapshot.data;
        // Yükleniyor DEĞİL ama klasör YOK: paylaşım kaldırılmış ya da klasör
        // silinmiş. Sayfa kendiliğinden kapanır (kendi klasörümdeki kural).
        if (snapshot.connectionState != ConnectionState.waiting &&
            folder == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
        }
        final notesAsync = ref.watch(
          sharedFolderNotesProvider((ownerId: ownerId, folderId: folderId)),
        );
        return Scaffold(
          appBar: AppBar(
            title: _FolderTitle(icon: folder?.iconData, name: folder?.name),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Tooltip(
                  message: l10n.folderShared,
                  child: const Icon(Icons.people_outline, size: 20),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: l10n.newTextNote,
            onPressed: () async {
              final repo = NotesRepository(FirebaseFirestore.instance, ownerId);
              final id = await repo.createNote(
                NoteType.text,
                folderId: folderId,
              );
              if (!context.mounted) return;
              await openNoteRoute(
                context,
                Note(id: id, type: NoteType.text, folderId: folderId),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: _NotesGrid(async: notesAsync),
        );
      },
    );
  }
}
