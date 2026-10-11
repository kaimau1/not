import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import 'note_images.dart';
import 'pdf_page_box.dart';

/// YAZIYA GÖMME — baştan tasarım (kullanıcı isteği 2026-10-11: "PDF gömme
/// doğru çalışmıyordu, gömme işini tamamen baştan tasarla; kelimeye video
/// gömme de olsun").
///
/// ESKİ akışın sorunları: (1) gömülecek şey nottaki eklerle sınırlıydı —
/// önce ayrı yoldan ek eklemek, sonra ikinci bir yoldan gömmek gerekiyordu;
/// (2) etikete dokunmak TAM EKRAN görüntüleyiciye atlıyordu (imleci etiketin
/// yanına koymak bile PDF'i açıyordu); (3) gömmeyi kaldırmanın yolu yoktu.
///
/// YENİ akış: seçili yazı → "Göm" → TEK levha: üstte YENİ ekleme (PDF,
/// görsel, video, YouTube — eklenen dosya şeride girer, sayfayı
/// kalabalıklaştırmaz), altta nottaki ekler. Gömülü yazıya dokununca
/// YERİNDE önizleme kartı açılır: video/YouTube kartın içinde oynar, PDF
/// sayfaları kartın içinde çevrilir; tam ekran, düzenle, değiştir ve
/// gömmeyi kaldır düğmeleri oradadır.

/// Seçicinin sonucu: ya var olan bir ek ya da oluşturulacak yeni ekin türü
/// (`pdf`, `image`, `video`, `youtube`).
class EmbedPick {
  const EmbedPick.existing(Attachment this.attachment) : create = null;
  const EmbedPick.create(String this.create) : attachment = null;

  final Attachment? attachment;
  final String? create;
}

IconData embedKindIcon(Attachment a) => a.isWebVideo
    ? Icons.smart_display_outlined
    : switch (a.kind) {
        AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
        AttachmentKind.slide => Icons.slideshow_outlined,
        AttachmentKind.video => Icons.videocam_outlined,
        AttachmentKind.audio => Icons.audiotrack_outlined,
        AttachmentKind.image => Icons.image_outlined,
      };

/// Gömülecek şeyi seçtirir. [label] seçili yazı (boşsa başlıkta gösterilmez).
Future<EmbedPick?> showEmbedPicker(
  BuildContext context, {
  required String label,
  required List<Attachment> attachments,
  bool allowCreate = true,
}) => showModalBottomSheet<EmbedPick>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.75,
  ),
  builder: (sheetContext) => _EmbedPicker(
    label: label,
    attachments: attachments,
    allowCreate: allowCreate,
  ),
);

class _EmbedPicker extends StatelessWidget {
  const _EmbedPicker({
    required this.label,
    required this.attachments,
    required this.allowCreate,
  });

  final String label;
  final List<Attachment> attachments;
  final bool allowCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final creates = <(String, IconData, String)>[
      ('pdf', Icons.picture_as_pdf_outlined, l10n.embedNewPdf),
      ('image', Icons.image_outlined, l10n.embedNewImage),
      ('video', Icons.video_library_outlined, l10n.embedNewVideo),
      ('youtube', Icons.smart_display_outlined, l10n.embedNewYouTube),
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            label.isEmpty ? l10n.embedPickTitle : l10n.embedPickTitleFor(label),
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.embedPickInfo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (allowCreate) ...[
            const SizedBox(height: 16),
            Text(l10n.embedSectionNew, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, icon, text) in creates)
                  ActionChip(
                    key: ValueKey('embed-new-$id'),
                    avatar: Icon(icon, size: 18),
                    label: Text(text),
                    onPressed: () =>
                        Navigator.pop(context, EmbedPick.create(id)),
                  ),
              ],
            ),
          ],
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.embedSectionExisting, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            for (final a in attachments)
              ListTile(
                key: ValueKey('embed-existing-${a.id}'),
                contentPadding: EdgeInsets.zero,
                leading: _Thumb(attachment: a),
                title: Text(
                  a.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(context, EmbedPick.existing(a)),
              ),
          ],
        ],
      ),
    );
  }
}

/// Listedeki küçük resim: görsel/video kendi karesiyle, diğerleri simgeyle.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = attachment;
    final visual = a.kind == AttachmentKind.image || a.isWebVideo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 40,
        child: visual
            ? IgnorePointer(child: NoteMediaBox(attachment: a))
            : ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Icon(embedKindIcon(a), color: scheme.primary),
              ),
      ),
    );
  }
}

/// Gömülü yazıya dokununca açılan ÖNİZLEME kartı. Tam ekrana atlamaz:
/// video/YouTube kartın içinde oynar, PDF sayfaları kartın içinde çevrilir.
Future<void> showEmbedPreview(
  BuildContext context, {
  required Attachment attachment,
  required String label,
  required VoidCallback onOpen,
  required VoidCallback onReplace,
  required VoidCallback onUnlink,
  VoidCallback? onEdit,
  ValueChanged<Attachment>? onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (sheetContext) {
    final l10n = sheetContext.l10n;
    final theme = Theme.of(sheetContext);
    final a = attachment;
    final height = MediaQuery.sizeOf(sheetContext).height * 0.42;
    void then(VoidCallback action) {
      Navigator.pop(sheetContext);
      action();
    }

    final Widget preview;
    if (a.kind == AttachmentKind.pdf) {
      preview = PdfPageBox(attachment: a, onChanged: onChanged ?? (_) {});
    } else if (a.kind == AttachmentKind.image ||
        a.kind == AttachmentKind.video) {
      preview = ColoredBox(
        color: a.kind == AttachmentKind.video
            ? Colors.black
            : theme.colorScheme.surfaceContainerHigh,
        child: NoteMediaBox(
          attachment: a,
          fit: BoxFit.contain,
          inlineWebVideo: true,
        ),
      );
    } else {
      preview = ColoredBox(
        color: theme.colorScheme.surfaceContainerHigh,
        child: Center(
          child: Icon(
            embedKindIcon(a),
            size: 48,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(embedKindIcon(a), color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        a.fileName,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(height: height, child: preview),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('embed-open'),
                  onPressed: () => then(onOpen),
                  icon: const Icon(Icons.fullscreen),
                  label: Text(l10n.fullscreen),
                ),
                if (onEdit != null)
                  OutlinedButton.icon(
                    onPressed: () => then(onEdit),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.attachmentTagEdit),
                  ),
                OutlinedButton.icon(
                  key: const ValueKey('embed-replace'),
                  onPressed: () => then(onReplace),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l10n.embedReplace),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('embed-unlink'),
                  onPressed: () => then(onUnlink),
                  icon: const Icon(Icons.link_off),
                  label: Text(l10n.embedRemove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
