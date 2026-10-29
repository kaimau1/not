import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'split_shell.dart';

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
    double radius = 12,
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
    final narrow = MediaQuery.sizeOf(context).width < kSplitBreakpoint;
    return _NoteOpenRoute<T>(page: this, origin: narrow ? origin : null);
  }
}

class _NoteOpenRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _NoteOpenRoute({required NoteOpenPage<T> page, this.origin})
    : super(settings: page);

  final NoteOpenOrigin? origin;

  NoteOpenPage<T> get _page => settings as NoteOpenPage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Duration get transitionDuration => origin == null
      ? super.transitionDuration
      : const Duration(milliseconds: 460);

  @override
  Duration get reverseTransitionDuration => origin == null
      ? super.reverseTransitionDuration
      : const Duration(milliseconds: 380);

  /// Genişleyen açılışta alttaki liste YERİNDE kalır (yana çekilmez): not
  /// onun üstünde büyür.
  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      origin == null && super.canTransitionFrom(previousRoute);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final origin = this.origin;
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

  @override
  void dispose() {
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
      child: RepaintBoundary(child: widget.child),
    );
  }

  Widget _build(BuildContext context, Widget? page) {
    final size = MediaQuery.sizeOf(context);
    final full = Offset.zero & size;
    final t = _curve.value;
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
    return Stack(
      children: [
        // Alttaki liste hafifçe kararır: derinlik hissi, açılan not öne çıkar.
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.10 * t)),
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
              boxShadow: settled
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.16 * fill * (1 - t),
                        ),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: settled ? Clip.none : Clip.antiAlias,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: size.width,
                maxWidth: size.width,
                minHeight: size.height,
                maxHeight: size.height,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: Opacity(opacity: content, child: page),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
