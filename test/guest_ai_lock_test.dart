import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';

/// F10.5: misafirde AI ekranları "30/30 puan" gösterip her araçta hata
/// veriyordu. Kilit yalnız misafir + anahtarsızda; kendi anahtarı olan
/// misafirde AI açık kalır.
void main() {
  Future<bool> locked({required bool anonymous, String? key}) async {
    final container = ProviderContainer(
      overrides: [
        isAnonymousProvider.overrideWithValue(anonymous),
        activeApiKeyProvider.overrideWith((ref) async => key),
      ],
    );
    addTearDown(container.dispose);
    await container.read(activeApiKeyProvider.future);
    return container.read(aiGuestLockedProvider);
  }

  test('misafir, anahtarsız → kilitli', () async {
    expect(await locked(anonymous: true), isTrue);
    expect(await locked(anonymous: true, key: ''), isTrue);
  });

  test('misafir, kendi anahtarıyla → açık', () async {
    expect(await locked(anonymous: true, key: 'AIza-test'), isFalse);
  });

  test('Google hesabı → açık', () async {
    expect(await locked(anonymous: false), isFalse);
  });
}
