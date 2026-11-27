import 'package:flutter/widgets.dart';

import '../a11y/motion.dart';
import '../../app/theme/app_tokens.dart';

/// Yeni beliren bir parçanın (araç paneli, ek döşemesi, levha içeriği)
/// yumuşak GİRİŞİ: hafif büyüyüp yukarı süzülerek belirir (kullanıcı isteği
/// 2026-10-17: "tüm aşamalarda akıcılık ve geçiş animasyonları"). Eskiden bu
/// parçalar bir karede "pat" diye çıkıyordu — uygulamanın "olmamış" hissinin
/// küçük ama sık görülen nedenlerinden biri.
///
/// Animasyon parçanın İLK kurulumunda bir kez koşar; aynı anahtarla yeniden
/// kurulunca tekrar oynamaz (yeniden oynatmak için anahtarı değiştir).
/// Yalnız saydamlık + dönüşüm — yerleşim etkilenmez.
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
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _c,
    curve: AppMotion.emphasized,
  );
  late Animation<double> _scale = Tween<double>(
    begin: widget.from,
    end: 1,
  ).animate(_curved);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate || !motionOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(PopIn old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) _c.duration = widget.duration;
    if (old.from != widget.from) {
      _scale = Tween<double>(begin: widget.from, end: 1).animate(_curved);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate || !motionOf(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _curved,
      child: ScaleTransition(
        scale: _scale,
        alignment: widget.alignment,
        child: AnimatedBuilder(
          animation: _curved,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, (1 - _curved.value) * widget.rise),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
