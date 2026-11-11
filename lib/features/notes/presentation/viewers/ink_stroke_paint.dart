import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/arrow.dart';
import '../../domain/attachment.dart';
import 'ink_pen.dart';

/// **TEK ÇİZİM YOLU** (F62.2): ekrandaki katman, kart önizlemesi, PDF/görsel
/// dışa aktarma ve yazdırma bir çizgiyi hep buradan çizer.
///
/// Çizgi başına BİR çizim çağrısı (ok iki): düz kalınlıkta çizgi tek `Path`
/// (sık noktalıda orta nokta yumuşatmalı), basınçlı çizgi değişken kalınlıkta
/// tek dolgu. Eskiden basınçlı çizgi nokta başına ayrı `drawLine`, saydam
/// basınçlı çizgi ayrıca `saveLayer` istiyordu (B4).
///
/// Geometri çizgi ÖRNEĞİNE bağlı önbellekte durur ([_geom]): çizgiler
/// değişmez (taşıma/boyama yenisini kurar). Tek istisna büyüyen etkin çizgi
/// — onu çizen [cache] `false` verir.
void paintInkStroke(
  Canvas canvas,
  Size size,
  InkStroke s, {
  bool cache = true,
}) {
  if (s.points.length < 2) return;
  final color = Color(s.color);
  final base = s.width * size.width;
  if (s.arrow && s.points.length >= 4) {
    final tail = Offset(s.points[0] * size.width, s.points[1] * size.height);
    final head = Offset(s.points[2] * size.width, s.points[3] * size.height);
    final geo = arrowGeometry(tail, head, base);
    canvas
      ..drawLine(tail, geo.lineEnd, inkPaint(color, base))
      ..drawPath(
        Path()
          ..moveTo(head.dx, head.dy)
          ..lineTo(geo.left.dx, geo.left.dy)
          ..lineTo(geo.right.dx, geo.right.dy)
          ..close(),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    return;
  }
  final fill = s.hasPressure;
  if (s.points.length == 2) {
    // i/ö/ü noktası: taban kalınlıkta (basınçlıda ×0,35 alt sınır korunur).
    final r = fill ? base * inkPressureFactor(s.pressures![0]) / 2 : base / 2;
    canvas.drawCircle(
      Offset(s.points[0] * size.width, s.points[1] * size.height),
      r,
      Paint()..color = color,
    );
    return;
  }
  var g = cache ? _geom[s] : null;
  if (g == null || g.size != size) {
    g = _StrokeGeom(size, fill ? _pressurePath(s, size) : _linePath(s, size));
    if (cache) _geom[s] = g;
  }
  canvas.drawPath(
    g.path,
    fill ? (Paint()..color = color) : inkPaint(color, base),
  );
}

class _StrokeGeom {
  _StrokeGeom(this.size, this.path);
  final Size size;
  final Path path;
}

/// ponytail: anahtar çizgi örneği, değer sayfa boyutuyla birlikte; boyut
/// değişince (döndürme, yakınlaştırma) bir kez yeniden kurulur.
final _geom = Expando<_StrokeGeom>('inkGeom');

/// Seyrek çizgi (şekil aracı, tanınan dikdörtgen, ok): ardışık iki nokta
/// sayfa genişliğinin %2'sinden uzak. Böyle çizgide köşe KESKİN kalır —
/// yumuşatma dikdörtgeni yuvarlardı.
bool _sparse(List<double> p) {
  for (var i = 2; i + 1 < p.length; i += 2) {
    if ((p[i] - p[i - 2]).abs() > 0.02 || (p[i + 1] - p[i - 1]).abs() > 0.02) {
      return true;
    }
  }
  return false;
}

Path _linePath(InkStroke s, Size size) {
  final p = s.points;
  final w = size.width, h = size.height;
  final n = p.length ~/ 2;
  final path = Path()..moveTo(p[0] * w, p[1] * h);
  if (n <= 3 || _sparse(p)) {
    for (var i = 1; i < n; i++) {
      path.lineTo(p[2 * i] * w, p[2 * i + 1] * h);
    }
    return path;
  }
  // Orta nokta yumuşatma: her ara nokta denetim noktası, iki komşu
  // noktanın ortası eğrinin geçtiği yer.
  for (var i = 1; i < n - 1; i++) {
    final x = p[2 * i] * w, y = p[2 * i + 1] * h;
    final nx = p[2 * i + 2] * w, ny = p[2 * i + 3] * h;
    path.quadraticBezierTo(x, y, (x + nx) / 2, (y + ny) / 2);
  }
  path.lineTo(p[2 * n - 2] * w, p[2 * n - 1] * h);
  return path;
}

/// Basınçlı çizgi: her parça uçları yuvarlak, kalınlığı iki ucun basıncıyla
/// değişen bir "kapsül" çokgeni; hepsi TEK yolda, aynı dönüş yönünde →
/// `nonZero` dolgu birleşimi boşluksuz doldurur, saydam renkte üst üste
/// binen yer koyulaşmaz (eski `saveLayer`'ın işi).
///
/// ponytail: tek şerit çokgen (normal ± yarı kalınlık) yerine parça başına
/// kapsül — şerit keskin dönüşte kendini keser, ters dönen bölge `nonZero`'da
/// delik olabilir; kapsül birleşimi her zaman dolu. Bedel parça başına 10 köşe.
Path _pressurePath(InkStroke s, Size size) {
  final p = s.points;
  final q = s.pressures!;
  final base = s.width * size.width;
  final w = size.width, h = size.height;
  final path = Path();
  for (var i = 2; i + 1 < p.length; i += 2) {
    final j = i ~/ 2;
    _capsule(
      path,
      Offset(p[i - 2] * w, p[i - 1] * h),
      base * inkPressureFactor(q[j - 1]) / 2,
      Offset(p[i] * w, p[i + 1] * h),
      base * inkPressureFactor(q[j]) / 2,
    );
  }
  return path;
}

/// [a] (yarıçap [ra]) → [b] (yarıçap [rb]) kapsülü; açılar hep artan yönde.
void _capsule(Path path, Offset a, double ra, Offset b, double rb) {
  const k = 4; // yarım daire başına parça
  final d = b - a;
  final dir = d.distance < 1e-6 ? 0.0 : math.atan2(d.dy, d.dx);
  // b'nin önündeki yarım daire (dir-90° → dir+90°), sonra a'nın arkası.
  for (var t = 0; t <= k; t++) {
    final ang = dir - math.pi / 2 + math.pi * t / k;
    final pt = b + Offset(math.cos(ang), math.sin(ang)) * rb;
    t == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
  }
  for (var t = 0; t <= k; t++) {
    final ang = dir + math.pi / 2 + math.pi * t / k;
    final pt = a + Offset(math.cos(ang), math.sin(ang)) * ra;
    path.lineTo(pt.dx, pt.dy);
  }
  path.close();
}
