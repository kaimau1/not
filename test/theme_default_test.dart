import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Varsayılan tema kağıt (i1 simge çalışmasıyla marka kağıt paletine geçti).
/// Asıl risk varsayılanın kendisi değil, GERİYE UYUM: kayıtlı seçimi olan
/// kullanıcının teması varsayılan değişince kaymamalı.
void main() {
  Future<ProviderContainer> container([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('kayıt yoksa varsayılan kağıt', () async {
    final c = await container();
    addTearDown(c.dispose);
    expect(c.read(themeChoiceProvider), AppThemeChoice.paper);
  });

  test('kayıtlı seçim varsayılanı ezer', () async {
    final c = await container({'theme_mode': 'dark'});
    addTearDown(c.dispose);
    expect(c.read(themeChoiceProvider), AppThemeChoice.dark);
  });

  test('kağıt açık temadır (ThemeMode.light)', () async {
    final c = await container();
    addTearDown(c.dispose);
    expect(c.read(effectiveThemeModeProvider), ThemeMode.light);
  });
}
