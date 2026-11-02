/// Ana ekran ızgarasının kaydırma hafızası (F18.11, 2026-11-02).
///
/// KÖK NEDEN (KALANLAR §3, 2026-08-06'dan beri): telefon ↔ geniş ekran
/// geçişinde (döndürme, web pencere boyu, katlanabilir) `DashboardScreen`
/// ağaçta BAŞKA bir yere taşınır — dar ekranda `/` rotasının sayfası, geniş
/// ekranda `SplitShell`in sol paneli. Yeni State yeni `ScrollController`
/// demek → liste başa dönüyordu. Konum burada (oturum boyunca, bellekte)
/// tutulur; yeni örnek aynı bölümdeyse oraya döner.
///
/// Piksel değil ORAN da saklanır: iki düzende sütun sayısı farklı, aynı
/// piksel başka bir nota denk gelir. Oran (konum / toplam uzunluk) iki
/// düzende de listenin aynı bölgesini gösterir.
abstract final class DashboardScrollMemory {
  static String? _segment;
  static double _pixels = 0;
  static double _fraction = 0;

  static void save(String segment, double pixels, double maxExtent) {
    _segment = segment;
    _pixels = pixels;
    _fraction = maxExtent <= 0 ? 0 : (pixels / maxExtent).clamp(0.0, 1.0);
  }

  /// Yeni düzendeki hedef konum; bölüm farklıysa ya da tepedeyse null.
  static double? restoreOffset(String segment, double maxExtent) {
    if (_segment != segment || _pixels <= 0) return null;
    if (maxExtent <= 0) return _pixels;
    return _fraction * maxExtent;
  }

  static void clear() {
    _segment = null;
    _pixels = 0;
    _fraction = 0;
  }
}
