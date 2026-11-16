import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// **TEK RENDER NESNELİ SİMGE DÜĞMESİ** — üst çubuğun "Notta ara"sı.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-11-16: "Notta ara butonu not açıldıktan
/// yarım saniye sonra görünüyor, önce yok sonra bir anda geliyor"): düğme
/// hız bütçesi (S18/S19) için açılış geçişi bitince (`AppMotion.long`
/// zamanlayıcısı) kuruluyordu. `IconButton` her karede InkWell + ipucu +
/// odak kurulumunu bütçeye ekliyordu.
///
/// Burada simge, dokunma ve ekran okuyucu adı TEK bir `RenderBox`ta: widget
/// kurulumu yok (RenderObjectElement `build` etmez), ilk karede görünür,
/// rota kapanırken yeniden kurulmaz. Yalnız [IconTheme]'e bağımlıdır
/// (renkli notta üst çubuk rengi).
class GlyphButton extends LeafRenderObjectWidget {
  const GlyphButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = IconTheme.of(context);
    return RenderGlyphButton(
      icon: icon,
      label: label,
      onTap: onTap,
      color: theme.color ?? const Color(0xFF000000),
      glyphSize: theme.size ?? 24,
      direction: Directionality.maybeOf(context) ?? TextDirection.ltr,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGlyphButton renderObject,
  ) {
    final theme = IconTheme.of(context);
    renderObject
      ..icon = icon
      ..label = label
      ..onTap = onTap
      ..color = theme.color ?? const Color(0xFF000000)
      ..glyphSize = theme.size ?? 24
      ..direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }
}

/// [GlyphButton]'ın render nesnesi.
class RenderGlyphButton extends RenderBox {
  RenderGlyphButton({
    required this._icon,
    required this._label,
    required this.onTap,
    required this._color,
    required double glyphSize,
    required this._direction,
  }) : _size = glyphSize {
    _tap = TapGestureRecognizer(debugOwner: this)..onTap = () => onTap();
  }

  late final TapGestureRecognizer _tap;
  VoidCallback onTap;
  final _painter = TextPainter();
  bool _dirtyText = true;

  IconData _icon;
  set icon(IconData v) {
    if (v == _icon) return;
    _icon = v;
    _dirtyText = true;
    markNeedsPaint();
  }

  String _label;
  set label(String v) {
    if (v == _label) return;
    _label = v;
    markNeedsSemanticsUpdate();
  }

  Color _color;
  set color(Color v) {
    if (v == _color) return;
    _color = v;
    _dirtyText = true;
    markNeedsPaint();
  }

  double _size;
  set glyphSize(double v) {
    if (v == _size) return;
    _size = v;
    _dirtyText = true;
    markNeedsPaint();
  }

  TextDirection _direction;
  set direction(TextDirection v) {
    if (v == _direction) return;
    _direction = v;
    _dirtyText = true;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(const Size.square(kMinInteractiveDimension));

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) _tap.addPointer(event);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_dirtyText) {
      _painter
        ..textDirection = _direction
        ..text = TextSpan(
          text: String.fromCharCode(_icon.codePoint),
          style: TextStyle(
            inherit: false,
            color: _color,
            fontSize: _size,
            fontFamily: _icon.fontFamily,
            package: _icon.fontPackage,
            height: 1,
          ),
        )
        ..layout();
      _dirtyText = false;
    }
    final at =
        offset +
        Offset(
          (size.width - _painter.width) / 2,
          (size.height - _painter.height) / 2,
        );
    _painter.paint(context.canvas, at);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isButton = true
      ..label = _label
      ..textDirection = _direction
      ..onTap = () => onTap();
  }

  @override
  void dispose() {
    _tap.dispose();
    _painter.dispose();
    super.dispose();
  }
}
