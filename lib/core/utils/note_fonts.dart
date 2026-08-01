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
TextStyle applyNoteFont(TextStyle base, String? family) {
  if (family == null || family.isEmpty) return base;
  if (family == 'serif' || family == 'monospace') {
    return base.copyWith(fontFamily: family);
  }
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}

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
