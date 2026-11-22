import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';

/// Net ve tanınabilir silgi simgesi (sihirli değnek yerine eğik blok silgi +
/// silme çizgisi). [Icon] gibi [size] ve [color] alır.
class EraserGlyph extends StatelessWidget {
  const EraserGlyph({
    super.key,
    this.size = AppIconSize.m,
    this.color,
    this.filled = false,
  });

  final double size;
  final Color? color;

  /// Seçili/etkin durumda üst blok hafifçe dolu çizilir.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _EraserGlyphPainter(color: c, filled: filled),
      ),
    );
  }
}

class _EraserGlyphPainter extends CustomPainter {
  const _EraserGlyphPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = (w * 0.085).clamp(1.3, 2.2);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Alt zemin silme çizgisi.
    canvas.drawLine(
      Offset(w * 0.22, h * 0.86),
      Offset(w * 0.88, h * 0.86),
      stroke,
    );

    // 45° eğik iki parçalı silgi gövdesi.
    canvas.save();
    canvas.translate(w * 0.50, h * 0.46);
    canvas.rotate(-0.78539816339); // -45°
    final bw = w * 0.64;
    final bh = h * 0.38;
    final rect = Rect.fromCenter(center: Offset.zero, width: bw, height: bh);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(bh * 0.24));

    // Kılıf (sağ/üst yarı) yumuşak dolgu.
    final sleeve = Rect.fromLTRB(0, rect.top, rect.right, rect.bottom);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      sleeve,
      Paint()
        ..color = color.withValues(
          alpha: filled ? AppAlpha.soft : AppAlpha.pressed,
        ),
    );
    canvas.restore();

    // Dış hat ve ortadaki bölme çizgisi.
    canvas.drawRRect(rrect, stroke);
    canvas.drawLine(
      Offset(0, rect.top + sw * 0.2),
      Offset(0, rect.bottom - sw * 0.2),
      stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EraserGlyphPainter old) =>
      old.color != color || old.filled != filled;
}
