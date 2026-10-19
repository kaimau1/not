import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/app.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Arayüz dilleri: yalnız Türkçe + İngilizce (F3.14, 2026-10-19). Eksik
/// çeviride gen-l10n şablon dilin metnini sessizce bırakır — anahtar
/// eşitliği burada kilitlenir.
void main() {
  test('desteklenen diller tr ve en; ayar listesi aynı kaynaktan', () {
    final codes = [
      for (final l in AppLocalizations.supportedLocales) l.toLanguageTag(),
    ];
    expect(codes, unorderedEquals(['tr', 'en']));
    expect(supportedLanguages.keys, unorderedEquals(codes));
  });

  test('en.arb tr.arb ile aynı anahtarları taşır', () {
    Set<String> keys(String lang) => {
      for (final k
          in (jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
                  as Map<String, dynamic>)
              .keys)
        if (!k.startsWith('@')) k,
    };
    expect(keys('en'), keys('tr'));
  });

  test('her dil kendi metnini, yer tutucuları değerle basar', () async {
    final tr = await AppLocalizations.delegate.load(const Locale('tr'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(tr.settings, 'Ayarlar');
    expect(en.settings, 'Settings');
    expect(en.selectedCount(3), contains('3'));
    expect(en.attachmentTooLarge(10), isNot(contains('{')));
  });

  test('sistem dili: desteklenmeyen dilde Türkçe, varyant eşleşir', () {
    Locale resolve(List<Locale>? l) =>
        resolveLocale(l, AppLocalizations.supportedLocales);
    expect(resolve(const [Locale('zz')]), const Locale('tr'));
    expect(resolve(null), const Locale('tr'));
    expect(
      resolve(const [Locale('de'), Locale('en', 'GB')]),
      const Locale('en'),
    );
  });
}
