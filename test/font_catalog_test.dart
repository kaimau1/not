import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/note_fonts.dart';
import 'package:notlar/features/settings/settings_providers.dart';

/// YAZI TİPİ KATALOĞU APK'ya GÖMÜLÜ (kullanıcı isteği 2026-08-07: "varsayılan
/// yazı tipi seçimi de olsun en az 15 tane font indir göm").
///
/// Katalog dört yerde birden yaşıyor: [kCatalogFonts] listesi, tek stil
/// çağrıları ([googleNoteFontIds]), metin teması çağrıları ([appFontIds]) ve
/// `assets/google_fonts/` altındaki dosyalar. Bunlardan biri ötekilerden
/// ayrılırsa hata SESSİZ olur — seçenek listede görünür, seçilir, ama ya
/// varsayılanla çizilir ya da (dosya eksikse) `google_fonts` ağdan indirmeye
/// çalışıp çevrimdışı cihazda sistem fontuna düşer. Test dördünü bağlar.
void main() {
  test('en az 15 yazı tipi katalogda', () {
    expect(kCatalogFonts.length, greaterThanOrEqualTo(15));
  });

  test('katalog · tek stil çağrıları · metin teması çağrıları örtüşüyor', () {
    final listed = kCatalogFonts.map((f) => f.id).whereType<String>().toSet();
    expect(googleNoteFontIds, containsAll(listed));
    expect(appFontIds, containsAll(listed));
    expect(
      listed,
      containsAll(appFontIds),
      reason: 'metin teması çağrısı var ama katalogda olmayan yazı tipi',
    );
  });

  test('varsayılan yazı tipi katalogda ve çağrısı yazılmış', () {
    expect(appFontIds, contains(kAppDefaultFont));
    expect(kCatalogFonts.map((f) => f.id), contains(kAppDefaultFont));
  });

  test('her yazı tipinin dosyaları gömülü', () {
    // Dosya adı `google_fonts`un aradığı kalıpta olmak ZORUNDA
    // (`<Aile>-<Ağırlık>.ttf`, aile adı BOŞLUKSUZ); adı değişirse paket
    // sessizce indirmeye döner.
    final bundled = Directory(
      'assets/google_fonts',
    ).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();
    for (final font in kCatalogFonts) {
      final family = font.id!.replaceAll(' ', '');
      final files = bundled.where((n) => n.startsWith('$family-'));
      expect(
        files,
        isNotEmpty,
        reason: '${font.id} için gömülü dosya yok (assets/google_fonts)',
      );
      // Gövde teması 400'ü her zaman ister; 500 yoksa paket 400'e düşer.
      expect(
        files,
        contains('$family-Regular.ttf'),
        reason: '${font.id}: Regular (400) dosyası şart',
      );
    }
  });

  test('varlık klasörü pubspec\'te bildirilmiş', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('assets/google_fonts/'),
    );
  });

  test(
    'yazı boyutu dört kademe, eski kaydırıcı değerleri en yakına oturur',
    () {
      expect(FontScaleStep.values.length, 4);
      // Kaydırıcı döneminden kalabilecek değerler:
      expect(nearestFontScaleStep(0.85), FontScaleStep.small);
      expect(nearestFontScaleStep(1.0), FontScaleStep.medium);
      expect(nearestFontScaleStep(1.07), FontScaleStep.medium);
      expect(nearestFontScaleStep(1.2), FontScaleStep.large);
      expect(nearestFontScaleStep(1.4), FontScaleStep.xlarge);
      // Kademeler artan sırada ve makul aralıkta.
      final scales = [for (final s in FontScaleStep.values) s.scale];
      expect(scales, orderedEquals([...scales]..sort()));
      expect(scales.first, greaterThanOrEqualTo(0.8));
      expect(scales.last, lessThanOrEqualTo(1.5));
    },
  );
}
