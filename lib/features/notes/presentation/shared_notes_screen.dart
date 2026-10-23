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
import '../../inbox/presentation/shared_hub_screen.dart';

/// **BENİMLE PAYLAŞILAN NOTLAR** — ortak notun (bkz. [NoteShare]) alıcı
/// tarafı. Notlar sahiplerinin koleksiyonundan TEK TEK canlı okunur; kart
/// sahibini editöre taşır (`?owner=`), yani burada açılan not sahibinin
/// notunun kendisidir, kopyası değil.
class SharedNotesScreen extends ConsumerWidget {
  const SharedNotesScreen({super.key});

  /// "Gelen ve paylaşılanlar" ekranının Paylaşılanlar sekmesi açılır
  /// (kullanıcı isteği 2026-10-17: "gelen ve paylaşılan notları birleştir,
  /// tek alandan yönetilsin").
  static Future<void> open(BuildContext context) =>
      SharedHubScreen.open(context, tab: SharedHubTab.shared);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sharedWithMe),
        actions: const [SharedMarkAllReadButton()],
      ),
      body: const SharedNotesBody(),
    );
  }
}

/// "Tümünü okundu say" — yalnız okunmamış ortak not varken.
class SharedMarkAllReadButton extends ConsumerWidget {
  const SharedMarkAllReadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(sharedNoteUnreadProvider);
    if (unread.isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: context.l10n.sharedMarkAllRead,
      icon: const Icon(Icons.done_all),
      onPressed: () {
        final seen = ref.read(sharedNoteSeenProvider.notifier);
        for (final id in unread) {
          seen.markSeen(id);
        }
      },
    );
  }
}

/// Benimle paylaşılan notların ızgarası (ayrı ekranda ve birleşik
/// "Gelen ve paylaşılanlar" ekranının sekmesinde aynı gövde).
class SharedNotesBody extends ConsumerWidget {
  const SharedNotesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = sharedNoteEntries(ref);
    final unread = ref.watch(sharedNoteUnreadProvider);
    return entries.isEmpty
        ? EmptyState(
            icon: Icons.people_alt_outlined,
            title: l10n.sharedWithMe,
            subtitle: l10n.sharedWithMeEmpty,
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / 220).floor().clamp(2, 6);
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
                                  fontWeight: isNew ? FontWeight.w700 : null,
                                ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
  }
}

/// Benimle paylaşılan notlar (sahibinden canlı), okunmamışlar üstte, kalanı
/// son değişikliğe göre. Ayrı ekran, birleşik ekranın sekmesi ve ana ekran
/// bölümü ([SharedNotesHomeSection]) aynı listeyi okur.
List<({Note note, NoteShare share})> sharedNoteEntries(WidgetRef ref) {
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
  return entries;
}

/// **ANA EKRANDA PAYLAŞILANLAR** (kullanıcı isteği 2026-10-23: "paylaşılan
/// notların paylaşılan kişinin ana ekranında da görülmesi, seçenek olarak"):
/// Ayarlar'da/Süz levhasında açılınca ana ekranın tepesinde ayrı bölüm.
/// Kendi notlarımın ızgarasına KARIŞTIRILMAZ: sıralama, seçim, sürükle-
/// sırala ve toplu işlemler yalnız kendi notlarımı bilir; ortak not sahibinin
/// koleksiyonunda durur. Bir SLIVER döner.
class SharedNotesHomeSection extends ConsumerWidget {
  const SharedNotesHomeSection({
    super.key,
    required this.columns,
    required this.cellWidth,
  });

  final int columns;
  final double cellWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final entries = sharedNoteEntries(ref);
    if (entries.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final unread = ref.watch(sharedNoteUnreadProvider);
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 4),
            child: Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 15,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.homeSharedSection,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Divider(height: 1, color: scheme.outlineVariant),
                ),
                TextButton(
                  onPressed: () => SharedNotesScreen.open(context),
                  child: Text(l10n.sectionNoteCount(entries.length)),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: sliverBalancedNoteColumns(
            items: [for (final e in entries) e.note],
            columns: columns,
            cellWidth: cellWidth,
            cell: (context, index) {
              final entry = entries[index];
              final isNew = unread.contains(entry.share.id);
              final caption = sharedNoteCaption(l10n, entry.share, entry.note);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  NoteCard(note: entry.note, ownerId: entry.share.ownerId),
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isNew ? scheme.error : scheme.onSurfaceVariant,
                          fontWeight: isNew ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
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
