import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bir temanın açık ya da koyu tonları.
@immutable
class NoteThemePalette {
  const NoteThemePalette({
    required this.top,
    required this.bottom,
    required this.art,
    required this.accent,
    required this.ink,
  });

  /// Zeminin dikey geçişi (üst → alt).
  final Color top;
  final Color bottom;

  /// Süslemenin ana rengi (yaprak gölgesi, yıldız, dalga…).
  final Color art;

  /// İkincil süsleme rengi (ay, güneş, çiçek göbeği, kabartma gölgesi).
  final Color accent;

  /// Temayla tam uyumlu vurgu/mürekkep tonu: defter çizgileri, kutucuklar,
  /// sayfa çubuğu ve alt kapsüller bu tondan beslenir; hem [top] hem
  /// [bottom] üzerinde okunur (WCAG AA ≥ 4,5:1).
  final Color ink;

  /// Notun DÜZ zemini: alt çubuk, kart ve geçiş bu rengi kullanır — sayfanın
  /// alt ucuyla birleşsin diye geçişin alt rengi.
  Color get base => bottom;

  /// [t] (0 üst – 1 alt) yüksekliğindeki zemin rengi.
  Color at(double t) => Color.lerp(top, bottom, t.clamp(0.0, 1.0))!;
}

/// **NOT TEMASI** (kullanıcı isteği 2026-10-28: "notun görselini/rengini
/// değiştirme ekranı güzel" — örnek uygulamada palmiye gölgeli krem, yapraklı
/// turkuaz, yıldızlı gece zeminleri).
///
/// Görsel dosyası DEĞİL, çizim: APK büyümez, her ekran yoğunluğunda keskin,
/// kartta küçülünce de orantılı; her temanın açık ve koyu tonları ayrı
/// (koyu temada göz almasın, yazı hep okunur kalsın).
@immutable
class NoteTheme {
  const NoteTheme(this.id, this.light, this.dark, this._art);

  final String id;
  final NoteThemePalette light;
  final NoteThemePalette dark;
  final void Function(Canvas canvas, Size size, NoteThemePalette p, double u)
  _art;

  NoteThemePalette palette(bool dark) => dark ? this.dark : light;
}

abstract final class NoteThemes {
  static const paper = 'paper';
  static const palm = 'palm';
  static const lagoon = 'lagoon';
  static const night = 'night';
  static const sunset = 'sunset';
  static const sakura = 'sakura';
  static const waves = 'waves';
  static const meadow = 'meadow';
  static const aurora = 'aurora';
  static const citrus = 'citrus';
  static const botanical = 'botanical';
  static const terracotta = 'terracotta';
  static const confetti = 'confetti';
  static const cobalt = 'cobalt';

  /// Seçicideki sıra: yeni canlı temalarla birlikte 14 sayfa teması.
  static const List<NoteTheme> all = [
    NoteTheme(
      aurora,
      NoteThemePalette(
        top: Color(0xFFDDF6F0),
        bottom: Color(0xFFF3ECFA),
        art: Color(0xA64FD4B6),
        accent: Color(0x99F28CB4),
        ink: Color(0xFF0E574D),
      ),
      NoteThemePalette(
        top: Color(0xFF0E1D2B),
        bottom: Color(0xFF1A1830),
        art: Color(0x664DE0C6),
        accent: Color(0x55C48DFC),
        ink: Color(0xFF9AF2E2),
      ),
      _aurora,
    ),
    NoteTheme(
      citrus,
      NoteThemePalette(
        top: Color(0xFFFFF0CA),
        bottom: Color(0xFFFFFBF0),
        art: Color(0xB3FFA242),
        accent: Color(0x9970B46B),
        ink: Color(0xFF784608),
      ),
      NoteThemePalette(
        top: Color(0xFF281F12),
        bottom: Color(0xFF1D1810),
        art: Color(0x88E09238),
        accent: Color(0x706CA663),
        ink: Color(0xFFFFD494),
      ),
      _citrus,
    ),
    NoteTheme(
      botanical,
      NoteThemePalette(
        top: Color(0xFFE0F2E8),
        bottom: Color(0xFFF6FBF7),
        art: Color(0x993EA678),
        accent: Color(0xCCF27B63),
        ink: Color(0xFF15573A),
      ),
      NoteThemePalette(
        top: Color(0xFF11221B),
        bottom: Color(0xFF0F1B16),
        art: Color(0x99357A5B),
        accent: Color(0x99E8806B),
        ink: Color(0xFF9EEBC5),
      ),
      _botanical,
    ),
    NoteTheme(
      terracotta,
      NoteThemePalette(
        top: Color(0xFFFAE2D4),
        bottom: Color(0xFFFDF5EF),
        art: Color(0x99DE7A54),
        accent: Color(0x804E8AC2),
        ink: Color(0xFF7D3318),
      ),
      NoteThemePalette(
        top: Color(0xFF291A15),
        bottom: Color(0xFF1E1411),
        art: Color(0x88AD5539),
        accent: Color(0x706494C4),
        ink: Color(0xFFFFC1A6),
      ),
      _terracotta,
    ),
    NoteTheme(
      confetti,
      NoteThemePalette(
        top: Color(0xFFEEF1FF),
        bottom: Color(0xFFFFF9F5),
        art: Color(0xB8F07CA6),
        accent: Color(0xB359B2E8),
        ink: Color(0xFF4D348C),
      ),
      NoteThemePalette(
        top: Color(0xFF18162B),
        bottom: Color(0xFF1E172B),
        art: Color(0x99F08AB2),
        accent: Color(0x996EC9FA),
        ink: Color(0xFFD9C7FF),
      ),
      _confetti,
    ),
    NoteTheme(
      cobalt,
      NoteThemePalette(
        top: Color(0xFFDCEBFC),
        bottom: Color(0xFFF5FAFF),
        art: Color(0x995A9AE8),
        accent: Color(0xA6E8B14E),
        ink: Color(0xFF14488A),
      ),
      NoteThemePalette(
        top: Color(0xFF0D192E),
        bottom: Color(0xFF111F38),
        art: Color(0x803C7CD6),
        accent: Color(0x99F2C672),
        ink: Color(0xFFA8D0FF),
      ),
      _cobalt,
    ),
    NoteTheme(
      palm,
      NoteThemePalette(
        top: Color(0xFFFFF1CC),
        bottom: Color(0xFFFFFBEF),
        art: Color(0x8CE3CC8C),
        accent: Color(0x40D9BF73),
        ink: Color(0xFF644E0E),
      ),
      NoteThemePalette(
        top: Color(0xFF2B2517),
        bottom: Color(0xFF1E1B13),
        art: Color(0x99453A22),
        accent: Color(0x403E3420),
        ink: Color(0xFFE8D196),
      ),
      _palm,
    ),
    NoteTheme(
      lagoon,
      NoteThemePalette(
        top: Color(0xFFA6DDD0),
        bottom: Color(0xFFCAEEE6),
        art: Color(0xA6BDE8DE),
        accent: Color(0x667FC4B4),
        ink: Color(0xFF0C4D43),
      ),
      NoteThemePalette(
        top: Color(0xFF0F3B36),
        bottom: Color(0xFF0B2B28),
        art: Color(0x9918544D),
        accent: Color(0x80082320),
        ink: Color(0xFF9BE6D8),
      ),
      _lagoon,
    ),
    NoteTheme(
      night,
      NoteThemePalette(
        top: Color(0xFFD7DEF7),
        bottom: Color(0xFFF2EFFB),
        art: Color(0xB37F8CC9),
        accent: Color(0xFFFFF4D6),
        ink: Color(0xFF2F3E80),
      ),
      NoteThemePalette(
        top: Color(0xFF0B1633),
        bottom: Color(0xFF1A2A55),
        art: Color(0xE6FFFFFF),
        accent: Color(0xFFF5EBC8),
        ink: Color(0xFFC2D1FF),
      ),
      _night,
    ),
    NoteTheme(
      sunset,
      NoteThemePalette(
        top: Color(0xFFFFD6BF),
        bottom: Color(0xFFFFF4EA),
        art: Color(0xA6FFFFFF),
        accent: Color(0x99FFA77A),
        ink: Color(0xFF833319),
      ),
      NoteThemePalette(
        top: Color(0xFF3A1D2C),
        bottom: Color(0xFF21131D),
        art: Color(0x664E2B3E),
        accent: Color(0x80A2475A),
        ink: Color(0xFFFFC1A6),
      ),
      _sunset,
    ),
    NoteTheme(
      sakura,
      NoteThemePalette(
        top: Color(0xFFFFE4EB),
        bottom: Color(0xFFFFF7F9),
        art: Color(0xB3F4ABC0),
        accent: Color(0x80B88F8F),
        ink: Color(0xFF822D4C),
      ),
      NoteThemePalette(
        top: Color(0xFF2F1B23),
        bottom: Color(0xFF1F1419),
        art: Color(0x99703A4D),
        accent: Color(0x80503139),
        ink: Color(0xFFFBBFD3),
      ),
      _sakura,
    ),
    NoteTheme(
      waves,
      NoteThemePalette(
        top: Color(0xFFE6F3FC),
        bottom: Color(0xFFD3EAF8),
        art: Color(0x99A9D3EF),
        accent: Color(0x80FFFFFF),
        ink: Color(0xFF174F77),
      ),
      NoteThemePalette(
        top: Color(0xFF0C1D2B),
        bottom: Color(0xFF0B2536),
        art: Color(0x8C1A4F72),
        accent: Color(0x33FFFFFF),
        ink: Color(0xFFA2D9FA),
      ),
      _waves,
    ),
    NoteTheme(
      meadow,
      NoteThemePalette(
        top: Color(0xFFF1F8E6),
        bottom: Color(0xFFE1F1D0),
        art: Color(0x99A2CC86),
        accent: Color(0xCCFFFFFF),
        ink: Color(0xFF2B561F),
      ),
      NoteThemePalette(
        top: Color(0xFF162218),
        bottom: Color(0xFF1B2C1D),
        art: Color(0x99345A38),
        accent: Color(0x66C9D9B0),
        ink: Color(0xFFB7E4A4),
      ),
      _meadow,
    ),
    NoteTheme(
      paper,
      NoteThemePalette(
        top: Color(0xFFFBF7EE),
        bottom: Color(0xFFF5EEDF),
        art: Color(0x14000000),
        accent: Color(0x0F5A4320),
        ink: Color(0xFF5A4322),
      ),
      NoteThemePalette(
        top: Color(0xFF27241F),
        bottom: Color(0xFF1F1C18),
        art: Color(0x12FFFFFF),
        accent: Color(0x26000000),
        ink: Color(0xFFE0D3BC),
      ),
      _paper,
    ),
  ];

  /// Kimliğin teması; boş ya da bu sürümün tanımadığı kimlikte null.
  static NoteTheme? byId(String id) {
    if (id.isEmpty) return null;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ── Çizimler ───────────────────────────────────────────────────────────
  // `u`: ölçek birimi — 400 dp'lik bir sayfada 1. Kartta küçülür, tablette
  // büyür; süslemenin oranı her boyda aynı kalır.

  static void _palm(Canvas c, Size s, NoteThemePalette p, double u) {
    // Yaprak GÖLGELERİ: yumuşak kenarlı (örnekteki gibi pencereden düşen
    // palmiye gölgesi). Her yaprak tek yol, tek bulanık çizim.
    final shade = Paint()
      ..color = p.art
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.6 * u);
    final faint = Paint()
      ..color = p.accent
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * u);
    _frond(c, Offset(-24 * u, -30 * u), 0.55, 300 * u, shade, curl: 0.22);
    _frond(c, Offset(-40 * u, 40 * u), 0.05, 220 * u, faint, curl: 0.3);
    _frond(c, Offset(s.width + 20 * u, -20 * u), 2.45, 270 * u, shade);
    _frond(c, Offset(s.width + 10 * u, 10 * u), 1.95, 190 * u, faint);
    _frond(
      c,
      Offset(s.width + 30 * u, s.height * 0.82),
      3.5,
      240 * u,
      faint,
      curl: -0.22,
    );
  }

  /// Palmiye yaprağı: kavisli orta damar + iki yana incelen yaprakçıklar.
  static void _frond(
    Canvas c,
    Offset start,
    double angle,
    double length,
    Paint paint, {
    double curl = 0.25,
  }) {
    final dir = Offset(math.cos(angle), math.sin(angle));
    final normal = Offset(-dir.dy, dir.dx);
    final end = start + dir * length;
    final ctrl = start + dir * (length * 0.5) + normal * (length * curl);
    final path = Path();
    // Orta damar ince bir şerit (çizgi yerine dolgu: tek yol, tek boyama).
    const ribSteps = 14;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= ribSteps; i++) {
      final t = i / ribSteps;
      final pt = _quad(start, ctrl, end, t);
      final tan = _quadTangent(start, ctrl, end, t);
      final n = Offset(-tan.dy, tan.dx);
      final w = length * 0.012 * (1 - t * 0.8);
      left.add(pt + n * w);
      right.add(pt - n * w);
    }
    path.moveTo(left.first.dx, left.first.dy);
    for (final pt in left.skip(1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    for (final pt in right.reversed) {
      path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    const leaflets = 17;
    for (var i = 1; i <= leaflets; i++) {
      final t = 0.06 + 0.92 * i / (leaflets + 1);
      final base = _quad(start, ctrl, end, t);
      final tan = _quadTangent(start, ctrl, end, t);
      final heading = math.atan2(tan.dy, tan.dx);
      for (final side in const [-1.0, 1.0]) {
        // Uca doğru kısalır ve damara yatar; küçük düzensizlik canlı gösterir.
        final wobble = 0.9 + 0.2 * ((i * 7 + (side > 0 ? 3 : 0)) % 5) / 4;
        final len = length * 0.4 * (1 - t * 0.6) * wobble;
        final a = heading + side * (1.0 - 0.5 * t);
        final d = Offset(math.cos(a), math.sin(a));
        final perp = Offset(-d.dy, d.dx);
        final tip = base + d * len;
        // Yaprakçık hafif sarkar (uca doğru eğilir).
        final mid = base + d * (len * 0.5) + Offset(dir.dx, dir.dy) * len * 0.1;
        final width = len * 0.11;
        path
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            mid.dx + perp.dx * width,
            mid.dy + perp.dy * width,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            mid.dx - perp.dx * width,
            mid.dy - perp.dy * width,
            base.dx,
            base.dy,
          )
          ..close();
      }
    }
    c.drawPath(path, paint);
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final mt = 1 - t;
    return a * (mt * mt) + b * (2 * mt * t) + c * (t * t);
  }

  static Offset _quadTangent(Offset a, Offset b, Offset c, double t) {
    final d = (b - a) * (2 * (1 - t)) + (c - b) * (2 * t);
    final len = d.distance;
    return len == 0 ? const Offset(1, 0) : d / len;
  }

  static void _lagoon(Canvas c, Size s, NoteThemePalette p, double u) {
    // KABARTMA yapraklar: önce kayık gölge, sonra açık ton, sonra damarlar
    // (örnekteki turkuaz zeminde yaprakların kabartma görünüşü).
    void leaf(Offset base, double angle, double length) {
      final path = _leafPath(base, angle, length);
      c.drawPath(
        path.shift(Offset(3 * u, 4 * u)),
        Paint()
          ..color = p.accent
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * u),
      );
      c.drawPath(path, Paint()..color = p.art);
      final vein = Paint()
        ..color = p.accent
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6 * u;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final normal = Offset(-dir.dy, dir.dx);
      c.drawLine(base, base + dir * (length * 0.92), vein);
      for (var i = 1; i <= 6; i++) {
        final t = i / 7;
        final at = base + dir * (length * t);
        final reach = length * 0.3 * math.sin(math.pi * t) + 4 * u;
        for (final side in const [-1.0, 1.0]) {
          c.drawLine(
            at,
            at + dir * (reach * 0.55) + normal * (reach * side),
            vein,
          );
        }
      }
    }

    leaf(Offset(s.width + 30 * u, s.height + 20 * u), 3.85, 330 * u);
    leaf(Offset(s.width * 0.55, s.height + 40 * u), 4.45, 250 * u);
    leaf(Offset(-30 * u, -20 * u), 0.75, 280 * u);
    leaf(Offset(s.width + 20 * u, s.height * 0.32), 2.75, 170 * u);
  }

  /// Uçları sivri, ortası dolgun yaprak.
  static Path _leafPath(Offset base, double angle, double length) {
    final dir = Offset(math.cos(angle), math.sin(angle));
    final normal = Offset(-dir.dy, dir.dx);
    final tip = base + dir * length;
    final w = length * 0.34;
    final a1 = base + dir * (length * 0.15) + normal * w;
    final a2 = base + dir * (length * 0.75) + normal * (w * 0.8);
    final b1 = base + dir * (length * 0.75) - normal * (w * 0.8);
    final b2 = base + dir * (length * 0.15) - normal * w;
    return Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(a1.dx, a1.dy, a2.dx, a2.dy, tip.dx, tip.dy)
      ..cubicTo(b1.dx, b1.dy, b2.dx, b2.dy, base.dx, base.dy)
      ..close();
  }

  static void _night(Canvas c, Size s, NoteThemePalette p, double u) {
    final rnd = math.Random(7);
    final count = (s.width * s.height / (2600 * u * u)).clamp(18, 150).toInt();
    final star = Paint();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * s.width;
      // Yıldızlar üstte yoğun, aşağı doğru seyrelir.
      final y = math.pow(rnd.nextDouble(), 1.6) * s.height;
      final r = (0.5 + rnd.nextDouble() * 1.2) * u.clamp(0.6, 1.4);
      star.color = p.art.withValues(
        alpha: p.art.a * (0.35 + rnd.nextDouble() * 0.65),
      );
      c.drawCircle(Offset(x, y.toDouble()), r, star);
    }
    // Birkaç parıltı (dört köşeli yıldız).
    for (var i = 0; i < (count / 14).ceil(); i++) {
      final x = rnd.nextDouble() * s.width;
      final y = math.pow(rnd.nextDouble(), 1.4) * s.height * 0.8;
      _sparkle(
        c,
        Offset(x, y.toDouble()),
        (4 + rnd.nextDouble() * 4) * u,
        star..color = p.art,
      );
    }
    // Hilal: dolu daire, üstüne zemin renginde kayık daire.
    final moon = Offset(s.width - 64 * u, 70 * u);
    final r = 26 * u;
    c.drawCircle(
      moon,
      r * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.accent.withValues(alpha: 0.28),
            p.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: moon, radius: r * 2.6)),
    );
    c.drawCircle(moon, r, Paint()..color = p.accent);
    c.drawCircle(
      moon + Offset(r * 0.48, -r * 0.3),
      r * 0.88,
      Paint()..color = p.at(moon.dy / s.height),
    );
  }

  static void _sparkle(Canvas c, Offset at, double r, Paint paint) {
    final k = r * 0.22;
    c.drawPath(
      Path()
        ..moveTo(at.dx, at.dy - r)
        ..quadraticBezierTo(at.dx + k, at.dy - k, at.dx + r, at.dy)
        ..quadraticBezierTo(at.dx + k, at.dy + k, at.dx, at.dy + r)
        ..quadraticBezierTo(at.dx - k, at.dy + k, at.dx - r, at.dy)
        ..quadraticBezierTo(at.dx - k, at.dy - k, at.dx, at.dy - r)
        ..close(),
      paint,
    );
  }

  static void _sunset(Canvas c, Size s, NoteThemePalette p, double u) {
    final sun = Offset(s.width * 0.76, 96 * u);
    final r = 48 * u;
    c.drawCircle(
      sun,
      r * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.accent.withValues(alpha: p.accent.a * 0.7),
            p.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: r * 3)),
    );
    c.drawCircle(sun, r, Paint()..color = p.accent);
    // Uzun, yumuşak bulut şeritleri (güneşin önünden geçer).
    final cloud = Paint()
      ..color = p.art
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * u);
    void streak(double x, double y, double w, double h) => c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(h / 2),
      ),
      cloud,
    );
    streak(s.width * 0.48, sun.dy + 14 * u, 190 * u, 13 * u);
    streak(s.width * 0.62, sun.dy + 36 * u, 150 * u, 10 * u);
    streak(-20 * u, 150 * u, 160 * u, 12 * u);
    streak(20 * u, 172 * u, 110 * u, 9 * u);
    streak(s.width * 0.3, s.height * 0.78, 220 * u, 12 * u);
    // Uzakta iki-üç kuş.
    final bird = Paint()
      ..color = p.accent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * u
      ..strokeCap = StrokeCap.round;
    for (final (dx, dy, k) in const [
      (0.30, 70.0, 1.0),
      (0.37, 58.0, 0.8),
      (0.25, 52.0, 0.7),
    ]) {
      final at = Offset(s.width * dx, dy * u);
      final w = 9 * u * k;
      c.drawPath(
        Path()
          ..moveTo(at.dx - w, at.dy - w * 0.4)
          ..quadraticBezierTo(at.dx - w * 0.4, at.dy - w * 0.7, at.dx, at.dy)
          ..quadraticBezierTo(
            at.dx + w * 0.4,
            at.dy - w * 0.7,
            at.dx + w,
            at.dy - w * 0.4,
          ),
        bird,
      );
    }
  }

  static void _sakura(Canvas c, Size s, NoteThemePalette p, double u) {
    // Sağ üstten sarkan ince dal ve üstünde çiçekler.
    final branch = Paint()
      ..color = p.accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2 * u;
    final b0 = Offset(s.width + 10 * u, 18 * u);
    final b1 = Offset(s.width - 120 * u, 60 * u);
    final b2 = Offset(s.width - 210 * u, 30 * u);
    c.drawPath(
      Path()
        ..moveTo(b0.dx, b0.dy)
        ..quadraticBezierTo(s.width - 60 * u, 70 * u, b1.dx, b1.dy)
        ..quadraticBezierTo(s.width - 170 * u, 55 * u, b2.dx, b2.dy),
      branch,
    );
    c.drawLine(b1, b1 + Offset(-30 * u, 48 * u), branch..strokeWidth = 2 * u);
    final petal = Paint()..color = p.art;
    final heart = Paint()..color = p.accent;
    for (final (at, r) in [
      (b1 + Offset(6 * u, -8 * u), 13.0),
      (b2 + Offset(-4 * u, 6 * u), 11.0),
      (Offset(s.width - 60 * u, 64 * u), 10.0),
      (b1 + Offset(-28 * u, 50 * u), 11.0),
      (Offset(s.width - 160 * u, 50 * u), 8.0),
    ]) {
      _blossom(c, at, r * u, petal, heart);
    }
    // Düşen yapraklar: aşağıya doğru seyrelir.
    final rnd = math.Random(11);
    final count = (s.width * s.height / (5200 * u * u)).clamp(8, 46).toInt();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = (0.08 + math.pow(rnd.nextDouble(), 1.3) * 0.92) * s.height;
      final size = (5 + rnd.nextDouble() * 5) * u;
      petal.color = p.art.withValues(
        alpha: p.art.a * (0.45 + rnd.nextDouble() * 0.55),
      );
      _petal(
        c,
        Offset(x, y.toDouble()),
        size,
        rnd.nextDouble() * math.pi * 2,
        petal,
      );
    }
  }

  static void _blossom(
    Canvas c,
    Offset at,
    double r,
    Paint petal,
    Paint heart,
  ) {
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      _petal(
        c,
        at + Offset(math.cos(a), math.sin(a)) * (r * 0.55),
        r * 0.62,
        a,
        petal,
      );
    }
    c.drawCircle(at, r * 0.22, heart);
  }

  /// Ucu çentikli kiraz yaprağı ([angle] yönünde).
  static void _petal(Canvas c, Offset at, double r, double angle, Paint paint) {
    c
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(angle + math.pi / 2)
      ..drawPath(
        Path()
          ..moveTo(0, r)
          ..cubicTo(-r * 0.9, r * 0.3, -r * 0.7, -r * 0.9, -r * 0.12, -r)
          ..lineTo(0, -r * 0.78)
          ..lineTo(r * 0.12, -r)
          ..cubicTo(r * 0.7, -r * 0.9, r * 0.9, r * 0.3, 0, r)
          ..close(),
        paint,
      )
      ..restore();
  }

  static void _waves(Canvas c, Size s, NoteThemePalette p, double u) {
    // Alttan üç katman dalga; her katman bir öncekinden koyu ve alçak.
    for (var k = 0; k < 3; k++) {
      final baseY = s.height - (118 - k * 34) * u;
      final amp = (9 - k * 1.5) * u;
      final len = (170 + k * 40) * u;
      final phase = k * 1.3;
      final path = Path()..moveTo(0, s.height);
      path.lineTo(0, baseY);
      for (var x = 0.0; x <= s.width + 4; x += 4) {
        path.lineTo(x, baseY + math.sin(x / len * 2 * math.pi + phase) * amp);
      }
      path
        ..lineTo(s.width, s.height)
        ..close();
      c.drawPath(
        path,
        Paint()..color = p.art.withValues(alpha: p.art.a * (0.55 + k * 0.2)),
      );
    }
    // Üstte ince köpük çizgileri ve birkaç kabarcık.
    final foam = Paint()
      ..color = p.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * u
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(5);
    for (var i = 0; i < 7; i++) {
      final at = Offset(
        rnd.nextDouble() * s.width,
        s.height - (40 + rnd.nextDouble() * 120) * u,
      );
      c.drawCircle(at, (2 + rnd.nextDouble() * 4) * u, foam);
    }
    for (var i = 0; i < 4; i++) {
      final y = (60 + i * 46) * u;
      final x = (i.isEven ? 0.12 : 0.55) * s.width;
      c.drawLine(Offset(x, y), Offset(x + 50 * u, y), foam);
    }
  }

  static void _meadow(Canvas c, Size s, NoteThemePalette p, double u) {
    final rnd = math.Random(3);
    final blade = Paint()
      ..color = p.art
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final count = (s.width / (5 * u)).clamp(24, 160).toInt();
    for (var i = 0; i < count; i++) {
      final x = i / count * s.width + rnd.nextDouble() * 4 * u;
      final h = (36 + rnd.nextDouble() * 70) * u;
      final lean = (rnd.nextDouble() - 0.5) * 34 * u;
      blade
        ..strokeWidth = (1.6 + rnd.nextDouble() * 1.6) * u
        ..color = p.art.withValues(
          alpha: p.art.a * (0.55 + rnd.nextDouble() * 0.45),
        );
      c.drawPath(
        Path()
          ..moveTo(x, s.height + 2)
          ..quadraticBezierTo(
            x + lean * 0.2,
            s.height - h * 0.6,
            x + lean,
            s.height - h,
          ),
        blade,
      );
    }
    // Çimenin arasında birkaç küçük çiçek.
    final flower = Paint()..color = p.accent;
    for (var i = 0; i < 9; i++) {
      final at = Offset(
        rnd.nextDouble() * s.width,
        s.height - (20 + rnd.nextDouble() * 60) * u,
      );
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * math.pi / 5;
        c.drawCircle(
          at + Offset(math.cos(a), math.sin(a)) * 3 * u,
          2.2 * u,
          flower,
        );
      }
    }
  }

  static void _paper(Canvas c, Size s, NoteThemePalette p, double u) {
    // İnce kâğıt dokusu + kenarlarda hafif gölge.
    final rnd = math.Random(9);
    final grain = Paint()..color = p.art;
    final count = (s.width * s.height / (700 * u * u)).clamp(60, 900).toInt();
    for (var i = 0; i < count; i++) {
      c.drawCircle(
        Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height),
        (0.4 + rnd.nextDouble() * 0.7) * u.clamp(0.7, 1.3),
        grain,
      );
    }
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [p.accent.withValues(alpha: 0), p.accent],
          stops: const [0.62, 1],
        ).createShader(rect),
    );
  }

  /// Aurora: üst sol ve alt sağ köşelerden akan ışıklı şeritler + ince parıltılar.
  static void _aurora(Canvas c, Size s, NoteThemePalette p, double u) {
    final topRibbon = Path()
      ..moveTo(-20 * u, 0)
      ..lineTo(s.width * 0.72, 0)
      ..cubicTo(
        s.width * 0.48,
        62 * u,
        s.width * 0.22,
        42 * u,
        -20 * u,
        155 * u,
      )
      ..close();
    c.drawPath(
      topRibbon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.art, p.accent.withValues(alpha: p.accent.a * 0.55), p.art.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, s.width * 0.75, 170 * u)),
    );
    final botRibbon = Path()
      ..moveTo(s.width + 20 * u, s.height)
      ..lineTo(s.width * 0.22, s.height)
      ..cubicTo(
        s.width * 0.52,
        s.height - 68 * u,
        s.width * 0.76,
        s.height - 44 * u,
        s.width + 20 * u,
        s.height - 165 * u,
      )
      ..close();
    c.drawPath(
      botRibbon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [p.accent, p.art.withValues(alpha: p.art.a * 0.55), p.accent.withValues(alpha: 0)],
        ).createShader(
          Rect.fromLTWH(s.width * 0.2, s.height - 175 * u, s.width * 0.8, 175 * u),
        ),
    );
    final glint = Paint()..color = p.art.withValues(alpha: (p.art.a * 0.95).clamp(0, 1));
    for (final (fx, fy, r) in const [
      (0.18, 0.10, 5.5),
      (0.84, 0.14, 4.2),
      (0.80, 0.86, 5.2),
      (0.24, 0.91, 3.8),
    ]) {
      _sparkle(c, Offset(s.width * fx, s.height * fy), r * u, glint);
    }
  }

  /// Narenciye: köşelerde güneşli portakal/limon dilimleri ve taze yapraklar.
  static void _citrus(Canvas c, Size s, NoteThemePalette p, double u) {
    void slice(Offset center, double r, double rot) {
      c
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(rot);
      c.drawCircle(Offset.zero, r, Paint()..color = p.art);
      c.drawCircle(
        Offset.zero,
        r * 0.86,
        Paint()..color = p.bottom.withValues(alpha: 0.75),
      );
      final wedge = Paint()..color = p.art.withValues(alpha: p.art.a * 0.8);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        c.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.76),
          a + 0.08,
          math.pi / 4 - 0.16,
          true,
          wedge,
        );
      }
      c.restore();
    }

    slice(Offset(26 * u, 28 * u), 56 * u, 0.3);
    slice(Offset(s.width - 18 * u, s.height - 24 * u), 62 * u, -0.4);
    slice(Offset(s.width - 52 * u, 30 * u), 30 * u, 0.8);
    final leafPaint = Paint()..color = p.accent;
    c.drawPath(_leafPath(Offset(70 * u, 26 * u), 0.45, 58 * u), leafPaint);
    c.drawPath(_leafPath(Offset(24 * u, 82 * u), 1.25, 48 * u), leafPaint);
    c.drawPath(
      _leafPath(Offset(s.width - 68 * u, s.height - 28 * u), 3.65, 56 * u),
      leafPaint,
    );
    c.drawPath(
      _leafPath(Offset(s.width - 24 * u, s.height - 84 * u), 4.35, 46 * u),
      leafPaint,
    );
  }

  /// Botanik: köşelerden uzanan ince okaliptüs dalları ve renkli küçük çiçekler.
  static void _botanical(Canvas c, Size s, NoteThemePalette p, double u) {
    final stem = Paint()
      ..color = p.art
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * u
      ..strokeCap = StrokeCap.round;
    final leaf = Paint()..color = p.art.withValues(alpha: p.art.a * 0.78);
    final bloom = Paint()..color = p.accent;

    void sprig(Offset start, Offset end, Offset ctrl) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      c.drawPath(path, stem);
      for (var i = 1; i <= 5; i++) {
        final t = i / 6;
        final pt = _quad(start, ctrl, end, t);
        final tan = _quadTangent(start, ctrl, end, t);
        final a = math.atan2(tan.dy, tan.dx);
        final len = (24 - i * 1.8) * u;
        c.drawPath(_leafPath(pt, a + 0.85, len), leaf);
        c.drawPath(_leafPath(pt, a - 0.85, len), leaf);
      }
      _blossom(c, end, 9.5 * u, bloom, Paint()..color = p.bottom);
    }

    sprig(
      Offset(-8 * u, 24 * u),
      Offset(108 * u, 74 * u),
      Offset(52 * u, 20 * u),
    );
    sprig(
      Offset(s.width + 8 * u, s.height - 28 * u),
      Offset(s.width - 114 * u, s.height - 82 * u),
      Offset(s.width - 54 * u, s.height - 22 * u),
    );
    sprig(
      Offset(s.width + 6 * u, 36 * u),
      Offset(s.width - 78 * u, 88 * u),
      Offset(s.width - 28 * u, 42 * u),
    );
  }

  /// Terrakota: modern organik kemerler ve yumuşak terrazzo taşları.
  static void _terracotta(Canvas c, Size s, NoteThemePalette p, double u) {
    c.drawCircle(
      Offset(-12 * u, 16 * u),
      84 * u,
      Paint()..color = p.art.withValues(alpha: p.art.a * 0.72),
    );
    c.drawCircle(
      Offset(56 * u, 56 * u),
      26 * u,
      Paint()..color = p.accent.withValues(alpha: p.accent.a * 0.65),
    );
    c.drawCircle(
      Offset(s.width + 14 * u, s.height - 12 * u),
      96 * u,
      Paint()..color = p.art.withValues(alpha: p.art.a * 0.68),
    );
    c.drawCircle(
      Offset(s.width - 62 * u, s.height - 54 * u),
      28 * u,
      Paint()..color = p.accent.withValues(alpha: p.accent.a * 0.65),
    );
    // Köşe organik dal çizgisi.
    final line = Paint()
      ..color = p.bottom.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(14 * u, 12 * u), Offset(42 * u, 52 * u), line);
    c.drawLine(Offset(26 * u, 28 * u), Offset(40 * u, 24 * u), line);
    c.drawLine(Offset(32 * u, 38 * u), Offset(22 * u, 44 * u), line);
    c.drawLine(
      Offset(s.width - 14 * u, s.height - 16 * u),
      Offset(s.width - 46 * u, s.height - 58 * u),
      line,
    );
  }

  /// Konfeti: üst ve alt kenarlara serpilmiş renkli halkalar, kapsüller ve noktalar.
  static void _confetti(Canvas c, Size s, NoteThemePalette p, double u) {
    final rnd = math.Random(42);
    final colors = [
      p.art,
      p.accent,
      Color.lerp(p.art, p.accent, 0.5)!,
      p.ink.withValues(alpha: 0.22),
    ];
    for (var i = 0; i < 24; i++) {
      final topBand = i.isEven;
      final x = (0.04 + rnd.nextDouble() * 0.92) * s.width;
      final y = topBand
          ? (8 + rnd.nextDouble() * 88) * u
          : s.height - (12 + rnd.nextDouble() * 96) * u;
      final color = colors[i % colors.length];
      final kind = i % 3;
      if (kind == 0) {
        c.drawCircle(Offset(x, y), (3.2 + rnd.nextDouble() * 3.5) * u, Paint()..color = color);
      } else if (kind == 1) {
        c.drawCircle(
          Offset(x, y),
          (4.5 + rnd.nextDouble() * 4.5) * u,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * u,
        );
      } else {
        c
          ..save()
          ..translate(x, y)
          ..rotate(rnd.nextDouble() * math.pi)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 14 * u, height: 4.5 * u),
              Radius.circular(2.5 * u),
            ),
            Paint()..color = color,
          )
          ..restore();
      }
    }
  }

  /// Kobalt: zarif geometrik ufuk yayları ve altın pusula parıltıları.
  static void _cobalt(Canvas c, Size s, NoteThemePalette p, double u) {
    final arc = Paint()
      ..color = p.art.withValues(alpha: p.art.a * 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * u;
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(s.width + 20 * u, -20 * u), (72 + i * 28) * u, arc);
      c.drawCircle(Offset(-24 * u, s.height + 24 * u), (78 + i * 28) * u, arc);
    }
    final fillWave = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, s.height - 54 * u)
      ..quadraticBezierTo(s.width * 0.35, s.height - 86 * u, s.width * 0.7, s.height - 46 * u)
      ..quadraticBezierTo(s.width * 0.88, s.height - 28 * u, s.width, s.height - 42 * u)
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(
      fillWave,
      Paint()..color = p.art.withValues(alpha: p.art.a * 0.38),
    );
    final star = Paint()..color = p.accent;
    _sparkle(c, Offset(s.width - 36 * u, 42 * u), 7.5 * u, star);
    _sparkle(c, Offset(s.width - 68 * u, 72 * u), 4.2 * u, star);
    _sparkle(c, Offset(36 * u, s.height - 44 * u), 6.0 * u, star);
  }
}

/// Temayı (zemin geçişi + süsleme) çizer.
class NoteThemePainter extends CustomPainter {
  const NoteThemePainter(this.theme, {required this.dark});

  final NoteTheme theme;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = theme.palette(dark);
    final rect = Offset.zero & size;
    canvas
      ..save()
      ..clipRect(rect)
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.top, p.bottom],
          ).createShader(rect),
      );
    final u = (size.shortestSide / 400).clamp(0.16, 1.4);
    theme._art(canvas, size, p, u);
    canvas.restore();
  }

  @override
  bool shouldRepaint(NoteThemePainter old) =>
      old.theme.id != theme.id || old.dark != dark;
}

/// Çocuğun ARKASINA notun temasını serer (tema yoksa arka katman boş).
/// Süsleme kendi katmanında: içerik kaydırılıp yazılırken yeniden çizilmez.
///
/// Ağaç yapısı tema olsa da olmasa da AYNI (çocuk hep ikinci sırada): tema
/// seçilip kaldırıldığında editörün kaydırma konumu, odağı ve alt ağacın
/// durumu korunur.
class NoteThemeBackdrop extends StatelessWidget {
  const NoteThemeBackdrop({super.key, required this.themeId, this.child});

  final String themeId;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = NoteThemes.byId(themeId);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: theme == null
              ? const SizedBox.shrink()
              : RepaintBoundary(
                  child: CustomPaint(
                    painter: NoteThemePainter(theme, dark: dark),
                  ),
                ),
        ),
        child ?? const SizedBox.shrink(),
      ],
    );
  }
}
