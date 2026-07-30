import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';

/// Görselin kullanılacak alanını seçtiren ekran. Sonuç `Navigator.pop` ile
/// GÖRSEL ORANINDA (0–1) bir dikdörtgen olarak döner; kırpmayı yapan taraf
/// bilir. İptal edilirse null döner.
///
/// ponytail: kırpma için paket EKLENMEDİ — dört köşe tutamacı + gövde
/// sürüklemesi bu kadar; hazır paketler ayrıca Windows'ta çalışmıyor
/// (uygulama Android + Windows hedefli).
class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.image,
    required this.aspect,
  });

  final ImageProvider image;

  /// Görselin en/boy oranı; kırpma katmanı görselin KUTUSUYLA birebir aynı
  /// olmalı, yoksa seçilen alan ile kırpılan alan kayar.
  final double aspect;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

enum _Handle { topLeft, topRight, bottomLeft, bottomRight, body }

class _ImageCropScreenState extends State<ImageCropScreen> {
  /// En küçük kırpma oranı: altına inilirse tutamaçlar üst üste biner.
  static const _min = 0.08;

  /// Tutamacın dokunma alanı (px). Görünen daire daha küçük — parmak ucu
  /// 20 px'lik bir daireyi tutturamıyor.
  static const _hit = 44.0;

  Rect _rect = const Rect.fromLTRB(0.05, 0.05, 0.95, 0.95);

  void _drag(_Handle handle, Offset delta, Size box) {
    final dx = delta.dx / box.width;
    final dy = delta.dy / box.height;
    setState(() {
      final r = _rect;
      _rect = switch (handle) {
        _Handle.topLeft => Rect.fromLTRB(
          (r.left + dx).clamp(0.0, r.right - _min),
          (r.top + dy).clamp(0.0, r.bottom - _min),
          r.right,
          r.bottom,
        ),
        _Handle.topRight => Rect.fromLTRB(
          r.left,
          (r.top + dy).clamp(0.0, r.bottom - _min),
          (r.right + dx).clamp(r.left + _min, 1.0),
          r.bottom,
        ),
        _Handle.bottomLeft => Rect.fromLTRB(
          (r.left + dx).clamp(0.0, r.right - _min),
          r.top,
          r.right,
          (r.bottom + dy).clamp(r.top + _min, 1.0),
        ),
        _Handle.bottomRight => Rect.fromLTRB(
          r.left,
          r.top,
          (r.right + dx).clamp(r.left + _min, 1.0),
          (r.bottom + dy).clamp(r.top + _min, 1.0),
        ),
        // Gövde sürüklemesi dikdörtgeni BOYUTUNU KORUYARAK taşır: eksenler
        // ayrı ayrı sıkıştırılır, yoksa bir kenara dayanınca kutu eziliyor.
        _Handle.body => _move(r, dx, dy),
      };
    });
  }

  static Rect _move(Rect r, double dx, double dy) {
    final x = (r.left + dx).clamp(0.0, 1.0 - r.width);
    final y = (r.top + dy).clamp(0.0, 1.0 - r.height);
    return Rect.fromLTWH(x, y, r.width, r.height);
  }

  Widget _handle(_Handle handle, Size box, Alignment corner) {
    final x = corner.x < 0 ? _rect.left : _rect.right;
    final y = corner.y < 0 ? _rect.top : _rect.bottom;
    return Positioned(
      left: x * box.width - _hit / 2,
      top: y * box.height - _hit / 2,
      width: _hit,
      height: _hit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => _drag(handle, d.delta, box),
        child: Center(
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(l10n.crop, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: l10n.cropReset,
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(
              () => _rect = const Rect.fromLTRB(0.05, 0.05, 0.95, 0.95),
            ),
          ),
          IconButton(
            tooltip: l10n.cropApply,
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(_rect),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          // Kenardaki tutamaçlar ekran dışına taşmasın.
          padding: const EdgeInsets.all(_hit / 2),
          child: AspectRatio(
            aspectRatio: widget.aspect,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final box = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // `fill` bilerek: kutu zaten görselin oranında, yani
                    // normalde `contain` ile aynı sonucu verir. Oranı
                    // bilinmeyen ESKİ ekte ([aspect] 1.0 varsayılır) görsel
                    // kareye gerilir — çirkin ama DOĞRU: gerilme doğrusal
                    // olduğundan seçilen oranlar gerçek görselde aynı yere
                    // düşer. `contain` olsaydı görsel kutunun içinde
                    // ortalanır, seçim ile kırpılan alan KAYARDI.
                    Positioned.fill(
                      child: Image(image: widget.image, fit: BoxFit.fill),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (d) => _drag(_Handle.body, d.delta, box),
                        child: CustomPaint(
                          painter: _CropOverlayPainter(_rect),
                        ),
                      ),
                    ),
                    _handle(_Handle.topLeft, box, Alignment.topLeft),
                    _handle(_Handle.topRight, box, Alignment.topRight),
                    _handle(_Handle.bottomLeft, box, Alignment.bottomLeft),
                    _handle(_Handle.bottomRight, box, Alignment.bottomRight),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            l10n.cropHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter(this.rect);

  /// Görsel oranında (0–1) seçili alan.
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTRB(
      rect.left * size.width,
      rect.top * size.height,
      rect.right * size.width,
      rect.bottom * size.height,
    );
    // Seçimin DIŞI karartılır: iki dikdörtgenin farkı tek yol olarak çizilir,
    // dört ayrı bant çizmekten hem kısa hem kenarlarda dikişsiz.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(r),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    for (var i = 1; i < 3; i++) {
      final dx = r.left + r.width * i / 3;
      canvas.drawLine(Offset(dx, r.top), Offset(dx, r.bottom), grid);
      final dy = r.top + r.height * i / 3;
      canvas.drawLine(Offset(r.left, dy), Offset(r.right, dy), grid);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) => old.rect != rect;
}
