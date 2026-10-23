import 'package:flutter/material.dart';

/// Elle çizim yapılan her yerde (el yazısı ekranı, PDF/slayt/görsel üstü
/// çizim) ortak kalem renkleri.
const kInkPalette = <Color>[
  Colors.black,
  Colors.white, // Koyu PDF/slayt üzerine yazmak için (beyaz zeminde görünmez).
  Color(0xFFE53935),
  Color(0xFFFB8C00),
  Color(0xFF43A047),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
];

/// Kalem türleri. Tek bir "çizgi kalınlığı" ayarı yetmiyordu: kullanıcı hem
/// ince not almak hem de yazının üstünü fosforluyla boyamak istiyor, ikisi
/// yalnız kalınlıkla ayrışmıyor (fosforlu SAYDAM olmalı, altındaki yazı
/// okunmalı).
///
/// Tür ayrı bir alan olarak SAKLANMAZ; renge işlenen saydamlıktan
/// (alfa kanalından) okunur. Sebep: [InkStroke] Firestore'a ARGB tamsayısı
/// olarak yazılıyor; yeni alan eklemek eski notların şemasını değiştirirdi.
/// Saydamlık zaten ARGB'nin içinde ve eski kayıtlar (alfa 255) tükenmez
/// kalem olarak doğru çizilir.
enum InkPen {
  /// Tükenmez: ince, tam opak, yuvarlak uç.
  pen(defaultWidth: 3, minWidth: 1, maxWidth: 12, alpha: 0xFF),

  /// Keçeli: kalın ve opak.
  marker(defaultWidth: 9, minWidth: 4, maxWidth: 24, alpha: 0xFF),

  /// Fosforlu: çok kalın ve yarı saydam; uç düz (kare) olduğu için satır
  /// başı/sonu gerçek bir fosforlu kalem gibi keskin biter.
  highlighter(defaultWidth: 22, minWidth: 10, maxWidth: 46, alpha: 0x66);

  const InkPen({
    required this.defaultWidth,
    required this.minWidth,
    required this.maxWidth,
    required this.alpha,
  });

  /// Tür seçilince kalınlık kaydırıcısının gittiği değer.
  final double defaultWidth;

  /// Kalınlık kaydırıcısının bu tür için sınırları.
  final double minWidth;
  final double maxWidth;

  /// Rengin saydamlığı (0–255). Türü geri okumaya da bu yarar.
  final int alpha;

  /// Kullanıcının seçtiği [base] rengi bu kalemin saydamlığıyla döndürür.
  Color apply(Color base) => base.withAlpha(alpha);

  /// [width] değerini bu kalemin aralığına sıkıştırır (tür değişince
  /// kaydırıcının eski değeri aralık dışında kalabilir).
  double clampWidth(double width) => width.clamp(minWidth, maxWidth);
}

/// Bir çizgiyi (renk + kalınlık) çizen boya. Fosforlu düz uçla çizilir:
/// yuvarlak uç saydam çizgide uç uca binince koyu lekeler bırakıyordu.
///
/// Fosforlu SAYDAMLIĞIYLA tanınır (tam 0x66): 2026-10-23'ten beri tükenmez ve
/// keçeli de şeffaf olabiliyor (kalem ayarları), onlar yuvarlak uçlu kalır.
Paint inkPaint(Color color, double strokeWidth) {
  final highlighter = (color.a * 255).round() == InkPen.highlighter.alpha;
  return Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..strokeCap = highlighter ? StrokeCap.butt : StrokeCap.round
    ..strokeJoin = highlighter ? StrokeJoin.bevel : StrokeJoin.round
    ..style = PaintingStyle.stroke;
}
