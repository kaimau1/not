import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Notun kendi yazı tipi seçenekleri.
///
/// İki kaynak var: sistemin GENEL aileleri (`serif`, `monospace`) ve Google
/// Fonts katalogu. Genel aileler her koşulda çalışır — çevrimdışı bile;
/// katalog yazı tipleri ilk kullanımda indirilir ve önbelleğe alınır.
/// Uygulamanın kendi tipografisi zaten aynı yolla geliyor (bkz. app_theme:
/// `GoogleFonts.interTightTextTheme`), yani yeni bir bağımlılık ya da yeni bir
/// çevrimdışı riski doğmuyor: indirilemeyen yazı tipinde metin varsayılanla
/// çizilir, içerik kaybı olmaz.
///
/// Liste bilerek kısa ve KARAKTER OLARAK AYRIK tutuldu; birbirine benzeyen on
/// yazı tipi arasından seçmek, üç seçenekten seçmekten daha zor.
@immutable
class NoteFontOption {
  const NoteFontOption(this.id, this.label, {this.google = false});

  /// Nota yazılan değer. null = uygulamanın varsayılan tipografisi.
  final String? id;

  /// Seçicide görünen ad. Katalog yazı tiplerinde yazı tipinin KENDİ adıdır
  /// (çeviri gerektirmez ve kullanıcı adı tanır).
  final String label;

  /// true: Google Fonts katalogundan; false: sistemin genel ailesi.
  final bool google;
}

/// Seçilebilir yazı tipleri. İlk üçü çevrimdışı da garanti.
const List<NoteFontOption> kNoteFonts = [
  NoteFontOption(null, 'Varsayılan'),
  NoteFontOption('serif', 'Kitap'),
  NoteFontOption('monospace', 'Daktilo'),
  NoteFontOption('Lora', 'Lora', google: true),
  NoteFontOption('Merriweather', 'Merriweather', google: true),
  NoteFontOption('Playfair Display', 'Playfair', google: true),
  NoteFontOption('Nunito', 'Nunito', google: true),
  NoteFontOption('Caveat', 'Caveat', google: true),
  NoteFontOption('Roboto Mono', 'Roboto Mono', google: true),
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
TextStyle applyNoteFont(TextStyle base, String? family) {
  if (family == null || family.isEmpty) return base;
  if (family == 'serif' || family == 'monospace') {
    return base.copyWith(fontFamily: family);
  }
  final builder = _googleBuilders[family];
  return builder == null ? base : builder(base);
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

/// Katalog yazı tiplerinin ÇAĞRILARI. Her biri doğrudan adıyla yazılır;
/// böylece derleyici yalnız bu altısını tutar (bkz. yukarıdaki tuzak).
final Map<String, TextStyle Function(TextStyle)> _googleBuilders = {
  'Lora': (base) => GoogleFonts.lora(textStyle: base),
  'Merriweather': (base) => GoogleFonts.merriweather(textStyle: base),
  'Playfair Display': (base) => GoogleFonts.playfairDisplay(textStyle: base),
  'Nunito': (base) => GoogleFonts.nunito(textStyle: base),
  'Caveat': (base) => GoogleFonts.caveat(textStyle: base),
  'Roboto Mono': (base) => GoogleFonts.robotoMono(textStyle: base),
};

/// Çağrısı yazılmış katalog yazı tipleri. [kNoteFonts] ile bunun ayrışması,
/// seçeneğin listede görünüp varsayılanla çizilmesi demek olurdu; test bu iki
/// listenin örtüştüğünü doğrular (yazı tipini YÜKLEMEDEN — ağ gerekmez).
Set<String> get googleNoteFontIds => _googleBuilders.keys.toSet();

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
