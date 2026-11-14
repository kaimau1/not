import 'package:flutter/material.dart';

import 'app_tokens.dart';

// **ORTAK TASARIM DİLİ — P62 ekleri** (docs/plan_tasarim_A.md §1). Ton, yüzey
// ve yana kaydırma belirteçleri; `app_tokens.dart`taki AppMotion / AppRadius /
// AppSpace / AppText ile birlikte kullanılır. P63 de bunları kullanır.

/// **TON**: şerit (`AppBanner`) ve bildirimlerin (`AppNotice`) renk rolü.
/// Renk rolü sözleşmesi (arayuz.md): `primary` = eylem, `secondary` =
/// zaman/dikkat, `tertiary` = yalnız yapay zekâ, `error` = hata/zorunlu;
/// gerisi nötr.
enum AppTone {
  neutral,
  action,
  attention,
  ai,
  danger;

  /// Şeridin zemin ve mürekkep rengi.
  ({Color bg, Color fg}) colors(ColorScheme s) => switch (this) {
    AppTone.neutral => (bg: s.surfaceContainerHigh, fg: s.onSurface),
    AppTone.action => (bg: s.primaryContainer, fg: s.onPrimaryContainer),
    AppTone.attention => (bg: s.secondaryContainer, fg: s.onSecondaryContainer),
    AppTone.ai => (bg: s.tertiaryContainer, fg: s.onTertiaryContainer),
    AppTone.danger => (bg: s.errorContainer, fg: s.onErrorContainer),
  };
}

/// **YÜZEYLER**. Üç yüzey, hepsi BULANIKSIZ (bulanık gölge yasak — AKICILIK
/// K7): derinlik ince çizgi + bulanıksız alt kenarla verilir.
abstract final class AppSurface {
  /// Grup kartı (ayar satırları, levha içi gruplar): zeminden bir ton açık,
  /// çizgisiz, köşe [AppRadius.l].
  static BoxDecoration group(ThemeData theme) => BoxDecoration(
    color: theme.colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(AppRadius.l),
  );

  /// Kâğıt (kimlik kartı, karo): not kartıyla aynı renk, çizgi ve gölge.
  static BoxDecoration paper(ThemeData theme) {
    final t = AppTokens.fromTheme(theme);
    return BoxDecoration(
      color: t.card,
      borderRadius: BorderRadius.circular(t.cardRadius),
      border: Border.all(color: t.hairline),
      boxShadow: t.cardShadow,
    );
  }

  /// Yüzen yüzey (bildirim, kalem kapsülü, dinleme kartı): [color] (yoksa
  /// `surfaceContainerHigh`), ince çizgi + [floatingShadow].
  static BoxDecoration floating(
    ThemeData theme, {
    Color? color,
    double radius = AppRadius.m,
  }) => BoxDecoration(
    color: color ?? theme.colorScheme.surfaceContainerHigh,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppTokens.fromTheme(theme).hairline),
    boxShadow: floatingShadow(theme),
  );

  /// Yüzen yüzeyin gölgesi: 2 dp aşağıda, bulanıklık 0.
  static List<BoxShadow> floatingShadow(ThemeData theme) => [
    BoxShadow(
      color: theme.colorScheme.shadow.withValues(alpha: AppAlpha.pressed),
      offset: const Offset(0, AppSpace.xxs),
    ),
  ];
}

/// **YANA KAYDIRMA**: uygulamadaki bütün yatay çekişlerin "geçti mi" kararı
/// ve oturma süresi tek yerde.
abstract final class AppSwipe {
  /// Genişliğin bu oranı çekilince bırakışta geçer.
  static const double commitFraction = 0.22;

  /// Bu hızın (dp/sn) üstündeki fiske, çekişle aynı yöndeyse geçer.
  static const double flingVelocity = 300;

  /// Durak yokken lastik direnci (içerik parmağın bu oranı kadar izler).
  static const double rubber = 0.25;

  /// Oturma / geri dönme süresinin alt ve üst sınırı.
  static const Duration settleMin = AppMotion.instant;
  static const Duration settleMax = AppMotion.medium;

  /// Bırakışta geçiş olur mu: [dragged] (işaretli, dp) [extent]'in
  /// [commitFraction]'ını aştıysa ya da [velocity] aynı yönde fiskeyse.
  static bool commits({
    required double dragged,
    required double extent,
    required double velocity,
  }) {
    if (dragged == 0 || extent <= 0) return false;
    if (dragged.abs() >= extent * commitFraction) return true;
    return velocity.abs() >= flingVelocity && velocity.sign == dragged.sign;
  }

  /// Kalan [distance] (dp) için oturma süresi: bırakış hızıyla ters
  /// orantılı, [settleMin]–[settleMax] arasında. Fiske değilse sabit bir
  /// "rahat" hız varsayılır (4 × [flingVelocity]).
  static Duration settleFor({required double distance, double velocity = 0}) {
    final v = velocity.abs() < flingVelocity
        ? flingVelocity * 4
        : velocity.abs();
    final ms = (distance.abs() / v * 1000).round();
    return Duration(
      milliseconds: ms.clamp(
        settleMin.inMilliseconds,
        settleMax.inMilliseconds,
      ),
    );
  }
}
