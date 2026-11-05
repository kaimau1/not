import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F42.2: AI durumu tek kaynak. F10.5'in misafir kilidi de burada: misafirde
/// "30/30 puan" görünüp her araç hata veriyordu.
void main() {
  Future<ProviderContainer> container({
    bool anonymous = false,
    String? key,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final store = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        isAnonymousProvider.overrideWithValue(anonymous),
        currentUidProvider.overrideWithValue(null),
        activeApiKeyProvider.overrideWith((ref) async => key),
        sharedPreferencesProvider.overrideWithValue(store),
      ],
    );
    addTearDown(c.dispose);
    await c.read(activeApiKeyProvider.future);
    return c;
  }

  Future<AiAvailability> status({
    bool anonymous = false,
    String? key,
    Map<String, Object> prefs = const {},
  }) async => (await container(
    anonymous: anonymous,
    key: key,
    prefs: prefs,
  )).read(aiAvailabilityProvider);

  int nowMs() => DateTime.now().millisecondsSinceEpoch;
  String todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'ai_points_used_${now.year}-$m-$d';
  }

  test('misafir, anahtarsız → kilitli; kendi anahtarıyla açık', () async {
    expect(await status(anonymous: true), AiAvailability.guest);
    expect(await status(anonymous: true, key: ''), AiAvailability.guest);
    expect(await status(anonymous: true, key: 'k'), AiAvailability.ready);
  });

  test('Google hesabı → hazır', () async {
    expect(await status(), AiAvailability.ready);
  });

  test(
    'dahili kapalı öğrenildi → anahtar gerekli, 24 saat hatırlanır',
    () async {
      expect(
        await status(prefs: {'ai_builtin_off_at': nowMs()}),
        AiAvailability.needsKey,
      );
      expect(
        await status(
          prefs: {
            'ai_builtin_off_at':
                nowMs() - const Duration(hours: 25).inMilliseconds,
          },
        ),
        AiAvailability.ready,
      );
      expect(
        await status(key: 'k', prefs: {'ai_builtin_off_at': nowMs()}),
        AiAvailability.ready,
      );
    },
  );

  test('Tekrar dene kapalı bayrağını siler', () async {
    final c = await container(prefs: {'ai_builtin_off_at': nowMs()});
    expect(c.read(aiAvailabilityProvider), AiAvailability.needsKey);
    c.read(aiBuiltInOffProvider.notifier).set(false);
    expect(c.read(aiAvailabilityProvider), AiAvailability.ready);
  });

  test('puan bitti → kota; yenilenme saati bilinmiyorsa kilitlemez', () async {
    final out = {
      todayKey(): 100000,
      'ai_quota_window_start':
          nowMs() - const Duration(hours: 1).inMilliseconds,
    };
    final c = await container(prefs: out);
    expect(c.read(aiAvailabilityProvider), AiAvailability.quotaOut);
    expect(c.read(aiQuotaRenewsAtProvider), isNotNull);
    expect(await status(prefs: {todayKey(): 100000}), AiAvailability.ready);
    // Pencere dolmuşsa yeni pencere açılacak: kilit yok.
    expect(
      await status(
        prefs: {
          todayKey(): 100000,
          'ai_quota_window_start':
              nowMs() - const Duration(hours: 25).inMilliseconds,
        },
      ),
      AiAvailability.ready,
    );
  });
}
