import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;
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
  final fountain = inkIsFountain(s.color);
  final fill = s.hasPressure || fountain;
  if (s.points.length == 2) {
    // i/ö/ü noktası: taban kalınlıkta (basınçlıda ×0,35 alt sınır korunur;
    // dolma kalemde taban yarıçap).
    final r = s.hasPressure && !fountain
        ? base * inkPressureFactor(s.pressures![0]) / 2
        : base / 2;
    canvas.drawCircle(
      Offset(s.points[0] * size.width, s.points[1] * size.height),
      r,
      Paint()..color = color,
    );
    return;
  }
  var g = cache ? _geom[s] : null;
  if (g == null || g.size != size) {
    g = _StrokeGeom(
      size,
      fill ? _variablePath(s, size, fountain) : _linePath(s, size),
    );
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

/// Basınçlı / dolma kalem çizgisi: her parça uçları yuvarlak, kalınlığı
/// iki ucun yarıçapıyla değişen bir "kapsül" çokgeni; hepsi TEK yolda, aynı
/// dönüş yönünde → `nonZero` dolgu birleşimi boşluksuz doldurur, saydam
/// renkte üst üste binen yer koyulaşmaz (eski `saveLayer`'ın işi).
///
/// ponytail: tek şerit çokgen (normal ± yarı kalınlık) yerine parça başına
/// kapsül — şerit keskin dönüşte kendini keser, ters dönen bölge `nonZero`'da
/// delik olabilir; kapsül birleşimi her zaman dolu. Bedel parça başına 10 köşe.
Path _variablePath(InkStroke s, Size size, bool fountain) {
  final p = s.points;
  final w = size.width, h = size.height;
  final r = fountain ? fountainRadii(s, size) : _pressureRadii(s, size);
  final path = Path();
  for (var i = 2; i + 1 < p.length; i += 2) {
    final j = i ~/ 2;
    _capsule(
      path,
      Offset(p[i - 2] * w, p[i - 1] * h),
      r[j - 1],
      Offset(p[i] * w, p[i + 1] * h),
      r[j],
    );
  }
  return path;
}

List<double> _pressureRadii(InkStroke s, Size size) {
  final base = s.width * size.width;
  return [for (final q in s.pressures!) base * inkPressureFactor(q) / 2];
}

/// Dolma kalemin nokta başına yarıçapı (F62.5): basınç eğrisi dik
/// (×0,2–×1,8; basınçsız girdide ×1), ardışık nokta ARALIĞI büyüdükçe
/// (hızlı çizgi) ×1,15'ten ×0,45'e incelir. Aralık iki komşu parçanın
/// ortalaması — tek titrek parça kalınlığı zıplatmasın. Şema değişmez.
@visibleForTesting
List<double> fountainRadii(InkStroke s, Size size) {
  final p = s.points;
  final n = p.length ~/ 2;
  final q = s.hasPressure ? s.pressures : null;
  final base = s.width * size.width;
  double seg(int i) {
    // i-1 → i parçasının sayfa genişliğine oranlı boyu.
    if (i <= 0 || i >= n) return -1;
    final dx = p[2 * i] - p[2 * i - 2];
    final dy = (p[2 * i + 1] - p[2 * i - 1]) * size.height / size.width;
    return math.sqrt(dx * dx + dy * dy);
  }

  return [
    for (var i = 0; i < n; i++)
      () {
        final a = seg(i), b = seg(i + 1);
        final v = a < 0 ? b : (b < 0 ? a : (a + b) / 2);
        final speed = (1.15 - 20 * math.max(0.0, v)).clamp(0.45, 1.15);
        final press = q == null ? 1.0 : 0.2 + 1.6 * q[i].clamp(0.0, 1.0);
        return math.max(0.5, base * press * speed / 2);
      }(),
  ];
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
