import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../ai/presentation/listen_screen.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/action_menu_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/presentation/folder_sheets.dart';
import '../../inbox/presentation/send_note_sheet.dart';
import '../data/attachment_repository.dart';
import '../data/note_speech.dart';
import '../data/notes_repository.dart';
import '../data/user_templates.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import 'color_picker_sheet.dart';
import 'local_only_action.dart';
import 'note_stats_sheet.dart';
import 'note_template_sheet.dart';
import 'notes_providers.dart';
import 'pdf_export_screen.dart';
import 'share_sheet.dart';
import '../../../core/widgets/app_sheet.dart';

/// Nota basılı tutunca açılan hızlı işlem menüsü: paylaş, kopyala,
/// arşivle, kilitle, seç, sil. Kilitli notun içeriği kimlik doğrulaması
/// yapılmadan paylaşılmaz/kopyalanmaz.
///
/// Yerleşim: hızlı satır + başlıklı gruplar + ayrı "Sil" (bkz.
/// [ActionMenu]).
Future<void> showNoteActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final l10n = context.l10n;
  final action = await showAppSheet<String>(
    context: context,
    showDragHandle: true,
    // Izgara varsayılan yükseklik sınırına (ekranın 9/16'sı) sığar ama büyük
    // yazı ölçeğinde taşabilir; isScrollControlled + kaydırma güvenlik ağı.
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: _ActionsGrid(
          note: note,
          l10n: l10n,
          localOnlyAvailable: localOnlySupported(ref),
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  await _runNoteAction(context, ref, note, action);
}

/// Not işlemleri levhası; "Sil" ayrı satırda ve uyarı renginde durur ki
/// yıkıcı işlem yanlışlıkla seçilmesin.
class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({
    required this.note,
    required this.l10n,
    this.localOnlyAvailable = false,
  });

  final Note note;
  final AppLocalizations l10n;

  /// "Senkronu kapat/aç" gösterilsin mi (bkz. `localOnlySupported`).
  final bool localOnlyAvailable;

  @override
  Widget build(BuildContext context) {
    // Gruplar ve sıra: bkz. [ActionMenu] (2026-10-11 yeniden düzen).
    return ActionMenu(
      title: note.displayTitle,
      quick: [
        MenuAction(
          'pin',
          note.pinned ? l10n.unpin : l10n.pin,
          note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
          selected: note.pinned,
        ),
        // YILDIZLA GERİ GELDİ (kullanıcı isteği 2026-10-20) — sabitlemeden
        // ayrı bir işaret; Süz → "Yıldızlı" ile bulunur.
        MenuAction(
          'star',
          note.starred ? l10n.unstar : l10n.star,
          note.starred ? Icons.star : Icons.star_outline,
          selected: note.starred,
        ),
        // Tek "Paylaş": düz metin, kopyala, PDF/görsel, ARKADAŞA GÖNDER, ortak
        // not ve DIŞA AKTAR hepsi levhada (bkz. showNoteShareSheet).
        // TOPARLAMA (kullanıcı isteği 2026-10-17: "tekrarlar düzelsin"):
        // "Arkadaşa gönder", "Kopyala" ve "Dışa aktar" bu menüden kalktı —
        // aynı işin iki kapısı kafa karıştırıyordu.
        MenuAction('share', l10n.share, Icons.share_outlined),
        MenuAction('select', l10n.select, Icons.check_circle_outline),
      ],
      sections: [
        MenuSection(l10n.menuSectionOrganize, [
          MenuAction('folder', l10n.moveToFolder, Icons.folder_outlined),
          MenuAction('color', l10n.backgroundColor, Icons.palette_outlined),
          // ÇERÇEVE GERİ GELDİ — yalnız ana ekran kartında çizilir.
          MenuAction('frame', l10n.frameColor, Icons.border_color_outlined),
        ]),
        MenuSection(l10n.menuSectionCopy, [
          // **NOTU ÇOĞALT** (bkz. NotesRepository.duplicateNote).
          MenuAction(
            'duplicate',
            l10n.duplicateNote,
            Icons.library_add_outlined,
          ),
          // KENDİ ŞABLONUM (kullanıcı isteği 2026-09-29).
          if (canSaveAsTemplate(note))
            MenuAction(
              'saveTemplate',
              l10n.saveAsTemplate,
              Icons.bookmark_add_outlined,
            ),
        ]),
        MenuSection(l10n.menuSectionTools, [
          MenuAction('listen', l10n.listenToNote, Icons.headphones_outlined),
          MenuAction('stats', l10n.noteStatsTitle, Icons.insights_outlined),
        ]),
        MenuSection(l10n.menuSectionProtect, [
          MenuAction(
            'archive',
            note.archivedAt != null ? l10n.unarchive : l10n.archive,
            note.archivedAt != null
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
          ),
          MenuAction(
            'lock',
            note.locked ? l10n.unlockNote : l10n.lockNote,
            note.locked ? Icons.lock_open_outlined : Icons.lock_outline,
          ),
          // NOTA ÖZEL SENKRON (kullanıcı isteği 2026-09-26). Web'de yok.
          if (localOnlyAvailable)
            MenuAction(
              'localOnly',
              note.localOnly ? l10n.localOnlyTurnOff : l10n.localOnlyTurnOn,
              note.localOnly
                  ? Icons.cloud_sync_outlined
                  : Icons.cloud_off_outlined,
            ),
        ]),
      ],
      danger: MenuAction('delete', l10n.delete, Icons.delete_outline),
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
    case 'localOnly':
      if (!context.mounted) return;
      await toggleNoteLocalOnly(context, ref, note);
    case 'copy':
      if (!await unlockIfNeeded()) return;
      // Paylaşımla AYNI biçim (bkz. noteShareText): `- [ ]` işaretleri yok.
      await Clipboard.setData(
        ClipboardData(text: noteShareText(note, pageLabel: l10n.pageLabel)),
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
    case 'saveTemplate':
      if (!await unlockIfNeeded()) return;
      if (context.mounted) await saveNoteAsTemplate(context, ref, note);
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
      // Kart önce küçülüp solar (bkz. leavingNotesProvider), sonra silinir.
      await ref.read(leavingNotesProvider.notifier).leave([note.id], () {
        repo.softDelete(note.id);
      });
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
