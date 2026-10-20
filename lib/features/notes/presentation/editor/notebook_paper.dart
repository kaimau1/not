// Özel alanlı render nesnesi (setter'lar markNeedsPaint çağırıyor).
// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    this.contentRuled = false,
  });

  final ArchivePaper style;
  final double gap;
  final ScrollController? scroll;

  /// Satır çizgilerini içerik mi çiziyor (bkz. [RuledLines])? Öyleyse
  /// çizgili desenlerde burada yalnız kenar çizgisi, zemin tonu ve cilt
  /// kalır — iki ayrı ızgara üst üste binmesin.
  final bool contentRuled;

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
        contentRuled: contentRuled,
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
    this.contentRuled = false,
  }) : super(repaint: contentRuled && style.ruled ? null : scroll);

  /// Bkz. [NotebookPaper.contentRuled].
  final bool contentRuled;

  final ArchivePaper style;
  final Color line;
  final Color margin;
  final Color spine;
  final double gap;
  final double topInset;
  final ScrollController? scroll;

  /// Sol kenar boşluğu çizgisinin yeri.
  static const double marginX = 30;

  /// Çizgileri içerik çizerken kenar çizgisinin yeri: metnin ve madde
  /// kutularının SOLUNDA (2026-10-20 — 30 dp'de kutuların ve başlığın
  /// üstünden geçiyordu).
  static const double contentMarginX = 8;

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
    final margined = style.ruled;
    final ruledByContent = contentRuled && style.ruled;
    final marginAt = ruledByContent ? contentMarginX : marginX;
    final left = margined ? marginAt : 12.0;
    final right = size.width - 12;
    void rows(Paint paint) {
      if (ruledByContent) return;
      for (var y = first; y < size.height; y += gap) {
        if (style == ArchivePaper.dashed) {
          drawDashedLine(canvas, Offset(left, y), right, paint);
        } else {
          canvas.drawLine(Offset(left, y), Offset(right, y), paint);
        }
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
        marginLine(marginAt);
      case ArchivePaper.dashed:
        rows(linePaint);
        marginLine(marginAt);
      case ArchivePaper.legal:
        canvas.drawRect(Offset.zero & size, Paint()..color = legalTint);
        rows(linePaint);
        // Bloknotun imzası: kenarda ÇİFT kırmızı çizgi.
        marginLine(marginAt - 3);
        marginLine(marginAt + 1);
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
      old.topInset != topInset ||
      old.contentRuled != contentRuled;
}

/// Kesikli yatay çizgi ([start]tan [endX]e). Kesik ve boşluk çizgi
/// kalınlığıyla ölçeklenir.
void drawDashedLine(
  Canvas canvas,
  Offset start,
  double endX,
  Paint paint, {
  double dash = 6,
  double space = 4,
}) {
  for (var x = start.dx; x < endX; x += dash + space) {
    canvas.drawLine(
      Offset(x, start.dy),
      Offset(math.min(x + dash, endX), start.dy),
      paint,
    );
  }
}

/// **YAZIYA OTURAN SATIR ÇİZGİLERİ** (kullanıcı bulgusu 2026-10-20:
/// "defter modunda çizgilerle yazılar düzgün olmalı, şu an üst üste
/// geliyorlar").
///
/// KÖK NEDEN: çizgiler gövdenin tepesinden başlayan SABİT bir ızgaraydı
/// (aralık = gövde satır yüksekliği, sistem yazı ölçeği bile hesapta
/// yoktu). Oysa sayfada başlık (büyük punto), çipler, sayfa çubuğu, madde
/// satırlarının dolgusu, "Yeni öğe" düğmesi gibi ızgaraya uymayan
/// yükseklikler var — birkaç satır sonra yazı çizginin ÜSTÜNE biniyordu.
///
/// ŞİMDİ: çizgiler içeriğin İÇİNDE, yerleşim bittikten sonra çizilir.
/// Sayfadaki her düzenlenebilir metin alanının ([RenderEditable]) her
/// satırının altına bir çizgi gelir; aradaki boşluklar satır aralığına en
/// yakın eşit adımlarla doldurulur, metin (düzenlenebilir ya da düğme
/// yazısı) kesen dolgu çizgisi atlanır. İçerik bitince çizgiler sayfanın
/// sonuna kadar aynı adımla sürer. Çizgiler çocuktan ÖNCE çizilir (yazının
/// arkasında kalır).
class RuledLines extends SingleChildRenderObjectWidget {
  const RuledLines({
    super.key,
    required this.gap,
    required this.color,
    this.dashed = false,
    this.extraBottom = 0,
    this.left = NotebookPaperPainter.contentMarginX,
    this.anchorParagraphs = false,
    super.child,
  });

  /// true: düz yazılar ([RenderParagraph]) da çizgi alır — salt okunur
  /// görünümde (ana ekran kartı) metin alanı yok, yazı Text ile çizilir.
  /// false: düz yazılar (düğme etiketleri) yalnız dolgu çizgisini engeller.
  final bool anchorParagraphs;

  /// Gövde metninin satır yüksekliği (dp) — dolgu çizgilerinin adımı.
  final double gap;
  final Color color;
  final bool dashed;

  /// Çocuğun altında çizgilerin sürdüğü ek pay (kaydırma alanının alt
  /// dolgusu).
  final double extraBottom;

  /// Çizgilerin sol başı (kenar çizgisi).
  final double left;

  @override
  RenderRuledLines createRenderObject(BuildContext context) => RenderRuledLines(
    gap: gap,
    color: color,
    dashed: dashed,
    extraBottom: extraBottom,
    left: left,
    anchorParagraphs: anchorParagraphs,
  );

  @override
  void updateRenderObject(BuildContext context, RenderRuledLines renderObject) {
    renderObject
      ..gap = gap
      ..color = color
      ..dashed = dashed
      ..extraBottom = extraBottom
      ..left = left
      ..anchorParagraphs = anchorParagraphs;
  }
}

class RenderRuledLines extends RenderProxyBox {
  RenderRuledLines({
    required double gap,
    required Color color,
    required bool dashed,
    required double extraBottom,
    required double left,
    bool anchorParagraphs = false,
  }) : _anchorParagraphs = anchorParagraphs,
       _gap = gap,
       _color = color,
       _dashed = dashed,
       _extraBottom = extraBottom,
       _left = left;

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsPaint();
  }

  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  bool _dashed;
  set dashed(bool value) {
    if (value == _dashed) return;
    _dashed = value;
    markNeedsPaint();
  }

  double _extraBottom;
  set extraBottom(double value) {
    if (value == _extraBottom) return;
    _extraBottom = value;
    markNeedsPaint();
  }

  double _left;
  set left(double value) {
    if (value == _left) return;
    _left = value;
    markNeedsPaint();
  }

  bool _anchorParagraphs;
  set anchorParagraphs(bool value) {
    if (value == _anchorParagraphs) return;
    _anchorParagraphs = value;
    markNeedsPaint();
  }

  /// Son çizimde bulunan çizgiler (testler için).
  @visibleForTesting
  List<double> lastLines = const [];

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_gap > 0 && hasSize) {
      final lines = computeLines();
      lastLines = lines;
      final paint = Paint()
        ..color = _color
        ..strokeWidth = 1;
      final canvas = context.canvas;
      final right = offset.dx + size.width - 12;
      for (final y in lines) {
        final start = Offset(offset.dx + _left, offset.dy + y);
        if (_dashed) {
          drawDashedLine(canvas, start, right, paint);
        } else {
          canvas.drawLine(start, Offset(right, start.dy), paint);
        }
      }
    }
    super.paint(context, offset);
  }

  /// Çizgilerin bu kutuya göre dikey konumları (artan sırada).
  @visibleForTesting
  List<double> computeLines() {
    final anchors = <double>[];
    final blocked = <(double, double)>[];
    void visit(RenderObject node) {
      if (node is RenderEditable) {
        _collectEditable(node, anchors, blocked);
        return; // İçindeki yer tutucular (çipler) metnin parçası.
      }
      if (node is RenderParagraph) {
        final box = _boxOf(node);
        if (box == null) return;
        blocked.add(box);
        if (_anchorParagraphs) _collectParagraph(node, box.$1, anchors);
        return;
      }
      node.visitChildren(visit);
    }

    visitChildren(visit);
    return layoutRuledLines(
      anchors: anchors,
      blocked: blocked,
      gap: _gap,
      bottom: size.height + _extraBottom,
    );
  }

  (double, double)? _boxOf(RenderBox node) {
    if (!node.attached || !node.hasSize || node.size.isEmpty) return null;
    final transform = node.getTransformTo(this);
    final top = MatrixUtils.transformPoint(transform, Offset.zero).dy;
    final bottom = MatrixUtils.transformPoint(
      transform,
      Offset(0, node.size.height),
    ).dy;
    return (top, bottom);
  }

  /// Düz yazının her satırının alt kenarı: seçim kutularının (satır
  /// parçaları) farklı alt kenarları.
  void _collectParagraph(RenderParagraph node, double top, List<double> out) {
    final length = node.text.toPlainText(includeSemanticsLabels: false).length;
    if (length == 0) return;
    final boxes = node.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: length),
    );
    final bottoms = <double>[];
    for (final b in boxes) {
      if (bottoms.every((y) => (y - b.bottom).abs() > 1)) bottoms.add(b.bottom);
    }
    for (final y in bottoms) {
      out.add(top + y);
    }
  }

  void _collectEditable(
    RenderEditable node,
    List<double> anchors,
    List<(double, double)> blocked,
  ) {
    final box = _boxOf(node);
    if (box == null) return;
    final (top, bottom) = box;
    final height = bottom - top;
    // Satır yüksekliği alanın kendi stilinden (başlık daha büyük); satırlar
    // `forceStrutHeight` ile eşit — adım = yükseklik / satır sayısı.
    final line = node.preferredLineHeight;
    final count = math.max(1, (height / (line > 0 ? line : _gap)).round());
    final step = height / count;
    for (var k = 1; k <= count; k++) {
      anchors.add(top + step * k);
    }
    blocked.add(box);
  }
}

/// [RenderRuledLines]ın hesap çekirdeği (saf, test edilebilir).
///
/// [anchors]: metin satırlarının alt kenarları — çizgi kesin olarak
/// buralara gelir. [blocked]: içinden dolgu çizgisi geçmemesi gereken dikey
/// aralıklar (metin alanları, düğme yazıları). Aradaki boşluk [gap]e en
/// yakın EŞİT adımlarla doldurulur; ilk metnin üstü boş kalır (başlığın
/// üstüne çizgi çekilmez), son metnin altı [bottom]a kadar [gap] adımıyla
/// sürer.
List<double> layoutRuledLines({
  required List<double> anchors,
  required List<(double, double)> blocked,
  required double gap,
  required double bottom,
}) {
  if (gap <= 0) return const [];
  const edge = 2.0;
  bool free(double y) {
    for (final (top, bottom) in blocked) {
      if (y > top + edge && y < bottom - edge) return false;
    }
    return true;
  }

  final sorted = [...anchors]..sort();
  final points = <double>[];
  for (final y in sorted) {
    // Aynı yükseklikte iki alan (iki sütunlu liste) tek çizgi verir.
    if (points.isNotEmpty && (y - points.last).abs() < gap * 0.35) continue;
    points.add(y);
  }
  final lines = <double>[];
  if (points.isEmpty) {
    for (var y = gap; y < bottom; y += gap) {
      if (free(y)) lines.add(y);
    }
    return lines;
  }
  for (var i = 0; i < points.length; i++) {
    final y = points[i];
    lines.add(y);
    if (i + 1 < points.length) {
      final distance = points[i + 1] - y;
      final steps = (distance / gap).round();
      if (steps >= 2) {
        final step = distance / steps;
        for (var k = 1; k < steps; k++) {
          final fill = y + step * k;
          if (free(fill)) lines.add(fill);
        }
      }
    }
  }
  for (var y = points.last + gap; y < bottom; y += gap) {
    if (free(y)) lines.add(y);
  }
  return lines;
}

/// Kâğıt deseninin adı.
String archivePaperLabel(AppLocalizations l10n, ArchivePaper paper) =>
    switch (paper) {
      ArchivePaper.lined => l10n.archivePaperLined,
      ArchivePaper.grid => l10n.archivePaperGrid,
      ArchivePaper.dots => l10n.archivePaperDots,
      ArchivePaper.plain => l10n.archivePaperPlain,
      ArchivePaper.dashed => l10n.archivePaperDashed,
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
