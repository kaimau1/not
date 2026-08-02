import 'dart:ui';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/app.dart';
import 'package:notlar/core/utils/language_names.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Dil listesi büyüdükçe sessizce bozulabilecek şeyler burada kilitleniyor.
/// Hepsi ekranda ancak o dile geçildiğinde fark edilirdi.
void main() {
  test('desteklenen dil listesi üretilen çevirilerden türer', () {
    // Liste artık elle tutulmuyor; `.arb` eklemek dili seçilebilir yapmalı,
    // ikinci bir yeri güncellemek gerekmemeli.
    final generated = {
      for (final locale in AppLocalizations.supportedLocales)
        locale.toLanguageTag(),
    };
    expect(supportedLanguages.keys, unorderedEquals(generated));
  });

  test('her dilin kendi yazımıyla bir adı var', () {
    // Adı olmayan dil listede ham kodla ('vi') görünür; kullanıcı kendi
    // dilini tanıyamaz.
    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      expect(
        languageLabel(tag),
        isNot(tag),
        reason: '$tag için language_names.dart içinde ad yok',
      );
    }
  });

  test('her dili Flutter da destekliyor', () {
    // EN KRİTİK KURAL: Flutter'ın hazır Material/Cupertino çevirisi olmayan
    // bir yerel ayar eklenirse uygulama o dilde ÇALIŞMA ANINDA hata verir
    // (tarih seçici, metin seçim menüsü gibi yerleşiklerin metni yoktur).
    // Çeviri aracı yanlış bir dil kodu üretirse burada yakalanır.
    for (final locale in AppLocalizations.supportedLocales) {
      expect(
        GlobalMaterialLocalizations.delegate.isSupported(locale),
        isTrue,
        reason:
            '${locale.toLanguageTag()} Flutter tarafından desteklenmiyor; '
            'bu dil için app_*.arb kaldırılmalı',
      );
      expect(
        GlobalCupertinoLocalizations.delegate.isSupported(locale),
        isTrue,
        reason: '${locale.toLanguageTag()} için Cupertino çevirisi yok',
      );
    }
  });

  test('desteklenmeyen sistem dilinde Türkçe\'ye düşülür', () {
    // 'zz' bilerek seçildi: gerçek bir dil kodu değil, yani dil listesi
    // büyüdükçe bu test kendiliğinden anlamsızlaşmaz.
    expect(_resolve(const [Locale('zz')]), const Locale('tr'));
    expect(_resolve(const []), const Locale('tr'));
    expect(_resolve(null), const Locale('tr'));
  });

  test('desteklenen dil ve bölge varyantı doğru eşleşir', () {
    expect(_resolve(const [Locale('de')]), const Locale('de'));
    expect(_resolve(const [Locale('es', 'MX')]), const Locale('es'));
    // Sıra önemli: kullanıcının ilk tercihi tutuyorsa sonrakine bakılmaz.
    expect(_resolve(const [Locale('en'), Locale('de')]), const Locale('en'));
    // İlk tercih desteklenmiyorsa ikinciye geçilir.
    expect(_resolve(const [Locale('zz'), Locale('de')]), const Locale('de'));
  });

  test('RTL dilleri katalogda işaretli', () {
    // Yön Flutter tarafından yerel ayardan çıkarılıyor; bu küme, elle
    // çizilen yerleşimlerin RTL'de doğru davranması için gerekiyor.
    expect(rtlLanguages, contains('ar'));
    expect(rtlLanguages, contains('he'));
    expect(rtlLanguages, isNot(contains('tr')));
  });
}

/// `MaterialApp.router`'a verilen kuralın TA KENDİSİ çağrılır — kopyasını
/// sınamak, kod değişince testin sessizce yeşil kalması demekti.
Locale _resolve(List<Locale>? locales) =>
    resolveLocale(locales, AppLocalizations.supportedLocales);
