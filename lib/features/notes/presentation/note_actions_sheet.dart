import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'notes_providers.dart';
import 'pdf_export_screen.dart';

/// Nota basılı tutunca açılan hızlı işlem menüsü: paylaş, kopyala,
/// arşivle, kilitle, seç, sil. Kilitli notun içeriği kimlik doğrulaması
/// yapılmadan paylaşılmaz/kopyalanmaz.
Future<void> showNoteActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final l10n = context.l10n;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    // Sekiz satır varsayılan yükseklik sınırını (ekranın 9/16'sı) aşıyordu;
    // taşan son satır ("Sil") sayfanın dışına, gezinme çubuğunun üstüne
    // düşüyordu. isScrollControlled sınırı kaldırır, kaydırma da kısa
    // ekranlarda güvenlik ağı olur.
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note.title.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    note.title.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(sheetContext).textTheme.titleSmall,
                  ),
                ),
              ),
            ListTile(
              leading: Icon(
                note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(note.pinned ? l10n.unpin : l10n.pin),
              onTap: () => Navigator.pop(sheetContext, 'pin'),
            ),
            ListTile(
              leading: Icon(note.starred ? Icons.star : Icons.star_outline),
              title: Text(note.starred ? l10n.unstar : l10n.star),
              onTap: () => Navigator.pop(sheetContext, 'star'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.share),
              onTap: () => Navigator.pop(sheetContext, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l10n.copy),
              onTap: () => Navigator.pop(sheetContext, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.exportPdf),
              onTap: () => Navigator.pop(sheetContext, 'pdf'),
            ),
            ListTile(
              leading: Icon(
                note.archivedAt != null
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
              title: Text(
                note.archivedAt != null ? l10n.unarchive : l10n.archive,
              ),
              onTap: () => Navigator.pop(sheetContext, 'archive'),
            ),
            ListTile(
              leading: Icon(
                note.locked ? Icons.lock_open_outlined : Icons.lock_outline,
              ),
              title: Text(note.locked ? l10n.unlockNote : l10n.lockNote),
              onTap: () => Navigator.pop(sheetContext, 'lock'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l10n.select),
              onTap: () => Navigator.pop(sheetContext, 'select'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.delete),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  final repo = ref.read(notesRepositoryProvider);
  if (repo == null) return;

  Future<bool> unlockIfNeeded() async {
    if (!note.locked) return true;
    return authenticateForNote(l10n.unlockAuthReason);
  }

  switch (action) {
    case 'pin':
      repo.setPinned(note.id, !note.pinned);
    case 'star':
      repo.setStarred(note.id, !note.starred);
    case 'share':
      if (!await unlockIfNeeded()) return;
      final text = note.toPlainText();
      if (text.isEmpty) return;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: note.title.trim().isEmpty ? l10n.appName : note.title.trim(),
        ),
      );
    case 'pdf':
      // Kilitli notun içeriği PDF'e de kimlik doğrulaması olmadan çıkmasın.
      if (!await unlockIfNeeded()) return;
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PdfExportScreen(note: note)),
      );
    case 'copy':
      if (!await unlockIfNeeded()) return;
      await Clipboard.setData(ClipboardData(text: note.toPlainText()));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.copied)));
      }
    case 'archive':
      final wasArchived = note.archivedAt != null;
      repo.setArchived(note.id, !wasArchived);
      if (!wasArchived && context.mounted) {
        showUndoSnackBar(
          context,
          message: l10n.noteArchived,
          undoLabel: l10n.undo,
          onUndo: () => repo.setArchived(note.id, false),
        );
      }
    case 'lock':
      // Kilidi kaldırmak kimlik doğrulaması ister; kilitlemek serbest.
      if (note.locked && !await authenticateForNote(l10n.unlockAuthReason)) {
        return;
      }
      repo.updateFields(note.id, {'locked': !note.locked});
    case 'select':
      ref.read(selectedNoteIdsProvider.notifier).toggle(note.id);
    case 'delete':
      repo.softDelete(note.id);
      if (context.mounted) {
        showUndoSnackBar(
          context,
          message: l10n.noteDeleted,
          undoLabel: l10n.undo,
          onUndo: () => repo.restore(note.id),
        );
      }
  }
}
