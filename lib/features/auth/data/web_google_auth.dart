import 'package:firebase_auth/firebase_auth.dart';

import 'auth_repository.dart';

/// Tarayıcı: Firebase'in kendi Google popup akışı.
///
/// google_sign_in eklentisi KULLANILMAZ — 7.x sürümünde web tarafı
/// `authenticate()` desteklemiyor (Google Identity Services, girişin kendi
/// çizdiği düğmeye tıklanarak başlatılmasını şart koşuyor), bu yüzden
/// [AndroidGoogleAuth] tarayıcıda sessizce çalışmıyordu. `signInWithPopup`
/// aynı işi eklenti olmadan yapıyor ve ek yapılandırma (client_id meta
/// etiketi, düğme render'ı) istemiyor.
class WebGoogleAuth implements AuthRepository {
  WebGoogleAuth({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  // ponytail: popup, iframe içinde tarayıcılarca engellenebilir. Uygulama
  // AHEK Plus'a gömülünce ya signInWithRedirect'e geçilir ya da (aynı origin +
  // aynı Firebase projesi kullanılırsa) kullanıcı zaten girişli geldiği için
  // bu akış hiç çalışmaz. Tek başına çalışırken popup doğru seçim.
  Future<UserCredential> signInWithGoogle() =>
      _auth.signInWithPopup(GoogleAuthProvider());

  @override
  Future<void> signOut() => _auth.signOut();
}
