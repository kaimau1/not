import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Varsayılan tema Adaçayı (TEMA_PLANI K1, 2026-11-04; önce kırık beyaz,
/// daha önce kağıttı). Eski temaların kayıtlı adları yeni ailelere eşlenir
/// (K2) — kayıt değiştirilmez.
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

  test('kayıt yoksa varsayılan Adaçayı', () async {
    final c = await container();
    addTearDown(c.dispose);
    expect(c.read(themeChoiceProvider), AppThemeChoice.sage);
  });

  test('eski temalar yeni ailelere eşlenir, kayıt değişmez', () async {
    for (final (stored, expected) in [
      ('offWhite', AppThemeChoice.sage),
      ('light', AppThemeChoice.porcelain),
      ('paper', AppThemeChoice.clay),
      ('system', AppThemeChoice.system),
      ('clay', AppThemeChoice.clay),
      ('bilinmeyen', AppThemeChoice.sage),
    ]) {
      final c = await container({'theme_mode': stored});
      addTearDown(c.dispose);
      expect(c.read(themeChoiceProvider), expected, reason: stored);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), stored);
    }
  });

  test('kayıtlı seçim varsayılanı ezer', () async {
    final c = await container({'theme_mode': 'dark'});
    addTearDown(c.dispose);
    expect(c.read(themeChoiceProvider), AppThemeChoice.dark);
  });

  test('aileler açık temadır (ThemeMode.light)', () async {
    final c = await container();
    addTearDown(c.dispose);
    expect(c.read(effectiveThemeModeProvider), ThemeMode.light);
  });
}
