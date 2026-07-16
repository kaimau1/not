// ============================================================================
// YER TUTUCU DOSYA — GERÇEK DEĞERLERLE DEĞİŞTİRİLMELİ
//
// Bu dosyayı FlutterFire CLI ile yeniden üretin:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --platforms=android,windows
//
// Ayrıntılar için README.md içindeki "Kurulum" bölümüne bakın.
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
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    storageBucket: _placeholder,
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    storageBucket: _placeholder,
    authDomain: _placeholder,
  );
}
