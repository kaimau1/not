import 'package:flutter/material.dart';

import '../../../../core/utils/note_fonts.dart';
import '../../domain/note.dart';

/// **NOT BAŞLIĞI TEK STİL** (K9, F37.1): editör, kart ve satır aynı aile, ağırlık
/// (w500: kalın w800 başlıkta ayırt edilsin, bkz. `markStyle`) ve harf aralığı;
/// yalnız boy yere göre. Aralık alanın gerçekte çizdiği ([fieldMergedStyle]),
/// `Text` `bodyLarge`ı miras almadığı için burada somutlaşır.
TextStyle noteTitleStyle(
  ThemeData theme,
  Note note, {
  required double fontSize,
}) {
  final headline = theme.textTheme.headlineSmall ?? const TextStyle();
  final ink = theme.colorScheme.onSurface;
  return applyNoteOpacity(
    applyNoteFont(
      headline.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: fontSize,
        // TUZAK: zıt okunurluk teması `Theme.of`tan geçmemiş ham temadır, M3
        // ölçüleri (aralık, satır yüksekliği) onda null; değerler sabit yedekli.
        letterSpacing:
            fieldMergedStyle(
              theme.textTheme.bodyLarge,
              headline,
            ).letterSpacing ??
            0.5,
        height: headline.height ?? 1.33,
        color: headline.color ?? ink,
      ),
      note.titleFontFamily,
    ),
    note.titleTextOpacity,
    ink,
  );
}

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
