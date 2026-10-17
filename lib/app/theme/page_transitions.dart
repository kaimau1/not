import 'package:flutter/cupertino.dart';

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
/// parmağı izler). Süre iOS'un 500 ms'sinden kısa (420/360 ms): telefonun
/// kendi geri hareketiyle yan yana hantal durmasın; eğri Cupertino'nun
/// "hızlı başla, yavaş otur" eğrisi.
class SmoothPageTransitionsBuilder extends CupertinoPageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 360);
}
