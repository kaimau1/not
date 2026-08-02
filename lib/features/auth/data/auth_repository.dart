import 'package:firebase_auth/firebase_auth.dart';

/// Platformdan bağımsız kimlik doğrulama arayüzü. Android'de
/// [AndroidGoogleAuth], Windows'ta [DesktopGoogleAuth], tarayıcıda
/// [WebGoogleAuth] uygular.
abstract interface class AuthRepository {
  Stream<User?> authStateChanges();

  User? get currentUser;

  Future<UserCredential> signInWithGoogle();

  /// "Yerel hesap": Google hesabı istemeden anında kullanıma başlatır.
  ///
  /// Teknik olarak Firebase anonim girişidir — kullanıcı yine bir uid alır,
  /// notlar yine Firestore'a yazılır (offline önbellekle birlikte). Farkı
  /// hesabın CİHAZA bağlı olması: başka cihazdan erişilemez ve uygulama
  /// silinirse geri getirilemez. Sonradan [linkWithGoogle] ile gerçek hesaba
  /// yükseltilebilir; uid aynı kaldığı için notlar olduğu yerde kalır.
  Future<UserCredential> signInAnonymously();

  /// Yerel hesabı Google hesabına BAĞLAR (yeni oturum açmaz).
  ///
  /// `signInWithGoogle` çağırmak yerine bağlama yapılır: yeni giriş yeni uid
  /// demektir ve anonim hesapta biriken bütün notlar erişilemez hâle gelirdi.
  Future<UserCredential> linkWithGoogle();

  Future<void> signOut();
}
