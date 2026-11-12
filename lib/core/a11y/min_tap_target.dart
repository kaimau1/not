import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// **GÖRÜNÜMÜ DEĞİŞTİRMEDEN 48 dp DOKUNMA ALANI** (F15.4, erişilebilirlik).
///
/// Sıkı satırlardaki küçük düğmeler (Süz, ayar araması ✨, dinleme kartının
/// başlık düğmeleri) bilerek 34–40 dp: M3'ün 48 dp'lik kutusu başlığı
/// eziyordu (bkz. `ListeningHeaderButton`). `MaterialTapTargetSize.padded`
/// YER kaplar; bu sarmalayıcı kaplamaz — yerleşimde çocuğun boyunda kalır,
/// yalnız dokunma ve ekran okuyucu sınırı her yönde [minSize]'a büyür.
///
/// Sınır: dokunuşu önce ATA kutular görür; atanın dışına taşan pay
/// yakalanmaz (satırın kendisi 48 dp'den alçaksa kazanç o kadardır). Ekran
/// okuyucu dikdörtgeni her durumda [minSize].
class MinTapTarget extends SingleChildRenderObjectWidget {
  const MinTapTarget({
    super.key,
    this.minSize = kMinInteractiveDimension,
    this.minWidth,
    required super.child,
  });

  final double minSize;

  /// Yatayda ayrı alt sınır (verilmezse [minSize]). Bitişik düğmelerde
  /// (not alt çubuğunun segmentleri, F75.2) pay komşunun GÖRÜNEN kutusuna
  /// taşmasın diye: segment + aradaki boşluk.
  final double? minWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinTapTarget(minSize, minWidth ?? minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) => (renderObject as _RenderMinTapTarget)
    ..minSize = minSize
    ..minWidth = minWidth ?? minSize;
}

class _RenderMinTapTarget extends RenderProxyBox {
  _RenderMinTapTarget(this._minSize, this._minWidth);

  double _minSize;
  set minSize(double value) {
    if (value == _minSize) return;
    _minSize = value;
    markNeedsSemanticsUpdate();
  }

  double _minWidth;
  set minWidth(double value) {
    if (value == _minWidth) return;
    _minWidth = value;
    markNeedsSemanticsUpdate();
  }

  Rect get _target {
    final dx = math.max(0.0, (_minWidth - size.width) / 2);
    final dy = math.max(0.0, (_minSize - size.height) / 2);
    return (Offset.zero & size).grow(dx: dx, dy: dy);
  }

  @override
  Rect get semanticBounds => _target;

  // Düğüm BU kutunun: çocuğun etiketi ve eylemleri içine katılır, ekran
  // okuyucu dikdörtgeni [semanticBounds] olur.
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_target.contains(position)) return false;
    // Pay içindeki dokunuş çocuğun en yakın noktasına iletilir.
    final inside = Offset(
      position.dx.clamp(0.0, math.max(0.0, size.width - 0.01)),
      position.dy.clamp(0.0, math.max(0.0, size.height - 0.01)),
    );
    final hit = hitTestChildren(result, position: inside);
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
}

extension on Rect {
  Rect grow({required double dx, required double dy}) =>
      Rect.fromLTRB(left - dx, top - dy, right + dx, bottom + dy);
}
