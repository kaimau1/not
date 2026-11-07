import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants.dart';
import '../../../core/utils/gms.dart';
import 'auth_repository.dart';

/// Android: google_sign_in eklentisi ile yerel Google girişi.
class AndroidGoogleAuth implements AuthRepository {
  AndroidGoogleAuth({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// `initialize` süreç başına TEK kez çağrılmalı — giriş ve Drive yetkisi
  /// (bkz. drive_store.dart) aynı kapıdan geçer.
  static Future<void>? _initFuture;

  static Future<void> ensureInitialized() =>
      _initFuture ??= GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.serverClientId.isEmpty
            ? null
            : AppConstants.serverClientId,
      );

  Future<void> _ensureInitialized() => ensureInitialized();

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Stream<User?> userChanges() => _auth.userChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    final AuthCredential credential;
    try {
      credential = await _googleCredential();
    } on _UseBrowserFlow {
      return _auth.signInWithProvider(_browserProvider());
    }
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  @override
  Future<UserCredential> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return signInWithGoogle();
    final AuthCredential credential;
    try {
      credential = await _googleCredential();
    } on _UseBrowserFlow {
      return user.linkWithProvider(_browserProvider());
    }
    return user.linkWithCredential(credential);
  }

  /// **TABLETTE GİRİŞ** (kullanıcı bulgusu 2026-11-02: "tablette Google
  /// bağlantısı çalışmıyor"). Yerel giriş Credential Manager'dan geçer; bazı
  /// tabletlerde (hesap/Play Hizmetleri sürümü, çoklu kullanıcı profili)
  /// seçici HİÇ açılmadan `canceled` / `noCredential` / yapılandırma hatası
  /// döner — kullanıcı düğmeye basar, hiçbir şey olmaz. Yerel yol böyle
  /// düşerse Firebase'in tarayıcı (Custom Tabs) akışına geçilir.
  ///
  /// Gerçek iptali (kullanıcı seçiciyi kapattı) ayırmak için süre bakılır:
  /// seçici açıldıysa kapatılması insan hızında olur (≥ [_instantCancel]);
  /// anında gelen iptal, seçicinin hiç görünmediği demektir.
  Future<AuthCredential> _googleCredential() async {
    // GMS yok (Huawei): yerel seçici hiç açılmaz, doğrudan tarayıcı.
    if (!await gmsInstalled()) throw const _UseBrowserFlow();
    await _ensureInitialized();
    final started = DateTime.now();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (shouldUseBrowserFlow(e.code, DateTime.now().difference(started))) {
        throw const _UseBrowserFlow();
      }
      rethrow;
    }
  }

  static const _instantCancel = Duration(milliseconds: 1500);

  /// Yerel giriş hatası tarayıcı akışıyla yeniden denenmeli mi?
  @visibleForTesting
  static bool shouldUseBrowserFlow(
    GoogleSignInExceptionCode code,
    Duration elapsed,
  ) => switch (code) {
    GoogleSignInExceptionCode.canceled ||
    GoogleSignInExceptionCode.interrupted => elapsed < _instantCancel,
    // Kullanıcı başka hesap seçti: yeniden sormak doğru değil.
    GoogleSignInExceptionCode.userMismatch => false,
    _ => true,
  };

  static GoogleAuthProvider _browserProvider() =>
      GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});

  @override
  Future<void> signOut() async {
    if (await gmsInstalled()) {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }
}

/// Yerel giriş düştü, tarayıcı akışına geç (yalnız bu dosyanın içinde).
class _UseBrowserFlow implements Exception {
  const _UseBrowserFlow();
}
