import 'package:flutter/widgets.dart';

import '../a11y/motion.dart';

/// Yeni beliren bir parçanın (araç paneli, ek döşemesi, levha içeriği)
/// yumuşak GİRİŞİ: hafif büyüyüp yukarı süzülerek belirir (kullanıcı isteği
/// 2026-10-17: "tüm aşamalarda akıcılık ve geçiş animasyonları"). Eskiden bu
/// parçalar bir karede "pat" diye çıkıyordu — uygulamanın "olmamış" hissinin
/// küçük ama sık görülen nedenlerinden biri.
///
/// Animasyon parçanın İLK kurulumunda bir kez koşar; aynı anahtarla yeniden
/// kurulunca tekrar oynamaz (yeniden oynatmak için anahtarı değiştir).
/// Yalnız saydamlık (`FadeTransition` = `RenderAnimatedOpacity`, her karede
/// `Opacity` widget'ı kurmaz ve tam görünürde katman açmaz) + tek dönüşüm —
/// yerleşim etkilenmez.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 240),
    this.from = 0.94,
    this.rise = 6,
    this.alignment = Alignment.topCenter,
    this.animate = true,
  });

  /// false ise doğrudan çizilir (ör. şeritte kaydırınca yeniden kurulan ESKİ
  /// döşeme — yalnız yeni gelen canlansın).
  final bool animate;

  final Widget child;
  final Duration duration;

  /// Başlangıç ölçeği.
  final double from;

  /// Başlangıçta kaç piksel aşağıda (yukarı süzülür).
  final double rise;

  /// Büyümenin merkezi.
  final Alignment alignment;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  CurvedAnimation? _curve;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.animate && motionOf(context)) {
        final c = AnimationController(vsync: this, duration: widget.duration);
        _controller = c;
        _curve = CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
        c.forward();
      }
    }
  }

  @override
  void didUpdateWidget(PopIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller?.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _curve?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curve;
    if (curve == null || !motionOf(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: curve,
      child: AnimatedBuilder(
        animation: curve,
        child: widget.child,
        builder: (context, child) {
          final t = curve.value;
          final scale = widget.from + (1 - widget.from) * t;
          return Transform(
            alignment: widget.alignment,
            transform: Matrix4.diagonal3Values(scale, scale, 1)
              ..setTranslationRaw(0, (1 - t) * widget.rise, 0),
            child: child,
          );
        },
      ),
    );
  }
}
