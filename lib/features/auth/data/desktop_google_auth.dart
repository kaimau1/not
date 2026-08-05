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
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  @override
  Future<UserCredential> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return signInWithGoogle();
    return user.linkWithCredential(await _googleCredential());
  }

  @override
  Future<UserCredential> signInWithGoogle() async =>
      _auth.signInWithCredential(await _googleCredential());

  Future<AuthCredential> _googleCredential() async {
    final tokens = await DesktopOAuthFlow(
      scopes: const ['openid', 'email', 'profile'],
    ).run();

    // Tarayıcıdan dönüşte uygulama penceresini öne getir.
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}

    // Refresh token artık İSTENMİYOR ve saklanmıyor (bkz. DesktopOAuthFlow —
    // hiçbir yer okumuyordu). signOut'taki clear() eski sürümlerin diske
    // yazdığı token'ı da temizlemeye devam ediyor.
    await _tokenStore.saveGrantedScopes(tokens.grantedScopes);

    return GoogleAuthProvider.credential(
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
  }

  @override
  Future<void> signOut() async {
    await _tokenStore.clear();
    await _auth.signOut();
  }
}
