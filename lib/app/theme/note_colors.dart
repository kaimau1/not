import 'package:flutter/material.dart';

import '../../core/utils/color_contrast.dart';
import '../../features/notes/domain/note.dart';
import 'app_theme.dart';
import 'app_tokens.dart';
import 'note_themes.dart';

/// Not renk belirteçlerini temaya (açık/koyu) uygun gerçek renklere çözer.
abstract final class NoteColors {
  /// **İNCELTİLMİŞ KEEP** (TEMA_PLANI K5, 2026-11-04). Tonlar ve sıra Keep'in
  /// paletiyle aynı (kullanıcı isteği: "palet Keep tonlarına dönsün"); yalnız
  /// PARLAKLIKLAR eşitlendi (OKLCH L 0,88–0,94). Keep'in kendi değerlerinde
  /// şeftali 0,78, bal 0,97'ydi — ızgarada bazı kartlar bağırıyor, bazıları
  /// zeminde kayboluyordu. Pembe mercandan ayrışsın diye pembeye kaydırıldı.
  /// Koyu temada ayrı küme: açık tonları karartmak gri ve bulanık sonuç
  /// veriyordu.
  static const _light = <NoteColor, Color>{
    NoteColor.red: Color(0xFFFFD2CD),
    NoteColor.peach: Color(0xFFFFD8BD),
    NoteColor.amber: Color(0xFFF7EAB9),
    NoteColor.green: Color(0xFFD8EECD),
    NoteColor.sage: Color(0xFFC4E9DE),
    NoteColor.blue: Color(0xFFD1E7F4),
    NoteColor.storm: Color(0xFFC0DBE9),
    NoteColor.purple: Color(0xFFE5D5F2),
    NoteColor.blossom: Color(0xFFFADFE0),
    NoteColor.clay: Color(0xFFE9E0D1),
    NoteColor.chalk: Color(0xFFE7EAED),
  };

  static const _dark = <NoteColor, Color>{
    NoteColor.red: Color(0xFF502825),
    NoteColor.peach: Color(0xFF4D2C15),
    NoteColor.amber: Color(0xFF41340A),
    NoteColor.green: Color(0xFF273C23),
    NoteColor.sage: Color(0xFF193D34),
    NoteColor.blue: Color(0xFF1B394C),
    NoteColor.storm: Color(0xFF233845),
    NoteColor.purple: Color(0xFF3C2E4C),
    NoteColor.blossom: Color(0xFF4A2A37),
    NoteColor.clay: Color(0xFF3E3327),
    NoteColor.chalk: Color(0xFF343539),
  };

  /// Her rengin KENDİ koyu tonu (koyu temada açık tonu): renkli kartta
  /// etiket hapı, kutucuk, ilerleme çubuğu, çerçeve ve defter çizgisi bu
  /// tondan çizilir — bugüne dek hepsi griydi. Kendi zemininde ≥ 4,5:1.
  static const _lightInk = <NoteColor, Color>{
    NoteColor.red: Color(0xFF923B33),
    NoteColor.peach: Color(0xFF944E21),
    NoteColor.amber: Color(0xFF7B5F06),
    NoteColor.green: Color(0xFF446630),
    NoteColor.sage: Color(0xFF246556),
    NoteColor.blue: Color(0xFF285D80),
    NoteColor.storm: Color(0xFF2F586F),
    NoteColor.purple: Color(0xFF624581),
    NoteColor.blossom: Color(0xFF8C4061),
    NoteColor.clay: Color(0xFF6D5640),
    NoteColor.chalk: Color(0xFF50565E),
  };

  static const _darkInk = <NoteColor, Color>{
    NoteColor.red: Color(0xFFFFBDB7),
    NoteColor.peach: Color(0xFFFBC49F),
    NoteColor.amber: Color(0xFFE5CF94),
    NoteColor.green: Color(0xFFB6DEAD),
    NoteColor.sage: Color(0xFF9EE1CE),
    NoteColor.blue: Color(0xFFA1D9FF),
    NoteColor.storm: Color(0xFFACD8F3),
    NoteColor.purple: Color(0xFFDDC4FC),
    NoteColor.blossom: Color(0xFFFCBCD4),
    NoteColor.clay: Color(0xFFE5CDB2),
    NoteColor.chalk: Color(0xFFCAD1DD),
  };

  /// Okunur sayılan en düşük yazı/zemin kontrastı (WCAG AA, gövde metni).
  static const double minTextContrast = 4.5;

  @visibleForTesting
  static Map<NoteColor, Color> palette({required bool dark}) =>
      dark ? _dark : _light;

  @visibleForTesting
  static Map<NoteColor, Color> inkPalette({required bool dark}) =>
      dark ? _darkInk : _lightInk;

  /// Kart/editör arka planı. [NoteColor.none] için temanın kâğıt rengi.
  static Color surface(BuildContext context, NoteColor color) =>
      surfaceIn(Theme.of(context), color);

  static Color surfaceIn(ThemeData theme, NoteColor color) {
    if (color == NoteColor.none) return AppTokens.fromTheme(theme).card;
    final map = theme.brightness == Brightness.dark ? _dark : _light;
    return map[color] ?? AppTokens.fromTheme(theme).card;
  }

  /// Hazır rengin koyu tonu; [NoteColor.none] için null (renksiz kart
  /// temanın vurgusunu kullanır).
  static Color? ink(BuildContext context, NoteColor color) {
    if (color == NoteColor.none) return null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return (dark ? _darkInk : _lightInk)[color];
  }

  /// Notun koyu tonu: hazır renkte paletten, özel renkte rengin kendisinden
  /// zemine göre okunur hâle getirilerek; renksiz ya da temalı notta null.
  static Color? noteInk(BuildContext context, Note note) {
    if (NoteThemes.byId(note.theme) != null) return null;
    final custom = note.customColor;
    if (custom != null) {
      return readableOn(
        Color(custom).withAlpha(255),
        noteSurface(context, note),
      );
    }
    return ink(context, note.color);
  }

  /// Mercan koyusu: defter kâğıdının kenar çizgisi (eskiden hata rengi
  /// `scheme.error` — anlamı "hata" olan renk kâğıtta durmasın).
  static Color marginInk(BuildContext context) =>
      marginInkFor(dark: Theme.of(context).brightness == Brightness.dark);

  static Color marginInkFor({required bool dark}) =>
      (dark ? _darkInk : _lightInk)[NoteColor.red]!;

  /// Notun GERÇEK zemini: çizilmiş tema → temanın alt tonu; paletten özel
  /// renk → [customSurface]; yoksa hazır ton ([surface]).
  static Color noteSurface(BuildContext context, Note note) =>
      noteSurfaceIn(Theme.of(context), note);

  static Color noteSurfaceIn(ThemeData theme, Note note) {
    // Çizilmiş tema rengin önünde: notun düz zemini temanın alt tonu.
    final noteTheme = NoteThemes.byId(note.theme);
    if (noteTheme != null) {
      return noteTheme.palette(theme.brightness == Brightness.dark).base;
    }
    final custom = note.customColor;
    if (custom == null) return surfaceIn(theme, note.color);
    return customSurface(theme, Color(custom));
  }

  static final Map<(int, Brightness, ThemeFamilyKey), Color> _customCache = {};

  /// **ÖZEL RENGİN ZEMİNİ — OKUNURLUK** (kullanıcı bulgusu 2026-11-04: "not
  /// arka plan rengini değiştirince bazen yazı rengi sabit kaldığı için okuma
  /// zorluğu oluyor").
  ///
  /// KÖK NEDEN: özel renk kâğıda sabit oranda (açıkta %55, koyuda %35)
  /// karıştırılıyor, yazı ise HEP temanın mürekkebinde kalıyordu. Koyu bir
  /// renk (lacivert, siyah, koyu yeşil) açık temada gri-orta bir zemin
  /// veriyordu: koyu yazı da açık yazı da 3:1'in altında.
  ///
  /// Kural: (1) karışım temanın yazısıyla ≥ 4,5 ise aynen; (2) kullanıcı
  /// temanın TERSİ bir renk seçtiyse (açıkta çok koyu, koyuda çok açık) rengin
  /// kendisi korunur, yazı ZIT temadan gelir (bkz. [inkThemeFor]) — rengi
  /// yeterince koyu/açık olana dek ayarlanır; (3) değilse karışım kâğıda doğru
  /// açılır (koyuda koyulaşır) — yazı temanın kalır.
  static Color customSurface(ThemeData theme, Color custom) {
    final key = (
      custom.toARGB32(),
      theme.brightness,
      ThemeFamilyKey(AppTokens.fromTheme(theme)),
    );
    final hit = _customCache[key];
    if (hit != null) return hit;
    if (_customCache.length > 256) _customCache.clear();
    return _customCache[key] = _customSurfaceUncached(theme, custom);
  }

  static Color _customSurfaceUncached(ThemeData theme, Color custom) {
    final dark = theme.brightness == Brightness.dark;
    final solid = custom.withAlpha(255);
    final base = AppTokens.fromTheme(theme).card;
    final ink = theme.colorScheme.onSurface;
    Color blend(double a, Color over) =>
        Color.alphaBlend(solid.withValues(alpha: a), over);
    final start = dark ? 0.35 : 0.55;
    final first = blend(start, base);
    if (contrast(ink, first) >= minTextContrast) return first;
    final lum = solid.computeLuminance();
    final opposite = dark ? lum > 0.45 : lum < 0.06;
    if (opposite) {
      final opp = AppTheme.opposite(theme);
      final oppInk = opp.colorScheme.onSurface;
      final oppBase = AppTokens.fromTheme(opp).card;
      for (var a = 0.9; a > 0; a -= 0.05) {
        final c = blend(a, oppBase);
        if (contrast(oppInk, c) >= minTextContrast) return c;
      }
      return oppBase;
    }
    for (var a = start - 0.05; a > 0; a -= 0.05) {
      final c = blend(a, base);
      if (contrast(ink, c) >= minTextContrast) return c;
    }
    return base;
  }

  /// [background] üstünde [theme]'in yazısı okunmuyorsa ZIT parlaklıktaki
  /// aynı tema (aynı aile + yazı tipi, önbellekten — yeni tema kurulmaz);
  /// okunuyorsa null. Editör ve kart bu temayla çizilir: yazı, simge, imleç,
  /// kutucuk hepsi zemine göre döner.
  static ThemeData? inkThemeFor(ThemeData theme, Color background) {
    final own = contrast(theme.colorScheme.onSurface, background);
    if (own >= minTextContrast) return null;
    final opp = AppTheme.opposite(theme);
    return contrast(opp.colorScheme.onSurface, background) > own ? opp : null;
  }

  /// WCAG 2.1 kontrast oranı (1–21).
  static double contrast(Color a, Color b) => contrastRatio(a, b);

  /// Kart çerçevesinin rengi (özel renk önce); çerçeve yoksa null. Hazır
  /// renkte rengin KOYU tonu (dolgu tonu ince halkada seçilmiyordu).
  static Color? noteFrame(Note note, {bool dark = false}) {
    final custom = note.customFrameColor;
    if (custom != null) return Color(custom);
    if (note.frameColor == NoteColor.none) return null;
    return (dark ? _darkInk : _lightInk)[note.frameColor];
  }

  /// Satır içi biçimlendirmenin renk paleti: metindeki `==2:...==` /
  /// `%%2:...%%` işaretlerindeki 1..5 indeksinin karşılığı. Yazı rengi
  /// olarak kullanılırken zemine göre okunur hâle getirilir
  /// (`readableOn`, `RichTextTheme.background`).
  static List<Color> get richPalette => const [
    Color(0xFFE57373),
    Color(0xFFFFC94D),
    Color(0xFF81C784),
    Color(0xFF64A5F5),
    Color(0xFFB39DDB),
  ];

  /// Renk seçicideki nokta rengi. Zeminin KENDİSİ gösterilir: kullanıcı
  /// noktaya bakınca sayfanın ne renk olacağını görür (Keep de böyle).
  /// [NoteColor.none] için tema yüzeyi kullanılamaz (bağlam yok), nötr gri.
  static Color swatch(NoteColor color) => color == NoteColor.none
      ? const Color(0xFF9E9E9E)
      : (_light[color] ?? const Color(0xFF9E9E9E));
}

/// Önbellek anahtarı: aynı ailenin aynı parlaklığı aynı sonucu verir.
@immutable
class ThemeFamilyKey {
  ThemeFamilyKey(AppTokens tokens)
    : family = tokens.family.index,
      card = tokens.card.toARGB32();

  final int family;
  final int card;

  @override
  bool operator ==(Object other) =>
      other is ThemeFamilyKey && other.family == family && other.card == card;

  @override
  int get hashCode => Object.hash(family, card);
}

/// **NOTUN VURGUSU — KART VE AÇIK NOT AYNI** (kullanıcı bulgusu 2026-11-04,
/// ekran görüntüleriyle: "notun açık hali ile dashboarddaki görüntüsü
/// farklı"). KÖK NEDEN: TEMA_PLANI F31.3 kartta kutucuk, etiket, klasör ve
/// raptiyeyi notun KENDİ koyu tonuyla ([NoteColors.noteInk]) çizdi; editör
/// aynı öğeleri temanın vurgusuyla (`primary`) çizmeye devam etti — koyu
/// pembe bir notta kart pembe, açık not petrol yeşili kutucuk gösteriyordu.
///
/// Kural tek: [accent] renkli notta notun koyu tonu, renksiz/temalı notta
/// null (temanın rengi). Kart ve editör bu sarmalayıcıyı DIŞ temadan
/// hesaplanmış değerle kurar (zıt okunurluk teması içeride yanlış zemin
/// hesaplardı). Kutucuk renkleri [NoteCheckColors]'tan okunur; etiket,
/// klasör ve hatırlatıcı hapları yazı + çerçeve olarak [accent]'ten.
class NoteAccent extends InheritedWidget {
  const NoteAccent({
    super.key,
    required this.accent,
    required this.background,
    required super.child,
  });

  /// Notun koyu tonu; null = renksiz not (temanın vurgusu).
  final Color? accent;

  /// Notun gerçek zemini ([NoteColors.noteSurface]).
  final Color background;

  static NoteAccent? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NoteAccent>();

  @override
  bool updateShouldNotify(NoteAccent oldWidget) =>
      oldWidget.accent != accent || oldWidget.background != background;
}

/// Madde kutucuğunun renkleri — kartta ve editörde AYNI kural (bkz.
/// [NoteAccent]). İşaretli kutu notun vurgusuyla DOLU ve soluk (üstü çizili
/// yazıyla aynı oran), boş kutu ince çerçeve.
abstract final class NoteCheckColors {
  /// İşaretli maddenin soluklaştırma oranı (yazı ve kutu birlikte; F15.6:
  /// 0,55'te üstü çizili yazı açık temada 2,8:1'e düşüyordu).
  static const double checkedDim = 0.8;

  /// İşaretli kutunun dolgusu (soluk hâli dahil).
  static Color checked(ColorScheme scheme, Color? accent) {
    final c = accent ?? scheme.primary;
    return c.withValues(alpha: c.a * checkedDim);
  }

  /// Boş kutunun çerçevesi.
  static Color unchecked(ColorScheme scheme, Color? accent) =>
      accent ?? scheme.onSurfaceVariant;

  /// İşaretin (✓) rengi: dolgunun üstünde zemin rengi — kartın simgesindeki
  /// "oyuk" onay işaretiyle aynı görünüm. Renksiz notta temanın `onPrimary`.
  static Color mark(ColorScheme scheme, Color? accent, Color background) =>
      accent == null ? scheme.onPrimary : background;
}

/// [background] üstündeki içeriği okunur temayla çizer: zemin temanın
/// yazısıyla okunmuyorsa ([NoteColors.inkThemeFor]) çocuk ZIT temada kurulur.
/// Gerekmiyorsa çocuk olduğu gibi döner (ek katman yok — ızgarada onlarca
/// kart var).
class NoteInkScope extends StatelessWidget {
  const NoteInkScope({
    super.key,
    required this.background,
    required this.child,
  });

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ink = NoteColors.inkThemeFor(Theme.of(context), background);
    if (ink == null) return child;
    // Renksiz `Text` üstteki Material'ın yazı stilini miras alır (o dış
    // temada kalır) — yazı rengi de burada çevrilir.
    return Theme(
      data: ink,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: ink.colorScheme.onSurface),
        child: child,
      ),
    );
  }
}
