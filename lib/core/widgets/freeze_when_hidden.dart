import 'dart:async';

import 'package:flutter/widgets.dart';

/// Tamamen ÖRTÜLÜYKEN alt ağacı yeniden kurmayan sarmalayıcı.
///
/// KÖK NEDEN (kullanıcı isteği 2026-09-26: "performans ve akıcılık
/// iyileştirmesi"): telefonda not editörü ana ekranın ÜSTÜNE açılır; ana
/// ekran yığında canlı kalır ve izlediği sağlayıcılar değiştikçe yeniden
/// kurulur. Editörde yazılan her kayıt not akışını tetikliyor, akış da
/// görünmeyen ana ekranın TAMAMINI (yüzlerce kart) her kayıtta yeniden
/// kuruyordu.
///
/// Navigator, opak bir rotanın altında kalan rotaları "sahne dışı" tutar ve
/// onlarda [TickerMode]'u KAPATIR. Burada o sinyal okunur: kapalıyken son
/// kurulan çocuk AYNEN döndürülür (aynı örnek → Flutter alt ağaca hiç
/// inmez). Sağlayıcı abonelikleri üst widget'ta sürdüğü için veri kaybolmaz,
/// yalnız ÇİZİM ertelenir. Yarı saydam levhalar (alt sayfa, diyalog) rotayı
/// sahne dışına almaz — onların arkasında ekran canlı kalır.
///
/// **YETİŞME GERİ DÖNÜŞ ANİMASYONUNDAN SONRA** (kullanıcı 2026-09-26:
/// "güncellemeden sonra kasma başladı"). İlk sürüm ekran görünür olur
/// olmaz — yani nottan geri dönüş animasyonunun İLK karesinde — bütün
/// kartları birden yeniden kuruyordu; animasyon tam o karede takılıyordu.
/// Artık animasyon boyunca eski (bir an önceki) görüntü kalır, güncelleme
/// [catchUpDelay] sonra tek seferde yapılır.
class FreezeWhenHidden extends StatefulWidget {
  const FreezeWhenHidden({
    super.key,
    required this.child,
    this.catchUpDelay = const Duration(milliseconds: 380),
  });

  final Widget child;

  /// Görünür olduktan sonra bekleme (rota geçişi ~300 ms).
  final Duration catchUpDelay;

  @override
  State<FreezeWhenHidden> createState() => _FreezeWhenHiddenState();
}

class _FreezeWhenHiddenState extends State<FreezeWhenHidden> {
  Widget? _shown;
  bool _visible = true;
  Timer? _catchUp;

  @override
  void dispose() {
    _catchUp?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = TickerMode.valuesOf(context).enabled;
    final shown = _shown;
    if (shown == null) return _shown = widget.child;
    if (!visible) {
      _visible = false;
      _catchUp?.cancel();
      return shown;
    }
    if (!_visible) {
      // Az önce görünür oldu: geri dönüş animasyonu ŞU AN oynuyor.
      _visible = true;
      if (identical(shown, widget.child)) return shown;
      _catchUp?.cancel();
      _catchUp = Timer(widget.catchUpDelay, () {
        if (mounted) setState(() {});
      });
      return shown;
    }
    // Bekleme sürerken gelen yeniden kurulumlar da bekler.
    if (_catchUp?.isActive ?? false) return shown;
    return _shown = widget.child;
  }
}
