import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'note_card.dart';
import 'notes_providers.dart';

/// Arşivlenen notlar. Karta dokununca editör açılır; menüden arşivden
/// çıkarılabilir veya silinebilir.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final archived = ref.watch(archivedNotesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.archiveTitle)),
      body: archived.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.genericError(e.toString()),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyState(
              icon: Icons.archive_outlined,
              title: l10n.archiveEmpty,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) => _ArchivedTile(note: notes[index]),
          );
        },
      ),
    );
  }
}

class _ArchivedTile extends ConsumerWidget {
  const _ArchivedTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Kilitli notun başlığı/içeriği kimlik doğrulamasız yüzeylerde gösterilmez
    // (ana ekran kartıyla aynı kural).
    final preview = note.locked ? '' : note.toPlainText();
    final title = note.locked
        ? l10n.lockedNote
        : (note.title.trim().isNotEmpty
              ? note.displayTitle
              : preview.split('\n').first);
    return ListTile(
      tileColor: scheme.surfaceContainerLow,
      leading: note.locked ? const Icon(Icons.lock_outline) : null,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: preview.isEmpty
          ? null
          : Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => openNoteRoute(context, note),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.unarchive,
            icon: const Icon(Icons.unarchive_outlined),
            onPressed: () =>
                ref.read(notesRepositoryProvider)?.setArchived(note.id, false),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            // Kilitli not doğrulamasız silinmesin (eylem levhasıyla aynı).
            onPressed: () async {
              if (note.locked &&
                  !await authenticateForNote(l10n.unlockAuthReason)) {
                return;
              }
              ref.read(notesRepositoryProvider)?.softDelete(note.id);
            },
          ),
        ],
      ),
    );
  }
}
