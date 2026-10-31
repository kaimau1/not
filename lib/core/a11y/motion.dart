import 'package:flutter/widgets.dart';

/// **HAREKETİ AZALT** (F15.5, erişilebilirlik): sistemin "Animasyonları
/// kaldır" / "Hareketi azalt" ayarı açıksa false. Uygulamanın kendi
/// hareketleri (kartın büyüyerek açılması, basınca çökme, kayarak beliren
/// alanlar) buna bakar: false iken ya ANINDA olur ya da yalnız kısa bir
/// solma kalır. Ağaçta `MediaQuery` yoksa (yalın testler) hareket açık.
bool motionOf(BuildContext context) =>
    !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
