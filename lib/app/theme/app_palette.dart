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
///
/// **RENK ROLLERİ** (DENEYIM_PLANI §2.2, K-D1 — bekçi `test/color_roles_test.dart`):
/// - `primary`/`primaryContainer` = eylem, seçim, oluşturma, odak ("+", seçili
///   çip, imleç, bağlantı, bugünün günü, bölüm adı).
/// - `secondary`/`secondaryContainer` (sıcak) = zaman, dikkat, etiket (sabitli,
///   yıldız, hatırlatıcı, zamanı gelen şeridi, bekleyen yükleme, etiket hapı).
/// - `tertiary`/`tertiaryContainer` = YALNIZ yapay zekâ kimliği (`AiIcon`, AI
///   levhası).
/// - `error` = yıkıcı (sil, kalıcı sil).
/// - nötr (`surfaceContainer*`, `onSurfaceVariant`) = geri kalan her şey.
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

  /// H · Krem (2026-11-06, kullanıcı isteği "saman kağıdı ama daha açık"):
  /// açık krem masa, beyaza yakın fildişi kâğıt, kehribar vurgu.
  cream,

  /// I · Şeftali (2026-11-06, "not uygulaması için bilimsel olarak iyi
  /// renkler"): okuma rahatlığı araştırmalarında (görsel stres, disleksi —
  /// İngiliz Disleksi Derneği'nin krem/pastel zemin önerisi) parlak beyaz
  /// yerine önerilen sıcak, düşük doygunluklu pastel zemin; mürekkep saf
  /// siyah değil (aşırı kontrast "titreşimi" yok), metin kontrastı ≥ 7:1.
  peach,

  /// J · Nane (2026-11-06): yeşil-mavi, gözün en duyarlı olduğu (≈ 500–
  /// 555 nm) bölgede düşük parlaklık — uzun okumada göz yorgunluğu düşük,
  /// sakin ve odak dostu kabul edilen ton; vurgu koyu deniz yeşili.
  mint,

  /// CANLI TEMALAR (kullanıcı isteği 2026-11-06: "birkaç tane daha canlı,
  /// renkli, kontrastlı tema yap, 5 adet"): doygun renkli masa, açık kâğıt,
  /// güçlü vurgu. Kontrast kuralları ötekilerle aynı (`theme_contrast_test`).
  ocean,
  rose,
  tangerine,
  emerald,
  amethyst,

  /// SADE KLASİK TEMALAR (kullanıcı isteği 2026-11-08: "çok sade klasik eski
  /// temalar, 5 adet, gayet basit, temiz"): beyaz kâğıt, açık gri masa,
  /// tek koyu vurgu; renk oyunu yok. Koyu kipte klasik beyazın koyusu.
  classic,
  newsprint,
  notebook,
  graphite,
  ledger,
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
      ThemeFamily.cream => dark ? _creamDark : _creamLight,
      ThemeFamily.peach => dark ? _peachDark : _peachLight,
      ThemeFamily.mint => dark ? _mintDark : _mintLight,
      ThemeFamily.ocean => dark ? _oceanDark : _oceanLight,
      ThemeFamily.rose => dark ? _roseDark : _roseLight,
      ThemeFamily.tangerine => dark ? _tangerineDark : _tangerineLight,
      ThemeFamily.emerald => dark ? _emeraldDark : _emeraldLight,
      ThemeFamily.amethyst => dark ? _amethystDark : _amethystLight,
      ThemeFamily.classic => dark ? _whiteDark : _classicLight,
      ThemeFamily.newsprint => dark ? _whiteDark : _newsprintLight,
      ThemeFamily.notebook => dark ? _whiteDark : _notebookLight,
      ThemeFamily.graphite => dark ? _whiteDark : _graphiteLight,
      ThemeFamily.ledger => dark ? _whiteDark : _ledgerLight,
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
    // F80.1-5 (2026-11-12, ölçüldü): 1C221E zeminden 0,038 L açıktı — kart
    // koyuda masaya karışıyordu; +1/kanal → 0,043 (`theme_contrast_test`; aynı
    // düzeltme lavanta, saman, krem koyusunda).
    card: Color(0xFF1D231F),
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
    // F80.1-5: 1F1D26 → 0,037 L; +1/kanal → 0,042.
    card: Color(0xFF201E27),
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

  // ── Sade klasik · Klasik ──
  static const _classicLight = FamilyTokens(
    ground: Color(0xFFEEEEEE),
    lowest: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    sheet: Color(0xFFFAFAFA),
    field: Color(0xFFF2F2F2),
    high: Color(0xFFE4E5E7),
    highest: Color(0xFFDADBDE),
    hair: Color(0xFFD5D7DA),
    outline: Color(0xFF74777C),
    ink: Color(0xFF1A1B1D),
    muted: Color(0xFF4A4D52),
    primary: Color(0xFF0B5E86),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD3E8F2),
    onPrimaryContainer: Color(0xFF05293C),
    secondary: Color(0xFF8A4B12),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF6E1CC),
    onSecondaryContainer: Color(0xFF3A1E05),
    tertiary: Color(0xFF5B4A8A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE6E0F5),
    onTertiaryContainer: Color(0xFF231A40),
    inverse: Color(0xFF2D2E31),
    onInverse: Color(0xFFF1F1F2),
    inversePrimary: Color(0xFF9CCBE6),
  );

  // ── Sade klasik · Gazete ──
  static const _newsprintLight = FamilyTokens(
    ground: Color(0xFFECECEA),
    lowest: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    sheet: Color(0xFFFAFAFA),
    field: Color(0xFFF2F2F2),
    high: Color(0xFFE4E5E7),
    highest: Color(0xFFDADBDE),
    hair: Color(0xFFD5D7DA),
    outline: Color(0xFF74777C),
    ink: Color(0xFF1A1B1D),
    muted: Color(0xFF4A4D52),
    primary: Color(0xFF2F3B4C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDFE3EA),
    onPrimaryContainer: Color(0xFF141A24),
    secondary: Color(0xFF7A4A2A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE9E6E0),
    onSecondaryContainer: Color(0xFF22201C),
    tertiary: Color(0xFF2E5A6B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDEE3E8),
    onTertiaryContainer: Color(0xFF1A2128),
    inverse: Color(0xFF2D2E31),
    onInverse: Color(0xFFF1F1F2),
    inversePrimary: Color(0xFFBDBDBD),
  );

  // ── Sade klasik · Defter ──
  static const _notebookLight = FamilyTokens(
    ground: Color(0xFFECEFF4),
    lowest: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    sheet: Color(0xFFFAFAFA),
    field: Color(0xFFF2F2F2),
    high: Color(0xFFE4E5E7),
    highest: Color(0xFFDADBDE),
    hair: Color(0xFFD5D7DA),
    outline: Color(0xFF74777C),
    ink: Color(0xFF1A1B1D),
    muted: Color(0xFF4A4D52),
    primary: Color(0xFF1B2E6B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCE3F5),
    onPrimaryContainer: Color(0xFF0B1638),
    secondary: Color(0xFFA8231B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFADBD8),
    onSecondaryContainer: Color(0xFF410E0B),
    tertiary: Color(0xFF2E6B4F),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD5EBDF),
    onTertiaryContainer: Color(0xFF0C2B1C),
    inverse: Color(0xFF2D2E31),
    onInverse: Color(0xFFF1F1F2),
    inversePrimary: Color(0xFFAEBFEF),
  );

  // ── Sade klasik · Kurşun kalem ──
  static const _graphiteLight = FamilyTokens(
    ground: Color(0xFFE8E9EB),
    lowest: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    sheet: Color(0xFFFAFAFA),
    field: Color(0xFFF2F2F2),
    high: Color(0xFFE4E5E7),
    highest: Color(0xFFDADBDE),
    hair: Color(0xFFD5D7DA),
    outline: Color(0xFF74777C),
    ink: Color(0xFF1A1B1D),
    muted: Color(0xFF4A4D52),
    primary: Color(0xFF33445A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDDE2E8),
    onPrimaryContainer: Color(0xFF161E26),
    secondary: Color(0xFF6A4E2E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEEE3D5),
    onSecondaryContainer: Color(0xFF2A1D0E),
    tertiary: Color(0xFF2E6B4F),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD5EBDF),
    onTertiaryContainer: Color(0xFF0C2B1C),
    inverse: Color(0xFF2D2E31),
    onInverse: Color(0xFFF1F1F2),
    inversePrimary: Color(0xFFB4C2D0),
  );

  // ── Sade klasik · Klasik yeşil ──
  static const _ledgerLight = FamilyTokens(
    ground: Color(0xFFEBF0EC),
    lowest: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    sheet: Color(0xFFFAFAFA),
    field: Color(0xFFF2F2F2),
    high: Color(0xFFE4E5E7),
    highest: Color(0xFFDADBDE),
    hair: Color(0xFFD5D7DA),
    outline: Color(0xFF74777C),
    ink: Color(0xFF1A1B1D),
    muted: Color(0xFF4A4D52),
    primary: Color(0xFF2B6A3C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD5EBDC),
    onPrimaryContainer: Color(0xFF0B2E15),
    secondary: Color(0xFF8A4B12),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF6E1CC),
    onSecondaryContainer: Color(0xFF3A1E05),
    tertiary: Color(0xFF1F5F7A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD3E8F0),
    onTertiaryContainer: Color(0xFF072A38),
    inverse: Color(0xFF2D2E31),
    onInverse: Color(0xFFF1F1F2),
    inversePrimary: Color(0xFFA3D3B0),
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
    // F80.1-5: 24201A → 0,0399 L; +1/kanal → 0,044.
    card: Color(0xFF25211B),
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

  // ── H · Krem ──
  static const _creamLight = FamilyTokens(
    ground: Color(0xFFF6F0DE),
    lowest: Color(0xFFFFFDF6),
    card: Color(0xFFFFFDF6),
    sheet: Color(0xFFFBF7EC),
    field: Color(0xFFF7F1E2),
    high: Color(0xFFEDE5CF),
    highest: Color(0xFFE5DCC3),
    hair: Color(0xFFE1D8BF),
    outline: Color(0xFF7E7660),
    ink: Color(0xFF2B261C),
    muted: Color(0xFF5A5241),
    primary: Color(0xFF8A5A22),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF6E3C4),
    onPrimaryContainer: Color(0xFF3A2408),
    secondary: Color(0xFF3E6E4F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCEBDF),
    onSecondaryContainer: Color(0xFF14261A),
    tertiary: Color(0xFF7A4B6E),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF1DDEB),
    onTertiaryContainer: Color(0xFF33182D),
    inverse: Color(0xFF37322A),
    onInverse: Color(0xFFF8F2E2),
    inversePrimary: Color(0xFFE8BE87),
  );

  static const _creamDark = FamilyTokens(
    ground: Color(0xFF1B1914),
    lowest: Color(0xFF141210),
    // F80.1-5: 25221C → 0,039 L; +1/kanal → 0,043.
    card: Color(0xFF26231D),
    sheet: Color(0xFF2A2721),
    field: Color(0xFF2A2721),
    high: Color(0xFF333029),
    highest: Color(0xFF3C3931),
    hair: Color(0xFF433F36),
    outline: Color(0xFF9C9584),
    ink: Color(0xFFEEE8D8),
    muted: Color(0xFFC2BAA7),
    primary: Color(0xFFE8BE87),
    onPrimary: Color(0xFF47290A),
    primaryContainer: Color(0xFF63431D),
    onPrimaryContainer: Color(0xFFF6E3C4),
    secondary: Color(0xFFA9C9B1),
    onSecondary: Color(0xFF1F3326),
    secondaryContainer: Color(0xFF344B3B),
    onSecondaryContainer: Color(0xFFDCEBDF),
    tertiary: Color(0xFFDDB4D2),
    onTertiary: Color(0xFF3D1F37),
    tertiaryContainer: Color(0xFF563550),
    onTertiaryContainer: Color(0xFFF1DDEB),
    inverse: Color(0xFFEEE8D8),
    onInverse: Color(0xFF2B261C),
    inversePrimary: Color(0xFF8A5A22),
  );

  // ── I · Şeftali ──
  static const _peachLight = FamilyTokens(
    ground: Color(0xFFF7EAE2),
    lowest: Color(0xFFFFF9F5),
    card: Color(0xFFFFF9F5),
    sheet: Color(0xFFFCF2EC),
    field: Color(0xFFF8EDE6),
    high: Color(0xFFEEDDD3),
    highest: Color(0xFFE6D3C8),
    hair: Color(0xFFE2CFC3),
    outline: Color(0xFF80706A),
    ink: Color(0xFF2B211D),
    muted: Color(0xFF5C4D46),
    primary: Color(0xFFA3432C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFBDCD2),
    onPrimaryContainer: Color(0xFF3D1308),
    secondary: Color(0xFF3F6A78),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD4E8EF),
    onSecondaryContainer: Color(0xFF0A2A35),
    tertiary: Color(0xFF6C5A1F),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF2E6C0),
    onTertiaryContainer: Color(0xFF2B2306),
    inverse: Color(0xFF3A2F2A),
    onInverse: Color(0xFFFBEEE7),
    inversePrimary: Color(0xFFF4B39F),
  );

  static const _peachDark = FamilyTokens(
    ground: Color(0xFF1C1715),
    lowest: Color(0xFF151110),
    card: Color(0xFF27201D),
    sheet: Color(0xFF2C2522),
    field: Color(0xFF2C2522),
    high: Color(0xFF352D29),
    highest: Color(0xFF3E3531),
    hair: Color(0xFF453B37),
    outline: Color(0xFF9E918B),
    ink: Color(0xFFF0E5E0),
    muted: Color(0xFFC6B8B1),
    primary: Color(0xFFF4B39F),
    onPrimary: Color(0xFF561D0D),
    primaryContainer: Color(0xFF77311F),
    onPrimaryContainer: Color(0xFFFBDCD2),
    secondary: Color(0xFF9ACCDB),
    onSecondary: Color(0xFF033441),
    secondaryContainer: Color(0xFF1F4C59),
    onSecondaryContainer: Color(0xFFD4E8EF),
    tertiary: Color(0xFFD9C78A),
    onTertiary: Color(0xFF3A2F00),
    tertiaryContainer: Color(0xFF54471A),
    onTertiaryContainer: Color(0xFFF2E6C0),
    inverse: Color(0xFFF0E5E0),
    onInverse: Color(0xFF2B211D),
    inversePrimary: Color(0xFFA3432C),
  );

  // ── J · Nane ──
  static const _mintLight = FamilyTokens(
    ground: Color(0xFFE5F2EE),
    lowest: Color(0xFFF9FDFB),
    card: Color(0xFFF9FDFB),
    sheet: Color(0xFFF2FAF7),
    field: Color(0xFFECF6F2),
    high: Color(0xFFD9E8E3),
    highest: Color(0xFFD0E0DA),
    hair: Color(0xFFCCDCD6),
    outline: Color(0xFF728580),
    ink: Color(0xFF182623),
    muted: Color(0xFF475A55),
    primary: Color(0xFF0E6B5C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFC3EDE3),
    onPrimaryContainer: Color(0xFF00302A),
    secondary: Color(0xFF8A4F7D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF6DBEF),
    onSecondaryContainer: Color(0xFF381330),
    tertiary: Color(0xFF3B5BA0),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDBE3FA),
    onTertiaryContainer: Color(0xFF0F1E45),
    inverse: Color(0xFF26332F),
    onInverse: Color(0xFFECF5F1),
    inversePrimary: Color(0xFF7FD6C3),
  );

  static const _mintDark = FamilyTokens(
    ground: Color(0xFF111A18),
    lowest: Color(0xFF0B1210),
    card: Color(0xFF1A2421),
    sheet: Color(0xFF1F2A26),
    field: Color(0xFF1F2A26),
    high: Color(0xFF28332F),
    highest: Color(0xFF313C38),
    hair: Color(0xFF37433E),
    outline: Color(0xFF8A9A95),
    ink: Color(0xFFDFEDE8),
    muted: Color(0xFFAEC0BA),
    primary: Color(0xFF7FD6C3),
    onPrimary: Color(0xFF00382F),
    primaryContainer: Color(0xFF0B5146),
    onPrimaryContainer: Color(0xFFC3EDE3),
    secondary: Color(0xFFE6B0D8),
    onSecondary: Color(0xFF4A1A40),
    secondaryContainer: Color(0xFF662E5A),
    onSecondaryContainer: Color(0xFFF6DBEF),
    tertiary: Color(0xFFB3C5F5),
    onTertiary: Color(0xFF152A5C),
    tertiaryContainer: Color(0xFF2E4479),
    onTertiaryContainer: Color(0xFFDBE3FA),
    inverse: Color(0xFFDFEDE8),
    onInverse: Color(0xFF182623),
    inversePrimary: Color(0xFF0E6B5C),
  );

  // ── Okyanus (canlı, 2026-11-06) ──
  static const _oceanLight = FamilyTokens(
    ground: Color(0xFFCDE0F7),
    lowest: Color(0xFFF9FBFD),
    card: Color(0xFFF9FBFD),
    sheet: Color(0xFFF1F6FB),
    field: Color(0xFFE5EEF8),
    high: Color(0xFFC8D8EA),
    highest: Color(0xFFBACDE3),
    hair: Color(0xFFB9CBDF),
    outline: Color(0xFF546578),
    ink: Color(0xFF0D1621),
    muted: Color(0xFF344456),
    primary: Color(0xFF0C60C0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB4D4F9),
    onPrimaryContainer: Color(0xFF051F3D),
    secondary: Color(0xFFAF590E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFAD9BD),
    onSecondaryContainer: Color(0xFF3D1F05),
    tertiary: Color(0xFF127D6B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC3F8F0),
    onTertiaryContainer: Color(0xFF073C33),
    inverse: Color(0xFF1E2A38),
    onInverse: Color(0xFFECF2F9),
    inversePrimary: Color(0xFF86BBF9),
  );

  static const _oceanDark = FamilyTokens(
    ground: Color(0xFF0D151E),
    lowest: Color(0xFF090F15),
    card: Color(0xFF161F2A),
    sheet: Color(0xFF1A2430),
    field: Color(0xFF1A2430),
    high: Color(0xFF222D3A),
    highest: Color(0xFF2B3746),
    hair: Color(0xFF303C4B),
    outline: Color(0xFF8793A1),
    ink: Color(0xFFE3EAF2),
    muted: Color(0xFFB1BCC9),
    primary: Color(0xFF76B3F9),
    onPrimary: Color(0xFF031D3A),
    primaryContainer: Color(0xFF1C426E),
    onPrimaryContainer: Color(0xFFCBE1FB),
    secondary: Color(0xFFF4B47B),
    onSecondary: Color(0xFF3A1D03),
    secondaryContainer: Color(0xFF67401E),
    onSecondaryContainer: Color(0xFFF9E1CD),
    tertiary: Color(0xFF88F2E0),
    onTertiary: Color(0xFF033A31),
    tertiaryContainer: Color(0xFF22675C),
    onTertiaryContainer: Color(0xFFCDF9F2),
    inverse: Color(0xFFE3EAF2),
    onInverse: Color(0xFF0D1621),
    inversePrimary: Color(0xFF0C60C0),
  );

  // ── Gül (canlı, 2026-11-06) ──
  static const _roseLight = FamilyTokens(
    ground: Color(0xFFF7CDDF),
    lowest: Color(0xFFFDF9FB),
    card: Color(0xFFFDF9FB),
    sheet: Color(0xFFFBF1F5),
    field: Color(0xFFF8E5ED),
    high: Color(0xFFEAC8D6),
    highest: Color(0xFFE3BACC),
    hair: Color(0xFFDFB9C9),
    outline: Color(0xFF785464),
    ink: Color(0xFF210D16),
    muted: Color(0xFF563443),
    primary: Color(0xFFC00C5A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF9B4D2),
    onPrimaryContainer: Color(0xFF3D051D),
    secondary: Color(0xFF0B7E89),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFBDF5FA),
    onSecondaryContainer: Color(0xFF05393D),
    tertiary: Color(0xFF936915),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF8E7C3),
    onTertiaryContainer: Color(0xFF3C2A07),
    inverse: Color(0xFF381E2A),
    onInverse: Color(0xFFF9ECF1),
    inversePrimary: Color(0xFFF986B8),
  );

  static const _roseDark = FamilyTokens(
    ground: Color(0xFF1E0D15),
    lowest: Color(0xFF15090F),
    card: Color(0xFF2A161F),
    sheet: Color(0xFF301A23),
    field: Color(0xFF301A23),
    high: Color(0xFF3A222C),
    highest: Color(0xFF462B36),
    hair: Color(0xFF4B303B),
    outline: Color(0xFFA18792),
    ink: Color(0xFFF2E3EA),
    muted: Color(0xFFC9B1BB),
    primary: Color(0xFFF976AF),
    onPrimary: Color(0xFF3A031B),
    primaryContainer: Color(0xFF6E1C3F),
    onPrimaryContainer: Color(0xFFFBCBE0),
    secondary: Color(0xFF7BEAF4),
    onSecondary: Color(0xFF03363A),
    secondaryContainer: Color(0xFF1E6167),
    onSecondaryContainer: Color(0xFFCDF6F9),
    tertiary: Color(0xFFF2CE88),
    onTertiary: Color(0xFF3A2803),
    tertiaryContainer: Color(0xFF675022),
    onTertiaryContainer: Color(0xFFF9EACD),
    inverse: Color(0xFFF2E3EA),
    onInverse: Color(0xFF210D16),
    inversePrimary: Color(0xFFC00C5A),
  );

  // ── Mandalina (canlı, 2026-11-06) ──
  static const _tangerineLight = FamilyTokens(
    ground: Color(0xFFF7DCCD),
    lowest: Color(0xFFFDFBF9),
    card: Color(0xFFFDFBF9),
    sheet: Color(0xFFFBF5F1),
    field: Color(0xFFF8ECE5),
    high: Color(0xFFEAD4C8),
    highest: Color(0xFFE3C9BA),
    hair: Color(0xFFDFC7B9),
    outline: Color(0xFF786154),
    ink: Color(0xFF21140D),
    muted: Color(0xFF564034),
    primary: Color(0xFFC04E0C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF9CDB4),
    onPrimaryContainer: Color(0xFF3D1A05),
    secondary: Color(0xFF0F66BD),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFBDDBFA),
    onSecondaryContainer: Color(0xFF05213D),
    tertiary: Color(0xFFB31966),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF8C3DE),
    onTertiaryContainer: Color(0xFF3C0721),
    inverse: Color(0xFF38281E),
    onInverse: Color(0xFFF9F1EC),
    inversePrimary: Color(0xFFF9B086),
  );

  static const _tangerineDark = FamilyTokens(
    ground: Color(0xFF1E130D),
    lowest: Color(0xFF150E09),
    card: Color(0xFF2A1D16),
    sheet: Color(0xFF30221A),
    field: Color(0xFF30221A),
    high: Color(0xFF3A2B22),
    highest: Color(0xFF46352B),
    hair: Color(0xFF4B3A30),
    outline: Color(0xFFA19087),
    ink: Color(0xFFF2E9E3),
    muted: Color(0xFFC9BAB1),
    primary: Color(0xFFF9A676),
    onPrimary: Color(0xFF3A1703),
    primaryContainer: Color(0xFF6E3A1C),
    onPrimaryContainer: Color(0xFFFBDDCB),
    secondary: Color(0xFF7BB8F4),
    onSecondary: Color(0xFF031F3A),
    secondaryContainer: Color(0xFF1E4267),
    onSecondaryContainer: Color(0xFFCDE3F9),
    tertiary: Color(0xFFF288BD),
    onTertiary: Color(0xFF3A031F),
    tertiaryContainer: Color(0xFF672245),
    onTertiaryContainer: Color(0xFFF9CDE3),
    inverse: Color(0xFFF2E9E3),
    onInverse: Color(0xFF21140D),
    inversePrimary: Color(0xFFC04E0C),
  );

  // ── Zümrüt (canlı, 2026-11-06) ──
  static const _emeraldLight = FamilyTokens(
    ground: Color(0xFFCDF7E5),
    lowest: Color(0xFFF9FDFC),
    card: Color(0xFFF9FDFC),
    sheet: Color(0xFFF1FBF7),
    field: Color(0xFFE5F8F0),
    high: Color(0xFFC8EADC),
    highest: Color(0xFFBAE3D2),
    hair: Color(0xFFB9DFCF),
    outline: Color(0xFF547869),
    ink: Color(0xFF0D2119),
    muted: Color(0xFF345648),
    primary: Color(0xFF08814F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB4F9DC),
    onPrimaryContainer: Color(0xFF053D26),
    secondary: Color(0xFFBD0F66),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFABDDB),
    onSecondaryContainer: Color(0xFF3D0521),
    tertiary: Color(0xFF1959B3),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC3D9F8),
    onTertiaryContainer: Color(0xFF071D3C),
    inverse: Color(0xFF1E382E),
    onInverse: Color(0xFFECF9F3),
    inversePrimary: Color(0xFF86F9C9),
  );

  static const _emeraldDark = FamilyTokens(
    ground: Color(0xFF0D1E17),
    lowest: Color(0xFF091510),
    card: Color(0xFF162A22),
    sheet: Color(0xFF1A3027),
    field: Color(0xFF1A3027),
    high: Color(0xFF223A30),
    highest: Color(0xFF2B463A),
    hair: Color(0xFF304B3F),
    outline: Color(0xFF87A196),
    ink: Color(0xFFE3F2EC),
    muted: Color(0xFFB1C9BF),
    primary: Color(0xFF76F9C3),
    onPrimary: Color(0xFF033A23),
    primaryContainer: Color(0xFF1C6E4C),
    onPrimaryContainer: Color(0xFFCBFBE7),
    secondary: Color(0xFFF47BB8),
    onSecondary: Color(0xFF3A031F),
    secondaryContainer: Color(0xFF671E42),
    onSecondaryContainer: Color(0xFFF9CDE3),
    tertiary: Color(0xFF88B4F2),
    onTertiary: Color(0xFF031A3A),
    tertiaryContainer: Color(0xFF223F67),
    onTertiaryContainer: Color(0xFFCDDFF9),
    inverse: Color(0xFFE3F2EC),
    onInverse: Color(0xFF0D2119),
    inversePrimary: Color(0xFF08814F),
  );

  // ── Ametist (canlı, 2026-11-06) ──
  static const _amethystLight = FamilyTokens(
    ground: Color(0xFFE3CDF7),
    lowest: Color(0xFFFBF9FD),
    card: Color(0xFFFBF9FD),
    sheet: Color(0xFFF6F1FB),
    field: Color(0xFFEFE5F8),
    high: Color(0xFFDAC8EA),
    highest: Color(0xFFD0BAE3),
    hair: Color(0xFFCDB9DF),
    outline: Color(0xFF675478),
    ink: Color(0xFF180D21),
    muted: Color(0xFF463456),
    primary: Color(0xFF6C0CC0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD9B4F9),
    onPrimaryContainer: Color(0xFF23053D),
    secondary: Color(0xFF0A7F62),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFBDFAEA),
    onSecondaryContainer: Color(0xFF053D2F),
    tertiary: Color(0xFFB34D19),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF8D5C3),
    onTertiaryContainer: Color(0xFF3C1807),
    inverse: Color(0xFF2C1E38),
    onInverse: Color(0xFFF3ECF9),
    inversePrimary: Color(0xFFC386F9),
  );

  static const _amethystDark = FamilyTokens(
    ground: Color(0xFF160D1E),
    lowest: Color(0xFF100915),
    card: Color(0xFF21162A),
    sheet: Color(0xFF261A30),
    field: Color(0xFF261A30),
    high: Color(0xFF2F223A),
    highest: Color(0xFF392B46),
    hair: Color(0xFF3E304B),
    outline: Color(0xFF9587A1),
    ink: Color(0xFFEBE3F2),
    muted: Color(0xFFBDB1C9),
    primary: Color(0xFFBC76F9),
    onPrimary: Color(0xFF20033A),
    primaryContainer: Color(0xFF481C6E),
    onPrimaryContainer: Color(0xFFE5CBFB),
    secondary: Color(0xFF7BF4D6),
    onSecondary: Color(0xFF033A2C),
    secondaryContainer: Color(0xFF1E6755),
    onSecondaryContainer: Color(0xFFCDF9EE),
    tertiary: Color(0xFFF2AB88),
    onTertiary: Color(0xFF3A1503),
    tertiaryContainer: Color(0xFF673922),
    onTertiaryContainer: Color(0xFFF9DBCD),
    inverse: Color(0xFFEBE3F2),
    onInverse: Color(0xFF180D21),
    inversePrimary: Color(0xFF6C0CC0),
  );
}
