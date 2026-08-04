import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
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
/// dokunma hedefleri; simge + etiket. "Yeni öğe" BURADA YOK: alt çubuğun kendi
/// liste/metin segmenti zaten aynı işi yapıyordu.
Future<String?> showAttachSheet(
  BuildContext context, {
  required bool isDesktop,
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
    copiedAttachmentName: copiedAttachmentName,
  ),
);

/// Izgaranın tek hücresi: (id, simge, etiket, açıklama).
typedef _Entry = (String, IconData, String, String?);

class _AttachSheet extends StatelessWidget {
  const _AttachSheet({required this.isDesktop, this.copiedAttachmentName});

  final bool isDesktop;
  final String? copiedAttachmentName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final copied = copiedAttachmentName;

    // GÖRSEL bölümü ile BELGE/DİĞER bölümü ayrı başlıklar altında: on üç
    // seçenek tek yığın hâlinde okunmuyordu.
    final visual = <_Entry>[
      ('image', Icons.image_outlined, l10n.addImage, l10n.addImageOnPageSubtitle),
      (
        'image-file',
        Icons.attachment_outlined,
        l10n.addImageAsFile,
        l10n.addImageAsFileSubtitle,
      ),
      if (!kIsWeb && !isDesktop)
        ('camera', Icons.photo_camera_outlined, l10n.takePhoto, null),
      if (DocumentScan.supported)
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
        ('video', Icons.videocam_outlined, l10n.newVideoNote, l10n.videoLocalOnly),
      if (qrScanSupported)
        ('qr', Icons.qr_code_scanner, l10n.qrScanTitle, l10n.qrScanSubtitle),
      ('color', Icons.palette_outlined, l10n.color, l10n.backgroundColorInfo),
      if (copied != null)
        ('paste-attachment', Icons.content_paste_go, l10n.pasteAttachment, copied),
    ];

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
          _SectionLabel(l10n.quickAddCapture),
          _Grid(entries: visual, scheme: scheme),
          _SectionLabel(l10n.aiSectionAttachments),
          _Grid(entries: other, scheme: scheme),
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

/// İki sütunlu ızgara. Hücre yüksekliği sabit: etiket iki satıra kadar
/// sığsın, açıklama üçüncü satırda kalsın.
class _Grid extends StatelessWidget {
  const _Grid({required this.entries, required this.scheme});

  final List<_Entry> entries;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Levha yatayda 14+14 dolgulu; iki sütun ve aradaki 8 px boşluk.
    final cellWidth = ((width - 28 - 8) / 2).clamp(120.0, 260.0);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (id, icon, label, info) in entries)
          SizedBox(
            width: cellWidth,
            height: 76,
            child: Material(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pop(context, id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                            if (info != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                info,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.15,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
