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

/// Oturumdaki kullanıcı. `userChanges` üzerinden: Google hesabı BAĞLANINCA
/// (uid aynı, yalnız anonimlik/ad/e-posta değişir) da yeni değer gelir —
/// misafir kartları ve "yerel hesap" kısıtları yeniden başlatmadan kalkar.
/// Belirteç tazelemeleri (saatlik) aynı özetle geldiği için süzülür: her
/// saat bütün dinleyicileri yeniden kurmasın.
final authStateProvider = StreamProvider<User?>((ref) {
  Object? last;
  var first = true;
  return ref.watch(authRepositoryProvider).userChanges().where((user) {
    // Özet olay ANINDA ilkel değerlerden kurulur: web'de User nesnesi
    // yerinde güncellenebiliyor, nesneyi saklamak hep "aynı" derdi.
    final key = (
      user?.uid,
      user?.isAnonymous,
      user?.email,
      user?.displayName,
      user?.photoURL,
    );
    if (!first && key == last) return false;
    first = false;
    last = key;
    return true;
  });
});

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
