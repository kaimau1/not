import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gemini API anahtarı yalnızca cihazdaki güvenli depoda tutulur
/// (Android Keystore / Windows DPAPI). Firestore'a asla yazılmaz.
class ApiKeyStore {
  const ApiKeyStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _key = 'gemini_api_key';

  Future<String?> read() => _storage.read(key: _key);

  Future<void> save(String value) => _storage.write(key: _key, value: value);

  Future<void> clear() => _storage.delete(key: _key);
}

final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => const ApiKeyStore());

/// Kayıtlı anahtar (yoksa null). Ayarlar ekranı kaydettikten sonra
/// invalidate eder.
final geminiApiKeyProvider = FutureProvider<String?>(
  (ref) => ref.watch(apiKeyStoreProvider).read(),
);
