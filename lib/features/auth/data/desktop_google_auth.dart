import 'package:firebase_auth/firebase_auth.dart';
import 'package:window_manager/window_manager.dart';

import 'auth_repository.dart';
import 'desktop_oauth_flow.dart';
import 'token_store.dart';

/// Windows: loopback PKCE akışı ile Google girişi.
class DesktopGoogleAuth implements AuthRepository {
  DesktopGoogleAuth({FirebaseAuth? auth, TokenStore? tokenStore})
    : _auth = auth ?? FirebaseAuth.instance,
      _tokenStore = tokenStore ?? const TokenStore();

  final FirebaseAuth _auth;
  final TokenStore _tokenStore;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    final tokens = await DesktopOAuthFlow(
      scopes: const ['openid', 'email', 'profile'],
    ).run();

    // Tarayıcıdan dönüşte uygulama penceresini öne getir.
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}

    if (tokens.refreshToken != null) {
      await _tokenStore.saveRefreshToken(tokens.refreshToken!);
      await _tokenStore.saveGrantedScopes(tokens.grantedScopes);
    }

    final credential = GoogleAuthProvider.credential(
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _tokenStore.clear();
    await _auth.signOut();
  }
}
