import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_tile.dart';

/// **KLASÖRLER** — geniş ekran gezinme rayının bölümü (kullanıcı isteği
/// 2026-09-22: rayda "Gelen kutusu ve Klasörler de eklensin").
///
/// Telefonda klasörler ana ekranın rafında yaşıyor; geniş ekranda raf
/// listenin tepesinde tek şerit kalıyor ve kaç klasör olduğu bir bakışta
/// görünmüyordu. Burada hepsi bir ızgarada: kendi klasörlerim, benimle
/// paylaşılanlar ve "Benimle paylaşılan notlar" çipi. Karolar ana ekrandakiyle
/// AYNI widget'lar — dokununca aynı klasör sayfası açılır.
///
/// Gizli klasörler, ana ekrandaki kuralla aynı: yalnız o oturumda açığa
/// çıkarıldıysa görünür.
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final revealHidden = ref.watch(hiddenFoldersRevealedProvider);
    final folders = [
      for (final f
          in ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[])
        if (!f.hidden || revealHidden) f,
    ];
    final shared = ref.watch(sharedFolderRefsProvider).value ?? const [];
    final total = folders.length + shared.length;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.foldersTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.maxWidth / 220).floor().clamp(2, 6);
          return CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
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
              if (total == 0)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: FolderTile.height,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == total) return const NewFolderTile();
                    if (index < folders.length) {
                      final folder = folders[index];
                      return FolderTile(
                        key: ValueKey('folder-${folder.id}'),
                        folder: folder,
                      );
                    }
                    final share = shared[index - folders.length];
                    return SharedFolderTile(
                      key: ValueKey('shared-folder-${share.folderId}'),
                      share: share,
                    );
                  }, childCount: total + 1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
