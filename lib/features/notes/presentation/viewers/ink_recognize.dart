import 'dart:math' as math;

import 'package:flutter/painting.dart' show Offset, Rect;

import 'ink_tools.dart';

/// **ÇİZİM DÜZELTME ÖNERİSİ** (kullanıcı isteği 2026-11-08: "kalemli modda
/// kabaca daire/dikdörtgen/üçgen/çizgi/ok çizince algılansın, sağ altta
/// küçük işaretçi çıksın, dokununca düzgün hâle gelsin"; tik ve çarpı da).
///
/// Saf geometri (ML yok): uzunluk/kiriş oranı, Ramer–Douglas–Peucker ile
/// köşe bulma ve [recognizeInkShape]'in elips/dikdörtgen uyum hatası. Tüm
/// noktalar EKRAN (piksel) uzayında — oranlı uzayda daire elips görünür.
enum InkFixKind { line, arrow, rectangle, ellipse, triangle, tick, cross }

/// Önerilen temiz çizgi (piksel): noktalar + ok başlığı.
typedef InkFixStroke = ({List<Offset> points, bool arrow});

class InkFix {
  const InkFix(this.kind, this.strokes, {this.usesPrevious = false});

  final InkFixKind kind;

  /// Yerine konacak çizgiler (çarpıda iki).
  final List<InkFixStroke> strokes;

  /// Önceki çizgi de bu şeklin parçası (çarpının ilk kolu, okun gövdesi):
  /// o da kaldırılır.
  final bool usesPrevious;

  /// Tik / çarpı (ayarı ayrı, varsayılan kapalı).
  bool get isMark => kind == InkFixKind.tick || kind == InkFixKind.cross;
}

/// Şekil önerisi için çizginin kutusunun köşegeni en az bu kadar (dp):
/// yazının harfleri (l, o, 1) şekil sanılmasın.
const kInkFixMinShape = 36.0;

/// Tik/çarpı daha küçük çizilir (kutucuk boyu).
const kInkFixMinMark = 14.0;

/// [points] son çizgi, [previous] hemen önceki çizgi (kısa süre içinde,
/// aynı sayfada — çağıran süzer). [shapes]/[marks] ayarlara göre.
InkFix? recognizeInkFix(
  List<Offset> points, {
  List<Offset>? previous,
  bool shapes = true,
  bool marks = true,
}) {
  if (points.length < 2) return null;
  final box = _bounds(points);
  final diag = math.sqrt(box.width * box.width + box.height * box.height);

  if (previous != null && previous.length >= 2) {
    if (marks) {
      final cross = _cross(previous, points);
      if (cross != null) return cross;
    }
    if (shapes) {
      final arrow = _twoStrokeArrow(previous, points);
      if (arrow != null) return arrow;
    }
  }
  if (marks && diag >= kInkFixMinMark) {
    final tick = _tick(points, diag);
    if (tick != null) return tick;
  }
  if (!shapes || diag < kInkFixMinShape) return null;

  final arrow = _hookArrow(points);
  if (arrow != null) return arrow;

  final found = recognizeInkShape(points);
  if (found != null) {
    final kind = switch (found.shape) {
      InkShape.line => InkFixKind.line,
      InkShape.rectangle => InkFixKind.rectangle,
      InkShape.ellipse => InkFixKind.ellipse,
    };
    final flat = inkShapePoints(
      found.shape,
      found.a.dx,
      found.a.dy,
      found.b.dx,
      found.b.dy,
    );
    return InkFix(kind, [(points: _unflatten(flat), arrow: false)]);
  }
  return _triangle(points);
}

// ── Yardımcılar ────────────────────────────────────────────────────────

Rect _bounds(List<Offset> pts) {
  var l = double.infinity, t = double.infinity;
  var r = -double.infinity, b = -double.infinity;
  for (final p in pts) {
    l = math.min(l, p.dx);
    t = math.min(t, p.dy);
    r = math.max(r, p.dx);
    b = math.max(b, p.dy);
  }
  return Rect.fromLTRB(l, t, r, b);
}

double _length(List<Offset> pts) {
  var s = 0.0;
  for (var i = 1; i < pts.length; i++) {
    s += (pts[i] - pts[i - 1]).distance;
  }
  return s;
}

List<Offset> _unflatten(List<double> flat) => [
  for (var i = 0; i + 1 < flat.length; i += 2) Offset(flat[i], flat[i + 1]),
];

double _cross2(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

/// Noktanın [a]–[b] doğru PARÇASINA uzaklığı.
double _segDistance(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = _dot(ab, ab);
  if (len2 == 0) return (p - a).distance;
  final t = (_dot(p - a, ab) / len2).clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

/// Ramer–Douglas–Peucker: [eps]'ten az sapan ara noktalar atılır (köşeler
/// kalır).
List<Offset> _simplify(List<Offset> pts, double eps) {
  if (pts.length < 3) return [...pts];
  final keep = List<bool>.filled(pts.length, false);
  keep[0] = keep[pts.length - 1] = true;
  final stack = <(int, int)>[(0, pts.length - 1)];
  while (stack.isNotEmpty) {
    final (s, e) = stack.removeLast();
    var maxD = 0.0;
    var idx = -1;
    for (var i = s + 1; i < e; i++) {
      final d = _segDistance(pts[i], pts[s], pts[e]);
      if (d > maxD) {
        maxD = d;
        idx = i;
      }
    }
    if (idx >= 0 && maxD > eps) {
      keep[idx] = true;
      stack
        ..add((s, idx))
        ..add((idx, e));
    }
  }
  return [
    for (var i = 0; i < pts.length; i++)
      if (keep[i]) pts[i],
  ];
}

/// Çizgi düz mü: kiriş uzunluğa yakın, hiçbir nokta kirişten uzak değil.
bool _straight(List<Offset> pts) {
  final chord = (pts.last - pts.first).distance;
  if (chord <= 0) return false;
  if (chord < _length(pts) * 0.9) return false;
  final dir = (pts.last - pts.first) / chord;
  var dev = 0.0;
  for (final p in pts) {
    dev = math.max(dev, _cross2(p - pts.first, dir).abs());
  }
  return dev <= math.max(4.0, chord * 0.08);
}

/// İki vektör arasındaki açı (derece, 0–180).
double _angle(Offset a, Offset b) {
  final la = a.distance, lb = b.distance;
  if (la == 0 || lb == 0) return 0;
  final c = (_dot(a, b) / (la * lb)).clamp(-1.0, 1.0);
  return math.acos(c) * 180 / math.pi;
}

// ── Tanıyıcılar ────────────────────────────────────────────────────────

/// ÇARPI: iki düz, çapraz (yataya 20–70°), ortalarına yakın kesişen ve boyu
/// birbirine yakın çizgi. Artı (+) çapraz değildir: yazının artısı bozulmaz.
InkFix? _cross(List<Offset> a, List<Offset> b) {
  if (!_straight(a) || !_straight(b)) return null;
  final a0 = a.first, a1 = a.last, b0 = b.first, b1 = b.last;
  final la = (a1 - a0).distance, lb = (b1 - b0).distance;
  if (la < kInkFixMinMark || lb < kInkFixMinMark) return null;
  final ratio = la / lb;
  if (ratio < 0.5 || ratio > 2) return null;
  bool diagonal(Offset v) {
    final deg = math.atan2(v.dy.abs(), v.dx.abs()) * 180 / math.pi;
    return deg >= 20 && deg <= 70;
  }

  final da = a1 - a0, db = b1 - b0;
  if (!diagonal(da) || !diagonal(db)) return null;
  final denom = _cross2(da, db);
  if (denom.abs() < 1e-9) return null;
  // Kesişim parametreleri: a0 + da·t = b0 + db·u.
  final t = _cross2(b0 - a0, db) / denom;
  final u = _cross2(b0 - a0, da) / denom;
  if (t < 0.2 || t > 0.8 || u < 0.2 || u > 0.8) return null;
  // İki kol zıt eğimli olmalı (biri "\", öbürü "/").
  if ((da.dx * da.dy).sign == (db.dx * db.dy).sign) return null;
  final box = _bounds([...a, ...b]);
  // Temiz çarpı: kare kutu (kenar uzun kenar), merkez kesişim noktası.
  final c = a0 + da * t;
  final h = math.max(box.width, box.height) / 2;
  return InkFix(InkFixKind.cross, [
    (points: [c + Offset(-h, -h), c + Offset(h, h)], arrow: false),
    (points: [c + Offset(h, -h), c + Offset(-h, h)], arrow: false),
  ], usesPrevious: true);
}

/// TİK (✓): kısa kol aşağı, uzun kol yukarı-sağa; dip en alttaki nokta.
/// Simetrik "v" harfi tik sayılmaz (uzun kol en az 1,3 kat).
InkFix? _tick(List<Offset> pts, double diag) {
  final s = _simplify(pts, diag * 0.12);
  if (s.length != 3) return null;
  final a = s[0], b = s[1], c = s[2];
  final v1 = b - a, v2 = c - b;
  if (v1.dy <= 0 || v2.dy >= 0 || v2.dx <= 0 || v1.dx < -v1.distance * 0.5) {
    return null;
  }
  final l1 = v1.distance, l2 = v2.distance;
  if (l2 < l1 * 1.3 || l1 < l2 * 0.15) return null;
  final apex = _angle(a - b, c - b);
  if (apex < 30 || apex > 115) return null;
  if (b.dy < math.max(a.dy, c.dy)) return null;
  return InkFix(InkFixKind.tick, [
    (points: [a, b, c], arrow: false),
  ]);
}

/// Tek çizgide ok: gövde + uçta geri dönen kanca(lar). Biçimler:
/// a→b→c (tek kanca) ya da a→b→c→b'→d (iki kanat, b ≈ b').
InkFix? _hookArrow(List<Offset> pts) {
  final len = _length(pts);
  final s = _simplify(pts, math.max(4.0, len * 0.05));
  if (s.length != 3 && s.length != 5) return null;
  final a = s[0], b = s[1];
  final shaft = (b - a).distance;
  if (shaft < kInkFixMinShape) return null;
  bool barb(Offset end) {
    final l = (end - b).distance;
    if (l < shaft * 0.08 || l > shaft * 0.5) return false;
    final ang = _angle(a - b, end - b);
    return ang >= 12 && ang <= 75;
  }

  if (s.length == 3) {
    if (!barb(s[2])) return null;
  } else {
    if ((s[3] - b).distance > shaft * 0.2) return null;
    if (!barb(s[2]) || !barb(s[4])) return null;
    // Kanatlar gövdenin iki yanında.
    final side1 = _cross2(b - a, s[2] - a).sign;
    final side2 = _cross2(b - a, s[4] - a).sign;
    if (side1 == side2) return null;
  }
  return InkFix(InkFixKind.arrow, [
    (points: [a, b], arrow: true),
  ]);
}

/// İki çizgide ok: önce düz gövde, sonra ucuna "^" (iki kanat, açısı
/// gövdeye geri bakar).
InkFix? _twoStrokeArrow(List<Offset> line, List<Offset> head) {
  if (!_straight(line)) return null;
  final p0 = line.first, p1 = line.last;
  final shaft = (p1 - p0).distance;
  if (shaft < kInkFixMinShape) return null;
  final hs = _simplify(head, math.max(3.0, _length(head) * 0.12));
  if (hs.length != 3) return null;
  final apex = hs[1];
  // Kanadın tepesi gövdenin bir ucunda.
  final atEnd = (apex - p1).distance;
  final atStart = (apex - p0).distance;
  final tipIsEnd = atEnd <= atStart;
  final tip = tipIsEnd ? p1 : p0;
  final tail = tipIsEnd ? p0 : p1;
  if ((apex - tip).distance > math.max(18.0, shaft * 0.2)) return null;
  for (final end in [hs[0], hs[2]]) {
    final l = (end - apex).distance;
    if (l < shaft * 0.06 || l > shaft * 0.6) return null;
    final ang = _angle(tail - tip, end - apex);
    if (ang < 10 || ang > 80) return null;
  }
  if (_cross2(tip - tail, hs[0] - tail).sign ==
      _cross2(tip - tail, hs[2] - tail).sign) {
    return null;
  }
  return InkFix(InkFixKind.arrow, [
    (points: [tail, tip], arrow: true),
  ], usesPrevious: true);
}

/// ÜÇGEN: kapalı çizgi, sadeleştirince üç köşe; her kenar çevrenin en az
/// %15'i.
InkFix? _triangle(List<Offset> pts) {
  final len = _length(pts);
  final chord = (pts.last - pts.first).distance;
  if (chord > len * 0.2) return null;
  // Kapalı döngü: ilk noktaya dönülür ki köşe bulma uçta kesilmesin. Başlangıç
  // köşede değilse (kenarın ortasından başlanmışsa) iki parça köşe çıkar;
  // başlangıç noktası sadeleştirmeden sonra atılırsa yine üç kalır.
  final closed = [...pts, pts.first];
  var s = _simplify(closed, len * 0.04);
  // Başlangıç bir kenarın ortasındaysa (köşe değil) düşer.
  if (s.length == 5) {
    final ang = _angle(s[1] - s[0], s[s.length - 2] - s[0]);
    if (ang > 150) s = s.sublist(1, s.length - 1)..add(s[1]);
  }
  if (s.length != 4) return null;
  final c = s.sublist(0, 3);
  for (var i = 0; i < 3; i++) {
    if ((c[(i + 1) % 3] - c[i]).distance < len * 0.15) return null;
  }
  return InkFix(InkFixKind.triangle, [
    (points: [c[0], c[1], c[2], c[0]], arrow: false),
  ]);
}
