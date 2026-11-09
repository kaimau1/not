import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// **JEST DOLUM HALKASI** (kullanıcı isteği 2026-11-09: "jestler için ilk
/// algılanıp yapılana kadar dolum çubuğu olsun"): basılı tutma jesti
/// algılandığı andan iş yapılana dek dolan halka. Dolum [duration]da biter
/// — çağıranın zamanlayıcısıyla aynı süre verilmeli. [restartKey] değişince
/// baştan dolar.
///
/// İlk [quietFraction] kadarı ÇİZİLMEZ: parmak/kalem hareket ettikçe jest
/// sürekli yeniden kuruluyor (ör. çizerken "şekle oturt" beklemesi); halka
/// yalnız gerçekten durulunca görünür, çizim sırasında titremez.
class HoldProgressRing extends StatelessWidget {
  const HoldProgressRing({
    super.key,
    required this.restartKey,
    required this.duration,
    this.size = 40,
    this.color,
    this.icon,
    this.quietFraction = 0.25,
  });

  final Object restartKey;
  final Duration duration;
  final double size;
  final Color? color;
  final IconData? icon;
  final double quietFraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(restartKey),
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        builder: (context, t, _) {
          if (t < quietFraction) return SizedBox.square(dimension: size);
          final shown = ((t - quietFraction) / (1 - quietFraction)).clamp(
            0.0,
            1.0,
          );
          return SizedBox.square(
            dimension: size,
            child: CustomPaint(
              key: const ValueKey('hold-progress-ring'),
              painter: _RingPainter(
                progress: shown,
                color: c,
                track: scheme.surface.withValues(alpha: 0.85),
              ),
              child: icon == null
                  ? null
                  : Center(
                      child: Icon(
                        icon,
                        size: size * 0.42,
                        color: c.withValues(alpha: 0.5 + 0.5 * shown),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.11;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 1);
    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 2,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// [child]a basılı tutulunca, dokunulan yerin üstünde [HoldProgressRing]
/// gösterir; [duration] dolunca (jest yapıldı), parmak kalkınca ya da
/// [slop]tan çok kayınca kalkar. Dokunuşu TÜKETMEZ (Listener) — alttaki
/// uzun basış/sürükleme jesti aynen çalışır. Yalnız dokunmatik ve kalem.
class HoldRingArea extends StatefulWidget {
  const HoldRingArea({
    super.key,
    required this.child,
    this.duration = kLongPressTimeout,
    this.enabled = true,
    this.slop = 12,
    this.icon,
  });

  final Widget child;
  final Duration duration;
  final bool enabled;
  final double slop;
  final IconData? icon;

  @override
  State<HoldRingArea> createState() => _HoldRingAreaState();
}

class _HoldRingAreaState extends State<HoldRingArea> {
  Offset? _at;
  int? _pointer;
  int _serial = 0;
  Timer? _done;

  @override
  void dispose() {
    _done?.cancel();
    super.dispose();
  }

  void _hide() {
    _done?.cancel();
    _pointer = null;
    if (_at != null && mounted) setState(() => _at = null);
  }

  void _down(PointerDownEvent e) {
    if (!widget.enabled || e.kind == PointerDeviceKind.mouse) return;
    if (_pointer != null) {
      // İkinci parmak: uzun basış değil (yakınlaştırma vb.).
      _hide();
      return;
    }
    _pointer = e.pointer;
    _done?.cancel();
    _done = Timer(widget.duration, _hide);
    setState(() {
      _at = e.localPosition;
      _serial++;
    });
  }

  void _move(PointerMoveEvent e) {
    final at = _at;
    if (e.pointer != _pointer || at == null) return;
    if ((e.localPosition - at).distance > widget.slop) _hide();
  }

  void _up(PointerEvent e) {
    if (e.pointer == _pointer) _hide();
  }

  @override
  Widget build(BuildContext context) {
    final at = _at;
    const ring = 44.0;
    return Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (at != null)
            Positioned(
              left: at.dx - ring / 2,
              top: at.dy - ring - 24,
              child: HoldProgressRing(
                restartKey: _serial,
                duration: widget.duration,
                size: ring,
                icon: widget.icon,
                quietFraction: 0.3,
              ),
            ),
        ],
      ),
    );
  }
}
