import 'package:flutter/painting.dart';

/// WCAG 2.1 kontrast oranı (1–21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

final Map<(int, int, double), Color> _readableCache = {};

/// [color]'ı [background] üstünde en az [min] kontrasta getirir: tonu ve
/// doygunluğu korur, yalnız açıklığı değiştirir (açık zeminde koyulaştırır,
/// koyu zeminde açar). Zaten okunuyorsa [color] aynen döner.
///
/// Kullanım: satır içi renkli yazı (sarı, yeşil…) ve özel renkli notun koyu
/// tonu. Not rengi değişince renkli yazı sabit kalıp okunmaz oluyordu
/// (kullanıcı bulgusu 2026-11-04).
Color readableOn(Color color, Color background, {double min = 4.5}) {
  final key = (color.toARGB32(), background.toARGB32(), min);
  final hit = _readableCache[key];
  if (hit != null) return hit;
  if (_readableCache.length > 512) _readableCache.clear();
  var result = color;
  if (contrastRatio(color, background) < min) {
    final darken = background.computeLuminance() > 0.18;
    var hsl = HSLColor.fromColor(color);
    for (var i = 0; i < 25 && contrastRatio(result, background) < min; i++) {
      final l = (hsl.lightness + (darken ? -0.04 : 0.04)).clamp(0.0, 1.0);
      hsl = hsl.withLightness(l);
      result = hsl.toColor().withValues(alpha: color.a);
    }
  }
  return _readableCache[key] = result;
}
