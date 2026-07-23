import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';

/// Elle çizim yapılan her yerde (çizim ekranı, PDF üstü not) ortak kalem
/// renkleri.
const kInkPalette = <Color>[
  Colors.black,
  Color(0xFFE53935),
  Color(0xFFFB8C00),
  Color(0xFF43A047),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
];

/// Basit çizim ekranı. Kaydedilirse PNG baytlarını döner.
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class Stroke {
  Stroke(this.color, this.width) : points = [];

  final Color color;
  final double width;
  final List<Offset> points;
}

class _DrawingScreenState extends State<DrawingScreen> {
  final _strokes = <Stroke>[];
  final _canvasKey = GlobalKey();
  Color _color = Colors.black;
  double _width = 3;
  bool _saving = false;

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      // Çizim, ekrandaki katmanı yakalayarak (RepaintBoundary.toImage) değil
      // AYNI painter'la yeni bir tuvale yeniden çizilerek üretilir.
      // Katman yakalama CanvasKit'te (web) ekranda görüneni birebir vermiyordu:
      // beyaz zemin geliyor, çizgiler gelmiyordu. Yeniden çizim platformdan ve
      // kare zamanlamasından bağımsız, sonuç her yerde aynı.
      final box = _canvasKey.currentContext!.findRenderObject()! as RenderBox;
      final size = box.size;
      const scale = 2.0; // Retina/yüksek DPI ekranlarda bulanık çıkmasın.

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(scale);
      // Zemin: ekrandaki tuval de beyaz. Şeffaf bırakılırsa JPEG'e
      // dönüştürülürken siyaha döner.
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      DrawingPainter(_strokes).paint(canvas, size);

      final image = await recorder.endRecording().toImage(
        (size.width * scale).round(),
        (size.height * scale).round(),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      // `data.buffer.asUint8List()` (offset/uzunluk vermeden) TÜM arabelleği
      // döndürür — ByteData bir DİLİM ise PNG'nin sonuna çöp bayt eklenir.
      // Android'de toByteData tam arabellek verdiğinden fark edilmiyordu;
      // CanvasKit'te dilim geldiği için tarayıcı çizimi çözemiyor ve
      // "EncodingError: The source image cannot be decoded" hatası veriyordu.
      Navigator.pop(
        context,
        data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (e) {
      // Sessizce yutulursa kullanıcı "Nota ekle"ye basar, ekran kapanmaz ve
      // neden olduğunu anlamaz.
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.attachmentFailed('$e'))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.drawingTitle),
        actions: [
          IconButton(
            tooltip: l10n.undo,
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(() => _strokes.removeLast()),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.addToNote),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: GestureDetector(
                  onPanStart: (details) => setState(() {
                    _strokes.add(
                      Stroke(_color, _width)
                        ..points.add(details.localPosition),
                    );
                  }),
                  onPanUpdate: (details) => setState(
                    () => _strokes.last.points.add(details.localPosition),
                  ),
                  child: CustomPaint(
                    painter: DrawingPainter(_strokes),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  for (final color in kInkPalette)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _color = color),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == color
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.line_weight,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Slider(
                    value: _width,
                    min: 1,
                    max: 12,
                    onChanged: (value) => setState(() => _width = value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter(this.strokes);

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
