import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../../settings/settings_providers.dart';
import '../../data/upload_queue.dart';
import '../../domain/attachment.dart';
import '../viewers/image_viewer.dart';
import '../viewers/pdf_viewer_screen.dart';
import '../viewers/slide_viewer_screen.dart';
import '../viewers/video_viewer.dart';
import '../../data/drive_store.dart';
import '../drive_ui.dart';
import '../note_card_media.dart' show CardMediaTile, PdfFirstPageThumb;

/// Görsel olmayan ekleri (PDF, sunum, ses, video) gösteren yatay şerit.
///
/// Şerit artık başlığın ALTINDA değil SAYFANIN DİBİNDE, alt çubuğun hemen
/// üstünde durur ve KAPANABİLİR: eskiden başlıkla gövde metninin arasına
/// giriyor, üç PDF eklenmiş bir notta yazı alanını ekranın yarısına indiriyordu.
/// Kapanınca yalnızca "Ekler (3)" satırı kalır; sayı sayesinde ek olduğu
/// gözden kaçmaz.
class AttachmentStrip extends StatelessWidget {
  const AttachmentStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
    required this.expanded,
    required this.onToggle,
    this.onChanged,
    this.onCopy,
    this.onInsertTag,
    this.onPlaceOnPage,
    this.onVideoToNote,
  });

  final List<Attachment> attachments;
  final ValueChanged<Attachment> onRemove;

  /// Eki panoya kopyalar (başka nota yapıştırılabilir). null ise düğme yok.
  final ValueChanged<Attachment>? onCopy;

  /// Eki METNİN İÇİNE etiket olarak yazar (bkz. attachment_tag.dart).
  /// null ise düğme çizilmez (ör. belge notunda gövde metni yok).
  final ValueChanged<Attachment>? onInsertTag;

  /// "Ek olarak" duran GÖRSELİ (ya da PDF'i) sayfaya geri koyar.
  final ValueChanged<Attachment>? onPlaceOnPage;

  /// Şerit açık mı? Kapalıyken yalnız başlık satırı çizilir (tercih kalıcıdır).
  final bool expanded;

  /// Başlık satırına dokununca çağrılır (aç/kapa).
  final VoidCallback onToggle;

  /// Görüntülü nottan AI ile detaylı not çıkarır. null ise düğme gizlenir.
  final Future<void> Function(Attachment)? onVideoToNote;

  /// PDF üzerine yapılan çizim kaydedilirken çağrılır; verilmezse PDF salt
  /// görüntülenir.
  final ValueChanged<Attachment>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    // BAŞLIK SATIRI YOK: "Ekler (1) · Göster" satırı alt çubuktaki ek
    // düğmesine taşındı (kullanıcı isteği 2026-08-08 — "bir satır alan
    // kurtarmış oluruz"). Şerit kapalıyken hiç yer kaplamaz.
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: attachments.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => _AttachmentTile(
              attachment: attachments[index],
              // Şeritteki GÖRSELLER bir galeri: tam ekranda yana kaydırarak
              // hepsinde gezilir.
              gallery: [
                for (final a in attachments)
                  if (a.kind == AttachmentKind.image) a,
              ],
              onRemove: () => onRemove(attachments[index]),
              onChanged: onChanged,
              onCopy: onCopy,
              onInsertTag: onInsertTag,
              onPlaceOnPage: onPlaceOnPage,
              onVideoToNote: onVideoToNote,
            ),
          ),
        ),
      ],
    );

    // Klavye açıkken şerit gizlenir: yazarken ekler için yer ayırmak metin
    // alanını gereksiz daraltıyordu. Bu MediaQuery bağımlılığı bilerek
    // BURADA duruyor — editörün kendi build'ine konsa klavye animasyonunun
    // her karesinde tüm editör yeniden kurulurdu.
    //
    // KASMA — `Offstage` + YAKALANMIŞ çocuk (kullanıcı bulgusu 2026-08-09:
    // "nota görsel eklendiğinde klavye açılırken klavye titreyerek kasarak
    // açılıyor hâlâ"): burada eskiden `return const SizedBox.shrink()` vardı,
    // yani klavyenin İLK karesinde şeridin bütün alt ağacı (karolar, görsel
    // çözdürmeleri, ses oynatıcısının State'i) ağaçtan DÜŞÜYOR, klavye
    // kapanınca da sıfırdan kuruluyordu — yeni eklenmiş bir görselde bu,
    // animasyonun tam ortasına denk gelen bir çözdürme demek. `Offstage`
    // çocuğu ağaçta TUTAR ama yerleşim ve boyama yapmaz; `content` build
    // dışında yakalandığı için de Builder'ın her karedeki yeniden çalışması
    // alt ağacı hiç yeniden kurmaz (aynı örnek → Flutter atlar).
    return Builder(
      builder: (context) => Offstage(
        offstage: !expanded || MediaQuery.viewInsetsOf(context).bottom > 0,
        child: content,
      ),
    );
  }
}

/// Ses eki: oynat/durdur düğmeli kompakt oynatıcı.
class _AudioTile extends StatefulWidget {
  const _AudioTile({required this.attachment});

  final Attachment attachment;

  @override
  State<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<_AudioTile> {
  /// TEMBEL: AudioPlayer() kurulur kurulmaz platform tarafında bir oynatıcı
  /// (Android'de ExoPlayer) ayırıyor. Eskiden her ses eki karosu state
  /// kurulurken oynatıcı açıyordu — çok sesli notta şeritte kaydırmak bile
  /// birden çok yerel oynatıcı ayağa kaldırıyordu. İlk oynatmada kurulur.
  AudioPlayer? _player;
  bool _loaded = false;

  Future<void> _toggle() async {
    try {
      final player = _player ??= AudioPlayer();
      if (!_loaded) {
        final a = widget.attachment;
        if (localFileExists(a.localPath)) {
          await player.setFilePath(a.localPath);
        } else if (a.isUploaded) {
          await player.setUrl(a.downloadUrl);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.attachmentNotSynced)),
            );
          }
          return;
        }
        _loaded = true;
        // Oynatıcı ilk kez kurulduysa StreamBuilder'lı düğmeye geç.
        if (mounted) setState(() {});
      }
      if (player.playing) {
        await player.pause();
      } else {
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero);
        }
        await player.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.genericError(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final player = _player;
    return SizedBox(
      width: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (player == null)
            IconButton.filledTonal(
              tooltip: context.l10n.mediaPlay,
              onPressed: _toggle,
              icon: const Icon(Icons.play_arrow),
            )
          else
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                final completed =
                    snapshot.data?.processingState == ProcessingState.completed;
                return IconButton.filledTonal(
                  tooltip: playing && !completed
                      ? context.l10n.mediaPause
                      : context.l10n.mediaPlay,
                  onPressed: _toggle,
                  icon: Icon(
                    playing && !completed ? Icons.pause : Icons.play_arrow,
                  ),
                );
              },
            ),
          const SizedBox(height: 2),
          Text(
            widget.attachment.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.onRemove,
    this.gallery = const [],
    this.onChanged,
    this.onCopy,
    this.onInsertTag,
    this.onPlaceOnPage,
    this.onVideoToNote,
  });

  final Attachment attachment;

  /// Tam ekranda kaydırarak geçilecek görseller (bkz. [ImageViewerScreen]).
  final List<Attachment> gallery;
  final VoidCallback onRemove;
  final ValueChanged<Attachment>? onChanged;
  final ValueChanged<Attachment>? onCopy;
  final ValueChanged<Attachment>? onInsertTag;
  final ValueChanged<Attachment>? onPlaceOnPage;
  final Future<void> Function(Attachment)? onVideoToNote;

  bool get _hasLocal => localFileExists(attachment.localPath);

  /// Sayfaya konabilen ekler: GÖRSEL, VİDEO (olduğu yerde oynar) ve PDF
  /// (kullanıcı isteği 2026-09-06 — sayfada sayfası çevrilen bir kutu olur,
  /// bkz. `PdfPageBox`).
  bool get _canPlaceOnPage =>
      attachment.kind == AttachmentKind.image ||
      attachment.kind == AttachmentKind.video ||
      attachment.kind == AttachmentKind.pdf;

  void _open(BuildContext context, WidgetRef ref) {
    // Ses eki için satır içi görüntüleyici yok (kompakt oynatıcıdan çalınır).
    if (attachment.kind == AttachmentKind.audio) return;
    // Drive'daki ek bu cihaza inmediyse önce indirilir (bkz. drive_ui.dart).
    if (!_hasLocal && attachment.isInDrive && !attachment.isUploaded) {
      fetchAttachmentNow(context, ref, attachment).then((ok) {
        if (ok && context.mounted) _open(context, ref);
      });
      return;
    }
    if (!_hasLocal && !attachment.isUploaded && !attachment.isWebVideo) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.attachmentNotSynced)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (attachment.kind) {
          AttachmentKind.pdf => PdfViewerScreen(
            attachment: attachment,
            onChanged: onChanged,
          ),
          AttachmentKind.slide => SlideViewerScreen(
            attachment: attachment,
            onChanged: onChanged,
          ),
          AttachmentKind.video => VideoViewerScreen(attachment: attachment),
          _ => ImageViewerScreen(
            attachment: attachment,
            gallery: gallery,
            onChanged: onChanged,
          ),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Otomatik yükleme sınırının ÜSTÜNDE kalan ek hiç yüklenmeyecek (kuyruk
    // atlıyor); "Yükleniyor" çarkı burada kalıcı bir yalan oluyordu. Onun
    // yerine bulut-kapalı rozeti ve ayarın kendi açıklaması gösterilir.
    final limitMb = ref.watch(syncLimitMbProvider);
    final overSyncLimit =
        limitMb > 0 && attachment.sizeBytes > limitMb * 1024 * 1024;
    // Kalıcı hata: çark burada da yalan söylüyordu (kural reddi/bozuk dosya
    // hiç düzelmez, kuyruk 6 saatlik beklemeye kadar sessizce tırmanır).
    // Eşik 3 deneme ≈ 1+2+4 dk: geçici bağlantı kesintisi buraya gelmeden
    // düzelir, kalıcı hata gelir.
    final failedAttempts =
        ref.watch(uploadFailuresProvider)[attachment.id] ?? 0;
    final uploadFailed = !overSyncLimit && failedAttempts >= 3;

    // GÖRSEL ÖNİZLEME (kullanıcı isteği 2026-10-16: "ekler altta iken sadece
    // metin olarak görülüyor; görsel, PDF, video önizlemesi görsel olarak
    // görülmeli"). PDF/sunum/video eskiden simge + dosya adıydı; artık
    // döşemenin tamamı önizleme (PDF'in ilk sayfası, videonun karesi,
    // YouTube kapağı — ana ekran kartlarıyla aynı önbellekli küçük resimler,
    // bkz. CardThumbs), altta koyu geçiş üstünde ad + tür rozeti.
    Widget content;
    if (attachment.kind == AttachmentKind.audio) {
      content = _AudioTile(attachment: attachment);
    } else if (attachment.kind == AttachmentKind.pdf) {
      content = _PreviewTile(
        preview: ColoredBox(
          color: Colors.white,
          child: PdfFirstPageThumb(attachment: attachment),
        ),
        name: attachment.fileName,
        badge: context.l10n.cardKindPdf,
        badgeColor: scheme.error,
      );
    } else if (attachment.kind == AttachmentKind.video) {
      // Görüntülü not: yalnız cihazda saklanır; dokununca uygulama içinde
      // oynatılır. AI ile not çıkarma köşedeki ✨ düğmesinde.
      content = _PreviewTile(
        preview: CardMediaTile(attachment: attachment),
        name: attachment.fileName,
        badge: attachment.isWebVideo
            ? 'YouTube'
            : context.l10n.uiItemVideoBadge,
        badgeColor: attachment.isWebVideo
            ? const Color(0xFFE53935)
            : scheme.primary,
        trailing: onVideoToNote != null && !attachment.isWebVideo
            ? Tooltip(
                message: context.l10n.videoToNote,
                child: InkWell(
                  onTap: () => onVideoToNote!(attachment),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : null,
      );
    } else if (attachment.kind == AttachmentKind.slide) {
      content = _PreviewTile(
        preview: ColoredBox(
          color: scheme.tertiaryContainer.withValues(alpha: 0.6),
          child: Center(
            child: Icon(
              Icons.slideshow_outlined,
              color: scheme.onTertiaryContainer,
              size: 30,
            ),
          ),
        ),
        name: attachment.fileName,
        badge: context.l10n.cardKindSlides,
        badgeColor: scheme.tertiary,
      );
    } else if (_hasLocal) {
      content = Image.file(
        File(attachment.localPath),
        width: 140,
        fit: BoxFit.cover,
        // 140 dp'lik önizleme için tam boy çözdürme (bellek/CPU).
        cacheWidth: 420,
      );
    } else if (attachment.isUploaded) {
      content = CachedNetworkImage(
        imageUrl: attachment.downloadUrl,
        width: 140,
        fit: BoxFit.cover,
        memCacheWidth: 420,
        // İnerken boş kutu değil ilerleme (bkz. note_images aynı düzeltme).
        progressIndicatorBuilder: (context, _, progress) => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.progress,
            ),
          ),
        ),
      );
    } else {
      content = Container(
        width: 140,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.attachmentNotSynced,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context, ref),
            child: SizedBox(height: 98, child: content),
          ),
        ),
        // Yükleme sürüyor göstergesi. Görüntülü not buluta HİÇ yüklenmediği
        // için burada asla dönmemeli: sürekli dönen çark "senkron edilmeye
        // çalışılıyor" izlenimi veriyordu.
        // Bulutta (Storage ya da Drive) kopyası olmayan ek; misafir hesapta
        // ekler buluta hiç gitmez — orada çark yalan olurdu.
        if (!attachment.isSynced &&
            _hasLocal &&
            attachment.kind != AttachmentKind.video &&
            ref.watch(attachmentSyncModeProvider) !=
                AttachmentSyncMode.textOnly)
          PositionedDirectional(
            start: 6,
            bottom: 6,
            child: Tooltip(
              message: overSyncLimit
                  ? context.l10n.syncLimitInfo
                  : uploadFailed
                  ? context.l10n.attachmentUploadFailed
                  : context.l10n.attachmentUploading,
              child: Material(
                color: uploadFailed ? scheme.error : Colors.black54,
                borderRadius: BorderRadius.circular(6),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  // Yalnız hata rozeti dokunulabilir: çark ve sınır rozeti
                  // bilgilendirme, elle tetiklenecek bir şey yok.
                  onTap: uploadFailed
                      ? () {
                          ref.read(uploadQueueProvider).retryNow(attachment.id);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.attachmentUploading),
                              ),
                            );
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: overSyncLimit
                        ? const Icon(
                            Icons.cloud_off_outlined,
                            size: 12,
                            color: Colors.white,
                          )
                        : uploadFailed
                        ? Icon(Icons.refresh, size: 12, color: scheme.onError)
                        : const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          end: 2,
          top: 2,
          child: IconButton(
            tooltip: context.l10n.removeAttachment,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.cancel, size: 18),
            color: Colors.white,
            style: IconButton.styleFrom(backgroundColor: Colors.black38),
            onPressed: onRemove,
          ),
        ),
        // Kopyala (her ek türünde) ve "sayfaya koy" (yalnız ek olarak duran
        // görselde). Küçük döşemede yer az: ikisi de sol üstte, kaldırmanın
        // karşı köşesinde durur ki yanlışlıkla silmeye basılmasın.
        if (onCopy != null ||
            onInsertTag != null ||
            (onPlaceOnPage != null && _canPlaceOnPage))
          PositionedDirectional(
            start: 2,
            top: 2,
            child: Row(
              children: [
                if (onCopy != null)
                  IconButton(
                    tooltip: context.l10n.copy,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                    onPressed: () => onCopy!(attachment),
                  ),
                // METNE EKLE (kullanıcı isteği 2026-08-16): imlecin olduğu
                // yere "📎 dosya.pdf" etiketi yazılır; etiket editörde
                // kırmızı ve altı çizili çizilir, dokununca önizleme açar.
                if (onInsertTag != null)
                  IconButton(
                    tooltip: context.l10n.attachmentTagInsert,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.text_snippet_outlined, size: 16),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                    onPressed: () => onInsertTag!(attachment),
                  ),
                if (onPlaceOnPage != null && _canPlaceOnPage)
                  IconButton(
                    tooltip: attachment.kind == AttachmentKind.pdf
                        ? context.l10n.pdfPlaceOnPage
                        : context.l10n.moveImageToPage,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.image_outlined, size: 16),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                    onPressed: () => onPlaceOnPage!(attachment),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Ek şeridinin önizlemeli döşemesi: önizleme döşemeyi doldurur, altta koyu
/// geçiş üstünde dosya adı; sol altta tür rozeti, sağ altta isteğe bağlı
/// düğme ([trailing]).
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.preview,
    required this.name,
    required this.badge,
    required this.badgeColor,
    this.trailing,
  });

  final Widget preview;
  final String name;
  final String badge;
  final Color badgeColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Stack(
        fit: StackFit.expand,
        children: [
          preview,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 16, 4, 5),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xC0000000)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
