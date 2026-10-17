import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/note_shares_repository.dart';
import '../data/notes_repository.dart';
import '../data/shared_note_activity.dart';
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
    // YENİLER ÜSTTE (kullanıcı bulgusu 2026-10-17: "yeni bir şey geldiğinde
    // anlaşılmıyor"): okunmamış notlar başa, kalanı son değişikliğe göre.
    final unread = ref.watch(sharedNoteUnreadProvider);
    entries.sort((a, b) {
      final ua = unread.contains(a.share.id);
      final ub = unread.contains(b.share.id);
      if (ua != ub) return ua ? -1 : 1;
      return (b.note.updatedAt ?? DateTime(0)).compareTo(
        a.note.updatedAt ?? DateTime(0),
      );
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sharedWithMe),
        actions: [
          if (unread.isNotEmpty)
            IconButton(
              tooltip: l10n.sharedMarkAllRead,
              icon: const Icon(Icons.done_all),
              onPressed: () {
                final seen = ref.read(sharedNoteSeenProvider.notifier);
                for (final id in unread) {
                  seen.markSeen(id);
                }
              },
            ),
        ],
      ),
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
                    final isNew = unread.contains(entry.share.id);
                    final scheme = Theme.of(context).colorScheme;
                    final caption = sharedNoteCaption(
                      l10n,
                      entry.share,
                      entry.note,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            NoteCard(
                              note: entry.note,
                              ownerId: entry.share.ownerId,
                            ),
                            if (isNew)
                              PositionedDirectional(
                                top: -4,
                                end: -2,
                                child: IgnorePointer(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.error,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      l10n.sharedNoteNew,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onError,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (caption.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 6,
                              top: 3,
                            ),
                            child: Text(
                              caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: isNew
                                        ? scheme.error
                                        : scheme.onSurfaceVariant,
                                    fontWeight: isNew
                                        ? FontWeight.w700
                                        : null,
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

/// Kartın altındaki satır: son değişikliği sahip DIŞINDA biri yaptıysa
/// "Ayşe güncelledi", değilse "Mehmet paylaştı". Kendi düzenlememde
/// paylaşanın adı kalır (kendimi görmenin anlamı yok).
String sharedNoteCaption(AppLocalizations l10n, NoteShare share, Note note) {
  final editor = note.updatedBy;
  if (editor.isNotEmpty &&
      editor != share.ownerId &&
      share.names.containsKey(editor) &&
      share.sharedWith.contains(editor)) {
    final name = share.names[editor]!;
    if (name.isNotEmpty) return l10n.sharedNoteUpdatedBy(name);
  }
  return share.ownerName.isEmpty ? '' : l10n.sharedByName(share.ownerName);
}
