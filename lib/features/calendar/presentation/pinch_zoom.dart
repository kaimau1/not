import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Yakınlaştırma yönü.
enum ZoomDirection { zoomIn, zoomOut }

/// **İKİ PARMAKLA GÖRÜNÜM GEÇİŞİ** (kullanıcı isteği 2026-11-06: "2 parmak
/// zoom ile ay/hafta/yıl geçişi; hafta için neresi zoom yapılırsa o hafta
/// açılmalı"). Hareket yarışmasına GİRMEZ (`Listener`): altındaki dikey
/// kaydırma ve yatay sayfa geçişi tek parmakta aynen çalışır.
///
/// * Dokunmatik: iki parmak arası mesafe oranı eşiği geçince BİR KEZ
///   [onZoom] (hareket başına tek geçiş); eşiğe dek [onPreview] canlı ölçek.
/// * Web/masaüstü: Ctrl+tekerlek (`PointerScaleEvent`) ve dokunmatik yüzey
///   kıstırması (`PointerPanZoom*`) aynı eşikle.
///
/// [onZoom]a odak noktası (KÜRESEL) gider: çağıran o noktadaki ayı/haftayı
/// açar.
class PinchZoomDetector extends StatefulWidget {
  const PinchZoomDetector({
    super.key,
    required this.child,
    required this.onZoom,
    this.onPreview,
    this.onPinchingChanged,
    this.zoomInAt = 1.22,
    this.zoomOutAt = 0.82,
  });

  final Widget child;
  final void Function(ZoomDirection direction, Offset globalFocal) onZoom;

  /// Canlı geri bildirim: ölçek (1 = yok) ve küresel odak.
  final void Function(double scale, Offset globalFocal)? onPreview;

  /// İki parmak inince true, kalkınca false (sayfa kaydırmasını kilitlemek
  /// için).
  final ValueChanged<bool>? onPinchingChanged;
  final double zoomInAt;
  final double zoomOutAt;

  @override
  State<PinchZoomDetector> createState() => _PinchZoomDetectorState();
}

class _PinchZoomDetectorState extends State<PinchZoomDetector> {
  final Map<int, Offset> _pointers = {};
  double? _startDistance;
  bool _fired = false;

  // Tekerlek/yüzey birikimi.
  double _wheelScale = 1;
  Timer? _wheelReset;

  @override
  void dispose() {
    _wheelReset?.cancel();
    super.dispose();
  }

  Offset get _focal {
    final pts = _pointers.values.take(2).toList();
    return (pts[0] + pts[1]) / 2;
  }

  double get _distance {
    final pts = _pointers.values.take(2).toList();
    return math.max((pts[0] - pts[1]).distance, 1);
  }

  void _down(PointerDownEvent e) {
    if (e.kind != PointerDeviceKind.touch &&
        e.kind != PointerDeviceKind.stylus) {
      return;
    }
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      _startDistance = _distance;
      _fired = false;
      widget.onPinchingChanged?.call(true);
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _startDistance;
    if (_pointers.length < 2 || start == null || _fired) return;
    _evaluate(_distance / start, _focal);
  }

  void _up(PointerEvent e) {
    if (_pointers.remove(e.pointer) == null) return;
    if (_pointers.length < 2 && _startDistance != null) {
      _startDistance = null;
      widget.onPreview?.call(1, Offset.zero);
      widget.onPinchingChanged?.call(false);
    }
  }

  void _evaluate(double scale, Offset focal) {
    if (scale >= widget.zoomInAt) {
      _fired = true;
      widget.onPreview?.call(1, focal);
      widget.onZoom(ZoomDirection.zoomIn, focal);
    } else if (scale <= widget.zoomOutAt) {
      _fired = true;
      widget.onPreview?.call(1, focal);
      widget.onZoom(ZoomDirection.zoomOut, focal);
    } else {
      widget.onPreview?.call(scale, focal);
    }
  }

  void _signal(PointerSignalEvent e) {
    if (e is! PointerScaleEvent) return;
    _accumulate(e.scale, e.position);
  }

  void _accumulate(double factor, Offset focal) {
    _wheelReset?.cancel();
    _wheelReset = Timer(const Duration(milliseconds: 350), () {
      _wheelScale = 1;
      _fired = false;
      widget.onPreview?.call(1, focal);
    });
    if (_fired) return;
    _wheelScale *= factor;
    _evaluate(_wheelScale, focal);
  }

  double _panZoomLast = 1;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: _up,
    onPointerSignal: _signal,
    onPointerPanZoomStart: (e) {
      _panZoomLast = 1;
      _wheelScale = 1;
      _fired = false;
    },
    onPointerPanZoomUpdate: (e) {
      // `scale` hareket başından beri toplam; artışı biriktir.
      final step = e.scale / _panZoomLast;
      _panZoomLast = e.scale;
      _accumulate(step, e.position);
    },
    child: widget.child,
  );
}

/// Ekrandaki "neresi" → tarih eşlemesi: görünür sayfa ay karolarını (yıl)
/// ya da hafta satırlarını (ay) buraya kaydeder; odak noktası hangisinin
/// içindeyse o açılır.
class ZoomTargets {
  final Map<GlobalKey, DateTime> _targets = {};

  GlobalKey keyFor(Object id, DateTime date) {
    final key = _keys.putIfAbsent(id, GlobalKey.new);
    _targets[key] = date;
    return key;
  }

  final Map<Object, GlobalKey> _keys = {};

  /// Odak noktasını içeren hedef (yoksa null).
  DateTime? at(Offset global) {
    for (final e in _targets.entries) {
      final box = e.key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(global)) return e.value;
    }
    return null;
  }

  void clear() {
    _targets.clear();
    _keys.clear();
  }
}
