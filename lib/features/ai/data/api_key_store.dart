import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_provider.dart';

/// API anahtarı yalnızca cihazdaki güvenli depoda tutulur
/// (Android Keystore; web'de tarayıcı deposu). Buluta asla yazılmaz.
class ApiKeyStore {
  const ApiKeyStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  /// TUZAK: Gemini'nin depo anahtarı `gemini_api_key` olarak KALMALI. Eski
  /// sürümler anahtarı bu adla yazdı; şema değişirse güncelleyen kullanıcı
  /// anahtarını kaybeder.
  static String storageKey([AiProvider provider = AiProvider.gemini]) =>
      'gemini_api_key';

  Future<String?> read([AiProvider provider = AiProvider.gemini]) =>
      _storage.read(key: storageKey(provider));

  Future<void> save(AiProvider provider, String value) =>
      _storage.write(key: storageKey(provider), value: value);

  Future<void> clear([AiProvider provider = AiProvider.gemini]) =>
      _storage.delete(key: storageKey(provider));
}

final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => const ApiKeyStore());

/// Kayıtlı Gemini BYOK anahtarı (yoksa null). Ayarlar ekranı kaydettikten
/// sonra bu sağlayıcıyı yeniler.
final activeApiKeyProvider = FutureProvider<String?>((ref) {
  return ref.watch(apiKeyStoreProvider).read();
});
