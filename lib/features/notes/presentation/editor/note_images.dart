import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../domain/attachment.dart';
import '../viewers/image_viewer.dart';
import '../viewers/ink_layer.dart';
import '../viewers/video_viewer.dart';
import 'text_wrap.dart';

/// Görseli tam ekran açar (yoksa "henüz senkronlanmadı" der). Tam ekranda
/// görselin üzerine elle yazılabilir; çizim [onChanged] ile ekin `ink`
/// alanına döner.
void openImageViewer(
  BuildContext context,
  Attachment img,
  ValueChanged<Attachment> onChanged, {
  Future<void> Function(Attachment, Rect)? onCrop,
  Future<void> Function(Attachment, int)? onRotate,
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

  @override
  Widget build(BuildContext context) {
    if (img.ink.isEmpty) return _content(context);
    return Stack(
      children: [
        Positioned.fill(child: _content(context)),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: InkPainter(img.ink, 1)),
          ),
        ),
      ],
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
          return CachedNetworkImage(
            imageUrl: img.downloadUrl,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: targetWidth,
          );
        }
        return Container(
          color: scheme.surfaceContainerHigh,
          alignment: Alignment.center,
          child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
        );
      },
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
                onVideoToNote != null)
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
                  }
                },
                itemBuilder: (context) => [
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
                  if (onCopy != null)
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
    if (f.top < y + lineHeight && y < f.bottom) y = f.bottom;
  }
  return y;
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
    this.onDetach,
    this.onVideoToNote,
    this.onTapEmpty,
    this.topLimit = 0,
    this.onFloats,
    this.hint,
    this.hintLineHeight = 0,
  });

  final List<Attachment> images;

  /// Sayfa içeriği (başlık, çipler, gövde metni). Görseller bunun üstünde.
  final Widget child;

  /// Görsellerin inebileceği en üst nokta (dp) — başlık ve çip satırının
  /// altı. Görsel başlığın üzerine hiç çıkamaz. Gövde metninin ilk satırının
  /// tepesi de burasıdır ([hint] bu noktadan aşağı itilir).
  final double topLimit;

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

  /// Tam ekranda seçilen kırpma alanını uygular (bkz. [ImageViewerScreen]).
  final Future<void> Function(Attachment, Rect)? onCrop;

  /// Görseli 90°'nin katıyla döndürüp KALICI olarak yeniden yazacak taraf
  /// ([onCrop] ile aynı gerekçe: dosyayı yeniden yazmak ek deposu ve not
  /// kimliği ister, ikisi de bu katmanda yok). null ise döndürme düğmesi
  /// çizilmez.
  final Future<void> Function(Attachment, int)? onRotate;
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

  /// Sürükleme bitince yeni konumu kaydeder ve canlı değerleri temizler.
  void _commitMove(Attachment img, double cw) {
    if (_moveId != img.id) return;
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
    });
  }

  /// Boyutlandırma sırasındaki canlı genişlik oranı; bırakınca kaydedilir.
  String? _resizeId;
  double? _resizeWFrac;

  static const double _minWidthFrac = 0.15;

  /// Eski küçük tuvalden gelen y oranını (0–1) dp'ye çevirirken kullanılan
  /// varsayılan tuval yüksekliği (eski tuvalin üst sınırı).
  static const double _legacyCanvasHeight = 440;

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

  /// Büyük önizlemede duran görselin kimliği (null = kapalı).
  ///
  /// Önizleme SAYFA DÜZENİNE dokunmaz: görselin `displayWidth`/konumu
  /// değişmez, dolayısıyla metnin sarması da değişmez. Yalnızca üstte,
  /// geçici bir katmanda büyük çizilir.
  String? _previewId;

  void _togglePreview(String id) =>
      setState(() => _previewId = _previewId == id ? null : id);

  void _closePreview() {
    if (_previewId != null) setState(() => _previewId = null);
  }

  Attachment? _previewOf(List<Attachment> images) {
    final id = _previewId;
    if (id == null) return null;
    for (final img in images) {
      if (img.id == id) return img;
    }
    return null;
  }

  /// Konumu YAZILMAMIŞ görsellerin (paylaşımdan gelen, eski kayıt) sayfadaki
  /// otomatik yeri.
  ///
  /// KÖK NEDEN (kullanıcı 2026-08-16: "3 resim gönderdim 2'si geldi ve üst
  /// üste geldiler"): burada eskiden `8 + index * 130` vardı — sabit 130 dp
  /// aralık. Ama görselin yüksekliği en boy oranından çıkıyor ve varsayılan
  /// genişlik sütunun yarısı: dikey bir fotoğraf ~240 dp geliyor, yani bir
  /// sonraki görsel öncekinin tam ortasına düşüyordu. İki görsel üst üste
  /// binince alttaki tümüyle görünmez oluyor, kullanıcı "gelmedi" sanıyordu.
  ///
  /// Artık yığın GERÇEK yüksekliklerle kuruluyor: konumu yazılı görseller
  /// yığına katılmaz (onlar kullanıcının koyduğu yerdedir), konumsuz olanlar
  /// sırayla bir öncekinin ALTINA iner.
  double _defaultTop(int index, double cw) {
    var cursor = 8.0;
    for (var i = 0; i < widget.images.length && i < index; i++) {
      final other = widget.images[i];
      // Kullanıcının yerleştirdiği görsel otomatik yığını kaydırmaz.
      if (other.pageY != null || other.y != null) continue;
      final aspect =
          (other.width != null &&
              other.height != null &&
              other.width! > 0 &&
              other.height! > 0)
          ? other.width! / other.height!
          : 1.0;
      final w = cw * (other.displayWidth ?? 0.5).clamp(_minWidthFrac, 1.0);
      cursor += w / aspect + 16;
    }
    return cursor;
  }

  /// Görselin sayfadaki nihai yerleşimi (dp). Canlı taşıma/boyutlandırma
  /// değerleri öncelikli. Üst sınır 0'a kırpılır; alt sınır yok — sayfa uzar.
  ({double left, double top, double w, double h}) _resolve(
    Attachment img,
    int index,
    double cw,
  ) {
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? 0.5))
            .clamp(_minWidthFrac, 1.0)
            .toDouble();
    final w = cw * wFrac;
    final aspect =
        (img.width != null &&
            img.height != null &&
            img.width! > 0 &&
            img.height! > 0)
        ? img.width! / img.height!
        : 1.0;
    final h = w / aspect;
    var left = (_moveId == img.id && _moveLeft != null)
        ? _moveLeft!
        : (img.x ?? 0.06) * cw;
    var top = (_moveId == img.id && _moveTop != null)
        ? _moveTop!
        : img.pageY ??
              (img.y != null
                  ? img.y! * _legacyCanvasHeight
                  : _defaultTop(index, cw));
    left = left.clamp(0.0, (cw - w).clamp(0.0, cw)).toDouble();
    // Başlık/çip bölgesi görsele kapalı: üst sınırın altına inemez.
    if (top < widget.topLimit) top = widget.topLimit;
    return (left: left, top: top, w: w, h: h);
  }

  /// Görsellerin SAYFA uzayındaki dışlama bantları. Metin alanları kendi
  /// konumlarını ölçüp bunları kendi uzaylarına çevirir (bkz.
  /// [WrapFieldMeasure]). Metnin görsele değmemesi için yatayda 12, dikeyde
  /// 8 dp pay bırakılır.
  List<FloatBox> _floatsFor(double cw) {
    final boxes = <FloatBox>[];
    for (final (index, img) in widget.images.indexed) {
      final r = _resolve(img, index, cw);
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

  double _hintTop(double cw) =>
      hintTopFor(_floatsFor(cw), widget.topLimit, widget.hintLineHeight);

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
    );
  }

  /// Ekin türüne göre sayfa kutusu içeriği: görsele [_ImageBox], videoya
  /// yerinde oynayan [_VideoBox]. Videonun doğal boyutu ekte yoksa ilk
  /// çözümde kalıcılaştırılır (oran 1:1 varsayılanında kalmasın).
  Widget _boxFor(Attachment a, {BoxFit fit = BoxFit.cover}) {
    if (a.kind == AttachmentKind.video) {
      return _VideoBox(
        video: a,
        fit: fit,
        onSize: (a.width == null || a.height == null)
            ? (s) => widget.onChanged(
                a.copyWith(width: s.width.round(), height: s.height.round()),
              )
            : null,
      );
    }
    return _ImageBox(img: a, fit: fit);
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
          _reportFloats(cw);
          // Sayfa en alttaki görseli (+ araç çubuğu payı) kapsayacak kadar uzar.
          var maxBottom = 0.0;
          for (final (index, img) in widget.images.indexed) {
            final r = _resolve(img, index, cw);
            final bottom = r.top + r.h + 72;
            if (bottom > maxBottom) maxBottom = bottom;
          }
          final selected = _selectedId;
          Attachment? selectedImg;
          var selectedIndex = 0;
          for (final (index, img) in widget.images.indexed) {
            if (img.id == selected) {
              selectedImg = img;
              selectedIndex = index;
            }
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
                Positioned(
                  left: 0,
                  right: 0,
                  top: _hintTop(cw),
                  child: IgnorePointer(child: widget.hint!),
                ),
              for (final (index, img) in widget.images.indexed)
                _positioned(context, img, index, cw),
              if (selectedImg != null)
                _toolbar(context, selectedImg, selectedIndex, cw),
              // Büyük önizleme en üstte: sayfa ölçüleriyle oynamadığı için
              // metnin sarması olduğu gibi kalır.
              if (previewImg != null) _preview(context, previewImg, cw),
            ],
          );
          if (imgForDismiss == null) return content;
          final r = _resolve(imgForDismiss, selectedIndex, cw);
          // Tutamaklar köşelerden taşar, panel görselin altında tam genişlik
          // bir bant: ikisinin de dışı "dışarısı" sayılır.
          final imageRect = Rect.fromLTWH(
            r.left - 24,
            r.top - 24,
            r.w + 48,
            r.h + 48,
          );
          final toolbarRect = Rect.fromLTWH(0, r.top + r.h + 6, cw, 64);
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
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
      bottom: 8 + keyboard + systemBar,
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
                icon: const Icon(Icons.select_all, size: 20),
                onPressed: () => setState(
                  () => _multi
                    ..clear()
                    ..addAll(widget.images.map((i) => i.id)),
                ),
              ),
              IconButton(
                tooltip: l10n.copy,
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
                        Positioned.fill(
                          child: _boxFor(img, fit: BoxFit.contain),
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

  Widget _positioned(
    BuildContext context,
    Attachment img,
    int index,
    double cw,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final editing = _selectedId == img.id;
    final checked = _multiMode && _multi.contains(img.id);
    final moving = _moveId == img.id;
    final r = _resolve(img, index, cw);
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.w,
      height: r.h,
      child: GestureDetector(
        onTap: () =>
            _multiMode ? _toggleMulti(img.id) : _select(img.id),
        // ÇİFT DOKUNUŞ = büyük önizleme (kullanıcı isteği). Aynı iş sağ-alt
        // köşedeki tutamağa dokunarak da yapılıyor ama o tutamak YALNIZ
        // görsel seçiliyken var: önizlemeye ulaşmak için önce seçmek, sonra
        // küçük bir köşeyi bulmak gerekiyordu. Çift dokunuş görselin her
        // yerinden, seçmeden çalışır.
        onDoubleTap: () => _togglePreview(img.id),
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
        onLongPressMoveUpdate: (d) {
          if (_moveId != img.id) return;
          setState(() {
            _moveLeft = ((_moveOriginLeft ?? r.left) + d.offsetFromOrigin.dx)
                .clamp(0.0, (cw - r.w).clamp(0.0, cw))
                .toDouble();
            final nt = (_moveOriginTop ?? r.top) + d.offsetFromOrigin.dy;
            _moveTop = nt < widget.topLimit ? widget.topLimit : nt;
          });
        },
        onLongPressEnd: (_) => _commitMove(img, cw),
        onLongPressCancel: () => _commitMove(img, cw),
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
                    _resizeWFrac = (img.displayWidth ?? 0.5)
                        .clamp(_minWidthFrac, 1.0)
                        .toDouble();
                  }),
                  onPanUpdate: (d) => setState(() {
                    final base = (_resizeWFrac ?? (img.displayWidth ?? 0.5));
                    _resizeWFrac = (base + d.delta.dx / cw)
                        .clamp(_minWidthFrac, 1.0)
                        .toDouble();
                  }),
                  onPanEnd: (_) {
                    final f = _resizeWFrac;
                    if (f != null) {
                      widget.onChanged(img.copyWith(displayWidth: f));
                    }
                    setState(() {
                      _resizeId = null;
                      _resizeWFrac = null;
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
  Widget _toolbar(BuildContext context, Attachment img, int index, double cw) {
    final r = _resolve(img, index, cw);
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? 0.5))
            .clamp(_minWidthFrac, 1.0)
            .toDouble();
    // OCR ve pano kopyası görsele özgü; videoda menüde gösterilmez
    // (taşı/boyutlandır/tam ekran/sil ve "Ek olarak taşı" ortak).
    final isVideo = img.kind == AttachmentKind.video;
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
        onExtractText: widget.onExtractText == null || isVideo
            ? null
            : () => widget.onExtractText!(img),
        onCopy: widget.onCopy == null || isVideo
            ? null
            : () => widget.onCopy!(img),
        onSelectMany: widget.onCopyMany == null || widget.images.length < 2
            ? null
            : () => _startMulti(img.id),
        onVideoToNote: widget.onVideoToNote == null || !isVideo
            ? null
            : () => widget.onVideoToNote!(img),
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
