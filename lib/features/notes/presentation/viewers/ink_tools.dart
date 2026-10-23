import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
  }
}
