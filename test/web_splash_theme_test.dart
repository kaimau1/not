import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/settings_providers.dart';

/// KW-6 (web keşfi 2026-11-18): koyu işletim sisteminde açılış katmanı koyu,
/// uygulama (varsayılan Adaçayı) açıktı — parlama. Katman artık uygulamanın
/// kayıtlı tema seçimini okur; işletim sistemi kipini KENDİ BAŞINA izlemez.
void main() {
  final html = File('web/index.html').readAsStringSync();

  test('açılış katmanı uygulamanın tema kaydını okur', () {
    expect(html, contains("localStorage.getItem('flutter.theme_mode')"));
    // Dart tarafındaki anahtar ve seçim adları aynı kalmalı.
    expect(
      File('lib/features/settings/settings_providers.dart').readAsStringSync(),
      contains("static const _key = 'theme_mode';"),
    );
    expect(html, contains("m === '${AppThemeChoice.dark.name}'"));
    expect(html, contains("m === '${AppThemeChoice.system.name}'"));
  });

  test('koyu renkler yalnız betiğin koyduğu sınıfla (OS kipiyle değil)', () {
    expect(html, contains(':root.dark {'));
    expect(
      RegExp(r'@media \(prefers-color-scheme: dark\)\s*\{\s*:root')
          .hasMatch(html),
      isFalse,
    );
  });
}
