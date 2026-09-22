import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/note_shares_repository.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'note_card.dart';
import 'note_grid.dart';

/// **BENİMLE PAYLAŞILAN NOTLAR** — ortak notun (bkz. [NoteShare]) alıcı
/// tarafı. Notlar sahiplerinin koleksiyonundan TEK TEK canlı okunur; kart
/// sahibini editöre taşır (`?owner=`), yani burada açılan not sahibinin
/// notunun kendisidir, kopyası değil.
class SharedNotesScreen extends ConsumerWidget {
  const SharedNotesScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SharedNotesScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shares = ref.watch(sharedNotesWithMeProvider).value ?? const [];
    final entries = <({Note note, NoteShare share})>[];
    for (final share in shares) {
      final note = ref
          .watch(
            ownedNoteStreamProvider((
              ownerId: share.ownerId,
              noteId: share.noteId,
            )),
          )
          .value;
      // Sahip notu çöpe attıysa ya da ayna yetim kaldıysa (not kalıcı
      // silindi) kart çizilmez — boş bir kart "not kayboldu" gibi okunurdu.
      if (note == null || note.deletedAt != null) continue;
      entries.add((note: note, share: share));
    }
    entries.sort(
      (a, b) => (b.note.updatedAt ?? DateTime(0)).compareTo(
        a.note.updatedAt ?? DateTime(0),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharedWithMe)),
      body: entries.isEmpty
          ? EmptyState(
              icon: Icons.people_alt_outlined,
              title: l10n.sharedWithMe,
              subtitle: l10n.sharedWithMeEmpty,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 220).floor().clamp(
                  2,
                  6,
                );
                return NoteBalancedGrid(
                  notes: [for (final e in entries) e.note],
                  columns: columns,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NoteCard(
                          note: entry.note,
                          ownerId: entry.share.ownerId,
                        ),
                        if (entry.share.ownerName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 6,
                              top: 3,
                            ),
                            child: Text(
                              l10n.sharedByName(entry.share.ownerName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
