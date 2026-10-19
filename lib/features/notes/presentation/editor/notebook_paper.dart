import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../domain/archive_paper.dart';

/// **DEFTER KÂĞIDI** (F3.5): Defter görünümündeki notun ([Note.paged])
/// arkasına çizilen desen (çizgili / kareli / noktalı / düz) ve cilt gölgesi.
///
/// Desen içerikle birlikte kayar ([scroll]) ama her zaman ekranın üstünden
/// başlar; aralık ([gap]) gövde metninin satır yüksekliğidir — yazı
/// çizgilere oturur.
class NotebookPaper extends StatelessWidget {
  const NotebookPaper({
    super.key,
    required this.style,
    required this.gap,
    required this.child,
    this.scroll,
    this.topInset = 0,
  });

  final ArchivePaper style;
  final double gap;
  final ScrollController? scroll;

  /// Desenin başladığı yer (başlık/sayfa çubuğu payı).
  final double topInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: NotebookPaperPainter(
        style: style,
        line: scheme.outlineVariant.withValues(alpha: 0.55),
        margin: scheme.error.withValues(alpha: 0.35),
        spine: scheme.shadow.withValues(alpha: 0.10),
        scroll: scroll,
        gap: gap,
        topInset: topInset,
      ),
      child: child,
    );
  }
}

class NotebookPaperPainter extends CustomPainter {
  NotebookPaperPainter({
    required this.style,
    required this.line,
    required this.margin,
    required this.spine,
    required this.gap,
    this.scroll,
    this.topInset = 0,
  }) : super(repaint: scroll);

  final ArchivePaper style;
  final Color line;
  final Color margin;
  final Color spine;
  final double gap;
  final double topInset;
  final ScrollController? scroll;

  /// Sol kenar boşluğu çizgisinin yeri.
  static const double marginX = 30;

  /// Cilt gölgesinin genişliği.
  static const double spineWidth = 14;

  /// Kaydırma konumu — `position` DEĞİL `positions`: sayfa geçişinde
  /// denetleyicinin bir an iki (ya da hiç) konumu olur, `position` doğrulama
  /// hatası verirdi.
  double get _offset {
    for (final position in scroll?.positions ?? const <ScrollPosition>[]) {
      return position.hasPixels ? position.pixels : 0;
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (gap <= 0) return;
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 1;
    final offset = _offset;
    // İlk çizginin yeri: içerikle birlikte kayar, ekranın üstünden taşanlar
    // atlanır.
    var first = topInset + gap - offset;
    if (first < 0) first += ((-first) / gap).ceil() * gap;
    final left = style == ArchivePaper.lined ? marginX : 12.0;
    switch (style) {
      case ArchivePaper.lined:
        for (var y = first; y < size.height; y += gap) {
          canvas.drawLine(
            Offset(left, y),
            Offset(size.width - 12, y),
            linePaint,
          );
        }
        canvas.drawLine(
          const Offset(marginX, 0),
          Offset(marginX, size.height),
          Paint()
            ..color = margin
            ..strokeWidth = 1.2,
        );
      case ArchivePaper.grid:
        for (var y = first; y < size.height; y += gap) {
          canvas.drawLine(
            Offset(left, y),
            Offset(size.width - 12, y),
            linePaint,
          );
        }
        for (var x = left; x < size.width - 12; x += gap) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        }
      case ArchivePaper.dots:
        final dots = <Offset>[
          for (var y = first; y < size.height; y += gap)
            for (var x = left; x < size.width - 12; x += gap) Offset(x, y),
        ];
        canvas.drawPoints(
          PointMode.points,
          dots,
          Paint()
            ..color = line
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
      case ArchivePaper.plain:
        break;
    }
    // Cilt: sol kenarda içeri doğru sönen gölge — düz kâğıtta da defter
    // olduğu belli olsun.
    final strip = Rect.fromLTWH(0, 0, spineWidth, size.height);
    canvas.drawRect(
      strip,
      Paint()
        ..shader = LinearGradient(colors: [spine, spine.withValues(alpha: 0)])
            .createShader(strip),
    );
  }

  @override
  bool shouldRepaint(NotebookPaperPainter old) =>
      old.style != style ||
      old.line != line ||
      old.margin != margin ||
      old.spine != spine ||
      old.gap != gap ||
      old.topInset != topInset;
}

/// Kâğıt deseninin adı.
String archivePaperLabel(
  ArchivePaper paper, {
  required String lined,
  required String grid,
  required String dots,
  required String plain,
}) => switch (paper) {
  ArchivePaper.lined => lined,
  ArchivePaper.grid => grid,
  ArchivePaper.dots => dots,
  ArchivePaper.plain => plain,
};
