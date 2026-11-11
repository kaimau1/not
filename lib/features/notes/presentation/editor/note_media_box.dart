part of 'note_images.dart';

// F18.23: sayfa medya kutuları note_images.dart'tan taşındı (davranış aynı).

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

/// Görsel ekin içeriği: yerel dosya → indirme adresi → yer tutucu sırasıyla.
/// Tam ekranda görselin üzerine yazılan çizim (ekin `ink` alanı) burada da
/// çizilir — yoksa çizim "kaybolmuş" görünürdü. Kutunun en-boy oranı görselin
/// oranıyla aynı tutulduğu için oranlı noktalar birebir oturur.
class _ImageBox extends StatelessWidget {
  const _ImageBox({
    required this.img,
    this.fit = BoxFit.cover,
    this.ink = true,
  });

  final Attachment img;

  /// false: çizimi çağıran boyar (sabit bölme — görselin `contain`
  /// dikdörtgeninde; burada kutunun TAMAMINA boyanır).
  final bool ink;

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
                padding: EdgeInsets.symmetric(horizontal: b.fill == 0 ? 0 : 2),
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
                    fontStyle: b.italic ? FontStyle.italic : FontStyle.normal,
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
    final ink = this.ink && img.ink.isNotEmpty;
    if (!ink && img.bubbles.isEmpty) return _content(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Positioned.fill(child: _content(context)),
            if (ink)
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
        // Web: Drive'daki görsel burada iner, aynı kutuda yeniden çizilir.
        if (kIsWeb && img.isInDrive) {
          return WebDriveGate(
            attachment: img,
            builder: (_, a) => Image.network(
              a.downloadUrl,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
            ),
          );
        }
        // Dosya bu cihazda yok, buluttan da gelmiyor: tek durum dili (F40.4).
        // Kutuya dokunuş kutunun (seçer); açıklama köşedeki rozette.
        final status = attachmentStatusOf(img, hasLocal: false);
        return Stack(
          fit: StackFit.expand,
          children: [
            AttachmentStatusPlaceholder(status: status, interactive: false),
            PositionedDirectional(
              start: 6,
              top: 6,
              child: AttachmentStatusBadge(status: status),
            ),
          ],
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
    this.noteAtButton = false,
    this.videoControls = true,
    this.imageInk = true,
  });

  /// Bkz. [_ImageBox.ink].
  final bool imageInk;

  final Attachment attachment;
  final BoxFit fit;
  final bool inlineWebVideo;

  /// Yerel videonun dibindeki denetim şeridi (bkz. [_VideoBox.controls]).
  final bool videoControls;

  /// Yerel videonun köşesinde "Bu ana not al" düğmesi (sayfa tuvali). Sabit
  /// bölmede kapalı — orada düğme bölmenin çubuğunda.
  final bool noteAtButton;

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
    // Ekran okuyucu (F15.2): kutu "tür: ad. açıklama" diye okunur; içindeki
    // oynat/durdur gibi denetimler kendi düğümleriyle kalır.
    final l10n = context.l10n;
    final name = a.fileName.trim();
    final kind = a.kind == AttachmentKind.video
        ? l10n.embedNewVideo
        : l10n.embedNewImage;
    final label = [
      name.isEmpty ? kind : l10n.mediaBoxSemantic(kind, name),
      if (a.caption.trim().isNotEmpty) a.caption.trim(),
    ].join('. ');
    return Semantics(
      container: true,
      image: a.kind == AttachmentKind.image,
      label: label,
      child: _box(a),
    );
  }

  Widget _box(Attachment a) {
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
      return _VideoBox(
        video: a,
        fit: fit,
        onSize: onSize,
        noteAtButton: noteAtButton,
        controls: videoControls,
      );
    }
    return _ImageBox(img: a, fit: fit, ink: imageInk);
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
