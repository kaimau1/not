import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import 'note_images.dart';
import 'pdf_page_box.dart';
import 'tag_chips.dart';

/// YAZIYA GÖMME — baştan tasarım (kullanıcı isteği 2026-10-11: "PDF gömme
/// doğru çalışmıyordu, gömme işini tamamen baştan tasarla; kelimeye video
/// gömme de olsun").
///
/// ESKİ akışın sorunları: (1) gömülecek şey nottaki eklerle sınırlıydı —
/// önce ayrı yoldan ek eklemek, sonra ikinci bir yoldan gömmek gerekiyordu;
/// (2) etikete dokunmak TAM EKRAN görüntüleyiciye atlıyordu (imleci etiketin
/// yanına koymak bile PDF'i açıyordu); (3) gömmeyi kaldırmanın yolu yoktu.
///
/// YENİ akış: seçili yazı → "Ek göm" → TEK levha: üstte nottaki ekler
/// (küçük resimleriyle, tek dokunuşla), altta YENİ ekleme (PDF, görsel,
/// video, YouTube — eklenen dosya şeride girer, sayfayı kalabalıklaştırmaz).
/// Gömülü yazıya dokununca YERİNDE önizleme kartı açılır: video/YouTube
/// kartın içinde oynar, PDF sayfaları kartın içinde çevrilir; tam ekran,
/// düzenle, değiştir ve gömmeyi kaldır düğmeleri oradadır.
///
/// **2026-10-15 yenilemesi** ("ek gömmenin tüm akışı ve görüntüsü
/// yenilenmeli"): gömülü yazı editörde türün renginde bir ÇİP ve rozetle
/// çizilir (bkz. [AttachmentTagChips]); seçici ile önizleme kartı da aynı
/// renk/simge dilini konuşur — PDF kırmızı, görsel turkuaz, video mor…

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
        AttachmentKind.text => Icons.subject,
      };

/// Ekin türünün rengi — editördeki çip, seçici ve önizleme kartı aynı rengi
/// kullanır ki "bu bir PDF" bir bakışta okunsun.
Color embedKindColor(Attachment a) => a.isWebVideo
    ? _webVideoColor
    : switch (a.kind) {
        AttachmentKind.pdf => _pdfColor,
        AttachmentKind.slide => _slideColor,
        AttachmentKind.video => _videoColor,
        AttachmentKind.audio => _audioColor,
        AttachmentKind.image => _imageColor,
        AttachmentKind.text => _textColor,
      };

const _pdfColor = Color(0xFFD32F2F);
const _imageColor = Color(0xFF00897B);
const _videoColor = Color(0xFF7B1FA2);
const _webVideoColor = Color(0xFFAD1457);
const _slideColor = Color(0xFFEF6C00);
const _audioColor = Color(0xFF1565C0);
const _textColor = Color(0xFF6D4C41);

/// Notun bütün etiket adlarının (bağ etiketleri + dosya adları) görünümü.
/// Çözüm kuralı editördeki `_attachmentForTag` ile aynı: aynı ad hem bağ
/// etiketi hem dosya adıysa BAĞ kazanır. Koyu temada renk açılır: koyu
/// zeminde koyu kırmızı yazı okunmuyordu.
Map<String, TagLook> embedTagLooks(Note note, {bool dark = false}) {
  if (note.attachments.isEmpty) return const {};
  final byId = {for (final a in note.attachments) a.id: a};
  TagLook look(Attachment a) {
    final color = embedKindColor(a);
    return TagLook(
      embedKindIcon(a),
      dark ? Color.lerp(color, Colors.white, 0.3)! : color,
    );
  }

  return {
    for (final a in note.attachments)
      if (a.fileName.trim().isNotEmpty) a.fileName.trim(): look(a),
    for (final link in note.tagLinks)
      if (link.label.trim().isNotEmpty && byId[link.attachmentId] != null)
        link.label.trim(): look(byId[link.attachmentId]!),
  };
}

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
    final scheme = theme.colorScheme;
    final creates = <(String, IconData, String, Color)>[
      ('pdf', Icons.picture_as_pdf_outlined, l10n.embedNewPdf, _pdfColor),
      ('image', Icons.image_outlined, l10n.embedNewImage, _imageColor),
      ('video', Icons.videocam_outlined, l10n.embedNewVideo, _videoColor),
      (
        'youtube',
        Icons.smart_display_outlined,
        l10n.embedNewYouTube,
        _webVideoColor,
      ),
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_file,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.isEmpty
                          ? l10n.embedPickTitle
                          : l10n.embedPickTitleFor(label),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.embedPickInfo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ÖNCE nottaki ekler: en sık iş zaten eklenmiş bir dosyayı bir
          // kelimeye bağlamak; eskiden listenin en altındaydı.
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 18),
            _SectionLabel(l10n.embedSectionExisting),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final a = attachments[i];
                  return _ExistingTile(
                    key: ValueKey('embed-existing-${a.id}'),
                    attachment: a,
                    onTap: () => Navigator.pop(context, EmbedPick.existing(a)),
                  );
                },
              ),
            ),
          ],
          if (allowCreate) ...[
            const SizedBox(height: 18),
            _SectionLabel(l10n.embedSectionNew),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (id, icon, text, color) in creates) ...[
                  if (id != creates.first.$1) const SizedBox(width: 8),
                  Expanded(
                    child: _CreateTile(
                      key: ValueKey('embed-new-$id'),
                      icon: icon,
                      label: text,
                      color: color,
                      onTap: () => Navigator.pop(context, EmbedPick.create(id)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 0.8,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// "Yeni ekle" kutusu: türün renginde simge, altında adı.
class _CreateTile extends StatelessWidget {
  const _CreateTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Color.alphaBlend(
        color.withValues(alpha: 0.10),
        scheme.surfaceContainerLow,
      ),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nottaki bir ek: küçük resim (görsel/video kendi karesiyle, diğerleri
/// türün renginde simgeyle), köşede türün rozeti, altında adı.
class _ExistingTile extends StatelessWidget {
  const _ExistingTile({
    super.key,
    required this.attachment,
    required this.onTap,
  });

  final Attachment attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = attachment;
    final color = embedKindColor(a);
    final visual = a.kind == AttachmentKind.image || a.isWebVideo;
    return SizedBox(
      width: 112,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 112,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (visual)
                      IgnorePointer(child: NoteMediaBox(attachment: a))
                    else
                      ColoredBox(
                        color: Color.alphaBlend(
                          color.withValues(alpha: 0.12),
                          scheme.surfaceContainerHigh,
                        ),
                        child: Icon(embedKindIcon(a), color: color, size: 30),
                      ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: _KindBadge(attachment: a, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              a.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Türün rozeti: dolu, türün renginde, beyaz simge (editördeki çipin
/// rozetiyle aynı).
class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.attachment, required this.size});

  final Attachment attachment;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: embedKindColor(attachment),
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Icon(
      embedKindIcon(attachment),
      size: size * 0.66,
      color: Colors.white,
    ),
  );
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
    final scheme = theme.colorScheme;
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
            : scheme.surfaceContainerHigh,
        child: NoteMediaBox(
          attachment: a,
          fit: BoxFit.contain,
          inlineWebVideo: true,
        ),
      );
    } else {
      preview = ColoredBox(
        color: scheme.surfaceContainerHigh,
        child: Center(
          child: Icon(embedKindIcon(a), size: 48, color: embedKindColor(a)),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _KindBadge(attachment: a, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        a.fileName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(height: height, child: preview),
            ),
            const SizedBox(height: 12),
            // Asıl işler geniş ve yan yana; seyrek işler (değiştir, kaldır)
            // altta yazılı düğmeler — eskiden dördü aynı boyda bir yığındı.
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('embed-open'),
                    onPressed: () => then(onOpen),
                    icon: const Icon(Icons.fullscreen),
                    label: Text(l10n.fullscreen),
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => then(onEdit),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.attachmentTagEdit),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  key: const ValueKey('embed-replace'),
                  onPressed: () => then(onReplace),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l10n.embedReplace),
                ),
                const Spacer(),
                TextButton.icon(
                  key: const ValueKey('embed-unlink'),
                  onPressed: () => then(onUnlink),
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
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
