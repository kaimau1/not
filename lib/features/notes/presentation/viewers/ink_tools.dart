import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset, Rect;
import 'package:shared_preferences/shared_preferences.dart';

/// Çizim aracının ŞEKİL kipleri. Ok ([InkController.arrow]) ayrı kalır —
/// başlığı olan, kayda `a` bayrağıyla yazılan tek şekil o.
///
/// Şekiller kayda SIRADAN çizgi olarak (nokta listesi) yazılır: şema
/// büyümez, eski istemci de aynen çizer, silgi/kırp/döndür değişmeden
/// çalışır. Elle düz çizgi, kare, daire çizmek hep eğri çıkıyordu.
enum InkShape {
  /// Düz çizgi: bastığın yerden kaldırdığın yere.
  line,

  /// Dikdörtgen: köşeden köşeye.
  rectangle,

  /// Elips (daire): çevreleyen kutudan.
  ellipse,
}

/// Şeklin nokta listesi ([x1, y1, x2, y2, ...], oranlı) — [a] başlangıç,
/// [b] parmağın/kalemin şu anki yeri.
List<double> inkShapePoints(
  InkShape shape,
  double ax,
  double ay,
  double bx,
  double by,
) {
  switch (shape) {
    case InkShape.line:
      return [ax, ay, bx, by];
    case InkShape.rectangle:
      return [ax, ay, bx, ay, bx, by, ax, by, ax, ay];
    case InkShape.ellipse:
      const steps = 48;
      final cx = (ax + bx) / 2;
      final cy = (ay + by) / 2;
      final rx = (bx - ax).abs() / 2;
      final ry = (by - ay).abs() / 2;
      return [
        for (var i = 0; i <= steps; i++) ...[
          cx + rx * math.cos(2 * math.pi * i / steps),
          cy + ry * math.sin(2 * math.pi * i / steps),
        ],
      ];
  }
}

/// **BASILI TUTUNCA ŞEKLE DÖNÜŞTÜR** (kullanıcı isteği 2026-10-30: "kalem
/// modu üzerine çalış, Samsung Notes gibi özelliklerimiz olsun"). Elle
/// çizilen çizginin sonunda kalem/parmak kısa süre kıpırdamadan tutulursa
/// çizgi tanınan şekle oturur: düz çizgi, dikdörtgen ya da elips.
///
/// [points] EKRAN (piksel) uzayında olmalı — oranlı uzayda sayfanın eni ve
/// boyu ayrı ölçeklendiği için daire elips, kare dikdörtgen görünürdü.
/// Tanınmazsa null.
({InkShape shape, Offset a, Offset b})? recognizeInkShape(
  List<Offset> points,
) {
  if (points.length < 6) return null;
  var length = 0.0;
  var left = double.infinity, top = double.infinity;
  var right = -double.infinity, bottom = -double.infinity;
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    if (i > 0) length += (p - points[i - 1]).distance;
    left = math.min(left, p.dx);
    top = math.min(top, p.dy);
    right = math.max(right, p.dx);
    bottom = math.max(bottom, p.dy);
  }
  if (length < 24) return null;
  final first = points.first;
  final last = points.last;
  final chord = (last - first).distance;

  // DÜZ ÇİZGİ: her nokta iki uçtan geçen doğruya yakın.
  if (chord >= 20 && chord >= length * 0.85) {
    final dir = (last - first) / chord;
    var deviation = 0.0;
    for (final p in points) {
      final d = p - first;
      deviation = math.max(deviation, (d.dx * dir.dy - d.dy * dir.dx).abs());
    }
    if (deviation <= math.max(6.0, chord * 0.06)) {
      return (shape: InkShape.line, a: first, b: last);
    }
    return null;
  }

  // KAPALI şekiller: uçlar birbirine yakın olmalı.
  final box = Rect.fromLTRB(left, top, right, bottom);
  if (box.width < 16 || box.height < 16) return null;
  if (chord > length * 0.22) return null;
  final cx = box.center.dx, cy = box.center.dy;
  final rx = box.width / 2, ry = box.height / 2;
  var ellipseError = 0.0;
  var rectError = 0.0;
  final shortSide = math.min(box.width, box.height);
  for (final p in points) {
    final nx = (p.dx - cx) / rx;
    final ny = (p.dy - cy) / ry;
    ellipseError += (math.sqrt(nx * nx + ny * ny) - 1).abs();
    final edge = math.min(
      math.min(p.dx - left, right - p.dx),
      math.min(p.dy - top, bottom - p.dy),
    );
    rectError += edge.abs() / shortSide;
  }
  ellipseError /= points.length;
  rectError /= points.length;
  // Daire köşegenlerde kutunun kenarından uzaklaşır (dikdörtgen hatası
  // büyür); kare köşelerinde elipsin dışına taşar (elips hatası büyür).
  if (ellipseError < 0.09 && ellipseError <= rectError * 1.6) {
    return (shape: InkShape.ellipse, a: box.topLeft, b: box.bottomRight);
  }
  if (rectError < 0.06) {
    return (shape: InkShape.rectangle, a: box.topLeft, b: box.bottomRight);
  }
  return null;
}

/// Nokta çokgenin içinde mi? Kement (seçim çemberi) çokgeni için çift-tek
/// kuralı; [polygon] düzleştirilmiş [x1, y1, x2, y2, ...].
bool inkPointInPolygon(double x, double y, List<double> polygon) {
  var inside = false;
  final n = polygon.length ~/ 2;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final xi = polygon[2 * i], yi = polygon[2 * i + 1];
    final xj = polygon[2 * j], yj = polygon[2 * j + 1];
    if ((yi > y) != (yj > y) &&
        x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

/// **KALEM TERCİHLERİNİN HAFIZASI** (kullanıcı isteği 2026-10-23: "pratiklik
/// şart"): son seçilen kalem türü, renk, kalınlık, şeffaflık, "yalnız kalemle
/// yaz" ve son kullanılan renkler. Her çizim ekranı (el yazısı, PDF, slayt,
/// görsel) yeni [InkController] kurduğundan seçim her açılışta siyah
/// tükenmeze dönüyordu; artık kaldığı yerden başlar. Cihaz tercihi
/// (hesaba/senkrona yazılmaz — kalem cihaza özgü).
class InkToolMemory {
  InkToolMemory._();

  static SharedPreferences? _prefs;

  static const _kPenOnly = 'ink_pen_only';
  static const _kPenOnlyChosen = 'ink_pen_only_chosen';
  static const _kPressure = 'ink_pressure';
  static const _kColor = 'ink_color';
  static const _kPen = 'ink_pen';
  static const _kWidth = 'ink_width';
  static const _kOpacity = 'ink_opacity';
  static const _kRecent = 'ink_recent_colors';
  static const _kShapeSnap = 'ink_shape_snap';
  static const _kPartialEraser = 'ink_partial_eraser';
  static const _kAutoStylus = 'ink_auto_stylus';

  /// Basılı tutunca şekle dönüştür ([recognizeInkShape]).
  static bool shapeSnap = true;

  /// Silgi çizginin YALNIZ değdiği kısmını siler (kapalıyken bütün çizgi).
  static bool partialEraser = false;

  /// **KALEMİ OTOMATİK ALGILA**: kalem (S Pen vb.) nota değince yazma kipi
  /// kendiliğinden açılır — PDF/slaytta kalem kipi, metin notunda el yazısı.
  static bool autoStylus = true;

  /// "Yalnız kalemle yaz": parmak çizmez; kaydırır ve yakınlaştırır.
  static bool penOnly = false;

  /// Kullanıcı "yalnız kalem"i ELLE açtı/kapattı mı. Seçmediyse ilk kalem
  /// dokunuşunda kendiliğinden açılır (Samsung Notes'taki gibi).
  static bool penOnlyChosen = false;

  /// Basınç algısı (kalem) açık mı.
  static bool pressure = true;

  static int? color;
  static int? pen;
  static double? width;
  static double opacity = 1;

  /// Son kullanılan özel renkler (en yeni başta, en çok [_recentMax]).
  static List<int> recentColors = [];
  static const _recentMax = 6;

  /// Uygulama açılışında (main) bir kez.
  static void attach(SharedPreferences prefs) {
    _prefs = prefs;
    penOnly = prefs.getBool(_kPenOnly) ?? false;
    penOnlyChosen = prefs.getBool(_kPenOnlyChosen) ?? false;
    pressure = prefs.getBool(_kPressure) ?? true;
    color = prefs.getInt(_kColor);
    pen = prefs.getInt(_kPen);
    width = prefs.getDouble(_kWidth);
    opacity = (prefs.getDouble(_kOpacity) ?? 1).clamp(0.1, 1.0).toDouble();
    shapeSnap = prefs.getBool(_kShapeSnap) ?? true;
    partialEraser = prefs.getBool(_kPartialEraser) ?? false;
    autoStylus = prefs.getBool(_kAutoStylus) ?? true;
    recentColors = [
      for (final s in prefs.getStringList(_kRecent) ?? const <String>[])
        ?int.tryParse(s),
    ];
  }

  static void savePenOnly(bool value, {required bool chosen}) {
    penOnly = value;
    if (chosen) penOnlyChosen = true;
    _prefs?.setBool(_kPenOnly, value);
    if (chosen) _prefs?.setBool(_kPenOnlyChosen, true);
  }

  static void saveShapeSnap(bool value) {
    shapeSnap = value;
    _prefs?.setBool(_kShapeSnap, value);
  }

  static void savePartialEraser(bool value) {
    partialEraser = value;
    _prefs?.setBool(_kPartialEraser, value);
  }

  static void saveAutoStylus(bool value) {
    autoStylus = value;
    _prefs?.setBool(_kAutoStylus, value);
  }

  static void savePressure(bool value) {
    pressure = value;
    _prefs?.setBool(_kPressure, value);
  }

  static void saveTool({
    required int color,
    required int pen,
    required double width,
    required double opacity,
  }) {
    InkToolMemory.color = color;
    InkToolMemory.pen = pen;
    InkToolMemory.width = width;
    InkToolMemory.opacity = opacity;
    _prefs
      ?..setInt(_kColor, color)
      ..setInt(_kPen, pen)
      ..setDouble(_kWidth, width)
      ..setDouble(_kOpacity, opacity);
  }

  /// Paletin dışından seçilen rengi "son kullanılanlar"ın başına koyar.
  static void rememberColor(int argb) {
    recentColors = [argb, ...recentColors.where((c) => c != argb)];
    if (recentColors.length > _recentMax) {
      recentColors = recentColors.sublist(0, _recentMax);
    }
    _prefs?.setStringList(_kRecent, [for (final c in recentColors) '$c']);
  }

  /// Testler için: hafızayı varsayılana döndürür.
  @visibleForTesting
  static void reset() {
    _prefs = null;
    penOnly = false;
    penOnlyChosen = false;
    pressure = true;
    color = null;
    pen = null;
    width = null;
    opacity = 1;
    recentColors = [];
    shapeSnap = true;
    partialEraser = false;
    autoStylus = true;
  }
}
