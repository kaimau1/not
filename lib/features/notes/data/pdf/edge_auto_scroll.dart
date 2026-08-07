import 'dart:ui' show Offset, Size;

/// Seçim sürüklenirken görüntünün kendiliğinden akması gereken miktar.
///
/// [pos] işaretçinin görüntü içindeki (yerel) konumu, [viewport] görüntünün
/// boyutu. Dönen değer bir KAREDE uygulanacak kayma: parmak kenar payına
/// (`margin`) girdikçe büyür, tam kenarda `maxStep`e ulaşır; ortada sıfırdır.
/// Böylece parmak ekranın altına dayandığında sayfa akmayı sürdürür ve seçim
/// satır satır büyür (Chrome'un seçim oto-kaydırması).
///
/// Saf fonksiyon → birim testli; çağıran yalnız matrisi iter.
Offset edgeAutoScrollDelta(
  Offset pos,
  Size viewport, {
  double margin = 56,
  double maxStep = 14,
}) {
  double axis(double p, double extent) {
    // Kenar payı görüntüyü kaplayacak kadar küçük ekranlarda (bölünmüş ekran,
    // pano bölmesi) payı küçült ki orta bölge her zaman "ölü bölge" kalsın.
    final m = extent < margin * 3 ? extent / 3 : margin;
    if (m <= 0) return 0;
    if (p < m) return -((m - p) / m).clamp(0.0, 1.0) * maxStep;
    if (p > extent - m) {
      return ((p - (extent - m)) / m).clamp(0.0, 1.0) * maxStep;
    }
    return 0;
  }

  return Offset(axis(pos.dx, viewport.width), axis(pos.dy, viewport.height));
}
