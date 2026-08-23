import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../settings/settings_providers.dart';

/// Ana ekran zemin **desenlerini** çizer (varlık dosyası yok — bkz.
/// [DashboardPattern]).
///
/// Desenler tek renkle, düşük alfayla çizilir: amaç dokunun HİSSEDİLMESİ,
/// kart ızgarasının okunurluğunu düşürmemek. Renk çağırandan gelir ki açık,
/// koyu ve kâğıt temada üçü de doğru görünsün.
class DashboardPatternPainter extends CustomPainter {
  const DashboardPatternPainter({
    required this.pattern,
    required this.color,
    this.cell = 28,
  });

  final DashboardPattern pattern;
  final Color color;

  /// Desenin tekrar aralığı (dp).
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == DashboardPattern.none) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (pattern == DashboardPattern.dots) {
      final dot = Paint()..color = color;
      for (var y = cell / 2; y < size.height; y += cell) {
        for (var x = cell / 2; x < size.width; x += cell) {
          canvas.drawCircle(Offset(x, y), 1.6, dot);
        }
      }
      return;
    }
    if (pattern == DashboardPattern.lines) {
      // Çizgili defter: yalnız yatay çizgiler.
      for (var y = cell; y <= size.height; y += cell) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      return;
    }
    if (pattern == DashboardPattern.diagonal) {
      // 45°'lik çizgiler: ekranı boydan boya geçmesi için genişlik +
      // yükseklik kadar ilerlenir.
      final total = size.width + size.height;
      for (var i = 0.0; i <= total; i += cell) {
        canvas.drawLine(
          Offset(i, 0),
          Offset(i - size.height, size.height),
          paint,
        );
      }
      return;
    }
    if (pattern == DashboardPattern.graph) {
      // Milimetrik kâğıt: ince kareler + her 5 karede bir belirgin çizgi.
      final small = cell / 5;
      final light = Paint()
        ..color = color.withValues(alpha: color.a * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      for (var x = 0.0; x <= size.width; x += small) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), light);
      }
      for (var y = 0.0; y <= size.height; y += small) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), light);
      }
    }
    // Kareli (ve milimetriğin kalın çizgileri) aynı ızgara.
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(DashboardPatternPainter old) =>
      old.pattern != pattern || old.color != color || old.cell != cell;
}

/// Zemin desenini bir widget olarak verir (ızgaranın arkasına konur).
///
/// Desen çizgileri ekranın TAMAMINI kaplıyor; `RepaintBoundary` olmadan
/// listenin her kaydırmasında yeniden boyanırdı.
class DashboardPatternLayer extends StatelessWidget {
  const DashboardPatternLayer({
    super.key,
    required this.pattern,
    required this.opacity,
    this.cell = 28,
  });

  final DashboardPattern pattern;

  /// Desenin görünürlüğü (zemin ayarındaki kaydırıcı).
  final double opacity;
  final double cell;

  @override
  Widget build(BuildContext context) {
    if (pattern == DashboardPattern.none) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    // Desen rengi yüzeyin ZIDDINDAN gelir: açık temada koyu, koyu temada
    // açık çizgiler. Alfa kullanıcının görünürlük ayarına bağlı ve her
    // durumda düşük tutulur (0.35 tavan) — desen zemin olarak kalmalı.
    final color = scheme.onSurface.withValues(
      alpha: (opacity.clamp(0.05, 1)) * 0.35,
    );
    return RepaintBoundary(
      child: CustomPaint(
        painter: DashboardPatternPainter(
          pattern: pattern,
          color: color,
          cell: math.max(8, cell),
        ),
      ),
    );
  }
}
