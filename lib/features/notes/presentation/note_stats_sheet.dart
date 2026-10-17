import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../domain/note.dart';
import '../domain/note_stats.dart';
import 'note_card.dart' show formatNoteDate;
import '../../../core/widgets/app_sheet.dart';

/// Notun sayısal özeti (kelime, karakter, madde, ek, okuma süresi) ve
/// oluşturma/güncelleme tarihleri.
///
/// NEDEN: "bu not ne kadar uzun?", "kaç maddeden kaçını bitirdim?", "bunu ne
/// zaman yazmıştım?" sorularının hiçbirinin cevabı uygulamada yoktu; not
/// kartındaki tek tarih son güncelleme tarihiydi.
Future<void> showNoteStatsSheet(BuildContext context, Note note) {
  final l10n = context.l10n;
  final stats = NoteStats.of(note);
  return showAppSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final textTheme = Theme.of(sheetContext).textTheme;
      Widget row(IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: textTheme.bodyMedium)),
          ],
        ),
      );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(l10n.noteStatsTitle, style: textTheme.titleMedium),
            ),
            row(Icons.text_fields, l10n.noteStatsWords(stats.words)),
            row(Icons.abc_outlined, l10n.noteStatsChars(stats.characters)),
            if (stats.readMinutes > 0)
              row(
                Icons.schedule_outlined,
                l10n.noteStatsReadTime(stats.readMinutes),
              ),
            if (stats.items > 0)
              row(
                Icons.checklist_outlined,
                // İşaretli/toplam: yapılacaklar listesinde asıl merak edilen.
                '${l10n.noteStatsItems(stats.items)}'
                ' · ${stats.checkedItems}/${stats.items}',
              ),
            if (stats.attachments > 0)
              row(
                Icons.attach_file_outlined,
                l10n.noteStatsAttachments(stats.attachments),
              ),
            const Divider(height: 20),
            if (note.createdAt != null)
              row(
                Icons.event_outlined,
                '${l10n.sortCreated}: ${formatNoteDate(note.createdAt!)}',
              ),
            if (note.updatedAt != null)
              row(
                Icons.update_outlined,
                '${l10n.sortUpdated}: ${formatNoteDate(note.updatedAt!)}',
              ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
