import 'package:flutter/material.dart';
import '../../calendar/presentation/note_calendar_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../ai/presentation/listen_screen.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/presentation/folder_sheets.dart';
import '../data/attachment_repository.dart';
import '../data/note_shortcut.dart';
import '../data/note_speech.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import 'color_picker_sheet.dart';
import 'local_only_action.dart';
import 'note_menu_model.dart';
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
/// Liste tek katalogdan: [noteMenuModel] (F38.1).
Future<void> showNoteActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final l10n = context.l10n;
  final menu = noteMenuModel(
    l10n,
    note,
    surface: NoteMenuSurface.card,
    canPinHome: NoteShortcut.supported,
    localOnlyAvailable: localOnlySupported(ref),
    localOnly: note.localOnly,
  );
  final action = await showAppSheet<String>(
    context: context,
    // Başlıklı menüde ✕ var, tutamak yok (DENEYIM K-D7).
    showDragHandle: !menu.hasHeader,
    // Izgara varsayılan yükseklik sınırına (ekranın 9/16'sı) sığar ama büyük
    // yazı ölçeğinde taşabilir; isScrollControlled + kaydırma güvenlik ağı.
    isScrollControlled: true,
    builder: (sheetContext) =>
        SafeArea(child: SingleChildScrollView(child: menu)),
  );
  if (action == null || !context.mounted) return;
  await _runNoteAction(context, ref, note, action);
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
    case 'pinHome':
      await pinNoteToHome(context, note);
    case 'pin':
      repo.setPinned(note.id, !note.pinned);
    case 'star':
      repo.setStarred(note.id, !note.starred);
    case 'cardMedia':
      repo.setCardMediaHidden(note.id, !note.cardMediaHidden);
    // Üç yol tek levhada: düz metin, `.notpaket` (başka bir Not kullanıcısına,
    // balonlar düzenlenebilir gelir) ve balonlu PDF (herkes açabilir).
    case 'share':
      if (!await unlockIfNeeded()) return;
      if (!context.mounted) return;
      await showNoteShareSheet(context, ref, note);
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
      // Bölünmüş notun balonları ağır kısımda — önce tam hâli (F13.1).
      final full = await hydrateNote(ref, note);
      await Clipboard.setData(
        ClipboardData(text: noteShareText(full, pageLabel: l10n.pageLabel)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showMessage(l10n.copied);
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
    case 'calendar':
      await showLinkNoteToCalendarSheet(context, note);
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
        currentCustom: note.customColor,
      );
      if (picked != null) {
        repo.setColor(note.id, picked.color, custom: picked.custom);
      }
    case 'frame':
      final picked = await showNoteColorPicker(
        context,
        frame: true,
        current: note.frameColor,
        currentCustom: note.customFrameColor,
      );
      if (picked != null) {
        repo.setFrameColor(note.id, picked.color, custom: picked.custom);
      }
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
