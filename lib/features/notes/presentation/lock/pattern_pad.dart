import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';

/// 3×3 KİLİT DESENİ (F4.8). Parmak noktaların üstünden geçtikçe onları sırayla
/// bağlar; bırakınca [onComplete] noktaların sırasını (0–8) verir. Arada
/// atlanan nokta (ör. 0'dan 2'ye düz çizgi) Android'deki gibi kendiliğinden
/// eklenir. [error] true iken çizgi kırmızı görünür.
class PatternPad extends StatefulWidget {
  const PatternPad({
    super.key,
    required this.onComplete,
    this.error = false,
    this.size = 260,
  });

  final ValueChanged<List<int>> onComplete;
  final bool error;
  final double size;

  @override
  State<PatternPad> createState() => _PatternPadState();
}

class _PatternPadState extends State<PatternPad> {
  final _dots = <int>[];
  Offset? _finger;

  Offset _center(int i) {
    final cell = widget.size / 3;
    return Offset((i % 3 + 0.5) * cell, (i ~/ 3 + 0.5) * cell);
  }

  void _hit(Offset p) {
    final radius = widget.size / 9;
    for (var i = 0; i < 9; i++) {
      if (_dots.contains(i) || (p - _center(i)).distance > radius) continue;
      if (_dots.isNotEmpty) {
        // Aradaki atlanan nokta (aynı satır/sütun/köşegen ortası).
        final a = _dots.last;
        final sx = a % 3 + i % 3;
        final sy = a ~/ 3 + i ~/ 3;
        final mid = sy ~/ 2 * 3 + sx ~/ 2;
        final between = sx.isEven && sy.isEven && mid != a && mid != i;
        if (between && !_dots.contains(mid)) _dots.add(mid);
      }
      _dots.add(i);
      HapticFeedback.selectionClick();
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.error ? scheme.error : scheme.primary;
    return Semantics(
      label: context.l10n.lockPatternSemantics,
      excludeSemantics: true,
      child: GestureDetector(
        onPanStart: (d) => setState(() {
          _dots.clear();
          _finger = d.localPosition;
          _hit(d.localPosition);
        }),
        onPanUpdate: (d) => setState(() {
          _finger = d.localPosition;
          _hit(d.localPosition);
        }),
        onPanEnd: (_) {
          final dots = List<int>.of(_dots);
          setState(() {
            _finger = null;
            _dots.clear();
          });
          if (dots.isNotEmpty) widget.onComplete(dots);
        },
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _PatternPainter(
            dots: List.of(_dots),
            finger: _finger,
            center: _center,
            color: color,
            idle: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.dots,
    required this.finger,
    required this.center,
    required this.color,
    required this.idle,
  });

  final List<int> dots;
  final Offset? finger;
  final Offset Function(int) center;
  final Color color;
  final Color idle;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (dots.isNotEmpty) {
      final path = Path()..moveTo(center(dots.first).dx, center(dots.first).dy);
      for (final d in dots.skip(1)) {
        path.lineTo(center(d).dx, center(d).dy);
      }
      if (finger != null) path.lineTo(finger!.dx, finger!.dy);
      canvas.drawPath(path, line);
    }
    for (var i = 0; i < 9; i++) {
      final on = dots.contains(i);
      canvas.drawCircle(
        center(i),
        on ? 12 : 7,
        Paint()..color = on ? color : idle.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => true;
}
