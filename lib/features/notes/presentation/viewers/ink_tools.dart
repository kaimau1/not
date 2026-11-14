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

  /// Üçgen: kutunun tabanı ve üst ortası (2026-11-08).
  triangle,

  /// Tablo: kutuya 3×3 ızgara (kullanıcı isteği 2026-11-08: "tablo
  /// eklemede olsun"). Tek çizgi: iç çizgilere kenar üstünden geçilir.
  table,
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
    case InkShape.triangle:
      final mx = (ax + bx) / 2;
      return [mx, ay, bx, by, ax, by, mx, ay];
    case InkShape.table:
      final l = math.min(ax, bx), r = math.max(ax, bx);
      final t = math.min(ay, by), b = math.max(ay, by);
      final y1 = t + (b - t) / 3, y2 = t + 2 * (b - t) / 3;
      final x1 = l + (r - l) / 3, x2 = l + 2 * (r - l) / 3;
      return [
        l, t, r, t, r, b, l, b, l, t, // dış kenar
        l, y1, r, y1, r, y2, l, y2, // iki yatay (kenardan geçerek)
        l, b, x1, b, x1, t, x2, t, x2, b, // iki dikey
      ];
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
({InkShape shape, Offset a, Offset b})? recognizeInkShape(List<Offset> points) {
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
  // Elle çizilen kare/çember çoğu zaman tam kapanmaz ya da başlangıcı aşar
  // (kullanıcı bildirimi 2026-11-08: "kare çember algılanmıyor") — eşikler
  // gevşetildi: açıklık çevrenin %30'u, elips %14, dikdörtgen %9 sapma.
  if (chord > length * 0.3) return null;
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
  if (ellipseError < 0.14 && ellipseError <= rectError * 1.6) {
    return (shape: InkShape.ellipse, a: box.topLeft, b: box.bottomRight);
  }
  if (rectError < 0.09) {
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
    if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

/// Parmak dokunuşunun işi (K34): kaydırır (= "yalnız kalem"), kalemin
/// aracıyla çizer ya da siler.
enum FingerTool { scroll, draw, erase }

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
  static const _kFingerEraser = 'ink_finger_eraser';
  static const _kToggleBlinked = 'ink_pen_toggle_blinked';

  /// Yüzen kalem düğmesi ilk görünüşünde yanıp söndü mü (bir kez,
  /// kullanıcı isteği 2026-11-13).
  static bool toggleBlinked = false;

  static void markToggleBlinked() {
    toggleBlinked = true;
    _prefs?.setBool(_kToggleBlinked, true);
  }
  static const _kPressure = 'ink_pressure';
  static const _kColor = 'ink_color';
  static const _kPen = 'ink_pen';
  static const _kWidth = 'ink_width';
  static const _kOpacity = 'ink_opacity';
  static const _kRecent = 'ink_recent_colors';
  static const _kShapeSnap = 'ink_shape_snap';
  static const _kPartialEraser = 'ink_partial_eraser';
  static const _kAutoStylus = 'ink_auto_stylus';
  static const _kStylusEver = 'ink_stylus_ever';
  static const _kPenToggleAt = 'ink_pen_toggle_at';
  static const _kShapeSuggest = 'ink_shape_suggest';
  static const _kMarkFix = 'ink_mark_fix';
  static const _kPresets = 'ink_presets';

  /// Basılı tutunca şekle dönüştür ([recognizeInkShape]).
  static bool shapeSnap = true;

  /// Çizgi bitince tanınan şekil için sağ altta düzeltme işaretçisi
  /// (`ink_recognize.dart`).
  static bool shapeSuggest = true;

  /// Tik/çarpı düzeltmesi: null = hiç sorulmadı (ilk algılamada sorulur),
  /// varsayılan KAPALI (kullanıcı isteği 2026-11-08).
  static bool? markFix;

  /// Kapsüle SABİTLENEN kalemler (kullanıcı isteği 2026-11-08): tür + renk +
  /// kalınlık, en çok [maxPresets]. Cihaz tercihi.
  static List<InkPreset> presets = [];
  static const maxPresets = 5;

  /// Silgi çizginin YALNIZ değdiği kısmını siler (kapalıyken bütün çizgi).
  static bool partialEraser = false;

  /// **KALEMİ OTOMATİK ALGILA**: kalem (S Pen vb.) nota değince yazma kipi
  /// kendiliğinden açılır — PDF/slaytta kalem kipi, metin notunda el yazısı.
  static bool autoStylus = true;

  /// [autoStylus]'un dinlenebilir kopyası: yüzen "kalem yazar / dokunur"
  /// düğmesi (2026-11-09) değiştirince açık editör ve sabit bölme uyar.
  static final autoStylusListenable = ValueNotifier<bool>(true);

  /// Yüzen kalem düğmesinin yeri (ekranın oranı, 0–1); null = varsayılan.
  static Offset? penToggleAt;

  /// Bu cihazda hiç kalem görüldü mü (yüzen düğme ancak o zaman çıkar).
  static bool stylusEver = false;

  /// "Yalnız kalemle yaz": parmak çizmez; kaydırır ve yakınlaştırır.
  static bool penOnly = false;

  /// Kullanıcı "yalnız kalem"i ELLE açtı/kapattı mı. Seçmediyse ilk kalem
  /// dokunuşunda kendiliğinden açılır (Samsung Notes'taki gibi).
  static bool penOnlyChosen = false;

  /// Parmak SİLER (K34, F63.6): `penOnly` kapalıyken parmak dokunuşu geçici
  /// silgidir (kalemin yan düğmesi yolu). Ayrı anahtar — eski `ink_pen_only`
  /// kaydı aynen okunur (yeni anahtar yoksa Kaydırır/Çizer).
  static bool fingerErases = false;

  /// Parmağın işi: [penOnly] + [fingerErases]'ten TÜRETİLİR (ayrı kayıt yok).
  static FingerTool get fingerTool => penOnly
      ? FingerTool.scroll
      : (fingerErases ? FingerTool.erase : FingerTool.draw);

  /// Basınç algısı (kalem) açık mı.
  static bool pressure = true;

  static int? color;
  static int? pen;
  static double? width;
  static double opacity = 1;

  // ── TEK ARAÇ DURUMU (OTURTMA F63.2, KALEM K4) ─────────────────────────
  // Araç (kalem türü, renk, kalınlık, silgi, ok/şekil, kement) BURADA durur;
  // `InkController` kopya tutmaz, her okuyuşta buraya bakar. Eskiden her
  // denetleyici kurulumda kopyalıyordu: tepside seçilen silgiyi/rengi sabit
  // ve gömülü ekin denetleyicisi hiç görmüyordu ("silgi seçili, kalem
  // yazıyor" — F60.S4).

  /// Geçici araçlar (kayda yazılmaz; yeni oturum kalemle başlar).
  static bool eraser = false;
  static bool arrow = false;
  static InkShape? shape;
  static bool lasso = false;

  /// Araç ya da etkin yüzey değişince artar: bütün açık denetleyiciler
  /// dinler (araç çubukları, imleç önizlemesi yenilensin).
  static final toolRev = ValueNotifier<int>(0);

  static void toolChanged() => toolRev.value++;

  static int _sessions = 0;

  /// Bir denetleyici açıldı. Açık başka denetleyici yoksa (yeni not, yeni
  /// çizim ekranı) geçici araç sıfırlanır: görünmeyen bir silgiyle
  /// başlanmaz. Not içindeki yüzeyler (sayfa, sabit, gömülü, paket, tam
  /// ekran) aynı oturumdur.
  static void openSession() {
    if (_sessions++ > 0) return;
    eraser = false;
    arrow = false;
    shape = null;
    lasso = false;
  }

  static void closeSession() {
    if (_sessions > 0) _sessions--;
  }

  /// Son kullanılan özel renkler (en yeni başta, en çok [_recentMax]).
  static List<int> recentColors = [];
  static const _recentMax = 6;

  /// Uygulama açılışında (main) bir kez.
  static void attach(SharedPreferences prefs) {
    _prefs = prefs;
    penOnly = prefs.getBool(_kPenOnly) ?? false;
    penOnlyChosen = prefs.getBool(_kPenOnlyChosen) ?? false;
    fingerErases = prefs.getBool(_kFingerEraser) ?? false;
    toggleBlinked = prefs.getBool(_kToggleBlinked) ?? false;
    pressure = prefs.getBool(_kPressure) ?? true;
    color = prefs.getInt(_kColor);
    pen = prefs.getInt(_kPen);
    width = prefs.getDouble(_kWidth);
    opacity = (prefs.getDouble(_kOpacity) ?? 1).clamp(0.1, 1.0).toDouble();
    shapeSnap = prefs.getBool(_kShapeSnap) ?? true;
    partialEraser = prefs.getBool(_kPartialEraser) ?? false;
    autoStylus = prefs.getBool(_kAutoStylus) ?? true;
    autoStylusListenable.value = autoStylus;
    stylusEver = prefs.getBool(_kStylusEver) ?? false;
    final at = prefs.getStringList(_kPenToggleAt);
    penToggleAt = at != null && at.length == 2
        ? Offset(double.tryParse(at[0]) ?? 1, double.tryParse(at[1]) ?? 0.5)
        : null;
    shapeSuggest = prefs.getBool(_kShapeSuggest) ?? true;
    markFix = prefs.getBool(_kMarkFix);
    presets = [
      for (final s in prefs.getStringList(_kPresets) ?? const <String>[])
        ?InkPreset.decode(s),
    ];
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

  /// Parmak aracını kullanıcı seçti (her zaman `chosen` — ilk kalem
  /// dokunuşundaki kendiliğinden "yalnız kalem" bunu ezmez).
  static void saveFingerTool(FingerTool tool) {
    fingerErases = tool == FingerTool.erase;
    _prefs?.setBool(_kFingerEraser, fingerErases);
    savePenOnly(tool == FingerTool.scroll, chosen: true);
  }

  static void saveShapeSnap(bool value) {
    shapeSnap = value;
    _prefs?.setBool(_kShapeSnap, value);
  }

  static void savePartialEraser(bool value) {
    partialEraser = value;
    _prefs?.setBool(_kPartialEraser, value);
  }

  static void saveShapeSuggest(bool value) {
    shapeSuggest = value;
    _prefs?.setBool(_kShapeSuggest, value);
  }

  static void saveMarkFix(bool value) {
    markFix = value;
    _prefs?.setBool(_kMarkFix, value);
  }

  static void savePresets(List<InkPreset> value) {
    presets = value.take(maxPresets).toList();
    _prefs?.setStringList(_kPresets, [for (final p in presets) p.encode()]);
  }

  static void saveAutoStylus(bool value) {
    autoStylus = value;
    autoStylusListenable.value = value;
    _prefs?.setBool(_kAutoStylus, value);
  }

  static void notePenToggleAt(Offset at) {
    penToggleAt = at;
    _prefs?.setStringList(_kPenToggleAt, ['${at.dx}', '${at.dy}']);
  }

  static void noteStylusEver() {
    if (stylusEver) return;
    stylusEver = true;
    _prefs?.setBool(_kStylusEver, true);
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

  /// **SÜREKLİ ÇIKMASIN** (P49 (d), kullanıcı 2026-11-12): bu OTURUMDA
  /// yazıyla söylenmiş kalem durumları. Yüzen düğmenin "kalem yazar /
  /// dokunur" yazısı her durum için bir kez ([stylusHintsTold]); editörün
  /// "yalnız kalem açık/kapalı" ipucu yalnız durum değişince
  /// ([lastPenOnlyHint]). Kalıcı değil (uygulama açılışında sıfır).
  static final Set<bool> stylusHintsTold = {};
  static bool? lastPenOnlyHint;

  /// Testler için: hafızayı varsayılana döndürür.
  @visibleForTesting
  static void reset() {
    stylusHintsTold.clear();
    lastPenOnlyHint = null;
    _prefs = null;
    eraser = false;
    arrow = false;
    shape = null;
    lasso = false;
    _sessions = 0;
    penOnly = false;
    penOnlyChosen = false;
    fingerErases = false;
    // Testte yanıp sönme yok (kare zamanlayıcısı açık kalmasın).
    toggleBlinked = true;
    pressure = true;
    color = null;
    pen = null;
    width = null;
    opacity = 1;
    recentColors = [];
    shapeSnap = true;
    partialEraser = false;
    autoStylus = true;
    autoStylusListenable.value = true;
    stylusEver = false;
    penToggleAt = null;
    shapeSuggest = true;
    markFix = null;
    presets = [];
  }
}

/// Sabitlenmiş kalem: tür ([InkPen] sırası), renk (ARGB, saydamlıksız
/// seçilen renk) ve kalınlık (px). Kayıt biçimi `tür|renk|kalınlık`.
class InkPreset {
  const InkPreset({
    required this.pen,
    required this.color,
    required this.width,
  });

  final int pen;
  final int color;
  final double width;

  String encode() => '$pen|$color|${width.toStringAsFixed(1)}';

  static InkPreset? decode(String s) {
    final parts = s.split('|');
    if (parts.length != 3) return null;
    final pen = int.tryParse(parts[0]);
    final color = int.tryParse(parts[1]);
    final width = double.tryParse(parts[2]);
    if (pen == null || color == null || width == null || pen < 0) return null;
    return InkPreset(pen: pen, color: color, width: width);
  }

  @override
  bool operator ==(Object other) =>
      other is InkPreset &&
      other.pen == pen &&
      other.color == color &&
      (other.width - width).abs() < 0.05;

  @override
  int get hashCode => Object.hash(pen, color, width.round());
}
