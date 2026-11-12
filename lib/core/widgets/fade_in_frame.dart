import 'package:flutter/widgets.dart';

import '../../app/theme/app_tokens.dart';

/// `Image.frameBuilder`: görsel ilk karesi çözülünce 150 ms solarak gelir
/// (DENEYIM F78.3c). Bellek önbelleğinden EŞZAMANLI gelen görsel solmaz —
/// listeye geri kaydırınca kartlar yanıp sönmez.
Widget fadeInFrame(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) return child;
  return AnimatedOpacity(
    opacity: frame == null ? 0 : 1,
    duration: AppMotion.of(context, AppMotion.quick),
    child: child,
  );
}
