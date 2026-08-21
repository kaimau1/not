import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/arrow.dart';
import '../domain/attachment.dart';

/// Görsel eklerin üzerine yapılan **çizim ve metin/balonları görselin
/// BAYTLARINA basar**.
///
/// Neden gerekli: çizim ([InkStroke]) ve balonlar ([PageBubble]) — Paint tarzı
/// açık metin alanı dahil — dosyaya gömülmez, ekin yanında oran (0–1) uzayında
/// durur ve yalnız uygulama içindeki katmanlarda çizilir. Bu yüzden görseli
/// dışa aktarırken (PDF/Word) ya da panoya alırken üzerine yazılan metin
/// gidiyordu (KALANLAR 2026-08-16 maddesi).
///
/// PDF eklerinin karşılığı [PdfEdit.burnForSharing]; burası aynı görünümü
/// **raster** tarafta üretir: görsel çözülür, üstüne aynı kurallarla çizilir ve
/// PNG olarak geri verilir. Ekin kendisine DOKUNULMAZ — damgalı kopya yalnız
/// dışa aktarılan/paylaşılan bayttır, uygulamadaki katman düzenlenebilir kalır.
///
/// **Ana izolede çağrılmalı**: `dart:ui` çizimi (Picture → Image) motor
/// gerektirir, `Isolate.run` içinde çalışmaz.
class ImageStamp {
  const ImageStamp._();

  /// Görsel tek "sayfa" olduğu için çizim/balon verisi hep 1. sayfada durur
  /// (bkz. `image_viewer.dart`).
  static const _page = 1;

  /// Ekranda 16 px'lik açık metin ([PageBubble.baseFontSize]) görselin
  /// genişliğinin oranına çevrilir — [PdfEdit] damgasıyla aynı katsayı, ki
  /// aynı not PDF'e ve görsele aynı boyda düşsün.
  static const _fontRatio = 0.028;

  /// Bu ekte basılacak bir şey var mı? Yoksa çağıran özgün baytı kullanmalı:
  /// yeniden kodlamak (JPEG → PNG) dosyayı gereksiz büyütür.
  static bool needed(Attachment attachment) =>
      attachment.kind == AttachmentKind.image &&
      (attachment.ink.any((s) => s.points.length >= 4) ||
          attachment.bubbles.any(_drawable));

  static bool _drawable(PageBubble b) =>
      b.isHighlight || b.text.trim().isNotEmpty || b.title.trim().isNotEmpty;

  /// [bytes]'ın üstüne ekin çizimini ve balonlarını basıp **PNG** döner.
  ///
  /// Basılacak bir şey yoksa ya da görsel çözülemezse özgün baytlar aynen
  /// döner: damga tek bir bozuk görsel yüzünden dışa aktarmayı düşürmemeli.
  static Future<Uint8List> burn(
    Uint8List bytes,
    Attachment attachment,
  ) async {
    if (!needed(attachment)) return bytes;
    try {
      final image = await _decode(bytes);
      try {
        final size = ui.Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(
          recorder,
          ui.Rect.fromLTWH(0, 0, size.width, size.height),
        );
        canvas.drawImage(image, ui.Offset.zero, ui.Paint());
        _drawStrokes(canvas, attachment.ink, size);
        for (final bubble in attachment.bubbles) {
          if (bubble.page != _page) continue;
          _drawHighlight(canvas, bubble, size);
        }
        for (final bubble in attachment.bubbles) {
          if (bubble.page != _page || !_drawable(bubble)) continue;
          _drawNote(canvas, bubble, size);
        }
        final picture = recorder.endRecording();
        try {
          final out = await picture.toImage(image.width, image.height);
          try {
            final data = await out.toByteData(format: ui.ImageByteFormat.png);
            if (data == null) return bytes;
            return data.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            );
          } finally {
            out.dispose();
          }
        } finally {
          picture.dispose();
        }
      } finally {
        image.dispose();
      }
    } catch (_) {
      return bytes;
    }
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  /// Çizgiler — ekrandaki `InkPainter` ile aynı kurallar: ok gövde + dolu
  /// başlık, tek noktalı çizgi nokta, fosforlu kalem (saydam renk) düz uçlu.
  static void _drawStrokes(
    ui.Canvas canvas,
    List<InkStroke> strokes,
    ui.Size size,
  ) {
    for (final s in strokes) {
      if (s.page != _page || s.points.length < 2) continue;
      final color = ui.Color(s.color);
      final width = (s.width * size.width).clamp(0.1, 400.0);
      final highlighter = color.a < 1;
      final paint = ui.Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = highlighter ? ui.StrokeCap.butt : ui.StrokeCap.round
        ..strokeJoin = highlighter ? ui.StrokeJoin.bevel : ui.StrokeJoin.round
        ..style = ui.PaintingStyle.stroke;
      ui.Offset at(int i) =>
          ui.Offset(s.points[i] * size.width, s.points[i + 1] * size.height);
      if (s.arrow && s.points.length >= 4) {
        final tail = at(0);
        final head = at(2);
        final geo = arrowGeometry(tail, head, width);
        canvas
          ..drawLine(tail, geo.lineEnd, paint)
          ..drawPath(
            ui.Path()
              ..moveTo(head.dx, head.dy)
              ..lineTo(geo.left.dx, geo.left.dy)
              ..lineTo(geo.right.dx, geo.right.dy)
              ..close(),
            ui.Paint()
              ..color = color
              ..style = ui.PaintingStyle.fill,
          );
        continue;
      }
      if (s.points.length == 2) {
        canvas.drawCircle(
          at(0),
          width / 2,
          ui.Paint()
            ..color = color
            ..style = ui.PaintingStyle.fill,
        );
        continue;
      }
      final path = ui.Path()..moveTo(at(0).dx, at(0).dy);
      for (var i = 2; i + 1 < s.points.length; i += 2) {
        path.lineTo(at(i).dx, at(i).dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Metin vurgusu: balonun renginin soluk hâliyle boyanmış dikdörtgenler
  /// (PDF damgasındaki 0.28 saydamlığın aynısı — altındaki yazı okunur kalır).
  static void _drawHighlight(
    ui.Canvas canvas,
    PageBubble bubble,
    ui.Size size,
  ) {
    if (bubble.rects.isEmpty) return;
    final paint = ui.Paint()
      ..color = ui.Color(bubble.color).withValues(alpha: 0.28)
      ..style = ui.PaintingStyle.fill;
    for (final r in bubble.rects) {
      final rect = ui.Rect.fromLTRB(
        r.left * size.width,
        r.top * size.height,
        r.right * size.width,
        r.bottom * size.height,
      );
      if (rect.width <= 0 || rect.height <= 0) continue;
      canvas.drawRect(rect.inflate(0.5), paint);
    }
  }

  static void _drawNote(ui.Canvas canvas, PageBubble bubble, ui.Size size) {
    if (bubble.plain) {
      _drawPlainText(canvas, bubble, size);
      return;
    }
    _drawCard(canvas, bubble, size);
  }

  /// Paint tarzı AÇIK METİN: kutusuz, doğrudan görselin üstüne. Ekranda
  /// olduğu gibi ÇİFT çizilir (koyu/açık dış hat + kendi rengi) — fotoğrafın
  /// parlak bir yerine düşen yazı yoksa okunmuyor.
  static void _drawPlainText(
    ui.Canvas canvas,
    PageBubble bubble,
    ui.Size size,
  ) {
    final text = bubble.text.trim();
    if (text.isEmpty) return;
    final color = ui.Color(bubble.color);
    final fontSize = (size.width * _fontRatio * bubble.size).clamp(4.0, 400.0);
    final maxWidth = math.max(
      size.width * 0.2,
      size.width - bubble.x * size.width,
    );
    final outline = color.computeLuminance() < 0.5
        ? const ui.Color(0xFFFFFFFF).withValues(alpha: 0.85)
        : const ui.Color(0xFF000000).withValues(alpha: 0.7);
    TextPainter painter(ui.Paint? foreground) => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.2,
          color: foreground == null ? color : null,
          foreground: foreground,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final body = painter(null);
    final at = ui.Offset(
      (bubble.x * size.width).clamp(
        0.0,
        math.max(0.0, size.width - body.width),
      ),
      (bubble.y * size.height).clamp(
        0.0,
        math.max(0.0, size.height - body.height),
      ),
    );
    painter(
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = math.max(2, fontSize / 6)
          ..color = outline,
      )
      ..paint(canvas, at)
      ..dispose();
    body
      ..paint(canvas, at)
      ..dispose();
  }

  /// Normal balon: ucundaki renkli nokta + fiş görünümlü not kutusu
  /// ([PdfEdit] damgasının raster karşılığı).
  static void _drawCard(ui.Canvas canvas, PageBubble bubble, ui.Size size) {
    final color = ui.Color(bubble.color);
    final anchor = ui.Offset(
      (bubble.x * size.width).clamp(0.0, size.width),
      (bubble.y * size.height).clamp(0.0, size.height),
    );
    final scale = size.width / 600; // PDF damgasının punto/dolgu ölçeği.
    canvas
      ..drawCircle(
        anchor,
        3 * scale,
        ui.Paint()
          ..color = color
          ..style = ui.PaintingStyle.fill,
      )
      ..drawCircle(
        anchor,
        3 * scale,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..strokeWidth = 0.8 * scale
          ..style = ui.PaintingStyle.stroke,
      );

    final head = bubble.title.trim();
    // Uzun not kutuyu sayfanın yarısına çıkarırdı: damgaya ilk 400 karakter
    // girer (PDF damgasıyla aynı sınır), tamamı uygulamada durur.
    final runes = bubble.text.trim().runes.toList();
    final text = runes.length > 400
        ? '${String.fromCharCodes(runes.take(400))}…'
        : bubble.text.trim();
    if (head.isEmpty && text.isEmpty) return;

    final pad = 5.0 * scale;
    final width = math.min(200.0 * scale, math.max(90.0 * scale, size.width * 0.42));
    final stripe = 4.0 * scale;
    final inner = math.max(10.0, width - pad * 2 - stripe);
    TextPainter? block(String value, double fontSize, Color textColor) {
      if (value.isEmpty) return null;
      return TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.25,
            color: textColor,
            fontWeight: fontSize > 9 * scale
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: inner);
    }

    final title = block(head, 9 * scale, const ui.Color(0xFF141414));
    final body = block(text, 8.5 * scale, const ui.Color(0xFF232323));
    final height =
        pad * 2 +
        (title?.height ?? 0) +
        (title == null || body == null ? 0 : 2 * scale) +
        (body?.height ?? 0);

    // Kutu ucun ALTINA açılır; sığmıyorsa üstüne alınır.
    var top = anchor.dy + 8 * scale;
    if (top + height > size.height) top = anchor.dy - 8 * scale - height;
    final box = ui.Rect.fromLTWH(
      (anchor.dx - width / 2).clamp(0.0, math.max(0.0, size.width - width)),
      top.clamp(0.0, math.max(0.0, size.height - height)),
      width,
      height,
    );
    canvas
      ..drawRect(
        box,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.95)
          ..style = ui.PaintingStyle.fill,
      )
      ..drawRect(
        box,
        ui.Paint()
          ..color = color.withValues(alpha: 0.45)
          ..strokeWidth = math.max(0.6, 0.6 * scale)
          ..style = ui.PaintingStyle.stroke,
      )
      ..drawRect(
        ui.Rect.fromLTWH(box.left, box.top, stripe, box.height),
        ui.Paint()
          ..color = color
          ..style = ui.PaintingStyle.fill,
      );
    var y = box.top + pad;
    if (title != null) {
      final titleHeight = title.height;
      title
        ..paint(canvas, ui.Offset(box.left + stripe + pad, y))
        ..dispose();
      y += titleHeight + (body == null ? 0 : 2 * scale);
    }
    if (body != null) {
      body
        ..paint(canvas, ui.Offset(box.left + stripe + pad, y))
        ..dispose();
    }
  }
}
