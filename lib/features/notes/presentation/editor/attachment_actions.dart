import 'package:flutter/material.dart';

import '../../../../core/app_icons.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../domain/attachment.dart';
import 'note_images.dart' show captionTextStyle;

/// **TEK EK MENÜSÜ (TUTARLILIK F40.1).** Aynı ekin menüsü görünüme göre başka
/// ad, başka sıra ve başka alt kümeydi (şerit levhası, yüzen ⋮, sabit ⋮, gömülü
/// önizleme). Bütün yüzeyler listeyi buradan alır; sıra TEK yerde.
///
/// Görünüm geçişi menü maddesi DEĞİL, anahtardır ([AttachmentAction.view]
/// yalnız anahtarın sığmadığı yerde satır olur; K6: "Sayfaya göm", "Ek olarak
/// taşı", "Sayfaya geri koy", "Nota aktar" yok).
enum AttachmentAction {
  open,
  view,
  edit,
  rotate,
  caption,
  transcribe,
  extractText,
  videoToNote,
  copy,
  selectMany,
  share,
  saveAs,
  copyLink,
  openExternal,
  remove,
}

/// Eki gösteren yüzey. Yüzeyin kendi çubuğunda ZATEN görünen iş menüde
/// tekrarlanmaz (K2 kuralı); kalan her şey aynı sırada.
enum AttachmentSurface { strip, floating, pinned, embedded, contextMenu }

/// Çağıranın verebildiği işler (salt okunur not, web, callback yok...).
@immutable
class AttachmentCaps {
  const AttachmentCaps({
    this.open = true,
    this.viewRow = false,
    this.edit = false,
    this.rotate = false,
    this.caption = false,
    this.transcribe = false,
    this.extractText = false,
    this.videoToNote = false,
    this.copy = false,
    this.selectMany = false,
    this.share = true,
    this.saveAs = false,
    this.copyLink = false,
    this.openExternal = false,
    this.remove = false,
  });

  final bool open;

  /// Anahtar yüzeyde sığmıyor: "Görünüm" satırı levhayı açar.
  final bool viewRow;
  final bool edit;

  /// Video döndürme oynatma çubuğuna sığmıyor: menüde.
  final bool rotate;

  /// Görsele açıklama (yüzende çubukta ayrı düğme).
  final bool caption;
  final bool transcribe;
  final bool extractText;
  final bool videoToNote;
  final bool copy;
  final bool selectMany;
  final bool share;
  final bool saveAs;
  final bool copyLink;
  final bool openExternal;
  final bool remove;
}

/// [a] için [surface]'te çizilecek işler, sabit sırayla (saf; test edilir).
List<AttachmentAction> attachmentActionsFor(
  Attachment a,
  AttachmentSurface surface,
  AttachmentCaps caps,
) {
  final web = a.isWebVideo;
  final video = a.kind == AttachmentKind.video;
  final audio = a.kind == AttachmentKind.audio;
  return [
    // Yüzen ve sabitte tam ekran çubuğun kendi düğmesi; ses kartı kendi oynatıcı.
    if (caps.open &&
        !audio &&
        surface != AttachmentSurface.floating &&
        surface != AttachmentSurface.pinned)
      AttachmentAction.open,
    if (caps.viewRow) AttachmentAction.view,
    if (caps.edit) AttachmentAction.edit,
    if (caps.rotate && video && !web) AttachmentAction.rotate,
    if (caps.caption &&
        a.kind == AttachmentKind.image &&
        surface != AttachmentSurface.floating)
      AttachmentAction.caption,
    if (caps.transcribe) AttachmentAction.transcribe,
    if (caps.extractText && a.kind == AttachmentKind.image)
      AttachmentAction.extractText,
    if (caps.videoToNote && video && !web) AttachmentAction.videoToNote,
    if (caps.copy && !web) AttachmentAction.copy,
    if (caps.selectMany) AttachmentAction.selectMany,
    if (caps.share) AttachmentAction.share,
    if (caps.saveAs && !web) AttachmentAction.saveAs,
    if (web && (caps.copy || caps.copyLink)) AttachmentAction.copyLink,
    if (web && caps.openExternal) AttachmentAction.openExternal,
    // Yüzende kaldır çubukta (çöp simgesi).
    if (caps.remove && surface != AttachmentSurface.floating)
      AttachmentAction.remove,
  ];
}

({String label, IconData icon}) attachmentActionLook(
  BuildContext context,
  AttachmentAction action, {
  bool transcribed = false,
}) {
  final l10n = context.l10n;
  return switch (action) {
    AttachmentAction.open => (label: l10n.fullscreen, icon: Icons.fullscreen),
    AttachmentAction.view => (
      label: l10n.viewModeTitle,
      icon: Icons.layers_outlined,
    ),
    AttachmentAction.edit => (
      label: l10n.attachmentTagEdit,
      icon: Icons.edit_outlined,
    ),
    AttachmentAction.rotate => (
      label: l10n.videoRotate,
      icon: Icons.rotate_90_degrees_cw_outlined,
    ),
    AttachmentAction.caption => (
      label: l10n.imageCaptionAdd,
      icon: Icons.short_text_rounded,
    ),
    AttachmentAction.transcribe => (
      label: l10n.transcriptAction,
      icon: transcribed ? Icons.subtitles : Icons.subtitles_outlined,
    ),
    AttachmentAction.extractText => (
      label: l10n.extractText,
      icon: Icons.document_scanner_outlined,
    ),
    AttachmentAction.videoToNote => (
      label: l10n.videoToNote,
      icon: Icons.auto_awesome_outlined,
    ),
    AttachmentAction.copy => (label: l10n.copy, icon: AppIcons.copy),
    AttachmentAction.selectMany => (
      label: l10n.selectImages,
      icon: Icons.checklist,
    ),
    AttachmentAction.share => (label: l10n.share, icon: Icons.share_outlined),
    AttachmentAction.saveAs => (
      label: l10n.attachmentSaveAs,
      icon: Icons.save_alt_outlined,
    ),
    AttachmentAction.copyLink => (label: l10n.copyVideoLink, icon: Icons.link),
    AttachmentAction.openExternal => (
      label: l10n.youTubeOpenExternal,
      icon: Icons.open_in_new,
    ),
    AttachmentAction.remove => (
      label: l10n.removeAttachment,
      icon: Icons.delete_outline,
    ),
  };
}

/// Açılır menü biçimi (yüzen ⋮, sabit ⋮, eke sağ tık).
List<PopupMenuEntry<AttachmentAction>> attachmentPopupItems(
  BuildContext context,
  List<AttachmentAction> actions,
) {
  final error = Theme.of(context).colorScheme.error;
  return [
    for (final action in actions) ...[
      if (action == AttachmentAction.remove && actions.length > 1)
        const PopupMenuDivider(),
      PopupMenuItem(
        value: action,
        child: Builder(
          builder: (context) {
            final look = attachmentActionLook(context, action);
            final danger = action == AttachmentAction.remove;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(look.icon, color: danger ? error : null),
              title: Text(
                look.label,
                style: danger ? TextStyle(color: error) : null,
              ),
            );
          },
        ),
      ),
    ],
  ];
}

/// Levha biçimi (şerit ⋯): aynı liste, satır satır.
List<Widget> attachmentSheetTiles(
  BuildContext context,
  List<AttachmentAction> actions, {
  required ValueChanged<AttachmentAction> onTap,
  bool transcribed = false,
}) {
  final error = Theme.of(context).colorScheme.error;
  return [
    for (final action in actions)
      Builder(
        builder: (context) {
          final look = attachmentActionLook(
            context,
            action,
            transcribed: transcribed,
          );
          final danger = action == AttachmentAction.remove;
          return ListTile(
            key: ValueKey('strip-action-${action.name}'),
            leading: Icon(look.icon, color: danger ? error : null),
            title: Text(
              look.label,
              style: danger ? TextStyle(color: error) : null,
            ),
            onTap: () => onTap(action),
          );
        },
      ),
  ];
}

/// Eke sağ tık (masaüstü, F40.8): aynı liste, imlecin yanında.
Future<AttachmentAction?> showAttachmentContextMenu(
  BuildContext context,
  Offset globalPosition,
  List<AttachmentAction> actions,
) {
  if (actions.isEmpty) return Future.value();
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return showMenu<AttachmentAction>(
    context: context,
    position: RelativeRect.fromRect(
      globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: attachmentPopupItems(context, actions),
  );
}

/// Görsel açıklamasını yazma levhası. Boş dönerse açıklama kalkar; null = vazgeçti.
Future<String?> showCaptionSheet(BuildContext context, String initial) {
  final controller = TextEditingController(text: initial);
  return showAppSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(sheet).bottom,
      ),
      child: TextField(
        key: const ValueKey('caption-sheet-field'),
        controller: controller,
        autofocus: true,
        maxLength: Attachment.maxCaptionChars,
        maxLines: 3,
        minLines: 1,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: sheet.l10n.imageCaptionHint,
          suffixIcon: IconButton(
            key: const ValueKey('caption-sheet-done'),
            tooltip: MaterialLocalizations.of(sheet).okButtonLabel,
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(sheet, controller.text.trim()),
          ),
        ),
        onSubmitted: (v) => Navigator.pop(sheet, v.trim()),
      ),
    ),
  ).whenComplete(controller.dispose);
}

/// Görselin altındaki açıklama, her görünümde aynı stil (F40.7).
class AttachmentCaptionBand extends StatelessWidget {
  const AttachmentCaptionBand({super.key, required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('attachment-caption-band'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: captionTextStyle(Theme.of(context).colorScheme),
      ),
    ),
  );
}
