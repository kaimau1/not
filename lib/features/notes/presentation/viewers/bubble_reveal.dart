part of 'bubble_layer.dart';

/// **AÇILAN BALONU GÖRÜNÜR KILMANIN TEK YOLU** (kullanıcı bulgusu
/// 2026-10-16: "balonlu modda balona tıklayınca odak bir aşağı bir yukarı
/// garip şeyler oluyor, odaklama baştan aşağı yenilenmeli").
///
/// ESKİ YOL VE KÖK NEDENLERİ:
///  1. Her açılışta (okuma kartı, sonra "Düzenle" ile yazma kartı) SABİT
///     420 ms sonra belge koşulsuz ORTALANIYORDU. Tutamaç zaten ekranda
///     olduğu için (ona dokunuldu!) her dokunuş bir kaydırma, "Düzenle" de
///     ikinci bir kaydırma demekti.
///  2. 420 ms klavyeyi beklemeye yetmiyordu: ölçüm klavye animasyonunun
///     ortasında yapılıyor, gövde klavye DURUNCA (KeyboardSnap) kısalıyor ve
///     belge yeniden kayıyordu.
///  3. pdfrx görüntüleyici boyutu her değiştiğinde (yazma kipinde başlık/
///     çubuklar gizlenince, klavye oturunca) SAYFANIN BAŞINA animasyonla
///     gidiyor (`_updateLayout` → `_goToPage`). Ortalama → sayfa başı →
///     ortalama: kullanıcının gördüğü "aşağı yukarı" buydu. Bu ayağı
///     [StableViewport] kapatır.
///
/// YENİ YOL:
///  * Yerleşim OTURANA dek beklenir: görünür alan, klavye, yazma kartının
///    boyu ve balonun ekrandaki yeri art arda birkaç ölçümde değişmeyince
///    (yazma kartı açılıyorsa klavye de gelmişken) TEK kez karar verilir.
///  * Balonun yeri TAHMİN edilmez, ölçülür: sayfa katmanının ekrandaki
///    kutusundan ([BubbleController.globalPointOf]).
///  * Balon zaten rahatça görünüyorsa HİÇ kaydırılmaz. Görünmüyorsa (yazma
///    kartının/klavyenin arkasında, ekran dışında) görünür alanın ortasına
///    tek, yumuşak bir kaydırmayla getirilir.
///  * Sayfası kurulu değilse ("balona git" başka sayfaya) görüntüleyicinin
///    kendi hesabıyla ortalanır ([centerUnbuilt]).
class BubbleReveal {
  BubbleReveal(this.controller);

  final BubbleController controller;

  /// Ölçüm döngüsü KAREYE bağlı (F2.2): eskiden 30 ms'lik zamanlayıcıydı —
  /// ölçüm kare ortasına, yerleşim bitmeden düşebiliyordu.
  FrameLoop? _loop;

  /// Yerleşimin "oturdu" sayılması için imzanın değişmeden kalacağı süre
  /// (eski döngüde 4 × 30 ms).
  static const _settle = Duration(milliseconds: 120);

  void cancel() {
    _loop?.dispose();
    _loop = null;
  }

  /// [viewport]: görüntüleyicinin (ve üstündeki yazma kartının) kutusu.
  /// [scrollBy]: belgeyi ekran pikseliyle [dy] kadar kaydırır (pozitif =
  /// içerik yukarı çıkar). [centerUnbuilt]: balonu görüntüleyicinin
  /// üstünden [top] kadar aşağıda başlayan [height] yüksekliğindeki alanın
  /// ortasına getirir.
  void request(
    PageBubble bubble, {
    required BuildContext viewport,
    required void Function(double dy) scrollBy,
    void Function(double top, double height)? centerUnbuilt,
  }) {
    cancel();
    final watch = Stopwatch()..start();
    final expectKeyboard = controller.editMode;
    Object? last;
    var stableSince = 0;
    void step(double _) {
      if (!viewport.mounted) {
        cancel();
        return;
      }
      final live = controller.byId(bubble.id) ?? bubble;
      final region = visibleRegionOf(viewport, controller.dockHeight.value);
      final signature = (
        region,
        controller.dockHeight.value,
        controller.globalPointOf(live),
      );
      final ms = watch.elapsedMilliseconds;
      if (signature != last) stableSince = ms;
      last = signature;
      // Yazma kartı açıldıysa klavye gelecek: o gelmeden oturmuş sayılmaz
      // (klavye isteği platformdan bir-iki kare geç döner).
      final keyboardReady =
          !expectKeyboard || _keyboardOf(viewport) > 0 || ms > 900;
      final settled = ms - stableSince >= _settle.inMilliseconds;
      if (ms < 1600 && (!settled || !keyboardReady)) return;
      cancel();
      if (region == null) return;
      // Kapanmış ya da başka balona geçilmişse iş yok.
      if (controller.openBubble?.id != bubble.id) return;
      final point = controller.globalPointOf(live);
      final box = viewport.findRenderObject();
      if (point == null) {
        if (box is RenderBox && box.hasSize) {
          final top = region.top - box.localToGlobal(Offset.zero).dy;
          centerUnbuilt?.call(top, region.height);
        }
        return;
      }
      final dy = revealDelta(point.dy, region, editing: controller.editMode);
      if (dy != 0) scrollBy(dy);
    }

    _loop = FrameLoop(step)..start();
  }

  /// Balonun noktası [region] içinde rahatça görünüyorsa 0; değilse noktayı
  /// alanın ortasına getiren kaydırma (saf, test edilir).
  ///
  /// Okuma kartı tutamacın altına/üstüne açıldığı için okurken pay daha
  /// geniş.
  @visibleForTesting
  static double revealDelta(
    double pointY,
    Rect region, {
    required bool editing,
  }) {
    final pad = math.min(editing ? 48.0 : 96.0, region.height * 0.3);
    if (pointY >= region.top + pad && pointY <= region.bottom - pad) return 0;
    return pointY - region.center.dy;
  }

  /// Görüntüleyicinin EKRANDA gerçekten görünen kısmı: altı klavyenin
  /// üstüyle ve yazma kartıyla kırpılmış (kart klavyenin üstünde durur).
  static Rect? visibleRegionOf(BuildContext viewport, double dock) {
    final box = viewport.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final view = View.maybeOf(viewport);
    var bottom = rect.bottom;
    if (view != null) {
      final height = view.physicalSize.height / view.devicePixelRatio;
      bottom = math.min(bottom, height - _keyboardOf(viewport));
    }
    bottom -= dock;
    const margin = 12.0;
    final top = rect.top + margin;
    bottom -= margin;
    if (bottom - top < 60) return null;
    return Rect.fromLTRB(rect.left, top, rect.right, bottom);
  }

  static double _keyboardOf(BuildContext context) {
    final view = View.maybeOf(context);
    if (view == null) return 0;
    return view.viewInsets.bottom / view.devicePixelRatio;
  }
}

/// Görüntüleyiciyi klavye ve yazma kipindeki bölme değişimlerinde SABİT
/// boyda tutar (bkz. [BubbleReveal] kök neden 3).
///
/// pdfrx görüntüleyicinin boyu her değiştiğinde belgeyi o anki sayfanın
/// BAŞINA kaydırıyor. Balona yazarken bölme iki kez boy değiştiriyordu
/// (başlık/çubuklar gizlenince uzuyor, klavye oturunca kısalıyor) ve her
/// seferinde okunan yer kaybolup sayfa başına sıçrıyordu.
///
/// Kural: klavye AÇIKKEN boy değişimi görüntüleyiciye hiç yansıtılmaz
/// (fazlası alttan kırpılır — zaten klavyenin/kartın arkasında kalan yer);
/// klavye kapalıyken yeni boy ancak [settle] kadar SABİT kalınca benimsenir
/// (yazma kipinden çıkarken bir-iki karelik ara boylar görüntüleyiciyi
/// tetiklemesin). Genişlik değişimi (döndürme, pencere) hemen uygulanır.
class StableViewport extends StatefulWidget {
  const StableViewport({
    super.key,
    required this.child,
    this.settle = const Duration(milliseconds: 280),
  });

  final Widget child;
  final Duration settle;

  /// [context]'in içinde bulunduğu [StableViewport]'un bağlamı (bölmenin
  /// GÖRÜNEN kutusu); yoksa [context]'in kendisi. Görüntüleyicinin kendi
  /// kutusu sabit tutulduğu için görünür alandan büyük olabilir.
  static BuildContext contextOf(BuildContext context) =>
      context.findAncestorStateOfType<_StableViewportState>()?.context ??
      context;

  @override
  State<StableViewport> createState() => _StableViewportState();
}

class _StableViewportState extends State<StableViewport> {
  double? _width;
  double? _height;

  /// Benimsenmeyi bekleyen boy ve zamanlayıcısı.
  double? _pending;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule(double height) {
    if (_pending == height && _timer != null) return;
    _pending = height;
    _timer?.cancel();
    _timer = Timer(widget.settle, () {
      _timer = null;
      if (!mounted || _pending == null) return;
      // Bu arada klavye açıldıysa bekleyen boy unutulur (klavye kapanınca
      // yeniden değerlendirilir).
      if (MediaQuery.viewInsetsOf(context).bottom > 0) return;
      setState(() {
        _height = _pending;
        _pending = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Yalnız BU widget klavye karelerinde tazelenir; [child] aynı örnek
    // olduğundan görüntüleyici yeniden kurulmaz.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (!width.isFinite || !height.isFinite) return widget.child;
        if (_height == null || _width != width) {
          _width = width;
          _height = height;
          _pending = null;
          _timer?.cancel();
          _timer = null;
        } else if (height == _height) {
          _pending = null;
          _timer?.cancel();
          _timer = null;
        } else if (!keyboard) {
          _schedule(height);
        } else {
          _pending = null;
          _timer?.cancel();
          _timer = null;
        }
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: width,
            maxWidth: width,
            minHeight: _height,
            maxHeight: _height,
            child: widget.child,
          ),
        );
      },
    );
  }
}
