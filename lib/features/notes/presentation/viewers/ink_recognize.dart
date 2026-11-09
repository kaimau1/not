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
enum InkFixKind {
  line,
  arrow,
  rectangle,
  ellipse,
  triangle,
  tick,
  cross,

  /// Dik açılı olmayan dörtgen (yamuk, paralelkenar).
  quad,

  /// Düzgün çokgen, 5–7 köşe (F55.3, 2026-11-09; sekizgen elle çizilmiş
  /// daireden güvenle ayrılmıyor — daire kalır).
  polygon,
}

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
    final cross = _singleStrokeCross(points, diag);
    if (cross != null) return cross;
  }
  if (!shapes || diag < kInkFixMinShape) return null;

  final arrow = _hookArrow(points);
  if (arrow != null) return arrow;

  // KAPALI ŞEKİLLER (2026-11-08 yeniden: "kare algılanmıyor, bazen çember
  // sanılıyor, dikdörtgen/üçgen de olmuyor"): bkz. [recognizeClosedShape].
  final closed = recognizeClosedShape(points);
  if (closed != null) {
    return InkFix(closed.kind, [(points: closed.outline, arrow: false)]);
  }
  final found = recognizeInkShape(points);
  if (found != null && found.shape == InkShape.line) {
    final kind = switch (found.shape) {
      InkShape.line => InkFixKind.line,
      InkShape.rectangle => InkFixKind.rectangle,
      InkShape.ellipse => InkFixKind.ellipse,
      InkShape.triangle => InkFixKind.triangle,
      InkShape.table => InkFixKind.rectangle,
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

/// [_straight]'ın çarpı kolu için gevşek hâli (hafif kavis serbest).
bool _roughlyStraight(List<Offset> pts) {
  final chord = (pts.last - pts.first).distance;
  if (chord <= 0) return false;
  if (chord < _length(pts) * 0.8) return false;
  final dir = (pts.last - pts.first) / chord;
  var dev = 0.0;
  for (final p in pts) {
    dev = math.max(dev, _cross2(p - pts.first, dir).abs());
  }
  return dev <= math.max(5.0, chord * 0.14);
}

/// TEK ÇİZGİDE ÇARPI: "\" → kalkmadan yukarı → "/" (4 köşe; 1. ve 3.
/// parça kesişir).
InkFix? _singleStrokeCross(List<Offset> pts, double diag) {
  final s = _dropCollinear(_simplify(pts, diag * 0.1));
  if (s.length != 4) return null;
  final fix = _cross([s[0], s[1]], [s[2], s[3]]);
  // Tek çizgi: kaldırılacak önceki çizgi yok.
  return fix == null ? null : InkFix(fix.kind, fix.strokes);
}

/// Sadeleşmiş çizgide neredeyse düz devam eden ara köşeleri atar (RDP eşit
/// uzaklıkta bir kenarın ortasında fazladan nokta bırakabiliyor).
List<Offset> _dropCollinear(List<Offset> s, {double maxTurn = 20}) {
  if (s.length < 3) return s;
  final out = <Offset>[s.first];
  for (var i = 1; i + 1 < s.length; i++) {
    final turn = _angle(s[i] - out.last, s[i + 1] - s[i]);
    if (turn >= maxTurn) out.add(s[i]);
  }
  out.add(s.last);
  return out;
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
  // 2026-11-09 ("X bazen tek çizgi sanılıyor, bazen tanınmıyor"): çabuk
  // atılan çarpının kolları hafif kavisli ve eşit değil — eşikler gevşedi.
  if (!_roughlyStraight(a) || !_roughlyStraight(b)) return null;
  final a0 = a.first, a1 = a.last, b0 = b.first, b1 = b.last;
  final la = (a1 - a0).distance, lb = (b1 - b0).distance;
  if (la < kInkFixMinMark || lb < kInkFixMinMark) return null;
  final ratio = la / lb;
  if (ratio < 0.4 || ratio > 2.5) return null;
  bool diagonal(Offset v) {
    final deg = math.atan2(v.dy.abs(), v.dx.abs()) * 180 / math.pi;
    return deg >= 15 && deg <= 75;
  }

  final da = a1 - a0, db = b1 - b0;
  if (!diagonal(da) || !diagonal(db)) return null;
  final denom = _cross2(da, db);
  if (denom.abs() < 1e-9) return null;
  // Kesişim parametreleri: a0 + da·t = b0 + db·u.
  final t = _cross2(b0 - a0, db) / denom;
  final u = _cross2(b0 - a0, da) / denom;
  if (t < 0.15 || t > 0.85 || u < 0.15 || u > 0.85) return null;
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


// ── Kapalı şekil tanıyıcı (2026-11-08) ────────────────────────────────

/// Tanınan kapalı şekil: tür + temiz dış çizgi (kapalı, ilk nokta sonda da).
/// [regular] = kare/daire/eşkenar düzeltmesi yapıldı.
typedef ClosedInkShape = ({
  InkFixKind kind,
  List<Offset> outline,
  bool regular,
});

/// **KAPALI ŞEKİL** (kullanıcı bulgusu 2026-11-08: "otomatik kare
/// algılanmıyor, hatta bazen kareler çember algılanıyor; dikdörtgen ve
/// üçgen de"). KÖK NEDEN: eski tanıyıcı yalnız EKSENE HİZALI kutuya göre
/// elips/dikdörtgen hatası ölçüyordu — köşeleri yuvarlak elle çizilmiş kare
/// elips hatasında daha düşük kalıyor (çember sanılıyor), biraz eğik
/// dikdörtgenin hatası eşiği aşıyor (hiç tanınmıyor).
///
/// Şimdi dört aday aynı ölçüyle (noktaların aday dış çizgiye ortalama
/// uzaklığı / köşegen) yarışır:
/// * elips — en küçük DÖNDÜRÜLMÜŞ kutunun iç elipsi,
/// * dikdörtgen — en küçük döndürülmüş kutu,
/// * dörtgen — dışbükey zarftaki en büyük alanlı dört köşe,
/// * üçgen — dışbükey zarftaki en büyük alanlı üç köşe.
///
/// **ÖNCE DÜZGÜN, ZORLANINCA SERBEST** (kullanıcı isteği 2026-11-08): en/boy
/// oranı 1'e yakınsa (≤ 1,18) KARE / DAİRE olur; belirgin uzunsa dikdörtgen
/// / elips; köşeler dik değilse serbest dörtgen. Eksene 10°'den yakın eğim
/// düzeltilir.
ClosedInkShape? recognizeClosedShape(List<Offset> pts) {
  if (pts.length < 8) return null;
  final len = _length(pts);
  final box = _bounds(pts);
  final diag = math.sqrt(box.width * box.width + box.height * box.height);
  if (diag < 16 || len < diag * 1.6) return null;
  // Kapanış: açıklık çevrenin %30'undan az (elle çizim tam kapanmaz).
  if ((pts.last - pts.first).distance > len * 0.3) return null;
  final hull = _convexHull(pts);
  if (hull.length < 3) return null;
  final hullArea = _polyArea(hull);
  // İnce uzun "döngü" (gidip gelen çizgi) şekil değil.
  if (hullArea < diag * diag * 0.04) return null;

  final mb = _minBox(hull);
  final rect = _rectOutline(mb.center, mb.w, mb.h, mb.angle);
  var reduced = _simplify([...hull, hull.first], diag * 0.02)..removeLast();
  // Köşe araması n⁴: zarf kısa tutulur (pil/kare bütçesi).
  if (reduced.length > 32) {
    reduced = _simplify([...hull, hull.first], diag * 0.05)..removeLast();
  }
  final tri = reduced.length >= 3 ? _maxAreaPolygon(reduced, 3) : null;
  final quad = reduced.length >= 4 ? _maxAreaPolygon(reduced, 4) : null;

  final eEll = _ellipseError(pts, mb) / diag;
  final eRect = _outlineError(pts, rect) / diag;
  final eTri = tri == null ? 9.0 : _outlineError(pts, [...tri, tri.first]) / diag;
  final eQuad = quad == null
      ? 9.0
      : _outlineError(pts, [...quad, quad.first]) / diag;

  // Daha çok serbestlik = küçük ceza (dörtgen her şeye biraz uyar).
  final scores = <InkFixKind, double>{
    InkFixKind.ellipse: eEll,
    InkFixKind.rectangle: eRect,
    InkFixKind.quad: eQuad * 1.25,
    InkFixKind.triangle: eTri * 0.95,
  };
  final best = scores.entries.reduce((a, b) => a.value <= b.value ? a : b);

  // ÇOKGEN (F55.3, 2026-11-09): 5–7 köşeli düzgün çokgen eskiden daire
  // sanılıyordu (elips hatası dörtgen/üçgenden düşük kalıyor). Yalnız
  // elipsten AÇIKÇA iyi uyuyorsa (≤ %60) ve kazanan elipsse ya da hiçbiri
  // tutmadıysa denenir — elle çizilmiş daire sekizgene de az çok uyar.
  if (best.key == InkFixKind.ellipse || best.value > 0.05) {
    final ratio = math.max(mb.w, mb.h) / math.max(1, math.min(mb.w, mb.h));
    if (ratio <= 1.35) {
      final pg = _regularPolygonFit(pts, hull, diag);
      if (pg != null &&
          pg.error <= 0.05 &&
          pg.error < eEll * 0.6 &&
          pg.error < math.min(eRect, math.min(eQuad, eTri))) {
        return (
          kind: InkFixKind.polygon,
          outline: _levelOutline(pg.outline),
          regular: true,
        );
      }
    }
  }
  if (best.value > 0.05) return null;

  switch (best.key) {
    case InkFixKind.ellipse:
      final ratio = math.max(mb.w, mb.h) / math.max(1, math.min(mb.w, mb.h));
      if (ratio <= 1.18) {
        final r = (mb.w + mb.h) / 4;
        return (
          kind: InkFixKind.ellipse,
          outline: _ellipseOutline(mb.center, r, r, 0),
          regular: true,
        );
      }
      return (
        kind: InkFixKind.ellipse,
        outline: _ellipseOutline(
          mb.center,
          mb.w / 2,
          mb.h / 2,
          _snapAngle(mb.angle),
        ),
        regular: false,
      );
    case InkFixKind.rectangle:
    case InkFixKind.quad:
      // Dörtgen kazandıysa ama köşeleri dik açıya yakınsa dikdörtgendir.
      final q = quad;
      final rightAngles =
          q != null &&
          [
            for (var i = 0; i < 4; i++)
              _angle(q[(i + 3) % 4] - q[i], q[(i + 1) % 4] - q[i]),
          ].every((a) => (a - 90).abs() <= 16);
      if (best.key == InkFixKind.quad && !rightAngles && eQuad < eRect * 0.7) {
        return (
          kind: InkFixKind.quad,
          outline: _levelOutline([...q!, q.first]),
          regular: false,
        );
      }
      final ratio = math.max(mb.w, mb.h) / math.max(1, math.min(mb.w, mb.h));
      final angle = _snapAngle(mb.angle);
      if (ratio <= 1.15) {
        final side = (mb.w + mb.h) / 2;
        return (
          kind: InkFixKind.rectangle,
          outline: _rectOutline(mb.center, side, side, angle),
          regular: true,
        );
      }
      return (
        kind: InkFixKind.rectangle,
        outline: _rectOutline(mb.center, mb.w, mb.h, angle),
        regular: false,
      );
    case InkFixKind.triangle:
      final t = tri!;
      return (
        kind: InkFixKind.triangle,
        outline: _levelOutline([...t, t.first]),
        regular: false,
      );
    default:
      return null;
  }
}

/// Eksene [kInkSnapDegrees]'den yakın eğim sıfırlanır (dik kenarlar).
/// Kullanıcı isteği 2026-11-09: "çizim mükemmel değil ama açı düzeltilmeli,
/// kişi 25 dereceden fazla eğik çizmediyse" (eskiden 10°).
double _snapAngle(double a) {
  final deg = a * 180 / math.pi;
  final m = ((deg % 90) + 90) % 90;
  if (m <= kInkSnapDegrees) return (deg - m) * math.pi / 180;
  if (m >= 90 - kInkSnapDegrees) return (deg + (90 - m)) * math.pi / 180;
  return a;
}

/// Şekil düzeltmesinde eksene oturtma eşiği (derece).
const kInkSnapDegrees = 25.0;

/// Çokgenin yataya en yakın kenarı [kInkSnapDegrees]'den az eğikse bütün
/// şekil o kadar döndürülür (üçgenin tabanı, dörtgenin/çokgenin bir kenarı
/// düz durur). Kapalı dış çizgi alır, kapalı döner.
List<Offset> _levelOutline(List<Offset> closed) {
  if (closed.length < 3) return closed;
  var best = double.infinity;
  for (var i = 0; i + 1 < closed.length; i++) {
    final e = closed[i + 1] - closed[i];
    if (e.distance < 1e-6) continue;
    // Yataya göre −90…90.
    var deg = math.atan2(e.dy, e.dx) * 180 / math.pi;
    if (deg > 90) deg -= 180;
    if (deg < -90) deg += 180;
    if (deg.abs() < best.abs()) best = deg;
  }
  if (!best.isFinite || best.abs() < 0.5 || best.abs() > kInkSnapDegrees) {
    return closed;
  }
  final c = _centroid(closed.sublist(0, closed.length - 1));
  final a = -best * math.pi / 180;
  return [for (final p in closed) c + _rot(p - c, a)];
}

/// Andrew'un monoton zinciri (saat yönünün tersine).
List<Offset> _convexHull(List<Offset> input) {
  final pts = [...input]
    ..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  if (pts.length < 3) return pts;
  double cross(Offset o, Offset a, Offset b) => _cross2(a - o, b - o);
  final lower = <Offset>[];
  for (final p in pts) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }
  final upper = <Offset>[];
  for (final p in pts.reversed) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }
  return [...lower..removeLast(), ...upper..removeLast()];
}

double _polyArea(List<Offset> poly) {
  var a = 0.0;
  for (var i = 0; i < poly.length; i++) {
    a += _cross2(poly[i], poly[(i + 1) % poly.length]);
  }
  return a.abs() / 2;
}

/// En küçük alanlı döndürülmüş kutu (zarfın kenar yönleri denenir).
({Offset center, double w, double h, double angle}) _minBox(
  List<Offset> hull,
) {
  var best = (center: Offset.zero, w: 0.0, h: 0.0, angle: 0.0);
  var bestArea = double.infinity;
  for (var i = 0; i < hull.length; i++) {
    final e = hull[(i + 1) % hull.length] - hull[i];
    if (e.distance < 1e-6) continue;
    final ang = math.atan2(e.dy, e.dx);
    final c = math.cos(-ang), s = math.sin(-ang);
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in hull) {
      final x = p.dx * c - p.dy * s;
      final y = p.dx * s + p.dy * c;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    final area = (maxX - minX) * (maxY - minY);
    if (area < bestArea) {
      bestArea = area;
      final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
      // Merkezi geri döndür.
      final cc = math.cos(ang), ss = math.sin(ang);
      best = (
        center: Offset(cx * cc - cy * ss, cx * ss + cy * cc),
        w: maxX - minX,
        h: maxY - minY,
        angle: ang,
      );
    }
  }
  return best;
}

Offset _rot(Offset v, double a) {
  final c = math.cos(a), s = math.sin(a);
  return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
}

List<Offset> _rectOutline(Offset c, double w, double h, double a) {
  final corners = [
    Offset(-w / 2, -h / 2),
    Offset(w / 2, -h / 2),
    Offset(w / 2, h / 2),
    Offset(-w / 2, h / 2),
  ].map((v) => c + _rot(v, a)).toList();
  return [...corners, corners.first];
}

List<Offset> _ellipseOutline(Offset c, double rx, double ry, double a) {
  const steps = 48;
  return [
    for (var i = 0; i <= steps; i++)
      c +
          _rot(
            Offset(
              rx * math.cos(2 * math.pi * i / steps),
              ry * math.sin(2 * math.pi * i / steps),
            ),
            a,
          ),
  ];
}

/// Noktaların kapalı çokgen dış çizgisine ortalama uzaklığı.
double _outlineError(List<Offset> pts, List<Offset> outline) {
  var sum = 0.0;
  for (final p in pts) {
    var d = double.infinity;
    for (var i = 0; i + 1 < outline.length; i++) {
      d = math.min(d, _segDistance(p, outline[i], outline[i + 1]));
    }
    sum += d;
  }
  return sum / pts.length;
}

/// Noktaların [mb] kutusunun iç elipsine yaklaşık ortalama uzaklığı.
double _ellipseError(
  List<Offset> pts,
  ({Offset center, double w, double h, double angle}) mb,
) {
  final a = math.max(1.0, mb.w / 2), b = math.max(1.0, mb.h / 2);
  var sum = 0.0;
  for (final p in pts) {
    final q = _rot(p - mb.center, -mb.angle);
    final r = math.sqrt(math.pow(q.dx / a, 2) + math.pow(q.dy / b, 2));
    if (r < 1e-9) {
      sum += math.min(a, b);
      continue;
    }
    // Işın üstündeki elips noktasına uzaklık.
    sum += (q.distance - q.distance / r).abs();
  }
  return sum / pts.length;
}

/// Sadeleşmiş zarftan en büyük alanlı [k] köşe (k = 3 ya da 4), zarf
/// sırasıyla.
List<Offset> _maxAreaPolygon(List<Offset> hull, int k) {
  final n = hull.length;
  var best = <Offset>[];
  var bestArea = -1.0;
  if (k == 3) {
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        for (var l = j + 1; l < n; l++) {
          final a = _polyArea([hull[i], hull[j], hull[l]]);
          if (a > bestArea) {
            bestArea = a;
            best = [hull[i], hull[j], hull[l]];
          }
        }
      }
    }
    return best;
  }
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      for (var l = j + 1; l < n; l++) {
        for (var m = l + 1; m < n; m++) {
          final a = _polyArea([hull[i], hull[j], hull[l], hull[m]]);
          if (a > bestArea) {
            bestArea = a;
            best = [hull[i], hull[j], hull[l], hull[m]];
          }
        }
      }
    }
  }
  return best;
}

/// Düzgün [k]-gen (k = 5…7) uydurma: merkez zarfın alan merkezi, yarıçap
/// noktaların merkeze ortalama uzaklığı (köşe ile kenar ortası arası), dönüş
/// 24 adımda aranır. En düşük hata (/ köşegen) veren k kazanır.
({List<Offset> outline, double error})? _regularPolygonFit(
  List<Offset> pts,
  List<Offset> hull,
  double diag,
) {
  final center = _centroid(hull);
  // Hata ölçümü için en çok 64 nokta (pil/kare bütçesi).
  final step = math.max(1, pts.length ~/ 64);
  final sample = [for (var i = 0; i < pts.length; i += step) pts[i]];
  var meanR = 0.0;
  for (final p in sample) {
    meanR += (p - center).distance;
  }
  meanR /= sample.length;
  if (meanR < 1) return null;
  List<Offset>? bestOutline;
  var bestErr = double.infinity;
  // 8: elle çizilmiş daireyle ayrılmıyor (ölçüldü: hata oranı 0,62 / 0,6).
  for (var k = 5; k <= 7; k++) {
    // Çevre noktalarının ortalama uzaklığı ≈ köşe yarıçapının bu oranı.
    final r = meanR / ((1 + math.cos(math.pi / k)) / 2);
    const steps = 24;
    for (var j = 0; j < steps; j++) {
      final rot = (2 * math.pi / k) * j / steps - math.pi / 2;
      final outline = [
        for (var i = 0; i <= k; i++)
          center +
              Offset(
                r * math.cos(rot + 2 * math.pi * i / k),
                r * math.sin(rot + 2 * math.pi * i / k),
              ),
      ];
      final e = _outlineError(sample, outline) / diag;
      if (e < bestErr) {
        bestErr = e;
        bestOutline = outline;
      }
    }
  }
  if (bestOutline == null) return null;
  return (outline: bestOutline, error: bestErr);
}

/// Kapalı çokgenin alan merkezi (dejenere ise köşe ortalaması).
Offset _centroid(List<Offset> poly) {
  var a = 0.0, cx = 0.0, cy = 0.0;
  for (var i = 0; i < poly.length; i++) {
    final p = poly[i], q = poly[(i + 1) % poly.length];
    final c = _cross2(p, q);
    a += c;
    cx += (p.dx + q.dx) * c;
    cy += (p.dy + q.dy) * c;
  }
  if (a.abs() < 1e-9) {
    var s = Offset.zero;
    for (final p in poly) {
      s += p;
    }
    return s / poly.length.toDouble();
  }
  return Offset(cx / (3 * a), cy / (3 * a));
}
