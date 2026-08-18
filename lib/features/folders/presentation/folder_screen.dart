import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/note_card.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folders_repository.dart';
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
/// Rota DEĞİL, `Navigator.push` ile açılır: geniş ekranda GoRouter kabuğu
/// (SplitShell) sağ paneli not editörüne ayırıyor; klasör listesi oraya
/// sıkışmamalı, tam sayfa açılmalı.
class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key, required this.folderId});

  final String folderId;

  static Future<void> open(BuildContext context, String folderId) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FolderScreen(folderId: folderId),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
        title: Row(
          children: [
            Icon(folder?.iconData ?? Icons.folder_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                folder?.name ?? l10n.filterSectionFolder,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.genericError('$e'),
        ),
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
                    itemBuilder: (context, index) =>
                        NoteCard(note: notes[index]),
                  );
                },
              ),
      ),
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
