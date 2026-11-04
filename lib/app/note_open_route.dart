import 'dart:ui' as ui show Image;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PaintingContextCallback;

import 'split_shell.dart';
import '../core/a11y/motion.dart';
import '../core/widgets/note_route_closing.dart';

/// **NOT KARTTAN GENİŞLEYEREK AÇILIR** (kullanıcı isteği 2026-10-28:
/// "notlar dashboard'dan açılırken sayfa kaydırma şeklinde değil, sanki o not
/// genişleyerek ekranı kaplıyormuş gibi yumuşak bir geçiş").
///
/// Kart dokunuşu ([register]) kartın ekrandaki yerini, köşesini ve zemin
/// rengini bırakır; `/note/:id` sayfası ([NoteOpenPage]) kurulurken bunu bir
/// kez alır ([take]) ve editör kartın yerinden, kartın renginde büyüyerek
/// ekranı kaplar. Kapanırken aynı yoldan KARTIN O ANKİ yerine küçülür (not
/// düzenlenip ızgarada yer değiştirdiyse yeni yerine). Kart artık yoksa
/// (kaydırılıp tembel listeden düştü, silindi) solarak küçülür.
///
/// Karttan gelmeyen açılış (bildirim, "+", derin bağlantı) ve geniş ekran
/// (liste solda dururken not sağ bölmede açılır) eskisi gibi yandan kayar.
/// **HERO TARAMASI KAPALI (F23.1, K5):** her `PageRoute` geçişinde
/// HeroController iki rotanın TÜM alt ağacını gezer (`Hero._allHeroesFor`) —
/// elle `Hero` yok, yalnız FAB `heroTag`ları; ana ekran + editör ağacında bu
/// kapanışın ilk karesine biniyordu. `HeroControllerScope.none` işe yaramaz:
/// go_router her gezgine kendi HeroController'ını koyuyor. `HeroMode(enabled:
/// false)` taramayı o düğümde DURDURUR (alt ağaca inilmez). Bedel: FAB'lar
/// sayfalar arasında uçmaz, sayfayla birlikte geçer.
Widget withoutHeroWalk(Widget child) => HeroMode(enabled: false, child: child);

class NoteOpenOrigin {
  NoteOpenOrigin._(this.noteId, this._card, this.radius, this.color);

  final String noteId;
  final BuildContext _card;

  /// Kartın köşe yarıçapı ve zemini: geçişin ilk karesi kartla aynı görünür.
  final double radius;
  final Color color;

  final DateTime _at = DateTime.now();

  static NoteOpenOrigin? _pending;

  /// Kart dokunuşunda çağrılır. Alt levhadan (sayfasız açılır rota) ya da
  /// ekranın neredeyse tamamını kaplayan bir bağlamdan gelen açılış kayıt
  /// bırakmaz: orada "kart" yok, büyüme görünmez.
  static void register(
    BuildContext card,
    String noteId, {
    double radius = 16,
    required Color color,
  }) {
    _pending = null;
    if (ModalRoute.of(card) is! PageRoute) return;
    final rect = _globalRect(card);
    if (rect == null) return;
    final screen = MediaQuery.sizeOf(card);
    if (rect.width * rect.height > screen.width * screen.height * 0.6) return;
    _pending = NoteOpenOrigin._(noteId, card, radius, color);
  }

  /// Bu notun bekleyen kaydını BİR KEZ verir. Eski kayıt (açılış kilit
  /// doğrulamasında takıldı, başka not açıldı) atılır.
  static NoteOpenOrigin? take(String noteId) {
    final pending = _pending;
    _pending = null;
    if (pending == null || pending.noteId != noteId) return null;
    if (DateTime.now().difference(pending._at) > const Duration(seconds: 2)) {
      return null;
    }
    return pending;
  }

  /// Kartın ŞU ANKİ küresel dikdörtgeni; kart artık ağaçta değilse null.
  Rect? currentRect() => _globalRect(_card);

  static Rect? _globalRect(BuildContext context) {
    if (!context.mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// `/note/:id` sayfası: kayıt varsa genişleyen geçiş, yoksa temanın olağan
/// geçişi ([MaterialRouteTransitionMixin] — bkz. SmoothPageTransitionsBuilder).
class NoteOpenPage<T> extends Page<T> {
  const NoteOpenPage({
    required this.child,
    required this.noteId,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final String noteId;

  @override
  Route<T> createRoute(BuildContext context) {
    final origin = NoteOpenOrigin.take(noteId);
    // Geniş ekranda not sağ bölmede açılır; soldaki karttan büyümesi bölme
    // sınırını aşan tuhaf bir hareket olurdu.
    // Not açıkken kabuk daha dar pencerede de yan yana çizer.
    final narrow = MediaQuery.sizeOf(context).width < kNoteSplitBreakpoint;
    // Hareketi azalt (F15.5): karttan büyüme yerine kısa bir solma.
    final motion = motionOf(context);
    return _NoteOpenRoute<T>(
      page: this,
      origin: narrow && motion ? origin : null,
      fadeOnly: !motion,
    );
  }
}

class _NoteOpenRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _NoteOpenRoute({
    required NoteOpenPage<T> page,
    this.origin,
    this.fadeOnly = false,
  }) : super(settings: page);

  final NoteOpenOrigin? origin;

  /// Sistemde "hareketi azalt" açık: yalnız solma, alttaki liste kımıldamaz.
  final bool fadeOnly;

  NoteOpenPage<T> get _page => settings as NoteOpenPage<T>;

  @override
  Widget buildContent(BuildContext context) => withoutHeroWalk(_page.child);

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Duration get transitionDuration => fadeOnly
      ? const Duration(milliseconds: 150)
      : origin == null
      ? super.transitionDuration
      : const Duration(milliseconds: 460);

  @override
  Duration get reverseTransitionDuration => fadeOnly
      ? const Duration(milliseconds: 150)
      : origin == null
      ? super.reverseTransitionDuration
      : const Duration(milliseconds: 380);

  /// Genişleyen açılışta alttaki liste YERİNDE kalır (yana çekilmez): not
  /// onun üstünde büyür.
  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      origin == null && !fadeOnly && super.canTransitionFrom(previousRoute);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final origin = this.origin;
    if (fadeOnly) {
      return FadeTransition(
        opacity: animation,
        child: super.buildTransitions(
          context,
          kAlwaysCompleteAnimation,
          secondaryAnimation,
          child,
        ),
      );
    }
    if (origin == null) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    // Temanın geçişi yine sarılır: üstüne başka ekran binince editör eskisi
    // gibi yana çekilir, kenardan geri çekme jesti de çalışır (jest rotanın
    // denetleyicisini sürer — not parmağı izleyerek karta doğru küçülür).
    final themed = super.buildTransitions(
      context,
      kAlwaysCompleteAnimation,
      secondaryAnimation,
      child,
    );
    return _ContainerTransform(
      animation: animation,
      origin: origin,
      child: themed,
    );
  }
}

class _ContainerTransform extends StatefulWidget {
  const _ContainerTransform({
    required this.animation,
    required this.origin,
    required this.child,
  });

  final Animation<double> animation;
  final NoteOpenOrigin origin;
  final Widget child;

  @override
  State<_ContainerTransform> createState() => _ContainerTransformState();
}

class _ContainerTransformState extends State<_ContainerTransform> {
  // Açılış Material 3'ün "vurgulu" eğrisiyle: hızlı kalkar, yumuşak oturur.
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: widget.animation,
    curve: Curves.easeInOutCubicEmphasized,
    reverseCurve: Curves.easeInOutCubic,
  );

  /// Kartın son bilinen yeri (kart ağaçtan düşerse kapanış buna değil
  /// solmaya döner — bkz. [_build]).
  late Rect? _lastCard = widget.origin.currentRect();

  /// KASMA (kullanıcı bulgusu 2026-10-29: "not açılış kapanış genişleyip
  /// daralma animasyonu kasıyor"): ölçeklenen editör her karede baştan
  /// rasterleşiyordu (metin, görseller, kırpma — tam ekran). Geçiş boyunca
  /// sayfa BİR KEZ görüntüye alınır ve kareler o görüntüyü ölçekler; sayfa
  /// yeniden çizilirse (not yüklendi) görüntü tazelenir. Platform görünümü
  /// (oynayan video) varsa `permissive` olağan çizime döner. Geçiş bitince
  /// kapanır — editör canlı çizilir.
  final SnapshotController _snapshot = SnapshotController();

  /// F23.4: içeriğin solması `Opacity` (ekran boyunda ara katman + birleştirme,
  /// GLES'te kare başına ~tam ekran fazladan doku) yerine görüntünün BOYA
  /// ALFASIYLA — dondurulmuş görüntü yarı saydam boyayla bir kez çizilir.
  final _FadeSnapshotPainter _fade = _FadeSnapshotPainter();

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
    _onStatus(widget.animation.status);
  }

  void _onStatus(AnimationStatus status) {
    _snapshot.allowSnapshotting = status.isAnimating;
    if (!status.isAnimating) _refreshed = false;
  }

  /// Görüntü geçiş boyunca donar. AÇILIŞTA not içeriği geçiş sürerken
  /// gelebilir (ilk kare yükleniyor): içerik tam belirdiğinde ([_kRefreshAt])
  /// görüntü BİR KEZ tazelenir. KAPANIŞTA hiç tazelenmez — sayfa artık
  /// değişmiyor.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-30: "not kapanırken küçülme
  /// efektinde kasma var", "art arda açıp kapatınca kasmaya başlıyor"):
  /// görüntü her iki yönde de ilerleyişin her ~%30'unda yeniden alınıyordu.
  /// Her alım tam ekran editörün yeniden çizilip ekran boyunda bir dokuya
  /// (≈10 MB) basılması demek; açılış + kapanış başına 5-6 alım, art arda
  /// açıp kapatmada GPU belleğini çalkalıyor ve kareleri düşürüyordu.
  bool _refreshed = false;

  static const double _kRefreshAt = 0.45;

  void _refreshSnapshot(double t) {
    if (_refreshed || widget.animation.status != AnimationStatus.forward) {
      return;
    }
    if (t >= _kRefreshAt) {
      _refreshed = true;
      _snapshot.clear();
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    _snapshot.dispose();
    _fade.dispose();
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: _build,
      // Sayfa kendi katmanında: her karede yalnız dönüşüm/kırpma değişir,
      // editör yeniden çizilmez.
      child: SnapshotWidget(
        controller: _snapshot,
        mode: SnapshotMode.permissive,
        painter: _fade,
        child: RepaintBoundary(
          child: _FrozenWhileClosing(
            animation: widget.animation,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _build(BuildContext context, Widget? page) {
    final size = MediaQuery.sizeOf(context);
    final full = Offset.zero & size;
    final t = _curve.value;
    if (_snapshot.allowSnapshotting) _refreshSnapshot(t);
    final card = widget.origin.currentRect();
    if (card != null) _lastCard = card;
    // Kart ağaçtan düştüyse kapanışta yerine ölçeklenerek solar.
    final lostCard =
        card == null && widget.animation.status == AnimationStatus.reverse;
    final overlay = Navigator.maybeOf(context)?.overlay?.context
        .findRenderObject();
    Rect? from = lostCard ? null : _lastCard;
    if (from != null && overlay is RenderBox && overlay.hasSize) {
      final topLeft = overlay.globalToLocal(from.topLeft);
      from = topLeft & from.size;
    }
    from ??= Rect.fromCenter(
      center: full.center,
      width: size.width * 0.86,
      height: size.height * 0.86,
    );
    final rect = Rect.lerp(from, full, t)!;
    final scale = (rect.width / size.width).clamp(0.05, 1.0);
    final radius = lerpDouble(widget.origin.radius, 0, t)!;
    // İçerik ilk üçte birde belirir; o ana dek kartın rengi büyür (kartın
    // kendisi genişliyormuş gibi). Kapanışta tersi: içerik sonda söner.
    final content = const Interval(0.08, 0.42).transform(t);
    final fill = lostCard ? content : const Interval(0, 0.12).transform(t);
    final settled = t >= 1;
    _fade.opacity = content;
    // Kenar yumuşatmalı kırpma (ara katman) yalnız köşe yuvarlakken; yarıçap
    // sıfıra inince düz dikdörtgen kırpma yeter (F23.4).
    final clip = settled
        ? Clip.none
        : (radius > 0.5 ? Clip.antiAlias : Clip.hardEdge);
    // Büyüyen kutunun bulanık gölgesi YOK: tam ekrana varan bir dikdörtgenin
    // 28 px bulanıklığı her karede GPU'da yeniden hesaplanıyordu (kasmanın
    // ikinci kaynağı); derinliği alttaki kararma veriyor.
    return Stack(
      children: [
        // Alttaki liste hafifçe kararır: derinlik hissi, açılan not öne çıkar.
        Positioned.fill(
          child: IgnorePointer(
            // Karartma temanın mürekkebinden (TEMA_PLANI F34.2): siyah perde
            // renkli zemini griye çekiyordu; açık temada `scrim` = mürekkep.
            child: ColoredBox(
              color: Theme.of(
                context,
              ).colorScheme.scrim.withValues(alpha: 0.10 * t),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: rect,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.origin.color.withValues(
                alpha: widget.origin.color.a * fill,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: clip,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: size.width,
                maxWidth: size.width,
                minHeight: size.height,
                maxHeight: size.height,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: page,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dondurulmuş sayfa görüntüsünü [opacity] alfasıyla çizer (F23.4). Görüntü
/// yokken (geçiş bitti, platform görünümü) alfa < 1 ise olağan opaklık
/// katmanına, 1 ise doğrudan çizime döner; 0 ise hiç çizmez.
class _FadeSnapshotPainter extends SnapshotPainter {
  double _opacity = 1;

  double get opacity => _opacity;
  set opacity(double value) {
    if (value == _opacity) return;
    _opacity = value;
    notifyListeners();
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    if (_opacity <= 0) return;
    if (_opacity >= 1) {
      painter(context, offset);
    } else {
      context.pushOpacity(offset, (_opacity * 255).round(), painter);
    }
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    if (_opacity <= 0) return;
    final src = Rect.fromLTWH(0, 0, sourceSize.width, sourceSize.height);
    final dst = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(0, 0, 0, _opacity);
    context.canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(_FadeSnapshotPainter oldPainter) =>
      oldPainter._opacity != _opacity;
}

/// Kapanış geçişi boyunca sayfanın gördüğü [MediaQuery] DONAR.
///
/// KÖK NEDEN (kapanış kasması): editörden çıkarken klavye de kapanıyor;
/// klavyenin her karesinde `viewInsets` değişip bütün editör (Scaffold,
/// gövde, maddeler, sabit bölme) yeniden yerleşiyordu — üstelik sayfa o
/// sırada zaten donmuş bir görüntü olarak çiziliyor, yerleşimin hiçbir
/// görünür etkisi yoktu. Ağacın şekli değişmez (MediaQuery hep burada); geri
/// çekme jesti vazgeçilip geçiş ileri dönerse canlı değerlere dönülür.
class _FrozenWhileClosing extends StatefulWidget {
  const _FrozenWhileClosing({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_FrozenWhileClosing> createState() => _FrozenWhileClosingState();
}

class _FrozenWhileClosingState extends State<_FrozenWhileClosing> {
  MediaQueryData? _frozen;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    final closing = status == AnimationStatus.reverse;
    noteRouteClosing.value = closing;
    if (closing == (_frozen != null)) return;
    setState(() => _frozen = closing ? MediaQuery.of(context) : null);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: _frozen ?? MediaQuery.of(context),
    child: widget.child,
  );
}
