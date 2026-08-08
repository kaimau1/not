import 'dart:math' as math;

import '../../data/pptx_render.dart';

/// Slaydın en-boy oranı (genişlik / yükseklik). Bilinmiyorsa 16:9.
double slideAspect(SlideVM slide) =>
    slide.heightPt == 0 ? 16 / 9 : slide.widthPt / slide.heightPt;

/// Dikey slayt akışının ölçüleri.
///
/// Slaytlar artık PDF gibi **alt alta ve boşluksuz** kayar (kullanıcı isteği
/// 2026-08-08: "slaytlarda yan yana değil PDF gibi aşağı doğru kaydırılsın,
/// arada boşluk olmasın"). Yatay `PageView` bırakıldı: her geçiş tam sayfalık
/// bir sıçramaydı ve okuma akışı PDF'ten ayrılıyordu.
///
/// Yükseklikler ÖNCEDEN bilindiği için liste `itemExtentBuilder` ile kurulur:
/// kaydırma konumundan slayt numarasını (ve tersini) hesaplamak, öğeleri
/// ölçmeden yapılabilir — hem takılma olmaz hem "balona git" tam yere gider.
class SlideStripMetrics {
  SlideStripMetrics(this.heights) : offsets = _cumulative(heights);

  /// Slayt en-boy oranlarından ([genişlik / yükseklik]) verilen genişlikteki
  /// yükseklikleri kurar. Oran bilinmiyorsa (0 ya da negatif) 16:9 varsayılır.
  factory SlideStripMetrics.forWidth(List<double> aspects, double width) =>
      SlideStripMetrics([
        for (final aspect in aspects) width / (aspect > 0 ? aspect : 16 / 9),
      ]);

  final List<double> heights;

  /// Her slaydın başlangıç konumu; sonda toplam yükseklik durur
  /// (uzunluk = `heights.length + 1`).
  final List<double> offsets;

  static List<double> _cumulative(List<double> heights) {
    final out = <double>[0];
    var sum = 0.0;
    for (final h in heights) {
      sum += h > 0 ? h : 0;
      out.add(sum);
    }
    return out;
  }

  bool get isEmpty => heights.isEmpty;
  int get length => heights.length;
  double get total => offsets.last;

  double heightOf(int page) => isEmpty
      ? 0
      : heights[(page - 1).clamp(0, heights.length - 1)];

  double startOf(int page) => isEmpty
      ? 0
      : offsets[(page - 1).clamp(0, heights.length - 1)];

  /// Görünür alanın ORTASINDAKİ slayt (1-tabanlı) — "şu an hangi slayttayız".
  ///
  /// Ortası ölçüt: üstte yarım kalan slayt değil, ekranı asıl dolduran slayt
  /// "geçerli" sayılmalı; not alanı da onun notunu gösterir.
  int pageAt(double scrollOffset, double viewportHeight) {
    if (isEmpty) return 1;
    final center = scrollOffset + viewportHeight / 2;
    for (var i = 0; i < heights.length; i++) {
      if (center < offsets[i + 1]) return i + 1;
    }
    return heights.length;
  }

  /// [page] slaydının [y] oranındaki noktasını, yüksekliği [free] olan görünür
  /// alanın ortasına getirecek kaydırma konumu.
  ///
  /// [free] görünür alanın TAMAMI değildir: klavye ve açık balon kartı ne kadar
  /// yer alıyorsa o kadar azdır (kullanıcı isteği: "tıklanan balon klavye ile
  /// ekranın üstü arasında ortalanmalı").
  double centerOffset({
    required int page,
    required double y,
    required double free,
    required double maxScroll,
  }) {
    if (isEmpty) return 0;
    final target =
        startOf(page) + y.clamp(0.0, 1.0) * heightOf(page) - free / 2;
    return target.clamp(0.0, math.max(0.0, maxScroll));
  }
}
