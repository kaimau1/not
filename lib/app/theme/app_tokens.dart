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

  /// Küçük solma, ipucu, gecikmeli halkanın belirmesi (DENEYIM F72.1).
  static const quick = Duration(milliseconds: 150);

  /// Büyük geçiş: kartın nota açılması gibi (DENEYIM F72.1).
  static const long = Duration(milliseconds: 420);

  static const Curve standard = Easing.standard;
  static const Curve enter = Easing.emphasizedDecelerate;
  static const Curve exit = Easing.emphasizedAccelerate;

  /// Seçim halkası, seçili karo/çip vurgusu (P62 ortak dil). [short] ile aynı
  /// değer; adı niyeti söyler.
  static const selection = short;

  /// "Vurgulu" oturma eğrisi: hızlı başlar, yumuşak oturur, TAŞMAZ
  /// (zıplayan eğri yasak — arayuz.md "Yapılmayacaklar (genel)").
  static const Curve emphasized = Curves.easeOutCubic;

  /// Çıkış süresi = girişin 2/3'ü (tasarım ilkesi 4).
  static Duration exitOf(Duration enter) => enter * (2 / 3);

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

// ---------------------------------------------------------------------------
// **TASARIM DİLİ BELİRTEÇLERİ** (DENEYIM_PLANI §2.1, F72.1). Yeni arayüzde
// ölçü elle yazılmaz; bunlardan biri seçilir. Mandal:
// `test/design_tokens_guard_test.dart` (elle değer sayısı yalnız düşer).
// ---------------------------------------------------------------------------

/// Boşluk (dolgu, ara).
abstract final class AppSpace {
  static const double xxs = 2,
      xs = 4,
      s = 8,
      m = 12,
      l = 16,
      xl = 20,
      xxl = 24,
      xxxl = 32;
}

/// Köşe yarıçapı.
abstract final class AppRadius {
  /// İlerleme çubuğu, imleç, ince şerit.
  static const double hair = 2;

  /// Kutucuk, küçük rozet.
  static const double xs = 4;

  /// Çip, etiket hapı, ipucu.
  static const double s = 8;

  /// Düğme, giriş alanı, karo, menü, bildirim.
  static const double m = 12;

  /// Kart, "+" düğmesi.
  static const double l = 16;

  /// Levha üstü, pencere.
  static const double xl = 24;

  static const double pill = 999;
}

/// Simge boyutu.
abstract final class AppIconSize {
  static const double xs = 16, s = 18, m = 20, l = 24;
}

/// Saydamlık basamakları (`withValues(alpha: AppAlpha.muted)`).
abstract final class AppAlpha {
  static const double hairline = 0.08,
      pressed = 0.12,
      soft = 0.24,
      disabled = 0.38,
      muted = 0.60,
      strong = 0.85,
      scrim = 0.32;
}

/// Arayüz kromunun yazı ağırlıkları — en kalını w600 (K-D2). Kullanıcının
/// notta yazdığı **kalın** bu kurala girmez.
abstract final class AppWeight {
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const strong = FontWeight.w600;
}

/// **YAZI ROLLERİ** (DENEYIM §2.1, F72.2). `ThemeData` alır, `BuildContext`
/// DEĞİL: editör ve kart dosyalarında `Theme.of(context)` yasak (`_themeOf`).
/// Her rol `TextTheme`'in en yakın rolünden türer (yazı tipi ailesi korunur);
/// punto/satır/ağırlık/renk burada sabittir — ham temada (ör.
/// `AppTheme.opposite`, M3 ölçüleri null) de null dönmez.
@immutable
class AppText {
  const AppText._({
    required this.badge,
    required this.meta,
    required this.label,
    required this.body,
    required this.section,
    required this.rowTitle,
    required this.sheetTitle,
    required this.screenTitle,
  });

  /// Sayı rozeti, sayfa hapı (okunan metin değil). 11/14 strong.
  final TextStyle badge;

  /// Tarih, alt bilgi. 12/16 regular, `onSurfaceVariant`.
  final TextStyle meta;

  /// Çip, karo adı, küçük düğme. 13/18 medium.
  final TextStyle label;

  /// Levha metni, satır açıklaması. 14/20 regular.
  final TextStyle body;

  /// Bölüm adı (`SectionLabel`) — her yerde AYNI. 14/20 strong, `primary`.
  final TextStyle section;

  /// Ayar/liste satırı, zengin karo başlığı. 16/22 medium.
  final TextStyle rowTitle;

  /// Levha / pencere başlığı. 18/24 strong.
  final TextStyle sheetTitle;

  /// Üst çubuk başlığı. 20/26 strong.
  final TextStyle screenTitle;

  static final Expando<AppText> _cache = Expando('AppText');

  /// Tema başına bir kez kurulur (tema nesneleri önbellekte: `AppTheme.of`).
  static AppText of(ThemeData theme) => _cache[theme] ??= _build(theme);

  static AppText _build(ThemeData theme) {
    final t = theme.textTheme;
    final s = theme.colorScheme;
    TextStyle role(
      TextStyle? from,
      double size,
      double line,
      FontWeight weight,
      Color color,
    ) => (from ?? const TextStyle()).copyWith(
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      color: color,
    );

    return AppText._(
      badge: role(t.labelSmall, 11, 14, AppWeight.strong, s.onSurface),
      meta: role(t.bodySmall, 12, 16, AppWeight.regular, s.onSurfaceVariant),
      label: role(t.labelLarge, 13, 18, AppWeight.medium, s.onSurface),
      body: role(t.bodyMedium, 14, 20, AppWeight.regular, s.onSurface),
      section: role(t.labelLarge, 14, 20, AppWeight.strong, s.primary),
      rowTitle: role(t.titleMedium, 16, 22, AppWeight.medium, s.onSurface),
      sheetTitle: role(t.titleLarge, 18, 24, AppWeight.strong, s.onSurface),
      screenTitle: role(t.titleLarge, 20, 26, AppWeight.strong, s.onSurface),
    );
  }
}
