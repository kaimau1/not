import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/customizable.dart';
import '../../data/document_scan.dart';
import '../qr_scan_screen.dart';

/// Not editörünün "Ekle" levhası: TEK sayfada, İKİ SÜTUNLU ızgara.
///
/// ESKİDEN iki katmandı: alt çubuktaki "Ekle" küçük bir açılır menü açıyor
/// (madde/görsel/PDF/renk), onun son satırı da tüm ekleri listeleyen ayrı bir
/// levhayı açıyordu. Aynı seçenek iki yerde görünüyor, hangisinin nerede
/// olduğu akılda kalmıyor ve "ekle" adı üç kez geçiyordu (kullanıcı: "ekle
/// alanı tamamen yenilenmeli, tek sayfada hepsi görülmeli").
///
/// ŞİMDİ: tek dokunuş → tek levha → her seçenek görünür. İki sütun, iri
/// dokunma hedefleri; simge + etiket.
///
/// **2026-10-11 YENİDEN DÜZENLENDİ** (kullanıcı isteği: "menüler yeniden
/// dizayn edilip toparlanmalı"): iki sütunlu, açıklamalı satırlar levhayı
/// ekranın tamamına yayıyor, "Görüntülü not" ve PDF'e ulaşmak kaydırma
/// istiyordu. Artık ÜÇ (geniş ekranda daha çok) sütunlu SİMGE ızgarası:
/// yuvarlak simge + kısa ad; açıklama uzun basınca ipucunda. "Yeni sayfa"
/// başlığın yanındaki "+" menüsüne taşındı (notun yapısı, içeriği değil);
/// görsel bölümünün başlığı "YAKALA — İÇERİKTEN NOT OLUŞTURUR" idi (ana
/// ekrandaki "+" panelinden ödünç, burada yanlış) → "Görsel ve çizim".
///
/// "Metin ekle" / "Liste maddesi ekle" de BURADA (en üstteki bölüm): eskiden
/// alt çubukta kendi segmentleri vardı, çubuk üç segmentle kalabalıktı ve
/// "ekleme" işi iki ayrı yere bölünmüştü. Artık eklenen her şey tek kapıdan
/// geçiyor, çubukta yalnız "Biçim" ve "Ekle" kaldı. İkisi de not tipinden
/// BAĞIMSIZ görünür (bkz. build).
Future<String?> showAttachSheet(
  BuildContext context, {
  required bool isDesktop,
  bool pageNote = false,
  bool canEmbed = false,
  String? copiedAttachmentName,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.8,
  ),
  builder: (sheetContext) => _AttachSheet(
    isDesktop: isDesktop,
    pageNote: pageNote,
    canEmbed: canEmbed,
    copiedAttachmentName: copiedAttachmentName,
  ),
);

/// Izgaranın tek hücresi: (id, simge, etiket, açıklama).
typedef _Entry = (String, IconData, String, String?);

/// "Ekle" levhasının KİŞİSELLEŞTİRİLEBİLİR seçenekleri (ayarlardaki seçici
/// için): kimlik, simge, ad. Kimlikler levhanın döndürdüğü değerlerle aynı.
/// Yalnız masaüstünde olan "Görsel yapıştır" ve içeriğe göre çıkan "Eki
/// yapıştır" listede yok.
List<({String id, IconData icon, String label})> attachSheetCatalog(
  AppLocalizations l10n,
) => [
  (id: 'text-block', icon: Icons.notes, label: l10n.addTextBlock),
  (id: 'list-item', icon: Icons.checklist, label: l10n.editorToolList),
  (id: 'embed-attachment', icon: Icons.link, label: l10n.attachmentTagEmbed),
  (id: 'image', icon: Icons.image_outlined, label: l10n.addImage),
  (
    id: 'image-file',
    icon: Icons.attachment_outlined,
    label: l10n.addImageAsFile,
  ),
  if (!kIsWeb)
    (id: 'camera', icon: Icons.photo_camera_outlined, label: l10n.takePhoto),
  if (DocumentScan.available)
    (
      id: 'scan',
      icon: Icons.document_scanner_outlined,
      label: l10n.scanDocument,
    ),
  (id: 'drawing', icon: Icons.brush_outlined, label: l10n.addDrawing),
  (id: 'pdf', icon: Icons.picture_as_pdf_outlined, label: l10n.addPdf),
  (id: 'slide', icon: Icons.slideshow_outlined, label: l10n.addSlide),
  if (!kIsWeb) (id: 'audio', icon: Icons.mic_none, label: l10n.recordAudio),
  if (!kIsWeb)
    (id: 'video', icon: Icons.videocam_outlined, label: l10n.newVideoNote),
  if (!kIsWeb)
    (
      id: 'video-gallery',
      icon: Icons.video_library_outlined,
      label: l10n.addVideoFromGallery,
    ),
  (
    id: 'youtube',
    icon: Icons.smart_display_outlined,
    label: l10n.addYouTubeVideo,
  ),
  if (qrScanSupported)
    (id: 'qr', icon: Icons.qr_code_scanner, label: l10n.qrScanTitle),
];

class _AttachSheet extends StatelessWidget {
  const _AttachSheet({
    required this.isDesktop,
    required this.pageNote,
    required this.canEmbed,
    this.copiedAttachmentName,
  });

  final bool isDesktop;

  /// Belge (PDF/sunum) notu mu? Öyleyse "not içeriği" bölümü HİÇ gösterilmez:
  /// o ekranda gövde metni de madde listesi de çizilmiyor (içerik sayfa
  /// başına tutulan notlarda), seçenek gösterip hiçbir şey olmaması
  /// kullanıcıyı yanıltırdı.
  final bool pageNote;

  /// Notta gömülebilecek EK var mı? "Yazıya ek göm" yalnız o zaman
  /// gösterilir — eki olmayan notta madde ölü durur.
  final bool canEmbed;

  final String? copiedAttachmentName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final copied = copiedAttachmentName;

    // Notun KENDİ içeriğine eklenenler (ek dosya değil): en üstte.
    //
    // İKİSİ DE HER ZAMAN görünür (kullanıcı bulgusu: "liste ekle seçeneği
    // yok"). Eskiden not tipine göre yalnız biri gösteriliyordu — metin
    // notunda "Liste maddesi", liste/belge notunda "Metin". Oysa not tipleri
    // KARIŞIK içerik taşıyabiliyor: metin notunun altına madde listesi,
    // liste notunun başına serbest metin girebiliyor. Tek seçenek göstermek
    // var olan bir yeteneği ekranda yokmuş gibi gösteriyordu; artık kullanıcı
    // hangi nottayken ne eklemek isterse onu seçiyor.
    final content = <_Entry>[
      if (!pageNote) ...[
        ('text-block', Icons.notes, l10n.addTextBlock, null),
        ('list-item', Icons.checklist, l10n.editorToolList, null),
        // YAZIYA EK GÖM (kullanıcı bulgusu 2026-08-16: "ek gömmeyi
        // bulamadım"). İki giriş noktası vardı ve ikisi de saklıydı: ek
        // şeridindeki 16 piksellik simge ve metin seçim menüsü — Android o
        // menüde fazla maddeleri "⋮" taşmasına atıyor, yani madde çoğu zaman
        // hiç görünmüyordu. Dosya eklemek için zaten buraya gelindiği için
        // asıl yeri burası.
        if (canEmbed)
          (
            'embed-attachment',
            Icons.link,
            l10n.attachmentTagEmbed,
            l10n.attachmentTagEmbedInfo,
          ),
      ],
    ];

    // GÖRSEL bölümü ile BELGE/DİĞER bölümü ayrı başlıklar altında: on üç
    // seçenek tek yığın hâlinde okunmuyordu.
    final visual = <_Entry>[
      (
        'image',
        Icons.image_outlined,
        l10n.addImage,
        l10n.addImageOnPageSubtitle,
      ),
      (
        'image-file',
        Icons.attachment_outlined,
        l10n.addImageAsFile,
        l10n.addImageAsFileSubtitle,
      ),
      if (!kIsWeb && !isDesktop)
        ('camera', Icons.photo_camera_outlined, l10n.takePhoto, null),
      if (DocumentScan.available)
        (
          'scan',
          Icons.document_scanner_outlined,
          l10n.scanDocument,
          l10n.scanDocumentSubtitle,
        ),
      ('drawing', Icons.brush_outlined, l10n.addDrawing, null),
      if (isDesktop) ('paste', Icons.content_paste, l10n.pasteImage, null),
    ];

    final other = <_Entry>[
      ('pdf', Icons.picture_as_pdf_outlined, l10n.addPdf, null),
      ('slide', Icons.slideshow_outlined, l10n.addSlide, null),
      if (!kIsWeb) ('audio', Icons.mic_none, l10n.recordAudio, null),
      if (!kIsWeb)
        (
          'video',
          Icons.videocam_outlined,
          l10n.newVideoNote,
          l10n.videoLocalOnly,
        ),
      // Galeriden video (kamera yolu yukarıda): masaüstünde image_picker
      // dosya seçiciye düşer, orada da çalışır.
      if (!kIsWeb)
        (
          'video-gallery',
          Icons.video_library_outlined,
          l10n.addVideoFromGallery,
          l10n.videoLocalOnly,
        ),
      (
        'youtube',
        Icons.smart_display_outlined,
        l10n.addYouTubeVideo,
        l10n.addYouTubeVideoSubtitle,
      ),
      if (qrScanSupported)
        ('qr', Icons.qr_code_scanner, l10n.qrScanTitle, l10n.qrScanSubtitle),
      // "Renk" BURADAN KALKTI (kullanıcı isteği 2026-08-10: "sayfa rengi ve
      // yanındaki kısımları biçim menüsüne al"): sayfa görünümü artık alt
      // çubuktaki "Biçim" şeridinin palet düğmesinde (bkz. format_bar.dart).
      // Bu levha yalnız NOTA GİREN şeyleri listeler; renk buraya ait değildi.
      if (copied != null)
        (
          'paste-attachment',
          Icons.content_paste_go,
          l10n.pasteAttachment,
          copied,
        ),
    ];

    // KİŞİSELLEŞTİRME (kullanıcı isteği 2026-10-16): gizlenen seçenekler
    // levhada yer kaplamaz; düzenleme modunda hepsi görünür, dokunmak
    // gizle/göster yapar (bkz. Customizable). Yapıştır, içeriğe göre
    // kendiliğinden çıkan bir seçenek — gizlenmez.
    List<_Entry> visibleOf(List<_Entry> entries) => Personalize.editing
        ? entries
        : [
            for (final e in entries)
              if (e.$1 == 'paste-attachment' ||
                  Personalize.current.shows(UiItem.attach(e.$1)))
                e,
          ];
    final contentShown = visibleOf(content);
    final visualShown = visibleOf(visual);
    final otherShown = visibleOf(other);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.addAttachment,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
          if (contentShown.isNotEmpty) ...[
            _SectionLabel(l10n.attachNoteContent),
            _Grid(entries: contentShown, scheme: scheme),
          ],
          if (visualShown.isNotEmpty) ...[
            _SectionLabel(l10n.attachSectionVisual),
            _Grid(entries: visualShown, scheme: scheme),
          ],
          if (otherShown.isNotEmpty) ...[
            _SectionLabel(l10n.aiSectionAttachments),
            _Grid(entries: otherShown, scheme: scheme),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

/// Simge ızgarası: sütun sayısı genişlikten (telefonda 3, genişte 4–6).
/// Hücre: yuvarlak simge + en çok iki satırlık ad. Açıklama ([_Entry]'nin
/// dördüncü alanı) ipucuna gider; yalnız "Kopyalanan eki yapıştır"ın dosya
/// adı hücrede de yazılır — neyin yapıştırılacağı görünmeden basılmaz.
class _Grid extends StatelessWidget {
  const _Grid({required this.entries, required this.scheme});

  final List<_Entry> entries;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final columns = (constraints.maxWidth / 112).floor().clamp(3, 6);
        final cellWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (id, icon, label, info) in entries)
              SizedBox(
                width: cellWidth,
                child: Customizable(
                  id: UiItem.attach(id),
                  badgeInset: 6,
                  child: _Cell(
                    id: id,
                    icon: icon,
                    label: label,
                    info: info,
                    scheme: scheme,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.id,
    required this.icon,
    required this.label,
    required this.info,
    required this.scheme,
  });

  final String id;
  final IconData icon;
  final String label;
  final String? info;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final showInfo = id == 'paste-attachment' && info != null;
    final cell = Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pop(context, id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 21, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 30,
                child: Center(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              if (showInfo)
                Text(
                  info!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return info == null ? cell : Tooltip(message: info, child: cell);
  }
}
