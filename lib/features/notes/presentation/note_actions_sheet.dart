import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../ai/presentation/listen_screen.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/presentation/folder_sheets.dart';
import '../../inbox/presentation/send_note_sheet.dart';
import '../data/attachment_repository.dart';
import '../data/note_speech.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import 'color_picker_sheet.dart';
import 'note_stats_sheet.dart';
import 'notes_providers.dart';
import 'pdf_export_screen.dart';
import 'share_sheet.dart';

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
      // Tek "Paylaş": düz metin / not paketi / balonlu PDF seçimi levhada
      // yapılır (bkz. showNoteShareSheet). Eskiden ızgarada iki ayrı kutu
      // vardı ve "Paylaş" PDF notunda sessizce hiçbir şey yapmıyordu.
      ('share', l10n.share, Icons.share_outlined),
      // **ARKADAŞA GÖNDER** (kullanıcı isteği 2026-08-18): sistem paylaşım
      // levhasından AYRI bir kutu — o, notu uygulamanın DIŞINA çıkarır;
      // bu, uygulamanın içinde bir kişinin gelen kutusuna bırakır.
      ('sendToFriend', l10n.sendNoteAction, Icons.send_outlined),
      ('copy', l10n.copy, Icons.copy_outlined),
      // **NOTU ÇOĞALT** — bir notu şablon gibi kullanmanın (haftalık liste,
      // toplantı notu) tek yolu metnini kopyalayıp yeni bir nota
      // yapıştırmaktı; biçim, renk, etiket ve madde işaretleri yolda
      // kayboluyordu (bkz. NotesRepository.duplicateNote).
      ('duplicate', l10n.duplicateNote, Icons.content_copy_outlined),
      ('select', l10n.select, Icons.check_circle_outline),
      ('folder', l10n.moveToFolder, Icons.folder_outlined),
      ('color', l10n.backgroundColor, Icons.palette_outlined),
      ('frame', l10n.frameColor, Icons.border_color_outlined),
      ('listen', l10n.listenToNote, Icons.headphones_outlined),
      // **İSTATİSTİK**: uzun bir notun ne kadar uzun olduğu yalnız
      // kaydırarak anlaşılıyordu.
      ('stats', l10n.noteStatsTitle, Icons.insights_outlined),
      // "PDF olarak dışa aktar" DEĞİL: belge notunda çıktı balonlu PDF de
      // olabiliyor, metin notunda Word de üretiliyor (bkz. `_runNoteAction`).
      ('pdf', l10n.exportTitle, Icons.ios_share_outlined),
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
    // Üç yol tek levhada: düz metin, `.notpaket` (başka bir Not kullanıcısına,
    // balonlar düzenlenebilir gelir) ve balonlu PDF (herkes açabilir).
    case 'share':
      if (!await unlockIfNeeded()) return;
      if (!context.mounted) return;
      await showNoteShareSheet(context, ref, note);
    case 'sendToFriend':
      // Kilitli notun içeriği doğrulamasız GÖNDERİLMESİN: kopya karşı
      // tarafta kilitsiz açılır (paylaş/kopyala ile aynı gerekçe).
      if (!await unlockIfNeeded()) return;
      if (!context.mounted) return;
      await showSendNoteToFriendSheet(context, ref, note);
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
            // BELGE notunda belgenin kendi metni de okunur (bkz.
            // noteSpeechText) — sayfa notları boşsa okuma boş kalmasın.
            loadText: () =>
                noteSpeechText(note, ref.read(attachmentRepositoryProvider)),
          ),
        ),
      );
    case 'pdf':
      // Kilitli notun içeriği PDF'e de kimlik doğrulaması olmadan çıkmasın.
      if (!await unlockIfNeeded()) return;
      if (!context.mounted) return;
      // Balonlu/çizimli belge taşıyan notta hangi çıktının istendiği
      // SORULUR: dışa aktarma eskiden her tipte aynı ekrana gidiyor ve
      // belge notunda yalnız sayfa notlarının metnini yazıyordu — belgenin
      // kendisi, balonlar ve el yazısı hiç çıkmıyordu (bkz. editördeki
      // `_export`, aynı kök neden).
      if (countStampablePdfs(note) > 0) {
        final choice = await showExportChoiceSheet(context);
        if (choice == null || !context.mounted) return;
        if (choice == 'document') {
          await runNoteShare(context, ref, note, 'pdf');
          return;
        }
        if (!context.mounted) return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PdfExportScreen(note: note)),
      );
    case 'copy':
      if (!await unlockIfNeeded()) return;
      // Paylaşımla AYNI biçim (bkz. noteShareText): `- [ ]` işaretleri yok.
      await Clipboard.setData(
        ClipboardData(
          text: noteShareText(note, pageLabel: l10n.pageLabel),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.copied)));
      }
    case 'duplicate':
      if (!await unlockIfNeeded()) return;
      final repo = ref.read(notesRepositoryProvider);
      if (repo == null) return;
      final id = await repo.duplicateNote(note);
      if (!context.mounted) return;
      showUndoSnackBar(
        context,
        // EKLER KOPYALANMAZ (bilinçli: Storage'da notun kimliği altında
        // duruyorlar, kopyalamak her dosyayı indirip yeniden yüklemek olurdu).
        // Ekli bir not çoğaltılınca bu SÖYLENİR — kullanıcı kopyada eklerin
        // olmadığını fark edemiyordu (KALANLAR 2026-09-05).
        message: note.attachments.isEmpty
            ? l10n.noteDuplicated
            : l10n.noteDuplicatedNoAttachments,
        undoLabel: l10n.undo,
        // Kopya HENÜZ hiç düzenlenmedi: geri alma onu kalıcı siler, çöpe
        // düşürüp kullanıcıya ikinci bir temizlik işi bırakmaz.
        onUndo: () => repo.hardDelete(id),
      );
    case 'stats':
      if (!await unlockIfNeeded()) return;
      if (context.mounted) await showNoteStatsSheet(context, note);
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
      // Kilitli not kimlik doğrulamasız SİLİNMESİN: paylaş/kopyala/dinle/PDF
      // hep doğrulama isterken silme istemiyordu — çöp+geri al olsa da
      // koruma modeliyle tutarsızdı (30 gün sonra kalıcı gider).
      if (!await unlockIfNeeded()) return;
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
