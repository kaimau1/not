// ============================================================================
// Firebase projesi: notlar-kaimau
//
// Buradaki apiKey değerleri gizli bilgi değildir; Firebase istemci anahtarları
// uygulamanın içine gömülmek üzere tasarlanmıştır. Güvenlik, Firestore/Storage
// kuralları ve Android SHA parmak izi doğrulamasıyla sağlanır.
// ============================================================================

import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static const String _placeholder = 'PLACEHOLDER';

  /// `flutterfire configure` çalıştırılana kadar false döner; uygulama bu
  /// durumda kurulum yönergelerini gösteren ekranı açar.
  static bool get isConfigured => !android.apiKey.contains(_placeholder);

  static FirebaseOptions get currentPlatform {
    // kIsWeb kontrolü Platform'dan ÖNCE gelmeli: dart:io tarayıcıda yok,
    // Platform.isAndroid'e dokunmak orada çalışma anında patlar.
    if (kIsWeb) return web;
    if (Platform.isAndroid) return android;
    throw UnsupportedError(
      'DefaultFirebaseOptions bu platform için yapılandırılmadı.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPO34mCxYxBjnqV2W_WZqvIcUhwhsaEgQ',
    appId: '1:625134692714:android:bb67b809ec89f732249d13',
    messagingSenderId: '625134692714',
    projectId: 'notlar-kaimau',
    storageBucket: 'notlar-kaimau.firebasestorage.app',
  );

  /// Tarayıcı kaydı (konsoldaki eski adı "Notlar Windows" — Windows sürümü
  /// 2026-10-19'da kaldırıldı, kayıt WEB platformunda: appId `...:web:...`).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCIFTCM2A7uXNoRlqS_9dD95C53EwVlAXs',
    appId: '1:625134692714:web:baf58fd4b904b2c8249d13',
    messagingSenderId: '625134692714',
    projectId: 'notlar-kaimau',
    storageBucket: 'notlar-kaimau.firebasestorage.app',
    authDomain: 'notlar-kaimau.firebaseapp.com',
  );
}
