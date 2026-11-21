import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/theme/app_tokens.dart';
import '../a11y/motion.dart';
import 'app_sheet.dart';
import 'keyboard_snap.dart';

/// Levhanın klavye payı (kullanıcı bulgusu 2026-11-06: "yeni etkinlik butonu
/// basıldığında açılırken ciddi kasma"). KÖK NEDEN: levha `viewInsets`'i
/// KENDİ build'inde okuyordu; klavye animasyonunun her karesinde bütün form
/// yeniden kuruluyordu. Burada yalnız bu ince dolgu yeniden kurulur, [child]
/// aynı örnek olduğundan dokunulmaz.
///
/// [extra] klavye payına eklenen sabit alt boşluktur (eski `16 + inset`
/// kalıbı). [floorViewPadding] doğruysa pay en az gezinme çubuğu kadardır
/// (klavye kapalıyken çubuk levhanın altını örtmesin).
class SheetInsetPadding extends StatelessWidget {
  const SheetInsetPadding({
    super.key,
    required this.child,
    this.extra = 0,
    this.floorViewPadding = false,
  });

  final Widget child;
  final double extra;
  final bool floorViewPadding;

  @override
  Widget build(BuildContext context) {
    var bottom = MediaQuery.viewInsetsOf(context).bottom;
    if (floorViewPadding) {
      bottom = math.max(bottom, MediaQuery.viewPaddingOf(context).bottom);
    }
    return Padding(
      padding: EdgeInsets.only(bottom: bottom + extra),
      child: child,
    );
  }
}

/// [focus]u levhanın/rotanın AÇILIŞ ANİMASYONU BİTİNCE ister. `autofocus`
/// klavyeyi levha kayarken açıyordu: iki animasyon (levha + klavye) aynı
/// karelerde yarışıp arkadaki ekranı her karede yeniden yerleştiriyordu.
/// `initState`ten çağrılır.
void focusAfterRouteOpens(State state, FocusNode focus) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!state.mounted) return;
    final animation = ModalRoute.of(state.context)?.animation;
    if (animation == null || animation.isCompleted) {
      focus.requestFocus();
      return;
    }
    void listener(AnimationStatus s) {
      if (s != AnimationStatus.completed) return;
      animation.removeStatusListener(listener);
      if (state.mounted) focus.requestFocus();
    }

    animation.addStatusListener(listener);
  });
}

/// Klavyeyle YERLEŞİMSİZ (yalnız boyama katmanında) yükselen alt levha
/// (kullanıcı bulgusu 2026-11-20: "klavye bu ekranda açıp kapanırken
/// kasıyor"; envanter K-67, S56).
///
/// `showModalBottomSheet` + [SheetInsetPadding] her klavye karesinde
/// `Padding(bottom: inset)` boyunu değiştirir; `SafeArea`, `BottomSheet`,
/// `Material` yuvarlak köşeleri ve gölge her karede yeniden dizilir — ayrıca
/// Android `onProgress` faz kayması ve API < 35 gezinme çubuğu sıçraması
/// doğrudan levhaya yansır.
///
/// Burada levha tam ekranlık bir [PopupRoute] içinde YALNIZ BİR KEZ dizilir
/// (`viewPadding.bottom` alt payı sabit, `RepaintBoundary` katmanı önbellekte).
/// Klavye açılır/kapanırken yalnız [_RenderSheetLift] boyama ötelemesini
/// günceller (`markNeedsPaint`): 0 widget kurulumu, 0 yerleşim. Android 11+
/// [KeyboardForecast] (kip `k`) varsa levha klavye başlamadan kısa eğriyle
/// hedefe gider/iner; yoksa canlı `viewInsets` (API < 35 düzeltmesiyle)
/// doğrudan boyama ötelemesine gider.
Future<T?> showLiftingSheet<T>({
  required BuildContext context,
  required Widget child,
  BoxConstraints? constraints,
  bool showDragHandle = true,
}) {
  final theme = Theme.of(context);
  final reduced = !motionOf(context);
  final barrier =
      theme.bottomSheetTheme.modalBarrierColor ??
      theme.colorScheme.scrim.withValues(alpha: AppAlpha.scrim);
  final label = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  return Navigator.of(context).push<T>(
    _LiftingSheetRoute<T>(
      child: child,
      constraints: sheetWidthConstraints(constraints),
      showDragHandle: showDragHandle,
      barrierColor: barrier,
      barrierLabel: label,
      reduced: reduced,
    ),
  );
}

class _LiftingSheetRoute<T> extends PopupRoute<T> {
  _LiftingSheetRoute({
    required this.child,
    required this.constraints,
    required this.showDragHandle,
    required this.barrierColor,
    required this.barrierLabel,
    required this.reduced,
  });

  final Widget child;
  final BoxConstraints constraints;
  final bool showDragHandle;
  @override
  final Color barrierColor;
  @override
  final String barrierLabel;
  final bool reduced;

  late final Animatable<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).chain(
    CurveTween(
      curve: reduced ? kAppSheetAnimationReduced.curve! : AppMotion.enter,
    ),
  );

  late final Animatable<Offset> _reverseSlide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).chain(
    CurveTween(
      curve: reduced ? kAppSheetAnimationReduced.curve! : AppMotion.exit,
    ),
  );

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration =>
      reduced ? AppMotion.reduced : AppMotion.medium;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? AppMotion.reduced : AppMotion.short;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _LiftingSheetView(
    constraints: constraints,
    showDragHandle: showDragHandle,
    routeAnimation: animation,
    child: child,
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final pos = animation.status == AnimationStatus.reverse
        ? animation.drive(_reverseSlide)
        : animation.drive(_slide);
    return SlideTransition(position: pos, child: child);
  }
}

class _LiftingSheetView extends StatefulWidget {
  const _LiftingSheetView({
    required this.constraints,
    required this.showDragHandle,
    required this.routeAnimation,
    required this.child,
  });

  final BoxConstraints constraints;
  final bool showDragHandle;
  final Animation<double> routeAnimation;
  final Widget child;

  @override
  State<_LiftingSheetView> createState() => _LiftingSheetViewState();
}

class _LiftingSheetViewState extends State<_LiftingSheetView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _repaint = _LiftNotifier();
  late final AnimationController _forecastAnim = AnimationController.unbounded(
    vsync: this,
  )..addListener(_repaint.bump);
  late final AnimationController _dragAnim = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onDragTick);

  double _liveKb = 0;
  double _nav = 0;
  bool _animating = false;
  double _lastStep = double.infinity;
  bool _useForecast = false;
  bool _closingForecast = false;
  double? _frozenLift;
  double _drag = 0;
  Timer? _settle;
  final _sheetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    KeyboardForecast.next.addListener(_onForecast);
    widget.routeAnimation.addStatusListener(_onRouteStatus);
    didChangeMetrics();
  }

  @override
  void dispose() {
    _settle?.cancel();
    widget.routeAnimation.removeStatusListener(_onRouteStatus);
    KeyboardForecast.next.removeListener(_onForecast);
    WidgetsBinding.instance.removeObserver(this);
    _forecastAnim.dispose();
    _dragAnim.dispose();
    _repaint.dispose();
    super.dispose();
  }

  /// Levha kapanmaya başlayınca (pop) klavye de aynı anda iner; iki dikey
  /// hareket çakışmasın diye yükseltme dondurulur — çıkış yalnız rotanın
  /// [SlideTransition]'ı ile tek eğride akar.
  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _frozenLift ??= _currentLift();
      _forecastAnim.stop();
      _settle?.cancel();
    } else if (status == AnimationStatus.forward) {
      _frozenLift = null;
    }
  }

  void _onDragTick() {
    _drag = _dragAnim.value;
    _repaint.bump();
  }

  void _trackEngine(double live, double nav) {
    final step = live - _liveKb;
    final tail = math.max(0.0, _lastStep);
    final endJump =
        _animating &&
        step >= nav - 1 &&
        step <= nav + 2 * tail + 3 &&
        _lastStep > -nav / 4 &&
        _lastStep < nav / 4 &&
        live > 2 * nav;
    _animating = live > 0 && !endJump;
    _lastStep = step;
  }

  void _animateLiftTo(double target) {
    if (!mounted) return;
    if (!motionOf(context)) {
      _forecastAnim.value = target;
      _repaint.bump();
      return;
    }
    unawaited(
      _forecastAnim.animateTo(
        target,
        duration: AppMotion.instant,
        curve: AppMotion.standard,
      ),
    );
  }

  @override
  void didChangeMetrics() {
    if (_frozenLift != null) return;
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final view = views.first;
    final dpr = view.devicePixelRatio;
    final raw = view.viewInsets.bottom / dpr;
    final nav = view.viewPadding.bottom / dpr;
    _nav = nav;
    if (raw == _liveKb) return;
    final prev = _liveKb;
    final beforeLift = _currentLift();
    _trackEngine(raw, nav);
    _liveKb = raw;
    // Kapanış (köprüden öngörü gelmeden ya da gecikince de): Android'in
    // düzensiz onProgress adımlarını kovalamak yerine kip `k` gibi tek
    // monoton eğriyle 0'a in (kullanıcı bulgusu 2026-11-21: kapanırken kasma).
    if (raw < prev &&
        !_closingForecast &&
        !_forecastAnim.isAnimating &&
        beforeLift > 0) {
      _useForecast = true;
      _closingForecast = true;
      _forecastAnim.value = beforeLift;
      _animateLiftTo(0);
    } else if (raw > prev && _closingForecast) {
      // Kapanırken yeniden açılmaya döndü.
      _closingForecast = false;
      final target = math.max(0.0, raw - nav);
      if (target > _forecastAnim.value) _animateLiftTo(target);
    }
    _settle?.cancel();
    _settle = Timer(AppMotion.quick, () {
      if (!mounted || _frozenLift != null) return;
      _animating = false;
      final settled = math.max(0.0, _liveKb - _nav);
      if (_useForecast &&
          !_forecastAnim.isAnimating &&
          (_forecastAnim.value - settled).abs() > 0.5) {
        _animateLiftTo(settled);
      }
      _repaint.bump();
    });
    if (_currentLift() != beforeLift) _repaint.bump();
  }

  void _onForecast() {
    if (_frozenLift != null) return;
    final f = KeyboardForecast.next.value;
    if (f == null || !mounted) return;
    final cur = _currentLift();
    _useForecast = true;
    _closingForecast = !f.open;
    if (!_forecastAnim.isAnimating) _forecastAnim.value = cur;
    final target = f.open ? math.max(0.0, f.target - _nav) : 0.0;
    _animateLiftTo(target);
    _repaint.bump();
  }

  double _currentLift() {
    if (_frozenLift case final f?) return f;
    final effectiveKb =
        _animating && KeyboardInset.navExcludedWhileAnimating && _liveKb > 0
        ? _liveKb + _nav
        : _liveKb;
    final liveLift = math.max(0.0, effectiveKb - _nav);
    if (!_useForecast) return liveLift;
    final anim = _forecastAnim.value;
    return _closingForecast ? anim : math.max(anim, liveLift);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragAnim.stop();
    _drag = math.max(0.0, _drag + d.delta.dy);
    _repaint.bump();
  }

  void _onDragEnd(DragEndDetails d) {
    final box = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    final h = box?.size.height ?? 240;
    final v = d.primaryVelocity ?? 0;
    if (v > 700 || _drag > h * 0.25) {
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).maybePop();
      return;
    }
    _dragAnim.value = _drag;
    unawaited(
      _dragAnim.animateTo(
        0,
        duration: AppMotion.short,
        curve: AppMotion.enter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bst = theme.bottomSheetTheme;
    final sheetColor =
        bst.modalBackgroundColor ??
        bst.backgroundColor ??
        scheme.surfaceContainerLow;
    final shape =
        bst.shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        );
    final handleColor =
        bst.dragHandleColor ??
        scheme.onSurfaceVariant.withValues(alpha: AppAlpha.disabled);
    // YALNIZ viewPadding okunur: klavye açılıp kapanırken DEĞİŞMEZ (0 kurulum).
    final viewPad = MediaQuery.viewPaddingOf(context);
    return _SheetLiftBox(
      repaint: _repaint,
      lift: _currentLift,
      drag: () => _drag,
      topSafe: viewPad.top,
      skirtColor: sheetColor,
      child: ConstrainedBox(
        constraints: widget.constraints,
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Material(
              key: _sheetKey,
              color: sheetColor,
              surfaceTintColor: Colors.transparent,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.showDragHandle)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.m,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: handleColor,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const SizedBox(
                            width: AppSpace.xxxl,
                            height: AppSpace.xs,
                          ),
                        ),
                      ),
                    ),
                  widget.child,
                  if (viewPad.bottom > 0) SizedBox(height: viewPad.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiftNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

class _SheetLiftBox extends SingleChildRenderObjectWidget {
  const _SheetLiftBox({
    required this.repaint,
    required this.lift,
    required this.drag,
    required this.topSafe,
    required this.skirtColor,
    super.child,
  });

  final Listenable repaint;
  final double Function() lift;
  final double Function() drag;
  final double topSafe;
  final Color skirtColor;

  @override
  _RenderSheetLift createRenderObject(BuildContext context) =>
      _RenderSheetLift(repaint, lift, drag, topSafe, skirtColor);

  @override
  void updateRenderObject(BuildContext context, _RenderSheetLift r) => r
    ..repaint = repaint
    ..lift = lift
    ..drag = drag
    ..topSafe = topSafe
    ..skirtColor = skirtColor;
}

class _RenderSheetLift extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderSheetLift(
    this._repaint,
    this._lift,
    this._drag,
    this._topSafe,
    this._skirtColor,
  );

  Listenable _repaint;
  double Function() _lift;
  double Function() _drag;
  double _topSafe;
  Color _skirtColor;

  set repaint(Listenable v) {
    if (identical(_repaint, v)) return;
    if (attached) _repaint.removeListener(markNeedsPaint);
    _repaint = v;
    if (attached) _repaint.addListener(markNeedsPaint);
  }

  set lift(double Function() v) => _lift = v;
  set drag(double Function() v) => _drag = v;

  set topSafe(double v) {
    if (_topSafe == v) return;
    _topSafe = v;
    markNeedsLayout();
  }

  set skirtColor(Color v) {
    if (_skirtColor == v) return;
    _skirtColor = v;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final c = child;
    if (c != null) {
      final maxH = math.max(0.0, size.height - _topSafe);
      c.layout(
        BoxConstraints(maxWidth: size.width, maxHeight: maxH),
        parentUsesSize: true,
      );
    }
  }

  Offset _childOffset(RenderBox c) {
    final maxLift = math.max(0.0, size.height - _topSafe - c.size.height);
    final lift = _lift().clamp(0.0, maxLift);
    final dx = (size.width - c.size.width) / 2;
    final dy = size.height - c.size.height - lift + _drag();
    return Offset(dx, dy);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    final co = _childOffset(c);
    final paintPos = offset + co;
    final skirtTop = paintPos.dy + c.size.height - 1;
    final skirtBottom = offset.dy + size.height;
    if (skirtBottom > skirtTop) {
      context.canvas.drawRect(
        Rect.fromLTRB(
          paintPos.dx,
          skirtTop,
          paintPos.dx + c.size.width,
          skirtBottom,
        ),
        Paint()..color = _skirtColor,
      );
    }
    context.paintChild(c, paintPos);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    final co = _childOffset(c);
    final local = position - co;
    if (!c.size.contains(local)) return false;
    return result.addWithPaintOffset(
      offset: co,
      position: position,
      hitTest: (r, p) => c.hitTest(r, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final co = _childOffset(child);
    transform.translateByDouble(co.dx, co.dy, 0, 1);
  }
}
