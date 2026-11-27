part of 'ink_layer.dart';

/// Bir sayfanın/slaytın üstüne serilen dokunma + çizim katmanı. İçeren
/// widget'ın tüm alanını kaplar (sayfa boyutu [LayoutBuilder]'dan alınır).
/// Bekleyen çizim düzeltmesi (bkz. [InkController.suggestion]).
class InkSuggestion {
  const InkSuggestion({
    required this.kind,
    required this.page,
    required this.anchor,
    required this.originals,
    required this.replacements,
    this.needsConsent = false,
  });

  final InkFixKind kind;
  final int page;

  /// Temiz şeklin sağ alt köşesi (oranlı).
  final Offset anchor;
  final List<InkStroke> originals;
  final List<InkStroke> replacements;

  /// Tik/çarpı ilk kez: önce "otomatik düzeltme açılsın mı" sorulur.
  final bool needsConsent;
}

class InkPageLayer extends StatelessWidget {
  const InkPageLayer({
    super.key,
    required this.controller,
    required this.page,
    this.uniform = false,
  });

  final InkController controller;

  /// y de GENİŞLİĞE oranlanır (kare birim): katmanın boyu değişse de çizim
  /// yerinde kalır, silgi yarıçapı iki eksende aynıdır. Uzayan not sayfası
  /// için (bkz. `PageInkStack`); PDF/görsel sayfasının oranı sabit.
  final bool uniform;

  /// 1 tabanlı sayfa/slayt numarası.
  final int page;

  /// Kalemin basıncı 0–1 aralığında; basınç bildirmeyen girdide null.
  static double? _pressure(PointerEvent e) {
    if (e.kind != PointerDeviceKind.stylus &&
        e.kind != PointerDeviceKind.invertedStylus) {
      return null;
    }
    final range = e.pressureMax - e.pressureMin;
    if (range <= 0) return null;
    return ((e.pressure - e.pressureMin) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Çizim kapalıyken katman dokunmayı hiç görmez.
      ignoring: !controller.editing,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = uniform
              ? Size.square(constraints.maxWidth)
              : Size(constraints.maxWidth, constraints.maxHeight);
          // Kalem HAVADA (S Pen yaklaşması): ucun kalınlığı/silgi halkası
          // önizlenir. Fare de aynı yoldan gelir — onda önizleme yok.
          void onHover(PointerEvent e) {
            if (e.kind != PointerDeviceKind.stylus &&
                e.kind != PointerDeviceKind.invertedStylus) {
              return;
            }
            controller.noteStylus();
            controller.hover.value = (page, e.localPosition);
          }

          void onExit(PointerEvent e) {
            if (controller.hover.value?.$1 == page) {
              controller.hover.value = null;
            }
          }

          final layer = MouseRegion(
            opaque: false,
            // Artı imleç: alttaki metnin "I" imleci kalırsa göz ucuna bakar,
            // tıklama ise ortasından olur — çizgi "biraz yukarıda" çıkıyordu
            // (kullanıcı bulgusu 2026-11-02).
            cursor: SystemMouseCursors.precise,
            onHover: onHover,
            onExit: onExit,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) => controller.pointerDown(
                page,
                e.localPosition,
                size,
                pointer: e.pointer,
                kind: e.kind,
                pressure: _pressure(e),
                stylusEraser:
                    e.kind == PointerDeviceKind.invertedStylus ||
                    e.buttons & kSecondaryStylusButton != 0,
                touchRadius: e.radiusMajor,
              ),
              onPointerMove: (e) => controller.pointerMove(
                page,
                e.localPosition,
                size,
                pointer: e.pointer,
                pressure: _pressure(e),
              ),
              onPointerUp: (e) =>
                  controller.pointerUp(pointer: e.pointer, kind: e.kind),
              onPointerCancel: (e) =>
                  controller.pointerCancel(pointer: e.pointer, kind: e.kind),
              // Yalnız çizgiler değişince yeniden boyanır; görüntüleyici (PDF/slayt)
              // yeniden kurulmaz — bu yüzden çizim sırasında jest bozulmaz.
              // RepaintBoundary: tek bir çizgi uzarken üstteki PDF/slayt
              // katmanının yeniden boyanmasına gerek yok.
              child: RepaintBoundary(
                // F62.1: widget YENİDEN KURULMAZ; iki boyayıcı kendi
                // bildiricisini dinler. Bitmiş çizgiler kendi
                // RepaintBoundary'sinde, yalnız [committedRev] ile boyanır;
                // etkin çizgi + kement/seçim/havadaki uç her harekette.
                child: ValueListenableBuilder<int>(
                  valueListenable: controller.committedRev,
                  builder: (context, _, child) {
                    // Ekran okuyucu (F4.7): tuval kendisi okunamaz; en azından
                    // sayfada çizim olduğu ve kaç çizgi olduğu söylenir.
                    final count = controller.strokesOf(page).length;
                    return Semantics(
                      image: count > 0,
                      label: count == 0 ? null : context.l10n.inkSemantics(count),
                      child: child,
                    );
                  },
                  child: _paintStack(context, size),
                ),
              ),
            ),
          );
          // Düzeltme işaretçisi Listener'ın ÜSTÜNDE: dokunuşu çizime gitmez.
          return Stack(
            clipBehavior: Clip.none,
            children: [
              layer,
              ValueListenableBuilder<InkHoldProgress?>(
                valueListenable: controller.holdProgress,
                builder: (context, h, _) {
                  if (h == null || h.page != page) {
                    return const SizedBox.shrink();
                  }
                  const ring = 44.0;
                  // Parmağın/kalemin ALTINDA kalmasın: noktanın üstünde
                  // (yer yoksa altında).
                  var top = h.at.dy * size.height - ring - 24;
                  if (top < 0) top = h.at.dy * size.height + 24;
                  return Positioned(
                    left: h.at.dx * size.width - ring / 2,
                    top: top,
                    child: HoldProgressRing(
                      restartKey: h.serial,
                      duration: h.duration,
                      size: ring,
                      quietFraction:
                          h.duration == kInkHoldDuration ? 0.25 : 0.0,
                      icon: h.eraser
                          ? Icons.auto_fix_normal_outlined
                          : controller.eraser
                          ? Icons.edit_outlined
                          : Icons.category_outlined,
                    ),
                  );
                },
              ),
              // Silgi ve kalem önerisi TEK dinleyicide (P59): ikisi aynı anda
              // olmaz; ayrı olunca her sayfaya bir öğe daha (S18 bütçesi).
              ListenableBuilder(
                listenable: controller.offers,
                builder: (context, _) {
                  final pen = controller.penOffer.value;
                  final o = pen ?? controller.eraserOffer.value;
                  if (o == null || o.page != page) {
                    // KALEM ↔ SİLGİ HIZLI DÜĞMESİ aynı dinleyicide (S18:
                    // sayfa başına ek öğe yok); basılı tutma önerisi varken
                    // çıkmaz (iniş onu zaten gizler).
                    final q = controller.quickSwap.value;
                    if (q == null || q.page != page) {
                      return const SizedBox.shrink();
                    }
                    final area = Size(
                      constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : size.width,
                      constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : size.height,
                    );
                    final at = q.at != null && q.size == area
                        ? q.at!
                        : inkQuickSwapPlace(q.box, area);
                    return Positioned(
                      left: at.dx,
                      top: at.dy,
                      child: InkQuickSwapButton(
                        shown: q.shown,
                        serial: q.serial,
                        onClaim: controller.claimPointer,
                        onTap: controller.toggleQuickSwap,
                      ),
                    );
                  }
                  const box = 44.0;
                  var left = o.at.dx * size.width - box / 2;
                  var top = o.at.dy * size.height - box - 16;
                  if (constraints.maxWidth.isFinite) {
                    left = left.clamp(0.0, constraints.maxWidth - box);
                  }
                  if (top < 0) top = o.at.dy * size.height + 16;
                  return Positioned(
                    left: left,
                    top: top,
                    child: _EraserOfferButton(
                      toPen: pen != null,
                      onClaim: controller.claimPointer,
                      onAccept: pen != null
                          ? controller.acceptPenOffer
                          : controller.acceptEraserOffer,
                    ),
                  );
                },
              ),
              ValueListenableBuilder<InkSuggestion?>(
                valueListenable: controller.suggestion,
                builder: (context, s, _) {
                  if (s == null || s.page != page) {
                    return const SizedBox.shrink();
                  }
                  const box = 36.0;
                  var left = s.anchor.dx * size.width + 2;
                  var top = s.anchor.dy * size.height + 2;
                  if (constraints.maxWidth.isFinite) {
                    left = left.clamp(0.0, constraints.maxWidth - box);
                  }
                  if (constraints.maxHeight.isFinite) {
                    top = top.clamp(0.0, constraints.maxHeight - box);
                  }
                  return Positioned(
                    left: left,
                    top: top,
                    child: InkFixMarker(
                      suggestion: s,
                      onClaim: controller.claimPointer,
                      onApply: () => _applyWithConsent(context, s),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paintStack(BuildContext context, Size size) {
    final paintSize = uniform ? size : Size.infinite;
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: CommittedInkPainter(controller, page),
            size: paintSize,
          ),
        ),
        CustomPaint(
          painter: ActiveInkPainter(
            controller,
            page,
            Theme.of(context).colorScheme.primary,
          ),
          size: paintSize,
        ),
      ],
    );
    return uniform
        ? OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: size.width,
            maxWidth: size.width,
            minHeight: size.height,
            maxHeight: size.height,
            child: stack,
          )
        // Kare kutudan taşan çizgi de boyanır (kırpılmaz). OverflowBox:
        // Align'la tuval katmanın boyuna sıkışıyordu — kalem kipi kapanınca
        // (sayfa altı boşluğu gidince) çizim dikeyde basılıp yukarı
        // kayıyordu (tablet bulgusu 2026-11-07).
        : stack;
  }

  /// Tik/çarpı ilk kez: "otomatik düzeltme açılsın mı" (varsayılan kapalı).
  Future<void> _applyWithConsent(BuildContext context, InkSuggestion s) async {
    if (!s.needsConsent) {
      controller.applySuggestion();
      return;
    }
    final l10n = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.inkMarkFixAskTitle),
        content: Text(l10n.inkMarkFixAskBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.inkMarkFixAskNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.inkMarkFixAskYes),
          ),
        ],
      ),
    );
    if (yes == null) return;
    InkToolMemory.saveMarkFix(yes);
    if (yes && identical(controller.suggestion.value, s)) {
      controller.applySuggestion();
    } else {
      controller.dismissSuggestion();
    }
  }
}


/// Boştaki saydamlık (yaklaşınca / basınca tam). Net ama yazıyı örtmeyen ton.
const double kInkQuickSwapIdleOpacity = 0.82;

/// Hızlı düğmenin yeri — TEK, BEKLENDİK KURAL (kullanıcı bulgusu
/// 2026-11-19: dört aday arasında sıçrayan düğme "rastgele dolaşıyor",
/// bazen çok uzakta kalıyordu):
/// 1. [previous] varsa ve yeni çizgi düğmeyi örtmüyor, düğmeye
///    [kInkQuickSwapReach] içindeyse düğme YERİNDE kalır (satır boyunca
///    yazarken kıpırdamaz).
/// 2. Yoksa çizgi kutusunun SOL ÜSTÜ (sağ elle yazarken el ve yazı sağ
///    altta kalır); sol kenara sığmazsa yatayda kenara kıstırılır (sağa
///    SIÇRAMAZ); tepeye sığmazsa aynı x'te kutunun altı.
Offset inkQuickSwapPlace(
  Rect stroke,
  Size area, {
  Offset? previous,
  double box = kInkQuickSwapSize,
  double gap = kInkQuickSwapGap,
}) {
  final maxX = math.max(0.0, area.width - box);
  final maxY = math.max(0.0, area.height - box);
  if (previous != null &&
      previous.dx <= maxX &&
      previous.dy <= maxY) {
    final button = previous & Size.square(box);
    if (!button.inflate(gap / 2).overlaps(stroke) &&
        _rectGap(button, stroke) <= kInkQuickSwapReach) {
      return previous;
    }
  }
  final x = (stroke.left - gap - box).clamp(0.0, maxX);
  var y = stroke.top - gap - box;
  if (y < 0) y = stroke.bottom + gap;
  return Offset(x, y.clamp(0.0, maxY));
}

/// İki dikdörtgen arası en kısa uzaklık (örtüşüyorsa 0).
double _rectGap(Rect a, Rect b) {
  final dx = math.max(0.0, math.max(a.left - b.right, b.left - a.right));
  final dy = math.max(0.0, math.max(a.top - b.bottom, b.top - a.bottom));
  return math.sqrt(dx * dx + dy * dy);
}

/// Kalem ↔ silgi hızlı düğmesi (bkz. [InkController.quickSwap]). Net çerçeveli
/// yüzen rozet: kalemdeyken eğik blok silgi, silgideyken vurgulu kalem +
/// etkin mürekkep rengi noktası. [shown] false olunca solar ve dokunuşu
/// geçirir. Kendi [RepaintBoundary]'sinde: solma ve basılma çizim katmanını
/// boyatmaz. Simge yalnız araç değişince ([InkToolMemory.toolRev]) yenilenir.
class InkQuickSwapButton extends StatefulWidget {
  const InkQuickSwapButton({
    super.key,
    required this.shown,
    required this.serial,
    required this.onClaim,
    required this.onTap,
  });

  final bool shown;
  final int serial;
  final ValueChanged<int> onClaim;
  final VoidCallback onTap;

  @override
  State<InkQuickSwapButton> createState() => _InkQuickSwapButtonState();
}

class _InkQuickSwapButtonState extends State<InkQuickSwapButton> {
  bool _near = false;

  /// [kInkQuickSwapIdle] boyunca dokunulmadı: solar (zamanlayıcı bu öğede —
  /// öğe sökülünce iptal olur).
  bool _idle = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _wake();
  }

  @override
  void didUpdateWidget(InkQuickSwapButton old) {
    super.didUpdateWidget(old);
    if (old.serial != widget.serial || (!old.shown && widget.shown)) {
      _idle = false;
      _wake();
    }
  }

  void _wake() {
    _idleTimer?.cancel();
    if (!widget.shown) return;
    _idleTimer = Timer(kInkQuickSwapIdle, () {
      if (mounted) setState(() => _idle = true);
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final l10n = context.l10n;
    final visible = widget.shown && !_idle;
    final opacity = !visible
        ? 0.0
        : (_near ? 1.0 : kInkQuickSwapIdleOpacity);
    return RepaintBoundary(
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          key: const ValueKey('ink-quick-swap'),
          opacity: opacity,
          duration: AppMotion.of(context, AppMotion.short),
          child: ValueListenableBuilder<int>(
            valueListenable: InkToolMemory.toolRev,
            builder: (context, _, _) {
              final erasing = InkToolMemory.eraser;
              final penColor = Color(
                InkToolMemory.color ?? kInkPalette.first.toARGB32(),
              );
              final label = erasing
                  ? l10n.inkQuickSwapToPen
                  : l10n.inkQuickSwapToEraser;
              return Semantics(
                button: true,
                label: label,
                onTap: widget.onTap,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _near = true),
                  onExit: (_) => setState(() => _near = false),
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) {
                      widget.onClaim(e.pointer);
                      setState(() => _near = true);
                      widget.onTap();
                      _wake();
                    },
                    onPointerUp: (_) => setState(() => _near = false),
                    onPointerCancel: (_) => setState(() => _near = false),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: erasing
                            ? scheme.primaryContainer
                            : tokens.card,
                        border: Border.all(
                          color: erasing
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: erasing ? 1.5 : 1,
                        ),
                        boxShadow: AppSurface.floatingShadow(theme),
                      ),
                      child: SizedBox.square(
                        dimension: kInkQuickSwapSize,
                        child: erasing
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    key: const ValueKey('ink-quick-swap-pen'),
                                    size: AppIconSize.m,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                  Positioned(
                                    right: AppSpace.s,
                                    bottom: AppSpace.s,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: penColor,
                                        border: Border.all(
                                          color: scheme.primaryContainer,
                                        ),
                                      ),
                                      child: const SizedBox.square(
                                        dimension: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: EraserGlyph(
                                  key: const ValueKey('ink-quick-swap-eraser'),
                                  color: scheme.onSurface,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Çizginin sağ altındaki küçük düzeltme düğmesi: önerilen şeklin simgesi.
class InkFixMarker extends StatelessWidget {
  const InkFixMarker({
    super.key,
    required this.suggestion,
    required this.onApply,
    this.onClaim,
  });

  final InkSuggestion suggestion;
  final VoidCallback onApply;
  final ValueChanged<int>? onClaim;

  static IconData iconOf(InkFixKind kind) => switch (kind) {
    InkFixKind.line => Icons.horizontal_rule_rounded,
    InkFixKind.arrow => Icons.north_east_rounded,
    InkFixKind.rectangle => Icons.crop_square_rounded,
    InkFixKind.ellipse => Icons.circle_outlined,
    InkFixKind.triangle => Icons.change_history_rounded,
    InkFixKind.quad => Icons.crop_din_rounded,
    InkFixKind.polygon => Icons.pentagon_outlined,
    InkFixKind.tick => Icons.check_rounded,
    InkFixKind.cross => Icons.close_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.l10n.inkFixApply,
      onTap: onApply,
      child: Tooltip(
        message: context.l10n.inkFixApply,
        child: Material(
          key: const ValueKey('ink-fix-marker'),
          color: scheme.primaryContainer,
          shape: const CircleBorder(),
          elevation: 3,
          // Ham işaretçi (Listener): kalemle basış InkWell'in jest
          // yarışmasında üst katmanlara (kaydırma/çizim) kaybediliyordu —
          // kalem modunda tik/onay düğmesi "basmayı algılamıyordu"
          // (kullanıcı bildirimi 2026-11-08). Parmak, kalem, fare aynı yol.
          child: Listener(
            behavior: HitTestBehavior.opaque,
            // İNİŞTE uygula: işaretçi en derinde, olayı çizim katmanından
            // ÖNCE alır; [onClaim] o dokunuşun çizgi başlatmasını engeller.
            onPointerDown: (e) {
              onClaim?.call(e.pointer);
              onApply();
            },
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: SizedBox.square(
                dimension: 36,
                child: Icon(
                  iconOf(suggestion.kind),
                  size: AppIconSize.m,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bitmiş çizgiler (F62.1): yalnız [InkController.committedRev] artınca
/// boyanır — kalem ilerlerken sayfadaki çizgiler yeniden çizilmez.
class CommittedInkPainter extends CustomPainter {
  CommittedInkPainter(this.controller, this.page)
    : super(repaint: controller.committedRev);

  final InkController controller;
  final int page;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in controller.strokesOf(page)) {
      paintInkStroke(canvas, size, s);
    }
  }

  @override
  bool shouldRepaint(CommittedInkPainter old) =>
      !identical(old.controller, controller) || old.page != page;
}

/// Etkin çizgi + kement çizgisi, seçimin çerçevesi ve kalemin havadaki
/// ucunun önizlemesi. Her bildirimde boyanır; işi sayfadaki çizgi
/// sayısından bağımsız (F62.1).
class ActiveInkPainter extends CustomPainter {
  ActiveInkPainter(this.controller, this.page, this.accent)
    : super(repaint: Listenable.merge([controller, controller.hover]));

  final InkController controller;
  final int page;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final active = controller.activeStroke;
    if (active != null && active.page == page) {
      paintInkStroke(canvas, size, active, cache: false);
    }
    final path = controller.lassoPathOn(page);
    final selection = controller.selectionPage == page
        ? controller.selectionBounds
        : null;
    _paintOverlay(canvas, size, path, selection);
  }

  void _paintOverlay(
    Canvas canvas,
    Size size,
    List<double>? path,
    Rect? selection,
  ) {

    if (path != null && path.length >= 4) {
      final p = Path()..moveTo(path[0] * size.width, path[1] * size.height);
      for (var i = 2; i + 1 < path.length; i += 2) {
        p.lineTo(path[i] * size.width, path[i + 1] * size.height);
      }
      canvas
        ..drawPath(p, Paint()..color = accent.withValues(alpha: AppAlpha.hairline))
        ..drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = accent,
        );
    }
    final sel = selection;
    if (sel != null) {
      final rect = Rect.fromLTRB(
        sel.left * size.width,
        sel.top * size.height,
        sel.right * size.width,
        sel.bottom * size.height,
      ).inflate(8);
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()..color = accent.withValues(alpha: 0.06),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = accent,
        )
        // Döndürme tutamağı (üst orta, 2026-11-09).
        ..drawLine(
          rect.topCenter,
          rect.topCenter.translate(0, -InkController.rotateHandleGap + 7),
          Paint()
            ..strokeWidth = 1.5
            ..color = accent,
        )
        ..drawCircle(
          rect.topCenter.translate(0, -InkController.rotateHandleGap),
          7,
          Paint()..color = accent,
        )
        ..drawCircle(
          rect.topCenter.translate(0, -InkController.rotateHandleGap),
          4,
          Paint()..color = const Color(0xFFFFFFFF),
        )
        // Boyut tutamağı (sağ alt).
        ..drawCircle(rect.bottomRight, 7, Paint()..color = accent)
        ..drawCircle(
          rect.bottomRight,
          4,
          Paint()..color = const Color(0xFFFFFFFF),
        );
    }
    final h = controller.hover.value;
    final at = h != null && h.$1 == page ? h.$2 : null;
    if (at != null) {
      if (controller.eraser) {
        canvas.drawCircle(
          at,
          InkController._eraseRadius * size.width,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = accent,
        );
      } else if (!controller.lasso) {
        canvas.drawCircle(
          at,
          math.max(1.5, controller.widthPx / 2),
          Paint()..color = controller.penColor,
        );
      }
    }
  }

  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(ActiveInkPainter old) =>
      !identical(old.controller, controller) ||
      old.page != page ||
      old.accent != accent;
}

