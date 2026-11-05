import 'package:flutter/material.dart';

import '../../../../core/widgets/sheet_header.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/customizable.dart';
import '../add_catalog.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Not editörünün "Ekle" levhası: tek dokunuş → tek levha → her seçenek görünür.
///
/// Seçenekler, adlar ve gruplar "+" paneliyle aynı katalogdan ([addCatalog],
/// F41.1); karo da aynı ([AddTile]). Levhanın döndürdüğü değer seçeneğin
/// kimliğidir (`_showAttachMenu`).
Future<String?> showAttachSheet(
  BuildContext context, {
  bool pageNote = false,
  bool canEmbed = false,
  String? copiedAttachmentName,
}) => showAppSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  // Geniş ekranda karolar yayılmasın (paylaşım hedefi levhasıyla aynı genişlik).
  constraints: BoxConstraints(
    maxWidth: 640,
    maxHeight: MediaQuery.sizeOf(context).height * 0.92,
  ),
  builder: (sheetContext) => _AttachSheet(
    pageNote: pageNote,
    canEmbed: canEmbed,
    copiedAttachmentName: copiedAttachmentName,
  ),
);

class _AttachSheet extends StatelessWidget {
  const _AttachSheet({
    required this.pageNote,
    required this.canEmbed,
    this.copiedAttachmentName,
  });

  /// Belge (PDF/sunum) notu mu? Öyleyse "Yaz" grubu HİÇ gösterilmez: o ekranda
  /// gövde metni de madde listesi de çizilmiyor (içerik sayfa başına tutulan
  /// notlarda), seçenek gösterip hiçbir şey olmaması kullanıcıyı yanıltırdı.
  final bool pageNote;

  /// Gömme seçicisi açılabilir mi?
  final bool canEmbed;

  final String? copiedAttachmentName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final copied = copiedAttachmentName;
    // Gizlenen seçenek yer kaplamaz; düzenleme modunda hepsi görünür, dokunmak
    // gizle/göster yapar (bkz. Customizable). Yapıştır içeriğe göre çıkar,
    // gizlenmez.
    final entries = [
      for (final e in addCatalog(l10n, AddContext.inNote))
        if (!(pageNote && e.group == AddGroup.write) &&
            (e.id != 'embed-attachment' || canEmbed) &&
            (Personalize.editing ||
                Personalize.current.shows(UiItem.attach(e.id))))
          e,
      if (copied != null)
        (
          id: 'paste-attachment',
          group: AddGroup.files,
          icon: Icons.content_paste_go,
          label: l10n.pasteAttachment,
          info: copied,
        ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        10 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: l10n.addAttachment,
            padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
          ),
          for (final group in AddGroup.values)
            if (entries.any((e) => e.group == group))
              _Section(
                title: addGroupTitle(l10n, group),
                entries: [
                  for (final e in entries)
                    if (e.group == group) e,
                ],
              ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.entries});

  final String title;
  final List<AddEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
        child: SectionLabel(title),
      ),
      AddTileGrid(
        count: entries.length,
        tile: (i, wide) {
          final e = entries[i];
          // Yapıştırılacak ekin adı karoda yazılır: neyin yapıştırılacağı
          // görünmeden basılmaz.
          final paste = e.id == 'paste-attachment';
          return Customizable(
            id: UiItem.attach(e.id),
            badgeInset: 6,
            child: AddTile(
              icon: e.icon,
              label: wide && paste ? '${e.label} · ${e.info}' : e.label,
              subtitle: !wide && paste ? e.info : null,
              tooltip: e.info,
              wide: wide,
              onTap: () => Navigator.pop(context, e.id),
            ),
          );
        },
      ),
    ],
  );
}
