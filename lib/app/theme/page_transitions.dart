import 'package:flutter/cupertino.dart';

import '../../core/a11y/motion.dart';
import 'app_tokens.dart';

/// **EKRAN GEÇİŞİ — iPhone gibi** (kullanıcı isteği 2026-10-17: "uygulamayı
/// premium gösteren aynı iPhone, Mac gibi geçişler, animasyonlar ve
/// akıcılık; A'dan Z'ye").
///
/// Android'de eskiden `PredictiveBackPageTransitionsBuilder` vardı; manifest
/// öngörülü geri hareketini açmadığı için (bkz. AndroidManifest — bilerek
/// açılmadı: `FlutterFragmentActivity` ile geri tuşunun uygulamayı kapatma
/// riski) her geçiş onun YEDEĞİ olan "solarak büyü" (FadeForwards, 800 ms)
/// ile oynuyordu: ekran yerinde belirip kayboluyor, hangi yöne gidildiği
/// hissedilmiyordu.
///
/// Artık iOS'un yığın geçişi: yeni ekran sağdan kayarak gelir, alttaki ekran
/// üçte bir oranında geri çekilir ve gölgede kalır; geri dönüşte tersi. Üç
/// tuşlu gezinmede sol kenardan parmakla geri çekilir (iOS'taki gibi
/// parmağı izler). Hareketi azalt açıkken düz doğrusal solmaya geçer.
class SmoothPageTransitionsBuilder extends CupertinoPageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.long;

  @override
  Duration get reverseTransitionDuration => AppMotion.medium;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!motionOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return super.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Masaüstü / web ekran geçişi: kısa, yönlü yatay süzülme + temiz solma.
/// Pencere içinde ağır kayma yapmadan ileri/geri yönünü hissettirir; yalnız
/// boyama dönüşümü kullanır ve hareketi azalt açıksa saf solmaya döner.
class SmoothDesktopPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothDesktopPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.medium;

  @override
  Duration get reverseTransitionDuration => AppMotion.short;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!motionOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final fadeCurve = CurveTween(
      curve: route.animation?.status == AnimationStatus.reverse
          ? AppMotion.exit
          : AppMotion.enter,
    );
    final opacity = animation.drive(fadeCurve);
    final slide = Tween<Offset>(
      begin: const Offset(0.03, 0),
      end: Offset.zero,
    ).chain(fadeCurve).animate(animation);
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
