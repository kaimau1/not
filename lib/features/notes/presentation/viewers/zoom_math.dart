/// **ÇİFT DOKUNUŞ YAKINLAŞTIRMASI** — Google Fotoğraflar mantığı, tek yerde.
///
/// Kullanıcı isteği 2026-09-06: "görsel açılınca çift tık zoom mantığı Google
/// fotoğraflar gibi". Google Fotoğraflar'ın davranışı üç kuraldan ibaret:
///  1. Çift dokunuş DOKUNULAN NOKTAYA yakınlaşır — ekranın ortasına değil.
///     Parmağın altındaki piksel yerinde kalır; okunmak istenen yer orasıdır.
///  2. Yakınken çift dokunuş SIĞDIR'a döner (ölçek 1, kayma sıfır).
///  3. Görsel hiçbir zaman kutunun dışına taşmaz: kenara yakın bir noktaya
///     yakınlaşmak boşluk açacaksa görüntü kenara YASLANIR (kırpma yerine
///     kaydırma). Bu olmadan çift dokunuş resmi yarı yarıya ekran dışına
///     itiyor, kullanıcı da onu geri sürüklemek zorunda kalıyordu.
///
/// Saf işlev: matris girer, matris çıkar. Görüntüleyici testlerinin pdfium/
/// gerçek dosya gerektirdiği yerde bile bu mantık ölçülebilsin diye burada.
library;

import 'package:flutter/widgets.dart';

/// Çift dokunuşta gidilen ölçek (sığdırılmış hâlin katı).
const double kDoubleTapScale = 2.5;

/// "Yakınlaşmış sayılma" eşiği: kayan nokta hatası yüzünden 1.0'ın kılpayı
/// üstünde kalan ölçekler sığdırılmış sayılır.
const double kZoomedThreshold = 1.02;

/// [matrix] yakınlaştırılmış mı?
bool isZoomed(Matrix4 matrix) =>
    matrix.getMaxScaleOnAxis() > kZoomedThreshold;

/// [viewportPoint] ekranın (kutunun) sol-üstüne göre dokunulan nokta.
///
/// Dönen matris o noktayı YERİNDE tutar, ölçeği [scale] yapar ve sonucu
/// [viewport] içine sıkıştırır. [scale] 1 (ya da altı) ise sığdır hâline
/// (kimlik matrisi) dönülür — ikinci çift dokunuşun karşılığı.
Matrix4 zoomAt({
  required Matrix4 current,
  required Offset viewportPoint,
  required Size viewport,
  double scale = kDoubleTapScale,
}) {
  if (scale <= 1) return Matrix4.identity();
  // Dokunulan noktanın SAHNE (ölçeklenmemiş içerik) karşılığı: yakınken
  // yapılan ikinci bir yakınlaştırmada da doğru nokta sabit kalsın.
  final inverse = Matrix4.inverted(current);
  final scene = MatrixUtils.transformPoint(inverse, viewportPoint);
  // Sahnedeki nokta ekranın aynı yerine düşecek şekilde ölçekle:
  //   yeni(q) = scale * (q - scene) + viewportPoint
  final target = Matrix4.identity()
    ..translateByDouble(
      viewportPoint.dx - scale * scene.dx,
      viewportPoint.dy - scale * scene.dy,
      0,
      1,
    )
    ..scaleByDouble(scale, scale, scale, 1);
  return clampToViewport(target, viewport);
}

/// Ölçeklenmiş içeriği kutunun içinde tutar: kenarda boşluk kalıyorsa
/// görüntü o kenara yaslanır, içerik kutudan küçükse ortalanır.
///
/// InteractiveViewer kendi jestlerinde bu sınırı uyguluyor ama denetleyiciye
/// DIŞARIDAN yazılan matriste uygulamıyor; çift dokunuş bu yüzden görseli
/// kutunun dışına itebiliyordu.
Matrix4 clampToViewport(Matrix4 matrix, Size viewport) {
  final scale = matrix.getMaxScaleOnAxis();
  final translation = matrix.getTranslation();
  final content = Size(viewport.width * scale, viewport.height * scale);
  return Matrix4.identity()
    ..translateByDouble(
      _clampAxis(translation.x, content.width, viewport.width),
      _clampAxis(translation.y, content.height, viewport.height),
      0,
      1,
    )
    ..scaleByDouble(scale, scale, scale, 1);
}

/// Tek eksende kayma sınırı. İçerik kutudan büyükse kayma
/// `[kutu - içerik, 0]` aralığında kalır (kenarda boşluk açılmaz); küçükse
/// tek bir doğru değer vardır: ortalama.
double _clampAxis(double value, double content, double viewport) {
  if (content <= viewport) return (viewport - content) / 2;
  return value.clamp(viewport - content, 0.0).toDouble();
}

/// İki parmakla küçültülüp bırakılan görselin geri yaslanacağı matris:
/// ölçek 1'in altına düştüyse sığdır hâline, düşmediyse kenarlara oturur.
///
/// Google Fotoğraflar'da da uzaklaştırma sınırın altına inince görsel
/// kendiliğinden sığdır hâline "geri yaylanır".
Matrix4 settle(Matrix4 matrix, Size viewport) {
  final scale = matrix.getMaxScaleOnAxis();
  if (scale <= 1.0001) return Matrix4.identity();
  return clampToViewport(matrix, viewport);
}
