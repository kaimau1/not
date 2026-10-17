import 'package:flutter/material.dart';

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
/// katmanın ölçeği değişir (kare bütçesine dokunmaz).
class MediaRoute<T> extends PageRouteBuilder<T> {
  MediaRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: _transition,
      );

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}
