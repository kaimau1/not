import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/android_google_auth.dart';
import '../data/auth_repository.dart';
import '../data/web_google_auth.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (kIsWeb) return WebGoogleAuth();
  return AndroidGoogleAuth();
});

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Oturum açmış kullanıcının uid'si; oturum yoksa null.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);

/// "Yerel hesap" mı? (Firebase anonim girişi — Google hesabı bağlanmamış.)
///
/// Kısıtlar buna bakar: dahili AI kapalı (anonim kullanıcı çıkıp yeniden
/// girerek yeni uid alıp kotayı sıfırlayabilirdi), satın alma kapalı (hak
/// kurtarılamayan bir hesaba bağlanamaz) ve cihazlar arası senkron yok.
/// Kendi API anahtarını giren anonim kullanıcı tüm AI özelliklerini
/// kullanabilir — orada maliyet kendisinde.
final isAnonymousProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).value?.isAnonymous ?? false,
);
