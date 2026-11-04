import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../core/utils/search_fold.dart';

/// **ARAMA VURGUSU AYRI KATMAN (F21.6, KARAR 2026-11-03).**
///
/// KÖK NEDEN (telefonda ölçüldü, arama karesi 139 ms): sorgu her harfte
/// değişiyor, vurgu metnin SPAN'larına (kalın + renk + zemin) gömülü olduğu
/// için görünen her kart yeniden KURULUP metni yeniden ŞEKİLLENDİRİYORDU.
/// Artık metin sorgudan bağımsız (aynı `Text`, aynı yerleşim); eşleşme
/// dikdörtgenleri paragrafın kendi kutularından (`getBoxesForSelection`)
/// hesaplanıp metnin ALTINA boyanır. Sorgu bir [ValueListenable]: değişince
/// yalnız bu katman yeniden BOYANIR — kurulum yok, yerleşim yok.
///
/// Bedel: vurgu artık kalın/renkli yazı değil (glif genişliği değişirdi →
/// yerleşim), zemin + alt çizgi.
class SearchHighlight extends SingleChildRenderObjectWidget {
  const SearchHighlight({
    super.key,
    required this.query,
    required this.fill,
    required this.underline,
    required Widget super.child,
  });

  /// Katlanmamış sorgu (katlama burada, [foldForSearch]).
  final ValueListenable<String> query;
  final Color fill;
  final Color underline;

  @override
  RenderSearchHighlight createRenderObject(BuildContext context) =>
      RenderSearchHighlight(query: query, fill: fill, underline: underline);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSearchHighlight renderObject,
  ) {
    renderObject
      ..query = query
      ..fill = fill
      ..underline = underline;
  }
}

/// Değişmeyen sorgu (arşiv, sürükleme görüntüsü, testler).
class FixedQuery implements ValueListenable<String> {
  const FixedQuery(this.value);

  static const empty = FixedQuery('');

  @override
  final String value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// [text] içinde katlanmış [query]nin bütün eşleşmeleri (başlangıç
/// indeksleri). Katlama uzunluğu korur (F1.8): indeksler özgün metinde de
/// doğru.
List<int> searchMatchStarts(String text, String query) {
  final q = foldForSearch(query);
  if (q.isEmpty) return const [];
  final folded = foldForSearch(text);
  final out = <int>[];
  var start = 0;
  while (true) {
    final i = folded.indexOf(q, start);
    if (i < 0) return out;
    out.add(i);
    start = i + q.length;
  }
}

class RenderSearchHighlight extends RenderProxyBox {
  RenderSearchHighlight({
    required this._query,
    required this._fill,
    required this._underline,
  });

  ValueListenable<String> _query;
  ValueListenable<String> get query => _query;
  set query(ValueListenable<String> value) {
    if (identical(value, _query)) return;
    if (attached) {
      _query.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _query = value;
    markNeedsPaint();
  }

  Color _fill;
  set fill(Color value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsPaint();
  }

  Color _underline;
  set underline(Color value) {
    if (value == _underline) return;
    _underline = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _query.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _query.removeListener(markNeedsPaint);
    super.detach();
  }

  /// Son boyamada vurgulanan aralıklar (test ve tanı için).
  @visibleForTesting
  List<TextRange> debugLastRanges = const [];

  RenderParagraph? _paragraph() {
    RenderParagraph? found;
    void visit(RenderObject o) {
      if (found != null) return;
      if (o is RenderParagraph) {
        found = o;
        return;
      }
      o.visitChildren(visit);
    }

    final c = child;
    if (c != null) visit(c);
    return found;
  }

  /// Şu anki sorguya göre vurgulanacak aralıklar.
  List<TextRange> currentRanges() {
    final q = _query.value.trim();
    if (q.isEmpty) return const [];
    final p = _paragraph();
    if (p == null) return const [];
    final text = p.text.toPlainText(includeSemanticsLabels: false);
    final len = q.length;
    return [
      for (final s in searchMatchStarts(text, q))
        TextRange(start: s, end: s + len),
    ];
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final ranges = currentRanges();
    debugLastRanges = ranges;
    final p = ranges.isEmpty ? null : _paragraph();
    if (p != null && p.hasSize) {
      final toThis = p.getTransformTo(this);
      final canvas = context.canvas;
      final fillPaint = Paint()..color = _fill;
      final linePaint = Paint()..color = _underline;
      canvas.save();
      canvas.clipRect(offset & size);
      for (final r in ranges) {
        final boxes = p.getBoxesForSelection(
          TextSelection(baseOffset: r.start, extentOffset: r.end),
        );
        for (final b in boxes) {
          final rect = MatrixUtils.transformRect(
            toThis,
            b.toRect(),
          ).shift(offset);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(3)),
            fillPaint,
          );
          canvas.drawRect(
            Rect.fromLTRB(
              rect.left,
              rect.bottom - 1.5,
              rect.right,
              rect.bottom,
            ),
            linePaint,
          );
        }
      }
      canvas.restore();
    }
    super.paint(context, offset);
  }
}
