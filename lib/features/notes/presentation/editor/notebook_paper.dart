import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
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

  /// Sarı bloknot zemini (bkz. [ArchivePaper.legal]). Saydam: notun kendi
  /// rengi ve koyu tema altta kalır, yalnız sıcak bir ton bindirilir.
  static const Color legalTint = Color(0x33FFE36E);

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
    final margined = style == ArchivePaper.lined || style == ArchivePaper.legal;
    final left = margined ? marginX : 12.0;
    final right = size.width - 12;
    void rows(Paint paint) {
      for (var y = first; y < size.height; y += gap) {
        canvas.drawLine(Offset(left, y), Offset(right, y), paint);
      }
    }

    void marginLine(double x) => canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = margin
        ..strokeWidth = 1.2,
    );

    switch (style) {
      case ArchivePaper.lined:
        rows(linePaint);
        marginLine(marginX);
      case ArchivePaper.legal:
        canvas.drawRect(Offset.zero & size, Paint()..color = legalTint);
        rows(linePaint);
        // Bloknotun imzası: kenarda ÇİFT kırmızı çizgi.
        marginLine(marginX - 3);
        marginLine(marginX + 1);
      case ArchivePaper.grid:
        rows(linePaint);
        for (var x = left; x < right; x += gap) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        }
      case ArchivePaper.engineering:
        // İnce kareler satır aralığının dörtte biri; satır çizgileri ve her
        // dördüncü dikey çizgi belirgin — yazı yine satıra oturur.
        final minor = Paint()
          ..color = line.withValues(alpha: line.a * 0.45)
          ..strokeWidth = 0.6;
        final step = gap / 4;
        // İnce yatay çizgiler satır çizgisiyle aynı fazda başlar.
        var y = first - gap;
        while (y < size.height) {
          for (var k = 1; k < 4; k++) {
            final yy = y + step * k;
            if (yy >= 0 && yy < size.height) {
              canvas.drawLine(Offset(left, yy), Offset(right, yy), minor);
            }
          }
          y += gap;
        }
        var i = 0;
        for (var x = left; x < right; x += step, i++) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            i % 4 == 0 ? linePaint : minor,
          );
        }
        rows(linePaint);
      case ArchivePaper.dots:
        final dots = <Offset>[
          for (var y = first; y < size.height; y += gap)
            for (var x = left; x < right; x += gap) Offset(x, y),
        ];
        canvas.drawPoints(
          PointMode.points,
          dots,
          Paint()
            ..color = line
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
      case ArchivePaper.isometric:
        // Üçgen örgü: satırlar arası [gap], aynı satırdaki noktalar arası
        // 2·gap/√3; tek satırlar yarım adım kayık. Satırın SIRASI kaydırma
        // payından hesaplanır ki desen kayarken noktalar yer değiştirmesin.
        final dx = gap * 2 / math.sqrt(3);
        final firstRow = ((first - topInset + offset) / gap).round();
        final dots = <Offset>[];
        var row = firstRow;
        for (var y = first; y < size.height; y += gap, row++) {
          final shift = row.isOdd ? dx / 2 : 0.0;
          for (var x = left + shift; x < right; x += dx) {
            dots.add(Offset(x, y));
          }
        }
        canvas.drawPoints(
          PointMode.points,
          dots,
          Paint()
            ..color = line
            ..strokeWidth = 2.2
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
String archivePaperLabel(AppLocalizations l10n, ArchivePaper paper) =>
    switch (paper) {
      ArchivePaper.lined => l10n.archivePaperLined,
      ArchivePaper.grid => l10n.archivePaperGrid,
      ArchivePaper.dots => l10n.archivePaperDots,
      ArchivePaper.plain => l10n.archivePaperPlain,
      ArchivePaper.legal => l10n.archivePaperLegal,
      ArchivePaper.engineering => l10n.archivePaperEngineering,
      ArchivePaper.isometric => l10n.archivePaperIsometric,
    };

/// **KÂĞIT SEÇİCİ** (kullanıcı bulgusu 2026-10-20: "defter görünümünde
/// kâğıt tipi seçimi çalışmıyor ve yenilikler lazım").
///
/// ESKİDEN: adların alt alta dizildiği bir radyo listesi; desenin neye
/// benzediği ancak seçince (o da çoğu zaman görünmüyordu — bkz. editörün
/// `_sameVisual` notu) anlaşılıyordu. ŞİMDİ: her desen kendi küçük
/// önizlemesiyle bir döşeme; dokunmak deseni ANINDA uygular, levha açık
/// kalır (renk şeridiyle aynı canlı davranış) — arkadaki sayfada sonuç
/// görülerek denenir.
class NotebookPaperPicker extends StatefulWidget {
  const NotebookPaperPicker({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final ArchivePaper initial;
  final ValueChanged<ArchivePaper> onChanged;

  @override
  State<NotebookPaperPicker> createState() => _NotebookPaperPickerState();
}

class _NotebookPaperPickerState extends State<NotebookPaperPicker> {
  late ArchivePaper _current = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              l10n.archivePaper,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              // Telefonda 4 (çok darda 3), geniş ekranda daha çok sütun.
              final columns = (constraints.maxWidth / 86).floor().clamp(3, 7);
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final paper in ArchivePaper.values)
                    SizedBox(
                      width: width,
                      child: _PaperTile(
                        key: ValueKey('paper-${paper.id}'),
                        paper: paper,
                        label: archivePaperLabel(l10n, paper),
                        selected: paper == _current,
                        scheme: scheme,
                        onTap: () {
                          if (paper == _current) return;
                          setState(() => _current = paper);
                          widget.onChanged(paper);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaperTile extends StatelessWidget {
  const _PaperTile({
    super.key,
    required this.paper,
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final ArchivePaper paper;
  final String label;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 92,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2.2 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: NotebookPaperPainter(
                        style: paper,
                        line: scheme.outlineVariant.withValues(alpha: 0.9),
                        margin: scheme.error.withValues(alpha: 0.45),
                        spine: scheme.shadow.withValues(alpha: 0.10),
                        gap: 13,
                      ),
                    ),
                    if (selected)
                      PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: Icon(
                          Icons.check_circle,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
