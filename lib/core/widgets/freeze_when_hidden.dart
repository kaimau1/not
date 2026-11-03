import 'dart:async';

import 'package:flutter/widgets.dart';

import 'note_route_closing.dart';

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
///
/// **KLAVYE VE KAPANIŞ KASMASI (kullanıcı bulgusu 2026-11-03: "klavye
/// açılırken kasma titreme, not kapanırken de kasma")** — iki kök neden:
/// * Gizliyken de `MediaQuery` değişimi alt ağaca İNİYORDU: ağaç kurulmasa
///   bile `MediaQuery`ye bağlı her öğe (Scaffold, yüzlerce kartın Material
///   parçaları) klavyenin HER karesinde uyarılıyordu — not editöründe klavye
///   açılırken görünmeyen ana ekran da kare kare iş yapıyordu. Artık gizliyken
///   alt ağacın gördüğü `MediaQuery` DONAR (ağacın şekli değişmez: sarmalayıcı
///   hep burada).
/// * Not karttan küçülerek kapanırken ([noteRouteClosing]) yetişme 380 ms'de
///   — kapanış animasyonunun (380 ms) TAM son karesinde — bütün ızgarayı
///   yeniden kuruyordu; notta değişiklik varsa (yazıldıysa) kapanışın sonu
///   takılıyordu. Kapanış sürerken hem yetişme hem `MediaQuery` (klavye o
///   sırada iniyor) bekler; rota kalktıktan [catchUpAfterClose] SONRA
///   (editörün söküldüğü kareden ayrı) tek seferde yapılır.
class FreezeWhenHidden extends StatefulWidget {
  const FreezeWhenHidden({
    super.key,
    required this.child,
    this.catchUpDelay = const Duration(milliseconds: 380),
    this.catchUpAfterClose = const Duration(milliseconds: 120),
  });

  final Widget child;

  /// Görünür olduktan sonra bekleme (rota geçişi ~300 ms).
  final Duration catchUpDelay;

  /// Karttan küçülen not kapanışı BİTTİKTEN sonraki bekleme (bkz.
  /// [noteRouteClosing]): rota kalkarken editör sökülür; yetişme o kareye
  /// binmesin.
  final Duration catchUpAfterClose;

  @override
  State<FreezeWhenHidden> createState() => _FreezeWhenHiddenState();
}

class _FreezeWhenHiddenState extends State<FreezeWhenHidden> {
  Widget? _shown;
  bool _visible = true;
  Timer? _catchUp;

  /// Gizliyken (ya da üstteki not kapanırken) alt ağacın gördüğü donmuş
  /// `MediaQuery`; null = canlı.
  MediaQueryData? _frozenMedia;

  /// Görünür olunca yetişme, üstteki not kapanışının BİTMESİNİ bekliyor.
  bool _waitingForClose = false;

  @override
  void initState() {
    super.initState();
    noteRouteClosing.addListener(_onRouteClosing);
  }

  @override
  void dispose() {
    noteRouteClosing.removeListener(_onRouteClosing);
    _catchUp?.cancel();
    super.dispose();
  }

  void _onRouteClosing() {
    if (!mounted) return;
    if (noteRouteClosing.value) {
      // Kapanış başladı (ya da geri çekme jesti yeniden geri gidiyor):
      // bekleyen yetişme kapanışın sonuna ertelenir.
      if (_visible && (_catchUp?.isActive ?? false)) {
        _catchUp?.cancel();
        _waitingForClose = true;
      }
      return;
    }
    if (!_waitingForClose) return;
    _waitingForClose = false;
    _scheduleCatchUp(widget.catchUpAfterClose);
  }

  void _scheduleCatchUp(Duration delay) {
    _catchUp?.cancel();
    _catchUp = Timer(delay, () {
      if (!mounted) return;
      setState(() => _frozenMedia = null);
    });
  }

  /// Donmuş değer yalnız KLAVYE/güvenli alan farkını saklar: pencere boyu
  /// ya da metin ölçeği değiştiyse (döndürme, bölünmüş ekran) görünür ekran
  /// eski ölçüyle bir an bile çizilmesin — hemen canlıya dönülür.
  Widget _wrap(Widget child, MediaQueryData live) {
    final frozen = _frozenMedia;
    if (frozen != null &&
        _visible &&
        (frozen.size != live.size ||
            frozen.textScaler != live.textScaler ||
            frozen.devicePixelRatio != live.devicePixelRatio)) {
      _frozenMedia = null;
    }
    return MediaQuery(data: _frozenMedia ?? live, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final live = MediaQuery.of(context);
    final visible = TickerMode.valuesOf(context).enabled;
    final shown = _shown;
    if (shown == null) return _wrap(_shown = widget.child, live);
    if (!visible) {
      _visible = false;
      _waitingForClose = false;
      _catchUp?.cancel();
      _frozenMedia ??= live;
      return _wrap(shown, live);
    }
    if (!_visible) {
      // Az önce görünür oldu: geri dönüş animasyonu ŞU AN oynuyor.
      _visible = true;
      if (noteRouteClosing.value) {
        // Karttan küçülen kapanış: animasyon bitene dek her şey donuk.
        _waitingForClose = true;
        return _wrap(shown, live);
      }
      _scheduleCatchUp(widget.catchUpDelay);
      return _wrap(shown, live);
    }
    // Bekleme sürerken gelen yeniden kurulumlar da bekler.
    if (_waitingForClose || (_catchUp?.isActive ?? false)) {
      return _wrap(shown, live);
    }
    _frozenMedia = null;
    return _wrap(_shown = widget.child, live);
  }
}
