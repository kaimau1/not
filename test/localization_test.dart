import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Diller gercekten yuklenebiliyor mu. Anahtar/yer tutucu esligini
/// `tool/check_arb.ps1` denetler; burada uretilen sinifin calistigi dogrulanir.
void main() {
  test('desteklenen diller: tr, en, de, es', () {
    final codes = [
      for (final l in AppLocalizations.supportedLocales) l.languageCode,
    ];
    expect(codes, containsAll(<String>['tr', 'en', 'de', 'es']));
  });

  test('her dil kendi metnini dondurur', () async {
    final tr = await AppLocalizations.delegate.load(const Locale('tr'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final de = await AppLocalizations.delegate.load(const Locale('de'));
    final es = await AppLocalizations.delegate.load(const Locale('es'));

    expect(tr.settings, 'Ayarlar');
    expect(en.settings, 'Settings');
    expect(de.settings, 'Einstellungen');
    expect(es.settings, 'Ajustes');
    // Ceviri gercekten yapilmis mi: ayni dizgi kalmis anahtar olmamali.
    // (Eksik ceviride gen-l10n sablon dilin metnini birakir, hata vermez —
    // yani bu esitsizlik denetimi kacan anahtarin tek isaretidir.)
    final texts = [tr.emptyNotes, en.emptyNotes, de.emptyNotes, es.emptyNotes];
    expect(texts.toSet(), hasLength(texts.length));
  });

  test('yer tutuculu metinler her dilde deger basar', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.selectedCount(3), contains('3'));
    expect(en.genericError('boom'), contains('boom'));
    // Yer tutucu ismi yanlis yazilmissa metinde ham '{' kalir.
    expect(en.attachmentTooLarge(10), isNot(contains('{')));
  });
}
