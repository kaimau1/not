import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/local_file.dart';
import '../../data/scan/scan_ocr.dart';
import '../editor/note_images.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import 'bubble_layer.dart';
import 'area_actions.dart';
import 'area_select.dart';
import 'image_crop.dart';
import 'ink_layer.dart';
import 'text_recognize_screen.dart';
import 'zoom_math.dart';
import '../editor/attachment_clipboard.dart';

/// Tam ekran görsel görüntüleyici (yakınlaştırma/kaydırma destekli).
///
/// [onChanged] verilirse PDF/slaytta olduğu gibi görselin ÜZERİNE elle
/// yazılabilir: çizim görsel dosyasına gömülmez, ekin `ink` alanında görsel
/// oranlı (0–1) vektör olarak saklanır — notla birlikte senkronlanır, her
/// açılışta yeniden düzenlenebilir, silinebilir.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.attachment,
    this.gallery = const [],
    this.onChanged,
    this.onCrop,
    this.onRotate,
  });

  final Attachment attachment;

  /// Tam ekranda YANA KAYDIRARAK geçilebilecek görseller (kullanıcı isteği
  /// 2026-09-05: "birden fazla görsel olduğunda tam ekran ve ön izlemede
  /// kaydırarak diğer görsele geçme olsun"). Boşsa ya da [attachment] içinde
  /// yoksa tek görsel açılır ve kaydırma hiç kurulmaz.
  ///
  /// Sayfa geçişi yakınlaştırma/çizim/metin/alan seçimi sırasında KİLİTLENİR:
  /// üçü de yatay parmağı kendi işi için kullanıyor, yoksa kullanıcı çizerken
  /// kazara sonraki görsele atlardı.
  final List<Attachment> gallery;

  /// null ise salt görüntüleme (ör. dışa aktarma önizlemesi): çizim kapalı.
  final ValueChanged<Attachment>? onChanged;

  /// Kırpma dikdörtgenini (görsel oranında, 0–1) uygulayacak taraf. Kırpma
  /// dosyanın kendisini yeniden yazdığı için ek deposu ve not kimliği gerekir;
  /// ikisi de bu ekranda yok, o yüzden iş çağırana bırakılır. null ise kırpma
  /// düğmesi hiç çizilmez.
  final Future<void> Function(Attachment, Rect)? onCrop;

  /// Görseli 90°'nin katıyla döndürüp KALICI olarak yeniden yazacak taraf
  /// ([onCrop] ile aynı gerekçe). null ise döndürme düğmeleri çizilmez.
  ///
  /// GÜNCELLENMİŞ eki döndürür (null = başarısız): ekran döndürdükten sonra
  /// KAPANMIYOR, yeni ekle kendini tazeliyor. Kullanıcı bulgusu 2026-08-16:
  /// "her döndürme işleminden sonra düzenleme ekranı kapanıyor ama işlem
  /// başarılı" — arka arkaya iki tur atmak için ekranı yeniden açmak
  /// gerekiyordu.
  final Future<Attachment?> Function(Attachment, int)? onRotate;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

/// Galeri kabuğu: tek görselde doğrudan sayfayı, birden çok görselde yatay
/// bir [PageView] kurar. Her sayfa KENDİ çizim/metin/yakınlaştırma durumunu
/// taşır — swipe ile geçilen görselin kalemi öncekinden etkilenmez.
class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final List<Attachment> _pages = _buildPages();
  late final int _initial = _pages.indexWhere(
    (a) => a.id == widget.attachment.id,
  );
  late final PageController _controller = PageController(
    initialPage: _initial < 0 ? 0 : _initial,
  );

  /// Yatay kaydırma kilitli mi — yakınlaştırılmış, çizim/metin/alan kipinde.
  final _swipeLock = ValueNotifier<bool>(false);
  late int _index = _initial < 0 ? 0 : _initial;

  /// Kaydırma listesi: yalnız GÖRSELLER (video kutusu kendi oynatıcısını
  /// açar) ve yalnız açılan ek listede varsa. Aksi hâlde tek sayfa.
  List<Attachment> _buildPages() {
    final list = [
      for (final a in widget.gallery)
        if (a.kind == AttachmentKind.image) a,
    ];
    if (list.length < 2 || !list.any((a) => a.id == widget.attachment.id)) {
      return [widget.attachment];
    }
    return list;
  }

  @override
  void dispose() {
    _controller.dispose();
    _swipeLock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.length < 2) {
      return _ImageViewerPage(
        attachment: widget.attachment,
        onChanged: widget.onChanged,
        onCrop: widget.onCrop,
        onRotate: widget.onRotate,
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _swipeLock,
      builder: (context, locked, _) => PageView.builder(
        controller: _controller,
        physics: locked ? const NeverScrollableScrollPhysics() : null,
        itemCount: _pages.length,
        onPageChanged: (i) {
          // Kilit sayfayla birlikte sıfırlanır: önceki görsel yakınlaştırılmış
          // bırakıldıysa yenisinde kaydırma kilitli kalmasın.
          _swipeLock.value = false;
          setState(() => _index = i);
        },
        itemBuilder: (context, i) => _ImageViewerPage(
          // Anahtar EK KİMLİĞİ: sayfalar yeniden kurulduğunda (kilit değişimi)
          // her görselin çizim/metin durumu kendi sayfasında kalsın.
          key: ValueKey(_pages[i].id),
          attachment: _pages[i],
          // Değişen ek KABUĞUN listesine de yazılır: uzak bir sayfaya kayıp
          // geri dönüldüğünde sayfa bu listeden yeniden kurulur ve bayat bir
          // kopya (döndürmede takas olmuş en-boy, silinmiş bulut kopyası)
          // kullanılırdı.
          onChanged: widget.onChanged == null
              ? null
              : (a) {
                  _pages[i] = a;
                  widget.onChanged!(a);
                },
          onCrop: widget.onCrop,
          onRotate: widget.onRotate == null
              ? null
              : (a, turns) async {
                  final rotated = await widget.onRotate!(a, turns);
                  if (rotated != null) _pages[i] = rotated;
                  return rotated;
                },
          swipeLock: _swipeLock,
          active: i == _index,
          position: '${i + 1}/${_pages.length}',
        ),
      ),
    );
  }
}

class _ImageViewerPage extends StatefulWidget {
  const _ImageViewerPage({
    super.key,
    required this.attachment,
    this.onChanged,
    this.onCrop,
    this.onRotate,
    this.swipeLock,
    this.active = true,
    this.position,
  });

  final Attachment attachment;
  final ValueChanged<Attachment>? onChanged;
  final Future<void> Function(Attachment, Rect)? onCrop;
  final Future<Attachment?> Function(Attachment, int)? onRotate;

  /// Galeri kabuğunun kaydırma kilidi; yalnız [active] sayfa yazar.
  final ValueNotifier<bool>? swipeLock;
  final bool active;

  /// Başlıkta gösterilen "3/6" konumu (tek görselde null).
  final String? position;

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage>
    with SingleTickerProviderStateMixin {
  /// EKRANIN GÖSTERDİĞİ ek. Döndürme dosyayı yeniden yazdığı için
  /// `_attachment` o andan sonra bayat: boyutlar takas olmuş, bulut
  /// kopyası silinmiş olur. Yerel kopya döndürme sonrası tazelenir.
  late Attachment _attachment = widget.attachment;

  /// GÖRSEL ÜZERİNE METİN — Paint'in metin aracının karşılığı.
  ///
  /// KÖK NEDEN (kullanıcı 2026-08-16: "paint tarzı metin alanını
  /// bulamıyorum"): "açık metin alanı" balon kipinin bir seçeneği olarak
  /// eklenmişti, ama BALON KİPİ yalnız PDF/sunum görüntüleyicisinde vardı —
  /// yani bir FOTOĞRAFIN üstüne yazı koymanın hiçbir yolu yoktu. Oysa
  /// Paint'te metin aracının doğal yeri tam olarak resmin üstü.
  ///
  /// Veri modeli hazırdı: `Attachment.bubbles` her ek türünde var ve
  /// senkronlanıyor; görsel tek "sayfa" olduğu için hepsi `page: 1`.
  late final BubbleController _bubbles = BubbleController(
    initial: widget.attachment.bubbles,
    onChanged: (list) =>
        widget.onChanged?.call(
          _attachment = _attachment.copyWith(bubbles: list),
        ),
    hidden: widget.attachment.bubblesHidden,
    onHiddenChanged: (hidden) => widget.onChanged?.call(
      _attachment = _attachment.copyWith(bubblesHidden: hidden),
    ),
  );

  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onChanged?.call(_attachment = _attachment.copyWith(ink: strokes)),
  );
  final _zoom = TransformationController();
  bool _editing = false;

  // ── ÇİFT DOKUNUŞLA YAKINLAŞTIRMA (Google Fotoğraflar mantığı) ──────────
  // Kullanıcı isteği 2026-09-06: "görsel açılınca çift tık zoom mantığı
  // Google fotoğraflar gibi". Tam ekran görüntüleyicide yakınlaştırmanın TEK
  // yolu iki parmaktı; tek elle telefon tutan kullanıcı için çift dokunuş
  // (dokunulan noktaya, animasyonlu) beklenen davranış. Hesap tek yerde:
  // bkz. zoom_math.dart — slayt kutusu ([ZoomBox]) da aynı işlevleri kullanır.
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _zoomTween;

  /// Görselin en son ölçülen kutusu (dp) — çift dokunuşun sınır hesabı için.
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    // Yakınlaştırma ve metin kipi kaydırma kilidini etkiliyor; ikisi de
    // ekranı yeniden kurmadan değişebiliyor, o yüzden dinlenir.
    _zoom.addListener(_syncSwipeLock);
    _bubbles.addListener(_syncSwipeLock);
    _zoomAnim.addListener(() {
      final tween = _zoomTween;
      if (tween != null) _zoom.value = tween.value;
    });
  }

  /// Matrisi animasyonla [target]'a götürür: ani sıçrama görselde nerede
  /// olunduğunu kaybettirir.
  void _animateZoomTo(Matrix4 target) {
    _zoomTween = Matrix4Tween(begin: _zoom.value, end: target).animate(
      CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic),
    );
    _zoomAnim.forward(from: 0);
  }

  /// Çift dokunuş: yakınsa SIĞDIR'a döner, değilse dokunulan noktaya
  /// yakınlaşır. Dokunuş görselin KENDİ (ölçeklenmemiş) uzayında geldiği
  /// için önce ekran uzayına çevrilir.
  void _handleDoubleTap(TapDownDetails details) {
    if (_viewport.isEmpty) return;
    if (isZoomed(_zoom.value)) {
      _animateZoomTo(Matrix4.identity());
      return;
    }
    _animateZoomTo(
      zoomAt(
        current: _zoom.value,
        viewportPoint: MatrixUtils.transformPoint(
          _zoom.value,
          details.localPosition,
        ),
        viewport: _viewport,
      ),
    );
  }

  /// İki parmak bırakılınca: sınırın altına inen ölçek sığdır hâline geri
  /// yaylanır, kenarda açılan boşluk kapanır (yine Google Fotoğraflar).
  void _settleZoom() {
    if (_viewport.isEmpty || _editing) return;
    final settled = settle(_zoom.value, _viewport);
    if (settled == _zoom.value) return;
    _animateZoomTo(settled);
  }

  @override
  void didUpdateWidget(_ImageViewerPage old) {
    super.didUpdateWidget(old);
    if (old.active && !widget.active) {
      // Sayfa geride kaldı: yarım kalan çizgi ve boş metin kutusu burada
      // kapatılır. Kare sonuna ERTELENİR — build sırasında not güncellemek
      // (setState) editörü yeniden kurmanın ortasına düşerdi.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ink.save();
        _bubbles.dropEmpty();
      });
    }
    if (!old.active && widget.active) _syncSwipeLock();
  }

  /// Kaydırma kilidini tazeler: yakınlaştırılmışken ya da çizim/metin/alan
  /// kipindeyken yatay parmak SAYFA DEĞİŞTİRMEZ.
  void _syncSwipeLock() {
    final lock = widget.swipeLock;
    if (lock == null || !widget.active) return;
    lock.value =
        _editing ||
        _areaMode ||
        _bubbles.adding ||
        _zoom.value.getMaxScaleOnAxis() > 1.01;
  }

  /// Döndürme sürerken (dosya yeniden kodlanıyor) düğmeler kilitlenir:
  /// iki döndürme üst üste binerse ikincisi birincinin ESKİ baytlarını okur
  /// ve ilk tur kaybolurdu.
  bool _busy = false;

  // ── Görseldeki METNİ TANI ────────────────────────────────────────────
  // Tanıma ve seçim BU EKRANDA DEĞİL, ortak "Metni Tanı" ekranında
  // (bkz. text_recognize_screen.dart). Burada bir satır seçim katmanı vardı;
  // uygulamada metin tanımanın üç ayrı görünümü oluşmuştu ve bu ekrandaki
  // yalnız SATIR seçebiliyordu (kullanıcı: "harf harf seçebilmeliyiz").

  /// Metin tanıma bu ekte mümkün mü: ML Kit yalnız mobilde var, OCR da
  /// dosyanın YEREL kopyasını okur (buluttaki kopya indirilmeden olmaz) ve
  /// kutuları yerleştirmek için görselin piksel ölçüsü gerekir.
  bool get _ocrAvailable {
    final a = _attachment;
    return ScanOcr.supported &&
        a.localPath.isNotEmpty &&
        localFileExists(a.localPath) &&
        (a.width ?? 0) > 0 &&
        (a.height ?? 0) > 0;
  }

  Future<void> _openRecognizer() async {
    final a = _attachment;
    // Çizim açıkken yarım kalan çizgi kaybolmasın.
    if (_editing) _ink.save();
    await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => TextRecognizeScreen(
          imagePath: a.localPath,
          imageWidth: a.width ?? 0,
          imageHeight: a.height ?? 0,
          title: a.fileName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _zoom.removeListener(_syncSwipeLock);
    _bubbles.removeListener(_syncSwipeLock);
    _ink.dispose();
    _bubbles.dispose();
    _zoomAnim.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _editing = !_editing;
      _ink.setEditing(_editing);
    });
    _syncSwipeLock();
  }

  /// Kırpma ekranını açar, seçilen alanı çağırana uygular ve tam ekrandan
  /// ÇIKAR: kırpma dosyayı yeniden yazdığından bu ekrandaki ek nesnesi (ve
  /// çizim denetleyicisi) anında bayatlar. Nota dönmek, kırpılmış hâli
  /// notun kendi tuvalinden göstermenin en kısa yolu.
  Future<void> _crop(double aspect) async {
    // Çizim açıkken kırpmaya geçilirse yarım kalan çizgi kaybolur.
    if (_editing) _ink.save();
    final rect = await Navigator.of(context).push<Rect>(
      MaterialPageRoute<Rect>(
        builder: (_) => ImageCropScreen(image: _provider(), aspect: aspect),
      ),
    );
    if (rect == null || !mounted) return;
    // Tüm görsel bir kez daha seçildiyse dosyayı boşuna yeniden yazma.
    if (rect.left <= 0 &&
        rect.top <= 0 &&
        rect.right >= 1 &&
        rect.bottom >= 1) {
      Navigator.of(context).pop();
      return;
    }
    await widget.onCrop!(_attachment, rect);
    if (mounted) Navigator.of(context).pop();
  }

  /// Görseli çeyrek tur döndürür ve EKRANDA KALIR.
  ///
  /// Kırpmadan ([_crop]) farkı burada: kırpma yeni bir çerçeve seçtirir ve
  /// sonuç notun tuvalinde görülmek istenir; döndürme ise arka arkaya
  /// yapılan bir ayardır ("bir tur daha"). Ekranı her turda kapatmak
  /// kullanıcıyı görseli yeniden açmaya zorluyordu.
  ///
  /// Döndürme dosyayı AYNI yola yeniden yazdığı için Flutter'ın görsel
  /// önbelleği temizlenmezse eski kare gösterilmeye devam eder; temizlik
  /// çağıranda yapılıyor (bkz. `_rotateImage`). Buradaki `_reloadKey` ise
  /// widget ağacındaki `Image`'ı yeni bir öğe yapıp çözdürmeyi zorlar.
  Future<void> _rotate(int quarterTurns) async {
    if (_busy) return;
    // Çizim açıkken yarım kalan çizgi kaybolmasın.
    if (_editing) _ink.save();
    setState(() => _busy = true);
    try {
      final updated = await widget.onRotate!(_attachment, quarterTurns);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (updated != null) {
          _attachment = updated;
          _reloadKey++;
          // Çizim de döndü; denetleyici yeni oranlı noktalarla tazelenir.
          _ink.replace(updated.ink);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Her döndürmede artar; `Image`'ın anahtarına girer ki aynı yoldaki yeni
  /// dosya gerçekten yeniden çözülsün.
  int _reloadKey = 0;

  /// **ALAN SEÇİMİ** kipi (bkz. [AreaSelectLayer]).
  bool _areaMode = false;
  final _areaBoundary = GlobalKey();

  /// Alan seçimini açar/kapatır; çizim ve metin bırakma kipleri kapanır —
  /// üçü de tek parmağı bekliyor.
  void _toggleAreaMode() {
    setState(_syncAreaMode);
    _syncSwipeLock();
  }

  void _syncAreaMode() {
    _areaMode = !_areaMode;
    if (!_areaMode) return;
    if (_editing) {
      _editing = false;
      _ink.setEditing(false);
    }
    _bubbles.setAdding(false);
  }

  /// Görselin kaynağı: yerel kopya → indirme adresi. Kırpma ekranı da aynı
  /// kaynağı kullanır ki seçilen alan gösterilenle birebir örtüşsün.
  ImageProvider _provider() {
    final a = _attachment;
    if (a.localPath.isNotEmpty && localFileExists(a.localPath)) {
      return FileImage(File(a.localPath));
    }
    return CachedNetworkImageProvider(a.downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = _attachment;
    Widget image;
    if (a.localPath.isNotEmpty && localFileExists(a.localPath)) {
      // Çözünürlük kovası: ekler 1600 px'e kadar olabiliyor ve tam
      // çözünürlük çözmek ~10 MB'lık bir bitmap demek. Yakınlaştırma için pay
      // bırakılır (2×), gerisi boşuna bellek.
      image = Image.file(
        File(a.localPath),
        // Döndürme dosyayı AYNI yola yazıyor; anahtar değişmezse Flutter
        // eski kareyi göstermeye devam eder (bkz. [_rotate]).
        key: ValueKey('${a.localPath}#$_reloadKey'),
        fit: BoxFit.contain,
        cacheWidth: decodeWidthBucket(
          MediaQuery.sizeOf(context).width * 2,
          MediaQuery.devicePixelRatioOf(context),
        ),
      );
    } else if (a.isUploaded) {
      image = CachedNetworkImage(
        imageUrl: a.downloadUrl,
        fit: BoxFit.contain,
        progressIndicatorBuilder: (context, url, progress) =>
            Center(child: CircularProgressIndicator(value: progress.progress)),
      );
    } else {
      image = const Icon(Icons.broken_image_outlined, size: 64);
    }

    // Çizim katmanı görselin KUTUSUYLA birebir aynı olmalı: oranlı noktalar
    // ancak o zaman yakınlaştırmada da görselin üstünde kalır. Bu yüzden
    // görsel, kendi en-boy oranındaki bir kutuya yerleştirilir.
    // ponytail: oranı bilinmeyen (eski) ekte kare varsayılır — not tuvali de
    // aynı varsayımı kullanıyor.
    final aspect = (a.width != null && a.height != null && a.height! > 0)
        ? a.width! / a.height!
        : 1.0;

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        _ink.save();
        // Yazılmadan bırakılan boş metin alanı görselde anlamsız bir çerçeve
        // olarak kalmasın (PDF görüntüleyicideki kuralın aynısı).
        _bubbles.dropEmpty();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Flexible(
                child: Text(
                  a.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              // Galeride kaçıncı görselde olduğumuz: kaydırmanın bir sonu
              // olduğu görünsün.
              if (widget.position != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.position!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ],
          ),
          actions: [
            // Eki kopyala (çizim kipinde gizli — araç çubuğu kalem için).
            if (!_editing) CopyAttachmentButton(attachment: _attachment),
            // Kırpma çizim MODUNDA gizlenir: o an araç çubuğu kalem/silgi
            // için kullanılıyor, iki kip aynı anda anlamlı değil.
            if (widget.onCrop != null && !_editing)
              IconButton(
                tooltip: l10n.crop,
                icon: const Icon(Icons.crop),
                onPressed: _busy ? null : () => _crop(aspect),
              ),
            // Döndürme (kullanıcı isteği 2026-08-16). Kırpmayla aynı kural:
            // çizim MODUNDA gizlenir, o an araç çubuğu kalem/silgi için.
            if (widget.onRotate != null && !_editing) ...[
              IconButton(
                tooltip: l10n.imageRotateLeft,
                icon: const Icon(Icons.rotate_left),
                onPressed: _busy ? null : () => _rotate(-1),
              ),
              IconButton(
                tooltip: l10n.imageRotateRight,
                icon: const Icon(Icons.rotate_right),
                onPressed: _busy ? null : () => _rotate(1),
              ),
            ],
            // METİN ARACI (Paint'teki gibi): görselin üstüne yazı bırakır.
            // Çizim kipiyle karşılıklı dışlamalı — ikisi de tek parmağı
            // kullanıyor.
            if (widget.onChanged != null)
              AnimatedBuilder(
                animation: _bubbles,
                builder: (context, _) => IconButton(
                  tooltip: _bubbles.adding
                      ? l10n.bubbleAddDone
                      : l10n.bubblePlainMode,
                  isSelected: _bubbles.adding,
                  icon: Icon(_bubbles.adding ? Icons.check : Icons.title),
                  onPressed: () {
                    if (!_bubbles.adding) {
                      if (_editing) _toggleEditing();
                      // Görselde varsayılan AÇIK METİN: kullanıcı buraya
                      // "Paint gibi yazı koymak" için geliyor, balon
                      // tutamacı için değil.
                      _bubbles.setPlainMode(true);
                    }
                    _bubbles.setAdding(!_bubbles.adding);
                  },
                ),
              ),
            if (widget.onChanged != null)
              IconButton(
                tooltip: _editing ? l10n.annotateDone : l10n.annotate,
                isSelected: _editing,
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                onPressed: _toggleEditing,
              ),
            // ALAN SEÇİMİ: görselin bir parçasını (formül, tablo, yazı)
            // panoya al ya da yapay zekâya sor — PDF/sunumdakiyle aynı kip.
            IconButton(
              tooltip: _areaMode ? l10n.areaSelectOff : l10n.areaSelect,
              isSelected: _areaMode,
              icon: const Icon(Icons.crop_free),
              onPressed: _busy ? null : _toggleAreaMode,
            ),
          ],
        ),
        body: _busy
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      key: _areaBoundary,
                      child: _canvas(aspect, image),
                    ),
                  ),
                  // Yazma kartı KLAVYENİN üstünde: Scaffold klavye kadar
                  // daraldığı için "alt kenar" = klavyenin üstü
                  // (PDF görüntüleyicideki yerleşimin aynısı).
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: BubbleDock(
                      controller: _bubbles,
                      readOnly: widget.onChanged == null,
                      bottomPadding: MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                  if (_areaMode)
                    Positioned.fill(
                      child: AreaSelectLayer(
                        boundaryKey: _areaBoundary,
                        onCancel: _toggleAreaMode,
                        onCaptured: (png) => showAreaActions(context, png),
                      ),
                    ),
                ],
              ),
        // Metni tanı düğmesi: çizim kipinde gizlenir (o an araç çubuğu
        // kalem/silgi için kullanılıyor).
        // Metni tanı düğmesi metin/çizim kiplerinde gizlenir. `AnimatedBuilder`
        // ŞART: kip değişince yalnız denetleyici haber veriyor, ekranın
        // kendisi yeniden kurulmuyor.
        floatingActionButton: AnimatedBuilder(
          animation: _bubbles,
          builder: (context, _) => !_ocrAvailable || _editing || _bubbles.adding
              ? const SizedBox.shrink()
              : FloatingActionButton.extended(
                  heroTag: 'image-ocr',
                  tooltip: l10n.imageOcrTitle,
                  onPressed: _openRecognizer,
                  icon: const Icon(Icons.text_fields),
                  label: Text(l10n.imageOcrShort),
                ),
        ),
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : ValueListenableBuilder<bool>(
                valueListenable: _bubbles.addingListenable,
                builder: (context, adding, _) => adding
                    ? BubbleToolbar(controller: _bubbles)
                    : const SizedBox.shrink(),
              ),
      ),
    );
  }

  /// Görsel + çizim + metin katmanları (hepsi görselin en-boy kutusunda).
  Widget _canvas(double aspect, Widget image) => Center(
    child: AspectRatio(
      aspectRatio: aspect,
      // Çizimde InteractiveViewer'ın kendi jestleri kapalı: tek parmak
      // çizer, iki parmak yakınlaştırma/kaydırmayı InkNavLayer matrise
      // uygular (IV iki parmağın birlikte hareketini "pan" sayıp
      // panEnabled:false'ta yutuyor — bkz. ink_layer.dart).
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewport = constraints.biggest;
          return InkNavLayer(
            enabled: _editing,
            controller: _ink,
            getMatrix: () => _zoom.value,
            setMatrix: (m) => _zoom.value = m,
            minScale: 1,
            maxScale: 8,
            clampToBounds: true,
            child: InteractiveViewer(
              transformationController: _zoom,
              maxScale: 8,
              panEnabled: !_editing,
              scaleEnabled: !_editing,
              // İki parmak bırakılınca sınırlar yerine oturur.
              onInteractionEnd: (_) => _settleZoom(),
              child: Stack(
                children: [
                  // ÇİFT DOKUNUŞ EN ALT KATMANDA — üstündeki balon/çizim
                  // katmanlarını SARMADAN. Çift dokunuş tanıyıcısı bir ATA
                  // olsaydı, altındaki her tek dokunuşun kararı ~300 ms
                  // gecikirdi (aynı tuzak tuvalde de yaşandı, bkz. HAFIZA
                  // 2026-09-05): balona dokunmak "takılıyor" gibi görünürdü.
                  // Kardeş olduğu için balonun dokunuşu buraya hiç düşmez.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTapDown: _handleDoubleTap,
                      // Konum yalnız `onDoubleTapDown` ile geliyor; tanıyıcı
                      // ancak `onDoubleTap` da verilince kurulur.
                      onDoubleTap: () {},
                      child: image,
                    ),
                  ),
                  Positioned.fill(
                    child: InkPageLayer(controller: _ink, page: 1),
                  ),
                  // Metin katmanı görselin KUTUSUYLA aynı: konumlar sayfa
                  // oranı olduğu için yakınlaştırmada da yerinde kalır
                  // (çizim katmanıyla aynı gerekçe). Görsel tek sayfa.
                  Positioned.fill(
                    child: BubblePageLayer(
                      controller: _bubbles,
                      page: 1,
                      readOnly: widget.onChanged == null,
                      // Görsel görüntüleyicide basılı tutmak bir şey
                      // bırakmaz: yakınlaştırıp gezerken parmağı
                      // dinlendirmek sürpriz metin alanı açmasın.
                      longPressAdd: false,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
