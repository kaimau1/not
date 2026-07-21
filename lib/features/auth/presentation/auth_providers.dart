import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/android_google_auth.dart';
import '../data/auth_repository.dart';
import '../data/desktop_google_auth.dart';
import '../data/web_google_auth.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (kIsWeb) return WebGoogleAuth();
  if (Platform.isWindows) return DesktopGoogleAuth();
  return AndroidGoogleAuth();
});

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Oturum açmış kullanıcının uid'si; oturum yoksa null.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);
