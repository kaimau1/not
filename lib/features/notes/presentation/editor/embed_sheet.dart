import 'dart:async';

import '../../domain/note_links.dart';
import '../../../../core/app_icons.dart';
import '../../../../app/theme/fixed_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/widgets/sheet_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../add_catalog.dart';
import 'note_images.dart';
import 'pdf_page_box.dart';
import 'tag_chips.dart';
import '../../../../core/widgets/app_sheet.dart';

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

/// Seçicinin sonucu: var olan bir ek, oluşturulacak yeni ekin türü (`pdf`,
/// `image`, `video`, `youtube`) ya da yazının bağlanacağı web adresi.
class EmbedPick {
  const EmbedPick.existing(Attachment this.attachment)
    : create = null,
      url = null;
  const EmbedPick.create(String this.create) : attachment = null, url = null;
  const EmbedPick.url(String this.url) : attachment = null, create = null;

  final Attachment? attachment;
  final String? create;
  final String? url;
}

/// Kullanıcının yazdığı adresi açılabilir web adresine çevirir (şemasızsa
/// `https://`); boşluk içeren ya da alan adı olmayan yazı null.
String? normalizeEmbedUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t.contains(RegExp(r'\s'))) return null;
  final hasScheme = RegExp(
    r'^[a-z][a-z0-9+.-]*:',
    caseSensitive: false,
  ).hasMatch(t);
  final withScheme = hasScheme ? t : 'https://$t';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || !uri.hasScheme) return null;
  if (uri.scheme == 'mailto' || uri.scheme == 'tel') return withScheme;
  if (!uri.host.contains('.')) return null;
  return withScheme;
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
        // Bu sürümün tanımadığı tür (F1.5) — "güncelle" işareti.
        AttachmentKind.unknown => Icons.system_update,
      };

/// Ekin türünün rengi — editördeki çip, seçici ve önizleme kartı aynı rengi
/// kullanır ki "bu bir PDF" bir bakışta okunsun.
Color embedKindColor(Attachment a) => a.isWebVideo
    ? FixedColors.kindWebVideo
    : switch (a.kind) {
        AttachmentKind.pdf => FixedColors.kindPdf,
        AttachmentKind.slide => FixedColors.kindSlide,
        AttachmentKind.video => FixedColors.kindVideo,
        AttachmentKind.audio => FixedColors.kindAudio,
        AttachmentKind.image => FixedColors.kindImage,
        AttachmentKind.text => FixedColors.kindText,
        AttachmentKind.unknown => FixedColors.kindUnknown,
      };


/// Notun bütün etiket adlarının (bağ etiketleri + dosya adları) görünümü.
/// Çözüm kuralı editördeki `_attachmentForTag` ile aynı: aynı ad hem bağ
/// etiketi hem dosya adıysa BAĞ kazanır. Koyu temada renk açılır: koyu
/// zeminde koyu kırmızı yazı okunmuyordu.
Map<String, TagLook> embedTagLooks(
  Note note, {
  bool dark = false,
  Set<String>? liveNoteIds,
}) {
  if (note.attachments.isEmpty &&
      !note.tagLinks.any(
        (l) => linkedNoteId(l) != null || linkedUrl(l) != null,
      )) {
    return const {};
  }
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
    // Not bağlantısı (F18.16): kendi rengi; hedef yoksa soluk.
    for (final link in note.tagLinks)
      if (link.label.trim().isNotEmpty && linkedNoteId(link) != null)
        link.label.trim(): TagLook(
          Icons.sticky_note_2_outlined,
          liveNoteIds == null || liveNoteIds.contains(linkedNoteId(link))
              ? (dark
                    ? Color.lerp(FixedColors.kindNoteLink, Colors.white, 0.3)!
                    : FixedColors.kindNoteLink)
              : FixedColors.kindNoteLink.withValues(alpha: 0.4),
        ),
    // Web bağlantısı (2026-11-24): bağlantı mavisi, zincir rozeti.
    for (final link in note.tagLinks)
      if (link.label.trim().isNotEmpty && linkedUrl(link) != null)
        link.label.trim(): TagLook(
          Icons.link_rounded,
          dark
              ? Color.lerp(FixedColors.kindWebLink, Colors.white, 0.35)!
              : FixedColors.kindWebLink,
        ),
  };
}

/// Gömülecek şeyi seçtirir. [label] seçili yazı (boşsa başlıkta gösterilmez).
/// [allowLink]: seçili yazı varken web bağlantısı da gömülebilir.
///
/// **2026-11-24 yenilemesi** (kullanıcı: "ek gömmenin görsel butonsal
/// tasarımlarını baştan yaz, link gömme de olsun"): başlıkta gömülecek yazı
/// çip olarak; üç bölüm — Bağlantı (adres kutusu + Yapıştır), Bu nottaki
/// ekler (önizlemeli kartlar), Yeni ekle (türün renginde karolar).
Future<EmbedPick?> showEmbedPicker(
  BuildContext context, {
  required String label,
  required List<Attachment> attachments,
  bool allowCreate = true,
  bool allowLink = false,
}) => showAppSheet<EmbedPick>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    maxWidth: 640,
  ),
  builder: (sheetContext) => SheetInsetPadding(
    child: _EmbedPicker(
      label: label,
      attachments: attachments,
      allowCreate: allowCreate,
      allowLink: allowLink,
    ),
  ),
);

class _EmbedPicker extends StatelessWidget {
  const _EmbedPicker({
    required this.label,
    required this.attachments,
    required this.allowCreate,
    required this.allowLink,
  });

  final String label;
  final List<Attachment> attachments;
  final bool allowCreate;
  final bool allowLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final creates = <(String, IconData, String, Color)>[
      ('pdf', Icons.picture_as_pdf_outlined, l10n.embedNewPdf, FixedColors.kindPdf),
      ('image', Icons.image_outlined, l10n.embedNewImage, FixedColors.kindImage),
      ('video', Icons.videocam_outlined, l10n.embedNewVideo, FixedColors.kindVideo),
      (
        'youtube',
        Icons.smart_display_outlined,
        l10n.embedNewYouTube,
        FixedColors.kindWebVideo,
      ),
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          0,
          AppSpace.l,
          AppSpace.l,
        ),
        children: [
          Text(
            l10n.embedPickTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                key: const ValueKey('embed-label-chip'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: AppAlpha.muted),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file_rounded,
                      size: AppIconSize.s,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xs),
          Text(
            l10n.embedPickInfo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (allowLink) ...[
            const SizedBox(height: AppSpace.l),
            _SectionLabel(l10n.embedSectionLink),
            const SizedBox(height: AppSpace.s),
            const _LinkField(),
          ],
          // ÖNCE nottaki ekler: en sık iş zaten eklenmiş bir dosyayı bir
          // kelimeye bağlamak.
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: AppSpace.l),
            _SectionLabel(l10n.embedSectionExisting),
            const SizedBox(height: AppSpace.s),
            SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s),
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
            const SizedBox(height: AppSpace.l),
            _SectionLabel(l10n.embedSectionNew),
            const SizedBox(height: AppSpace.s),
            AddTileGrid(
              count: creates.length,
              tile: (i, wide) {
                final (id, icon, text, color) = creates[i];
                return AddTile(
                  key: ValueKey('embed-new-$id'),
                  icon: icon,
                  label: text,
                  accent: color,
                  wide: wide,
                  onTap: () => Navigator.pop(context, EmbedPick.create(id)),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Bağlantı kutusu: adres yazılır ya da panodan yapıştırılır; geçerli
/// adreste "Bağla" etkinleşir, Enter da bağlar.
class _LinkField extends StatefulWidget {
  const _LinkField();

  @override
  State<_LinkField> createState() => _LinkFieldState();
}

class _LinkFieldState extends State<_LinkField> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    try {
      final d = await Clipboard.getData(Clipboard.kTextPlain);
      final t = d?.text?.trim();
      if (t == null || t.isEmpty || !mounted) return;
      setState(() => _c.text = t);
    } catch (_) {
      // Pano izni yok (web): kullanıcı Ctrl+V ile yapıştırır.
    }
  }

  void _submit() {
    final url = normalizeEmbedUrl(_c.text);
    if (url == null) return;
    Navigator.pop(context, EmbedPick.url(url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ok = normalizeEmbedUrl(_c.text) != null;
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('embed-link-field'),
            controller: _c,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.embedLinkHint,
              prefixIcon: const Icon(
                Icons.link_rounded,
                color: FixedColors.kindWebLink,
              ),
              suffixIcon: IconButton(
                tooltip: MaterialLocalizations.of(context).pasteButtonLabel,
                icon: const Icon(Icons.content_paste_rounded),
                onPressed: () => unawaited(_paste()),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.s),
        FilledButton(
          key: const ValueKey('embed-link-ok'),
          style: FilledButton.styleFrom(
            backgroundColor: FixedColors.kindWebLink,
            foregroundColor: Colors.white,
            disabledBackgroundColor: scheme.surfaceContainerHighest,
            minimumSize: const Size(0, 48),
          ),
          onPressed: ok ? _submit : null,
          child: Text(l10n.embedLinkApply),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SectionLabel(text);
}

/// Nottaki bir ek: önizleme (görsel/video kendi karesiyle, diğerleri türün
/// renginde simgeyle), köşede türün rozeti, altında adı — tek kart.
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
      width: 124,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.m),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 84,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (visual)
                      IgnorePointer(child: NoteMediaBox(attachment: a))
                    else
                      ColoredBox(
                        color: color.withValues(alpha: AppAlpha.pressed),
                        child: Icon(embedKindIcon(a), color: color, size: 34),
                      ),
                    PositionedDirectional(
                      start: AppSpace.xs,
                      top: AppSpace.xs,
                      child: _KindBadge(attachment: a, size: 22),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s,
                  vertical: AppSpace.xs,
                ),
                child: Text(
                  a.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
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
  Widget? viewSwitch,
  VoidCallback? onCopy,
  VoidCallback? onShare,
  ValueChanged<Attachment>? onChanged,
}) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
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
            // K6: ekin nerede durduğu her yüzeyde aynı anahtar ("Nota aktar"
            // ayrı iş değil, Yüzen seçmektir).
            if (viewSwitch != null) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: viewSwitch,
              ),
              const SizedBox(height: 8),
            ],
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
                if (onCopy != null)
                  IconButton(
                    key: const ValueKey('embed-copy'),
                    tooltip: l10n.copyAttachment,
                    onPressed: () => then(onCopy),
                    icon: const Icon(AppIcons.copy),
                  ),
                // PAYLAŞ (TUTARLILIK F36.4, kullanıcı listesi: "ekleri paylaş
                // seçeneği ... gömülmüş ek menüsünde olsun").
                if (onShare != null)
                  IconButton(
                    key: const ValueKey('embed-share'),
                    tooltip: l10n.share,
                    onPressed: () => then(onShare),
                    icon: const Icon(Icons.share_outlined),
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
