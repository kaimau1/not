import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/scan/scan_ocr.dart';

/// **KALEMLE YAZ → METİN** (kullanıcı isteği 2026-11-08: "kalem aktifken
/// balon metin yazma alanına kalemle yazılabilsin, otomatik metne dönüşsün").
///
/// Alanın üstüne KALEM değince (parmak/klavye alana gider) mürekkep çizilir;
/// kalem 0,9 sn kalkık kalınca çizgiler beyaz zemine basılır ve cihaz içi
/// OCR'dan (ML Kit, Türkçe harfler dahil — notta zaten kullanılan) geçen
/// yazı [onText] ile alana eklenir.
///
/// ponytail: el yazısı OCR'ı düzgün el yazısında iyi, bitişik yazıda zayıf;
/// gerekirse ML Kit Digital Ink (dil modeli indirir) ile değiştir.
class HandwriteField extends StatefulWidget {
  const HandwriteField({super.key, required this.onText, required this.child});

  final ValueChanged<String> onText;
  final Widget child;

  @override
  State<HandwriteField> createState() => _HandwriteFieldState();
}

class _HandwriteFieldState extends State<HandwriteField> {
  final _strokes = ValueNotifier<List<List<Offset>>>(const []);
  Timer? _idle;
  bool _busy = false;

  @override
  void dispose() {
    _idle?.cancel();
    _strokes.dispose();
    super.dispose();
  }

  void _down(Offset p) {
    _idle?.cancel();
    _strokes.value = [
      ..._strokes.value,
      [p],
    ];
  }

  void _move(Offset p) {
    final all = _strokes.value;
    if (all.isEmpty) return;
    _strokes.value = [
      ...all.sublist(0, all.length - 1),
      [...all.last, p],
    ];
  }

  void _up() {
    _idle?.cancel();
    _idle = Timer(const Duration(milliseconds: 900), _recognize);
  }

  Future<void> _recognize() async {
    final strokes = _strokes.value;
    if (strokes.isEmpty || _busy) return;
    _busy = true;
    try {
      final path = await _render(strokes);
      final lines = await ScanOcr.recognizeImageLines(path);
      unawaited(File(path).delete().catchError((_) => File(path)));
      final text = lines.map((l) => l.text.trim()).join(' ').trim();
      if (text.isNotEmpty && mounted) widget.onText(text);
    } catch (_) {
      // Tanınamadı: çizgi silinir, kullanıcı yeniden yazar.
    } finally {
      _busy = false;
      if (mounted) _strokes.value = const [];
    }
  }

  /// Çizgileri beyaz zemine, kenar boşluklu ve OCR'ın sevdiği boya basar.
  Future<String> _render(List<List<Offset>> strokes) async {
    var l = double.infinity, t = double.infinity;
    var r = -double.infinity, b = -double.infinity;
    for (final s in strokes) {
      for (final p in s) {
        l = math.min(l, p.dx);
        t = math.min(t, p.dy);
        r = math.max(r, p.dx);
        b = math.max(b, p.dy);
      }
    }
    const pad = 24.0;
    // Yazı yüksekliği ~80 px olsun (çok küçük el yazısı OCR'da kaçar).
    final scale = (80 / math.max(1, b - t)).clamp(1.0, 4.0);
    final w = ((r - l) * scale + pad * 2).ceil();
    final h = ((b - t) * scale + pad * 2).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = Colors.white,
      );
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4 * scale.toDouble()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      final path = Path();
      for (var i = 0; i < s.length; i++) {
        final p = Offset((s[i].dx - l) * scale + pad, (s[i].dy - t) * scale + pad);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
    final image = await recorder.endRecording().toImage(w, h);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/handwrite_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png!.buffer.asUint8List());
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    if (!ScanOcr.supported) return widget.child;
    final color = Theme.of(context).colorScheme.onSurface;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: {
              _StylusClaim: GestureRecognizerFactoryWithHandlers<_StylusClaim>(
                _StylusClaim.new,
                (r) => r
                  ..onDown = _down
                  ..onMove = _move
                  ..onUp = _up,
              ),
            },
            child: IgnorePointer(
              child: ValueListenableBuilder<List<List<Offset>>>(
                valueListenable: _strokes,
                builder: (_, strokes, _) => CustomPaint(
                  painter: _StrokesPainter(strokes, color),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Yalnız KALEM dokunuşunu ilk anda üstlenir (alttaki metin alanı seçim
/// sürüklemesine başlamasın); parmak yarışa hiç girmez.
class _StylusClaim extends OneSequenceGestureRecognizer {
  _StylusClaim() : super(supportedDevices: const {
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
        });

  ValueChanged<Offset>? onDown;
  ValueChanged<Offset>? onMove;
  VoidCallback? onUp;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
    onDown?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onMove?.call(event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      onUp?.call();
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'stylus-claim';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter(this.strokes, this.color);

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => old.strokes != strokes;
}
