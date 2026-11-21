import 'dart:ui' as ui show Image;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show
        BoxHitTestResult,
        LayerHandle,
        PaintingContextCallback,
        PipelineOwner,
        RenderProxyBox,
        TransformLayer;

import 'split_shell.dart';
import 'theme/app_tokens.dart';
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
    final narrow = !splitActiveFor(MediaQuery.sizeOf(context));
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

  /// **KENARDAN ÇEKİNCE NOT KAPANMASIN** (kullanıcı bulgusu 2026-11-21:
  /// "not içinde soldan sağa çekince en kenardan kapatıyor"): temanın
  /// Cupertino geçişi sol kenarda geri çekme jesti kuruyordu; notta kalemle
  /// ya da parmakla kenardan başlayan her çizgi/kaydırma notu kapatıyordu.
  /// Not geri tuşu / ← düğmesiyle kapanır.
  @override
  bool get popGestureEnabled => false;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Duration get transitionDuration => fadeOnly
      ? AppMotion.short
      : origin == null
      ? super.transitionDuration
      : AppMotion.long;

  @override
  Duration get reverseTransitionDuration => fadeOnly
      ? AppMotion.short
      : origin == null
      ? AppMotion.exitOf(AppMotion.medium)
      : AppMotion.medium;

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
        child: _FrozenWhileClosing(
          animation: animation,
          child: super.buildTransitions(
            context,
            kAlwaysCompleteAnimation,
            secondaryAnimation,
            child,
          ),
        ),
      );
    }
    if (origin == null) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        _FrozenWhileClosing(animation: animation, child: child),
      );
    }
    // Temanın geçişi yine sarılır: üstüne başka ekran binince editör eskisi
    // gibi yana çekilir.
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

/// **BOYAMA-YALNIZ NOT GEÇİŞİ** (2026-11-21 kapanış kasması kökü):
///
/// ESKİDEN: `AnimatedBuilder` + `Positioned.fromRect` + `OverflowBox` +
/// `ClipRRect` her animasyon karesinde yeniden kurulup yerleşim yapıyordu
/// (kapanışta ~153 `RenderObject` dizilmesi, ~523 kurulum karesi, her karede
/// `currentRect()` + `localToGlobal`).
///
/// ŞİMDİ: geçiş karelerinde **sıfır widget kurulumu, sıfır yerleşim** —
/// `_TransformShell` ve `_ScaleRRectClipper` doğrudan `_curve` dinleyerek
/// yalnız boyama katmanında ölçekler/kırpar; kart konumu geçiş başında BİR
/// KEZ ölçülür. `ClipRRect.clipBehavior` yalnız animasyon başı/sonunda
/// (`Clip.antiAlias` ↔ `Clip.none`) değişir.
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
  // Açılış vurgulu eğriyle, kapanış hızlı ve pürüzsüz.
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: widget.animation,
    curve: AppMotion.emphasized,
    reverseCurve: AppMotion.enter,
  );

  /// Kartın başlangıç/kapanış dikdörtgeni (geçiş başında BİR KEZ ölçülür —
  /// kapanış boyunca pano `FreezeWhenHidden` ile donuk olduğundan yer değişmez).
  Rect? _fromLocal;
  bool _lostCard = false;

  /// Geçiş sürüyor mu: yalnız başlangıç/bitişte değişir (`ClipRRect` kırpması).
  late final _animating = ValueNotifier<bool>(widget.animation.status.isAnimating);

  /// Geçiş boyunca sayfa BİR KEZ görüntüye alınır (F23.4).
  final SnapshotController _snapshot = SnapshotController();

  /// İçeriğin solması `Opacity` ara katmanı yerine boya alfasıyla (F23.4).
  final _FadeSnapshotPainter _fade = _FadeSnapshotPainter();

  bool _refreshed = false;
  static const double _kRefreshAt = 0.45;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
    _curve.addListener(_onTick);
    _onStatus(widget.animation.status);
  }

  void _captureOrigin({required bool closing}) {
    final card = widget.origin.currentRect();
    _lostCard = closing && card == null;
    if (card == null) {
      if (closing) _fromLocal = null;
      return;
    }
    final overlay = Navigator.maybeOf(context)?.overlay?.context
        .findRenderObject();
    if (overlay is RenderBox && overlay.hasSize) {
      _fromLocal = overlay.globalToLocal(card.topLeft) & card.size;
    } else {
      _fromLocal = card;
    }
  }

  void _onStatus(AnimationStatus status) {
    final active = status.isAnimating;
    _snapshot.allowSnapshotting = active;
    if (!active) _refreshed = false;
    if (status == AnimationStatus.reverse && mounted) {
      _captureOrigin(closing: true);
    }
    if (_animating.value != active) _animating.value = active;
  }

  void _onTick() {
    final t = _curve.value;
    _fade.opacity = const Interval(0.08, 0.42).transform(t);
    if (_snapshot.allowSnapshotting &&
        !_refreshed &&
        widget.animation.status == AnimationStatus.forward &&
        t >= _kRefreshAt) {
      _refreshed = true;
      _snapshot.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fromLocal == null && !_lostCard) {
      _captureOrigin(closing: widget.animation.status == AnimationStatus.reverse);
    }
  }

  @override
  void dispose() {
    _curve.removeListener(_onTick);
    widget.animation.removeStatusListener(_onStatus);
    _animating.dispose();
    _snapshot.dispose();
    _fade.dispose();
    _curve.dispose();
    super.dispose();
  }

  Rect _resolveFrom(Size size) =>
      _fromLocal ??
      Rect.fromCenter(
        center: (Offset.zero & size).center,
        width: size.width * 0.86,
        height: size.height * 0.86,
      );

  @override
  Widget build(BuildContext context) {
    final scrim = Theme.of(context).colorScheme.scrim;
    final page = SnapshotWidget(
      controller: _snapshot,
      mode: SnapshotMode.permissive,
      painter: _fade,
      child: RepaintBoundary(
        child: _FrozenWhileClosing(
          animation: widget.animation,
          child: widget.child,
        ),
      ),
    );
    return _TransformShell(
      animation: _curve,
      resolveFrom: _resolveFrom,
      lostCard: () => _lostCard,
      originRadius: widget.origin.radius,
      originColor: widget.origin.color,
      scrimColor: scrim,
      child: ValueListenableBuilder<bool>(
        valueListenable: _animating,
        child: page,
        builder: (context, animating, child) => ClipRRect(
          clipBehavior: animating ? Clip.antiAlias : Clip.none,
          clipper: _ScaleRRectClipper(
            animation: _curve,
            resolveFrom: _resolveFrom,
            originRadius: widget.origin.radius,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Boyama katmanında kırpma dikdörtgeni (çocuğun yerel koordinatlarında).
class _ScaleRRectClipper extends CustomClipper<RRect> {
  _ScaleRRectClipper({
    required this.animation,
    required this.resolveFrom,
    required this.originRadius,
  }) : super(reclip: animation);

  final Animation<double> animation;
  final Rect Function(Size size) resolveFrom;
  final double originRadius;

  @override
  RRect getClip(Size size) {
    final t = animation.value;
    if (t >= 1) return RRect.fromRectXY(Offset.zero & size, 0, 0);
    final from = resolveFrom(size);
    final full = Offset.zero & size;
    final rect = Rect.lerp(from, full, t)!;
    final scale = (rect.width / size.width).clamp(0.05, 1.0);
    final radius = lerpDouble(originRadius, 0, t)! / scale;
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, rect.width / scale, rect.height / scale),
      Radius.circular(radius),
    );
  }

  @override
  bool shouldReclip(_ScaleRRectClipper old) =>
      old.animation != animation || old.originRadius != originRadius;
}

/// Scrim + kart rengi + ölçek/öteleme: yalnız boyama (yerleşim ve kurulum 0).
class _TransformShell extends SingleChildRenderObjectWidget {
  const _TransformShell({
    required this.animation,
    required this.resolveFrom,
    required this.lostCard,
    required this.originRadius,
    required this.originColor,
    required this.scrimColor,
    required super.child,
  });

  final Animation<double> animation;
  final Rect Function(Size size) resolveFrom;
  final bool Function() lostCard;
  final double originRadius;
  final Color originColor;
  final Color scrimColor;

  @override
  _RenderTransformShell createRenderObject(BuildContext context) =>
      _RenderTransformShell(
        animation,
        resolveFrom: resolveFrom,
        lostCard: lostCard,
        originRadius: originRadius,
        originColor: originColor,
        scrimColor: scrimColor,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTransformShell renderObject,
  ) {
    renderObject
      ..animation = animation
      ..resolveFrom = resolveFrom
      ..lostCard = lostCard
      ..originRadius = originRadius
      ..originColor = originColor
      ..scrimColor = scrimColor;
  }
}

class _RenderTransformShell extends RenderProxyBox {
  _RenderTransformShell(
    this._animation, {
    required this.resolveFrom,
    required this.lostCard,
    required this.originRadius,
    required this.originColor,
    required this.scrimColor,
  });

  Animation<double> _animation;
  set animation(Animation<double> v) {
    if (identical(v, _animation)) return;
    if (attached) {
      _animation.removeListener(markNeedsPaint);
      v.addListener(markNeedsPaint);
    }
    _animation = v;
    markNeedsPaint();
  }

  Rect Function(Size size) resolveFrom;
  bool Function() lostCard;
  double originRadius;
  Color originColor;
  Color scrimColor;

  final _transformLayer = LayerHandle<TransformLayer>();

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsPaint);
    _transformLayer.layer = null;
    super.detach();
  }

  @override
  void dispose() {
    _transformLayer.layer = null;
    super.dispose();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_animation.value < 0.99) return false;
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final t = _animation.value;
    if (t >= 1) {
      _transformLayer.layer = null;
      context.paintChild(child, offset);
      return;
    }
    final canvas = context.canvas;
    if (t > 0) {
      canvas.drawRect(
        offset & size,
        Paint()..color = scrimColor.withValues(alpha: 0.10 * t),
      );
    }
    final from = resolveFrom(size);
    final full = Offset.zero & size;
    final rect = Rect.lerp(from, full, t)!;
    final scale = (rect.width / size.width).clamp(0.05, 1.0);
    final radius = lerpDouble(originRadius, 0, t)!;
    final content = const Interval(0.08, 0.42).transform(t);
    final fill = lostCard() ? content : const Interval(0, 0.12).transform(t);
    if (fill > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.shift(offset), Radius.circular(radius)),
        Paint()
          ..color = originColor.withValues(alpha: originColor.a * fill),
      );
    }
    final matrix = Matrix4.identity()
      ..translateByDouble(rect.left, rect.top, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _transformLayer.layer = context.pushTransform(
      needsCompositing,
      offset,
      matrix,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: _transformLayer.layer,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final t = _animation.value;
    if (t >= 1 || !hasSize) return;
    final from = resolveFrom(size);
    final rect = Rect.lerp(from, Offset.zero & size, t)!;
    final scale = (rect.width / size.width).clamp(0.05, 1.0);
    transform
      ..translateByDouble(rect.left, rect.top, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
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
/// görünür etkisi yoktu. Ağacın şekli değişmez (MediaQuery hep burada);
/// son canlı değer önbellekte tutulduğu için kapanış başında ek `setState`
/// yapılmaz.
class _FrozenWhileClosing extends StatefulWidget {
  const _FrozenWhileClosing({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_FrozenWhileClosing> createState() => _FrozenWhileClosingState();
}

class _FrozenWhileClosingState extends State<_FrozenWhileClosing> {
  MediaQueryData? _lastLive;
  MediaQueryData? _frozen;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    final closing = status == AnimationStatus.reverse;
    noteRouteClosing.value = closing;
    if (closing) {
      // Son canlı MediaQuery ile aynı: yeniden kurulum tetiklemeden dondur.
      _frozen ??= _lastLive;
    } else if (_frozen != null) {
      setState(() => _frozen = null);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    if (noteRouteClosing.value) noteRouteClosing.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = MediaQuery.of(context);
    _lastLive = live;
    return MediaQuery(data: _frozen ?? live, child: widget.child);
  }
}
