import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Masaüstü OAuth akışında verilen kapsamları güvenli depoda (Windows DPAPI /
/// Android Keystore) saklar. Refresh token artık istenmiyor da saklanmıyor
/// (bkz. DesktopOAuthFlow); [clear] eski sürümlerin yazdığı token'ı yine de
/// siler ki diskte uzun ömürlü kimlik bilgisi kalmasın.
class TokenStore {
  const TokenStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _refreshTokenKey = 'google_refresh_token';
  static const _scopesKey = 'google_granted_scopes';

  Future<List<String>> readGrantedScopes() async {
    final raw = await _storage.read(key: _scopesKey);
    if (raw == null || raw.isEmpty) return const [];
    return raw.split(' ');
  }

  Future<void> saveGrantedScopes(List<String> scopes) =>
      _storage.write(key: _scopesKey, value: scopes.join(' '));

  Future<void> clear() async {
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _scopesKey);
  }
}
