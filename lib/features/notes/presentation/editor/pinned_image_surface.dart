import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show BoxHitTestResult, PipelineOwner, RenderProxyBox;

import '../../domain/attachment.dart';
import '../viewers/ink_layer.dart';
import 'page_ink_layer.dart' show InkClaim;

/// Sabit görselin `contain` dikdörtgeni (balon ve mürekkep katmanlarının ortak
/// uzayı). Ekte piksel ölçüsü eksikse yoklanan [probedRatio] (`h / w`) ile
/// hesaplanır ki kalem/silgi ölçüsüz görsellerde de kaymadan çalışsın.
Rect? computePinnedImageRect(
  Size box, {
  int? width,
  int? height,
  double? probedRatio,
}) {
  if (box.isEmpty) return null;
  var w = (width ?? 0).toDouble();
  var h = (height ?? 0).toDouble();
  if (w <= 0 || h <= 0) {
    final ratio = probedRatio;
    if (ratio == null || !ratio.isFinite || ratio <= 0) return null;
    w = 1.0;
    h = ratio;
  }
  final scale = (box.width / w) < (box.height / h)
      ? box.width / w
      : box.height / h;
  final dw = w * scale;
  final dh = h * scale;
  return Rect.fromLTWH((box.width - dw) / 2, (box.height - dh) / 2, dw, dh);
}

/// Sabit görsel üzerindeki mürekkep katmanı: kalem kipi açıksa etkileşimli
/// [InkClaim] + [InkPageLayer], kapalıyken salt okunur [InkPainter] çizer.
class PinnedImageInkSurface extends StatelessWidget {
  const PinnedImageInkSurface({
    super.key,
    required this.strokes,
    required this.revision,
    required this.width,
    required this.height,
    required this.probedRatio,
    this.activeController,
  });

  final List<InkStroke> strokes;
  final int revision;
  final int? width;
  final int? height;
  final double? probedRatio;
  final InkController? activeController;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final rect = computePinnedImageRect(
        box.biggest,
        width: width,
        height: height,
        probedRatio: probedRatio,
      );
      if (rect == null) return const SizedBox.shrink();
      final pen = activeController;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fromRect(
            rect: rect,
            child: pen == null
                ? IgnorePointer(
                    child: CustomPaint(
                      painter: InkPainter(strokes, 1, revision: revision),
                    ),
                  )
                : InkClaim(
                    ink: pen,
                    child: InkPageLayer(controller: pen, page: 1),
                  ),
          ),
        ],
      );
    },
  );
}

/// [FitWidthBox] kaydırma durumu: konum ve son yerleşimden tavan.
class FitScroll extends ChangeNotifier {
  double offset = 0;
  double max = 0;

  void by(double dy) => to(offset + dy);

  void to(double value) {
    final next = value.clamp(0.0, max);
    if (next == offset) return;
    offset = next;
    notifyListeners();
  }
}

/// Çocuğu bölmenin genişliğinde, `ratio * genişlik` boyunda dizer; bölmeyi
/// doldurur ve çocuğu [scroll] kadar yukarı kaydırıp kırparak boyar.
class FitWidthBox extends SingleChildRenderObjectWidget {
  const FitWidthBox({
    super.key,
    required this.ratio,
    required this.scroll,
    required super.child,
    this.whole = false,
  });

  final double ratio;
  final FitScroll scroll;
  final bool whole;

  @override
  RenderFitWidthBox createRenderObject(BuildContext context) =>
      RenderFitWidthBox(ratio, scroll)..whole = whole;

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFitWidthBox renderObject,
  ) {
    renderObject
      ..ratio = ratio
      ..whole = whole
      ..scroll = scroll;
  }
}

class RenderFitWidthBox extends RenderProxyBox {
  RenderFitWidthBox(this._ratio, this._scroll);

  double _ratio;
  set ratio(double v) {
    if (v == _ratio) return;
    _ratio = v;
    markNeedsLayout();
  }

  bool _whole = false;
  set whole(bool v) {
    if (v == _whole) return;
    _whole = v;
    markNeedsLayout();
  }

  FitScroll _scroll;
  set scroll(FitScroll v) {
    if (identical(v, _scroll)) return;
    if (attached) {
      _scroll.removeListener(_changed);
      v.addListener(_changed);
    }
    _scroll = v;
    markNeedsPaint();
  }

  void _changed() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  double get _dy => _scroll.offset.clamp(0.0, _scroll.max);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scroll.addListener(_changed);
  }

  @override
  void detach() {
    _scroll.removeListener(_changed);
    super.detach();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    final width = size.width;
    final height = _whole ? size.height : math.max(width * _ratio, size.height);
    child.layout(BoxConstraints.tight(Size(width, height)));
    _scroll.max = math.max(0, height - size.height);
    if (_scroll.offset > _scroll.max) _scroll.offset = _scroll.max;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => context.paintChild(child, offset + Offset(0, -_dy)),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || !(Offset.zero & size).contains(position)) {
      return false;
    }
    return result.addWithPaintOffset(
      offset: Offset(0, -_dy),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, -_dy, 0, 1);
  }
}
