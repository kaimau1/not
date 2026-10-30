import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Yazı tipi katalogu: hem UYGULAMANIN genel yazı tipi (Ayarlar → Görünüm)
/// hem de NOTUN kendi yazı tipi (biçim şeridi) buradan beslenir.
///
/// İki kaynak var: sistemin GENEL aileleri (`serif`, `monospace`) ve Google
/// Fonts katalogu. Katalogdaki her yazı tipinin dosyaları APK'ya GÖMÜLÜ
/// (`assets/google_fonts/`), yani seçim çevrimdışı da, ilk açılışta da
/// çalışır ve her telefonda AYNI görünür — indirme yolu tamamen kapandı
/// (bkz. pubspec'teki gerekçe ve `test/font_catalog_test.dart`).
///
/// Liste KARAKTER OLARAK AYRIK tutuldu: her ailenin bir işi var (sistem
/// arayüzü, kitap, ekran/başlık, daktilo, el yazısı); birbirinin kopyası iki
/// yazı tipi eklemek seçimi zorlaştırmaktan başka işe yaramaz.
/// Katalog yazı tiplerinin öbeği. Seçici uzun bir liste yerine öbek öbek
/// gösterir: 19 ad tek yığın hâlinde okunmuyordu ("ayarlarda font seçimi çok
/// dağınık"), oysa kullanıcı zaten "sade mi, kitap mı, daktilo mu, el yazısı
/// mı" diye seçiyor.
enum NoteFontGroup { sans, serif, mono, hand }

@immutable
class NoteFontOption {
  const NoteFontOption(
    this.id,
    this.label, {
    this.google = false,
    this.group = NoteFontGroup.sans,
  });

  /// Seçicideki öbeği (yalnız katalog yazı tipleri için anlamlı).
  final NoteFontGroup group;

  /// Nota yazılan değer. null = uygulamanın varsayılan tipografisi.
  final String? id;

  /// Seçicide görünen ad. Katalog yazı tiplerinde yazı tipinin KENDİ adıdır
  /// (çeviri gerektirmez ve kullanıcı adı tanır).
  final String label;

  /// true: Google Fonts katalogundan; false: sistemin genel ailesi.
  final bool google;
}

/// Gömülü katalog yazı tipleri (uygulama geneli ve not başına ORTAK).
///
/// Sıra bilinçli: önce arayüz/gövde için sade sans'lar, sonra kitap serif'i,
/// sonra daktilo ve en sonda el yazısı. Yeni bir yazı tipi eklerken üç yer
/// birlikte güncellenmeli — bu liste, [_googleBuilders], [_googleTextThemes]
/// ve dosyaların kendisi (`assets/google_fonts/`); test dördünün örtüştüğünü
/// doğrular.
const List<NoteFontOption> kCatalogFonts = [
  NoteFontOption('Inter Tight', 'Inter Tight', google: true),
  NoteFontOption('Roboto', 'Roboto', google: true),
  NoteFontOption('Open Sans', 'Open Sans', google: true),
  NoteFontOption('Lato', 'Lato', google: true),
  NoteFontOption('Source Sans 3', 'Source Sans', google: true),
  NoteFontOption('Work Sans', 'Work Sans', google: true),
  NoteFontOption('Rubik', 'Rubik', google: true),
  NoteFontOption('Nunito', 'Nunito', google: true),
  NoteFontOption('Montserrat', 'Montserrat', google: true),
  NoteFontOption('Poppins', 'Poppins', google: true),
  NoteFontOption('Lora', 'Lora', google: true, group: NoteFontGroup.serif),
  NoteFontOption(
    'Merriweather',
    'Merriweather',
    google: true,
    group: NoteFontGroup.serif,
  ),
  NoteFontOption(
    'PT Serif',
    'PT Serif',
    google: true,
    group: NoteFontGroup.serif,
  ),
  NoteFontOption(
    'EB Garamond',
    'EB Garamond',
    google: true,
    group: NoteFontGroup.serif,
  ),
  NoteFontOption(
    'Playfair Display',
    'Playfair',
    google: true,
    group: NoteFontGroup.serif,
  ),
  NoteFontOption(
    'Roboto Mono',
    'Roboto Mono',
    google: true,
    group: NoteFontGroup.mono,
  ),
  NoteFontOption(
    'JetBrains Mono',
    'JetBrains Mono',
    google: true,
    group: NoteFontGroup.mono,
  ),
  NoteFontOption('Caveat', 'Caveat', google: true, group: NoteFontGroup.hand),
  NoteFontOption(
    'Patrick Hand',
    'Patrick Hand',
    google: true,
    group: NoteFontGroup.hand,
  ),
];

/// Notun yazı tipi seçenekleri: varsayılan + iki sistem ailesi + katalog.
const List<NoteFontOption> kNoteFonts = [
  NoteFontOption(null, 'Varsayılan'),
  NoteFontOption('serif', 'Kitap'),
  NoteFontOption('monospace', 'Daktilo'),
  ...kCatalogFonts,
];

/// [family] yazı tipini [base] stiline uygular.
///
/// Bilinmeyen ya da indirilemeyen bir ad geldiğinde stil DEĞİŞMEDEN döner:
/// eski bir notta duran ya da elle bozulmuş bir değer metni yok etmemeli.
///
/// TUZAK — **`GoogleFonts.getFont(ad)` KULLANILMAZ**: ada göre arama, paketin
/// bin beş yüzü aşkın yazı tipini tanımlayan kataloğunu derlemeye sokar ve
/// ağaç budama onu atamaz. Ölçüldü: APK 59,4 MB → 67,4 MB (v1.0.167).
/// Yazı tipleri BURADA tek tek, adıyla çağrılır; kullanılmayan katalog
/// derlemeye hiç girmez. Yeni bir yazı tipi eklerken hem [kNoteFonts]'a hem
/// buraya satır eklenmeli — ikisi ayrışırsa seçenek listede görünür ama
/// varsayılanla çizilir.
/// Uygulanmış yazı tiplerinin sınırlı önbelleği.
///
/// KÖK NEDEN (kasma): ana ekranda önbellek payı ~130 kartı canlı tutuyor ve
/// her kart bu işlevi en az iki kez (gövde + başlık) çağırıyor; her çağrı bir
/// katalog araması ve yeni bir [TextStyle] demek. Girdi çifti (taban stil +
/// aile) kartlar arasında neredeyse hep AYNI.
const _fontCacheLimit = 128;
final Map<(TextStyle, String), TextStyle> _fontCache = {};

TextStyle applyNoteFont(TextStyle base, String? family) {
  if (family == null || family.isEmpty) return base;
  if (family == 'serif' || family == 'monospace') {
    return base.copyWith(fontFamily: family);
  }
  final key = (base, family);
  final cached = _fontCache[key];
  if (cached != null) return cached;
  final builder = _googleBuilders[family];
  final applied = builder == null ? base : builder(base);
  if (_fontCache.length >= _fontCacheLimit) _fontCache.clear();
  _fontCache[key] = applied;
  return applied;
}

/// Katalog yazı tiplerini (normal + orta kalınlık) ÖNDEN yükler.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-30: "yazı tipi değiştiğinde kasma
/// oluyor"): gömülü yazı tipi ilk KULLANILDIĞI an yükleniyor ve her yükleme
/// motora "yazı tipleri değişti" dedirtiyor — çerçeve o anda ekrandaki
/// BÜTÜN metni yeniden yerleştiriyor (uzun notta yüzlerce paragraf). Seçici
/// tepsisi kaydırılırken her yeni önizleme, seçimde de kalın dosyası ayrıca
/// bir kez daha. Yükleme ilk kareden ÖNCE biterse yerleştirilecek metin
/// henüz yoktur, bedel sıfırdır. Hata sessiz (yazı tipi kullanımda yine
/// yüklenmeye çalışılır).
Future<void> preloadNoteFonts() async {
  try {
    for (final builder in _googleBuilders.values) {
      builder(const TextStyle());
      builder(const TextStyle(fontWeight: FontWeight.w500));
    }
    await GoogleFonts.pendingFonts();
  } catch (_) {}
}

/// Notun şeffaflık ayarını [base] stiline uygular.
///
/// Rengi olmayan stiller temadan besleniyor; opaklık verilebilmesi için renk
/// BURADA somutlaşır ([fallback] ile). 1 (tam koyu) hiçbir şey değiştirmez —
/// eski notlar bir kıl bile kaymasın.
TextStyle applyNoteOpacity(TextStyle base, double opacity, Color fallback) {
  if (opacity >= 1) return base;
  final color = base.color ?? fallback;
  return base.copyWith(color: color.withValues(alpha: opacity.clamp(0.1, 1)));
}

/// Katalog yazı tiplerinin TEK STİL çağrıları (not metni, seçici satırları).
/// Her biri doğrudan adıyla yazılır; böylece derleyici yalnız bunları tutar
/// (bkz. yukarıdaki tuzak).
final Map<String, TextStyle Function(TextStyle)> _googleBuilders = {
  'Inter Tight': (base) => GoogleFonts.interTight(textStyle: base),
  'Roboto': (base) => GoogleFonts.roboto(textStyle: base),
  'Open Sans': (base) => GoogleFonts.openSans(textStyle: base),
  'Lato': (base) => GoogleFonts.lato(textStyle: base),
  'Source Sans 3': (base) => GoogleFonts.sourceSans3(textStyle: base),
  'Work Sans': (base) => GoogleFonts.workSans(textStyle: base),
  'Rubik': (base) => GoogleFonts.rubik(textStyle: base),
  'Nunito': (base) => GoogleFonts.nunito(textStyle: base),
  'Montserrat': (base) => GoogleFonts.montserrat(textStyle: base),
  'Poppins': (base) => GoogleFonts.poppins(textStyle: base),
  'Lora': (base) => GoogleFonts.lora(textStyle: base),
  'Merriweather': (base) => GoogleFonts.merriweather(textStyle: base),
  'PT Serif': (base) => GoogleFonts.ptSerif(textStyle: base),
  'EB Garamond': (base) => GoogleFonts.ebGaramond(textStyle: base),
  'Playfair Display': (base) => GoogleFonts.playfairDisplay(textStyle: base),
  'Roboto Mono': (base) => GoogleFonts.robotoMono(textStyle: base),
  'JetBrains Mono': (base) => GoogleFonts.jetBrainsMono(textStyle: base),
  'Caveat': (base) => GoogleFonts.caveat(textStyle: base),
  'Patrick Hand': (base) => GoogleFonts.patrickHand(textStyle: base),
};

/// Aynı yazı tiplerinin TÜM METİN TEMASI çağrıları — uygulamanın genel yazı
/// tipi ayarı (Ayarlar → Görünüm → Yazı tipi) bunu kullanır.
///
/// Ayrı bir harita gerekiyor: tek tek stil kurmak, temanın on beş metin
/// biçimini (başlık/gövde/etiket) elle dolaşmak demekti; paketin kendi
/// `...TextTheme` çağrısı bunu doğru harflerle ve doğru ağırlıklarla yapar.
final Map<String, TextTheme Function(TextTheme)> _googleTextThemes = {
  'Inter Tight': GoogleFonts.interTightTextTheme,
  'Roboto': GoogleFonts.robotoTextTheme,
  'Open Sans': GoogleFonts.openSansTextTheme,
  'Lato': GoogleFonts.latoTextTheme,
  'Source Sans 3': GoogleFonts.sourceSans3TextTheme,
  'Work Sans': GoogleFonts.workSansTextTheme,
  'Rubik': GoogleFonts.rubikTextTheme,
  'Nunito': GoogleFonts.nunitoTextTheme,
  'Montserrat': GoogleFonts.montserratTextTheme,
  'Poppins': GoogleFonts.poppinsTextTheme,
  'Lora': GoogleFonts.loraTextTheme,
  'Merriweather': GoogleFonts.merriweatherTextTheme,
  'PT Serif': GoogleFonts.ptSerifTextTheme,
  'EB Garamond': GoogleFonts.ebGaramondTextTheme,
  'Playfair Display': GoogleFonts.playfairDisplayTextTheme,
  'Roboto Mono': GoogleFonts.robotoMonoTextTheme,
  'JetBrains Mono': GoogleFonts.jetBrainsMonoTextTheme,
  'Caveat': GoogleFonts.caveatTextTheme,
  'Patrick Hand': GoogleFonts.patrickHandTextTheme,
};

/// Uygulamanın genel yazı tipi. [family] null / bilinmiyorsa varsayılan
/// ([kAppDefaultFont]) uygulanır — kayıtta bozuk bir ad kalsa bile uygulama
/// yazısız kalmaz.
TextTheme appFontTextTheme(TextTheme base, String? family) =>
    (_googleTextThemes[family] ?? _googleTextThemes[kAppDefaultFont]!)(base);

/// Uygulamanın varsayılan yazı tipi. Ayar hiç ellenmediğinde bu geçerlidir.
const String kAppDefaultFont = 'Inter Tight';

/// Çağrısı yazılmış katalog yazı tipleri. [kNoteFonts] ile bunun ayrışması,
/// seçeneğin listede görünüp varsayılanla çizilmesi demek olurdu; test bu iki
/// listenin örtüştüğünü doğrular (yazı tipini YÜKLEMEDEN — ağ gerekmez).
Set<String> get googleNoteFontIds => _googleBuilders.keys.toSet();

/// Metin teması çağrısı yazılmış yazı tipleri (aynı sebeple test edilir).
Set<String> get appFontIds => _googleTextThemes.keys.toSet();

/// Genel ailelerin etiketleri çeviriden gelir (bu katman l10n bilmez);
/// katalog yazı tipleri kendi adlarıyla görünür.
String noteFontLabel(
  String? family, {
  required String defaultLabel,
  required String serifLabel,
  required String monoLabel,
}) => switch (family) {
  null || '' => defaultLabel,
  'serif' => serifLabel,
  'monospace' => monoLabel,
  _ => family,
};
