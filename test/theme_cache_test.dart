import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/utils/note_fonts.dart';

/// KÖK NEDEN (kasma — "font değişince kasıyor"): `NotlarApp.build` her
/// çalıştığında `theme:` ve `darkTheme:` için iki tam [ThemeData] sıfırdan
/// kuruluyordu. Her biri bir `ColorScheme.fromSeed` (Material'ın renk
/// algoritması) ve paketin on beş metin biçimini kuran bir `...TextTheme`
/// çağrısı demek. Üstelik her seferinde YENİ nesne döndüğü için
/// `Theme.updateShouldNotify` [ThemeData]'nın yüzlerce alanlı `==`'ini
/// koşuyor ve tema hiç değişmemiş olsa bile ağaç gereksiz yere ilgileniyordu.
void main() {
  // `google_fonts` gömülü dosyayı varlık manifestinden arar; bağlama
  // kurulmadan varlık paketi okunamaz.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppTheme.clearCache);

  test('aynı ayarlar AYNI ThemeData nesnesini verir', () {
    expect(identical(AppTheme.light(), AppTheme.light()), isTrue);
    expect(identical(AppTheme.dark(), AppTheme.dark()), isTrue);
    for (final f in ThemeFamily.values) {
      for (final b in Brightness.values) {
        expect(identical(AppTheme.of(f, b), AppTheme.of(f, b)), isTrue);
      }
    }
    expect(
      identical(AppTheme.light(font: 'Lora'), AppTheme.light(font: 'Lora')),
      isTrue,
    );
  });

  test('farklı ayarlar AYRI tema verir (önbellek anahtarı doğru)', () {
    final light = AppTheme.light();
    expect(identical(light, AppTheme.dark()), isFalse);
    // Aileler aynı parlaklıkta: anahtarda aile olmasa birbirine karışırdı.
    expect(
      identical(light, AppTheme.of(ThemeFamily.clay, Brightness.light)),
      isFalse,
    );
    expect(identical(light, AppTheme.light(font: 'Lora')), isFalse);
    expect(
      AppTheme.of(ThemeFamily.clay, Brightness.light).colorScheme.surface,
      const Color(0xFFF3ECE9),
    );
    // Varsayılan aile Adaçayı.
    expect(light.colorScheme.surface, const Color(0xFFEAF0EB));
  });

  test('zıt tema aynı aile + yazı tipinden, önbellekten gelir', () {
    final clay = AppTheme.of(ThemeFamily.clay, Brightness.light, font: 'Lora');
    final opp = AppTheme.opposite(clay);
    expect(opp.brightness, Brightness.dark);
    expect(
      identical(
        opp,
        AppTheme.of(ThemeFamily.clay, Brightness.dark, font: 'Lora'),
      ),
      isTrue,
    );
    expect(identical(AppTheme.opposite(opp), clay), isTrue);
  });

  test('katalogdaki her yazı tipi kendi temasını kurabiliyor', () {
    for (final font in kCatalogFonts) {
      final theme = AppTheme.light(font: font.id);
      expect(theme.textTheme.bodyLarge, isNotNull, reason: font.id);
    }
    expect(AppTheme.light(font: 'Lora').brightness, Brightness.light);
    expect(AppTheme.dark(font: 'Lora').brightness, Brightness.dark);
  });
}
