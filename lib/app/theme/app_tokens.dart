import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/a11y/motion.dart';
import 'app_palette.dart';

/// Ana ekran ızgarası (TEMA_PLANI F31.5): kenar payı 13, kartlar arası 10.
const double kGridInset = 13;
const double kGridGap = 10;

/// **HAREKET BELİRTEÇLERİ** (TEMA_PLANI F34.1). Süre + eğri tek yerde; en sık
/// sabit süreler bağlı, gerisine dokunulmadı (toplu değişiklik yok).
abstract final class AppMotion {
  /// Kart basma, düğme, kutucuk.
  static const instant = Duration(milliseconds: 100);

  /// Not rengi, çip, simge, seçim halkası.
  static const short = Duration(milliseconds: 200);

  /// Levha, menü, süzgeç/segment.
  static const medium = Duration(milliseconds: 300);

  /// "Hareketi azalt" açıkken üst sınır (F34.7).
  static const reduced = Duration(milliseconds: 150);

  static const Curve standard = Easing.standard;
  static const Curve enter = Easing.emphasizedDecelerate;
  static const Curve exit = Easing.emphasizedAccelerate;

  /// [duration], hareket azaltılmışsa en çok [reduced].
  static Duration of(BuildContext context, Duration duration) =>
      motionOf(context) || duration <= reduced ? duration : reduced;

  /// [curve], hareket azaltılmışsa doğrusal solma.
  static Curve curveOf(BuildContext context, Curve curve) =>
      motionOf(context) ? curve : Curves.linear;
}

/// Temanın `ColorScheme`'de karşılığı olmayan belirteçleri (TEMA_PLANI F29.1):
/// kart rengi, kart çizgisi, kart gölgesi, köşe. `Theme.of` üstünden okunur —
/// kart başına yeni sağlayıcı/abonelik YOK (HAFIZA: kart tek abonelik).
///
/// Uzantısı olmayan bir `ThemeData` (testlerde düz `MaterialApp`) için
/// [of] şemadan makul bir karşılık türetir; çağıran hiç null görmez.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.family,
    required this.font,
    required this.card,
    required this.hairline,
    required this.cardShadow,
    required this.cardRadius,
  });

  /// Bu temanın ailesi ve yazı tipi: zıt parlaklıktaki aynı temayı
  /// kurabilmek için (bkz. `AppTheme.opposite` — okunurluk düzeltmesi).
  final ThemeFamily family;
  final String? font;

  /// Renksiz notun kartı / sayfası (kâğıt): zeminden AÇIK.
  final Color card;

  /// Renksiz kartın kenar çizgisi (mürekkep %8).
  final Color hairline;

  /// Kartın gölgesi. VARSAYILAN BULANIKSIZ (K4): 1 dp alt kenar — bulanık
  /// gölge her karede yeniden taranır ve Adreno ≤ 650'de (GLES, AKICILIK K7)
  /// kaydırmada raster bütçesini zorlar. Yumuşak gölge telefonda ölçüldükten
  /// sonra açılacak (KALANLAR §2).
  final List<BoxShadow> cardShadow;

  /// Kart köşesi (eski 12 → 16).
  final double cardRadius;

  static AppTokens of(BuildContext context) => fromTheme(Theme.of(context));

  static AppTokens fromTheme(ThemeData theme) {
    final own = theme.extension<AppTokens>();
    if (own != null) return own;
    final s = theme.colorScheme;
    return AppTokens(
      family: ThemeFamily.sage,
      font: null,
      card: s.surfaceContainerLow,
      hairline: s.outlineVariant.withValues(alpha: 0.5),
      cardShadow: const [],
      cardRadius: 16,
    );
  }

  @override
  AppTokens copyWith({
    ThemeFamily? family,
    String? font,
    Color? card,
    Color? hairline,
    List<BoxShadow>? cardShadow,
    double? cardRadius,
  }) => AppTokens(
    family: family ?? this.family,
    font: font ?? this.font,
    card: card ?? this.card,
    hairline: hairline ?? this.hairline,
    cardShadow: cardShadow ?? this.cardShadow,
    cardRadius: cardRadius ?? this.cardRadius,
  );

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      family: t < 0.5 ? family : other.family,
      font: t < 0.5 ? font : other.font,
      card: Color.lerp(card, other.card, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? [],
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
    );
  }
}
