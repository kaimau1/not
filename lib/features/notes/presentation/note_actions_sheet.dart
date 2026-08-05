import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n_ext.dart';
import '../../ai/presentation/listen_screen.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/presentation/folder_sheets.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'color_picker_sheet.dart';
import 'notes_providers.dart';
import 'pdf_export_screen.dart';

/// Nota basılı tutunca açılan hızlı işlem menüsü: paylaş, kopyala,
/// arşivle, kilitle, seç, sil. Kilitli notun içeriği kimlik doğrulaması
/// yapılmadan paylaşılmaz/kopyalanmaz.
///
/// Yerleşim İKİ SÜTUNLU ızgara: on üç işlem tek sütunlu liste hâlinde ekranın
/// tamamını dolduruyor, "Sil" en altta kaydırma gerektiriyordu. Izgarada hepsi
/// tek bakışta görünür ve sayfa yarı yükseklikte kalır.
Future<void> showNoteActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final l10n = context.l10n;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    // Izgara varsayılan yükseklik sınırına (ekranın 9/16'sı) sığar ama büyük
    // yazı ölçeğinde taşabilir; isScrollControlled + kaydırma güvenlik ağı.
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: _ActionsGrid(note: note, l10n: l10n),
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  await _runNoteAction(context, ref, note, action);
}

/// Not işlemleri: iki sütunlu düğme ızgarası. Her düğme simge + etiket
/// taşıyan dokunma hedefidir; "Sil" ayrı satırda ve uyarı renginde durur ki
/// yıkıcı işlem yanlışlıkla seçilmesin.
class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({required this.note, required this.l10n});

  final Note note;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = note.displayTitle.trim();
    // (aksiyon, etiket, simge) — sıra sık kullanımdan seyreğe.
    final actions = <(String, String, IconData)>[
      (
        'pin',
        note.pinned ? l10n.unpin : l10n.pin,
        note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
      ),
      (
        'star',
        note.starred ? l10n.unstar : l10n.star,
        note.starred ? Icons.star : Icons.star_outline,
      ),
      ('share', l10n.share, Icons.share_outlined),
      ('copy', l10n.copy, Icons.copy_outlined),
      ('select', l10n.select, Icons.check_circle_outline),
      ('folder', l10n.moveToFolder, Icons.folder_outlined),
      ('color', l10n.backgroundColor, Icons.palette_outlined),
      ('frame', l10n.frameColor, Icons.border_color_outlined),
      ('listen', l10n.listenToNote, Icons.headphones_outlined),
      ('pdf', l10n.exportPdf, Icons.picture_as_pdf_outlined),
      (
        'archive',
        note.archivedAt != null ? l10n.unarchive : l10n.archive,
        note.archivedAt != null
            ? Icons.unarchive_outlined
            : Icons.archive_outlined,
      ),
      (
        'lock',
        note.locked ? l10n.unlockNote : l10n.lockNote,
        note.locked ? Icons.lock_open_outlined : Icons.lock_outline,
      ),
    ];

    Widget tile(
      String action,
      String label,
      IconData icon, {
      bool danger = false,
    }) {
      final color = danger ? scheme.error : scheme.onSurface;
      return Material(
        color: danger
            ? scheme.errorContainer.withValues(alpha: 0.4)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(context, action),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // İki sütun: 16 kenar dolgusu + 8 sütun aralığı.
        final cellWidth = (constraints.maxWidth - 40) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (action, label, icon) in actions)
                    SizedBox(
                      width: cellWidth,
                      child: tile(action, label, icon),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Yıkıcı işlem tek başına, tam genişlikte.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: tile(
                'delete',
                l10n.delete,
                Icons.delete_outline,
                danger: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Seçilen işlemi uygular. Kilitli notun içeriğine dokunan işlemler önce
/// kimlik doğrulaması ister.
Future<void> _runNoteAction(
  BuildContext context,
  WidgetRef ref,
  Note note,
  String action,
) async {
  final l10n = context.l10n;

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
          subject: note.displayTitle.trim().isEmpty
              ? l10n.appName
              : note.displayTitle.trim(),
        ),
      );
    case 'listen':
      // Okuma cihazın TTS'i ile yapılır (model çağrısı yok). Kilitli notun
      // içeriği sesli de okunmasın.
      if (!await unlockIfNeeded()) return;
      if (!context.mounted) return;
      final title = note.displayTitle.trim();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ListenScreen(
            title: title.isEmpty ? l10n.appName : title,
            // Kilitli notun podcast metni de diske yazılmasın.
            allowCache: !note.locked,
            // toPlainText değil: başlık ve `- [x]` işaretleri sesli okunmasın.
            loadText: () async => note.toContentText(),
          ),
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
    case 'folder':
      final picked = await showFolderPickSheet(
        context,
        ref,
        currentFolderId: note.folderId,
      );
      if (picked != null) {
        repo.updateFields(note.id, {
          'folderId': picked.isEmpty ? null : picked,
        });
      }
    case 'color':
      final picked = await showNoteColorPicker(
        context,
        frame: false,
        current: note.color,
      );
      if (picked != null) repo.setColor(note.id, picked);
    case 'frame':
      final picked = await showNoteColorPicker(
        context,
        frame: true,
        current: note.frameColor,
      );
      if (picked != null) repo.setFrameColor(note.id, picked);
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
