import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants.dart';
import 'auth_repository.dart';

/// Android: google_sign_in eklentisi ile yerel Google girişi.
class AndroidGoogleAuth implements AuthRepository {
  AndroidGoogleAuth({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<void>? _initFuture;

  Future<void> _ensureInitialized() =>
      _initFuture ??= GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.serverClientId.isEmpty
            ? null
            : AppConstants.serverClientId,
      );

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async =>
      _auth.signInWithCredential(await _googleCredential());

  @override
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  @override
  Future<UserCredential> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return signInWithGoogle();
    return user.linkWithCredential(await _googleCredential());
  }

  Future<AuthCredential> _googleCredential() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
