import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/a11y/motion.dart';

/// **YANA ÇEKİŞLE SAYFA DEĞİŞTİRME** (kullanıcı isteği 2026-10-20: "defterde
/// sağa sola kaydırarak sayfa değiştirilebilsin").
///
/// Ham [Listener]: jest yarışına GİRMEZ. Sayfanın içinde metin alanları,
/// madde sürükleme, seçim tutamaçları ve dikey kaydırma var; bir
/// `HorizontalDragGestureRecognizer` onlarla yarışır ve kazandığında imleç
/// sürükleme / seçim bozulurdu. Burada yalnız parmak KALKINCA bakılır: kısa
/// sürede, belirgin biçimde YATAY ve yeterince uzun bir çekiş sayfa çevirir;
/// geri kalan her hareket (yazma, seçme, kaydırma) olduğu gibi akar.
class PageSwipeDetector extends StatefulWidget {
  const PageSwipeDetector({
    super.key,
    required this.child,
    required this.onSwipe,
    this.enabled = true,
  });

  final Widget child;

  /// +1 = sonraki sayfa (sola çekiş, sağdan sola dillerde sağa), -1 = önceki.
  final ValueChanged<int> onSwipe;
  final bool enabled;

  /// Çekişin en az yatay mesafesi (dp) ve en çok süresi.
  static const double minDistance = 72;
  static const Duration maxDuration = Duration(milliseconds: 450);

  @override
  State<PageSwipeDetector> createState() => _PageSwipeDetectorState();
}

class _PageSwipeDetectorState extends State<PageSwipeDetector> {
  int? _pointer;
  Offset _start = Offset.zero;
  Duration _startTime = Duration.zero;
  bool _multi = false;

  void _down(PointerDownEvent e) {
    if (e.kind != PointerDeviceKind.touch) return;
    if (_pointer != null) {
      // İkinci parmak: yakınlaştırma/iki parmak kaydırma — çekiş sayılmaz.
      _multi = true;
      return;
    }
    _pointer = e.pointer;
    _start = e.position;
    _startTime = e.timeStamp;
    _multi = false;
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (_multi || !widget.enabled) return;
    final delta = e.position - _start;
    final elapsed = e.timeStamp - _startTime;
    if (elapsed > PageSwipeDetector.maxDuration) return;
    if (delta.dx.abs() < PageSwipeDetector.minDistance) return;
    if (delta.dx.abs() < delta.dy.abs() * 2.2) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward = rtl ? delta.dx > 0 : delta.dx < 0;
    widget.onSwipe(forward ? 1 : -1);
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) _pointer = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: widget.child,
  );
}

/// **SAYFA ÇEVİRME GÖRÜNÜMÜ** (TEMA_PLANI F33.6): [index] değişince gelen sayfa
/// çevrildiği yandan kayarak girer, kenarında ince gölge; altta kısa süre yarı
/// saydam kâğıt hapı "2 / 5". Hareketi azaltta yalnız solma. Kayan katman
/// `RepaintBoundary`: metin her karede yeniden boyanmaz.
class PageTurn extends StatefulWidget {
  const PageTurn({
    super.key,
    required this.index,
    required this.count,
    required this.child,
  });

  final int index;

  /// 1 ise (sayfasız not) geçiş de hap da yok; ağaç şekli aynı kalır.
  final int count;
  final Widget child;

  @visibleForTesting
  static const pillDuration = Duration(milliseconds: 1400);

  @override
  State<PageTurn> createState() => _PageTurnState();
}

class _PageTurnState extends State<PageTurn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: AppMotion.enter,
  );
  late final Animation<double> _fade = Tween<double>(begin: 0.4, end: 1).animate(_t);
  double _dir = 0;
  bool _pill = false;
  Timer? _pillTimer;

  @override
  void didUpdateWidget(PageTurn old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index || widget.count <= 1) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    _dir = !motionOf(context)
        ? 0
        : (widget.index > old.index ? 1.0 : -1.0) * (rtl ? -1 : 1);
    _c.duration = AppMotion.of(context, AppMotion.medium);
    unawaited(_c.forward(from: 0));
    _pill = true;
    _pillTimer?.cancel();
    _pillTimer = Timer(PageTurn.pillDuration, () {
      if (mounted) setState(() => _pill = false);
    });
  }

  @override
  void dispose() {
    _pillTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        AnimatedBuilder(
          animation: _t,
          builder: (context, child) {
            final dx = _dir * (1 - _t.value) * 28;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Stack(
                fit: StackFit.passthrough,
                clipBehavior: Clip.none,
                children: [
                  child!,
                  if (_c.isAnimating && _dir != 0)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: _dir > 0 ? -8 : null,
                      right: _dir < 0 ? -8 : null,
                      width: 8,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: _dir > 0
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              end: _dir > 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              colors: [
                                scheme.onSurface.withValues(
                                  alpha: 0.14 * (1 - _t.value),
                                ),
                                scheme.onSurface.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          child: FadeTransition(
            opacity: _fade,
            child: RepaintBoundary(child: widget.child),
          ),
        ),
        if (widget.count > 1)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 16,
            child: IgnorePointer(
              // Üstteki sayfa çubuğu aynı bilgiyi okuyor.
              child: ExcludeSemantics(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _pill ? 1 : 0,
                    duration: AppMotion.short,
                    curve: AppMotion.standard,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.card.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tokens.hairline),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: Text(
                          '${widget.index + 1} / ${widget.count}',
                          key: const ValueKey('page-pill'),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurface),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
