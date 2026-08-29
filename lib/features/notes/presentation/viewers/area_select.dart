import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import '../../../../core/l10n_ext.dart';

/// **ALAN SEÇİMİ** — sayfanın üzerinde bir dikdörtgen çizip o parçayı görüntü
/// olarak almak (kullanıcı isteği: "PDF içerisinden formül yazı seç — alan
/// seçip kopyalama, slayt vs görsel hepsinde").
///
/// Niye metin seçimi yetmiyor: bir formül sayfada METİN olarak durmaz. İndis,
/// kesir çizgisi, kök işareti, integral; bunlar ayrı ayrı yerleştirilmiş
/// glifler (ya da doğrudan çizim) olduğu için metin katmanından kopyalanınca
/// anlamsız bir karakter dizisine dönüşür. Aynısı tablo, grafik ve el yazısı
/// için de geçerli. Bu yüzden seçilen alan METİN olarak değil GÖRÜNTÜ olarak
/// alınır: panoya yapıştırılabilir ve yapay zekâya sorulabilir.
///
/// Yakalama yolu **ekranda görünen katman**dır (`RepaintBoundary.toImage`),
/// belgenin kendisi değil. Gerekçe: aynı kod PDF, sunum ve görselde birebir
/// çalışır (sunum bir belge değil, çizilen bir widget ağacı) ve seçilen alan
/// kullanıcının GÖRDÜĞÜ şeydir — üzerine konmuş vurgu, balon ve el yazısı da
/// dahil. Çözünürlük yakınlaştırmaya bağlı: küçük bir formülü net kopyalamak
/// isteyen önce yakınlaştırır, kayıp olmaz.
class AreaSelectLayer extends StatefulWidget {
  const AreaSelectLayer({
    super.key,
    required this.boundaryKey,
    required this.onCaptured,
    required this.onCancel,
  });

  /// Yakalanacak katmanı saran [RepaintBoundary]'nin anahtarı. Katman bu
  /// widget'ın DIŞINDA olmalı, yoksa karartma ve seçim çerçevesi de
  /// görüntüye girer.
  final GlobalKey boundaryKey;

  /// Seçim tamamlandı: PNG baytları.
  final ValueChanged<Uint8List> onCaptured;

  /// Kip kapatıldı (geri düğmesi / kapat).
  final VoidCallback onCancel;

  @override
  State<AreaSelectLayer> createState() => _AreaSelectLayerState();
}

class _AreaSelectLayerState extends State<AreaSelectLayer> {
  Offset? _start;
  Offset? _current;
  bool _busy = false;

  Rect? get _rect {
    final start = _start;
    final current = _current;
    if (start == null || current == null) return null;
    return Rect.fromPoints(start, current);
  }

  Future<void> _finish() async {
    final rect = _rect;
    setState(() {
      _start = null;
      _current = null;
    });
    if (rect == null) return;
    // 24 dp'den küçük seçim kaza eseri bir dokunuştur; yakalamaya değmez.
    if (rect.width < 24 || rect.height < 24) {
      _snack(context.l10n.areaTooSmall);
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final global = Rect.fromPoints(
      box.localToGlobal(rect.topLeft),
      box.localToGlobal(rect.bottomRight),
    );
    setState(() => _busy = true);
    Uint8List? bytes;
    try {
      bytes = await captureBoundaryArea(
        boundaryKey: widget.boundaryKey,
        globalRect: global,
      );
    } catch (_) {
      bytes = null;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (bytes == null) {
      _snack(context.l10n.areaCaptureFailed);
      return;
    }
    widget.onCaptured(bytes);
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _busy
          ? null
          : (details) => setState(() {
              _start = details.localPosition;
              _current = details.localPosition;
            }),
      onPanUpdate: _busy
          ? null
          : (details) => setState(() => _current = details.localPosition),
      onPanEnd: _busy ? null : (_) => _finish(),
      onPanCancel: _busy
          ? null
          : () => setState(() {
              _start = null;
              _current = null;
            }),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AreaPainter(rect: _rect, color: scheme.primary),
            ),
          ),
          // Yönerge + çıkış: kip açıkken sayfa dokunuşa cevap vermiyor,
          // kullanıcı "dondu mu" diye düşünmesin.
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Material(
              color: scheme.inverseSurface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.areaSelectHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onInverseSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.areaSelectOff,
                      icon: const Icon(Icons.close, size: 18),
                      color: scheme.onInverseSurface,
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

/// Seçim dışını karartır, seçimi çerçeveler. Seçim yokken yalnız hafif bir
/// örtü çizer — kipin açık olduğu görünsün.
class _AreaPainter extends CustomPainter {
  const _AreaPainter({required this.rect, required this.color});

  final Rect? rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final dim = Paint()..color = const Color(0x66000000);
    final selection = rect;
    if (selection == null) {
      canvas.drawRect(full, Paint()..color = const Color(0x1A000000));
      return;
    }
    // Dışarısı karartılır: `evenOdd` ile seçim deliği açılır.
    final path = Path()
      ..addRect(full)
      ..addRect(selection)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dim);
    canvas.drawRect(
      selection,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
      old.rect != rect || old.color != color;
}

/// [boundaryKey] ile işaretlenmiş katmanı yakalar ve [globalRect] parçasını
/// PNG olarak döndürür.
///
/// [pixelRatio] ekran çözünürlüğünün ÜSTÜNDE: küçük bir formülü yakınlaştırmadan
/// seçen kullanıcıda bile yazı okunur kalsın. Yakalama tüm katmanı çözdüğü için
/// oran çok büyük seçilirse bellek sıçrar — 3 ölçülü bir üst sınır.
Future<Uint8List?> captureBoundaryArea({
  required GlobalKey boundaryKey,
  required Rect globalRect,
  double pixelRatio = 3,
}) async {
  final object = boundaryKey.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return null;
  final image = await object.toImage(pixelRatio: pixelRatio);
  ByteData? data;
  try {
    data = await image.toByteData(format: ui.ImageByteFormat.png);
  } finally {
    image.dispose();
  }
  if (data == null) return null;
  final local = Rect.fromPoints(
    object.globalToLocal(globalRect.topLeft),
    object.globalToLocal(globalRect.bottomRight),
  );
  return compute(
    _cropPng,
    _CropRequest(
      png: data.buffer.asUint8List(),
      left: local.left * pixelRatio,
      top: local.top * pixelRatio,
      width: local.width * pixelRatio,
      height: local.height * pixelRatio,
    ),
  );
}

@immutable
class _CropRequest {
  const _CropRequest({
    required this.png,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final Uint8List png;
  final double left;
  final double top;
  final double width;
  final double height;
}

/// Arka planda kırpar: tam ekran bir PNG'yi çözmek UI izolatında birkaç yüz
/// milisaniye tutuyor.
Uint8List? _cropPng(_CropRequest request) {
  final decoded = img.decodeImage(request.png);
  if (decoded == null) return null;
  final left = request.left.round().clamp(0, decoded.width - 1);
  final top = request.top.round().clamp(0, decoded.height - 1);
  final width = request.width.round().clamp(1, decoded.width - left);
  final height = request.height.round().clamp(1, decoded.height - top);
  final cropped = img.copyCrop(
    decoded,
    x: left,
    y: top,
    width: width,
    height: height,
  );
  return Uint8List.fromList(img.encodePng(cropped));
}
