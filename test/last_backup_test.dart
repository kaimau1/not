import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/presentation/backup_ui.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F54.2: son tam yedeğin tarihi ve not sayısı cihazda kalıcı.
void main() {
  test('yedek kaydı tercihe yazılır, yeni kapsayıcıda okunur', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final a = make();
    expect(a.read(lastBackupProvider), isNull);
    final at = DateTime(2026, 11, 9, 7, 30);
    a.read(lastBackupProvider.notifier).record(42, at: at);
    expect(a.read(lastBackupProvider)?.count, 42);
    a.dispose();
    final b = make();
    addTearDown(b.dispose);
    expect(b.read(lastBackupProvider), (at: at, count: 42));
  });
}
