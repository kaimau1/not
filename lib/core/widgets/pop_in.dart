import 'package:flutter/widgets.dart';

/// Yeni beliren bir parçanın (araç paneli, ek döşemesi, levha içeriği)
/// yumuşak GİRİŞİ: hafif büyüyüp yukarı süzülerek belirir (kullanıcı isteği
/// 2026-10-17: "tüm aşamalarda akıcılık ve geçiş animasyonları"). Eskiden bu
/// parçalar bir karede "pat" diye çıkıyordu — uygulamanın "olmamış" hissinin
/// küçük ama sık görülen nedenlerinden biri.
///
/// Animasyon parçanın İLK kurulumunda bir kez koşar; aynı anahtarla yeniden
/// kurulunca tekrar oynamaz (yeniden oynatmak için anahtarı değiştir).
/// Yalnız saydamlık + dönüşüm — yerleşim etkilenmez.
class PopIn extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!animate || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * rise),
          child: Transform.scale(
            scale: from + (1 - from) * t,
            alignment: alignment,
            child: child,
          ),
        ),
      ),
    );
  }
}
