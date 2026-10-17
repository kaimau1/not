import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/note_card.dart';
import '../data/inbox_repository.dart';
import 'shared_hub_screen.dart';

/// **GELEN NOTLAR** ekranı — kullanıcı isteği 2026-08-18: "paylaşılan not
/// alıcıda farklı gelen notlar klasöründe görülsün ve oradan normal
/// dashboard'a taşınabilsin."
///
/// Ayrı bir ekran, klasör DEĞİL: gelen not henüz kullanıcının notu değil.
/// Kendi klasörlerinin arasında dursaydı hem silinemeyen bir "klasör" gibi
/// görünürdü hem de kabul edilmemiş notlar aramaya/AI'a karışırdı.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  /// "Gelen ve paylaşılanlar" ekranının Gelen sekmesi (kullanıcı isteği
  /// 2026-10-17: gelen ve paylaşılan notlar tek alandan yönetilsin).
  static Future<void> open(BuildContext context) =>
      SharedHubScreen.open(context, tab: SharedHubTab.inbox);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(inboxNotesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.inboxTitle),
            // Kaç not beklediği listeye bakmadan görünsün.
            if ((async.value?.length ?? 0) > 0)
              Text(
                l10n.inboxCountLabel(async.value!.length),
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: const InboxList(),
    );
  }
}

/// Gelen notların listesi (ayrı ekranda ve birleşik ekranın sekmesinde).
class InboxList extends ConsumerWidget {
  const InboxList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(inboxNotesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          EmptyState(icon: Icons.error_outline, title: l10n.genericError('$e')),
      data: (notes) => notes.isEmpty
          ? EmptyState(
              icon: Icons.move_to_inbox_outlined,
              title: l10n.inboxEmpty,
              subtitle: l10n.inboxEmptyHint,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _InboxCard(note: notes[index]),
            ),
    );
  }
}

class _InboxCard extends ConsumerWidget {
  const _InboxCard({required this.note});

  final InboxNote note;

  /// Kartta gösterilen özet: metin notunda gövde, listede maddeler.
  String _preview() {
    if (note.items.isNotEmpty) {
      return [for (final i in note.items) '• ${i.text}'].join('\n');
    }
    return note.body;
  }

  /// Reddetme GERİ ALINAMAZ: gelen not alıcının kutusundan silinir ve
  /// güvenlik kuralları alıcının onu yeniden yaratmasına izin vermez (yalnız
  /// GÖNDEREN yazabilir, bkz. firestore.rules → inboxNotes). Tek dokunuşta
  /// yok olmasın diye önce onay sorulur — "geri al" bildirimi burada
  /// kurulamıyor.
  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteForeverConfirm),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await ref.read(inboxRepositoryProvider)?.decline(note.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.inboxDeclined)));
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final repo = ref.read(inboxRepositoryProvider);
    if (repo == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = await repo.acceptNote(note);
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.inboxAccepted)));
      // Kabul edilen not DOĞRUDAN açılır: kullanıcı "nereye gitti" diye ana
      // ekranda aramasın.
      await openNoteRoute(
        context,
        Note(id: id, type: note.type, title: note.title),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final title = note.displayTitle;
    final preview = _preview().trim();
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  note.type == NoteType.text
                      ? Icons.sticky_note_2_outlined
                      : Icons.checklist_outlined,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.inboxFrom(note.senderLabel),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (title.isNotEmpty)
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                preview,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            Row(
              children: [
                // Geliş zamanı: "bu not ne zaman geldi" sorusunun cevabı
                // hiçbir yerde yazmıyordu.
                Expanded(
                  child: note.sentAt == null
                      ? const SizedBox.shrink()
                      : Text(
                          formatNoteDate(note.sentAt!),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ),
                TextButton(
                  onPressed: () => _decline(context, ref),
                  child: Text(l10n.delete),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _accept(context, ref),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(l10n.inboxAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
