import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme/app_tokens.dart';

/// **KLAVYE ODAK HALKASI** (DENEYIM F80.3c, OTURTMA F67.7): klavyeyle (Tab,
/// oklar) gezinirken odaklı öğenin çevresinde 2 dp `primary` halka. Material
/// düğmeleri odakta yalnız %12'lik bir dolgu alıyordu; açık kâğıt zeminde
/// hangi öğede olunduğu görünmüyordu.
///
/// Yalnız [FocusHighlightMode.traditional]'da çizilir — Flutter bu kipe
/// fiziksel tuşa basılınca geçer, dokununca/tıklayınca çıkar. Telefonda
/// (dokunmatik) hiç görünmez, fareyle tıklayınca da kaybolur.
///
/// Çizilmeyenler: metin alanı (imleci var), ekranın yarısından büyük odak
/// kapsamları (çerçevenin kendi `Focus`'u, sayfa) ve boş kutular.
///
/// AĞAÇ ŞEKLİ SABİT: hep `Stack(child, IgnorePointer(CustomPaint))`; halka
/// yalnız boyamada değişir (CLAUDE.md kasma listesi 4). Konum her çizilen
/// karenin SONUNDA okunur (kare istemeden); değiştiyse bir kare daha boyanır.
class KeyboardFocusRing extends StatefulWidget {
  const KeyboardFocusRing({super.key, required this.child});

  final Widget child;

  /// Odak kutusunun ekran alanına oranı bunu aşarsa halka çizilmez.
  static const double maxAreaFraction = 0.5;

  @override
  State<KeyboardFocusRing> createState() => _KeyboardFocusRingState();
}

class _KeyboardFocusRingState extends State<KeyboardFocusRing> {
  final _rect = ValueNotifier<Rect?>(null);
  bool _frameHooked = false;
  Size _screen = Size.zero;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_update);
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_update);
    FocusManager.instance.removeHighlightModeListener(_onMode);
    _rect.dispose();
    super.dispose();
  }

  void _onMode(FocusHighlightMode _) => _update();

  void _update() {
    if (!mounted) return;
    _rect.value = ringRectFor(
      FocusManager.instance.primaryFocus,
      FocusManager.instance.highlightMode,
      _screen,
    );
    // Halka görünürken kaydırma/yerleşim değişince konum kareden kareye
    // izlenir; kare İSTEMEZ, yalnız çizilen karenin sonunda bakar.
    if (_rect.value != null && !_frameHooked) {
      _frameHooked = true;
      SchedulerBinding.instance.addPostFrameCallback(_afterFrame);
    }
  }

  void _afterFrame(Duration _) {
    _frameHooked = false;
    _update();
  }

  @override
  Widget build(BuildContext context) {
    _screen = MediaQuery.sizeOf(context);
    final color = Theme.of(context).colorScheme.primary;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('keyboard-focus-ring'),
                painter: FocusRingPainter(_rect, color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Halkanın kutusu (genel koordinatta) ya da null. Test edilebilsin diye ayrı.
Rect? ringRectFor(FocusNode? node, FocusHighlightMode mode, Size screen) {
  if (mode != FocusHighlightMode.traditional || node == null) return null;
  final context = node.context;
  if (context == null || !context.mounted) return null;
  final render = context.findRenderObject();
  if (render is! RenderBox || !render.attached || !render.hasSize) return null;
  // Metin alanı: imleç zaten odağı gösterir.
  if (context.widget is EditableText ||
      context.findAncestorWidgetOfExactType<EditableText>() != null) {
    return null;
  }
  final Rect rect;
  try {
    rect = node.rect;
  } on Object {
    return null;
  }
  if (rect.isEmpty) return null;
  final area = screen.width * screen.height;
  if (area <= 0 ||
      rect.width * rect.height > area * KeyboardFocusRing.maxAreaFraction) {
    return null;
  }
  return rect;
}

class FocusRingPainter extends CustomPainter {
  FocusRingPainter(this.rect, this.color) : super(repaint: rect);

  final ValueListenable<Rect?> rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = rect.value;
    if (r == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(AppRadius.m)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(FocusRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rect != rect;
}
