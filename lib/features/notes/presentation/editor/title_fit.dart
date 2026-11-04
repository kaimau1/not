import 'package:flutter/widgets.dart';

/// **BAŞLIK ALANA SIĞAR** (kullanıcı isteği 2026-11-01: "aksi yapılamadıkça
/// başlıklar yazı alanına sığsın, otomatik boyutlandırma ile — şu an uzun
/// başlıklar taşıyor").
///
/// Tek satırlık başlık [maxWidth]'e sığmıyorsa yazı boyu [baseSize]'dan
/// küçültülür; [minSize]'ın altına inmez — orada da sığmıyorsa alan eskisi
/// gibi yatay kayar ("aksi yapılamadıkça"). Genişlik yazı boyuyla neredeyse
/// doğrusal büyüdüğü için oran tahmini yapılıp en çok üç ölçümle düzeltilir
/// (satır içi boyut işaretleri doğrusallığı bozabilir).
///
/// [spanFor], verilen yazı boyunda alanın ÇİZECEĞİ metni döner (biçim
/// işaretleri gizli, kalın/italik dahil) — ölçüm gerçek çizimle aynı olsun.
/// `TextField`ın metne GERÇEKTEN verdiği stil: Material 3'te alan kendi
/// stilini temanın `bodyLarge`ının üstüne birleştirir (`TextField` →
/// `_m3InputStyle`). Ölçüm bununla yapılmazsa başlığın vermediği her özellik
/// (harf aralığı 0,5, yazı özellikleri) ölçüme girmez, çizime girer.
TextStyle fieldMergedStyle(TextStyle? fieldDefault, TextStyle style) =>
    (fieldDefault ?? const TextStyle()).merge(style);

double fitTitleFontSize({
  required InlineSpan Function(double fontSize) spanFor,
  required double maxWidth,
  required double baseSize,
  double minSize = 14,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
}) {
  if (!maxWidth.isFinite || maxWidth <= 0) return baseSize;
  final floor = minSize < baseSize ? minSize : baseSize;
  double widthAt(double size) {
    final painter = TextPainter(
      text: spanFor(size),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  var size = baseSize;
  var width = widthAt(size);
  if (width <= maxWidth) return baseSize;
  for (var i = 0; i < 3 && width > maxWidth; i++) {
    // %2 pay: yuvarlama ve imleç yeri yazıyı kenara yapıştırmasın.
    size = (size * maxWidth / width * 0.98).clamp(floor, baseSize);
    if (size <= floor) return floor;
    width = widthAt(size);
  }
  return size;
}
