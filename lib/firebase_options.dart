// ============================================================================
// Firebase projesi: notlar-kaimau
//
// Buradaki apiKey değerleri gizli bilgi değildir; Firebase istemci anahtarları
// uygulamanın içine gömülmek üzere tasarlanmıştır. Güvenlik, Firestore/Storage
// kuralları ve Android SHA parmak izi doğrulamasıyla sağlanır.
// ============================================================================

import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const String _placeholder = 'PLACEHOLDER';

  /// `flutterfire configure` çalıştırılana kadar false döner; uygulama bu
  /// durumda kurulum yönergelerini gösteren ekranı açar.
  static bool get isConfigured => !android.apiKey.contains(_placeholder);

  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) return android;
    if (Platform.isWindows) return windows;
    throw UnsupportedError(
      'DefaultFirebaseOptions yalnızca Android ve Windows için yapılandırıldı.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPO34mCxYxBjnqV2W_WZqvIcUhwhsaEgQ',
    appId: '1:625134692714:android:bb67b809ec89f732249d13',
    messagingSenderId: '625134692714',
    projectId: 'notlar-kaimau',
    storageBucket: 'notlar-kaimau.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCIFTCM2A7uXNoRlqS_9dD95C53EwVlAXs',
    appId: '1:625134692714:web:baf58fd4b904b2c8249d13',
    messagingSenderId: '625134692714',
    projectId: 'notlar-kaimau',
    storageBucket: 'notlar-kaimau.firebasestorage.app',
    authDomain: 'notlar-kaimau.firebaseapp.com',
  );
}
