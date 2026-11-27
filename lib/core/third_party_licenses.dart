import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// **PAKETLİ YAZI TİPLERİNİN LİSANSLARI** (PLAN §1.5 PL7, 16K rapor §4.5).
///
/// SIL Open Font License 1.1, yazı tipiyle birlikte lisans metninin de
/// dağıtılmasını ister. Dosyalar `assets/google_fonts/<Aile>-OFL.txt`
/// (google/fonts deposundaki `OFL.txt`, aileye özgü telif satırıyla); klasör
/// pubspec'te bütün olarak bildirildiği için ayrı satır gerekmez —
/// `google_fonts` paketi yalnız `.ttf/.otf` adlarını taradığından `.txt`
/// dosyaları yazı tipi aramasını etkilemez.
///
/// PL10: pakette `.ttf`i kalmayan, seçilince indirilen aileler
/// (`kDownloadableFontSources`) de BURADA kalır — kullanıcının cihazına yazı
/// tipi dağıtılıyor, lisans metni uygulamada taşınmaya devam eder.
///
/// Anahtar: `.ttf` dosya adındaki aile öneki (`Lato-Regular.ttf` → `Lato`).
/// Yeni aile eklenince buraya satır + `-OFL.txt` dosyası ŞART; bekçi
/// `test/third_party_licenses_test.dart`.
const Map<String, String> bundledFontLicenses = {
  'Caveat': 'Caveat',
  'EBGaramond': 'EB Garamond',
  'InterTight': 'Inter Tight',
  'JetBrainsMono': 'JetBrains Mono',
  'Lato': 'Lato',
  'Lora': 'Lora',
  'Merriweather': 'Merriweather',
  'Montserrat': 'Montserrat',
  'Nunito': 'Nunito',
  'OpenSans': 'Open Sans',
  'PTSans': 'PT Sans',
  'PTSerif': 'PT Serif',
  'PatrickHand': 'Patrick Hand',
  'PlayfairDisplay': 'Playfair Display',
  'Poppins': 'Poppins',
  'Roboto': 'Roboto',
  'RobotoMono': 'Roboto Mono',
  'Rubik': 'Rubik',
  'SourceSans3': 'Source Sans 3',
  'WorkSans': 'Work Sans',
};

/// Aile önekinin lisans dosyası (asset yolu).
String fontLicenseAsset(String family) => 'assets/google_fonts/$family-OFL.txt';

/// Ayarlar → Lisanslar sayfasına yazı tipi OFL metinlerini, CMU BSD
/// bildirimini ve yazım sözlüğünün Apache-2.0 bildirimini ekler. Metinler sayfa AÇILINCA okunur (açılışa yük yok).
void registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: name)
        in bundledFontLicenses.entries) {
      final String text;
      try {
        text = await rootBundle.loadString(fontLicenseAsset(family));
      } catch (_) {
        continue; // dosya yoksa (olmamalı; bekçi testi) sayfa yine açılır
      }
      yield LicenseEntryWithLineBreaks(['$name (font)'], text);
    }
    // Yazım denetiminin kök sözlüğü (Zemberek-NLP, Apache-2.0; 2026-11-26).
    try {
      yield LicenseEntryWithLineBreaks([
        'Zemberek-NLP (Türkçe sözlük)',
      ], await rootBundle.loadString(spellLexiconNotice));
    } catch (_) {}
  });
}

/// Yazım sözlüğünün lisans/kaynak bildirimi (Apache-2.0 tam metniyle).
const spellLexiconNotice = 'assets/spell/NOTICE.txt';
