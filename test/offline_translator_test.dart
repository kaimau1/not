import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/translate/data/offline_translator.dart';

/// Dil eşlemesi çeviri kalitesinin sessiz kırılma noktası: desteklenmeyen bir
/// dil yanlışlıkla "destekleniyor" sayılırsa ML Kit çağrısı çalışma anında
/// patlar ya da boş döner. Çevirmen ekranındaki 16 dilin hepsi burada.
void main() {
  test('Desteklenen diller ML Kit diline eşlenir', () {
    for (final code in [
      'tr',
      'en',
      'de',
      'fr',
      'es',
      'it',
      'ar',
      'ru',
      'fa',
      'nl',
      'pt',
      'el',
      'ja',
      'ko',
      'zh',
    ]) {
      expect(
        OfflineTranslator.languageFor(code),
        isNotNull,
        reason: '$code ML Kit tarafından desteklenmeli',
      );
    }
  });

  test('Azerbaycanca ML Kit\'te YOK — Gemini yoluna düşmeli', () {
    expect(OfflineTranslator.languageFor('az'), isNull);
  });

  test('Bilinmeyen kod null döner, çökmez', () {
    expect(OfflineTranslator.languageFor('xx'), isNull);
    expect(OfflineTranslator.languageFor(''), isNull);
  });

  test('Büyük harfli kod da eşlenir', () {
    expect(OfflineTranslator.languageFor('TR'), isNotNull);
  });
}
