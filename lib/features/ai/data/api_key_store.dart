import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../settings/settings_providers.dart';
import 'ai_provider.dart';

/// API anahtarları yalnızca cihazdaki güvenli depoda tutulur
/// (Android Keystore / Windows DPAPI). Firestore'a asla yazılmaz.
///
/// Her sağlayıcının anahtarı AYRI saklanır: kullanıcı Gemini ile OpenAI
/// arasında geçiş yaptığında anahtarını yeniden girmek zorunda kalmasın.
class ApiKeyStore {
  const ApiKeyStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  /// TUZAK: Gemini'nin depo anahtarı `gemini_api_key` olarak KALMALI. Çok
  /// sağlayıcılı yapıya geçmeden önceki sürümler anahtarı bu adla yazdı;
  /// şema değişirse güncelleyen kullanıcı anahtarını kaybeder.
  static String storageKey(AiProvider provider) => provider == AiProvider.gemini
      ? 'gemini_api_key'
      : '${provider.id}_api_key';

  Future<String?> read(AiProvider provider) =>
      _storage.read(key: storageKey(provider));

  Future<void> save(AiProvider provider, String value) =>
      _storage.write(key: storageKey(provider), value: value);

  Future<void> clear(AiProvider provider) =>
      _storage.delete(key: storageKey(provider));
}

final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => const ApiKeyStore());

/// Seçili sağlayıcı. Sır değil, bu yüzden SharedPreferences'ta tutulur
/// (güvenli depo okuması yavaştır; bu değer her AI çağrısında lazım).
final activeProviderProvider =
    NotifierProvider<ActiveProviderNotifier, AiProvider>(
      ActiveProviderNotifier.new,
    );

class ActiveProviderNotifier extends Notifier<AiProvider> {
  static const prefsKey = 'ai_provider';

  @override
  AiProvider build() => AiProvider.fromId(
    ref.watch(sharedPreferencesProvider).getString(prefsKey),
  );

  void set(AiProvider provider) {
    state = provider;
    ref.read(sharedPreferencesProvider).setString(prefsKey, provider.id);
  }
}

/// Seçili sağlayıcının kayıtlı anahtarı (yoksa null). Ayarlar ekranı
/// kaydettikten sonra invalidate eder.
final activeApiKeyProvider = FutureProvider<String?>((ref) {
  final provider = ref.watch(activeProviderProvider);
  return ref.watch(apiKeyStoreProvider).read(provider);
});

/// Tek tek sağlayıcıların anahtarı — Ayarlar'da "hangi sağlayıcıda anahtar
/// kayıtlı" rozetlerini çizmek için.
final providerApiKeyProvider = FutureProvider.family<String?, AiProvider>(
  (ref, provider) => ref.watch(apiKeyStoreProvider).read(provider),
);
