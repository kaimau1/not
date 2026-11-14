import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/a11y/motion.dart';

/// P63 iskelet (docs/plan_tasarim_B.md §6.4): gerçek ses düzeyini izleyen
/// dalga. `ListeningWaveform` kalıbı (tek Ticker + tek CustomPaint); düzey
/// olayı widget KURMAZ, yalnız boyar. Ekrana PB5 bağlar.

const double _barWidth = 3;
const double _barGap = 4;
const double _barStep = _barWidth + _barGap;
const double _idleDot = 3;
const double _riseMs = 80;
const double _fallMs = 320;
const double _breathMs = 2400;
const double _jitterBaseMs = 560;
const double _jitterStepMs = 41;

/// Genişliğe sığan çubuk sayısı (16–64).
int waveBarsFor(double width) => (width / _barStep).floor().clamp(16, 64);

/// Düzeyi yumuşatır: yükseliş ~80 ms, düşüş ~320 ms (üstel yaklaşım).
double smoothLevel(double current, double target, Duration dt) {
  final tau = target > current ? _riseMs : _fallMs;
  final k = 1 - math.exp(-dt.inMicroseconds / 1000 / tau);
  return current + (target - current) * k;
}

/// i. çubuğun yükseklik çarpanı (0–1).
double waveBarFactor(
  int i,
  int n,
  double level,
  Duration t, {
  bool reduceMotion = false,
}) {
  final ms = t.inMicroseconds / 1000;
  final breath = reduceMotion
      ? 0.0
      : 0.04 * math.sin(2 * math.pi * ms / _breathMs);
  final envelope = 0.35 + 0.65 * math.sin(math.pi * (i + 0.5) / n);
  final jitter = reduceMotion
      ? 1.0
      : 1 +
            0.2 *
                math.sin(
                  2 * math.pi * ms / (_jitterBaseMs + _jitterStepMs * i) +
                      0.7 * i,
                );
  return (0.14 + breath + level.clamp(0.0, 1.0) * 0.86 * envelope * jitter)
      .clamp(0.0, 1.0);
}

typedef _Frame = ({Duration t, double level});

class VoiceLevelWave extends StatefulWidget {
  const VoiceLevelWave({
    super.key,
    required this.active,
    required this.color,
    this.level,
    this.idleColor,
    this.height = 32,
  });

  /// false: noktalar, ticker DURUR.
  final bool active;
  final Color color;

  /// 0–1; null = sabit 0.5.
  final ValueListenable<double>? level;

  /// Varsayılan `outlineVariant`.
  final Color? idleColor;
  final double height;

  @override
  State<VoiceLevelWave> createState() => _VoiceLevelWaveState();
}

class _VoiceLevelWaveState extends State<VoiceLevelWave>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _frame = ValueNotifier<_Frame>((t: Duration.zero, level: 0));
  Duration _last = Duration.zero;
  bool _motion = true;

  void _onTick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    final target = widget.level?.value ?? 0.5;
    _frame.value = (
      t: elapsed,
      level: smoothLevel(_frame.value.level, target, dt),
    );
  }

  void _sync() {
    final run = widget.active && _motion;
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = motionOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(VoiceLevelWave old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idle =
        widget.idleColor ?? Theme.of(context).colorScheme.outlineVariant;
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _VoiceLevelPainter(
            active: widget.active,
            motion: _motion,
            frame: _frame,
            level: widget.level,
            color: widget.color,
            idleColor: idle,
          ),
        ),
      ),
    );
  }
}

class _VoiceLevelPainter extends CustomPainter {
  _VoiceLevelPainter({
    required this.active,
    required this.motion,
    required this.frame,
    required this.level,
    required this.color,
    required this.idleColor,
  }) : super(repaint: !active ? null : (motion ? frame : level));

  final bool active;
  final bool motion;
  final ValueListenable<_Frame> frame;
  final ValueListenable<double>? level;
  final Color color;
  final Color idleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = waveBarsFor(size.width);
    final step = math.min(_barStep, size.width / n);
    final barW = math.min(_barWidth, step);
    final left = (size.width - step * n + (step - barW)) / 2;
    final midY = size.height / 2;
    if (!active) {
      final p = Paint()..color = idleColor;
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(
          Offset(left + i * step + barW / 2, midY),
          _idleDot / 2,
          p,
        );
      }
      return;
    }
    final lv = motion ? frame.value.level : (level?.value ?? 0.5);
    final t = motion ? frame.value.t : Duration.zero;
    // Sessizde renk vurgu × muted'a doğru söner.
    final c = Color.lerp(
      color.withValues(alpha: color.a * AppAlpha.muted),
      color,
      lv.clamp(0.0, 1.0),
    )!;
    final p = Paint()..color = c;
    final r = Radius.circular(barW / 2);
    for (var i = 0; i < n; i++) {
      final h = size.height * waveBarFactor(i, n, lv, t, reduceMotion: !motion);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left + i * step, midY - h / 2, barW, h),
          r,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceLevelPainter old) =>
      old.active != active ||
      old.motion != motion ||
      old.color != color ||
      old.idleColor != idleColor ||
      old.level != level ||
      old.frame != frame;
}
