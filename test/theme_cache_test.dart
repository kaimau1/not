import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(identical(AppTheme.paper(), AppTheme.paper()), isTrue);
    expect(
      identical(AppTheme.light(font: 'Lora'), AppTheme.light(font: 'Lora')),
      isTrue,
    );
  });

  test('farklı ayarlar AYRI tema verir (önbellek anahtarı doğru)', () {
    final light = AppTheme.light();
    expect(identical(light, AppTheme.dark()), isFalse);
    // Kağıt teması da açık parlaklıkta: anahtarda `paper` olmasa ikisi
    // birbirine karışır ve kağıt yüzeyler açık temaya sızardı.
    expect(identical(light, AppTheme.paper()), isFalse);
    expect(identical(light, AppTheme.light(font: 'Lora')), isFalse);
    expect(AppTheme.paper().colorScheme.surface, const Color(0xFFF3EFE3));
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
