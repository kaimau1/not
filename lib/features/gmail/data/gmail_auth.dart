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

/// Bağlı Gmail hesabının e-postası (varsa) — Ayarlar'da gösterilir.
final gmailAccountEmailProvider = Provider<String?>(
  (ref) =>
      ref.watch(sharedPreferencesProvider).getString(GmailAuth.accountKey),
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
  static const accountKey = 'gmail_account_email';

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  // google_sign_in 7.x'te authenticate()/authorizeScopes() öncesi initialize()
  // ŞART. Firebase oturumu kalıcı olduğundan kullanıcı uygulamayı tekrar
  // açtığında Google girişinden geçmeyebilir; bu durumda GoogleSignIn.instance
  // hiç başlatılmamış olur ve Gmail'i bağlarken "bir sorun oluştu" hatası
  // verirdi. Tek seferlik, tembel başlatma ile bunu garanti altına alıyoruz.
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() => _initFuture ??= _initialize();

  Future<void> _initialize() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.serverClientId.isEmpty
            ? null
            : AppConstants.serverClientId,
      );
    } catch (_) {
      // Uygulamanın başka yerinde (Android Google girişi) GoogleSignIn zaten
      // başlatılmış olabilir; ikinci initialize çağrısının hatasını yut.
      // Gerçekten başlatılamadıysa sonraki authenticate() zaten anlamlı bir
      // hata fırlatır ve çağıran onu gösterir.
    }
  }

  /// Kullanıcı Ayarlar'dan "Gmail'i Bağla"ya bastığında çağrılır.
  /// Hesap seçici gösterir (giriş hesabından farklı bir Gmail de
  /// seçilebilir), gerekli izni alır ve bağlantı bayrağını kaydeder.
  Future<void> connect() async {
    if (_isWindows) {
      await _ensureDesktopScope(forcePrompt: true);
    } else {
      await _ensureInitialized();
      // authenticate() hesap seçiciyi açar; kullanıcı ikinci bir Gmail
      // hesabını da burada seçebilir. authorizeScopes tek başına seçici
      // göstermeden mevcut hesabı kullanıyordu.
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const [AppConstants.gmailReadonlyScope],
      );
      await account.authorizationClient
          .authorizeScopes(const [AppConstants.gmailReadonlyScope]);
      await _prefs.setString(accountKey, account.email);
    }
    await _prefs.setBool(prefKey, true);
  }

  Future<void> disconnect() async {
    await _prefs.setBool(prefKey, false);
    await _prefs.remove(accountKey);
    if (_isWindows) {
      // Gmail kapsamı düşsün diye kayıtlı token'ı bırak; yalnızca kapsam
      // kaydını temizle.
      await _tokenStore.saveGrantedScopes(const []);
    }
  }

  /// Gmail API çağrıları için yetkili istemci döner.
  Future<http.Client> getClient() async {
    if (_isWindows) return _desktopClient();
    await _ensureInitialized();
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
