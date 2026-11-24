import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../a11y/motion.dart';

/// **MEDYA AÇILIŞI — yakınlaşarak belir** (kullanıcı isteği 2026-10-17:
/// "premium gösteren iPhone, Mac gibi geçişler").
///
/// Ekranlar arası gezinme yandan kayar (bkz. `SmoothPageTransitionsBuilder`);
/// bir görseli, videoyu ya da belgeyi TAM EKRANDA açmak ise gezinme değil
/// "yakına getirme"dir — iOS Fotoğraflar'daki gibi içerik hafifçe büyüyerek
/// koyu zeminin üstünde belirir, kapanınca aynı yoldan küçülerek kaybolur.
/// Görüntüleyici yandan kayınca (eskiden FadeForwards) not sayfası ile
/// görsel arasındaki bağ kopuyordu.
///
/// Yalnız dönüşüm + saydamlık: sahne yeniden yerleşmez, her kare tek bir
/// katmanın ölçeği değişir (kare bütçesine dokunmaz). Hareketi azalt açıksa
/// yakınlaşma olmadan temiz solma oynar.
class MediaRoute<T> extends PageRouteBuilder<T> {
  MediaRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: AppMotion.medium,
        reverseTransitionDuration: AppMotion.short,
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: _transition,
      );

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (!motionOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final curve = CurveTween(
      curve: animation.status == AnimationStatus.reverse
          ? AppMotion.exit
          : AppMotion.enter,
    );
    return FadeTransition(
      opacity: animation.drive(curve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.93, end: 1).chain(curve).animate(animation),
        child: child,
      ),
    );
  }
}
