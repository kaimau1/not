import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../domain/attachment.dart';
import '../../../../core/widgets/sheet_keyboard.dart';
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

  /// ÜSTÜNE YAZI EKLE (kullanıcı isteği 2026-11-09: "görsel ve PDF üzerine
  /// hızlı açık metin ekleme, tüm ek tiplerinde tek buton"): tam ekranı
  /// açık metin bırakma kipinde açar. Sabit bölmede çubukta doğrudan "T".
  addText,
  rotate,
  caption,
  rename,
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
    this.addText = false,
    this.rotate = false,
    this.caption = false,
    this.rename = false,
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

  /// Görsel/PDF'e açık metin yazılabilir (yazılabilir not).
  final bool addText;

  /// Video döndürme oynatma çubuğuna sığmıyor: menüde.
  final bool rotate;

  /// Görsele açıklama (yüzende çubukta ayrı düğme).
  final bool caption;
  final bool rename;
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
    // Yüzende ve sabitte çubuğun kendi "T" düğmesi.
    if (caps.addText &&
        (a.kind == AttachmentKind.image || a.kind == AttachmentKind.pdf) &&
        surface != AttachmentSurface.floating &&
        surface != AttachmentSurface.pinned)
      AttachmentAction.addText,
    if (caps.rotate && video && !web) AttachmentAction.rotate,
    if (caps.caption &&
        a.kind == AttachmentKind.image &&
        surface != AttachmentSurface.floating)
      AttachmentAction.caption,
    if (caps.rename) AttachmentAction.rename,
    if (caps.transcribe) AttachmentAction.transcribe,
    if (caps.extractText && a.kind == AttachmentKind.image)
      AttachmentAction.extractText,
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
    AttachmentAction.addText => (
      label: l10n.attachmentAddText,
      icon: Icons.title,
    ),
    AttachmentAction.rotate => (
      label: l10n.videoRotate,
      icon: Icons.rotate_90_degrees_cw_outlined,
    ),
    AttachmentAction.caption => (
      label: l10n.imageCaptionAdd,
      icon: Icons.short_text_rounded,
    ),
    AttachmentAction.rename => (
      label: l10n.attachmentRename,
      icon: Icons.drive_file_rename_outline,
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
///
/// T10 KÖK NEDEN: denetleyici burada kurulup gelecek bitince
/// (`whenComplete`) atılıyordu; gelecek `pop` anında biter ama levha kapanış
/// animasyonu boyunca alanı yeniden çizer — atılmış denetleyici kullanılıyordu
/// ("used after being disposed"). Denetleyici artık levhanın KENDİ durumunda:
/// rota ağaçtan kalkınca atılır.
Future<String?> showCaptionSheet(BuildContext context, String initial) =>
    showAppSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CaptionSheet(initial: initial),
    );

class _CaptionSheet extends StatefulWidget {
  const _CaptionSheet({required this.initial});

  final String initial;

  @override
  State<_CaptionSheet> createState() => _CaptionSheetState();
}

class _CaptionSheetState extends State<_CaptionSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetInsetPadding(
    extra: 16,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        key: const ValueKey('caption-sheet-field'),
        controller: _controller,
        autofocus: true,
        maxLength: Attachment.maxCaptionChars,
        maxLines: 3,
        minLines: 1,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: context.l10n.imageCaptionHint,
          suffixIcon: IconButton(
            key: const ValueKey('caption-sheet-done'),
            tooltip: MaterialLocalizations.of(context).okButtonLabel,
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
          ),
        ),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
    ),
  );
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

/// Dosya uzantısını (ör. `.pdf`, `.png`) kullanıcı yeni bir uzantı yazmadığı
/// sürece koruyarak yeni ek adını üretir.
String resolveRenamedAttachmentName(String input, String currentName) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  final dot = currentName.lastIndexOf('.');
  final hasExt = dot > 0 && dot < currentName.length - 1;
  if (!trimmed.contains('.') && hasExt) {
    final ext = currentName.substring(dot);
    if (ext.length <= 8 && !ext.contains(' ')) {
      return '$trimmed$ext';
    }
  }
  return trimmed;
}

/// Ek dosyasının adını düzenler; uzantıyı (örn. `.pdf`) korur.
Future<String?> showRenameAttachmentSheet(
  BuildContext context, {
  required String currentName,
}) {
  final dot = currentName.lastIndexOf('.');
  final hasExt =
      dot > 0 &&
      dot < currentName.length - 1 &&
      currentName.length - dot <= 8 &&
      !currentName.substring(dot).contains(' ');
  final base = hasExt ? currentName.substring(0, dot) : currentName;
  final ext = hasExt ? currentName.substring(dot) : '';
  return showDialog<String>(
    context: context,
    builder: (_) => _RenameAttachmentDialog(
      initialBase: base,
      ext: ext,
      currentName: currentName,
    ),
  );
}

class _RenameAttachmentDialog extends StatefulWidget {
  const _RenameAttachmentDialog({
    required this.initialBase,
    required this.ext,
    required this.currentName,
  });

  final String initialBase;
  final String ext;
  final String currentName;

  @override
  State<_RenameAttachmentDialog> createState() =>
      _RenameAttachmentDialogState();
}

class _RenameAttachmentDialogState extends State<_RenameAttachmentDialog> {
  late final TextEditingController _ctl =
      TextEditingController(text: widget.initialBase)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialBase.length,
        );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _submit() {
    final next = resolveRenamedAttachmentName(_ctl.text, widget.currentName);
    if (next.isEmpty) return;
    Navigator.pop(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.attachmentRename),
      content: TextField(
        key: const ValueKey('attachment-rename-input'),
        controller: _ctl,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.attachmentRenameHint,
          suffixText: widget.ext.isEmpty ? null : widget.ext,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('attachment-rename-save'),
          onPressed: _submit,
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
