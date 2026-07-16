import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../auth/data/desktop_oauth_flow.dart';
import '../../auth/data/token_store.dart';
import '../../settings/settings_providers.dart';

final gmailAuthProvider = Provider<GmailAuth>(
  (ref) => GmailAuth(ref.watch(sharedPreferencesProvider)),
);

/// Gmail bağlantı durumu (Ayarlar'daki anahtara göre).
final gmailConnectedProvider = Provider<bool>(
  (ref) => ref.watch(sharedPreferencesProvider).getBool(GmailAuth.prefKey) ??
      false,
);

/// Gmail için platforma göre yetkili HTTP istemcisi üretir.
/// - Android: google_sign_in artımlı kapsam yetkilendirmesi.
/// - Windows: masaüstü loopback OAuth akışı + refresh token.
class GmailAuth {
  GmailAuth(this._prefs, {TokenStore? tokenStore})
      : _tokenStore = tokenStore ?? const TokenStore();

  final SharedPreferences _prefs;
  final TokenStore _tokenStore;

  static const prefKey = 'gmail_connected';

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  /// Kullanıcı Ayarlar'dan "Gmail'i Bağla"ya bastığında çağrılır.
  /// Gerekli izni alır ve bağlantı bayrağını kaydeder.
  Future<void> connect() async {
    if (_isWindows) {
      await _ensureDesktopScope(forcePrompt: true);
    } else {
      await GoogleSignIn.instance.authorizationClient
          .authorizeScopes(const [AppConstants.gmailReadonlyScope]);
    }
    await _prefs.setBool(prefKey, true);
  }

  Future<void> disconnect() async {
    await _prefs.setBool(prefKey, false);
    if (_isWindows) {
      // Gmail kapsamı düşsün diye kayıtlı token'ı bırak; yalnızca kapsam
      // kaydını temizle.
      await _tokenStore.saveGrantedScopes(const []);
    }
  }

  /// Gmail API çağrıları için yetkili istemci döner.
  Future<http.Client> getClient() async {
    if (_isWindows) return _desktopClient();
    final authorization = await GoogleSignIn.instance.authorizationClient
        .authorizeScopes(const [AppConstants.gmailReadonlyScope]);
    return authorization.authClient(
      scopes: const [AppConstants.gmailReadonlyScope],
    );
  }

  Future<String> _ensureDesktopScope({bool forcePrompt = false}) async {
    final refreshToken = await _tokenStore.readRefreshToken();
    final scopes = await _tokenStore.readGrantedScopes();
    final hasScope = scopes.contains(AppConstants.gmailReadonlyScope);
    if (!forcePrompt && refreshToken != null && hasScope) return refreshToken;

    final tokens = await DesktopOAuthFlow(
      scopes: const [
        'openid',
        'email',
        'profile',
        AppConstants.gmailReadonlyScope,
      ],
    ).run();
    if (tokens.refreshToken == null) {
      throw StateError('Google refresh token vermedi; tekrar deneyin.');
    }
    await _tokenStore.saveRefreshToken(tokens.refreshToken!);
    await _tokenStore.saveGrantedScopes(tokens.grantedScopes);
    return tokens.refreshToken!;
  }

  Future<http.Client> _desktopClient() async {
    final refreshToken = await _ensureDesktopScope();
    final fresh = await DesktopOAuthFlow.refresh(refreshToken);
    final credentials = gauth.AccessCredentials(
      gauth.AccessToken(
        'Bearer',
        fresh.accessToken,
        DateTime.now().toUtc().add(Duration(seconds: fresh.expiresIn - 60)),
      ),
      refreshToken,
      const [AppConstants.gmailReadonlyScope],
    );
    return gauth.authenticatedClient(http.Client(), credentials);
  }
}
