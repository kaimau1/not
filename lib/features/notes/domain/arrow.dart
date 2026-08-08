import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Bir OKUN geometrisi: gövde çizgisinin BİTTİĞİ nokta ve ucundaki dolu
/// başlığın iki kanadı ([left]/[right] — üçüncü köşe okun ucudur).
///
/// Ekrandaki katman (`InkPainter`) ile paylaşılan PDF'in damgası (`PdfEdit`)
/// AYNI hesabı kullansın diye burada, saf Dart olarak tek kopya: iki yerde
/// ayrı yazılsaydı paylaşılan PDF'teki ok ekrandakinden başka türlü çıkardı.
/// (Kullanıcı isteği 2026-08-08: "bir de ok işareti çekme istiyorum.")
///
/// Gövde başlığın İÇİNE kadar sürmez ([lineEnd] başlığın dibinde biter):
/// kalın kalemde çizgi başlığın ucundan taşıp sivriliği bozuyordu. Başlık
/// kalınlıkla büyür ama okun kendisinin yarısından uzun olamaz — kısa bir okta
/// uç, gövdeyi yutmamalı.
({Offset lineEnd, Offset left, Offset right}) arrowGeometry(
  Offset tail,
  Offset head,
  double strokeWidth,
) {
  final dx = head.dx - tail.dx;
  final dy = head.dy - tail.dy;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length < 0.01) return (lineEnd: head, left: head, right: head);
  final size = math.min(
    math.max(strokeWidth * 3.2, 12.0),
    math.max(length * 0.45, 1.0),
  );
  final ux = dx / length;
  final uy = dy / length;
  final baseX = head.dx - ux * size;
  final baseY = head.dy - uy * size;
  final wing = size * 0.42;
  return (
    // Çizgi başlığın dibine biraz GİRER: aradaki dikişin görünmemesi için.
    lineEnd: Offset(baseX + ux * size * 0.35, baseY + uy * size * 0.35),
    left: Offset(baseX - uy * wing, baseY + ux * wing),
    right: Offset(baseX + uy * wing, baseY - ux * wing),
  );
}
