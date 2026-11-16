/// **KLAVYE GERİYLE KAPANDI MI?** (kullanıcı bulgusu 2026-11-16: "klavye
/// biçim menüsü açıkken geri yapıldığında önce biçim menüsü kapanmalı; şu an
/// önce klavye kapanıyor").
///
/// KÖK NEDEN: Android'de klavye açıkken geri tuşunu ÖNCE klavye (IME) alır
/// ve kendini gizler; olay uygulamanın `PopScope`una hiç ulaşmaz. Bu yüzden
/// editörün "geri önce biçim panelini kapatır" kuralı klavye açıkken
/// çalışmıyordu. Uygulama geri olayını göremez, ama sonucunu görür: alan
/// odakta KALDIĞI hâlde klavye boşluğu çöker.
///
/// Bu sınıf klavye boşluğunu kare kare izler ve kapanış BAŞLADIĞINDA (zirvenin
/// yarısının altına inince — öneri şeridi gibi küçük boy değişimleri
/// sayılmaz) bir kez true döner. Çağıran, odak hâlâ yazı alanındaysa paneli
/// kapatıp klavyeyi geri açar; alan dışına dokunup odağı bırakmak bu yola
/// girmez (odak önce gider).
class ImeHideDetector {
  double _peak = 0;
  double _last = 0;

  /// Bu iniş için zaten haber verildi (iniş bitene dek bir daha yok).
  bool _fired = false;

  /// Zirvenin bu oranının altı "kapanıyor" sayılır.
  static const double collapse = 0.5;

  /// Takibi sıfırlar (panel kapandı / yeniden açıldı).
  void reset() {
    _peak = 0;
    _last = 0;
    _fired = false;
  }

  /// Yeni klavye boşluğu (dp). Kapanış başladıysa true (iniş başına bir kez).
  bool onInset(double inset) {
    final rising = inset > _last;
    _last = inset;
    if (rising) {
      if (_fired) {
        _fired = false;
        _peak = 0;
      }
      if (inset > _peak) _peak = inset;
      return false;
    }
    if (inset <= 0) {
      // Tek adımda dibe inen klavye de sayılır.
      final fire = !_fired && _peak > 0;
      _peak = 0;
      _fired = false;
      return fire;
    }
    if (!_fired && _peak > 0 && inset < _peak * collapse) {
      _fired = true;
      return true;
    }
    return false;
  }
}
