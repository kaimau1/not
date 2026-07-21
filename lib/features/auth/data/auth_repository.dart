import 'package:firebase_auth/firebase_auth.dart';

/// Platformdan bağımsız kimlik doğrulama arayüzü. Android'de
/// [AndroidGoogleAuth], Windows'ta [DesktopGoogleAuth], tarayıcıda
/// [WebGoogleAuth] uygular.
abstract interface class AuthRepository {
  Stream<User?> authStateChanges();

  User? get currentUser;

  Future<UserCredential> signInWithGoogle();

  Future<void> signOut();
}
