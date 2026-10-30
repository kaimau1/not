import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/color_palette.dart';
import '../viewers/ink_layer.dart';
import '../viewers/ink_pen.dart';
import '../viewers/ink_tools.dart';

/// Tepsideki araçlar (soldan sağa).
enum PenTrayTool { lasso, shapes, eraser, pen, marker, highlighter }

/// **KALEM TEPSİSİ** (kullanıcı isteği 2026-10-28: "örnek çizim ekranı daha
/// görsel olarak bütün ve menüsü güzel"). Araçlar simge değil, tepside
/// duran KALEMLER: cetvel (şekiller), silgi, tükenmez, keçeli, fosforlu.
/// Seçili araç tepsiden yukarı kalkar ve ucu çizilen renktedir — hangi
/// kalemin hangi renkte olduğu bir bakışta görülür. Seçili araca (ya da
/// sağdaki renk düğmesine) yeniden dokunmak ayar panelini açar: renkler,
/// kalınlık (canlı önizlemeli), şekil seçimi, silgide "temizle".
class PenTray extends StatefulWidget {
  const PenTray({super.key, required this.controller});

  final InkController controller;

  @override
  State<PenTray> createState() => _PenTrayState();
}

class _PenTrayState extends State<PenTray> {
  bool _panel = false;

  InkController get _ink => widget.controller;

  PenTrayTool get _current {
    if (_ink.lasso) return PenTrayTool.lasso;
    if (_ink.eraser) return PenTrayTool.eraser;
    if (_ink.arrow || _ink.shape != null) return PenTrayTool.shapes;
    return switch (_ink.pen) {
      InkPen.pen => PenTrayTool.pen,
      InkPen.marker => PenTrayTool.marker,
      InkPen.highlighter => PenTrayTool.highlighter,
    };
  }

  void _tap(PenTrayTool tool) {
    HapticFeedback.selectionClick();
    if (tool == _current) {
      setState(() => _panel = !_panel);
      return;
    }
    switch (tool) {
      case PenTrayTool.lasso:
        _ink.setLasso(true);
      case PenTrayTool.shapes:
        // Son şekil hatırlanmıyor: ok en sık kullanılanı ("şuraya bak").
        _ink.setArrow(true);
      case PenTrayTool.eraser:
        _ink.setEraser(true);
      case PenTrayTool.pen:
        _ink.setPen(InkPen.pen);
      case PenTrayTool.marker:
        _ink.setPen(InkPen.marker);
      case PenTrayTool.highlighter:
        _ink.setPen(InkPen.highlighter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ink,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final current = _current;
    final labels = {
      PenTrayTool.lasso: l10n.inkLasso,
      PenTrayTool.shapes: l10n.inkShapes,
      PenTrayTool.eraser: l10n.eraser,
      PenTrayTool.pen: l10n.penBallpoint,
      PenTrayTool.marker: l10n.penMarker,
      PenTrayTool.highlighter: l10n.penHighlighter,
    };
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: _panel
                  ? _Options(controller: _ink, tool: current)
                  : const SizedBox(width: double.infinity),
            ),
            SizedBox(
              height: 92,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  for (final tool in PenTrayTool.values)
                    Expanded(
                      child: _TrayTool(
                        key: ValueKey('pen-tray-${tool.name}'),
                        tool: tool,
                        label: labels[tool]!,
                        selected: tool == current,
                        ink: _ink.color,
                        onTap: () => _tap(tool),
                      ),
                    ),
                  // RENK düğmesi: seçili renk; dokununca panel.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Tooltip(
                      message: l10n.inkColor,
                      child: InkResponse(
                        key: const ValueKey('pen-tray-color'),
                        radius: 26,
                        onTap: () => setState(() => _panel = !_panel),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _ink.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _panel
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              width: _panel ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tepsideki tek araç: seçiliyse yukarı kalkar (yaylı), altında küçük renk
/// noktası belirir.
class _TrayTool extends StatelessWidget {
  const _TrayTool({
    super.key,
    required this.tool,
    required this.label,
    required this.selected,
    required this.ink,
    required this.onTap,
  });

  final PenTrayTool tool;
  final String label;
  final bool selected;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 320),
                  curve: selected ? Curves.easeOutBack : Curves.easeOutCubic,
                  offset: Offset(0, selected ? 0.02 : 0.24),
                  child: SizedBox(
                    width: 44,
                    height: 96,
                    child: CustomPaint(
                      painter: _ToolPainter(
                        tool: tool,
                        ink: ink,
                        dark: dark,
                        lifted: selected,
                      ),
                    ),
                  ),
                ),
                // Seçili aracın altındaki çizgi (örnekteki gibi).
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 22,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: tool == PenTrayTool.eraser ? scheme.primary : ink,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kalemleri çizer: gövde (soldan ışık alan silindir), konik uç ve renkli
/// uç. Hepsi 44 × 96'lık kutuda, ucu yukarıda.
class _ToolPainter extends CustomPainter {
  const _ToolPainter({
    required this.tool,
    required this.ink,
    required this.dark,
    required this.lifted,
  });

  final PenTrayTool tool;
  final Color ink;
  final bool dark;
  final bool lifted;

  Color get _body => dark ? const Color(0xFF4A4A4F) : const Color(0xFFF4F2EF);
  Color get _bodyShade =>
      dark ? const Color(0xFF2E2E33) : const Color(0xFFD9D5CF);
  Color get _wood => dark ? const Color(0xFFB59A78) : const Color(0xFFEBD3B0);

  Paint _cylinder(Rect r, [Color? base, Color? shade]) =>
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(base ?? _body, Colors.white, dark ? 0.08 : 0.5)!,
            base ?? _body,
            shade ?? _bodyShade,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(r);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Kalkmış aracın gölgesi tepsiye düşer.
    if (lifted) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 12, 30, 24, size.height),
          const Radius.circular(8),
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    switch (tool) {
      case PenTrayTool.pen:
        _ballpoint(canvas, size, cx);
      case PenTrayTool.marker:
        _marker(canvas, size, cx);
      case PenTrayTool.highlighter:
        _highlighter(canvas, size, cx);
      case PenTrayTool.eraser:
        _eraser(canvas, size, cx);
      case PenTrayTool.shapes:
        _setSquare(canvas, size, cx);
      case PenTrayTool.lasso:
        _lasso(canvas, size, cx);
    }
  }

  /// Kement: kesik çizgili ilmek ve sapı.
  void _lasso(Canvas c, Size s, double cx) {
    final handle = Rect.fromLTRB(cx - 5, 46, cx + 5, s.height + 4);
    c.drawRRect(
      RRect.fromRectAndCorners(
        handle,
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      _cylinder(handle),
    );
    final loop = Paint()
      ..color = ink.withAlpha(255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    const dashes = 12;
    final rect = Rect.fromCenter(center: Offset(cx, 26), width: 32, height: 24);
    for (var i = 0; i < dashes; i++) {
      final start = 2 * math.pi * i / dashes;
      c.drawArc(rect, start, math.pi / dashes, false, loop);
    }
    c.drawLine(Offset(cx, 38), Offset(cx, 47), loop);
  }

  void _ballpoint(Canvas c, Size s, double cx) {
    const half = 8.0;
    final body = Rect.fromLTRB(cx - half, 34, cx + half, s.height + 4);
    c.drawRRect(
      RRect.fromRectAndCorners(
        body,
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      _cylinder(body),
    );
    // Konik uç (ahşap/metal) + renkli bilye.
    final cone = Path()
      ..moveTo(cx - half, 35)
      ..lineTo(cx - 2.6, 13)
      ..lineTo(cx + 2.6, 13)
      ..lineTo(cx + half, 35)
      ..close();
    c.drawPath(
      cone,
      _cylinder(body, _wood, Color.lerp(_wood, Colors.black, 0.25)),
    );
    final nib = Path()
      ..moveTo(cx - 2.6, 13.5)
      ..lineTo(cx, 5)
      ..lineTo(cx + 2.6, 13.5)
      ..close();
    c.drawPath(nib, Paint()..color = ink.withAlpha(255));
    // Gövdede rengi gösteren halka.
    c.drawRect(
      Rect.fromLTRB(cx - half, 44, cx + half, 50),
      Paint()..color = ink.withAlpha(235),
    );
  }

  void _marker(Canvas c, Size s, double cx) {
    const half = 11.0;
    final body = Rect.fromLTRB(cx - half, 36, cx + half, s.height + 4);
    c.drawRRect(
      RRect.fromRectAndCorners(
        body,
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      ),
      _cylinder(body),
    );
    final collar = Path()
      ..moveTo(cx - half + 1, 37)
      ..lineTo(cx - 6, 22)
      ..lineTo(cx + 6, 22)
      ..lineTo(cx + half - 1, 37)
      ..close();
    c.drawPath(
      collar,
      _cylinder(body, _bodyShade, Color.lerp(_bodyShade, Colors.black, 0.2)),
    );
    // Yuvarlak keçe uç.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 4.5, 9, cx + 4.5, 23),
        const Radius.circular(4.5),
      ),
      Paint()..color = ink.withAlpha(255),
    );
    c.drawRect(
      Rect.fromLTRB(cx - half, 48, cx + half, 58),
      Paint()..color = ink.withAlpha(220),
    );
  }

  void _highlighter(Canvas c, Size s, double cx) {
    const half = 13.0;
    final body = Rect.fromLTRB(cx - half, 38, cx + half, s.height + 4);
    final tone = Color.lerp(_body, ink.withAlpha(255), 0.18)!;
    c.drawRRect(
      RRect.fromRectAndCorners(
        body,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      _cylinder(body, tone),
    );
    final collar = Path()
      ..moveTo(cx - half + 2, 39)
      ..lineTo(cx - 8, 24)
      ..lineTo(cx + 8, 24)
      ..lineTo(cx + half - 2, 39)
      ..close();
    c.drawPath(
      collar,
      _cylinder(body, _bodyShade, Color.lerp(_bodyShade, Colors.black, 0.2)),
    );
    // Eğik kesik (keski) uç, yarı saydam renkte.
    final chisel = Path()
      ..moveTo(cx - 7, 25)
      ..lineTo(cx - 7, 15)
      ..lineTo(cx + 7, 9)
      ..lineTo(cx + 7, 25)
      ..close();
    c.drawPath(chisel, Paint()..color = ink.withAlpha(200));
  }

  void _eraser(Canvas c, Size s, double cx) {
    const half = 13.0;
    final top = Rect.fromLTRB(cx - half, 14, cx + half, 46);
    final rubber = dark ? const Color(0xFFC98A98) : const Color(0xFFF7B6C3);
    c.drawRRect(
      RRect.fromRectAndCorners(
        top,
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      ),
      _cylinder(top, rubber, Color.lerp(rubber, Colors.black, 0.18)),
    );
    final sleeve = Rect.fromLTRB(
      cx - half - 1,
      44,
      cx + half + 1,
      s.height + 4,
    );
    final blue = dark ? const Color(0xFF3F6A9A) : const Color(0xFF6FA4DA);
    c.drawRRect(
      RRect.fromRectAndCorners(
        sleeve,
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
      _cylinder(sleeve, blue, Color.lerp(blue, Colors.black, 0.25)),
    );
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.7);
    c.drawRect(Rect.fromLTRB(cx - half - 1, 54, cx + half + 1, 57), stripe);
  }

  void _setSquare(Canvas c, Size s, double cx) {
    // Gönye: yarı saydam üçgen cetvel, kenarında ölçü çizgileri.
    final tint = dark ? const Color(0x9988B8E8) : const Color(0xB3A9D2F5);
    final edge = dark ? const Color(0xFF9CC6EE) : const Color(0xFF5E9BD6);
    final tri = Path()
      ..moveTo(cx - 14, 10)
      ..lineTo(cx - 14, s.height + 4)
      ..lineTo(cx + 16, s.height + 4)
      ..close();
    c.drawPath(tri, Paint()..color = tint);
    c.drawPath(
      tri,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final hole = Path()
      ..moveTo(cx - 8, 44)
      ..lineTo(cx - 8, s.height - 6)
      ..lineTo(cx + 4, s.height - 6)
      ..close();
    c.drawPath(
      hole,
      Paint()
        ..color = edge.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final tick = Paint()
      ..color = edge
      ..strokeWidth = 1;
    for (var y = 18.0; y < s.height; y += 6) {
      final long = ((y - 18) / 6).round() % 3 == 0;
      c.drawLine(Offset(cx - 14, y), Offset(cx - (long ? 9 : 11), y), tick);
    }
    // Şeklin seçili rengi küçük bir noktada.
    c.drawCircle(Offset(cx - 6, 22), 3, Paint()..color = ink.withAlpha(255));
  }

  @override
  bool shouldRepaint(_ToolPainter old) =>
      old.tool != tool ||
      old.ink != ink ||
      old.dark != dark ||
      old.lifted != lifted;
}

/// Tepsinin üstünde açılan ayar paneli: renkler, kalınlık/önizleme, araca
/// göre şekiller ya da temizle.
class _Options extends StatelessWidget {
  const _Options({required this.controller, required this.tool});

  final InkController controller;
  final PenTrayTool tool;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final pen = controller.pen;
    final recent = [
      for (final c in InkToolMemory.recentColors.take(4))
        if (!kInkPalette.any((p) => p.toARGB32() == c)) Color(c),
    ];
    Widget dot(Color color) {
      final selected =
          !controller.eraser && controller.color.toARGB32() == color.toARGB32();
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 10),
        child: InkResponse(
          radius: 20,
          onTap: () {
            HapticFeedback.selectionClick();
            controller.setColor(color);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 32 : 28,
            height: selected ? 32 : 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      );
    }

    String shapeLabel(InkShape s) => switch (s) {
      InkShape.line => l10n.inkShapeLine,
      InkShape.rectangle => l10n.inkShapeRectangle,
      InkShape.ellipse => l10n.inkShapeEllipse,
    };
    IconData shapeIcon(InkShape s) => switch (s) {
      InkShape.line => Icons.horizontal_rule_rounded,
      InkShape.rectangle => Icons.crop_square_rounded,
      InkShape.ellipse => Icons.circle_outlined,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tool == PenTrayTool.shapes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.north_east_rounded, size: 18),
                    label: Text(l10n.inkArrow),
                    selected: controller.arrow,
                    onSelected: (_) => controller.setArrow(true),
                  ),
                  for (final s in InkShape.values)
                    ChoiceChip(
                      avatar: Icon(shapeIcon(s), size: 18),
                      label: Text(shapeLabel(s)),
                      selected: controller.shape == s,
                      onSelected: (_) => controller.setShape(s),
                    ),
                ],
              ),
            ),
          if (tool == PenTrayTool.lasso)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: controller.hasSelection
                  ? Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.inkDeleteSelection),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.error,
                          ),
                          onPressed: controller.deleteSelection,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.deselect),
                          label: Text(l10n.inkClearSelection),
                          onPressed: controller.clearSelection,
                        ),
                      ],
                    )
                  : Text(
                      l10n.inkLassoHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          if (tool == PenTrayTool.eraser) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l10n.clearInk),
                onPressed: controller.ink.isEmpty ? null : controller.clear,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l10n.inkPartialEraserTitle),
              subtitle: Text(l10n.inkPartialEraserInfo),
              value: controller.partialEraser,
              onChanged: controller.setPartialEraser,
            ),
          ] else if (tool == PenTrayTool.lasso && !controller.hasSelection)
            const SizedBox.shrink()
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final color in kInkPalette) dot(color),
                  for (final color in recent) dot(color),
                  PaletteButton(
                    title: l10n.paletteMore,
                    size: 28,
                    current: kInkPalette.contains(controller.color)
                        ? null
                        : controller.color,
                    onPicked: controller.setColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Kalınlığın CANLI önizlemesi: gerçek çizgi kalınlığında nokta.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: controller.widthPx.clamp(2.0, 46.0),
                      height: controller.widthPx.clamp(2.0, 46.0),
                      decoration: BoxDecoration(
                        color: controller.penColor,
                        shape: pen == InkPen.highlighter
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: pen.clampWidth(controller.widthPx),
                    min: pen.minWidth,
                    max: pen.maxWidth,
                    onChanged: controller.setWidth,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
