import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

/// Çöp kutusu: silinen notlar geri alınabilir veya kalıcı silinebilir.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  Future<void> _emptyTrash(
    BuildContext context,
    WidgetRef ref,
    List<Note> notes,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.emptyTrash),
        content: Text(l10n.emptyTrashConfirm(notes.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    for (final note in notes) {
      await repo.deleteNotePermanently(note);
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.trashEmptied)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trash = ref.watch(trashStreamProvider);
    final notes = trash.value ?? const <Note>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trashTitle),
        actions: [
          if (notes.isNotEmpty)
            IconButton(
              tooltip: l10n.emptyTrash,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _emptyTrash(context, ref, notes),
            ),
        ],
      ),
      body: trash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.genericError(e.toString()),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyState(
              icon: Icons.delete_outline,
              title: l10n.trashEmpty,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l10n.trashInfo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              return _TrashTile(note: notes[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class _TrashTile extends ConsumerWidget {
  const _TrashTile({required this.note});

  final Note note;

  Future<void> _deleteForever(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteForever),
        content: Text(l10n.deleteForeverConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      // Ekler de Storage'dan silinsin; yalnız dokümanı silmek dosya bırakır.
      await ref.read(notesRepositoryProvider)?.deleteNotePermanently(note);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final preview = note.toPlainText();
    return ListTile(
      tileColor: scheme.surfaceContainerLow,
      title: Text(
        note.title.trim().isNotEmpty ? note.title : preview.split('\n').first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: preview.isEmpty
          ? null
          : Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.restore,
            icon: const Icon(Icons.restore_from_trash_outlined),
            onPressed: () =>
                ref.read(notesRepositoryProvider)?.restore(note.id),
          ),
          IconButton(
            tooltip: l10n.deleteForever,
            icon: Icon(Icons.delete_forever_outlined, color: scheme.error),
            onPressed: () => _deleteForever(context, ref),
          ),
        ],
      ),
    );
  }
}
