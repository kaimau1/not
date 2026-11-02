import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/attachment.dart';
import '../presentation/viewers/ink_layer.dart' show InkPainter;

/// **Görselin üstündeki çizim ve yazılar dışa aktarmada** (F18.13,
/// 2026-11-02). KALANLAR §3 (2026-07'den beri): görsele çizilen kalem izi ve
/// Paint tarzı açık metin (`PageBubble.plain`) yalnız uygulamada görünüyor,
/// PDF/Word dışa aktarımında ve paylaşılan görselde YOKTU — görselin ham
/// baytları gidiyordu. Burada katmanlar görselin üstüne "basılır" (PNG).

/// Görselin basılacak bir katmanı var mı.
bool hasImageAnnotations(Attachment a) =>
    a.kind == AttachmentKind.image &&
    (a.ink.isNotEmpty || a.bubbles.any((b) => _label(b).isNotEmpty));

String _label(PageBubble b) {
  final title = b.title.trim();
  final text = b.text.trim();
  if (title.isEmpty) return text;
  if (text.isEmpty) return title;
  return '$title\n$text';
}

/// Uzun kenar bu sınırı aşarsa basılmış görsel küçültülür (bellek).
const _maxEdge = 2400;

/// Görsel + çizim + yazı → PNG. Çözülemezse ya da katman yoksa null
/// (çağıran ham baytla sürer).
Future<Uint8List?> burnImageAnnotations(Uint8List bytes, Attachment a) async {
  if (!hasImageAnnotations(a)) return null;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final scale = math.min(1.0, _maxEdge / math.max(image.width, image.height));
    final w = (image.width * scale).round();
    final h = (image.height * scale).round();
    final size = Size(w.toDouble(), h.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
    // Görsel tek "sayfa": çizgiler 1. sayfada (bkz. görsel çizim aracı).
    InkPainter(a.ink, 1).paint(canvas, size);
    for (final b in a.bubbles) {
      final label = _label(b);
      if (label.isEmpty) continue;
      _paintBubble(canvas, size, b, label);
    }
    final picture = recorder.endRecording();
    final out = await picture.toImage(w, h);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    out.dispose();
    picture.dispose();
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

void _paintBubble(Canvas canvas, Size size, PageBubble b, String label) {
  final anchor = Offset(b.x * size.width, b.y * size.height);
  final color = Color(b.color);
  final base = size.width * 0.035;
  if (b.plain) {
    // Açık metin: yazı doğrudan görselin üstünde, balonun renginde.
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: base * b.size,
          fontWeight: b.bold ? FontWeight.w700 : FontWeight.w500,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(1, size.width - anchor.dx));
    painter.paint(canvas, anchor);
    painter.dispose();
    return;
  }
  // Normal balon: renkli iğne + yanında okunur kart.
  final r = base * 0.45;
  canvas.drawCircle(anchor, r, Paint()..color = color);
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(color: const Color(0xFF1B1B1B), fontSize: base * 0.8),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: math.max(1, size.width * 0.45));
  final pad = base * 0.3;
  double left = anchor.dx + r + pad;
  if (left + painter.width + pad * 2 > size.width) {
    left = math.max(0.0, anchor.dx - r - pad - painter.width - pad * 2);
  }
  final top = (anchor.dy - painter.height / 2 - pad)
      .clamp(0.0, math.max(0.0, size.height - painter.height - pad * 2))
      .toDouble();
  final box = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, painter.width + pad * 2, painter.height + pad * 2),
    Radius.circular(pad),
  );
  canvas
    ..drawRRect(box, Paint()..color = const Color(0xF2FFFFFF))
    ..drawRRect(
      box,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, base * 0.08),
    );
  painter.paint(canvas, Offset(left + pad, top + pad));
  painter.dispose();
}

/// Dışa aktarmaya girecek baytlar: katmanlıysa basılmış PNG + boyut, değilse
/// ham bayt (F18.13). [mimeType] PNG'ye döner.
Future<({Uint8List bytes, String mimeType, int? width, int? height})>
exportImageBytes(Uint8List bytes, Attachment a) async {
  final burned = await burnImageAnnotations(bytes, a);
  if (burned == null) {
    return (
      bytes: bytes,
      mimeType: a.mimeType,
      width: a.width,
      height: a.height,
    );
  }
  final codec = await ui.instantiateImageCodec(burned);
  final frame = await codec.getNextFrame();
  final dims = (frame.image.width, frame.image.height);
  frame.image.dispose();
  return (
    bytes: burned,
    mimeType: 'image/png',
    width: dims.$1,
    height: dims.$2,
  );
}
