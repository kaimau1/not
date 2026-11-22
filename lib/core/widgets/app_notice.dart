import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/theme/app_design.dart';
import '../../app/theme/app_tokens.dart';
import 'undo_snackbar.dart' show snackBarBottomObstacle;

/// Geçici bildirimin türü — sırayı ve dokunuş davranışını belirler.
enum AppNoticeKind {
  /// Bir kez çıkan ipucu. Yalnız şerit BOŞKEN çıkar (başka bildirimin önüne
  /// geçmez), dokunuşu ENGELLEMEZ, ekrana ilk dokunuşta kalkar.
  tip,

  /// Acelesi olmayan duyuru ("Yenilikler"). Şerit boşalana dek BEKLER.
  announce,

  /// Az önce olan şeyin iletisi (kaydedildi, silindi + Geri al, hata).
  /// EN YENİ KAZANIR: görünen bildirimin yerine geçer.
  message,
}

/// Tek bir geçici bildirim.
@immutable
class AppNoticeData {
  const AppNoticeData({
    required this.text,
    this.kind = AppNoticeKind.message,
    this.details = const [],
    this.icon,
    this.actionLabel,
    this.onAction,
    this.duration = const Duration(seconds: 4),
  }) : assert((actionLabel == null) == (onAction == null));

  final String text;
  final AppNoticeKind kind;

  /// Başlığın altındaki kısa satırlar (duyuru maddeleri).
  final List<String> details;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
}

/// **BİLDİRİM ŞERİDİ** (P62 ortak dil, docs/plan_tasarim_A.md §5): ipucu,
/// ileti, "Geri al" ve duyuruların TEK kapısı. Aynı anda EN ÇOK BİR bildirim
/// görünür; kurallar [AppNoticeKind]'da.
///
/// Çizen: [AppNoticeHost] (`app.dart`ta, uygulamanın tepesinde tek tane).
/// Eski yollar (`TipOnce.show`, `showMessage`, `showUndoSnackBar`) şerit
/// ağaçtayken buraya akar; `timedSnackBar` görüneni kapatır (P62 PA5).
class AppNoticeController extends ChangeNotifier {
  AppNoticeData? _current;
  final _waiting = Queue<AppNoticeData>();
  Timer? _timer;

  AppNoticeData? get current => _current;

  /// Bildirimi gösterir ya da sıraya alır. false = gösterilmedi (ipucu,
  /// şerit doluydu) — çağıran ipucunu "gösterildi" SAYMAZ.
  bool show(AppNoticeData data) {
    final shown = _current;
    switch (data.kind) {
      case AppNoticeKind.tip:
        if (shown != null) return false;
      case AppNoticeKind.announce:
        if (shown != null) {
          _waiting.add(data);
          return true;
        }
      case AppNoticeKind.message:
        // Yarıda kesilen duyuru kaybolmaz: sıranın başına döner.
        if (shown != null && shown.kind == AppNoticeKind.announce) {
          _waiting.addFirst(shown);
        }
    }
    _set(data);
    return true;
  }

  /// Görünen bildirimi kaldırır (sırada bekleyen varsa o gelir). [only]
  /// verilirse yalnız o bildirim görünüyorsa/bekliyorsa.
  void dismiss([AppNoticeData? only]) {
    if (only != null && !identical(only, _current)) {
      _waiting.remove(only);
      return;
    }
    if (_current == null) return;
    _set(_waiting.isEmpty ? null : _waiting.removeFirst());
  }

  /// Şerit ([AppNoticeHost]) ağaçta mı? Yokken (yalın widget testi) çağıran
  /// eski SnackBar yoluna düşer — ileti sessizce kaybolmaz. Dinleyici sayısı
  /// DEĞİL (ertelenen ipucu da dinler — bkz. TipOnce.show), şerit sayısı.
  bool get hosted => _hosts > 0;
  int _hosts = 0;

  /// Görüneni ve sırayı siler. Şerit sökülürken çağrılır: bekleyen
  /// zamanlayıcı kalmaz (testte "Timer is still pending").
  void clear() {
    _waiting.clear();
    if (_current != null) _set(null);
  }

  void _set(AppNoticeData? data) {
    _timer?.cancel();
    _current = data;
    _timer = data == null ? null : Timer(data.duration, dismiss);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Uygulamanın tek bildirim şeridi.
final appNotice = AppNoticeController();

/// **ÜST KROMUN BOYU** (dp, güvenli alan hariç): ipucu bunun ALTINDA çıkar,
/// üst çubuğu / arama hapını örtmez. Üst kromu standart çubuktan uzun ya da
/// kısa olan ekran (ör. tam ekran görüntüleyici: 0) açılırken yazar,
/// kapanırken [kToolbarHeight]'a döndürür. Dinlenmez; ipucu kurulurken okunur.
final noticeTopInset = ValueNotifier<double>(kToolbarHeight);

/// [child]'ın (Navigator) üstünde bildirimleri çizer; levha/diyalog da
/// altında kalır. İki yer, aynı anda yalnız BİRİ dolu:
///  * ipucu ÜSTTE, üst kromun ([noticeTopInset]) altında (kullanıcı bulgusu
///    2026-11-08: alttaki ipucu düğmeleri kapatıyordu);
///  * ileti / duyuru DİPTE, klavyenin ve dibe yapışık panelin
///    ([snackBarBottomObstacle]) üstünde, alt-BAŞ köşede; GENİŞ pencerede
///    ([wideBreakpoint]) alt-SON köşede (KW-5: başta sol raydaki düğmeleri
///    ve bölünmüş görünümde liste bölmesini örtüyordu; son köşe hep içerik).
/// En çok [maxWidth] genişlikte.
///
/// **YÜZEN DÜĞME BÖLGESİ**: ekranın alt-SON köşesindeki [fabReserve] ×
/// [fabRow] dp'lik alana (ana ekranın mikrofon / "+" / yapay zekâ satırı,
/// öbür ekranların "+"sı) hiçbir bildirim GİRMEZ: ileti o bölgenin YANINDA
/// durur, geniş içerikli duyuru ([AppNoticeData.details]) ÜSTÜNDE.
///
/// [child] bu widget yüzünden yeniden KURULMAZ: bildirim değişince yalnız
/// şerit kurulur (kasma listesi madde 3, 7).
class AppNoticeHost extends StatefulWidget {
  const AppNoticeHost({super.key, required this.child, this.controller});

  final Widget child;

  /// Varsayılan [appNotice].
  final AppNoticeController? controller;

  static const double maxWidth = 480;

  /// Bu genişlikten itibaren dip şeridi alt-SON köşede (= `kRailBreakpoint`:
  /// ray ve liste bölmesi baş tarafta).
  static const double wideBreakpoint = 600;

  /// Yüzen düğme bölgesinin eni (ekranın son kenarından) ve boyu (dipten,
  /// güvenli alan hariç): 56 dp düğme + 16 dp kenar.
  static const double fabReserve = 144;
  static const double fabRow = 72;

  @override
  State<AppNoticeHost> createState() => _AppNoticeHostState();
}

class _AppNoticeHostState extends State<AppNoticeHost> {
  AppNoticeController get _controller => widget.controller ?? appNotice;

  @override
  void initState() {
    super.initState();
    _controller._hosts++;
  }

  @override
  void dispose() {
    _controller._hosts--;
    _controller.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      _NoticeLane(controller: _controller, top: true),
      _NoticeLane(controller: _controller, top: false),
    ],
  );
}

class _NoticeLane extends StatelessWidget {
  const _NoticeLane({required this.controller, required this.top});

  final AppNoticeController controller;

  /// true = ipucu şeridi (üstte); false = ileti şeridi (dipte).
  final bool top;

  @override
  Widget build(BuildContext context) {
    // Şerit BOŞKEN pencere ENİ dışında MediaQuery okunmaz (R5, S31 klavye_karesi_kurulum): güvenli
    // alan / klavye payını görünen KART kendisi okur. Tam ekran Align dokunuş
    // yakalamaz (çocuğu yokken isabet yok).
    return Positioned.fill(
      left: AppSpace.m,
      right: AppSpace.m,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final shown = controller.current;
          final data = shown != null && (shown.kind == AppNoticeKind.tip) == top
              ? shown
              : null;
          // Yalnız GENİŞLİK okunur (`sizeOf`; klavye/güvenli alan değişince
          // şerit kurulmaz). Çıkan kart da aynı köşede kalsın diye boşken de.
          final AlignmentGeometry align = top
              ? Alignment.topCenter
              : MediaQuery.sizeOf(context).width >=
                        AppNoticeHost.wideBreakpoint
              ? AlignmentDirectional.bottomEnd
              : AlignmentDirectional.bottomStart;
          final enter = AppMotion.of(context, AppMotion.short);
          return Align(
            alignment: align,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppNoticeHost.maxWidth,
              ),
              child: AnimatedSwitcher(
                duration: enter,
                reverseDuration: AppMotion.exitOf(enter),
                switchInCurve: AppMotion.curveOf(context, AppMotion.enter),
                switchOutCurve: AppMotion.curveOf(context, AppMotion.exit),
                // Yalnız boyama: solma + kendi boyunun dörtte biri kadar kayma.
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(0, top ? -0.25 : 0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                // Çıkan ve giren bildirim aynı köşeye yaslı (varsayılan orta:
                // dar ileti çıkarken ortaya zıplardı).
                layoutBuilder: (current, previous) =>
                    Stack(alignment: align, children: [...previous, ?current]),
                child: data == null
                    ? const SizedBox.shrink()
                    : _NoticeCard(
                        key: ObjectKey(data),
                        data: data,
                        controller: controller,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoticeCard extends StatefulWidget {
  const _NoticeCard({super.key, required this.data, required this.controller});

  final AppNoticeData data;
  final AppNoticeController controller;

  @override
  State<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<_NoticeCard> {
  bool get _tip => widget.data.kind == AppNoticeKind.tip;

  @override
  void initState() {
    super.initState();
    // İpucu ekranın HERHANGİ bir yerine ilk dokunuşta kalkar; dokunuşu
    // tüketmez (alttaki düğme yine çalışır) — bkz. tips.dart, 2026-11-09.
    if (_tip) GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  // ── Kolay kapanış: dokun ya da yana / aşağı it ─────────────────────────
  final _drag = ValueNotifier<Offset>(Offset.zero);
  bool _gone = false;

  /// Bu kadar itiş (dp) ya da bu hız (dp/sn) kapatır.
  static const double _distance = 56;
  static const double _speed = 400;

  late final List<GestureRecognizer> _recognizers = [
    TapGestureRecognizer(debugOwner: this)..onTap = _dismissByHand,
    HorizontalDragGestureRecognizer(debugOwner: this)
      ..onUpdate = (d) {
        _drag.value = Offset(_drag.value.dx + d.delta.dx, 0);
      }
      ..onEnd = (d) => _dragEnd(d.velocity, horizontal: true),
    VerticalDragGestureRecognizer(debugOwner: this)
      ..onUpdate = (d) {
        _drag.value = Offset(0, math.max(0, _drag.value.dy + d.delta.dy));
      }
      ..onEnd = (d) => _dragEnd(d.velocity, horizontal: false),
  ];

  void _dismissByHand() {
    if (_gone) return;
    _gone = true;
    widget.controller.dismiss(widget.data);
  }

  void _dragEnd(Velocity velocity, {required bool horizontal}) {
    final o = _drag.value;
    final v = velocity.pixelsPerSecond;
    final far = horizontal ? o.dx.abs() > _distance : o.dy > _distance * 0.6;
    final fast = horizontal ? v.dx.abs() > _speed : v.dy > _speed;
    if (far || fast) {
      _dismissByHand();
    } else {
      _drag.value = Offset.zero;
    }
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) widget.controller.dismiss(widget.data);
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _drag.dispose();
    if (_tip) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final data = widget.data;
    // TASARIM BİRLİĞİ (kullanıcı bulgusu 2026-11-22: "tost bildirimler çok
    // yüksek, renkli, farklı; daha kibar olmalı"): koyu ters renkli kart
    // yerine kalem kapsülü/levhalarla aynı yüzen yüzey (açık ton, ince
    // çizgi, bulanıksız gölge), alçak satır, eylem `primary`.
    final ink = scheme.onSurface;
    final icon = data.icon ?? (_tip ? Icons.lightbulb_outline : null);
    // Navigator'ın ÜSTÜNDE Material atası yok: yazı varsayılanı (sarı alt
    // çizgi) ve düğme mürekkebi için saydam Material.
    final card = Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: AppSurface.floating(theme, radius: AppRadius.l),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: AppSpace.l,
                    end: data.actionLabel == null ? AppSpace.l : AppSpace.xxs,
                    top: AppSpace.xxs,
                    bottom: AppSpace.xxs,
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: AppIconSize.s,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: AppSpace.s),
                      ],
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.xs,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.text,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    (data.details.isEmpty
                                            ? text.body
                                            : text.label)
                                        .copyWith(color: ink),
                              ),
                              for (final line in data.details)
                                Text(
                                  '• $line',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.body.copyWith(color: ink),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (data.actionLabel != null)
                        TextButton(
                          key: const ValueKey('notice-action'),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                            visualDensity: VisualDensity.compact,
                            textStyle: text.label.copyWith(
                              fontWeight: AppWeight.strong,
                            ),
                          ),
                          onPressed: () {
                            widget.controller.dismiss(data);
                            data.onAction!();
                          },
                          child: Text(data.actionLabel!),
                        ),
                    ],
                  ),
                ),
                // Kalan süre: eylemli bildirimde dipte incelen çizgi (kullanıcı
                // bulgusu 2026-10-17). Yalnız boyama (ölçek), dizilim yok.
                if (data.actionLabel != null)
                  SteppedCountdown(
                    key: const ValueKey('notice-countdown'),
                    duration: data.duration,
                    color: scheme.primary.withValues(alpha: AppAlpha.muted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (_tip) {
      return Padding(
        padding: EdgeInsets.only(
          top:
              MediaQuery.paddingOf(context).top +
              noticeTopInset.value +
              AppSpace.s,
        ),
        child: IgnorePointer(child: card),
      );
    }
    // Engel yüksekliği bildirim KURULURKEN okunur (dinlenmez: değer
    // dizilim sırasında yazılıyor — bkz. snackBarBottomObstacle).
    final lift = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      snackBarBottomObstacle.value,
    );
    // Yüzen düğme bölgesi (bkz. AppNoticeHost): ileti YANINDA, duyuru
    // ÜSTÜNDE. Pay kartla birlikte gider (çıkarken yeri değişmez).
    final wide = data.details.isNotEmpty;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        end: wide ? 0 : AppNoticeHost.fabReserve - AppSpace.m,
        bottom:
            lift +
            MediaQuery.paddingOf(context).bottom +
            AppSpace.m +
            (wide ? AppNoticeHost.fabRow : 0),
      ),
      // KOLAY KAPANIŞ (kullanıcı bulgusu 2026-11-16: "bildirimleri kapatmak
      // zor, bayağı kapanmıyor"): karta dokunmak ya da yana / aşağı itmek
      // kapatır; eylem düğmesi kendi dokunuşunu alır (iç düğme kazanır).
      // Kurulum bütçesi (S31): tek boyama nesnesi hem kaydırır hem
      // dokunuşu tanır; kayarken hiçbir widget kurulmaz.
      child: _DragPaint(
        key: const ValueKey('notice-swipe'),
        offset: _drag,
        recognizers: _recognizers,
        child: card,
      ),
    );
  }
}

/// Çocuğunu [offset] kadar kaydırıp itiş arttıkça soldurur — yalnız
/// BOYAMA ve isabet testi; kayarken hiçbir widget kurulmaz (S31 bütçesi).
class _DragPaint extends SingleChildRenderObjectWidget {
  const _DragPaint({
    super.key,
    required this.offset,
    required this.recognizers,
    super.child,
  });

  final ValueNotifier<Offset> offset;

  /// Karta inen her parmak bunlara verilir (iç düğme arenada kazanır).
  final List<GestureRecognizer> recognizers;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDragPaint(offset)..recognizers = recognizers;

  @override
  void updateRenderObject(BuildContext context, _RenderDragPaint render) =>
      render
        ..offset = offset
        ..recognizers = recognizers;
}

class _RenderDragPaint extends RenderProxyBox {
  _RenderDragPaint(this._offset);

  List<GestureRecognizer> recognizers = const [];

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is! PointerDownEvent) return;
    for (final r in recognizers) {
      r.addPointer(event);
    }
  }

  ValueNotifier<Offset> _offset;
  set offset(ValueNotifier<Offset> value) {
    if (identical(value, _offset)) return;
    if (attached) {
      _offset.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _offset = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: _offset.value,
        position: position,
        hitTest: (result, p) => super.hitTestChildren(result, position: p),
      );

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final o = _offset.value;
    final alpha = (255 * (1 - (o.dx.abs() + o.dy) / 240).clamp(0.2, 1.0))
        .round();
    layer = context.pushOpacity(
      offset + o,
      alpha,
      (context, at) => context.paintChild(child, at),
      oldLayer: layer as OpacityLayer?,
    );
  }
}

/// **GERİ SAYIM ÇİZGİSİ** — tek [AnimationController], doğrusal, kesintisiz.
///
/// Geçmiş: (1) `TweenAnimationBuilder` her karede alt ağacı YENİDEN KURUYORDU
/// (kullanıcı bulgusu 2026-11-16: "bildirim varken kasma var"); (2) çare
/// olarak çizgi saniyede 8 adıma indirildi — ama `Timer.periodic` vsync'e
/// bağlı değil, adımlar düzensiz düştü ve çizgi gözle "takılarak" ilerledi
/// (kullanıcı bulgusu U5, 2026-11-18). Şimdi: denetleyici her karede yalnız
/// ressamı boyatır ([CustomPainter] `repaint:`), HİÇBİR widget yeniden
/// kurulmaz; çizgi kendi [RepaintBoundary] katmanında, sahnenin geri kalanı
/// önbellekten birleşir. Uygulama arka plandayken [TickerMode] durdurur.
class SteppedCountdown extends StatefulWidget {
  const SteppedCountdown({
    super.key,
    required this.duration,
    required this.color,
    this.height = AppSpace.xxs,
    this.onEnd,
    this.trackColor,
    this.radius = 0,
  });

  final Duration duration;
  final Color color;
  final double height;

  /// Süre bitince bir kez çağrılır (bildirimi/paneli kapatmak için).
  final VoidCallback? onEnd;

  /// Verilirse çubuğun boş kısmı bu renkte çizilir (ilerleme izi).
  final Color? trackColor;

  /// Köşe yarıçapı (iz ve dolgu).
  final double radius;

  @override
  State<SteppedCountdown> createState() => _SteppedCountdownState();
}

class _SteppedCountdownState extends State<SteppedCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onEnd?.call();
      });
    if (widget.duration <= Duration.zero) {
      _run.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onEnd?.call();
      });
    } else {
      _run.forward();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size(double.infinity, widget.height),
      painter: CountdownPainter(
        _run,
        widget.color,
        Directionality.of(context),
        track: widget.trackColor,
        radius: widget.radius,
      ),
    ),
  );
}

class CountdownPainter extends CustomPainter {
  CountdownPainter(
    this.elapsed,
    this.color,
    this.direction, {
    this.track,
    this.radius = 0,
  }) : super(repaint: elapsed);

  /// Geçen süre oranı (0 → 1).
  final Animation<double> elapsed;

  /// Kalan oran (1 → 0); çizginin dolu kısmı.
  @visibleForTesting
  double get remaining => 1 - elapsed.value;
  final Color color;
  final TextDirection direction;
  final Color? track;
  final double radius;

  void _bar(Canvas canvas, Rect r, Color c) {
    final paint = Paint()..color = c;
    if (radius <= 0) {
      canvas.drawRect(r, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(radius)),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (track != null) _bar(canvas, Offset.zero & size, track!);
    final w = size.width * remaining;
    if (w <= 0) return;
    final x = direction == TextDirection.rtl ? size.width - w : 0.0;
    _bar(canvas, Rect.fromLTWH(x, 0, w, size.height), color);
  }

  @override
  bool shouldRepaint(CountdownPainter old) =>
      old.color != color ||
      old.direction != direction ||
      old.elapsed != elapsed ||
      old.track != track ||
      old.radius != radius;
}
