import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/youtube.dart';
import '../data/pdf/pdf_page_render.dart';
import '../data/video_frame.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

/// **KARTIN MEDYA PLANI** — ana ekran kartında hangi ekin nasıl görüneceği.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-15: "notlarda video veya resim
/// olduğunda dashboard'da görülmüyor; video, PDF, balonlu mod için düzenli,
/// anlaşılır ve kolayca ayırt edilebilir bir görüntü olmalı"): kartın ek
/// önizlemesi yalnız GÖRSEL, PDF ve sunum ekini tanıyordu. Video (galeriden
/// ya da YouTube) ve ses eki kartta HİÇ çizilmiyordu — üstte sabitli bir
/// YouTube videosu olan not ana ekranda başlıktan ibaret, başlıksızsa
/// bomboş bir kart görünüyordu. Belge (balonlu) notu da sıradan bir notun
/// ekiymiş gibi tek satırlık dosya adıyla duruyordu.
///
/// Plan SAF bir hesap (widget'tan ayrı): kart yüksekliği tahmini
/// ([estimateHeight]) ile çizim aynı kararı okusun, test edilebilsin.
@immutable
class CardMediaPlan {
  const CardMediaPlan._({
    required this.hero,
    required this.heroDocument,
    required this.strip,
    required this.docs,
    required this.audioCount,
    required this.bubbleCount,
    required this.documentNote,
    this.transcriptCount = 0,
  });

  /// Kartın tepesinde KENARDAN KENARA duran büyük kapak (görsel/video).
  /// Notun üstüne sabitlenmiş medya varsa odur (editördeki "üstte video,
  /// altta not" düzeni kartta da aynı); yoksa notun TEK görseli/videosu.
  final Attachment? hero;

  /// Belge kartı: ilk sayfanın küçük resmi + tür etiketi. Balonlu (PDF/
  /// sunum) notun belgesi, ya da görseli olmayan notun ilk belge eki.
  final Attachment? heroDocument;

  /// Kapağın altındaki küçük karolar (görsel/video), sırayla.
  final List<Attachment> strip;

  /// Satır olarak gösterilen öbür belgeler (PDF/sunum).
  final List<Attachment> docs;

  final int audioCount;

  /// Metin eki (transkript) sayısı — kartta tek satır.
  final int transcriptCount;

  /// Belgedeki balon + vurgu sayısı (balonlu notu ayırt eden bilgi).
  final int bubbleCount;

  /// Not BELGE notu mu (balonlu kip: `NoteType.pdf`/`slides`).
  final bool documentNote;

  /// Karoların en çoğu; fazlası son karoda "+N" olur.
  static const maxStrip = 3;
  static const maxDocs = 2;

  static const stripHeight = 64.0;
  static const documentHeight = 72.0;
  static const docRowHeight = 24.0;

  /// BALONLU notun kapağı: belgesi kartın tepesinde kenardan kenara (bkz.
  /// [CardDocumentCover]). Sıradan notun belge eki kapak OLMAZ — gövdede
  /// küçük belge kartı olarak durur.
  ///
  /// Üste SABİTLENMİŞ belge de kapaktır: editörde notun tepesinde duruyor,
  /// kartta da tepede durur.
  Attachment? get cover => documentNote || (heroDocument?.isPinnedTop ?? false)
      ? heroDocument
      : null;

  /// Belge kapağının [width] genişlikteki yüksekliği: sayfanın üst kısmı
  /// (başlık, ilk satırlar) okunacak kadar.
  static double coverHeight(double width) =>
      (width * 0.72).clamp(96.0, 150.0).toDouble();

  bool get isEmpty =>
      hero == null &&
      heroDocument == null &&
      strip.isEmpty &&
      docs.isEmpty &&
      audioCount == 0 &&
      transcriptCount == 0;

  static bool _visual(Attachment a) =>
      a.kind == AttachmentKind.image || a.kind == AttachmentKind.video;

  static bool _document(Attachment a) =>
      a.kind == AttachmentKind.pdf || a.kind == AttachmentKind.slide;

  /// [showVisuals] false: görsel/video yok; [showFiles] false: belge, ses ve
  /// metin ekleri yok (Ayarlar → Kartta görünenler; `cardDisplayProvider`).
  factory CardMediaPlan.of(
    Note note, {
    bool showVisuals = true,
    bool showFiles = true,
  }) {
    // Zemin görseli ek DEĞİL: notun arkasında duvar kâğıdı olarak duruyor.
    final all = [
      for (final a in note.attachments)
        if (a.id != note.backgroundImageId &&
            !note.hidesDerivedDocument(a) &&
            (_visual(a) ? showVisuals : showFiles))
          a,
    ];
    // Sabitli medya önce: kartın kapağı odur.
    final visuals = [
      for (final a in all)
        if (_visual(a) && a.isPinnedTop) a,
      for (final a in all)
        if (_visual(a) && !a.isPinnedTop) a,
    ];
    final documents = [
      for (final a in all)
        if (_document(a)) a,
    ];
    final documentNote =
        note.type == NoteType.pdf || note.type == NoteType.slides;

    // Üste SABİTLENMİŞ belge (bkz. Attachment.isPinnedTop) kartın kapağıdır
    // — sabitli görselin belgedeki karşılığı.
    final pinnedDocument = documents.where((d) => d.isPinnedTop).firstOrNull;
    Attachment? hero;
    if (visuals.isNotEmpty &&
        (visuals.first.isPinnedTop || visuals.length == 1) &&
        !documentNote &&
        pinnedDocument == null) {
      hero = visuals.first;
    }
    Attachment? heroDocument;
    if (pinnedDocument != null && !documentNote) {
      heroDocument = pinnedDocument;
    } else if (documents.isNotEmpty && (documentNote || visuals.isEmpty)) {
      heroDocument = documents.first;
    }
    var bubbles = 0;
    for (final d in documents) {
      bubbles += d.bubbles.length;
    }
    return CardMediaPlan._(
      hero: hero,
      heroDocument: heroDocument,
      strip: [
        for (final v in visuals)
          if (!identical(v, hero)) v,
      ],
      docs: [
        for (final d in documents)
          if (!identical(d, heroDocument)) d,
      ],
      audioCount: all.where((a) => a.kind == AttachmentKind.audio).length,
      transcriptCount: all.where((a) => a.kind == AttachmentKind.text).length,
      bubbleCount: bubbles,
      documentNote: documentNote,
    );
  }

  /// Kapağın [width] genişlikteki yüksekliği. Video 16:9; görsel kendi
  /// oranıyla (bilinmiyorsa 4:3), çok uzun/çok basık olmasın diye sınırlı.
  static double heroHeight(Attachment a, double width) {
    double aspect;
    if (a.kind == AttachmentKind.video) {
      aspect = 16 / 9;
    } else if ((a.width ?? 0) > 0 && (a.height ?? 0) > 0) {
      aspect = a.width! / a.height!;
    } else {
      aspect = 4 / 3;
    }
    return (width / aspect).clamp(72.0, 168.0);
  }

  /// Planın kartta kapladığı YAKLAŞIK yükseklik (bkz.
  /// `estimateNoteCardHeight`). [width] kartın tam genişliği.
  double estimateHeight(double width) {
    var h = 0.0;
    if (hero case final hero?) h += heroHeight(hero, width);
    if (cover != null) h += coverHeight(width);
    var below = 0.0;
    if (heroDocument != null && cover == null) below += documentHeight + 8;
    if (strip.isNotEmpty) below += stripHeight + 8;
    below += math.min(docs.length, maxDocs) * docRowHeight;
    if (docs.length > maxDocs) below += 16;
    if (audioCount > 0) below += docRowHeight;
    if (transcriptCount > 0) below += docRowHeight;
    return h + below;
  }
}

/// Kartın tepesindeki kenardan kenara kapak. Kart kendi köşelerine kırpar.
class CardHeroMedia extends StatelessWidget {
  const CardHeroMedia({super.key, required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: CardMediaPlan.heroHeight(attachment, constraints.maxWidth),
      width: double.infinity,
      child: CardMediaTile(attachment: attachment, large: true),
    ),
  );
}

/// Kapak/karonun altındaki gövde: belge kartı, küçük karolar, belge ve ses
/// satırları.
class CardMediaBody extends StatelessWidget {
  const CardMediaBody({super.key, required this.plan});

  final CardMediaPlan plan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final children = <Widget>[];
    void gap() {
      if (children.isNotEmpty) children.add(const SizedBox(height: 6));
    }

    // Balonlu notun belgesi gövdede DEĞİL, kartın tepesinde kapak olarak
    // durur (bkz. [CardDocumentCover]).
    if (plan.heroDocument case final doc? when plan.cover == null) {
      gap();
      children.add(_DocumentCard(document: doc));
    }
    if (plan.strip.isNotEmpty) {
      gap();
      final shown = plan.strip.take(CardMediaPlan.maxStrip).toList();
      final more = plan.strip.length - shown.length;
      children.add(
        SizedBox(
          height: CardMediaPlan.stripHeight,
          child: Row(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CardMediaTile(attachment: shown[i]),
                        if (more > 0 && i == shown.length - 1)
                          ColoredBox(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+$more',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    final docs = plan.docs.take(CardMediaPlan.maxDocs).toList();
    if (docs.isNotEmpty || plan.audioCount > 0 || plan.transcriptCount > 0) {
      gap();
    }
    for (final d in docs) {
      children.add(
        _FileRow(
          icon: d.kind == AttachmentKind.pdf
              ? Icons.picture_as_pdf_outlined
              : Icons.slideshow_outlined,
          color: d.kind == AttachmentKind.pdf ? scheme.error : scheme.tertiary,
          label: d.fileName,
          style: labelStyle,
        ),
      );
    }
    if (plan.docs.length > docs.length) {
      children.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, top: 1),
          child: Text(
            l10n.cardMoreFiles(plan.docs.length - docs.length),
            style: labelStyle,
          ),
        ),
      );
    }
    if (plan.audioCount > 0) {
      children.add(
        _FileRow(
          icon: Icons.graphic_eq,
          color: scheme.primary,
          label: l10n.cardAudioCount(plan.audioCount),
          style: labelStyle,
        ),
      );
    }
    if (plan.transcriptCount > 0) {
      children.add(
        _FileRow(
          icon: Icons.subject,
          color: const Color(0xFF6D4C41),
          label: l10n.cardTranscriptCount(plan.transcriptCount),
          style: labelStyle,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.icon,
    required this.color,
    required this.label,
    this.style,
  });

  final IconData icon;
  final Color color;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: CardMediaPlan.docRowHeight,
    child: Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 6),
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
  );
}

/// Sıradan notun BELGE eki: solda ilk sayfanın küçük resmi (kâğıt gibi,
/// altında türün şeridi), sağda dosya adı ve türü.
///
/// 2026-10-15 toparlaması ("dashboard'ta balonlu mod görseli ve diğerleri
/// biraz daha toparlanmalı"): tür rozeti metin sütununun başında bir hap
/// olarak duruyordu ve dar kartta "BALONLU …" diye kesiliyordu. Tür artık
/// kâğıdın altındaki şeritte; balonlu not ise hiç burada değil, kapakta.
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final Attachment document;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final pdf = document.kind == AttachmentKind.pdf;
    final accent = pdf ? scheme.error : scheme.tertiary;
    final small = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      height: CardMediaPlan.documentHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kâğıt: beyaz zemin + ince kenarlık; sayfa oranına yakın.
          Container(
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: pdf
                      ? _PdfFirstPage(attachment: document)
                      : Icon(Icons.slideshow_outlined, color: accent),
                ),
                ColoredBox(
                  color: accent,
                  child: Text(
                    pdf ? l10n.cardKindPdf : l10n.cardKindSlides,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      height: 1.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                document.fileName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: small?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// BALONLU notun kapağı: belgenin ilk sayfası kartın tepesinde KENARDAN
/// KENARA — video/görsel kapağıyla aynı yer, aynı dil.
///
/// KULLANICI İSTEĞİ (2026-10-15): "dashboard'ta balonlu mod görseli ve
/// diğerleri için biraz daha toparlanmalı". Balonlu not ana ekranda sayfa
/// notlarının ALTINDA, 62 px'lik bir kâğıt + kesilen "BALONLU …" rozetiyle
/// duruyordu; notun kendisi belge olduğu hâlde belge en son okunuyordu.
/// Şimdi belge önde: sayfanın üst kısmı, sol üstte tür rozeti, altta koyu
/// geçiş üstünde dosya adı ve balon sayısı.
class CardDocumentCover extends StatelessWidget {
  const CardDocumentCover({
    super.key,
    required this.document,
    required this.bubbleCount,
  });

  final Attachment document;
  final int bubbleCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final pdf = document.kind == AttachmentKind.pdf;
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: CardMediaPlan.coverHeight(constraints.maxWidth),
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (pdf)
              ColoredBox(
                color: Colors.white,
                child: _PdfFirstPage(attachment: document, iconSize: 36),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.tertiaryContainer, scheme.primaryContainer],
                  ),
                ),
                child: Icon(
                  Icons.slideshow_outlined,
                  size: 40,
                  color: scheme.onTertiaryContainer,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xB3000000)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (bubbleCount > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chat_bubble,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        l10n.cardBubbleCount(bubbleCount),
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Tür rozeti sol üstte: balonlu not ana ekranda sıradan bir PDF
            // ekinden bakışta ayrılsın (sağ üstte kartın ⋮ düğmesi var).
            PositionedDirectional(
              start: 8,
              top: 8,
              end: 40,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 11,
                        color: scheme.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          pdf ? l10n.cardBubbleDocument : l10n.cardBubbleSlides,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görsel/video karosu. Video kapağın ortasında oynat işareti, YouTube'da
/// kırmızı YouTube düğmesi taşır — fotoğraftan bakışta ayrılsın.
class CardMediaTile extends StatelessWidget {
  const CardMediaTile({
    super.key,
    required this.attachment,
    this.large = false,
  });

  final Attachment attachment;

  /// Kapak (büyük) mu — YouTube başlığı yalnız kapakta yazılır.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    if (a.isWebVideo) return _youTube(a);
    if (a.kind == AttachmentKind.video) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _LocalVideoCover(video: a),
          Center(child: _PlayBadge(size: large ? 40 : 26)),
        ],
      );
    }
    return _image(a);
  }

  Widget _youTube(Attachment a) {
    final id = youTubeVideoId(a.webUrl);
    const placeholder = ColoredBox(
      color: Color(0xFF202020),
      child: Center(
        child: Icon(Icons.smart_display_outlined, color: Colors.white70),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (id == null)
          placeholder
        else
          CachedNetworkImage(
            imageUrl: youTubeThumbnailUrl(id),
            fit: BoxFit.cover,
            memCacheWidth: 480,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          ),
        Center(
          child: Container(
            width: large ? 44 : 30,
            height: large ? 30 : 21,
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000),
              borderRadius: BorderRadius.circular(large ? 9 : 6),
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: large ? 22 : 16,
            ),
          ),
        ),
        if (large && a.fileName.isNotEmpty && a.fileName != 'YouTube')
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB3000000)],
                ),
              ),
              child: Text(
                a.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _image(Attachment a) {
    // Kart küçük resmi için 2048 px'lik eki tam boy çözdürmek boşuna bellek
    // ve CPU (liste kaydırma takılması); 480 px, 3x ekranda bile yeterli.
    //
    // YEREL KOPYA ÖNCE (2026-09-23, "görseller çok gecikiyor"): dosya zaten
    // cihazdayken kart onu ağdan YENİDEN indiriyordu.
    if (localFileExists(a.localPath)) {
      return Image.file(
        File(a.localPath),
        fit: BoxFit.cover,
        cacheWidth: 480,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _MissingTile(icon: Icons.image),
      );
    }
    if (a.isUploaded) {
      return CachedNetworkImage(
        imageUrl: a.downloadUrl,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        memCacheWidth: 480,
        placeholder: (context, _) => const ColoredBox(color: Colors.black12),
        errorWidget: (_, _, _) => const _MissingTile(icon: Icons.image),
      );
    }
    return const _MissingTile(icon: Icons.image_outlined);
  }
}

class _MissingTile extends StatelessWidget {
  const _MissingTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black12,
    child: Center(child: Icon(icon, size: 20, color: Colors.black38)),
  );
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white70, width: 1.5),
    ),
    child: Icon(Icons.play_arrow, color: Colors.white, size: size * 0.62),
  );
}

/// Cihazdaki videonun kapak karesi. Kare çıkarılamazsa (masaüstü, video bu
/// cihazda değil) koyu zemin üstünde kamera simgesi.
class _LocalVideoCover extends StatelessWidget {
  const _LocalVideoCover({required this.video});

  final Attachment video;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: Color(0xFF263238),
      child: Center(
        child: Icon(Icons.videocam_outlined, color: Colors.white54, size: 22),
      ),
    );
    if (!VideoFrame.supported || !localFileExists(video.localPath)) {
      return fallback;
    }
    return _AsyncThumb(
      future: CardThumbs.videoCover(video),
      fallback: fallback,
    );
  }
}

/// Not sayfasındaki videonun KAPAK KARESİ — oynatıcı kurulmadan önce
/// (bkz. `_VideoBox`'un tembel kurulumu). Kart kapağından büyük (720 px)
/// üretilir: sayfa genişliğinde bulanık durmasın. Diskte önbelleklenir.
class VideoPoster extends StatelessWidget {
  const VideoPoster({super.key, required this.video, this.fit = BoxFit.cover});

  final Attachment video;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: Color(0xFF263238),
      child: Center(
        child: Icon(Icons.videocam_outlined, color: Colors.white54, size: 26),
      ),
    );
    if (!VideoFrame.supported || !localFileExists(video.localPath)) {
      return fallback;
    }
    return FutureBuilder<Uint8List?>(
      future: CardThumbs.videoPoster(video),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return fallback;
        return Image.memory(
          bytes,
          fit: fit,
          cacheWidth: 720,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
  }
}

/// PDF'in (yer imli sayfası, yoksa ilk) sayfasının önbellekli küçük resmi —
/// kartın dışında da kullanılır (not ekranının alt ek şeridi).
class PdfFirstPageThumb extends StatelessWidget {
  const PdfFirstPageThumb({super.key, required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) =>
      _PdfFirstPage(attachment: attachment, iconSize: 28);
}

class _PdfFirstPage extends StatelessWidget {
  const _PdfFirstPage({required this.attachment, this.iconSize = 24});

  final Attachment attachment;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Center(
      child: Icon(
        Icons.picture_as_pdf_outlined,
        color: scheme.error,
        size: iconSize,
      ),
    );
    if (!localFileExists(attachment.localPath)) return fallback;
    return _AsyncThumb(
      future: CardThumbs.pdfPage(attachment, math.max(1, attachment.pdfPage)),
      fallback: fallback,
      alignment: Alignment.topCenter,
    );
  }
}

/// Önbellekteki küçük resmi gösterir; hazır olana dek [fallback].
class _AsyncThumb extends StatelessWidget {
  const _AsyncThumb({
    required this.future,
    required this.fallback,
    this.alignment = Alignment.center,
  });

  final Future<Uint8List?> future;
  final Widget fallback;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: future,
    builder: (context, snap) {
      final bytes = snap.data;
      if (bytes == null) return fallback;
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        alignment: alignment,
        cacheWidth: 480,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    },
  );
}

/// Kart küçük resimlerinin (video kapağı, PDF ilk sayfası) önbelleği.
///
/// Anahtar çizimde G/Ç YAPMADAN ekin alanlarından kurulur (yol + boyut +
/// sayfa); üretilen resim diske yazılır (`<önbellek>/card_thumbs/`), üretim
/// TEK SIRADA (kaydırmada çözücüler yarışmaz), video karesi arka planda ve
/// doğrudan küçük. Bellekteki baytlar bütçeli (F7.1).
abstract final class CardThumbs {
  static final _cache = <String, Future<Uint8List?>>{};
  static const _cap = 64;

  /// Bellekteki baytların tavanı (F7.1): 64 PDF kapağı PNG'yken yüzlerce
  /// KB'tan onlarca MB'a çıkabiliyordu. Aşınca en eski kullanılan düşer
  /// (disk kopyası kalır).
  static const _byteBudget = 6 * 1024 * 1024;
  static final _sizes = <String, int>{};
  static int _bytes = 0;

  /// Bellekte tutulan küçük resim baytları (teşhis — F9.2).
  static int get memoryBytes => _bytes;

  /// Üretim kuyruğu: bir önceki iş bitmeden yenisi başlamaz.
  static Future<void> _queue = Future.value();

  static Future<Uint8List?> videoCover(Attachment video) => _get(
    'v|${video.localPath}|${video.sizeBytes}',
    () => VideoFrame.thumbnail(video.localPath),
  );

  /// Sayfadaki video kutusunun kapağı (bkz. [VideoPoster]) — 720 px.
  static Future<Uint8List?> videoPoster(Attachment video) => _get(
    'vp|${video.localPath}|${video.sizeBytes}',
    () => VideoFrame.thumbnail(video.localPath, maxSide: 720),
  );

  /// Bellekteki küçük resim baytlarını bırakır (disk önbelleği kalır).
  /// Uygulama arka plana geçince ve sistem bellek sıkışıklığı bildirince
  /// çağrılır — geri dönüşte diskten anında okunur.
  static void clearMemory() {
    _cache.clear();
    _sizes.clear();
    _bytes = 0;
  }

  static Future<Uint8List?> pdfPage(Attachment pdf, int page) => _get(
    // 'pj': kapak JPEG (eski 'p' anahtarlı PNG'ler diskte yeniden kullanılmaz).
    'pj|${pdf.localPath}|${pdf.sizeBytes}|$page',
    () => _renderPdf(pdf.localPath, page),
  );

  static Future<Uint8List?> _get(
    String key,
    Future<Uint8List?> Function() make,
  ) {
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit; // en yeni kullanılan sona
      return hit;
    }
    final future = _load(key, make).catchError((Object _) => null);
    _cache[key] = future;
    if (_cache.length > _cap) _forget(_cache.keys.first);
    future.then((bytes) {
      // Bu arada düşürüldüyse sayılmaz.
      if (bytes == null || !identical(_cache[key], future)) return;
      _bytes += bytes.length - (_sizes[key] ?? 0);
      _sizes[key] = bytes.length;
      _trim(key);
    });
    return future;
  }

  static void _forget(String key) {
    _cache.remove(key);
    _bytes -= _sizes.remove(key) ?? 0;
  }

  /// Bütçe aşılınca en eski kullanılanları düşürür; [keep] (az önce gelen)
  /// tek başına bütçeyi aşsa da kalır.
  static void _trim(String keep) {
    while (_bytes > _byteBudget) {
      final oldest = _cache.keys.firstWhere(
        (k) => k != keep,
        orElse: () => keep,
      );
      if (oldest == keep) break;
      _forget(oldest);
    }
  }

  static Future<Uint8List?> _load(
    String key,
    Future<Uint8List?> Function() make,
  ) async {
    final file = await _diskFile(key);
    if (file != null && await file.exists()) return file.readAsBytes();
    // Sıraya gir: önceki üretim bitince başla.
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    try {
      await previous;
      final bytes = await make();
      if (bytes != null && file != null) {
        try {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        } catch (_) {
          // Disk dolu/erişilemez: küçük resim yalnız bellekte kalır.
        }
      }
      return bytes;
    } finally {
      done.complete();
    }
  }

  static String? _dir;

  static Future<File?> _diskFile(String key) async {
    if (kIsWeb) return null;
    try {
      _dir ??= (await getApplicationCacheDirectory()).path;
    } catch (_) {
      return null;
    }
    final name = sha1.convert(utf8.encode(key)).toString();
    return File('$_dir/card_thumbs/$name.img');
  }

  static Future<Uint8List?> _renderPdf(String path, int pageNumber) async {
    final document = await PdfDocument.openFile(path);
    try {
      final pages = document.pages;
      if (pages.isEmpty) return null;
      final page = pages[(pageNumber - 1).clamp(0, pages.length - 1)];
      // Kart kapağı ~200 dp genişlikte: 3x ekranda ~600 px; 480 px yeter.
      return await renderPdfPageJpeg(page, width: 480);
    } finally {
      await document.dispose();
    }
  }

  @visibleForTesting
  static void clear() => clearMemory();

  /// Testte üretimi taklit etmek için (disk ve pdfium olmadan).
  @visibleForTesting
  static Future<Uint8List?> debugGet(
    String key,
    Future<Uint8List?> Function() make,
  ) => _get(key, make);
}
