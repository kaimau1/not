import 'package:flutter/widgets.dart';

/// Tamamen ÖRTÜLÜYKEN alt ağacı yeniden kurmayan sarmalayıcı.
///
/// KÖK NEDEN (kullanıcı isteği 2026-09-26: "performans ve akıcılık
/// iyileştirmesi"): telefonda not editörü ana ekranın ÜSTÜNE açılır; ana
/// ekran yığında canlı kalır ve izlediği sağlayıcılar değiştikçe yeniden
/// kurulur. Editörde yazılan her kayıt not akışını tetikliyor, akış da
/// görünmeyen ana ekranın TAMAMINI (yüzlerce kart) her kayıtta yeniden
/// kuruyordu — yazma sırasında boşa giden iş ve takılmanın bir kaynağı.
///
/// Navigator, opak bir rotanın altında kalan rotaları "sahne dışı" tutar ve
/// onlarda [TickerMode]'u KAPATIR. Burada o sinyal okunur: kapalıyken son
/// kurulan çocuk AYNEN döndürülür (aynı örnek → Flutter alt ağaca hiç
/// inmez); açılınca (rota yeniden görünür olunca) en son verilen çocukla bir
/// kez kurulur. Sağlayıcı abonelikleri üst widget'ta sürdüğü için veri
/// kaybolmaz, yalnız ÇİZİM ertelenir. Yarı saydam levhalar (alt sayfa,
/// diyalog) rotayı sahne dışına almaz — onların arkasında ekran canlı kalır.
class FreezeWhenHidden extends StatefulWidget {
  const FreezeWhenHidden({super.key, required this.child});

  final Widget child;

  @override
  State<FreezeWhenHidden> createState() => _FreezeWhenHiddenState();
}

class _FreezeWhenHiddenState extends State<FreezeWhenHidden> {
  Widget? _shown;

  @override
  Widget build(BuildContext context) {
    final visible = TickerMode.valuesOf(context).enabled;
    final shown = _shown;
    if (!visible && shown != null) return shown;
    return _shown = widget.child;
  }
}
