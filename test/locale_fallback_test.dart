import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/app.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Dil listesi büyüdükçe iki şey sessizce bozulabiliyor: (1) Ayarlar'daki
/// seçenek `.arb` dosyası olmayan bir dili gösterebilir, (2) desteklenmeyen
/// sistem dilinde uygulama alfabetik olarak ilk gelen dile (bugün Almanca)
/// düşebilir. İkisi de ekranda ancak o dilde bakınca fark ediliyor.
void main() {
  test('Ayarlar\'daki her dilin çevirisi üretilmiş', () {
    final generated = {
      for (final locale in AppLocalizations.supportedLocales)
        locale.languageCode,
    };
    expect(supportedLanguages.keys, everyElement(isIn(generated)));
    expect(generated, unorderedEquals(supportedLanguages.keys));
  });

  test('desteklenmeyen sistem dilinde Türkçe\'ye düşülür', () {
    expect(_resolve(const [Locale('fr')]), const Locale('tr'));
    expect(_resolve(const []), const Locale('tr'));
    expect(_resolve(null), const Locale('tr'));
  });

  test('desteklenen dil ve bölge varyantı doğru eşleşir', () {
    expect(_resolve(const [Locale('de')]), const Locale('de'));
    expect(_resolve(const [Locale('es', 'MX')]), const Locale('es'));
    // Sıra önemli: kullanıcının ilk tercihi tutuyorsa sonrakine bakılmaz.
    expect(_resolve(const [Locale('en'), Locale('de')]), const Locale('en'));
    // İlk tercih desteklenmiyorsa ikinciye geçilir.
    expect(_resolve(const [Locale('fr'), Locale('de')]), const Locale('de'));
  });
}

/// `MaterialApp.router`'a verilen kuralın TA KENDİSİ çağrılır — kopyasını
/// sınamak, kod değişince testin sessizce yeşil kalması demekti.
Locale _resolve(List<Locale>? locales) =>
    resolveLocale(locales, AppLocalizations.supportedLocales);
