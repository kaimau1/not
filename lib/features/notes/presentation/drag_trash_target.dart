import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_ext.dart';

/// **Sürüklerken çöp kutusu** (F60.S9, kullanıcı 2026-11-11): ana ekranda
/// bir not kartı sürüklenirken ekranın altında beliren bırakma hedefi.
///
/// Kart hedefin üstüne gelince [armDelay] boyunca dairesel bir dolum çizilir
/// ve hedef hafifçe büyür; dolum bitince titreşim verilir ve hedef "silmeye
/// hazır" olur. Ancak o hâldeyken bırakılan not [onTrash]'e gider. Dolum
/// bitmeden bırakılır ya da hedeften çıkılırsa hiçbir şey olmaz.
///
/// AKICILIK (kasma listesi 4 ve 6): hedef HER ZAMAN ağaçtadır; görünme,
/// büyüme ve dolum yalnız BOYAMA düzeyinde (kaydırma/solma/ölçek dönüşümü,
/// [CustomPaint]) — yerleşim hiç değişmez, ana ekran yeniden kurulmaz.
class DragTrashTarget extends StatefulWidget {
  const DragTrashTarget({
    super.key,
    required this.active,
    required this.onTrash,
  });

  /// Bir kart sürükleniyor mu? Hedef buna göre kayarak belirir/kaybolur.
  final bool active;

  /// "Silmeye hazır" hedefe bırakılan notun kimliği.
  final void Function(String noteId) onTrash;

  /// Hedefin üstünde bekleme süresi (dolum).
  static const armDelay = Duration(milliseconds: 600);

  @override
  State<DragTrashTarget> createState() => _DragTrashTargetState();
}

class _DragTrashTargetState extends State<DragTrashTarget>
    with TickerProviderStateMixin {
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: widget.active ? 1 : 0,
  );
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: DragTrashTarget.armDelay,
  )..addStatusListener(_onFillStatus);

  /// Bırakılınca kısa "yutma" hareketi (kapak sallanır, hedef küçülür).
  // Bir kez kurulur (her build'de yeni CurvedAnimation dinleyici bırakır).
  late final Animation<double> _curved = CurvedAnimation(
    parent: _show,
    curve: Curves.easeOutCubic,
  );
  late final AnimationController _gulp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  /// Dolum bitti: bırakılırsa çöpe gider. Yalnız etiket bunu dinler.
  final ValueNotifier<bool> _armed = ValueNotifier(false);

  void _onFillStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _armed.value = true;
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void didUpdateWidget(DragTrashTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _reset();
      _show.forward();
    } else if (!_gulp.isAnimating) {
      _show.reverse();
    }
  }

  void _reset() {
    _fill.reset();
    _hover.reverse();
    _armed.value = false;
  }

  @override
  void dispose() {
    (_curved as CurvedAnimation).dispose();
    _show.dispose();
    _hover.dispose();
    _fill.dispose();
    _gulp.dispose();
    _armed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    // Büyüme: üstüne gelince 1,12; yutarken 0,85'e iner ve geri döner.
    final scale = Listenable.merge([_hover, _gulp]);
    return IgnorePointer(
      ignoring: !widget.active,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.8),
          end: Offset.zero,
        ).animate(_curved),
        child: FadeTransition(
          opacity: _curved,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (_) {
              if (!widget.active) return false;
              _hover.forward();
              _armed.value = false;
              _fill.forward(from: 0);
              return true;
            },
            onLeave: (_) => _reset(),
            onAcceptWithDetails: (details) {
              final ready = _fill.isCompleted;
              _reset();
              if (!ready) return;
              _gulp.forward(from: 0).whenCompleteOrCancel(() {
                if (mounted && !widget.active) _show.reverse();
              });
              widget.onTrash(details.data);
            },
            builder: (context, candidate, rejected) => Semantics(
              label: l10n.dragTrashHint,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: scale,
                    builder: (context, child) {
                      final g = _gulp.value;
                      final gulp = g == 0
                          ? 1.0
                          : 1 - 0.15 * math.sin(g * math.pi);
                      return Transform.scale(
                        scale: (1 + 0.12 * _hover.value) * gulp,
                        child: child,
                      );
                    },
                    child: SizedBox.square(
                      dimension: 68,
                      child: CustomPaint(
                        painter: _TrashRingPainter(
                          fill: _fill,
                          base: scheme.surfaceContainerHighest,
                          ring: scheme.error,
                          armedBase: scheme.errorContainer,
                          shadow: scheme.shadow,
                        ),
                        child: Center(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _armed,
                            builder: (context, armed, _) => Icon(
                              armed
                                  ? Icons.delete_forever_rounded
                                  : Icons.delete_outline_rounded,
                              size: 30,
                              color: armed
                                  ? scheme.onErrorContainer
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.92,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _armed,
                        builder: (context, armed, _) => Text(
                          armed ? l10n.dragTrashReady : l10n.dragTrashHint,
                          style: Theme.of(context).textTheme.labelMedium,
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
    );
  }
}

/// Hedef dairesi + dolum halkası. YALNIZ boyar; dolum [fill] ile tetiklenir.
class _TrashRingPainter extends CustomPainter {
  _TrashRingPainter({
    required this.fill,
    required this.base,
    required this.ring,
    required this.armedBase,
    required this.shadow,
  }) : super(repaint: fill);

  final Animation<double> fill;
  final Color base;
  final Color ring;
  final Color armedBase;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final t = fill.value;
    canvas.drawCircle(
      c + const Offset(0, 3),
      r - 2,
      Paint()
        ..color = shadow.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      c,
      r - 2,
      Paint()..color = Color.lerp(base, armedBase, t >= 1 ? 1 : t * 0.4)!,
    );
    if (t <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 4),
      -math.pi / 2,
      2 * math.pi * t,
      false,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TrashRingPainter old) =>
      old.fill != fill ||
      old.base != base ||
      old.ring != ring ||
      old.armedBase != armedBase ||
      old.shadow != shadow;
}
