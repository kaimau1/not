import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/font_sources.dart';
import 'package:notlar/core/utils/note_fonts.dart';
import 'package:notlar/features/settings/settings_providers.dart';

/// YAZI TİPİ KATALOĞU (kullanıcı isteği 2026-08-07: "varsayılan yazı tipi
/// seçimi de olsun en az 15 tane font"). PL10: yalnız [kCoreFontIds] APK'ya
/// GÖMÜLÜ; kalanı seçilince indirilir (`font_downloads.dart`).
///
/// Katalog birkaç yerde birden yaşıyor: [kCatalogFonts] listesi, çekirdek için
/// tek stil çağrıları ([googleNoteFontIds]) ve metin teması çağrıları,
/// `assets/google_fonts/` altındaki dosyalar, indirilenler için
/// [kDownloadableFontSources]. Biri ayrılırsa hata SESSİZ olur — seçenek
/// listede görünür ama varsayılanla çizilir. Test hepsini bağlar.
void main() {
  test('en az 15 yazı tipi katalogda', () {
    expect(kCatalogFonts.length, greaterThanOrEqualTo(15));
  });

  test('katalog · tek stil çağrıları · metin teması çağrıları örtüşüyor', () {
    final listed = kCatalogFonts.map((f) => f.id).whereType<String>().toSet();
    expect(googleNoteFontIds, kCoreFontIds, reason: 'gömülü = çekirdek');
    expect(listed, containsAll(kCoreFontIds));
    expect(
      listed.difference(kCoreFontIds),
      kDownloadableFontSources.keys.toSet(),
      reason: 'çekirdek olmayan her aile indirme kaynağına sahip olmalı',
    );
    expect(appFontIds, listed);
  });

  test(
    'indirme kaynağı her ailede 400, varsa 500; hepsi SHA-256 biçiminde',
    () {
      for (final entry in kDownloadableFontSources.entries) {
        expect(entry.value.first.weight, 400, reason: entry.key);
        for (final s in entry.value) {
          expect(
            s.sha256,
            matches(RegExp(r'^[0-9a-f]{64}$')),
            reason: entry.key,
          );
          expect(s.length, greaterThan(10000), reason: entry.key);
        }
      }
    },
  );

  test('varsayılan yazı tipi katalogda ve çağrısı yazılmış', () {
    expect(appFontIds, contains(kAppDefaultFont));
    expect(kCatalogFonts.map((f) => f.id), contains(kAppDefaultFont));
  });

  test('çekirdek yazı tiplerinin dosyaları gömülü', () {
    // Dosya adı `google_fonts`un aradığı kalıpta olmak ZORUNDA
    // (`<Aile>-<Ağırlık>.ttf`, aile adı BOŞLUKSUZ); adı değişirse paket
    // sessizce indirmeye döner.
    final bundled = Directory('assets/google_fonts')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
    for (final font in kCatalogFonts.where((f) => !f.downloadable)) {
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

  test('ilk açılış sistem yazı ölçeğinin en yakın kademesinden başlar', () {
    expect(initialFontScale(1.0), FontScaleStep.medium.scale);
    expect(initialFontScale(1.3), FontScaleStep.xlarge.scale);
    expect(initialFontScale(2.0), FontScaleStep.xlarge.scale);
    expect(initialFontScale(0.8), FontScaleStep.small.scale);
    // KW-10: web masaüstü penceresinde başlangıç en az "Büyük".
    expect(
      initialFontScale(1.0, web: true, windowWidth: 1440),
      FontScaleStep.large.scale,
    );
    expect(
      initialFontScale(1.3, web: true, windowWidth: 1440),
      FontScaleStep.xlarge.scale,
    );
    expect(initialFontScale(1.0, web: true, windowWidth: 800), 1.0);
    expect(initialFontScale(1.0, windowWidth: 1440), 1.0, reason: 'uygulama');
  });
}
