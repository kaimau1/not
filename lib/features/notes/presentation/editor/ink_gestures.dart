/// Metnin üstüne PARMAKLA/KALEMLE çizilen jestler (kullanıcı isteği
/// 2026-10-30): maddenin üstünü çizmek ya da ✓ atmak işaretler, karalamak
/// siler, daire içine almak yazımı düzeltir; "Buraya bağla" kipinde daire
/// içine alınan yazıya ek bağlanır.
///
/// Tanıma SAF bir işlevdir ([classifyInkGesture]) — nokta listesinden karar
/// verir, testle korunur. Katman ([InkGestureLayer]) yalnız jest kipi
/// açıkken notun içerik alanını örter: tek parmak çizer, iki parmak sayfayı
/// kaydırır (alttaki kaydırıcı katmanın altında kaldığı için elle).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderEditable;

/// Tanınan jest.
enum InkGesture {
  /// Yatay çizgi (üstünü çiz) → işaretle.
  strike,

  /// ✓ → işaretle.
  check,

  /// Zikzak karalama → sil.
  scribble,

  /// Kapalı halka → yazımı düzelt / (bağlama kipinde) seç.
  circle,

  /// Tanınmadı (ya da dokunuş kadar kısa).
  none,
}

/// Noktaların sınır kutusu.
Rect inkBounds(List<Offset> points) {
  var left = double.infinity, top = double.infinity;
  var right = -double.infinity, bottom = -double.infinity;
  for (final p in points) {
    left = math.min(left, p.dx);
    top = math.min(top, p.dy);
    right = math.max(right, p.dx);
    bottom = math.max(bottom, p.dy);
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

/// Yatayda yön değiştirme sayısı; [hysteresis] dp'den kısa titremeler
/// sayılmaz (elle çizilen düz çizgi de biraz dalgalanır).
int _horizontalReversals(List<Offset> points, {double hysteresis = 8}) {
  var reversals = 0;
  var direction = 0;
  var anchor = points.first.dx;
  for (final p in points.skip(1)) {
    final dx = p.dx - anchor;
    if (dx.abs() < hysteresis) continue;
    final sign = dx > 0 ? 1 : -1;
    if (direction != 0 && sign != direction) reversals++;
    direction = sign;
    anchor = p.dx;
  }
  return reversals;
}

double _pathLength(List<Offset> points) {
  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    length += (points[i] - points[i - 1]).distance;
  }
  return length;
}

/// Bir çizgiyi jest olarak sınıflar. Sıra önemli: karalama da kapanabilir
/// (önce o), halka ✓'ten, ✓ düz çizgiden önce bakılır.
InkGesture classifyInkGesture(List<Offset> points) {
  if (points.length < 4) return InkGesture.none;
  final box = inkBounds(points);
  final w = box.width;
  final h = box.height;
  final extent = math.max(w, h);
  if (extent < 18) return InkGesture.none;
  final length = _pathLength(points);
  final reversals = _horizontalReversals(points);
  final closure = (points.last - points.first).distance / extent;

  // KARALAMA: en az üç yatay dönüş ve kutunun genişliğinin çok üstünde yol.
  if (reversals >= 3 && w >= 20 && length > 2.5 * w) {
    return InkGesture.scribble;
  }
  // HALKA: başa dönen, iki eksende de boyu olan, çevresi kadar yol.
  if (closure < 0.35 &&
      w >= 16 &&
      h >= 12 &&
      math.min(w, h) / extent > 0.18 &&
      // Kapalı halka en az iki genişlik yol alır; kelimeyi saran yassı
      // elips (160×40) ~2,15 × genişlik — eşik 1,8.
      length > 1.8 * extent) {
    return InkGesture.circle;
  }
  // ✓: önce aşağı (kısa), sonra yukarı (uzun); sağa ilerler.
  var lowest = 0;
  for (var i = 1; i < points.length; i++) {
    if (points[i].dy > points[lowest].dy) lowest = i;
  }
  final first = points.first;
  final last = points.last;
  final bottom = points[lowest];
  final down = bottom.dy - first.dy;
  final up = bottom.dy - last.dy;
  if (lowest > 0 &&
      lowest < points.length - 1 &&
      reversals <= 1 &&
      down >= 6 &&
      up > down &&
      up >= 0.5 * h &&
      last.dx > first.dx + 0.3 * w &&
      bottom.dx > first.dx - 4 &&
      h >= 0.3 * w) {
    return InkGesture.check;
  }
  // ÜSTÜNÜ ÇİZ: yatık, düz, en az bir kelime boyu.
  if (w >= 30 && h <= 0.45 * w && reversals <= 1) return InkGesture.strike;
  return InkGesture.none;
}

/// [global] noktanın üstündeki (ya da en yakın, [slop] içinde) düzenlenebilir
/// metin alanı. [root] altındaki öğe ağacı bir kez dolaşılır — yalnız çizgi
/// bitince çağrılır.
EditableTextState? editableTextAt(
  BuildContext root,
  Offset global, {
  double slop = 10,
}) {
  EditableTextState? found;
  void visit(Element element) {
    if (found != null) return;
    if (element is StatefulElement && element.state is EditableTextState) {
      final state = element.state as EditableTextState;
      final RenderEditable box = state.renderEditable;
      if (box.attached && box.hasSize) {
        final rect = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        if (rect.inflate(slop).contains(global)) {
          found = state;
          return;
        }
      }
    }
    element.visitChildren(visit);
  }

  root.visitChildElements(visit);
  return found;
}

/// Daire içine alınan bölgenin metin seçimi ([editable]'ın GÖRÜNTÜ metni
/// konumlarında). Tek satır boyundaki halka o satırın içini, daha uzunu
/// ilk satırın solundan son satırın sağına kadarını seçer. Boşsa null.
TextSelection? selectionInside(RenderEditable editable, Rect lasso) {
  final line = editable.preferredLineHeight;
  final Offset from;
  final Offset to;
  if (lasso.height < line * 1.6) {
    from = Offset(lasso.left, lasso.center.dy);
    to = Offset(lasso.right, lasso.center.dy);
  } else {
    from = Offset(lasso.left, lasso.top + line * 0.5);
    to = Offset(lasso.right, lasso.bottom - line * 0.5);
  }
  final a = editable.getPositionForPoint(from).offset;
  final b = editable.getPositionForPoint(to).offset;
  if (a == b) return null;
  return TextSelection(
    baseOffset: math.min(a, b),
    extentOffset: math.max(a, b),
  );
}

/// Jest kipinin örtüsü: tek parmak çizgisi [onStroke]'a (KÜRESEL noktalar),
/// iki parmak [scrollPosition]'ı kaydırır.
class InkGestureLayer extends StatefulWidget {
  const InkGestureLayer({
    super.key,
    required this.onStroke,
    required this.color,
    this.scrollPosition,
  });

  final ValueChanged<List<Offset>> onStroke;
  final Color color;
  final ScrollPosition? Function()? scrollPosition;

  @override
  State<InkGestureLayer> createState() => _InkGestureLayerState();
}

class _InkGestureLayerState extends State<InkGestureLayer> {
  final _pointers = <int, Offset>{};

  /// Çizilen çizgi: ekranda (katmanın yerel uzayı) ve geri çağrıya giden
  /// KÜRESEL hâli.
  final _points = ValueNotifier<List<Offset>>(const []);
  var _global = <Offset>[];
  int? _strokePointer;

  @override
  void dispose() {
    _points.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    if (_pointers.length == 1) {
      _strokePointer = event.pointer;
      _points.value = [event.localPosition];
      _global = [event.position];
    } else {
      // İkinci parmak: çizgi iptal, kaydırma başlar.
      _strokePointer = null;
      _points.value = const [];
      _global = [];
    }
  }

  void _move(PointerMoveEvent event) {
    final previous = _pointers[event.pointer];
    if (previous == null) return;
    _pointers[event.pointer] = event.position;
    if (event.pointer == _strokePointer) {
      _points.value = [..._points.value, event.localPosition];
      _global.add(event.position);
      return;
    }
    if (_pointers.length >= 2) {
      final position = widget.scrollPosition?.call();
      if (position == null || !position.hasPixels) return;
      final dy = (event.position.dy - previous.dy) / _pointers.length;
      position.jumpTo(
        (position.pixels - dy).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    }
  }

  void _up(PointerEvent event, {bool cancelled = false}) {
    _pointers.remove(event.pointer);
    if (event.pointer != _strokePointer) return;
    _strokePointer = null;
    final points = _global;
    _global = [];
    _points.value = const [];
    if (!cancelled && points.length > 1) widget.onStroke(points);
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: (e) => _up(e, cancelled: true),
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _StrokePainter(_points, widget.color),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.points, this.color) : super(repaint: points);

  final ValueNotifier<List<Offset>> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final list = points.value;
    if (list.length < 2) return;
    final path = Path()..moveTo(list.first.dx, list.first.dy);
    for (final p in list.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.color != color || !identical(old.points, points);
}
