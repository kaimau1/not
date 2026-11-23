import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_tokens.dart';
import 'font_downloads.dart';
import 'font_sources.dart';

/// Yazı tipi katalogu: hem UYGULAMANIN genel yazı tipi (Ayarlar → Görünüm)
/// hem de NOTUN kendi yazı tipi (biçim şeridi) buradan beslenir.
///
/// İki kaynak var: sistemin GENEL aileleri (`serif`, `monospace`) ve Google
/// Fonts katalogu. Katalogdan yalnız [kCoreFontIds] APK'ya GÖMÜLÜ
/// (`assets/google_fonts/`): varsayılan görünüm çevrimdışı da, ilk açılışta
/// da her telefonda AYNIdır. Kalan aileler (PL10, `font_downloads.dart`)
/// kullanıcı seçince BİR KEZ indirilir ve yerelde önbelleklenir; inene dek
/// varsayılan yazı tipi görünür. Çalışma anı indirmesi başka hiçbir yolda
/// yok (bkz. [disableFontRuntimeFetching], `test/font_runtime_fetch_test.dart`).
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

  /// Pakette değil, seçilince indirilen aile (seçicide bulut simgesi).
  bool get downloadable =>
      id != null && kDownloadableFontSources.containsKey(id);
}

/// APK'da gömülü kalan çekirdek aileler: varsayılan ([kAppDefaultFont]) ve
/// her öbekten (sade, kitap, daktilo, el yazısı) bir temsilci.
const Set<String> kCoreFontIds = {
  'Inter Tight',
  'Roboto',
  'Lora',
  'Roboto Mono',
  'Caveat',
};

/// Katalog yazı tipleri (uygulama geneli ve not başına ORTAK): çekirdek olanlar
/// gömülü, kalanı [NoteFontOption.downloadable].
///
/// Sıra bilinçli: önce arayüz/gövde için sade sans'lar, sonra kitap serif'i,
/// sonra daktilo ve en sonda el yazısı. Yeni bir yazı tipi eklerken üç yer
/// birlikte güncellenmeli — bu liste ile ÇEKİRDEK için [_googleBuilders],
/// [_googleTextThemes] ve dosyalar (`assets/google_fonts/`); indirilenler için
/// `font_sources.dart` (tool/gen_font_sources.py). Test bunların örtüştüğünü
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

TextStyle applyNoteFont(TextStyle base, String? family, {bool fetch = true}) {
  if (family == null || family.isEmpty) return base;
  if (family == 'serif' || family == 'monospace') {
    return base.copyWith(fontFamily: family);
  }
  // PL10: pakette olmayan aile. Bilinen ad hep KENDİ adıyla istenir, yedek
  // varsayılan yazı tipi; yüklenince motor yeniden dizer. [fetch] false:
  // yalnız önizleme (seçici satırları) — indirmeyi TETİKLEMEZ.
  if (kDownloadableFontSources.containsKey(family)) {
    if (fetch) fontDownloads.request(family);
    return _downloadedStyle(base, family);
  }
  final key = (base, family);
  final cached = _fontCache[key];
  if (cached != null) return cached;
  final builder = _googleBuilders[family];
  final weight = base.fontWeight;
  // Pakette aile başına yalnız 400/500 var (T3/K-54): GoogleFonts'a daha
  // kalını sorulursa o kesimi ARAR (indirme kapalı → hata, sistem yazı tipi).
  // 500'le yüklenir, kalınlık stilde kalır — motor kalınlaştırır (bugünkü
  // satır içi kalın metnin yolu).
  final applied = builder == null
      ? base
      : weight != null && weight.value > 500
      ? builder(base.copyWith(fontWeight: AppWeight.medium))
            .copyWith(fontWeight: weight)
      : builder(base);
  if (_fontCache.length >= _fontCacheLimit) _fontCache.clear();
  _fontCache[key] = applied;
  return applied;
}

/// İndirilen ailenin stili: kesim kalınlığa göre seçilir (500 yoksa 400, daha
/// kalını motor kalınlaştırır — gömülü ailelerle aynı). Yedek: varsayılan
/// yazı tipinin aynı kesimi; indirme bitene dek ya da çevrimdışıyken o görünür.
TextStyle _downloadedStyle(TextStyle base, String id) {
  final w = base.fontWeight?.value ?? 400;
  final has500 = kDownloadableFontSources[id]!.any((s) => s.weight == 500);
  final weight = w >= 500 && has500 ? 500 : 400;
  return base.copyWith(
    fontFamily: downloadedFontFamily(id, weight),
    fontFamilyFallback: _defaultFallback[weight] ??= [
      _googleBuilders[kAppDefaultFont]!(
        TextStyle(fontWeight: weight == 500 ? AppWeight.medium : null),
      ).fontFamily!,
    ],
  );
}

final Map<int, List<String>> _defaultFallback = {};

/// **ÇALIŞMA ANI İNDİRMESİ KAPALI** (T3 / K-54, 2026-11-17). `google_fonts`
/// pakette bulamadığı kesimi fonts.gstatic.com'dan indirir; gelince motor
/// "yazı tipleri değişti" der ve ekrandaki BÜTÜN metin yeniden dizilir,
/// çevrimdışıyken sessizce sistem yazı tipi çizilir. Kanıt: paket 8.x'te
/// Merriweather'ın 500 kesimi var ama dosyası pakette yoktu → her Merriweather
/// başlığı (w500) ağdan iniyordu. Uygulama GoogleFonts'a yalnız 400/500 sorar
/// ([applyNoteFont] kalını 500'e indirir; metin temaları ≤ 500), hepsi
/// `assets/google_fonts/`ta. PL10: paketten ÇIKARILAN aileler `google_fonts`
/// ile değil [FontDownloads] ile, yalnız kullanıcı seçince iner; paketin
/// indirmesi kapalı kalır. Bekçi: `test/font_runtime_fetch_test.dart`.
void disableFontRuntimeFetching() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Uygulamanın genel yazı tipini (temanın kullandığı kalınlıklarla) ÖNDEN
/// yükler; `main` ilk kareden önce en çok 400 ms bekler.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-30: "yazı tipi değiştiğinde kasma
/// oluyor"): gömülü yazı tipi ilk KULLANILDIĞI an yükleniyor ve her yükleme
/// motora "yazı tipleri değişti" dedirtiyor — çerçeve o anda ekrandaki BÜTÜN
/// metni yeniden yerleştiriyor. Yükleme ilk kareden ÖNCE biterse
/// yerleştirilecek metin henüz yoktur.
///
/// F25.1 (2026-11-04, telefonda ölçüldü): 19 ailenin hepsini açılışta yüklemek
/// 35 dosya / 5,2 MB'ı ana iş parçacığında açıp çözüyordu. Artık yalnız ana
/// ekranda görünen aile; kalanı seçici açılınca ([preloadRemainingNoteFonts]).
/// Seçicinin dışında başka aileyi yalnız o aileyi kullanan not ister: o da
/// ilk kullanımda bir kez yüklenir. Hata sessiz (kullanımda yine denenir).
Future<void> preloadNoteFonts(String? appFamily) async {
  try {
    appFontTextTheme(ThemeData().textTheme, appFamily);
    await GoogleFonts.pendingFonts();
  } catch (_) {}
}

bool _remainingFontsAsked = false;

/// Yazı tipi seçicisi açılınca: seçicinin satırları kendi aileleriyle çizilir;
/// kaydırılırken ayrı ayrı yüklenmesin (yukarıdaki kök neden), hepsi bir kez.
void preloadRemainingNoteFonts() {
  if (_remainingFontsAsked) return;
  _remainingFontsAsked = true;
  try {
    for (final builder in _googleBuilders.values) {
      builder(const TextStyle());
      builder(const TextStyle(fontWeight: FontWeight.w500));
    }
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
  'Lora': (base) => GoogleFonts.lora(textStyle: base),
  'Roboto Mono': (base) => GoogleFonts.robotoMono(textStyle: base),
  'Caveat': (base) => GoogleFonts.caveat(textStyle: base),
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
  'Lora': GoogleFonts.loraTextTheme,
  'Roboto Mono': GoogleFonts.robotoMonoTextTheme,
  'Caveat': GoogleFonts.caveatTextTheme,
};

/// Uygulamanın genel yazı tipi. [family] null / bilinmiyorsa varsayılan
/// ([kAppDefaultFont]) uygulanır — kayıtta bozuk bir ad kalsa bile uygulama
/// yazısız kalmaz. İndirilen ailede (PL10) metin biçimlerinin her biri aynı
/// kesim kuralıyla [_downloadedStyle]'dan geçer.
TextTheme appFontTextTheme(TextTheme base, String? family) {
  if (family != null && kDownloadableFontSources.containsKey(family)) {
    fontDownloads.request(family);
    TextStyle? m(TextStyle? s) =>
        s == null ? null : _downloadedStyle(s, family);
    return base.copyWith(
      displayLarge: m(base.displayLarge),
      displayMedium: m(base.displayMedium),
      displaySmall: m(base.displaySmall),
      headlineLarge: m(base.headlineLarge),
      headlineMedium: m(base.headlineMedium),
      headlineSmall: m(base.headlineSmall),
      titleLarge: m(base.titleLarge),
      titleMedium: m(base.titleMedium),
      titleSmall: m(base.titleSmall),
      bodyLarge: m(base.bodyLarge),
      bodyMedium: m(base.bodyMedium),
      bodySmall: m(base.bodySmall),
      labelLarge: m(base.labelLarge),
      labelMedium: m(base.labelMedium),
      labelSmall: m(base.labelSmall),
    );
  }
  return (_googleTextThemes[family] ?? _googleTextThemes[kAppDefaultFont]!)(
    base,
  );
}

/// Uygulamanın varsayılan yazı tipi. Ayar hiç ellenmediğinde bu geçerlidir.
const String kAppDefaultFont = 'Inter Tight';

/// Çağrısı yazılmış GÖMÜLÜ (çekirdek) yazı tipleri. [kCoreFontIds] ile bunun
/// ayrışması, seçeneğin listede görünüp varsayılanla çizilmesi demek olurdu;
/// test bu iki kümenin örtüştüğünü doğrular (yazı tipini YÜKLEMEDEN).
Set<String> get googleNoteFontIds => _googleBuilders.keys.toSet();

/// Uygulama yazı tipi olarak geçerli her ad: metin teması çağrısı yazılmış
/// çekirdek aileler + indirilebilir aileler (aynı sebeple test edilir).
Set<String> get appFontIds => {
  ..._googleTextThemes.keys,
  ...kDownloadableFontSources.keys,
};

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
