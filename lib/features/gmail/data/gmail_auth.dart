import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/web_session.dart';
import '../../auth/data/android_google_auth.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/drive_files_api.dart' show DriveTokenCache;
import '../../notes/data/drive_store.dart' show isGoogleUser;
import 'gmail_api.dart';

/// Gmail jeton kaynağı (F28.1). Drive'ınkiyle aynı iki yol, AYRI kapsam:
/// Gmail izni Drive iznini genişletmez, Drive'ı bağlayan Gmail'e
/// erişmiş olmaz (kullanıcı ikisini ayrı onaylar).
abstract class GmailAuth {
  /// Pencere açmadan jeton (Android: önceden verilmiş yetki; web: sekmede
  /// saklı, süresi dolmamış jeton). Yoksa null.
  Future<({String token, DateTime expiry})?> silent();

  /// Kullanıcıdan izin ister (Google onay penceresi).
  Future<({String token, DateTime expiry})?> connect();
}

/// Android jetonunun ömrü bildirilmez; ~1 saat verilir, 50 dk sayılır.
const _assumedLife = Duration(minutes: 50);

class AndroidGmailAuth implements GmailAuth {
  String? get _email {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    for (final p in user.providerData) {
      if (p.providerId == 'google.com' && p.email != null) return p.email;
    }
    return user.email;
  }

  Future<({String token, DateTime expiry})?> _authorize(bool prompt) async {
    await AndroidGoogleAuth.ensureInitialized();
    final data = await GoogleSignInPlatform.instance
        .clientAuthorizationTokensForScopes(
          ClientAuthorizationTokensForScopesParameters(
            request: AuthorizationRequestDetails(
              scopes: const [kGmailReadonlyScope],
              userId: null,
              email: _email,
              promptIfUnauthorized: prompt,
            ),
          ),
        );
    final t = data?.accessToken;
    return t == null
        ? null
        : (token: t, expiry: DateTime.now().add(_assumedLife));
  }

  @override
  Future<({String token, DateTime expiry})?> silent() async {
    try {
      return await _authorize(false);
    } catch (e) {
      debugPrint('Gmail jetonu alınamadı: $e');
      return null;
    }
  }

  @override
  Future<({String token, DateTime expiry})?> connect() => _authorize(true);
}

/// Web: Firebase'in Google açılır penceresi Gmail kapsamıyla yeniden
/// doğrulanır. Jeton SEKMEDE (`sessionStorage`, uid'e bağlı) — sayfa
/// yenilemesinde yeniden pencere istenmez; süre dolunca istenir (web'de
/// yenileme anahtarı yok).
class WebGmailAuth implements GmailAuth {
  static const _key = 'notlar_gmail_token';

  @override
  Future<({String token, DateTime expiry})?> silent() async {
    final raw = sessionRead(_key);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (raw == null || uid == null) return null;
    final parts = raw.split('|');
    if (parts.length != 3 || parts[2] != uid) return null;
    final ms = int.tryParse(parts[1]);
    if (ms == null) return null;
    final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
    if (DateTime.now().isAfter(expiry)) return null;
    return (token: parts[0], expiry: expiry);
  }

  @override
  Future<({String token, DateTime expiry})?> connect() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final provider = GoogleAuthProvider()..addScope(kGmailReadonlyScope);
    final email = user.email;
    if (email != null) provider.setCustomParameters({'login_hint': email});
    final result = await user.reauthenticateWithPopup(provider);
    final credential = result.credential;
    final token = credential is OAuthCredential ? credential.accessToken : null;
    if (token == null) return null;
    final expiry = DateTime.now().add(const Duration(minutes: 55));
    sessionWrite(_key, '$token|${expiry.millisecondsSinceEpoch}|${user.uid}');
    return (token: token, expiry: expiry);
  }
}

/// Gmail yalnız Google hesabında (misafirde yok) ve Android/web'de.
final gmailAvailableProvider = Provider<bool>((ref) {
  if (!isGoogleUser(ref.watch(authStateProvider).value)) return false;
  return kIsWeb || Platform.isAndroid;
});

final gmailAuthProvider = Provider<GmailAuth?>((ref) {
  if (!ref.watch(gmailAvailableProvider)) return null;
  return kIsWeb ? WebGmailAuth() : AndroidGmailAuth();
});

/// Oturum boyunca tek jeton önbelleği + istemci (hesap değişince yenilenir).
final gmailSessionProvider =
    Provider<({GmailApi api, DriveTokenCache tokens, GmailAuth auth})?>((ref) {
      ref.watch(currentUidProvider);
      final auth = ref.watch(gmailAuthProvider);
      if (auth == null) return null;
      final tokens = DriveTokenCache(silentRefresh: auth.silent);
      final client = http.Client();
      ref.onDispose(client.close);
      return (
        api: GmailApi(client: client, tokens: tokens),
        tokens: tokens,
        auth: auth,
      );
    });
