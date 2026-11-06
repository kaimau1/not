import 'package:flutter/material.dart';

/// **TEMA AİLESİ** (TEMA_PLANI.md, Faz 29–30 — kullanıcı isteği 2026-11-04:
/// "kırık beyaz soluk ve sıkıcı, saman çok sarı, beyaz çok parlak; premium,
/// herkesin rahatça kullanacağı, sıkılmayacağı bir tema").
///
/// İlke "masa ve kâğıt": zemin (masa) orta açıklıkta ve hafif renkli — ekran
/// parlamaz; kart (kâğıt) zeminden AÇIK — yazı temiz okunur; levha/menü bir
/// kat üstte. Bir serin vurgu (dokunulacak yerler: ekle, seçili, imleç) + bir
/// sıcak vurgu (dikkat: sabitli, yıldız, hatırlatıcı). Yazı saf siyah değil,
/// zeminin tonunu taşıyan mürekkep.
///
/// KÖK NEDEN (eski kırık beyaz neden soluktu): kart (`#F2EFE9`) zeminden
/// (`#F8F6F1`) KOYUYDU — kâğıt masadan koyu olunca ekran kirli görünür; vurgu
/// grafit olduğu için hiçbir yerde renk sinyali yoktu.
///
/// Değerler OKLCH'ten türetildi (zemin L≈0,95, kart L≈0,99); kontrastlar
/// `theme_contrast_test` ile korunur. Yeni renk gerekiyorsa buraya ekle.
enum ThemeFamily {
  /// A · Adaçayı (varsayılan): yeşile çalan taş grisi, petrol, bakır.
  sage,

  /// B · Porselen: serin porselen, mürekkep laciverti, pirinç.
  porcelain,

  /// C · Kil: gül kurusu taş, erik, petrol yeşili (sıcak ama sarı değil).
  clay,

  /// D · Lavanta (2026-11-05, kullanıcı isteği "yeni 2 tema"): leylak
  /// grisi masa, mürdüm mor, deniz yeşili.
  lavender,

  /// E · Zeytin (2026-11-05): zeytin taşı masa, zeytin yeşili, gül kurusu.
  olive,

  /// F · Klasik beyaz (2026-11-06, kullanıcı isteği "klasik bir beyaz tema
  /// ve saman kağıdı teması da olsun, yeni stile uyumlu"): açık gri masa,
  /// bembeyaz kâğıt, mavi vurgu. Eski parlak beyazdan farkı: zemin beyaz
  /// DEĞİL (masa ve kâğıt ilkesi), vurgu tohumdan değil elle seçili.
  white,

  /// G · Saman kâğıdı (2026-11-06): saman masa, krem kâğıt, sepya vurgu,
  /// kiremit. Eski "kağıt" temasından farkı: kâğıt zeminden AÇIK, yazı sepya
  /// mürekkep; sarılık zeminde kalır, okunan yüzey kremdir.
  straw,
}

/// Bir ailenin tek parlaklıktaki ham belirteçleri.
@immutable
class FamilyTokens {
  const FamilyTokens({
    required this.ground,
    required this.lowest,
    required this.card,
    required this.sheet,
    required this.field,
    required this.high,
    required this.highest,
    required this.hair,
    required this.outline,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.inverse,
    required this.onInverse,
    required this.inversePrimary,
  });

  /// Zemin (masa) — `ColorScheme.surface`.
  final Color ground;

  /// En uç yüzey (açıkta = kart, koyuda zeminden koyu).
  final Color lowest;

  /// Kart / not sayfası (kâğıt).
  final Color card;

  /// Levha, menü, alt şerit.
  final Color sheet;

  /// Kart içi alan: arama, giriş kutusu.
  final Color field;

  /// Ayırıcı yüzey: iskelet, seçili satır.
  final Color high;
  final Color highest;

  /// İnce çizgi (`outlineVariant`).
  final Color hair;
  final Color outline;

  /// Yazı (`onSurface`) ve soluk yazı (`onSurfaceVariant`).
  final Color ink;
  final Color muted;

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color inverse;
  final Color onInverse;
  final Color inversePrimary;
}

abstract final class FamilyPalettes {
  static FamilyTokens of(ThemeFamily family, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (family) {
      ThemeFamily.sage => dark ? _sageDark : _sageLight,
      ThemeFamily.porcelain => dark ? _porcelainDark : _porcelainLight,
      ThemeFamily.clay => dark ? _clayDark : _clayLight,
      ThemeFamily.lavender => dark ? _lavenderDark : _lavenderLight,
      ThemeFamily.olive => dark ? _oliveDark : _oliveLight,
      ThemeFamily.white => dark ? _whiteDark : _whiteLight,
      ThemeFamily.straw => dark ? _strawDark : _strawLight,
    };
  }

  // ── A · Adaçayı ─────────────────────────────────────────────────────────
  static const _sageLight = FamilyTokens(
    ground: Color(0xFFEAF0EB),
    lowest: Color(0xFFFAFCFA),
    card: Color(0xFFFAFCFA),
    sheet: Color(0xFFF5F9F6),
    field: Color(0xFFEFF4F0),
    high: Color(0xFFDEE5DF),
    highest: Color(0xFFD5DDD7),
    hair: Color(0xFFD1D8D2),
    outline: Color(0xFF7A837B),
    ink: Color(0xFF1B2420),
    muted: Color(0xFF4D5853),
    primary: Color(0xFF106561),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFC8E9E6),
    onPrimaryContainer: Color(0xFF002E2C),
    secondary: Color(0xFFA26239),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFBE3D2),
    onSecondaryContainer: Color(0xFF412615),
    tertiary: Color(0xFF5A5385),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE4E1FB),
    onTertiaryContainer: Color(0xFF292440),
    inverse: Color(0xFF28302C),
    onInverse: Color(0xFFEDF2ED),
    inversePrimary: Color(0xFF88CDC8),
  );

  static const _sageDark = FamilyTokens(
    ground: Color(0xFF131916),
    lowest: Color(0xFF0D120F),
    card: Color(0xFF1C221E),
    sheet: Color(0xFF202723),
    field: Color(0xFF202723),
    high: Color(0xFF29302C),
    highest: Color(0xFF323934),
    hair: Color(0xFF383F3B),
    outline: Color(0xFF8C9590),
    ink: Color(0xFFE1E8E4),
    muted: Color(0xFFB1BAB5),
    primary: Color(0xFF76CDC5),
    onPrimary: Color(0xFF002E2B),
    primaryContainer: Color(0xFF0B4A46),
    onPrimaryContainer: Color(0xFFC8E9E5),
    secondary: Color(0xFFE5A880),
    onSecondary: Color(0xFF3F2007),
    secondaryContainer: Color(0xFF55341C),
    onSecondaryContainer: Color(0xFFF8DFCF),
    tertiary: Color(0xFFBCB7E8),
    onTertiary: Color(0xFF292440),
    tertiaryContainer: Color(0xFF3F3B59),
    onTertiaryContainer: Color(0xFFE4E2F8),
    inverse: Color(0xFFE1E8E4),
    onInverse: Color(0xFF1B241F),
    inversePrimary: Color(0xFF116560),
  );

  // ── B · Porselen ────────────────────────────────────────────────────────
  static const _porcelainLight = FamilyTokens(
    ground: Color(0xFFEAEEF4),
    lowest: Color(0xFFFAFCFE),
    card: Color(0xFFFAFCFE),
    sheet: Color(0xFFF5F8FC),
    field: Color(0xFFEFF3F8),
    high: Color(0xFFDEE3EA),
    highest: Color(0xFFD6DBE3),
    hair: Color(0xFFD1D6DE),
    outline: Color(0xFF7A818A),
    ink: Color(0xFF1D2229),
    muted: Color(0xFF50555E),
    primary: Color(0xFF304D8C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6E2F9),
    onPrimaryContainer: Color(0xFF1A263F),
    secondary: Color(0xFF956725),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF5E6CE),
    onSecondaryContainer: Color(0xFF3D290E),
    tertiary: Color(0xFF71497A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEFDEF3),
    onTertiaryContainer: Color(0xFF342038),
    inverse: Color(0xFF2B2E34),
    onInverse: Color(0xFFEDF0F6),
    inversePrimary: Color(0xFFA7BEEC),
  );

  static const _porcelainDark = FamilyTokens(
    ground: Color(0xFF14171C),
    lowest: Color(0xFF0E1114),
    card: Color(0xFF1D2126),
    sheet: Color(0xFF22252B),
    field: Color(0xFF22252B),
    high: Color(0xFF2A2E34),
    highest: Color(0xFF33373D),
    hair: Color(0xFF393D44),
    outline: Color(0xFF8E939A),
    ink: Color(0xFFE2E7ED),
    muted: Color(0xFFB3B8BF),
    primary: Color(0xFF9FBBF2),
    onPrimary: Color(0xFF1A263F),
    primaryContainer: Color(0xFF2F3F60),
    onPrimaryContainer: Color(0xFFD6E2F9),
    secondary: Color(0xFFD9AF75),
    onSecondary: Color(0xFF3A2400),
    secondaryContainer: Color(0xFF4F3815),
    onSecondaryContainer: Color(0xFFF3E2CB),
    tertiary: Color(0xFFD2B0DA),
    onTertiary: Color(0xFF342038),
    tertiaryContainer: Color(0xFF4C3750),
    onTertiaryContainer: Color(0xFFEEDFF1),
    inverse: Color(0xFFE2E7ED),
    onInverse: Color(0xFF1D2229),
    inversePrimary: Color(0xFF425782),
  );

  // ── C · Kil ─────────────────────────────────────────────────────────────
  static const _clayLight = FamilyTokens(
    ground: Color(0xFFF3ECE9),
    lowest: Color(0xFFFEFBF9),
    card: Color(0xFFFEFBF9),
    sheet: Color(0xFFFBF7F4),
    field: Color(0xFFF7F1EE),
    high: Color(0xFFEAE1DD),
    highest: Color(0xFFE2D8D4),
    hair: Color(0xFFDDD4CF),
    outline: Color(0xFF897D78),
    ink: Color(0xFF291F1E),
    muted: Color(0xFF5E5252),
    primary: Color(0xFF743957),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF5D8E4),
    onPrimaryContainer: Color(0xFF381C2A),
    secondary: Color(0xFF2F6F6F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCEEFF1),
    onSecondaryContainer: Color(0xFF023536),
    tertiary: Color(0xFF7B4F29),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF7E0CE),
    onTertiaryContainer: Color(0xFF3B220D),
    inverse: Color(0xFF342C2B),
    onInverse: Color(0xFFF5EFEC),
    inversePrimary: Color(0xFFE1ACC4),
  );

  static const _clayDark = FamilyTokens(
    ground: Color(0xFF1B1614),
    lowest: Color(0xFF140F0E),
    card: Color(0xFF261F1C),
    sheet: Color(0xFF2B2321),
    field: Color(0xFF2B2321),
    high: Color(0xFF332C29),
    highest: Color(0xFF3C3532),
    hair: Color(0xFF433B38),
    outline: Color(0xFF99908D),
    ink: Color(0xFFEDE4E2),
    muted: Color(0xFFBFB5B3),
    primary: Color(0xFFE5A4C2),
    onPrimary: Color(0xFF381C2A),
    primaryContainer: Color(0xFF573244),
    onPrimaryContainer: Color(0xFFF5D8E4),
    secondary: Color(0xFF6BCAC9),
    onSecondary: Color(0xFF003232),
    secondaryContainer: Color(0xFF034747),
    onSecondaryContainer: Color(0xFFCBECEC),
    tertiary: Color(0xFFE0B491),
    onTertiary: Color(0xFF3B220D),
    tertiaryContainer: Color(0xFF533924),
    onTertiaryContainer: Color(0xFFF4E0D1),
    inverse: Color(0xFFEDE4E2),
    onInverse: Color(0xFF291F1D),
    inversePrimary: Color(0xFF77465E),
  );

  // ── D · Lavanta ─────────────────────────────────────────────────────────
  static const _lavenderLight = FamilyTokens(
    ground: Color(0xFFEDEBF3),
    lowest: Color(0xFFFCFBFE),
    card: Color(0xFFFCFBFE),
    sheet: Color(0xFFF7F5FB),
    field: Color(0xFFF1EFF6),
    high: Color(0xFFE2DFEA),
    highest: Color(0xFFD9D6E2),
    hair: Color(0xFFD4D1DD),
    outline: Color(0xFF7E7A8A),
    ink: Color(0xFF211F2A),
    muted: Color(0xFF55525F),
    primary: Color(0xFF5B4B8A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE5DEFA),
    onPrimaryContainer: Color(0xFF231A40),
    secondary: Color(0xFF2F7466),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCDEEE6),
    onSecondaryContainer: Color(0xFF00352C),
    tertiary: Color(0xFF975A44),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF8E0D6),
    onTertiaryContainer: Color(0xFF3D1E12),
    inverse: Color(0xFF2E2C36),
    onInverse: Color(0xFFF1EFF6),
    inversePrimary: Color(0xFFC6B8F4),
  );

  static const _lavenderDark = FamilyTokens(
    ground: Color(0xFF16151B),
    lowest: Color(0xFF100F14),
    card: Color(0xFF1F1D26),
    sheet: Color(0xFF24222B),
    field: Color(0xFF24222B),
    high: Color(0xFF2D2B35),
    highest: Color(0xFF36343E),
    hair: Color(0xFF3C3A45),
    outline: Color(0xFF928F9C),
    ink: Color(0xFFE7E4EF),
    muted: Color(0xFFB8B5C2),
    primary: Color(0xFFC6B8F4),
    onPrimary: Color(0xFF2C2152),
    primaryContainer: Color(0xFF433669),
    onPrimaryContainer: Color(0xFFE5DEFA),
    secondary: Color(0xFF7DD3C2),
    onSecondary: Color(0xFF00382F),
    secondaryContainer: Color(0xFF0D4E43),
    onSecondaryContainer: Color(0xFFCDEEE6),
    tertiary: Color(0xFFE9B6A2),
    onTertiary: Color(0xFF3D1E12),
    tertiaryContainer: Color(0xFF5A3A2D),
    onTertiaryContainer: Color(0xFFF8E0D6),
    inverse: Color(0xFFE7E4EF),
    onInverse: Color(0xFF211F2A),
    inversePrimary: Color(0xFF5B4B8A),
  );

  // ── E · Zeytin ──────────────────────────────────────────────────────────
  static const _oliveLight = FamilyTokens(
    ground: Color(0xFFEDEEE6),
    lowest: Color(0xFFFBFCF8),
    card: Color(0xFFFBFCF8),
    sheet: Color(0xFFF6F7F1),
    field: Color(0xFFF0F1EA),
    high: Color(0xFFE2E4DA),
    highest: Color(0xFFD9DBD0),
    hair: Color(0xFFD4D6CB),
    outline: Color(0xFF7D8075),
    ink: Color(0xFF1F221B),
    muted: Color(0xFF52564B),
    primary: Color(0xFF4F6A2A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD9EBC0),
    onPrimaryContainer: Color(0xFF162404),
    secondary: Color(0xFF8C4A5F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF7DCE4),
    onSecondaryContainer: Color(0xFF3A1421),
    tertiary: Color(0xFF2F6378),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD3E8F2),
    onTertiaryContainer: Color(0xFF032D3C),
    inverse: Color(0xFF2E312A),
    onInverse: Color(0xFFF0F1EA),
    inversePrimary: Color(0xFFB2D18A),
  );

  static const _oliveDark = FamilyTokens(
    ground: Color(0xFF161813),
    lowest: Color(0xFF10120D),
    card: Color(0xFF1F221B),
    sheet: Color(0xFF242720),
    field: Color(0xFF242720),
    high: Color(0xFF2D3028),
    highest: Color(0xFF363931),
    hair: Color(0xFF3C3F37),
    outline: Color(0xFF91948A),
    ink: Color(0xFFE4E6DD),
    muted: Color(0xFFB6B9AE),
    primary: Color(0xFFB2D18A),
    onPrimary: Color(0xFF203606),
    primaryContainer: Color(0xFF384F18),
    onPrimaryContainer: Color(0xFFD9EBC0),
    secondary: Color(0xFFEDB0C3),
    onSecondary: Color(0xFF4F1F31),
    secondaryContainer: Color(0xFF6B3547),
    onSecondaryContainer: Color(0xFFF7DCE4),
    tertiary: Color(0xFF9BCCE2),
    onTertiary: Color(0xFF003548),
    tertiaryContainer: Color(0xFF154B5F),
    onTertiaryContainer: Color(0xFFD3E8F2),
    inverse: Color(0xFFE4E6DD),
    onInverse: Color(0xFF1F221B),
    inversePrimary: Color(0xFF4F6A2A),
  );

  // ── F · Klasik beyaz ────────────────────────────────────────────────────
  static const _whiteLight = FamilyTokens(
    ground: Color(0xFFF3F4F6),
    lowest: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    sheet: Color(0xFFFAFAFB),
    field: Color(0xFFF1F2F4),
    high: Color(0xFFE4E6EA),
    highest: Color(0xFFDADDE2),
    hair: Color(0xFFD6D9DE),
    outline: Color(0xFF74787F),
    ink: Color(0xFF1A1C1F),
    muted: Color(0xFF4A4E55),
    primary: Color(0xFF1F5FBF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD8E4FA),
    onPrimaryContainer: Color(0xFF0B2A5C),
    secondary: Color(0xFFA44F0C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFCE3CF),
    onSecondaryContainer: Color(0xFF3F1F05),
    tertiary: Color(0xFF6B4A9A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFECE0FA),
    onTertiaryContainer: Color(0xFF2C1A47),
    inverse: Color(0xFF2D2F33),
    onInverse: Color(0xFFF1F2F4),
    inversePrimary: Color(0xFFA8C5F5),
  );

  static const _whiteDark = FamilyTokens(
    ground: Color(0xFF121314),
    lowest: Color(0xFF0C0D0E),
    card: Color(0xFF1C1D1F),
    sheet: Color(0xFF212224),
    field: Color(0xFF212224),
    high: Color(0xFF2A2B2E),
    highest: Color(0xFF333438),
    hair: Color(0xFF3A3B3F),
    outline: Color(0xFF909299),
    ink: Color(0xFFE6E7EA),
    muted: Color(0xFFB7B9BE),
    primary: Color(0xFFA8C5F5),
    onPrimary: Color(0xFF0B2A5C),
    primaryContainer: Color(0xFF22437A),
    onPrimaryContainer: Color(0xFFD8E4FA),
    secondary: Color(0xFFF2B07E),
    onSecondary: Color(0xFF3F1F05),
    secondaryContainer: Color(0xFF5A3311),
    onSecondaryContainer: Color(0xFFFCE3CF),
    tertiary: Color(0xFFCDB6F0),
    onTertiary: Color(0xFF2C1A47),
    tertiaryContainer: Color(0xFF463263),
    onTertiaryContainer: Color(0xFFECE0FA),
    inverse: Color(0xFFE6E7EA),
    onInverse: Color(0xFF1A1C1F),
    inversePrimary: Color(0xFF1F5FBF),
  );

  // ── G · Saman kâğıdı ────────────────────────────────────────────────────
  static const _strawLight = FamilyTokens(
    ground: Color(0xFFEDE3C8),
    lowest: Color(0xFFFCF8EC),
    card: Color(0xFFFCF8EC),
    sheet: Color(0xFFF8F2E1),
    field: Color(0xFFF3EBD6),
    high: Color(0xFFE3D8BB),
    highest: Color(0xFFDACEAF),
    hair: Color(0xFFD6CAAB),
    outline: Color(0xFF7D7259),
    ink: Color(0xFF2A2216),
    muted: Color(0xFF574C38),
    primary: Color(0xFF7A4A1E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF2DCC0),
    onPrimaryContainer: Color(0xFF34200A),
    secondary: Color(0xFF9C3A2C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF8D9D2),
    onSecondaryContainer: Color(0xFF3E130C),
    tertiary: Color(0xFF3B6158),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD2E8E1),
    onTertiaryContainer: Color(0xFF0E2C25),
    inverse: Color(0xFF352D20),
    onInverse: Color(0xFFF6EFDD),
    inversePrimary: Color(0xFFE5B98A),
  );

  static const _strawDark = FamilyTokens(
    ground: Color(0xFF1A1711),
    lowest: Color(0xFF13110C),
    card: Color(0xFF24201A),
    sheet: Color(0xFF29251E),
    field: Color(0xFF29251E),
    high: Color(0xFF322D25),
    highest: Color(0xFF3B362D),
    hair: Color(0xFF423C32),
    outline: Color(0xFF9A9180),
    ink: Color(0xFFEDE5D3),
    muted: Color(0xFFC0B6A2),
    primary: Color(0xFFE5B98A),
    onPrimary: Color(0xFF452A0D),
    primaryContainer: Color(0xFF5E3E1C),
    onPrimaryContainer: Color(0xFFF2DCC0),
    secondary: Color(0xFFF0A898),
    onSecondary: Color(0xFF4E1A11),
    secondaryContainer: Color(0xFF6E2C22),
    onSecondaryContainer: Color(0xFFF8D9D2),
    tertiary: Color(0xFF9FCFC3),
    onTertiary: Color(0xFF0E2C25),
    tertiaryContainer: Color(0xFF25483F),
    onTertiaryContainer: Color(0xFFD2E8E1),
    inverse: Color(0xFFEDE5D3),
    onInverse: Color(0xFF2A2216),
    inversePrimary: Color(0xFF7A4A1E),
  );
}
