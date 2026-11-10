import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';

/// **SABİT PDF: SÜREKLİ DİKEY KAYDIRMA** (F65.8, kullanıcı 2026-11-09:
/// "sayfa sayfa değil; bütün sayfalar alt alta, yalnız kaydırıyoruz").
///
/// Sayfalar genişliğe oturur, aralarında [kPdfPageGap] boşluk. Liste TEMBEL:
/// yalnız görünen sayfalar (+ önbellek payı, ±2 sayfa) kurulur; dışarıda
/// kalanın görüntüsü `PdfPageImage.dispose` ile bırakılır — 300 sayfalık
/// belgede bellek ve kare maliyeti sayfa sayısıyla büyümez. Boylar
/// `itemExtentBuilder` ile önceden bilinir: atlama (yer imi, 📖 s.N, tam
/// ekrandan dönüş) çocukları kurmadan doğrudan ofsete gider.
///
/// Kaydırma sırasında kök `setState` YOK: ortadaki sayfa değişince yalnız
/// [onPageChanged] (hap), kaydırma DURUNCA [onPageSettled] (nota yazım).
class PdfPageColumn extends StatefulWidget {
  const PdfPageColumn({
    super.key,
    required this.count,
    required this.initialPage,
    required this.ratioOf,
    required this.itemBuilder,
    this.physics,
    this.onPageChanged,
    this.onPageSettled,
  });

  final int count;

  /// 1'den başlar.
  final int initialPage;

  /// [index]. sayfanın (0'dan) yükseklik / genişlik oranı.
  final double Function(int index) ratioOf;

  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollPhysics? physics;

  /// Görünür alanın ortasındaki sayfa değişti (kaydırırken; 1'den başlar).
  final ValueChanged<int>? onPageChanged;

  /// Kaydırma durdu; ortadaki sayfa.
  final ValueChanged<int>? onPageSettled;

  @override
  State<PdfPageColumn> createState() => PdfPageColumnState();
}

class PdfPageColumnState extends State<PdfPageColumn> {
  ScrollController? _scroll;
  double _width = 0;
  late int _page = widget.initialPage;

  /// Sayfanın BAŞINA gider; komşu sayfaya [animate] ile kayar.
  void showPage(int page, {bool animate = false}) {
    _page = page.clamp(1, widget.count < 1 ? 1 : widget.count);
    final c = _scroll;
    if (c == null || !c.hasClients || _width <= 0) return;
    final target = pdfColumnOffset(
      _page,
      _width,
      widget.ratioOf,
    ).clamp(0.0, c.position.maxScrollExtent);
    if (animate) {
      c.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      c.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollUpdateNotification) {
      final p = pdfColumnPageAt(
        n.metrics.pixels,
        n.metrics.viewportDimension,
        _width,
        widget.count,
        widget.ratioOf,
      );
      if (p != _page) {
        _page = p;
        widget.onPageChanged?.call(p);
      }
    } else if (n is ScrollEndNotification) {
      widget.onPageSettled?.call(_page);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth;
      if (_scroll == null) {
        _scroll = ScrollController(
          initialScrollOffset: pdfColumnOffset(_page, width, widget.ratioOf),
        );
      } else if (width != _width) {
        // Bölme genişliği değişti (döndürme, yan bölme): aynı sayfada kal.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showPage(_page);
        });
      }
      _width = width;
      return NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.builder(
          controller: _scroll,
          physics: widget.physics,
          itemCount: widget.count,
          itemExtentBuilder: (i, d) => i >= widget.count
              ? null
              : _extent(d.crossAxisExtent, widget.ratioOf(i)),
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: kPdfPageGap),
            child: widget.itemBuilder(context, i),
          ),
        ),
      );
    },
  );
}

/// Sayfalar arası boşluk (bölmenin zemini görünür).
const double kPdfPageGap = 8;

double _extent(double width, double ratio) => width * ratio + kPdfPageGap;

/// [page]. sayfanın (1'den) sütundaki üst kenarı.
// ponytail: O(n) toplam — 10 000+ sayfada önek dizisine geçilir.
double pdfColumnOffset(
  int page,
  double width,
  double Function(int index) ratioOf,
) {
  var top = 0.0;
  for (var i = 0; i < page - 1; i++) {
    top += _extent(width, ratioOf(i));
  }
  return top;
}

/// Görünür alanın ORTASINDAKİ sayfa (1'den).
int pdfColumnPageAt(
  double offset,
  double viewport,
  double width,
  int count,
  double Function(int index) ratioOf,
) {
  if (count <= 0) return 1;
  final line = offset + viewport / 2;
  var bottom = 0.0;
  for (var i = 0; i < count; i++) {
    bottom += _extent(width, ratioOf(i));
    if (bottom > line) return i + 1;
  }
  return count;
}

/// Bölmenin sağ altındaki küçük sayfa hapı ("12 / 240"). Kaydırırken tam,
/// durunca soluk — yalnız RENK ALFASI (Opacity katmanı ayrı çizim geçişi
/// açardı); boyu hiç değişmez (kasma listesi madde 6).
class PdfPagePill extends StatelessWidget {
  const PdfPagePill({
    super.key,
    required this.page,
    required this.count,
    required this.lit,
    this.onTap,
  });

  final ValueListenable<int> page;
  final int count;
  final ValueListenable<bool> lit;

  /// Dokununca sayfaya atlama levhası.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;
    return ValueListenableBuilder<bool>(
      valueListenable: lit,
      builder: (context, on, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: on ? 1 : 0.4),
        duration: const Duration(milliseconds: 300),
        builder: (context, t, _) => GestureDetector(
          key: const ValueKey('pdf-page-pill'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.card.withValues(alpha: tokens.card.a * 0.92 * t),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: tokens.hairline.withValues(alpha: tokens.hairline.a * t),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: ValueListenableBuilder<int>(
                valueListenable: page,
                builder: (context, p, _) => Text(
                  '$p / $count',
                  maxLines: 1,
                  style: style?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: scheme.onSurfaceVariant.a * t,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
