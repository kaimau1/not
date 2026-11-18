import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/third_party_licenses.dart';

/// PL7 bekçisi: pakette taşınan HER yazı tipi ailesinin OFL metni hem
/// dosya olarak var hem Lisanslar sayfasına kayıtlı; CMU BSD bildirimi de.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Set<String> bundledFamilies() {
    final families = <String>{};
    for (final dir in ['assets/google_fonts', 'assets/fonts']) {
      for (final f in Directory(dir).listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;
        families.add(name.split('-').first);
      }
    }
    return families;
  }

  test('her paketli yazı tipi ailesinin lisans kaydı ve OFL dosyası var', () {
    final families = bundledFamilies();
    expect(families, isNotEmpty);
    for (final family in families) {
      expect(
        bundledFontLicenses.containsKey(family),
        isTrue,
        reason: '$family: bundledFontLicenses satırı yok',
      );
      final file = File(fontLicenseAsset(family));
      expect(file.existsSync(), isTrue, reason: '${file.path} yok');
      final text = file.readAsStringSync();
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(text, startsWith('Copyright'));
    }
    // Haritada artık pakette olmayan aile kalmasın.
    expect(bundledFontLicenses.keys.toSet(), families);
  });

  test(
    'Lisanslar sayfası yazı tiplerini ve CMU bildirimini listeler',
    () async {
      registerThirdPartyLicenses();
      final packages = <String>{};
      final texts = <String, String>{};
      await for (final entry in LicenseRegistry.licenses) {
        for (final p in entry.packages) {
          packages.add(p);
          texts[p] = entry.paragraphs.map((e) => e.text).join('\n');
        }
      }
      for (final name in bundledFontLicenses.values) {
        expect(packages, contains('$name (font)'));
        expect(texts['$name (font)'], contains('SIL OPEN FONT LICENSE'));
      }
      expect(packages, contains('CMU Pronouncing Dictionary'));
      expect(texts['CMU Pronouncing Dictionary'], contains('Carnegie Mellon'));
    },
  );
}
