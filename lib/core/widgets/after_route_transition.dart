import 'package:flutter/widgets.dart';

/// Çocuğunu, bulunduğu rotanın AÇILIŞ GEÇİŞİ bitince kurar; o zamana dek
/// [placeholder] (aynı yerde, aynı boyda) durur.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-20: "ana ekranda notu açmaya
/// bastığımda ufak bir donma oluyor"): not açılırken editörün İLK karesinde
/// sabit bölmedeki PDF/sunum görüntüleyicisi, video oynatıcısı ve sayfaya
/// gömülü belge kutuları da kuruluyordu. Rota geçişi o karenin bitmesini
/// bekliyor, sonraki karede animasyon süresinin bir kısmı zaten geçmiş
/// oluyordu — sayfa kayarken bir an "takılıyordu". Bu parçalar geçişin
/// sonuna (≈420 ms) ertelenir: kayan sayfa hafif kalır, belge geçiş biter
/// bitmez yerine oturur.
///
/// Rota yoksa, geçişi yoksa ya da geçiş zaten bitmişse (not açıkken eklenen
/// belge, geri dönüş) çocuk HEMEN kurulur.
class AfterRouteTransition extends StatefulWidget {
  const AfterRouteTransition({
    super.key,
    required this.child,
    this.placeholder = const SizedBox.expand(),
  });

  final Widget child;
  final Widget placeholder;

  @override
  State<AfterRouteTransition> createState() => _AfterRouteTransitionState();
}

class _AfterRouteTransitionState extends State<AfterRouteTransition> {
  bool _ready = false;
  bool _checking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready && _settled()) _ready = true;
    if (!_ready) _scheduleCheck();
  }

  /// Rota yerinde mi? İTİLEN rotanın İLK karesinde Hero denetleyicisi
  /// sayfayı sahne dışında (`offstage`) kurar ve o karede animasyon
  /// "tamamlandı" görünür (vekil, `kAlwaysCompleteAnimation`a bağlı) — bu
  /// yüzden durum tek başına yetmez.
  bool _settled() {
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (route == null || animation == null) return true;
    if (route.offstage) return false;
    return animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed;
  }

  /// Her karenin sonunda yeniden bakılır (geçiş ~25 kare). Durum dinleyicisi
  /// yetmiyor: sahne dışından "tamamlandı"dan geçişsiz "tamamlandı"ya dönen
  /// rota hiç bildirim üretmez.
  void _scheduleCheck() {
    if (_checking) return;
    _checking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checking = false;
      if (!mounted || _ready) return;
      if (_settled()) {
        setState(() => _ready = true);
      } else {
        _scheduleCheck();
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? widget.child : widget.placeholder;
}
