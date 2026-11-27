part of 'dashboard_screen.dart';

/// İki parmak oranından hedef sütun (F39.2): parmaklar açılınca (oran > 1)
/// kartlar büyür, sütun AZALIR. Her adım için parmak arası en az %25 değişir;
/// tek jestte 1 ↔ 4 arası gezilebilir.
int pinchTargetColumns(int base, double ratio) {
  if (ratio <= 0) return base;
  final steps = (math.log(ratio) / math.log(1.25)).truncate();
  return (base - steps).clamp(
    GridColumnsNotifier.minColumns,
    GridColumnsNotifier.maxColumns,
  );
}

/// **İKİ PARMAK ZOOM** (F39.2): jest boyunca ızgara yalnız ölçeklenir (tek
/// `Transform`, `RepaintBoundary` içinde, yerleşim YOK); hedef sütun köşede
/// küçük simgeyle görünür, bırakınca sütun TEK kez değişir + kısa oturma.
/// Ölçüm (v1.1.680): eskiden her adım tam yerleşim, kare 116–247 ms + "N sütun"
/// bildirimi. Ham [Listener]: jest yarışına girmez, tek parmak etkilenmez.
class PinchColumns extends StatefulWidget {
  const PinchColumns({
    super.key,
    required this.child,
    required this.columns,
    required this.onCommit,
  });

  final Widget child;
  final int columns;
  final ValueChanged<int> onCommit;

  @override
  State<PinchColumns> createState() => _PinchColumnsState();
}

class _PinchColumnsState extends State<PinchColumns>
    with SingleTickerProviderStateMixin {
  final _points = <int, Offset>{};
  final _target = ValueNotifier<int?>(null);
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  double _base = 0;
  int _baseColumns = 2;
  Offset _focal = Offset.zero;
  Timer? _hide;
  Timer? _wheelEnd;
  double _wheelRatio = 1;

  @override
  void dispose() {
    _hide?.cancel();
    _wheelEnd?.cancel();
    _target.dispose();
    _scale.dispose();
    super.dispose();
  }

  void _begin(double base, Offset focal) {
    _base = base;
    _baseColumns = widget.columns;
    _focal = focal;
    _hide?.cancel();
  }

  void _move() {
    if (_points.length != 2) return;
    final values = _points.values.toList();
    final distance = (values[0] - values[1]).distance;
    if (_base == 0) {
      if (distance < 24) return; // parmaklar üst üste: oran anlamsız
      _begin(distance, (values[0] + values[1]) / 2);
      return;
    }
    _applyRatio(distance / _base);
  }

  /// Ctrl+tekerlek ve web'de dokunmatik yüzey kıstırması (F44.5). Bir tekerlek
  /// çentiği tek sütun: oran kıstırılır (web `exp(-dy/200)` verir, çentik 2
  /// adım sayılırdı); ince dokunmatik yüzey adımları birikir. Bırakma olayı
  /// olmadığı için kısa sessizlikte biter.
  void _zoomBy(double scale, Offset focal) {
    if (_base == 0) {
      _begin(1, focal);
      _wheelRatio = 1;
    }
    _wheelRatio *= scale.clamp(0.79, 1.27);
    _applyRatio(_wheelRatio);
    _wheelEnd?.cancel();
    _wheelEnd = Timer(const Duration(milliseconds: 180), () {
      if (mounted) _end(commit: true);
    });
  }

  void _onSignal(PointerSignalEvent event) {
    final double scale;
    if (event is PointerScaleEvent) {
      scale = event.scale;
    } else if (event is PointerScrollEvent &&
        HardwareKeyboard.instance.isControlPressed) {
      scale = math.exp(-event.scrollDelta.dy / 200);
    } else {
      return;
    }
    // Resolver: Ctrl+tekerlek aynı anda ızgarayı kaydırmasın.
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => _zoomBy(scale, event.localPosition),
    );
  }

  void _applyRatio(double ratio) {
    // İki parmakla düz kaydırma ızgarayı titretmesin.
    if (motionOf(context) && (ratio - 1).abs() > 0.03) {
      _scale.value = ratio.clamp(0.85, 1.15);
    }
    final target = pinchTargetColumns(_baseColumns, ratio);
    final shown = target == _baseColumns ? null : target;
    if (shown != _target.value) {
      _target.value = shown;
      unawaited(AppHaptics.tick());
    }
  }

  void _end({required bool commit}) {
    if (_base == 0) return;
    _base = 0;
    final target = _target.value;
    final changed = commit && target != null && target != widget.columns;
    if (changed) widget.onCommit(target);
    if (!changed) _target.value = null;
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 700), () {
      _target.value = null;
    });
    if (!motionOf(context)) {
      _scale.value = 1;
      return;
    }
    // Yeni sütunlarla hafif küçük/büyük başlar, yerine oturur.
    if (changed) _scale.value = target < _baseColumns ? 0.97 : 1.03;
    unawaited(
      _scale.animateTo(1, duration: AppMotion.short, curve: AppMotion.standard),
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _points[e.pointer] = e.localPosition;
      _move();
    },
    onPointerMove: (e) {
      if (!_points.containsKey(e.pointer)) return;
      _points[e.pointer] = e.localPosition;
      _move();
    },
    onPointerUp: (e) {
      _points.remove(e.pointer);
      _end(commit: true);
    },
    onPointerCancel: (e) {
      _points.remove(e.pointer);
      _end(commit: false);
    },
    // Dokunmatik yüzey kıstırması (Android/masaüstü), iki parmakla aynı yol.
    onPointerPanZoomStart: (e) => _begin(1, e.localPosition),
    onPointerPanZoomUpdate: (e) => _applyRatio(e.scale),
    onPointerPanZoomEnd: (_) => _end(commit: true),
    onPointerSignal: _onSignal,
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        ClipRect(
          child: AnimatedBuilder(
            animation: _scale,
            builder: (context, child) => Transform(
              transform: Matrix4.diagonal3Values(_scale.value, _scale.value, 1),
              origin: _focal,
              child: child,
            ),
            child: RepaintBoundary(child: widget.child),
          ),
        ),
        PositionedDirectional(
          top: 10,
          end: 10,
          child: IgnorePointer(
            child: ValueListenableBuilder<int?>(
              valueListenable: _target,
              builder: (context, count, _) => count == null
                  ? const SizedBox.shrink()
                  : _ColumnsGlyph(count: count),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Köşedeki kısa sütun simgesi: yazısız, N küçük dikey çubuk.
class _ColumnsGlyph extends StatelessWidget {
  const _ColumnsGlyph({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: context.l10n.gridColumnsCount(count),
      child: DecoratedBox(
        key: ValueKey('pinch-columns-$count'),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: 6,
                  height: 18,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.hair),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tepeden aşağı çekişin göstergesi: ızgaranın üstünde, çekildikçe inen ve
/// dolan küçük klasör dairesi; eşik aşılınca vurgu rengine döner ("bırak →
/// klasörler"). [progress] dp cinsinden çekiş; 0 iken hiç çizilmez.
class FolderPullIndicator extends StatelessWidget {
  const FolderPullIndicator({
    super.key,
    required this.progress,
    required this.distance,
    required this.child,
    this.icon = Icons.folder_outlined,
  });

  final ValueNotifier<double> progress;
  final double distance;
  final Widget child;

  /// Jestin hedefinin simgesi (U1: takvim, not, klasör…).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, pull, _) {
                if (pull <= 0) return const SizedBox.shrink();
                final t = (pull / distance).clamp(0.0, 1.0);
                final ready = pull >= distance;
                final scheme = Theme.of(context).colorScheme;
                return Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, 4 + 28 * t),
                    child: Opacity(
                      opacity: (t * 1.6).clamp(0.0, 1.0),
                      child: AnimatedContainer(
                        key: const ValueKey('folder-pull-indicator'),
                        duration: const Duration(milliseconds: 120),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ready
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black26),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: CircularProgressIndicator(
                                value: t,
                                strokeWidth: 2.5,
                                color: ready
                                    ? scheme.onPrimary
                                    : scheme.primary,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                            Icon(
                              icon,
                              size: AppIconSize.s,
                              color: ready ? scheme.onPrimary : scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// **YANA KAYDIRARAK KLASÖR GEÇİŞİ** (F39.3): ızgara parmağı izler (tek
/// `Transform`, yeni kurulum yok), açılan kenarda sonraki durağın adı; eşik
/// (%22 genişlik ya da hızlı fiske) aşılınca geçer, aşılmazsa yerine döner.
/// Sonraki klasörün kartları BİLEREK çizilmez: jest sırasında ikinci ızgara
/// kurmak kaydırma bütçesini (AKICILIK) aşar; adı yeter.
class FolderSwipe extends StatefulWidget {
  const FolderSwipe({
    super.key,
    required this.enabled,
    required this.nextLabel,
    required this.onCommit,
    required this.child,
    this.nextIcon,
    this.continuesInPlace,
  });

  final bool enabled;

  /// **AKAN GEÇİŞ** (kullanıcı isteği 2026-11-06: "hızlı geçerken takılma
  /// animasyonu güzel his vermiyor"). Geçiş içerik değiştirerek YERİNDE
  /// olacaksa (takvim açmıyorsa) çağrılır, bırakılan konumu genişlik oranı
  /// olarak (fiziksel, işaretli) alır ve true döner: ızgara geri SEKMEZ,
  /// ayrılan görünümü çağıran bu konumdan devam ettirir.
  final bool Function(int direction, double releaseFraction)? continuesInPlace;

  /// Yön (+1 sonraki, -1 önceki) için durağın adı; yoksa null.
  final String? Function(int direction) nextLabel;

  /// Yön için hedefin simgesi (ör. takvim, klasör, tümü).
  final IconData? Function(int direction)? nextIcon;

  final ValueChanged<int> onCommit;
  final Widget child;

  @override
  State<FolderSwipe> createState() => _FolderSwipeState();
}

/// Izgaranın parmağı izleyebileceği en uzak yol ve etiket kartının en geniş
/// hâli (genişlik oranı; düzen oranı, belirteç değil — P62 §6.2).
const _kFollowLimit = 0.42;
const _kLabelWidth = 0.46;

class _FolderSwipeState extends State<FolderSwipe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dx = AnimationController.unbounded(
    vsync: this,
  );
  int _direction = 0;
  String? _label;
  IconData? _icon;
  double _raw = 0;
  bool _past = false;
  double _labelMax = 160;

  /// Geçiş eşiğine ne kadar gelindi (0–1) — etiketteki DOLUM ÇUBUĞU
  /// (kullanıcı isteği 2026-11-09). Ayrı bildirici: her çekiş karesinde
  /// yalnız çubuk boyanır.
  final _progress = ValueNotifier<double>(0);
  Timer? _wheelEnd;

  /// Geçişten sonra süren dokunmatik yüzey ataleti ikinci geçiş sayılmasın.
  bool _wheelQuiet = false;

  @override
  void dispose() {
    _wheelEnd?.cancel();
    _progress.dispose();
    _dx.dispose();
    super.dispose();
  }

  /// Yatay dokunmatik yüzey kaydırması (F44.5): web'de tekerlek olayı gelir,
  /// bırakma yok; çekişle aynı yol, kısa sessizlikte biter.
  void _onSignal(PointerSignalEvent event) {
    if (!widget.enabled || event is! PointerScrollEvent) return;
    final delta = event.scrollDelta;
    if (delta.dx.abs() <= delta.dy.abs() ||
        HardwareKeyboard.instance.isControlPressed) {
      return;
    }
    // Resolver: içteki yatay şerit (klasör çipleri) kaydırırsa o kazanır.
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      _wheelEnd?.cancel();
      _wheelEnd = Timer(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        if (_wheelQuiet) {
          _wheelQuiet = false;
          return;
        }
        _finish(0);
        _wheelQuiet = true;
        _wheelEnd = Timer(const Duration(milliseconds: 240), () {
          _wheelQuiet = false;
        });
      });
      if (!_wheelQuiet) _follow(-delta.dx);
    });
  }

  double get _width => (context.size?.width ?? 1).clamp(1, double.infinity);

  /// Fiziksel çekiş → yön (sağdan sola dillerde ters).
  int _directionOf(double dx) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return (rtl ? dx > 0 : dx < 0) ? 1 : -1;
  }

  void _update(DragUpdateDetails d) => _follow(d.primaryDelta ?? 0);

  /// Eşik sonrası yumuşak lastik direnç: sert duvara çarpmadan akıcı his.
  double _dampedFollow(double raw, double width) {
    final abs = raw.abs();
    final sign = raw.sign;
    if (_label == null) {
      final cap = width * 0.14;
      final d = abs * AppSwipe.rubber;
      return sign * (d / (1 + d / cap));
    }
    final threshold = width * AppSwipe.commitFraction;
    if (abs <= threshold) return raw;
    final excess = abs - threshold;
    final headroom = width * (_kFollowLimit - AppSwipe.commitFraction);
    final softened = headroom * (1 - 1 / (1 + excess / (headroom * 1.4)));
    return sign * (threshold + softened);
  }

  void _follow(double delta) {
    _raw += delta;
    if (_raw == 0) return;
    final width = _width;
    final direction = _directionOf(_raw);
    if (direction != _direction) {
      _direction = direction;
      _labelMax = width * _kLabelWidth;
      final label = widget.nextLabel(direction);
      final icon = label == null ? null : widget.nextIcon?.call(direction);
      setState(() {
        _label = label;
        _icon = icon;
      });
    }
    final follow = _dampedFollow(_raw, width);
    if (motionOf(context)) _dx.value = follow;
    _progress.value = _label == null
        ? 0
        : (_raw.abs() / (width * AppSwipe.commitFraction)).clamp(0.0, 1.0);
    final past =
        _label != null && _raw.abs() >= width * AppSwipe.commitFraction;
    if (past != _past) {
      setState(() => _past = past);
      if (past) unawaited(AppHaptics.tick());
    }
  }

  void _finish(double velocity) {
    final width = _width;
    // Ortak karar kuralı (P62 §6.2): bugünkü `_past || fiske` ile aynı sayı.
    final commit =
        _label != null &&
        AppSwipe.commits(dragged: _raw, extent: width, velocity: velocity);
    // Fiskeyle (eşiği aşmadan) geçiş de aynı hafif titreşimi verir (K3).
    if (commit && !_past) unawaited(AppHaptics.tick());
    final direction = _direction;
    setState(() {
      _label = null;
      _icon = null;
      _past = false;
      _direction = 0;
    });
    _raw = 0;
    _progress.value = 0;
    if (commit &&
        (widget.continuesInPlace?.call(direction, _dx.value / width) ??
            false)) {
      _dx.stop();
      _dx.value = 0;
      widget.onCommit(direction);
      return;
    }
    if (commit) {
      widget.onCommit(direction);
      // Yeni rota (takvim) çekiş yönünden kayarken ızgara geri sekmek yerine
      // yumuşakça sıfırlanır.
      _dx.stop();
      _dx.value = 0;
      return;
    }
    if (_dx.value != 0) {
      // Kalan yolla orantılı oturma (P62 §6.2, K2): kısa çekiş çabuk, hızlı
      // bırakış kopmadan döner; eğri taşmaz.
      unawaited(
        _dx.animateTo(
          0,
          duration: AppSwipe.settleFor(distance: _dx.value, velocity: velocity),
          curve: AppMotion.emphasized,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final forwardEdge = _direction > 0;
    final ink = _past ? scheme.onPrimaryContainer : scheme.onSurface;
    final icon =
        _icon ??
        (forwardEdge ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded);
    return Listener(
      onPointerSignal: _onSignal,
      child: GestureDetector(
        // Yatay çekişle filtreler/klasörler arasında gezin; dikey kaydırma
        // CustomScrollView'de kalır, eksenler farklı olduğundan yarışmaz.
        onHorizontalDragStart: widget.enabled ? (_) => _raw = 0 : null,
        onHorizontalDragUpdate: widget.enabled ? _update : null,
        onHorizontalDragEnd: widget.enabled
            ? (d) => _finish(d.primaryVelocity ?? 0)
            : null,
        onHorizontalDragCancel: widget.enabled ? () => _finish(0) : null,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            AnimatedBuilder(
              animation: _dx,
              builder: (context, child) => Transform.translate(
                offset: Offset(_dx.value, 0),
                child: child,
              ),
              child: widget.child,
            ),
            if (label != null)
              PositionedDirectional(
                top: 0,
                bottom: 0,
                start: forwardEdge ? null : AppSpace.m,
                end: forwardEdge ? AppSpace.m : null,
                child: IgnorePointer(
                  child: Center(
                    // S23/S33 koruması: çekiş sırasında yalnız
                    // ValueListenableBuilder(_progress) yenilenir.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: _labelMax),
                      child: DecoratedBox(
                        key: const ValueKey('swipe-next-label'),
                        decoration: BoxDecoration(
                          color: _past
                              ? scheme.primaryContainer
                              : tokens.card,
                          borderRadius: BorderRadius.circular(AppRadius.l),
                          border: Border.all(
                            color: _past ? scheme.primary : tokens.hairline,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.m,
                            AppSpace.s,
                            AppSpace.m,
                            AppSpace.s,
                          ),
                          child: IntrinsicWidth(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!forwardEdge) ...[
                                      Icon(
                                        icon,
                                        size: AppIconSize.s,
                                        color: _past
                                            ? scheme.primary
                                            : scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: AppSpace.s),
                                    ],
                                    Flexible(
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.of(theme).label.copyWith(
                                          color: ink,
                                          fontWeight: AppWeight.strong,
                                        ),
                                      ),
                                    ),
                                    if (forwardEdge) ...[
                                      const SizedBox(width: AppSpace.s),
                                      Icon(
                                        icon,
                                        size: AppIconSize.s,
                                        color: _past
                                            ? scheme.primary
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppSpace.xs),
                                // DOLUM ÇUBUĞU: dolunca bırakmak geçişi yapar.
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  child: SizedBox(
                                    height: 3,
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: _progress,
                                      builder: (context, p, _) => Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ColoredBox(color: tokens.hairline),
                                          FractionallySizedBox(
                                            key: const ValueKey(
                                              'swipe-progress',
                                            ),
                                            alignment: forwardEdge
                                                ? AlignmentDirectional.centerEnd
                                                : AlignmentDirectional
                                                      .centerStart,
                                            widthFactor: p,
                                            child: ColoredBox(
                                              color: scheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}

/// Ana ekranın sağ alt sütunundaki mikrofon düğmesi: dokunuş doğrudan
/// yazdırır (editörün alt çubuğundaki sade mikrofonla aynı simge), basılı
/// tutmak yapay zekâ ile sesli notu açar.
/// İlk kareden SONRA kurulan çocuk. Ana ekranın ilk karesi bütçeli (S24:
/// soğuk açılışta ilk kare); ikincil düğmeler (⚡ Hızlı ekle) bir kare sonra
/// gelir — 16 ms, gözle görülmez, kartlarla aynı karede.
/// Ana ekranın nötr kare düğmelerinin (mikrofon, ⚡) köşesi — tek yerde.
const _kDashButtonRadius = BorderRadius.all(Radius.circular(14));

