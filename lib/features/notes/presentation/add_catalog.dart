import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../data/document_scan.dart';
import 'qr_scan_screen.dart';

/// **TEK "EKLE" KATALOĞU** (TUTARLILIK F41.1–F41.2): "+" paneli (yeni not) ve
/// not içindeki Ekle levhası aynı satırları okur; ad, simge ve grup burada bir
/// kez yazılır, yüzey yalnız kendi alt kümesini alır. Kişiselleştir ekranı da
/// aynı listeden kurulur.
enum AddGroup { write, pen, camera, files, sound, template }

/// Listenin okunduğu yer.
enum AddContext { newNote, inNote }

String addGroupTitle(AppLocalizations l10n, AddGroup group) => switch (group) {
  AddGroup.write => l10n.addGroupWrite,
  AddGroup.pen => l10n.addGroupPen,
  AddGroup.camera => l10n.quickAddCamera,
  AddGroup.files => l10n.addGroupFiles,
  AddGroup.sound => l10n.addGroupSound,
  AddGroup.template => l10n.addGroupTemplate,
};

/// [id] kalıcı tercih anahtarıdır (`UiItem.quickAdd` / `UiItem.attach`):
/// kimlikler eski kayıtlar bozulmasın diye iki yüzeyde farklı kalır.
typedef AddEntry = ({
  String id,
  AddGroup group,
  IconData icon,
  String label,
  String? info,
});

/// Bağlamın seçenekleri, grup sırasıyla. Platformda olmayanlar düşer.
///
/// Bilinçli farklar: "Metin notu" yeni not, "Metin ekle" not içi; Görsel ve
/// Ses kaydı yalnız not içinde; PDF ayrı satır değil, "Dosya ekle"de
/// (kullanıcı kararı 2026-10-20). Dikte ve AI sesli not not içinde alt çubuğun
/// kapsülünde, ana ekranda tek mikrofonda (K2: bir iş, bir yer).
List<AddEntry> addCatalog(
  AppLocalizations l10n,
  AddContext context, {
  bool web = kIsWeb,
}) {
  final inNote = context == AddContext.inNote;
  final out = <AddEntry>[];
  void row(
    AddGroup group,
    IconData icon,
    String label, {
    String? quick,
    String? attach,
    String? info,
  }) {
    final id = inNote ? attach : quick;
    if (id == null) return;
    out.add((id: id, group: group, icon: icon, label: label, info: info));
  }

  row(AddGroup.write, Icons.notes, l10n.newTextNote, quick: 'text');
  row(AddGroup.write, Icons.notes, l10n.addTextBlock, attach: 'text-block');
  row(
    AddGroup.write,
    Icons.check_box_outlined,
    l10n.newChecklist,
    quick: 'checklist',
    attach: 'list-item',
  );
  row(
    AddGroup.write,
    Icons.format_list_numbered_rounded,
    l10n.newOrderedList,
    quick: 'ordered',
  );
  row(
    AddGroup.write,
    Icons.link,
    l10n.attachmentTagEmbed,
    attach: 'embed-attachment',
    info: l10n.attachmentTagEmbedInfo,
  );
  row(
    AddGroup.pen,
    Icons.draw_outlined,
    l10n.addHandwriting,
    quick: 'draw',
    attach: 'handwriting',
    info: l10n.addHandwritingSubtitle,
  );
  row(
    AddGroup.pen,
    Icons.brush_outlined,
    l10n.addSeparateDrawing,
    quick: 'drawing',
    attach: 'drawing',
    info: l10n.addDrawingSubtitle,
  );
  row(
    AddGroup.camera,
    Icons.photo_camera_outlined,
    l10n.newPhotoNote,
    quick: 'photo',
    attach: web ? null : 'camera',
  );
  row(
    AddGroup.camera,
    Icons.videocam_outlined,
    l10n.newVideoNote,
    quick: 'video',
    attach: web ? null : 'video',
    info: l10n.videoLocalOnly,
  );
  if (DocumentScan.available) {
    row(
      AddGroup.camera,
      Icons.document_scanner_outlined,
      l10n.newScanNote,
      quick: 'scan',
      attach: 'scan',
      info: l10n.scanDocumentSubtitle,
    );
  }
  if (qrScanSupported) {
    row(
      AddGroup.camera,
      Icons.qr_code_scanner,
      l10n.qrScanTitle,
      quick: 'qr',
      attach: 'qr',
      info: l10n.qrScanSubtitle,
    );
  }
  row(
    AddGroup.files,
    Icons.upload_file_outlined,
    l10n.quickAddFile,
    quick: 'file',
    attach: 'any-file',
    info: l10n.attachAnyFileInfo,
  );
  row(
    AddGroup.files,
    Icons.image_outlined,
    l10n.addImage,
    attach: 'image',
    info: l10n.addImageOnPageSubtitle,
  );
  row(
    AddGroup.files,
    Icons.smart_display_outlined,
    l10n.quickAddYouTube,
    quick: 'youtube',
    attach: 'youtube',
    info: l10n.addYouTubeVideoSubtitle,
  );
  row(AddGroup.sound, Icons.graphic_eq, l10n.newVoiceCapture, quick: 'voice');
  row(
    AddGroup.sound,
    Icons.mic_none,
    l10n.recordAudio,
    attach: web ? null : 'audio',
  );
  row(
    AddGroup.template,
    Icons.dashboard_customize_outlined,
    l10n.fromTemplate,
    quick: 'template',
  );
  row(
    AddGroup.template,
    Icons.shopping_cart_outlined,
    l10n.tplShoppingName,
    quick: 'shopping',
  );
  row(
    AddGroup.template,
    Icons.book_outlined,
    l10n.archiveNotebook,
    quick: 'archive',
  );
  return out;
}

/// Ekle yüzeylerinin TEK karosu (F41.3): "+" paneli, Ekle levhası, gömme
/// seçicisi. Renk yalnız simgede; [accent] verilmezse uygulamanın ana rengi
/// (gömme seçicisi ek türünün rengini verir).
class AddTile extends StatelessWidget {
  const AddTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.wide = false,
    this.subtitle,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  /// Geniş karo: simge solda, ad sağında tek satır.
  final bool wide;

  /// Adın altında tek satır (yapıştırılacak ekin adı).
  final String? subtitle;

  /// Uzun basınca görünen açıklama.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final circle = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
    final sub = subtitle;
    final tile = Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: wide
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    circle,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    circle,
                    const SizedBox(height: 5),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: sub == null ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
      ),
    );
    return tooltip == null ? tile : Tooltip(message: tooltip, child: tile);
  }
}

/// Karoların TEK dizilim kuralı: en çok iki karo satırı geniş doldurur, fazlası
/// genişliğe göre sütunlanır (telefonda 4); az karo satırı boş bırakmaz.
class AddTileGrid extends StatelessWidget {
  const AddTileGrid({super.key, required this.count, required this.tile});

  final int count;

  /// `wide`: karo geniş mi çizilmeli.
  final Widget Function(int index, bool wide) tile;

  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    // Yazı ölçeğiyle büyür: büyük yazıda ad karodan taşmasın.
    final scaler = MediaQuery.textScalerOf(context);
    if (count <= 2) {
      return Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(
              child: SizedBox(height: scaler.scale(52), child: tile(i, true)),
            ),
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 80).floor().clamp(3, 8);
        final perRow = columns < count ? columns : count;
        final width = (constraints.maxWidth - _gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: width,
                height: scaler.scale(76),
                child: tile(i, false),
              ),
          ],
        );
      },
    );
  }
}
