import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/language_names.dart';
import 'package:notlar/core/utils/speech_output.dart'
    show SpeechOutputController;
import 'package:notlar/app/app.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Arayüz dilleri: beş pazar dili (tr, en, ar, id, ms; 2026-11-27). Eksik
/// çeviride gen-l10n şablon dilin metnini sessizce bırakır — anahtar
/// eşitliği burada kilitlenir.
void main() {
  // 2026-11-27: beş pazar dili (tr, en, ar, id, ms).
  test('desteklenen diller beş pazar dili; ayar listesi aynı kaynaktan', () {
    final codes = [
      for (final l in AppLocalizations.supportedLocales) l.toLanguageTag(),
    ];
    expect(codes, unorderedEquals(kMarketLanguages));
    expect(supportedLanguages.keys, unorderedEquals(codes));
  });

  test('en.arb tr.arb ile aynı anahtarları taşır', () {
    Set<String> keys(String lang) => {
      for (final k in (jsonDecode(
        File('lib/l10n/app_$lang.arb').readAsStringSync(),
      ) as Map<String, dynamic>).keys)
        if (!k.startsWith('@')) k,
    };
    expect(keys('en'), keys('tr'));
    for (final lang in const ['ar', 'id', 'ms']) {
      expect(keys(lang), keys('tr'), reason: lang);
    }
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

  // 2026-11-27: dikte her yerde "Türkçe değilse İngilizce" diyordu.
  test('dikte dili beş pazar dilinde kendi tanıyıcısı', () {
    expect(SpeechOutputController.speechLocale('tr'), 'tr-TR');
    expect(SpeechOutputController.speechLocale('en'), 'en-US');
    expect(SpeechOutputController.speechLocale('ar'), 'ar-SA');
    expect(SpeechOutputController.speechLocale('id'), 'id-ID');
    expect(SpeechOutputController.speechLocale('ms'), 'ms-MY');
    expect(SpeechOutputController.speechLocale('zz'), 'en-US');
    expect(
      SpeechOutputController.alternateSpeechLocale('ms-MY', 'ms-MY'),
      'en-US',
    );
    expect(
      SpeechOutputController.alternateSpeechLocale('en-US', 'ms-MY'),
      'ms-MY',
    );
  });

  test('Arapça, Endonezce, Malayca kendi metnini basar', () async {
    for (final (code, word) in const [
      ('ar', 'الإعدادات'),
      ('id', 'Pengaturan'),
      ('ms', 'Tetapan'),
    ]) {
      final l = await AppLocalizations.delegate.load(Locale(code));
      expect(l.settings, word);
      expect(l.selectedCount(3), contains('3'));
      expect(l.notesDuplicatedCount(2), contains('2'));
    }
  });

  test('Android Gradle beş pazar dilinin tamamını tutar', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    for (final code in ['"tr"', '"en"', '"ar"', '"id"', '"ms"']) {
      expect(
        gradle,
        contains(code),
        reason: 'resourceConfigurations $code içermeli',
      );
    }
  });
}
