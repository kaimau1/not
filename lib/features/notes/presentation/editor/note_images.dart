import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../domain/attachment.dart';
import '../viewers/image_viewer.dart';
import '../viewers/ink_layer.dart';
import '../viewers/pdf_viewer_screen.dart';
import '../../../../core/utils/youtube.dart';
import '../viewers/video_viewer.dart';
import '../viewers/youtube_viewer.dart';
import 'image_layout.dart';
import 'pdf_page_box.dart';
import 'text_wrap.dart';

/// Görseli tam ekran açar (yoksa "henüz senkronlanmadı" der). Tam ekranda
/// görselin üzerine elle yazılabilir; çizim [onChanged] ile ekin `ink`
/// alanına döner.
void openImageViewer(
  BuildContext context,
  Attachment img,
  ValueChanged<Attachment> onChanged, {
  Future<void> Function(Attachment, Rect)? onCrop,
  Future<Attachment?> Function(Attachment, int)? onRotate,
  List<Attachment> gallery = const [],
}) {
  final hasLocal = localFileExists(img.localPath);
  if (!hasLocal && !img.isUploaded) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.attachmentNotSynced)));
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ImageViewerScreen(
        attachment: img,
        // Tam ekranda yana kaydırarak nottaki diğer görsellere geçilir.
        gallery: gallery,
        onChanged: onChanged,
        onCrop: onCrop,
        onRotate: onRotate,
      ),
    ),
  );
}

/// Sayfayı en az [minHeight] kadar uzatır ama bu değeri ÇOCUĞA GEÇİRMEZ.
///
/// KÖK NEDEN (kullanıcı: "yeni öğe ekleyince klavye açılırken kasma devam
/// ediyor ve kasma birikip artıyor sanki"): burada eskiden
/// `ConstrainedBox(minHeight: …)` vardı. `ConstrainedBox` en az yüksekliği
/// çocuğun KISITINA yazar; çocuk da bütün not sayfası (başlık, gövde ve
/// `shrinkWrap` olduğu için TEK TEK YERLEŞTİRİLEN her madde satırı).
///
/// Sayfanın en az yüksekliği gövdenin görünür yüksekliğidir ve klavye
/// açılırken bu değer her karede değişir (alt çubuk klavye kadar büyüdüğü
/// için gövde kısalır). Yani klavyenin her animasyon karesinde madde
/// listesinin TAMAMI yeniden yerleşiyordu: 20 maddelik bir notta kare başına
/// 20 `TextField` yerleşimi. "Birikip artıyor" hissi de buradan — bedel
/// madde sayısıyla doğru orantılı, her yeni madde klavyeyi bir tık daha
/// ağırlaştırıyordu.
///
/// Bu kutu çocuğu kendi doğal yüksekliğinde ölçer (kısıt DEĞİŞMEZ, yerleşim
/// atlanır) ve yalnız KENDİ boyunu büyütür. Sayfanın dokunulabilir alanı ve
/// kaydırma uzunluğu aynı kalır.
class PageMinHeight extends SingleChildRenderObjectWidget {
  const PageMinHeight({super.key, required this.minHeight, super.child});

  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPageMinHeight(minHeight);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderPageMinHeight).minHeight = minHeight;
}

class _RenderPageMinHeight extends RenderProxyBox {
  _RenderPageMinHeight(this._minHeight);

  double _minHeight;
  set minHeight(double value) {
    if (_minHeight == value) return;
    _minHeight = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(0, _minHeight));
      return;
    }
    // Çocuğa GELEN kısıt olduğu gibi verilir: `_minHeight` değişse de çocuğun
    // kısıtı değişmez, kirli değilse yerleşimi tümden atlanır.
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, math.max(child.size.height, _minHeight)),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(super.computeMinIntrinsicHeight(width), _minHeight);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(super.computeMaxIntrinsicHeight(width), _minHeight);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(Size(0, _minHeight));
    final childSize = child.getDryLayout(constraints);
    return constraints.constrain(
      Size(childSize.width, math.max(childSize.height, _minHeight)),
    );
  }
}

/// Çözdürme genişliğinin YUVARLANDIĞI adım (px). Bkz. [decodeWidthBucket].
const int kDecodeWidthStep = 256;

/// Görselin kaç piksel genişliğinde çözdürüleceği — kutunun genişliğinden
/// hesaplanır ama [kDecodeWidthStep]'in katına YUVARLANIR.
///
/// KÖK NEDEN (kullanıcı: "görsel ekleyince sayfaya kasma artıyor", "kasma
/// birikip artıyor sanki"): `cacheWidth` doğrudan `kutuGenişliği × dpr`
/// idi, yani kutu bir piksel bile değişse BAŞKA bir değer çıkıyordu. O değer
/// görsel önbelleğinin anahtarının parçası: her yeni değer için dosya
/// DİSKTEN yeniden çözülüyor ve önbelleğe AYRI bir kopya olarak giriyordu.
///
/// Sonuçları tam olarak kullanıcının tarif ettiği gibi:
/// - Görseli köşesinden boyutlandırmak kare başına bir tam çözdürme demekti.
/// - Aynı görselin onlarca kopyası önbelleği (varsayılan 100 MB) dolduruyor,
///   dolan önbellek başka görselleri atıyor, onlar da yeniden çözülüyordu —
///   yani kasma kullandıkça BİRİKİYORDU.
/// - Anahtar her değiştiğinde kare boşa düşüyor, görsel bir an kayboluyordu.
///
/// 256 px'lik adımlarla boyutlandırma boyunca anahtar sabit kalır (aynı bitmap
/// yeniden kullanılır) ve önbellekte görsel başına birkaç kopya olur. Adım
/// kalitede fark yaratmaz: `BoxFit` zaten ölçekliyor ve yukarı yuvarlandığı
/// için çözünürlük gösterilen boyuttan asla düşük kalmaz.
int? decodeWidthBucket(double boxWidth, double devicePixelRatio) {
  if (!boxWidth.isFinite || boxWidth <= 0) return null;
  final pixels = boxWidth * devicePixelRatio;
  final buckets = (pixels / kDecodeWidthStep).ceil();
  return math.max(1, buckets) * kDecodeWidthStep;
}

/// Görsel ekin içeriği: yerel dosya → indirme adresi → yer tutucu sırasıyla.
/// Tam ekranda görselin üzerine yazılan çizim (ekin `ink` alanı) burada da
/// çizilir — yoksa çizim "kaybolmuş" görünürdü. Kutunun en-boy oranı görselin
/// oranıyla aynı tutulduğu için oranlı noktalar birebir oturur.
class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.img, this.fit = BoxFit.cover});

  final Attachment img;

  /// Tuvalde `cover` (kutuyu doldurur), büyük önizlemede `contain`
  /// (görselin tamamı görünsün — önizlemenin amacı bu).
  final BoxFit fit;

  /// Görselin üstüne yazılmış AÇIK METİNLER (Paint tarzı metin aracı —
  /// bkz. `PageBubble.plain`). Not sayfasındaki küçük halde de görünmeli:
  /// yoksa kullanıcı fotoğrafa yazı koyuyor ama notta hiçbir şey değişmiyor.
  ///
  /// Yalnız `plain` olanlar çizilir; balon TUTAMAÇLARI küçük önizlemede
  /// okunmaz birer nokta olurdu, onlar tam ekranda görünür.
  ///
  /// Salt çizim: denetleyici kurulmaz (küçük halde düzenleme yok) ve
  /// dokunuş yutulmaz — görsele dokunmak yine tam ekranı açar.
  List<Widget> _plainTexts(Size box) {
    final texts = [
      for (final b in img.bubbles)
        if (b.plain && b.text.trim().isNotEmpty) b,
    ];
    if (texts.isEmpty) return const [];
    return [
      for (final b in texts)
        Positioned(
          left: b.x * box.width,
          top: b.y * box.height,
          child: IgnorePointer(
            child: DecoratedBox(
              // Dolgu küçük halde de çizilir: tam ekranda zemini olan bir
              // yazı, notta zeminsiz görünüp okunmaz olmasın.
              decoration: BoxDecoration(
                color: b.fill == 0 ? null : Color(b.fill),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: b.fill == 0 ? 0 : 2,
                ),
                child: Text(
                  b.text.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: switch (b.align) {
                    1 => TextAlign.center,
                    2 => TextAlign.right,
                    _ => TextAlign.left,
                  },
                  style: TextStyle(
                    // Küçük halde okunabilirlik için oranlı: tam ekrandaki
                    // 16 pt burada kutunun genişliğine göre küçülür.
                    fontSize: (box.width * 0.05).clamp(7.0, 14.0),
                    height: 1.2,
                    fontWeight: b.bold ? FontWeight.w800 : FontWeight.w600,
                    fontStyle: b.italic
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: Color(b.color),
                    shadows: b.fill == 0
                        ? const [Shadow(blurRadius: 2, color: Colors.black54)]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (img.ink.isEmpty && img.bubbles.isEmpty) return _content(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Positioned.fill(child: _content(context)),
            if (img.ink.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: InkPainter(img.ink, 1)),
                ),
              ),
            ..._plainTexts(box),
          ],
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // build sıcak yolunda senkron stat yapmamak için önbellekli denetim.
    final hasLocal = localFileExists(img.localPath);
    // Görseli EKRAN boyutunda çözdür: ekler 2048 px'e kadar saklanıyor ama
    // tuvalde ~300-400 px gösteriliyor; tam çözünürlükte decode etmek boşuna
    // bellek + işlemci (kaydırma takılması) demekti.
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final targetWidth = decodeWidthBucket(constraints.maxWidth, dpr);
        if (hasLocal) {
          return Image.file(
            File(img.localPath),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: targetWidth,
          );
        } else if (img.isUploaded) {
          // İNERKEN BOŞ KUTU YOKTU (kullanıcı ekran görüntüsü 2026-09-23:
          // altı görselli not başka cihazda boş bir ızgara gibi görünüyordu).
          // Artık indirme ilerlemesi kutunun ortasında; gelince yumuşakça
          // belirir, inemezse kırık görsel simgesi durur.
          return CachedNetworkImage(
            imageUrl: img.downloadUrl,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: targetWidth,
            fadeInDuration: const Duration(milliseconds: 180),
            progressIndicatorBuilder: (context, _, progress) => Container(
              color: scheme.surfaceContainerHigh,
              alignment: Alignment.center,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: progress.progress,
                  color: scheme.primary,
                ),
              ),
            ),
            errorWidget: (context, _, _) => Container(
              color: scheme.surfaceContainerHigh,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        }
        // Başka cihazda eklenmiş, henüz buluta çıkmamış görsel: boş bir
        // görsel simgesi "bozuk" gibi okunuyordu; bulut-senkron simgesi
        // "geliyor" der.
        return Container(
          color: scheme.surfaceContainerHigh,
          alignment: Alignment.center,
          child: Icon(
            Icons.cloud_sync_outlined,
            color: scheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

/// Görsel/video ekin İÇERİĞİ — sayfa tuvali ile notun üstündeki sabit
/// bölme ([PinnedMediaPane]) aynı çizimi kullanır.
///
/// [inlineWebVideo]: YouTube eki oynat düğmesinde KUTUNUN İÇİNDE oynar
/// (sabit bölme — "üstte video, altta not"); false ise oynatıcı ekranı
/// açılır (sayfada yüzen kutu taşınabilir kalsın, WebView jestleri yutmasın).
class NoteMediaBox extends StatelessWidget {
  const NoteMediaBox({
    super.key,
    required this.attachment,
    this.fit = BoxFit.cover,
    this.inlineWebVideo = false,
    this.webPlaying,
    this.onWebPlay,
    this.onSize,
    this.showWebTitle = false,
  });

  final Attachment attachment;
  final BoxFit fit;
  final bool inlineWebVideo;

  /// YouTube kapağının üstünde videonun BAŞLIĞI (kullanıcı isteği
  /// 2026-10-11: "videoların başlığı üzerine tıklayınca görülmeli"). Sayfada
  /// kutu SEÇİLİNCE, büyük önizlemede ve sabit bölmede açık.
  final bool showWebTitle;

  /// DENETİMLİ kip (sayfa tuvali): oynuyor mu bilgisini çağıran tutar —
  /// kutunun DIŞINDA bir "durdur" düğmesi çizebilsin diye. null = kutu kendi
  /// durumunu tutar (sabit bölme).
  final bool? webPlaying;
  final VoidCallback? onWebPlay;
  final ValueChanged<Size>? onSize;

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    if (a.isWebVideo) {
      return _WebVideoBox(
        video: a,
        fit: fit,
        inline: inlineWebVideo,
        playing: webPlaying,
        onPlay: onWebPlay,
        showTitle: showWebTitle,
      );
    }
    if (a.kind == AttachmentKind.video) {
      return _VideoBox(video: a, fit: fit, onSize: onSize);
    }
    return _ImageBox(img: a, fit: fit);
  }
}

/// YouTube ekinin kutusu: kapak görseli + oynat düğmesi + küçük YouTube
/// rozeti. Kapak ağsız da çizilemezse koyu zemin üstünde simge kalır.
class _WebVideoBox extends StatefulWidget {
  const _WebVideoBox({
    required this.video,
    required this.fit,
    required this.inline,
    this.playing,
    this.onPlay,
    this.showTitle = false,
  });

  final Attachment video;
  final BoxFit fit;
  final bool inline;
  final bool? playing;
  final VoidCallback? onPlay;
  final bool showTitle;

  @override
  State<_WebVideoBox> createState() => _WebVideoBoxState();
}

class _WebVideoBoxState extends State<_WebVideoBox> {
  bool _playing = false;

  void _play() {
    if (widget.inline && youTubeInAppSupported) {
      if (widget.onPlay != null) {
        widget.onPlay!();
      } else {
        setState(() => _playing = true);
      }
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoViewerScreen(attachment: widget.video),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _WebVideoBox old) {
    super.didUpdateWidget(old);
    if (old.video.webUrl != widget.video.webUrl) _playing = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playing ?? _playing) {
      return YouTubeInlinePlayer(url: widget.video.webUrl);
    }
    final id = youTubeVideoId(widget.video.webUrl);
    final placeholder = Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: const Icon(Icons.smart_display_outlined, color: Colors.white70),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (id == null)
          placeholder
        else
          CachedNetworkImage(
            imageUrl: youTubeThumbnailUrl(id),
            fit: widget.fit,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          ),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _play,
            child: Container(
              width: 52,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        // Başlık YouTube'daki gibi üstte, koyu geçişli şeritte. Dokunuşu
        // yutmaz (kutu taşınabilir/seçilebilir kalsın). Ad henüz gelmediyse
        // ("YouTube" yer tutucusu) şerit çizilmez.
        if (widget.showTitle && widget.video.fileName != 'YouTube')
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                key: const ValueKey('web-video-title'),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
                child: Text(
                  widget.video.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Video ekin sayfa üzerindeki kutusu: video **olduğu yerde** oynar — ortada
/// oynat/durdur düğmesi, ayrı ekrana gitmek gerekmez (tam ekran, araç
/// çubuğundaki düğmede). Dosya yoksa (video buluta çıkmaz — başka cihazda
/// yalnız yer tutucu olur) ya da oynatıcı desteklenmiyorsa (masaüstü) kamera
/// simgeli yer tutucu çizilir; kutu taşınıp boyutlandırılabilir kalır.
class _VideoBox extends StatefulWidget {
  const _VideoBox({required this.video, this.fit = BoxFit.cover, this.onSize});

  final Attachment video;

  /// Tuvalde `cover`, büyük önizlemede `contain` (bkz. [_ImageBox.fit]).
  final BoxFit fit;

  /// Video çözülünce doğal boyutunu bildirir — ekin `width`/`height` alanları
  /// boşsa kalıcılaştırılır ki kutunun oranı (1:1 varsayılan yerine) sonraki
  /// açılışta da doğru olsun. null = zaten biliniyor, bildirme.
  final ValueChanged<Size>? onSize;

  @override
  State<_VideoBox> createState() => _VideoBoxState();
}

class _VideoBoxState extends State<_VideoBox> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _playing = false;
  bool _sizeReported = false;

  /// TARTILDI, TEMBELLEŞTİRİLMEDİ: oynatıcı `initState`te kurulur.
  ///
  /// Tembel kurulum (ilk dokunuşta) platform çözücüsünü geciktirirdi — çok
  /// videolu notta eşzamanlı çözücü sınırını zorlamamak açısından iyi olurdu.
  /// Ama kutunun İLK KARESİ oynatıcıdan geliyor: tembel kurulumda kullanıcı
  /// dokunana kadar videonun yerinde genel bir kamera simgesi duruyor. Bir
  /// videolu (yaygın) durumda görünür bir gerileme, dört videolu (nadir)
  /// durumda kazanç — takas kabul edilmedi. Küçük resim ayrıca üretilirse
  /// tembel kurulum yeniden düşünülebilir.
  bool _initStarted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (_initStarted) return;
    _initStarted = true;
    // Dosya yoksa denemeye gerek yok: yer tutucu kalır.
    if (!localFileExists(widget.video.localPath)) return;
    final controller = VideoPlayerController.file(File(widget.video.localPath));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(_onTick);
      setState(() {});
      final size = controller.value.size;
      if (!_sizeReported && size.width > 0 && size.height > 0) {
        _sizeReported = true;
        widget.onSize?.call(size);
      }
    } catch (_) {
      // Oynatıcı bu platformda yok (Windows) ya da dosya bozuk.
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Yalnız oynuyor/durdu geçişinde yeniden çizim — her karede setState
  /// çağırmak kutuyu boşuna ısıtırdı (VideoPlayer kendi karesini kendisi
  /// tazeliyor).
  void _onTick() {
    final playing = _controller?.value.isPlaying ?? false;
    if (playing != _playing && mounted) setState(() => _playing = playing);
  }

  @override
  void didUpdateWidget(covariant _VideoBox old) {
    super.didUpdateWidget(old);
    if (old.video.localPath != widget.video.localPath) {
      _controller?.removeListener(_onTick);
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _initStarted = false;
      _init();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    // İlk dokunuşta oynatıcı burada kurulur (bkz. [_initStarted]).
    if (!_initStarted) {
      await _init();
      if (!mounted) return;
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }
    // Bittiyse oynat = baştan.
    final v = controller.value;
    if (v.duration > Duration.zero && v.position >= v.duration) {
      await controller.seekTo(Duration.zero);
    }
    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller;
    if (controller == null || _failed || !controller.value.isInitialized) {
      return Container(
        color: scheme.surfaceContainerHigh,
        alignment: Alignment.center,
        child: Icon(Icons.videocam_outlined, color: scheme.onSurfaceVariant),
      );
    }
    final size = controller.value.size;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        // Oynat/durdur dokunuşu KENDİ alır: dıştaki jest (seçim) çalışmaya
        // devam eder — videonun kenarına dokunmak seçer, ortasına dokunmak
        // oynatır. Oynarken düğme yarı saydamlaşır, video okunur kalır.
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: AnimatedOpacity(
              opacity: _playing ? 0.35 : 1,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Seçili görselin işlem çubuğu içeriği (genişlik kaydırıcısı + OCR + tam
/// ekran + sil): küçük tuval ve tam sayfa katmanı ortak kullanır.
class _ImageTools extends StatelessWidget {
  const _ImageTools({
    required this.wFrac,
    required this.minWidthFrac,
    required this.onWidthChanged,
    required this.onWidthEnd,
    required this.onFullscreen,
    required this.onRemove,
    this.onExtractText,
    this.onCopy,
    this.onSelectMany,
    this.onDetach,
    this.onVideoToNote,
    this.onPinTop,
    this.copyIsLink = false,
    this.onOpenExternal,
  });

  final double wFrac;
  final double minWidthFrac;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onWidthEnd;
  final VoidCallback onFullscreen;
  final VoidCallback onRemove;
  final VoidCallback? onExtractText;

  /// Görseli panoya kopyalar (uygulama içi ek panosu + sistem panosu).
  final VoidCallback? onCopy;

  /// ÇOKLU seçim kipini açar (birden çok görseli birlikte kopyala/sil).
  /// Sayfada tek görsel varsa gösterilmez — seçecek ikinci bir şey yok.
  final VoidCallback? onSelectMany;

  /// Görseli sayfadan alıp alt şeritte DOSYA eki yapar.
  final VoidCallback? onDetach;

  /// Videodan (görüntü + ses) AI ile not çıkarır — yalnız video ekinde dolu.
  final VoidCallback? onVideoToNote;

  /// Görseli/videoyu notun ÜSTÜNDEKİ sabit bölmeye alır (bkz.
  /// [Attachment.pinHeight]). Aynı iş görseli sayfanın tepesine sürükleyerek
  /// de yapılır; menüdeki giriş, hareketi bilmeyen için.
  final VoidCallback? onPinTop;

  /// [onCopy] BAĞLANTI kopyalar (YouTube eki — dosyası yok, kopyalanacak şey
  /// adresi). Menüde "Bağlantıyı kopyala" olarak ÜSTTE görünür.
  final bool copyIsLink;

  /// YouTube ekini YouTube uygulamasında/tarayıcıda açar.
  final VoidCallback? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Material(
      color: scheme.surfaceContainerHighest,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.photo_size_select_large,
              size: 18,
              color: scheme.primary,
            ),
            Expanded(
              child: Slider(
                value: wFrac,
                min: minWidthFrac,
                max: 1,
                onChanged: onWidthChanged,
                onChangeEnd: onWidthEnd,
              ),
            ),
            IconButton(
              tooltip: l10n.fullscreen,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.fullscreen, size: 20),
              onPressed: onFullscreen,
            ),
            IconButton(
              tooltip: l10n.removeAttachment,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: scheme.error,
              onPressed: onRemove,
            ),
            // Seyrek kullanılan işlemler menüde: hepsi ayrı düğme olsaydı
            // çubuk dar ekranda kaydırıcıya yer bırakmazdı. Hiçbiri
            // verilmemişse düğme de çizilmez (boş menü açılışta patlar).
            if (onExtractText != null ||
                onCopy != null ||
                onSelectMany != null ||
                onDetach != null ||
                onVideoToNote != null ||
                onPinTop != null ||
                onOpenExternal != null)
              PopupMenuButton<String>(
                tooltip: l10n.more,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case 'ocr':
                      onExtractText?.call();
                    case 'copy':
                      onCopy?.call();
                    case 'selectMany':
                      onSelectMany?.call();
                    case 'detach':
                      onDetach?.call();
                    case 'videoToNote':
                      onVideoToNote?.call();
                    case 'pinTop':
                      onPinTop?.call();
                    case 'openExternal':
                      onOpenExternal?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (onCopy != null && copyIsLink)
                    PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.link),
                        title: Text(l10n.copyVideoLink),
                      ),
                    ),
                  if (onOpenExternal != null)
                    PopupMenuItem(
                      value: 'openExternal',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.open_in_new),
                        title: Text(l10n.youTubeOpenExternal),
                      ),
                    ),
                  if (onPinTop != null)
                    PopupMenuItem(
                      value: 'pinTop',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.vertical_align_top),
                        title: Text(l10n.pinMediaTop),
                      ),
                    ),
                  if (onVideoToNote != null)
                    PopupMenuItem(
                      value: 'videoToNote',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.auto_awesome_outlined),
                        title: Text(l10n.videoToNote),
                      ),
                    ),
                  if (onExtractText != null)
                    PopupMenuItem(
                      value: 'ocr',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.document_scanner_outlined),
                        title: Text(l10n.extractText),
                      ),
                    ),
                  if (onCopy != null && !copyIsLink)
                    PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.copy_outlined),
                        title: Text(l10n.copy),
                      ),
                    ),
                  if (onSelectMany != null)
                    PopupMenuItem(
                      value: 'selectMany',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.checklist),
                        title: Text(l10n.selectImages),
                      ),
                    ),
                  if (onDetach != null)
                    PopupMenuItem(
                      value: 'detach',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.attachment_outlined),
                        title: Text(l10n.moveImageToAttachments),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Metin notunda görselleri (el yazısı çizimleri dahil — onlar da görsel
/// ektir) ve videoları TÜM SAYFA üzerinde serbest katman olarak gösterir:
/// video da görsel gibi taşınır/boyutlandırılır ve olduğu yerde oynar
/// ([_VideoBox]). [child]
/// (başlık + gövde metni) normal akışında durur, görseller üstünde yüzer ve
/// sayfayla birlikte kayar. Görsel metnin sağına/soluna, sayfanın istenen
/// yerine sürüklenebilir; kalan alana metin yazılır ("çerçeve içi" küçük
/// tuvalin kaldırdığı sınır).
///
/// Konum: yatay [Attachment.x] (sayfa genişliği oranı), dikey
/// [Attachment.pageY] (sayfa tepesinden dp — sayfa yüksekliği metinle
/// değiştiğinden oran değil mutlak değer). Sayfa, en alttaki görseli
/// kapsayacak kadar uzar; görsel aşağı sürüklendikçe büyür.
/// İpucunun oturacağı yükseklik: gövdenin ilk satırı ([bodyTop]), onu kesen
/// görsel bantlarının altına itilmiş hâli.
///
/// Bantlar yukarıdan aşağı taranır ve tek geçiş yeter: ipucu her itilişte
/// aşağı gider, itildikten sonra o bandı bir daha kesemez, sıradaki bantlar
/// ise zaten daha aşağıdadır. Kesişme yoksa sonuç [bodyTop]'tur — yani
/// görselsiz notta ipucu her zamanki yerinde kalır.
@visibleForTesting
double hintTopFor(List<FloatBox> floats, double bodyTop, double lineHeight) {
  final sorted = [...floats]..sort((a, b) => a.top.compareTo(b.top));
  var y = bodyTop;
  for (final f in sorted) {
    if (f.top < y + lineHeight && y < f.bottom) {
      // SATIRA OTURT: metin sürekli değil, SATIR SATIR akar — imleç bandın
      // bittiği dp'ye değil, bandı geçen İLK SATIRIN başına iner (sarma planı
      // da tam olarak bunu yapar, bkz. planTextWrap). Yuvarlanmazsa ipucu bir
      // satırın altında kalan bir farkla imlecin üstünde/altında görünür —
      // kullanıcının "ipucu ile imleç farklı yerlerde" dediği fark budur.
      y = lineHeight > 0
          ? bodyTop + ((f.bottom - bodyTop) / lineHeight).ceil() * lineHeight
          : f.bottom;
    }
  }
  return y;
}

/// İpucunun ilk satırda SOLDAN ne kadar içeride başlayacağı (dp).
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-08-16, ekran görüntüsü: "Not... yazısı
/// ile imleç farklı yerlerde, imlecin yeri doğru"): ipucu görselin ALTINA
/// itiliyordu ([hintTopFor]), oysa METİN görselin YANINDAN akıyor — imleç de
/// ilk satırda, görselin sağında duruyordu. İpucu ile imleç iki ayrı yerde
/// görününce not boşken kullanıcı nereye yazacağını göremiyordu.
///
/// Artık ipucu metnin kuralını izler: ilk satırda görselin sağında kullanılır
/// genişlik kalıyorsa ipucu O SATIRDA, görselin sağından başlar; kalmıyorsa
/// (sarma eşiği — bkz. `text_wrap.dart`) eskisi gibi görselin altına iner.
///
/// [columnWidth] metin sütununun genişliği. Dönen değer soldaki dolgudur —
/// üst konum yine [hintTopFor]'dan gelir ve dolgu sıfırdan büyükse o üst konum
/// [bodyTop]'ta kalır.
///
/// DOLGU BURADA HESAPLANMAZ, SARMA PLANINDAN OKUNUR ([wrapLineIndents]).
/// Eskiden buradaki ayrı hesap `left > 0` olan her görseli "sağ kenarda"
/// sayıyordu; ORTADA duran bir görselde plan metni görselin SAĞINA akıtırken
/// ipucu kendini ALTINA indiriyordu (kullanıcı bulgusu 2026-08-30: "imleç
/// kaymıyor ama ipucu başka yerde hâlâ"). Aynı dikiş üçüncü kez patladığı için
/// karar tek kaynağa bağlandı.
({double top, double left}) hintPlacement(
  List<FloatBox> floats,
  double bodyTop,
  double lineHeight,
  double columnWidth, {
  double textScaleFactor = 1.0,
}) {
  if (floats.isEmpty || columnWidth <= 0) return (top: bodyTop, left: 0);
  // İlk satırın dolgusu: metnin ilk satırı da tam olarak bundan etkileniyor.
  final indents = wrapLineIndents(
    floats: floats,
    columnWidth: columnWidth,
    top: bodyTop,
    bottom: bodyTop + lineHeight,
    textScaleFactor: textScaleFactor,
  );
  if (indents.start >= columnWidth) {
    // Satırın tamamı dolgu: metin de bu satıra sığmıyor, ikisi birlikte
    // görselin altına iner.
    return (top: hintTopFor(floats, bodyTop, lineHeight), left: 0);
  }
  return (top: bodyTop, left: indents.start);
}

class NotePageCanvas extends StatefulWidget {
  const NotePageCanvas({
    super.key,
    required this.images,
    required this.child,
    required this.minHeight,
    required this.onRemove,
    required this.onChanged,
    this.onCrop,
    this.onRotate,
    this.onExtractText,
    this.onCopy,
    this.onCopyMany,
    this.onChangedMany,
    this.onDetach,
    this.onVideoToNote,
    this.onPinTop,
    this.onPinHover,
    this.onTapEmpty,
    this.topLimit = 0,
    this.onFloats,
    this.hint,
    this.hintLineHeight = 0,
    this.textTop = 0,
    this.textLeft = 0,
  });

  final List<Attachment> images;

  /// Sayfa içeriği (başlık, çipler, gövde metni). Görseller bunun üstünde.
  final Widget child;

  /// Görsellerin inebileceği en üst nokta (dp) — başlık ve çip satırının
  /// altı. Görsel başlığın üzerine hiç çıkamaz. Gövde metninin ilk satırının
  /// tepesi de burasıdır ([hint] bu noktadan aşağı itilir).
  final double topLimit;

  /// [topLimit] ile gövde metninin İLK SATIRININ tepesi arasındaki boşluk
  /// (dp) — alanın `contentPadding.top`u. İpucu metnin ilk satırıyla AYNI
  /// çizgide durmalı; bu pay geçilmezse ipucu bir yerde, imleç başka yerde
  /// görünür (kullanıcı bulgusu 2026-08-16 ve yine 2026-08-30).
  final double textTop;

  /// Gövde metninin SOL kenarı (dp) — alanın sayfa kenarından boşluğu.
  /// İpucu, metnin sütununda konumlanır: bantlar sayfa uzayında ölçülüyor,
  /// sarma planı ise sütun uzayında çalışıyor. Bu pay geçilmezse ipucu, metnin
  /// başladığı yerin bir kenar boşluğu KADAR sağında durur.
  final double textLeft;

  /// Boş gövdenin ipucu metni ("Not yaz…"), tuval üzerinde konumlandırılır.
  ///
  /// KÖK NEDEN: ipucu metin değil dekorasyondur — sarma motoru onu görselin
  /// etrafından akıtamaz, sabit yerinde durur ve üste sürüklenen görselin
  /// altında kaybolur. Eskiden görsel bir satır aşağı ZORLANARAK çözülüyordu;
  /// kullanıcı görseli en üste koyamıyordu. Artık görsel serbest, ipucu iner.
  final Widget? hint;

  /// İpucu satırının yüksekliği (dp) — hangi görsellerin ipucunu kestiği
  /// bu bantla ölçülür.
  final double hintLineHeight;

  /// Görsellerin SAYFA üzerinde kapladığı bantları bildirir; metin bunların
  /// etrafından akar (bkz. text_wrap.dart). Konumlar sayfanın (bu tuvalin
  /// [child]'ının) sol-üst köşesine göredir.
  final ValueChanged<List<FloatBox>>? onFloats;

  /// Sayfanın en az yüksekliği (görünür alan — boş nota da tam sayfa tuval).
  final double minHeight;

  final ValueChanged<Attachment> onRemove;
  final ValueChanged<Attachment> onChanged;

  /// Birden çok eki TEK yazımda günceller ("satıra sığdır", "boyutları
  /// eşitle"). null ise ekler tek tek [onChanged]'e verilir — o zaman her ek
  /// ayrı bir kayıt ve ayrı bir geri-al adımı olur.
  final ValueChanged<List<Attachment>>? onChangedMany;

  /// Tam ekranda seçilen kırpma alanını uygular (bkz. [ImageViewerScreen]).
  final Future<void> Function(Attachment, Rect)? onCrop;

  /// Görseli 90°'nin katıyla döndürüp KALICI olarak yeniden yazacak taraf
  /// ([onCrop] ile aynı gerekçe: dosyayı yeniden yazmak ek deposu ve not
  /// kimliği ister, ikisi de bu katmanda yok). null ise döndürme düğmesi
  /// çizilmez.
  final Future<Attachment?> Function(Attachment, int)? onRotate;
  final Future<void> Function(Attachment)? onExtractText;

  /// Görseli panoya kopyalar; null ise menüde görünmez.
  final ValueChanged<Attachment>? onCopy;

  /// ÇOKLU seçimde: seçilen eklerin tamamını panoya alır (kullanıcı isteği
  /// 2026-08-09: "görsellerde çoklu seçim ve kopyalama"). null ise çoklu
  /// seçim girişi hiç gösterilmez.
  final ValueChanged<List<Attachment>>? onCopyMany;

  /// Görseli sayfadan alıp ek şeridine taşır; null ise menüde görünmez.
  final ValueChanged<Attachment>? onDetach;

  /// Videodan AI ile not çıkarır; yalnız video ekinin menüsünde görünür.
  final ValueChanged<Attachment>? onVideoToNote;

  /// **ÜSTE SABİTLE** (kullanıcı isteği 2026-10-11: "üstte video/resim, altta
  /// not — görseli sürükleyerek"): basılı tutup sürüklenen görsel ekranın
  /// TEPESİNE (sayfanın görünen üst kenarına) bırakılınca çağrılır; görsel
  /// sayfadan kalkar, notun üstündeki sabit bölmeye geçer. null = kapalı.
  final ValueChanged<Attachment>? onPinTop;

  /// Sürüklenen görsel sabitleme bölgesine girdi/çıktı — editör o sırada
  /// ekranın tepesinde "Bırak: üste sabitle" şeridini gösterir.
  final ValueChanged<bool>? onPinHover;

  /// Boş alana dokununca (seçili görsel yokken) çağrılır — editör bununla
  /// gövde metnine odaklanır ("aşağıya dokun, yazmaya başla" davranışı).
  final VoidCallback? onTapEmpty;

  @override
  State<NotePageCanvas> createState() => _NotePageCanvasState();
}

class _NotePageCanvasState extends State<NotePageCanvas> {
  String? _selectedId;

  /// Taşıma sırasındaki canlı sol/üst (dp); bırakınca kaydedilir.
  String? _moveId;
  double? _moveLeft;
  double? _moveTop;

  /// Sürüklemenin başladığı yer — parmağın toplam yer değiştirmesi buna
  /// eklenir (canlı değere eklemek hareketi katlardı).
  double? _moveOriginLeft;
  double? _moveOriginTop;

  /// Sayfada YERİNDE oynayan YouTube ekleri (kullanıcı bulgusu 2026-10-11:
  /// "basınca ayrı bir video sayfası açılıyor, direkt o alanda
  /// oynatılabilmeli"). Oynarken WebView dokunuşları yutar; kutunun
  /// köşesindeki "durdur" düğmesi oynatıcıyı kapatıp kutuyu yeniden
  /// taşınabilir yapar.
  final _playingWeb = <String>{};

  /// Parmak şu an sabitleme bölgesinde mi (bkz. [NotePageCanvas.onPinTop]).
  bool _inPinZone = false;

  /// Sabitleme bölgesi: kaydırılan sayfanın GÖRÜNEN üst kenarından bu kadar
  /// dp (parmağın ekrandaki yeri ölçülür — sayfa aşağı kaydırılmışken de
  /// ekranın tepesine sürüklemek yeter).
  static const double _pinZoneHeight = 56;

  void _setPinZone(bool value) {
    if (_inPinZone == value) return;
    _inPinZone = value;
    if (value) HapticFeedback.mediumImpact();
    widget.onPinHover?.call(value);
  }

  /// Görsel izin verilen en üst noktanın ([NotePageCanvas.topLimit]) bu
  /// kadar ötesine ZORLANINCA sabitleme bölgesi sayılır.
  static const double _pinOverPull = 36;

  /// Sabitleme bölgesi mi: parmak ekranın tepesinde YA DA görsel yukarı doğru
  /// başlığın üstüne zorlanıyor ([rawTop] = parmağın istediği, kırpılmamış
  /// üst kenar).
  ///
  /// Kullanıcı bulgusu 2026-10-11: "sabitlemek için görseli en üst ortaya
  /// getirmek gerekiyor, zor". Görsel başlığın altında DURDUĞU için (üste
  /// çıkamaz) parmak ekranın tepesine kadar gitmek zorundaydı. Artık nerede
  /// olursa olsun yukarı doğru biraz zorlamak yeter; yatay konum önemsiz.
  bool _pinZoneHit(Offset global, {required double rawTop}) {
    if (widget.onPinTop == null) return false;
    if (rawTop < widget.topLimit - _pinOverPull) return true;
    final scrollable = Scrollable.maybeOf(context);
    final box = scrollable?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    return global.dy < top + _pinZoneHeight;
  }

  /// Sürükleme bitince yeni konumu kaydeder ve canlı değerleri temizler.
  void _commitMove(Attachment img, double cw) {
    if (_moveId != img.id) return;
    if (_inPinZone) {
      _setPinZone(false);
      setState(() {
        _moveId = null;
        _moveLeft = null;
        _moveTop = null;
        _moveOriginLeft = null;
        _moveOriginTop = null;
        _guides = const [];
        _selectedId = null;
      });
      widget.onPinTop?.call(img);
      return;
    }
    final nl = _moveLeft;
    final nt = _moveTop;
    if (nl != null && nt != null) {
      widget.onChanged(img.copyWith(x: nl / cw, pageY: nt));
    }
    setState(() {
      _moveId = null;
      _moveLeft = null;
      _moveTop = null;
      _moveOriginLeft = null;
      _moveOriginTop = null;
      _guides = const [];
    });
  }

  /// Boyutlandırma sırasındaki canlı genişlik oranı; bırakınca kaydedilir.
  String? _resizeId;
  double? _resizeWFrac;

  /// Parmağın YAPIŞMA UYGULANMAMIŞ genişliği. Kılavuza oturan değer geri
  /// beslenirse yapışma hareketi "yiyor": parmak ilerlerken genişlik aynı
  /// kilitli değerden hesaplandığı için görsel kılavuzdan bir türlü
  /// kopamıyordu. Ham değer ayrı birikir, ekrana yapışmış hâli çizilir.
  double? _resizeRawFrac;

  /// Taşıma/boyutlandırma sırasında çizilen hizalama çizgileri.
  List<AlignGuide> _guides = const [];

  /// Son yerleşimde ölçülen sayfa genişliği (dp) — çoklu seçim çubuğu gibi
  /// LayoutBuilder dışında kalan yerler oranları buradan çevirir.
  double _cw = 0;

  /// Konumu yazılmamış görsellerin bu karede hesaplanan yerleri (ek kimliği →
  /// sol/üst, dp). Her yerleşimde bir kez kurulur; [_resolve] buradan okur.
  final _autoSlots = <String, ({double left, double top})>{};

  static const double _minWidthFrac = 0.15;

  /// Çoklu seçim çubuğundaki düğmelerin sıkıştırması: altı simge ve seçim
  /// sayacı 360 dp'lik bir ekrana yan yana sığmalı.
  static const _kBarDensity = VisualDensity(horizontal: -4, vertical: -2);

  void _select(String id) =>
      setState(() => _selectedId = _selectedId == id ? null : id);

  void _deselect() {
    if (_selectedId != null) setState(() => _selectedId = null);
  }

  // ── ÇOKLU SEÇİM ─────────────────────────────────────────────────────────
  // Sayfadaki görseller tek tek seçilip ⋮ menüsünden kopyalanabiliyordu ama
  // ikisini birden almanın yolu yoktu (kullanıcı isteği 2026-08-09).
  // "Görselleri seç" tek görselin araç panelinden açılır; sonrasında her
  // dokunuş bir görseli işaretler, işlem çubuğu ekranın dibinde durur.

  /// Çoklu seçim açık mı ve hangi ekler işaretli.
  final _multi = <String>{};
  bool _multiMode = false;

  /// İşlem çubuğunu ekranın DİBİNE demirleyen katman (madde listesindeki
  /// seçim çubuğuyla aynı desen — sayfa nerede olursa olsun görünür).
  final _multiBar = OverlayPortalController();

  void _startMulti(String id) {
    setState(() {
      _multiMode = true;
      _selectedId = null;
      _multi
        ..clear()
        ..add(id);
    });
    if (!_multiBar.isShowing) _multiBar.show();
  }

  void _toggleMulti(String id) {
    setState(() {
      if (!_multi.remove(id)) _multi.add(id);
    });
    if (_multi.isEmpty) _endMulti();
  }

  void _endMulti() {
    setState(() {
      _multiMode = false;
      _multi.clear();
    });
    if (_multiBar.isShowing) _multiBar.hide();
  }

  /// İşaretli ekler — sayfa sırasıyla.
  List<Attachment> get _multiSelected => [
    for (final img in widget.images)
      if (_multi.contains(img.id)) img,
  ];

  /// Toplu düzen değişikliğini yazar: varsa tek yazım, yoksa tek tek.
  void _applyMany(List<Attachment> updated) {
    final many = widget.onChangedMany;
    if (many != null) {
      many(updated);
      return;
    }
    for (final a in updated) {
      widget.onChanged(a);
    }
  }

  /// İşaretli görsellerin GENİŞLİĞİNİ eşitler (kullanıcı isteği 2026-09-05:
  /// "görsel boyutu eşitleme seçeneği olsun"). Yükseklik en-boy oranından
  /// çıktığı için aynı orandaki görseller birebir aynı boyuta gelir.
  void _equalizeSizes() {
    final chosen = _multiSelected;
    if (chosen.length < 2 || _cw <= 0) return;
    final target = equalWidthFrac(
      [for (final a in chosen) a.displayWidth ?? _defaultWFrac(_cw)],
      minFrac: _minWidthFrac,
    );
    _applyMany([for (final a in chosen) a.copyWith(displayWidth: target)]);
    _endMulti();
  }

  /// İşaretli görselleri [perRow] sütunlu satırlara SIĞDIRIR: kenarları
  /// birbirine ve sayfanın iki yanına yapışacak şekilde yeniden
  /// boyutlandırılıp dizilir (kullanıcı isteği: "2 ya da 3 görseli bir satıra
  /// sığdır"). Seçim sütun sayısını aşarsa satırlara dengeli bölünür
  /// (6 görsel, 3 sütun → 3 + 3; 2 sütun → 2 + 2 + 2).
  ///
  /// SÜTUN SAYISI KULLANICIDA (2026-09-05 geri bildirimi: "hep 3 sütunlu
  /// yapıyor, 2 sütunlu da olmalı"): eskiden satır başına en çok 3 görsel
  /// sabitti ve altı görsel her zaman 3+3 diziliyordu.
  ///
  /// Blok, seçili görsellerin EN ÜSTTEKİNİN hizasından başlar: kullanıcı
  /// düzenlediği yeri kaybetmesin.
  void _fitRow(int perRow) {
    final chosen = _multiSelected;
    final cw = _cw;
    if (chosen.length < 2 || cw <= 0) return;
    var top = double.infinity;
    for (final img in chosen) {
      final t = _resolve(img, cw).top;
      if (t < top) top = t;
    }
    if (!top.isFinite) top = widget.topLimit + kImageGap;
    final fits = fitRowsLayout(
      aspects: [for (final a in chosen) _aspectOf(a)],
      columnWidth: cw,
      top: math.max(top, widget.topLimit),
      minWidthFrac: _minWidthFrac,
      // Satır başına en çok 6: 1/7 genişlik [_minWidthFrac]'ın altına düşer
      // ve tuval genişliği yukarı kırparken görseller birbirine binerdi.
      maxPerRow: perRow.clamp(1, chosen.length).clamp(1, 6),
    );
    _applyMany([
      for (var i = 0; i < chosen.length && i < fits.length; i++)
        chosen[i].copyWith(
          displayWidth: fits[i].widthFrac,
          x: fits[i].leftFrac,
          pageY: fits[i].top,
        ),
    ]);
    _endMulti();
  }

  /// Büyük önizlemede duran görselin kimliği (null = kapalı).
  ///
  /// Önizleme SAYFA DÜZENİNE dokunmaz: görselin `displayWidth`/konumu
  /// değişmez, dolayısıyla metnin sarması da değişmez. Yalnızca üstte,
  /// geçici bir katmanda büyük çizilir.
  String? _previewId;

  /// Önizlemedeki yatay kaydırma denetleyicisi (kullanıcı isteği 2026-09-05:
  /// "birden fazla görsel olduğunda tam ekran ve ön izlemede kaydırarak
  /// diğer görsele geçme olsun"). Yalnız önizleme AÇIKKEN yaşar.
  PageController? _previewPages;

  void _togglePreview(String id) {
    if (_previewId == id) {
      _closePreview();
      return;
    }
    final index = widget.images.indexWhere((a) => a.id == id);
    _previewPages?.dispose();
    _previewPages = PageController(initialPage: index < 0 ? 0 : index);
    setState(() => _previewId = id);
  }

  void _closePreview() {
    if (_previewId == null) return;
    _previewPages?.dispose();
    _previewPages = null;
    setState(() => _previewId = null);
  }

  @override
  void dispose() {
    _previewPages?.dispose();
    super.dispose();
  }

  Attachment? _previewOf(List<Attachment> images) {
    final id = _previewId;
    if (id == null) return null;
    for (final img in images) {
      if (img.id == id) return img;
    }
    return null;
  }

  /// Görselin en-boy oranı (bilinmiyorsa kare sayılır).
  ///
  /// PDF kutusunda GÖRÜNTÜ döndürmesi de hesaba katılır: 90°/270°'de sayfa
  /// yan yatar, kutu da onunla birlikte yatmalı (bkz. [pdfBoxAspect]).
  double _aspectOf(Attachment img) {
    if (img.width == null ||
        img.height == null ||
        img.width! <= 0 ||
        img.height! <= 0) {
      return 1.0;
    }
    if (img.kind == AttachmentKind.pdf) {
      return pdfBoxAspect(
        img.width!.toDouble(),
        img.height!.toDouble(),
        img.pdfTurns,
      );
    }
    return img.width! / img.height!;
  }

  /// Genişliği yazılmamış görselin varsayılan genişlik oranı.
  ///
  /// Tek görsel sütunun yarısını kaplar. Nota İKİNCİ görsel girdiği anda
  /// varsayılan bir tık daralır: iki görsel araya boşluk da girerek AYNI
  /// SATIRA sığsın (bkz. [packSlot]). 0,5 + 0,5 satıra sığmadığı için ikinci
  /// görsel her seferinde alta iniyordu. BEŞ ve üzeri görselde satıra üç
  /// tane sığar: paylaşımdan gelen bir demet fotoğraf (konum/genişlik
  /// yazılmadan gelirler) düzgün bir ızgaraya otursun.
  double _defaultWFrac(double cw) {
    final count = widget.images.length;
    if (count < 2 || cw <= 0) return 0.5;
    final perRow = count >= 5 ? 3 : 2;
    return (((cw - kImageGap * (perRow - 1)) / perRow) / cw)
        .clamp(_minWidthFrac, 1.0)
        .toDouble();
  }

  /// Görselin sayfadaki ölçüsü (dp) — canlı boyutlandırma değeri öncelikli.
  ({double w, double h}) _sizeOf(Attachment img, double cw) {
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? _defaultWFrac(cw)))
            .clamp(_minWidthFrac, 1.0)
            .toDouble();
    final w = cw * wFrac;
    return (w: w, h: w / _aspectOf(img));
  }

  /// Konumu YAZILMAMIŞ görselin (paylaşımdan gelen, sayfa ölçülmeden eklenen,
  /// eski kayıt) sayfadaki otomatik yeri — kare başına BİR kez hesaplanır.
  ///
  /// KÖK NEDEN (kullanıcı 2026-08-16: "3 resim gönderdim 2'si geldi ve üst
  /// üste geldiler"; yine 2026-09-05: "birden fazla görsel eklendiğinde üst
  /// üste başlıyor"): burada gerçek yüksekliklerle bir DİKEY yığın kuruluyordu
  /// ama sonuç [NotePageCanvas.topLimit]'e kırpılıyordu — başlığın altına
  /// düşen bütün görseller aynı çizgiye çöküyor, yani üst üste biniyordu.
  /// Üstelik yığın hep alta indiği için satırın sağındaki koca boşluk hiç
  /// kullanılmıyordu.
  ///
  /// Artık yerleşim [packSlot] ile yapılır: görsel önce SATIRDA yan yana yer
  /// arar, sığmazsa alta iner ve kullanıcının elle yerleştirdiği görsellerin
  /// üstüne de binmez.
  void _computeAutoSlots(double cw) {
    _cw = cw;
    _autoSlots.clear();
    if (cw <= 0) return;
    final occupied = <Rect>[];
    // Önce kullanıcının yerleştirdiği görseller: otomatik yerleşim onlara
    // çarpmadan boşluk arar.
    for (final img in widget.images) {
      if (_isAuto(img)) continue;
      final r = _resolve(img, cw);
      occupied.add(Rect.fromLTWH(r.left, r.top, r.w, r.h));
    }
    for (final img in widget.images) {
      if (!_isAuto(img)) continue;
      final size = _sizeOf(img, cw);
      final slot = packSlot(
        occupied: occupied,
        columnWidth: cw,
        width: size.w,
        height: size.h,
        anchorTop: widget.topLimit + kImageGap,
        topLimit: widget.topLimit,
      );
      _autoSlots[img.id] = slot;
      occupied.add(Rect.fromLTWH(slot.left, slot.top, size.w, size.h));
    }
  }

  /// Konumu hiç yazılmamış görsel mi (yeri otomatik hesaplanır).
  bool _isAuto(Attachment img) => img.pageY == null && img.y == null;

  /// Görselin sayfadaki nihai yerleşimi (dp). Canlı taşıma/boyutlandırma
  /// değerleri öncelikli. Üst sınır 0'a kırpılır; alt sınır yok — sayfa uzar.
  ({double left, double top, double w, double h}) _resolve(
    Attachment img,
    double cw,
  ) {
    final size = _sizeOf(img, cw);
    final w = size.w;
    final auto = _autoSlots[img.id];
    var left = (_moveId == img.id && _moveLeft != null)
        ? _moveLeft!
        : (auto?.left ?? (img.x ?? 0.06) * cw);
    var top = (_moveId == img.id && _moveTop != null)
        ? _moveTop!
        : (auto?.top ??
              img.pageY ??
              (img.y != null
                  ? img.y! * kLegacyCanvasHeight
                  : widget.topLimit + kImageGap));
    left = left.clamp(0.0, (cw - w).clamp(0.0, cw)).toDouble();
    // Başlık/çip bölgesi görsele kapalı: üst sınırın altına inemez.
    if (top < widget.topLimit) top = widget.topLimit;
    return (left: left, top: top, w: w, h: size.h);
  }

  /// [img] DIŞINDAKİ görsellerin sayfa kutuları — yapışma, çarpışma ve
  /// kılavuzlar bunlara göre hesaplanır.
  List<Rect> _othersOf(Attachment img, double cw) {
    final out = <Rect>[];
    for (final other in widget.images) {
      if (other.id == img.id) continue;
      final r = _resolve(other, cw);
      out.add(Rect.fromLTWH(r.left, r.top, r.w, r.h));
    }
    return out;
  }

  /// Görsellerin SAYFA uzayındaki dışlama bantları. Metin alanları kendi
  /// konumlarını ölçüp bunları kendi uzaylarına çevirir (bkz.
  /// [WrapFieldMeasure]). Metnin görsele değmemesi için yatayda 12, dikeyde
  /// 8 dp pay bırakılır.
  List<FloatBox> _floatsFor(double cw) {
    final boxes = <FloatBox>[];
    for (final img in widget.images) {
      final r = _resolve(img, cw);
      boxes.add(
        FloatBox(
          top: r.top,
          left: r.left - 12,
          right: r.left + r.w + 12,
          height: r.h + 8,
        ),
      );
    }
    return boxes;
  }

  /// İpucunun SAYFA uzayındaki yeri.
  ///
  /// Hesap METİN SÜTUNU uzayında yapılır (bantlar sola/sağa kenar boşluğu
  /// kadar kaydırılır, sütun genişliği iki kenar boşluğu düşülerek verilir) —
  /// sarma planı da tam olarak bu uzayda çalışıyor (bkz. WrapFieldMeasure).
  /// İki hesap ayrı uzaylarda yapılırsa ipucu ile imleç ayrı yerlere düşer.
  ({double top, double left}) _hintPlacement(double cw) {
    final inset = widget.textLeft;
    final place = hintPlacement(
      [
        for (final f in _floatsFor(cw))
          FloatBox(
            top: f.top,
            left: f.left - inset,
            right: f.right - inset,
            height: f.height,
          ),
      ],
      // METİN uzayı: ipucu, alanın kutusuna değil ilk satırın tepesine oturur.
      widget.topLimit + widget.textTop,
      widget.hintLineHeight,
      (cw - inset * 2).clamp(0.0, cw),
      // Okunur genişlik tabanı yazı ölçeğiyle büyüyor; sarma planı da AYNI
      // ölçeği kullanıyor (bkz. WrapFieldMeasure), yoksa büyük yazıda ipucu
      // ile metin yine ayrışır.
      textScaleFactor: MediaQuery.textScalerOf(context).scale(1),
    );
    return (top: place.top, left: inset + place.left);
  }

  void _reportFloats(double cw) {
    final cb = widget.onFloats;
    if (cb == null) return;
    final next = _floatsFor(cw);
    if (_lastFloats != null && sameFloatList(_lastFloats!, next)) return;
    _lastFloats = next;
    // Ölçüm build sırasında yapılır; bildirimi kare sonuna erteleriz ki
    // gövde denetleyicisi build içinde setState tetiklemesin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb(next);
    });
  }

  List<FloatBox>? _lastFloats;

  void _openViewer(Attachment img) {
    if (img.kind == AttachmentKind.pdf) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfViewerScreen(
            attachment: img,
            initialPage: img.pdfPage,
            onPageChanged: (p) =>
                widget.onChanged(img.copyWith(pdfPage: p)),
            onChanged: widget.onChanged,
          ),
        ),
      );
      return;
    }
    if (img.kind == AttachmentKind.video) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoViewerScreen(attachment: img),
        ),
      );
      return;
    }
    openImageViewer(
      context,
      img,
      widget.onChanged,
      onCrop: widget.onCrop,
      onRotate: widget.onRotate,
      gallery: widget.images,
    );
  }

  /// Ekin türüne göre sayfa kutusu içeriği: görsele [_ImageBox], videoya
  /// yerinde oynayan [_VideoBox]. Videonun doğal boyutu ekte yoksa ilk
  /// çözümde kalıcılaştırılır (oran 1:1 varsayılanında kalmasın).
  Widget _boxFor(Attachment a, {BoxFit fit = BoxFit.cover}) {
    // SAYFAYA GÖMÜLÜ PDF: görselin kutusunun belge karşılığı — sayfası
    // çevrilebilir, yer imi konur, tam ekrana geçer (bkz. [PdfPageBox]).
    if (a.kind == AttachmentKind.pdf) {
      return PdfPageBox(
        attachment: a,
        onChanged: widget.onChanged,
        // Büyük önizlemede de sayfa çevrilebilir (önizleme okumak için
        // açılıyor) ama YATAY KAYDIRMA orada nottaki diğer eke geçiyor;
        // sayfa yalnız çubuğun oklarıyla değişir.
        swipeToTurn: fit == BoxFit.cover,
        onDetach: widget.onDetach == null
            ? null
            : () {
                _deselect();
                widget.onDetach!(a);
              },
      );
    }
    return NoteMediaBox(
      attachment: a,
      fit: fit,
      inlineWebVideo: true,
      showWebTitle: fit == BoxFit.contain || _selectedId == a.id,
      webPlaying: _playingWeb.contains(a.id),
      onWebPlay: () => setState(() => _playingWeb.add(a.id)),
      onSize: (a.width == null || a.height == null)
          ? (s) => widget.onChanged(
              a.copyWith(width: s.width.round(), height: s.height.round()),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      // Son görsel silinince bantların BOŞALDIĞI da bildirilmeli — yoksa
      // metin, artık var olmayan bir görselin etrafından akmaya devam eder.
      _reportFloats(0);
      // Görsel yokken katmanın görsel maliyeti olmasın; dokun-odaklan kalır.
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTapEmpty,
        child: PageMinHeight(minHeight: widget.minHeight, child: widget.child),
      );
    }
    // Geri tuşu önce ÖNİZLEMEYİ, sonra görsel seçimini kapatır; not ancak
    // ikisi de kapalıyken kapanır (madde: "geri butonu direk anasayfaya
    // dönmesin bu tür durumlarda").
    return PopScope(
      canPop: _previewId == null && _selectedId == null && !_multiMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_previewId != null) {
          _closePreview();
        } else if (_multiMode) {
          _endMulti();
        } else {
          _deselect();
        }
      },
      child: OverlayPortal(
        controller: _multiBar,
        overlayChildBuilder: _multiToolbar,
        child: LayoutBuilder(
        builder: (context, constraints) {
          final cw = constraints.maxWidth;
          // Otomatik yerleşim bu karede BİR kez kurulur; aşağıdaki bütün
          // _resolve çağrıları aynı sonucu okur.
          _computeAutoSlots(cw);
          _reportFloats(cw);
          // Sayfa en alttaki görseli (+ araç çubuğu payı) kapsayacak kadar uzar.
          var maxBottom = 0.0;
          for (final img in widget.images) {
            final r = _resolve(img, cw);
            final bottom = r.top + r.h + 72;
            if (bottom > maxBottom) maxBottom = bottom;
          }
          final selected = _selectedId;
          Attachment? selectedImg;
          for (final img in widget.images) {
            if (img.id == selected) selectedImg = img;
          }
          final previewImg = _previewOf(widget.images);
          // Görsel araç paneli, görselin/panelin DIŞINA düşen her dokunuşta
          // kapanır. Alttaki GestureDetector yalnız "boş alan" dokunuşlarını
          // görüyordu: metin alanına dokunmak alanın kendisine gittiğinden
          // panel açık kalıyordu ("resmin üzerine tıklanmayınca panel
          // kapanmıyor"). Listener jestleri YUTMAZ — dokunuş hem paneli
          // kapatır hem hedefine (ör. metin alanına odak) gider.
          final imgForDismiss = selectedImg;
          final content = Stack(
            clipBehavior: Clip.none,
            children: [
              // İçerik: boş alana dokununca önce seçim kalkar, seçim yoksa
              // gövdeye odaklanılır (dokunuş metin alanına da düşer).
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_selectedId != null) {
                    _deselect();
                  } else {
                    widget.onTapEmpty?.call();
                  }
                },
                child: PageMinHeight(
                  minHeight: maxBottom > widget.minHeight
                      ? maxBottom
                      : widget.minHeight,
                  child: widget.child,
                ),
              ),
              // İpucu görsellerin ALTINDA çizilir: zaten kesişmeyecek yere
              // konuyor, dokunuşu da yutmamalı (boş alana dokun → gövdeye odak).
              if (widget.hint != null)
                Builder(
                  builder: (context) {
                    // İpucu metnin ilk satırıyla AYNI yere oturur: görselin
                    // yanında yer varsa yanına, yoksa altına (bkz.
                    // [hintPlacement]).
                    final place = _hintPlacement(cw);
                    return PositionedDirectional(
                      start: place.left,
                      end: widget.textLeft,
                      top: place.top,
                      child: IgnorePointer(child: widget.hint!),
                    );
                  },
                ),
              for (final img in widget.images) _positioned(context, img, cw),
              // YERİNDE OYNAYAN YouTube'un "durdur" düğmesi kutunun SOL ÜST
              // köşesinin DIŞINDA (oynatıcının kendi düğmelerini örtmesin);
              // tuvalin kendi katmanında ki dokunuş kutunun sınırına takılmasın.
              for (final img in widget.images)
                if (_playingWeb.contains(img.id))
                  Builder(
                    builder: (context) {
                      final r = _resolve(img, cw);
                      return Positioned(
                        left: r.left - 14,
                        top: r.top - 14,
                        child: Material(
                          color: Theme.of(context).colorScheme.inverseSurface,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                setState(() => _playingWeb.remove(img.id)),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onInverseSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              // Hizalama kılavuzları görsellerin ÜSTÜNDE: taşınan görsel
              // çizgiyi kapatırsa hizalama görünmez olurdu.
              if (_guides.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _GuidePainter(
                        guides: _guides,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              if (selectedImg != null) _toolbar(context, selectedImg, cw),
              // Büyük önizleme en üstte: sayfa ölçüleriyle oynamadığı için
              // metnin sarması olduğu gibi kalır.
              if (previewImg != null) _preview(context, previewImg, cw),
            ],
          );
          // Listener HER ZAMAN ağaçta (seçim yokken boş geçer).
          //
          // KÖK NEDEN (2026-10-11, "görseli sürükleyerek üste sabitle"
          // üzerinde çalışırken bulundu): Listener eskiden yalnız seçim
          // VARKEN sarılıyordu. Seçili olmayan görsele basılı tutunca
          // `onLongPressStart` seçimi açıyor → içerik bu karede Listener'a
          // sarılıyor → Stack'in altındaki bütün ağaç (görselin jest
          // tanıyıcısı dahil) yeniden kuruluyor ve süren sürükleme kopuyordu:
          // "basılı tut, sürükle" ancak görsel ÖNCEDEN seçiliyse çalışıyordu.
          Rect? imageRect;
          Rect? toolbarRect;
          if (imgForDismiss != null) {
            final r = _resolve(imgForDismiss, cw);
            // Tutamaklar köşelerden taşar, panel görselin altında tam genişlik
            // bir bant: ikisinin de dışı "dışarısı" sayılır.
            imageRect = Rect.fromLTWH(r.left - 24, r.top - 24, r.w + 48, r.h + 48);
            toolbarRect = Rect.fromLTWH(0, r.top + r.h + 6, cw, 64);
          }
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (imageRect == null || toolbarRect == null) return;
              final p = event.localPosition;
              if (!imageRect.contains(p) && !toolbarRect.contains(p)) {
                _deselect();
              }
            },
            child: content,
          );
        },
        ),
      ),
    );
  }

  /// Çoklu seçim işlem çubuğu — ekranın dibinde, kaydırmadan bağımsız.
  Widget _multiToolbar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;
    final chosen = _multiSelected;
    return Positioned(
      left: 8,
      right: 8,
      // Klavye yüksekliği gezinme çubuğunu ZATEN içeriyor: ikisini toplamak
      // klavye açıkken çubuğu klavyeden ~48 dp yukarıda asılı bırakıyordu.
      bottom: 8 + (keyboard > systemBar ? keyboard : systemBar),
      child: Material(
        color: scheme.primaryContainer,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.cancel,
                visualDensity: _kBarDensity,
                icon: const Icon(Icons.close, size: 20),
                onPressed: _endMulti,
              ),
              Expanded(
                child: Text(
                  l10n.imagesSelectedCount(chosen.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: l10n.selectAllItems,
                visualDensity: _kBarDensity,
                icon: const Icon(Icons.select_all, size: 20),
                onPressed: () => setState(
                  () => _multi
                    ..clear()
                    ..addAll(widget.images.map((i) => i.id)),
                ),
              ),
              IconButton(
                tooltip: l10n.imagesEqualizeSize,
                visualDensity: _kBarDensity,
                icon: const Icon(Icons.straighten, size: 20),
                onPressed: chosen.length < 2 ? null : _equalizeSizes,
              ),
              // Sığdırma SÜTUN SAYISINI sorar: aynı altı görsel kimi zaman
              // 3+3, kimi zaman 2+2+2 isteniyor.
              PopupMenuButton<int>(
                tooltip: l10n.imagesFitRow,
                enabled: chosen.length >= 2,
                icon: const Icon(Icons.view_column_outlined, size: 20),
                onSelected: _fitRow,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 2,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.view_agenda_outlined),
                      title: Text(l10n.imagesFitColumns(2)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 3,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.view_column_outlined),
                      title: Text(l10n.imagesFitColumns(3)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 4,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.view_module_outlined),
                      title: Text(l10n.imagesFitColumns(4)),
                    ),
                  ),
                  // Hepsi TEK satıra: seçim kaç taneyse o kadar sütun.
                  PopupMenuItem(
                    value: 99,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.table_rows_outlined),
                      title: Text(l10n.imagesFitSingleRow),
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: l10n.copy,
                visualDensity: _kBarDensity,
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: chosen.isEmpty
                    ? null
                    : () {
                        widget.onCopyMany?.call(chosen);
                        _endMulti();
                      },
              ),
              IconButton(
                tooltip: l10n.delete,
                visualDensity: _kBarDensity,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: chosen.isEmpty
                    ? null
                    : () {
                        for (final img in chosen) {
                          widget.onRemove(img);
                        }
                        _endMulti();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Görseli sayfanın üzerinde BÜYÜK gösteren geçici katman. Boyut/konum
  /// değiştirmez; herhangi bir yere dokunmak kapatır.
  Widget _preview(BuildContext context, Attachment img, double cw) {
    final scheme = Theme.of(context).colorScheme;
    final aspect =
        (img.width != null &&
            img.height != null &&
            img.width! > 0 &&
            img.height! > 0)
        ? img.width! / img.height!
        : 1.0;
    // Görünür alanın içinde kal: hem genişlik hem yükseklik sınırlanır ki
    // uzun görseller taşmasın.
    final maxW = cw - 16;
    final maxH = widget.minHeight - 32;
    var w = maxW;
    var h = w / aspect;
    if (h > maxH && maxH > 0) {
      h = maxH;
      w = h * aspect;
    }
    // KAPATMA ALANI SAYFANIN TAMAMI (kullanıcı bulgusu 2026-08-10: "görseli
    // ön izlemede açıkça üst ve yanlarına tıklayınca kapanıyor ama altına
    // tıklayınca kapanmıyor"): kutu `Positioned(top: …)` idi ve alt sınırı
    // olmadığı için yalnız GÖRSELİN KENDİ BANDI kadar yer kaplıyordu — o
    // bandın altına düşen dokunuş önizlemeye hiç ulaşmıyor, altındaki sayfaya
    // (metin alanına/boşluğa) gidiyordu. `Positioned.fill` ile katman sayfanın
    // tamamını kapsar: neresine dokunulursa dokunulsun önizleme kapanır ve
    // dokunuş sayfaya SIZMAZ (opaque).
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _closePreview,
        // İç Stack: kart yine yalnız YUKARIDAN konumlanır (alt sınırı yok),
        // yani yüksekliği eskisi gibi serbest kalır — `Padding` kullanılsaydı
        // uzun görselde kalan yer daralıp taşma verirdi.
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              // Önizleme, sayfanın görünen kısmına yakın dursun diye üst sınır
              // görselin bandına göre verilir.
              top: (widget.topLimit + 8).clamp(0.0, double.infinity),
              child: Center(
                child: Material(
                  elevation: 8,
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      children: [
                        // Yana kaydırınca nottaki diğer göresele geçilir;
                        // kutu boyutu geçilen görselin oranına göre yenilenir.
                        Positioned.fill(
                          child: widget.images.length < 2
                              ? _boxFor(img, fit: BoxFit.contain)
                              : PageView.builder(
                                  controller: _previewPages,
                                  itemCount: widget.images.length,
                                  onPageChanged: (i) => setState(
                                    () => _previewId = widget.images[i].id,
                                  ),
                                  itemBuilder: (context, i) => _boxFor(
                                    widget.images[i],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton(
                            tooltip: context.l10n.close,
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                            onPressed: _closePreview,
                          ),
                        ),
                        // Kaçıncı görselde olduğumuz: kaydırmanın bir sonu
                        // olduğu görünsün.
                        if (widget.images.length > 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 6,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    '${widget.images.indexWhere((a) => a.id == img.id) + 1}'
                                    '/${widget.images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positioned(BuildContext context, Attachment img, double cw) {
    final scheme = Theme.of(context).colorScheme;
    final editing = _selectedId == img.id;
    final checked = _multiMode && _multi.contains(img.id);
    final moving = _moveId == img.id;
    final r = _resolve(img, cw);
    return Positioned(
      // Anahtar ölçüm içindir: yerleşim testleri kutunun ekrandaki dikdörtgenini
      // bu anahtarla okur (bkz. test/note_canvas_layout_test.dart).
      key: ValueKey('page-image-${img.id}'),
      left: r.left,
      top: r.top,
      width: r.w,
      height: r.h,
      child: GestureDetector(
        onTap: () =>
            _multiMode ? _toggleMulti(img.id) : _select(img.id),
        // ÇİFT DOKUNUŞ = büyük önizleme, ama YALNIZ görsel SEÇİLİYKEN.
        //
        // KÖK NEDEN (kullanıcı 2026-09-05: "görselleri seçerken gecikme
        // var"): çift dokunuş tanıyıcısı kayıtlıyken tek dokunuşun kararı
        // ikinci dokunuş penceresi (~300 ms) dolmadan VERİLEMEZ — her seçim,
        // her işaretleme o kadar bekliyordu. Tanıyıcı artık yalnız seçili
        // görselde kurulur: seçme ve çoklu seçimde işaretleme ANINDA olur,
        // önizleme de seçtikten sonra çift dokunuşla (ya da her zaman olduğu
        // gibi sağ-alt köşedeki tutamağa dokunarak) hâlâ açılır.
        onDoubleTap: editing && !_multiMode
            ? () => _togglePreview(img.id)
            : null,
        // Taşıma TEK jestte: basılı tut, parmağını kaldırmadan sürükle.
        // (Önce seçip sonra sürüklemek gerekiyordu — kullanımı zordu.)
        // Uzun basma dikey kaydırmayla çakışmaz: sayfa kaydırma anlık
        // sürüklemeyle başlar, taşıma ise basılı tutmayı bekler.
        onLongPressStart: (d) {
          // Çoklu seçim açıkken taşıma kapalı: parmak işaretlemek için
          // geziyor, kazara görsel sürüklenmesin.
          if (_multiMode) {
            _toggleMulti(img.id);
            return;
          }
          HapticFeedback.selectionClick();
          setState(() {
            _selectedId = img.id;
            _moveId = img.id;
            // Sürükleme başlangıcı ayrı tutulur: _resolve taşıma sırasında
            // canlı değeri döndürdüğü için onu baz almak kaymayı katlardı.
            _moveOriginLeft = r.left;
            _moveOriginTop = r.top;
            _moveLeft = r.left;
            _moveTop = r.top;
          });
        },
        // KENAR ÇARPIŞMASI + KILAVUZ (kullanıcı isteği 2026-09-05): parmağın
        // istediği ham kutu [snapMove]'a verilir; kenarlar sayfaya ve komşulara
        // yapışır, hafif temasta çarpışıp durur, parmak komşunun derinine
        // girmeye devam ederse engel kalkar. Ham konum SAKLANMAZ, her karede
        // sürüklemenin başlangıcından yeniden hesaplanır: yapışmış değer geri
        // beslenseydi görsel kılavuzdan kopamazdı.
        onLongPressMoveUpdate: (d) {
          if (_moveId != img.id) return;
          _setPinZone(
            _pinZoneHit(
              d.globalPosition,
              rawTop: (_moveOriginTop ?? r.top) + d.offsetFromOrigin.dy,
            ),
          );
          final snapped = snapMove(
            rect: Rect.fromLTWH(
              (_moveOriginLeft ?? r.left) + d.offsetFromOrigin.dx,
              (_moveOriginTop ?? r.top) + d.offsetFromOrigin.dy,
              r.w,
              r.h,
            ),
            others: _othersOf(img, cw),
            columnWidth: cw,
            topLimit: widget.topLimit,
          );
          if (_guides.isEmpty && snapped.guides.isNotEmpty) {
            HapticFeedback.selectionClick();
          }
          setState(() {
            _moveLeft = snapped.left;
            _moveTop = snapped.top;
            _guides = snapped.guides;
          });
        },
        onLongPressEnd: (_) => _commitMove(img, cw),
        onLongPressCancel: () {
          // İptal (ör. jest başka bir tanıyıcıya geçti) sabitleme SAYILMAZ.
          _setPinZone(false);
          _commitMove(img, cw);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: editing || checked
                      ? Border.all(color: scheme.primary, width: 2)
                      : Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                ),
                // RepaintBoundary: görsel kendi katmanına çizilir. Sayfada
                // yazarken/kaydırırken imleç ve satırlar sık sık yeniden
                // çiziliyor; sınır olmadan her seferinde görselin rasterı da
                // yeniden çiziliyordu (birkaç görselli notta kare bütçesinin
                // görünür bir dilimi).
                // SÜRÜKLERKEN YARI SAYDAM (kullanıcı bulgusu 2026-08-10: "notu
                // sürüklediğinde metin notu resmin altında kalıyor"): görseller
                // metnin ÜSTÜNE çizilir, metin de onların etrafından akar —
                // ama akış ancak yeni bantlar ölçülüp uygulandıktan sonra
                // yerine oturur (ölçüm kare sonunda yapılır). Parmak hızlıysa
                // görsel arada metnin üstünde duruyor ve altındaki satırlar
                // tümüyle kayboluyordu. Saydamlık yalnız TAŞIMA sürerken: metin
                // her an okunur kalır, bırakınca görsel tam opak olur ve sarma
                // zaten kesin konuma göre hesaplanmıştır.
                child: Opacity(
                  opacity: moving ? 0.55 : 1,
                  child: RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _boxFor(img),
                    ),
                  ),
                ),
              ),
            ),
            // Çoklu seçim rozeti: işaretliyse dolu tik, değilse boş halka.
            if (_multiMode)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: checked ? scheme.primary : Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: checked
                      ? Icon(Icons.check, size: 14, color: scheme.onPrimary)
                      : null,
                ),
              ),
            // Sağ-alt köşe tutamağı: serbest boyutlandırma (yalnız seçiliyken).
            if (editing && !_multiMode)
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  // Köşe tutamağı SÜRÜKLENİYOR ama dokunmak hiçbir şey
                  // yapmıyordu; küçültülmüş bir görseli okumak için ya tam
                  // ekrana gitmek ya da büyütüp sonra geri küçültmek
                  // gerekiyordu. Dokunuş artık BÜYÜK ÖNİZLEME açar: görsel
                  // sayfanın üstünde büyük çizilir, düzen (ve metnin akışı)
                  // hiç değişmez — kapanınca her şey yerli yerinde kalır.
                  onTap: () => _togglePreview(img.id),
                  onPanStart: (_) => setState(() {
                    _resizeId = img.id;
                    _resizeWFrac = (img.displayWidth ?? _defaultWFrac(cw))
                        .clamp(_minWidthFrac, 1.0)
                        .toDouble();
                    _resizeRawFrac = _resizeWFrac;
                  }),
                  // Boyutlandırırken de kılavuz çıkar: sağ kenar sayfanın
                  // kenarına/ortasına, komşunun kenarına ya da komşuyla EŞİT
                  // genişliğe yapışır.
                  onPanUpdate: (d) {
                    final base =
                        _resizeRawFrac ??
                        (img.displayWidth ?? _defaultWFrac(cw));
                    final raw = (base + d.delta.dx / cw)
                        .clamp(_minWidthFrac, 1.0)
                        .toDouble();
                    final snapped = snapWidth(
                      left: r.left,
                      width: raw * cw,
                      others: _othersOf(img, cw),
                      columnWidth: cw,
                    );
                    if (_guides.isEmpty && snapped.guides.isNotEmpty) {
                      HapticFeedback.selectionClick();
                    }
                    setState(() {
                      _resizeRawFrac = raw;
                      _resizeWFrac = (snapped.width / cw)
                          .clamp(_minWidthFrac, 1.0)
                          .toDouble();
                      _guides = snapped.guides;
                    });
                  },
                  onPanEnd: (_) {
                    final f = _resizeWFrac;
                    if (f != null) {
                      widget.onChanged(img.copyWith(displayWidth: f));
                    }
                    setState(() {
                      _resizeId = null;
                      _resizeWFrac = null;
                      _resizeRawFrac = null;
                      _guides = const [];
                    });
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.onPrimary, width: 2),
                    ),
                    child: Icon(
                      Icons.open_in_full,
                      size: 13,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Araç çubuğu seçili görselin hemen altında belirir (sayfa uzun olduğundan
  /// alta sabitlemek görünmez kalabilirdi).
  Widget _toolbar(BuildContext context, Attachment img, double cw) {
    final r = _resolve(img, cw);
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? _defaultWFrac(cw)))
            .clamp(_minWidthFrac, 1.0)
            .toDouble();
    // OCR ve pano kopyası görsele özgü; videoda ve PDF'te menüde gösterilmez
    // (taşı/boyutlandır/tam ekran/sil ve "Ek olarak taşı" ortak). PDF'in
    // metni kendi kutusundaki menüden sayfa sayfa alınır — dosyanın tamamını
    // OCR'a vermek yanlış araç olurdu (bkz. [PdfPageBox]).
    final isVideo = img.kind == AttachmentKind.video;
    final isPdf = img.kind == AttachmentKind.pdf;
    return Positioned(
      left: 8,
      right: 8,
      top: r.top + r.h + 6,
      child: _ImageTools(
        wFrac: wFrac,
        minWidthFrac: _minWidthFrac,
        onWidthChanged: (v) => setState(() {
          _resizeId = img.id;
          _resizeWFrac = v;
        }),
        onWidthEnd: (v) {
          widget.onChanged(img.copyWith(displayWidth: v));
          setState(() {
            _resizeId = null;
            _resizeWFrac = null;
          });
        },
        onExtractText: widget.onExtractText == null || isVideo || isPdf
            ? null
            : () => widget.onExtractText!(img),
        // YouTube ekinin kopyası BAĞLANTISIDIR (kullanıcı bulgusu
        // 2026-10-11: "videoların bağlantı adresi kopyalanmıyor" — menüde
        // video için kopyalama hiç yoktu).
        onCopy: widget.onCopy == null || (isVideo && !img.isWebVideo)
            ? null
            : () => widget.onCopy!(img),
        copyIsLink: img.isWebVideo,
        onOpenExternal: img.isWebVideo
            ? () => launchUrl(
                Uri.parse(img.webUrl),
                mode: LaunchMode.externalApplication,
              )
            : null,
        onSelectMany: widget.onCopyMany == null || widget.images.length < 2
            ? null
            : () => _startMulti(img.id),
        // YouTube ekinin dosyası yok — videodan not çıkarmak mümkün değil.
        onVideoToNote: widget.onVideoToNote == null || !isVideo || img.isWebVideo
            ? null
            : () => widget.onVideoToNote!(img),
        // PDF sabitlenmez: üst bölme görsel/video içindir.
        onPinTop: widget.onPinTop == null || isPdf
            ? null
            : () {
                _deselect();
                widget.onPinTop!(img);
              },
        onDetach: widget.onDetach == null
            ? null
            : () {
                _deselect();
                widget.onDetach!(img);
              },
        onFullscreen: () => _openViewer(img),
        onRemove: () => widget.onRemove(img),
      ),
    );
  }
}

/// Taşıma/boyutlandırma sırasında sayfa boyunca uzanan kesik hizalama
/// çizgileri (kullanıcı isteği 2026-09-05: "boyut ayarlarken kılavuz kenar
/// çizgileri çıksın ve diğer görselle ve sayfa ile hizalamak kolay olsun").
///
/// Çizgiler sayfanın TAMAMINI kateder: kullanıcı hangi kenarın tuttuğunu —
/// sayfanın kenarı mı, ortası mı, komşunun kenarı mı — tek bakışta görür.
class _GuidePainter extends CustomPainter {
  const _GuidePainter({required this.guides, required this.color});

  final List<AlignGuide> guides;
  final Color color;

  /// Kesik çizginin dolu ve boş parçaları (dp).
  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final g in guides) {
      final end = g.vertical ? size.height : size.width;
      for (var p = 0.0; p < end; p += _dash + _gap) {
        final q = math.min(p + _dash, end);
        canvas.drawLine(
          g.vertical ? Offset(g.pos, p) : Offset(p, g.pos),
          g.vertical ? Offset(g.pos, q) : Offset(q, g.pos),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) {
    if (old.color != color || old.guides.length != guides.length) return true;
    for (var i = 0; i < guides.length; i++) {
      if (old.guides[i] != guides[i]) return true;
    }
    return false;
  }
}
