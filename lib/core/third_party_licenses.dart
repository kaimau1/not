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

/// CMU Telaffuz Sözlüğü (BSD 2-Clause). Antalia'nın yabancı kelime
/// sözlükleri ondan türetilmiş; bildirim Antalia kapalı derlemede (Play) de
/// zararsız, lisans sayfası eksiksiz olsun diye her derlemede kayıtlı.
const String cmuDictLicense =
    'The CMU Pronouncing Dictionary\n'
    'Copyright (C) 1993-2015 Carnegie Mellon University. All rights reserved.\n'
    '\n'
    'Redistribution and use in source and binary forms, with or without '
    'modification, are permitted provided that the following conditions '
    'are met:\n'
    '\n'
    '1. Redistributions of source code must retain the above copyright '
    'notice, this list of conditions and the following disclaimer.\n'
    '   The contents of this file are deemed to be source code.\n'
    '\n'
    '2. Redistributions in binary form must reproduce the above copyright '
    'notice, this list of conditions and the following disclaimer in the '
    'documentation and/or other materials provided with the distribution.\n'
    '\n'
    'This work was supported in part by funding from the Defense Advanced '
    'Research Projects Agency, the Office of Naval Research and the National '
    'Science Foundation of the United States of America, and by member '
    'companies of the Carnegie Mellon Sphinx Speech Consortium. We acknowledge '
    'the contributions of many volunteers to the expansion and improvement of '
    'this dictionary.\n'
    '\n'
    'THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY ``AS IS\'\' AND '
    'ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE '
    'IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR '
    'PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY NOR '
    'ITS EMPLOYEES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, '
    'EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, '
    'PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR '
    'PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF '
    'LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING '
    'NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS '
    'SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.';

/// Ayarlar → Lisanslar sayfasına yazı tipi OFL metinlerini ve CMU BSD
/// bildirimini ekler. Metinler sayfa AÇILINCA okunur (açılışa yük yok).
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
    yield const LicenseEntryWithLineBreaks([
      'CMU Pronouncing Dictionary',
    ], cmuDictLicense);
  });
}
