// P63 iskelet — docs/plan_tasarim_B.md §6.3
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../domain/attachment.dart';
import '../viewers/ink_stroke_paint.dart';

/// Önizleme kutusunun varsayılan boyu (sınırsız kısıtta) ve sabit kalem
/// çipinin dairesi.
const double _previewHeight = 44;
const double _compactSide = 30;

/// `compact`'ta kalınlık kutu boyunun en çok bu oranı (46 px'lik fosforlu
/// 30 px daireden taşmasın).
const double _compactWidthShare = 0.45;

/// S eğrisinin nokta sayısı ve x'teki sıkışma payı.
///
/// `x(u) = u + k·sin(2πu)/(2π)`: nokta aralığı uçlarda (1+k) kat geniş,
/// ortada (1−k) kat dar. Dolma kalem kalınlığını nokta ARALIĞINDAN okur
/// (`fountainRadii`: aralık büyüdükçe "hızlı çizgi" incelir) → uçlar incelir,
/// orta kalınlaşır; basınç (`pressures`) gerekmez.
const int _points = 41;
const double _squeeze = 0.8;

/// S biçimli kısa önizleme çizgisi; [size] önizleme kutusu. Saf işlev.
InkStroke penPreviewStroke({
  required int argb,
  required double widthPx,
  required Size size,
  bool compact = false,
}) {
  final w = compact
      ? math.min(widthPx, size.shortestSide * _compactWidthShare)
      : widthPx;
  // Yuvarlak uç kutudan taşmasın.
  final inset = w / 2 + AppSpace.xxs;
  final span = math.max(0.0, size.width - 2 * inset);
  final amp = math.max(0.0, size.height / 2 - inset);
  final points = <double>[];
  for (var i = 0; i < _points; i++) {
    final u = i / (_points - 1);
    final t = 2 * math.pi * u;
    final x = inset + span * (u + _squeeze * math.sin(t) / (2 * math.pi));
    final y = size.height / 2 - amp * math.sin(t);
    points
      ..add(x / size.width)
      ..add(y / size.height);
  }
  return InkStroke(page: 1, color: argb, width: w / size.width, points: points);
}

/// **KALEMİN GERÇEK ÇİZGİ ÖNİZLEMESİ**: nokta yerine S biçimli kısa çizgi,
/// `paintInkStroke` ile — fosforlu saydam ve düz uçlu, dolma kalem incelip
/// kalınlaşır, keçeli dolu. Yalnız çizgi; kâğıt zemin çağıranın.
///
/// Çizgi yalnız `(argb, widthPx, compact, boyut)` değişince yeniden üretilir:
/// geometri önbelleği çizgi ÖRNEĞİNE bağlı (`ink_stroke_paint.dart` `_geom`).
/// Kendi `RepaintBoundary`'si: kaydırıcı sürüklenirken yalnız bu katman boyanır.
class PenStrokePreview extends StatefulWidget {
  const PenStrokePreview({
    super.key,
    required this.argb,
    required this.widthPx,
    this.compact = false,
  });

  /// Kalemin SON rengi (saydamlık uygulanmış).
  final int argb;
  final double widthPx;

  /// Sabit kalem çipi: 30 × 30 daire içinde kısa çizgi.
  final bool compact;

  @override
  State<PenStrokePreview> createState() => _PenStrokePreviewState();
}

class _PenStrokePreviewState extends State<PenStrokePreview> {
  ({int argb, double widthPx, bool compact, Size size})? _input;
  InkStroke? _stroke;

  InkStroke _strokeFor(Size size) {
    final input = (
      argb: widget.argb,
      widthPx: widget.widthPx,
      compact: widget.compact,
      size: size,
    );
    if (input != _input || _stroke == null) {
      _input = input;
      _stroke = penPreviewStroke(
        argb: input.argb,
        widthPx: input.widthPx,
        size: size,
        compact: input.compact,
      );
    }
    return _stroke!;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = widget.compact ? _compactSide : _previewHeight;
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(
          c.hasBoundedWidth ? c.maxWidth : fallback,
          c.hasBoundedHeight ? c.maxHeight : fallback,
        );
        return RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: PenStrokePainter(_strokeFor(size)),
          ),
        );
      },
    );
  }
}

/// Önizleme çizgisini boyar; aynı örnekte yeniden boyamaz.
class PenStrokePainter extends CustomPainter {
  PenStrokePainter(this.stroke);

  final InkStroke stroke;

  @override
  void paint(Canvas canvas, Size size) => paintInkStroke(canvas, size, stroke);

  @override
  bool shouldRepaint(PenStrokePainter old) => !identical(old.stroke, stroke);
}
