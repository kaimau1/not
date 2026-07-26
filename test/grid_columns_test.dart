import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ana ekranda iki parmak zoom, ızgarayı 1–4 sütun arasında gezdirir.
/// Sütun sayısı kalıcıdır; 0 "otomatik" (ekran genişliğinden hesapla) demek.
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

  test('varsayılan otomatik (0)', () async {
    final c = await container();
    addTearDown(c.dispose);
    expect(c.read(gridColumnsProvider), 0);
  });

  test('kayıtlı değer okunur', () async {
    final c = await container({'grid_columns': 3});
    addTearDown(c.dispose);
    expect(c.read(gridColumnsProvider), 3);
  });

  test('aralık dışı değerler 1–4 arasına kırpılır', () async {
    final c = await container();
    addTearDown(c.dispose);
    final notifier = c.read(gridColumnsProvider.notifier);

    notifier.set(9);
    expect(c.read(gridColumnsProvider), 4);

    notifier.set(1);
    expect(c.read(gridColumnsProvider), 1);

    // 0 ve altı "otomatik"e döner (kırpılmaz).
    notifier.set(0);
    expect(c.read(gridColumnsProvider), 0);
  });

  test('seçim kalıcıdır', () async {
    final c = await container();
    addTearDown(c.dispose);
    c.read(gridColumnsProvider.notifier).set(2);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('grid_columns'), 2);
  });
}
