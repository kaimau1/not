import 'package:flutter/material.dart';

import '../../../app/theme/note_colors.dart';
import '../../../app/theme/note_themes.dart';
import '../../../core/app_icons.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/widgets/action_menu_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/note_shortcut.dart';
import '../data/user_templates.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

/// Not menüsünün açıldığı yer.
enum NoteMenuSurface { card, editor }

/// **TEK NOT MENÜSÜ** (TUTARLILIK F38.1, K2): kart ⋮ ve not ⋮ bu tek katalogdan
/// çizilir; grup ve sıra iki yüzeyde AYNI. Kural:
///
/// 1. Bir iş iki yüzeyde de varsa aynı grupta, aynı sıradadır.
/// 2. O ekranda başka yerde AÇIKÇA duran iş düşer ([visibleElsewhere]: not
///    ekranında üst çubuktaki raptiye ve görünüm, alt çubuktaki Ara ve Paylaş);
///    çubuktan düşen ya da gizlenen iş menüye geri gelir, erişilemez kalmaz.
/// 3. Yalnız bir yüzeyin işi: açık notun içeriğine dokunanlar (sürüm geçmişi,
///    dönüştür, sırala, temizle, hesap makinesi, notta ara) `editor`,
///    çoklu seçim `card`.
///
/// Yeni iş buraya eklenir; handler `_runNoteAction` ve `_openNoteMenu`da.
ActionMenu noteMenuModel(
  AppLocalizations l10n,
  Note note, {
  required NoteMenuSurface surface,
  Set<String> visibleElsewhere = const {},
  bool readOnly = false,
  bool canPinHome = false,
  bool localOnlyAvailable = false,
  bool localOnly = false,
  bool? bubbleView,
  bool canRemoveParts = false,
}) {
  final editor = surface == NoteMenuSurface.editor;
  final archived = note.archivedAt != null;
  final isList =
      note.type == NoteType.checklist || note.type == NoteType.ordered;
  bool shows(String id) => !visibleElsewhere.contains(id);
  return ActionMenu(
    title: note.displayTitle,
    quick: [
      if (shows('pin'))
        MenuAction(
          'pin',
          note.pinned ? l10n.unpin : l10n.pin,
          note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
          selected: note.pinned,
        ),
      MenuAction(
        'star',
        note.starred ? l10n.unstar : l10n.star,
        note.starred ? Icons.star : Icons.star_outline,
        selected: note.starred,
      ),
      MenuAction('folder', l10n.moveToFolder, AppIcons.moveToFolder),
      if (editor) MenuAction('history', l10n.versionHistory, Icons.history),
      MenuAction('listen', l10n.listenToNote, AppIcons.listen),
      if (shows('share')) MenuAction('share', l10n.share, Icons.share_outlined),
    ],
    sections: [
      MenuSection(l10n.menuSectionOrganize, [
        if (!editor)
          MenuAction('select', l10n.select, Icons.check_circle_outline),
        if (!readOnly) ...[
          if (shows('color'))
            MenuAction('color', l10n.backgroundColor, AppIcons.color),
          // Çerçeve yalnız ana ekran kartında çizilir; seçimi iki yerden.
          MenuAction('frame', l10n.frameColor, Icons.border_color_outlined),
          if (note.attachments.isNotEmpty || note.cardMediaHidden)
            MenuAction(
              'cardMedia',
              note.cardMediaHidden ? l10n.cardMediaShow : l10n.cardMediaHide,
              note.cardMediaHidden
                  ? Icons.image_outlined
                  : Icons.hide_image_outlined,
            ),
        ],
        if (editor) ...[
          // Belge notunun sayfa tuvali yok: defter yalnız zaten açıksa görünür.
          if (!note.type.isPageNoteType || note.paged)
            MenuAction(
              'paged',
              note.paged ? l10n.notebookViewOff : l10n.notebookViewOn,
              AppIcons.notebook,
              selected: note.paged,
            ),
          if (note.paged) MenuAction('paper', l10n.archivePaper, Icons.texture),
          if (bubbleView != null)
            MenuAction(
              'docView',
              bubbleView ? l10n.docViewToClassic : l10n.docViewToBubbles,
              bubbleView
                  ? Icons.view_agenda_outlined
                  : Icons.chat_bubble_outline,
            ),
          if (isList) ...[
            MenuAction('toText', l10n.convertToText, Icons.notes_outlined),
            MenuAction('sortItems', l10n.sortItems, Icons.sort),
            MenuAction(
              'columns',
              note.listColumns == 2 ? l10n.listOneColumn : l10n.listTwoColumns,
              note.listColumns == 2
                  ? Icons.view_agenda_outlined
                  : Icons.view_column_outlined,
            ),
          ] else
            MenuAction('toList', l10n.convertToList, Icons.checklist),
          if (canRemoveParts) ...[
            MenuAction(
              'removeList',
              l10n.removeListPart,
              Icons.playlist_remove_rounded,
            ),
            MenuAction(
              'removeText',
              l10n.removeTextPart,
              Icons.format_clear_rounded,
            ),
          ],
          if (note.attachments.any((a) => a.floatsOnPage))
            MenuAction(
              'imagesToFiles',
              l10n.imagesToAttachments,
              Icons.attach_file,
            ),
          MenuAction('clear', l10n.clearNote, Icons.backspace_outlined),
        ],
      ]),
      MenuSection(l10n.menuSectionCopy, [
        MenuAction('duplicate', l10n.duplicateNote, AppIcons.duplicate),
        if (canSaveAsTemplate(note))
          MenuAction(
            'saveTemplate',
            l10n.saveAsTemplate,
            Icons.bookmark_add_outlined,
          ),
        if (editor && note.attachments.isNotEmpty)
          MenuAction('toArchive', l10n.archiveCopyHere, Icons.book_outlined),
      ]),
      MenuSection(l10n.menuSectionTools, [
        if (canPinHome)
          MenuAction(
            'pinHome',
            l10n.pinToHomeScreen,
            Icons.add_to_home_screen_rounded,
          ),
        MenuAction('stats', l10n.noteStatsTitle, Icons.insights_outlined),
        if (editor) ...[
          if (shows('search'))
            MenuAction('search', l10n.noteSearchTitle, AppIcons.search),
          MenuAction(
            'calculator',
            l10n.calculatorTitle,
            Icons.calculate_outlined,
          ),
        ],
      ]),
      MenuSection(l10n.menuSectionProtect, [
        MenuAction(
          'archive',
          archived ? l10n.unarchive : l10n.archive,
          archived ? AppIcons.unarchive : AppIcons.archive,
        ),
        MenuAction(
          'lock',
          note.locked ? l10n.unlockNote : l10n.lockNote,
          note.locked ? Icons.lock_open_outlined : Icons.lock_outline,
        ),
        if (localOnlyAvailable)
          MenuAction(
            'localOnly',
            localOnly ? l10n.localOnlyTurnOff : l10n.localOnlyTurnOn,
            localOnly ? Icons.cloud_sync_outlined : Icons.cloud_off_outlined,
          ),
      ]),
    ],
    danger: MenuAction('delete', l10n.delete, Icons.delete_outline),
    // Notun değil ekranın/uygulamanın işi: en altta ince satır (F12.1).
    footer: [
      if (editor) ...[
        MenuAction('customize', l10n.noteMenuCustomize, Icons.tune_rounded),
        MenuAction('settings', l10n.settings, Icons.settings_outlined),
      ],
    ],
  );
}

/// Notu başlatıcıya kısayol olarak koyar (bkz. [NoteShortcut]). Simge notun
/// AÇIK temadaki rengini taşır (başlatıcı her zaman açık zeminli simge bekler);
/// başlık yoksa gövdenin ilk satırı ad olur.
Future<void> pinNoteToHome(BuildContext context, Note note) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final theme = NoteThemes.byId(note.theme);
  final color =
      theme?.light.top.toARGB32() ??
      note.customColor ??
      (note.color == NoteColor.none
          ? 0xFFFFE08A
          : NoteColors.swatch(note.color).toARGB32());
  var title = note.title.trim();
  if (title.isEmpty) {
    title = stripRichMarkers(note.body)
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => l10n.untitledNote);
  }
  final ok = await NoteShortcut.pin(
    id: note.id,
    title: title,
    body: note.body,
    color: color,
  );
  messenger
    ..hideCurrentSnackBar()
    ..showMessage(ok ? l10n.pinToHomeSent : l10n.pinToHomeUnsupported);
}
