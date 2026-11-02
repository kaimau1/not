import 'package:flutter/foundation.dart';

/// Not sayfası karttan KÜÇÜLEREK kapanırken true (bkz. `note_open_route.dart`).
/// Uzun liste editörü bu sürede maddelerini kare başına birkaçı sökerek
/// azaltır: sayfa o sırada donmuş görüntü; yıkımın tamamı rota kalkarken tek
/// karede (~100 ms) olursa kapanış animasyonunun sonu takılıyordu.
final ValueNotifier<bool> noteRouteClosing = ValueNotifier(false);
