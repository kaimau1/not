import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../../../core/utils/gms.dart';
import '../../../core/utils/web_session.dart';
import 'android_google_auth.dart';

/// Tek kapsamlı Google jeton kaynağı (Gmail F28.1, Drive F28.2). Kapsamlar AYRI
/// istenir: biri ötekini genişletmez, kullanıcı ikisini ayrı onaylar.
abstract class GoogleScopeAuth {
  /// Pencere açmadan jeton (Android: önceden verilmiş yetki; web: sekmede
  /// saklı, süresi dolmamış jeton). Yoksa null.
  Future<({String token, DateTime expiry})?> silent();

  /// Kullanıcıdan izin ister (Google onay penceresi).
  Future<({String token, DateTime expiry})?> connect();
}

/// Android jetonunun ömrü bildirilmez; ~1 saat verilir, 50 dk sayılır.
const _assumedLife = Duration(minutes: 50);

/// **GMS'SİZ ANDROID** (tablet bulgusu 2026-11-07, Huawei MatePad: "Google
/// hizmetleri GBox ile, verimli değil"). Play Hizmetleri yoksa
/// google_sign_in'in yetki istemcisi hiç çalışmaz; jeton Firebase'in
/// tarayıcı akışıyla (Custom Tabs, kapsamla yeniden doğrulama) alınır —
/// webdeki açılır pencerenin Android karşılığı. Yenileme anahtarı yok:
/// jeton ~55 dk cihazda (şifreli depo, uid'e bağlı) saklanır, dolunca
/// arayüz yeniden "bağla" der.
@visibleForTesting
FlutterSecureStorage browserTokenStorage = const FlutterSecureStorage();

Future<({String token, DateTime expiry})?> storedBrowserToken(
  String key,
) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final String? raw;
  try {
    raw = await browserTokenStorage.read(key: key);
  } catch (_) {
    return null;
  }
  return parseScopeToken(raw, uid, DateTime.now());
}

/// `jeton|bitişMs|uid` — başka hesabın ya da süresi dolmuş jetonu null.
@visibleForTesting
({String token, DateTime expiry})? parseScopeToken(
  String? raw,
  String uid,
  DateTime now,
) {
  if (raw == null) return null;
  final parts = raw.split('|');
  if (parts.length != 3 || parts[2] != uid) return null;
  final ms = int.tryParse(parts[1]);
  if (ms == null) return null;
  final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
  if (now.isAfter(expiry)) return null;
  return (token: parts[0], expiry: expiry);
}

Future<({String token, DateTime expiry})?> browserScopeToken(
  List<String> scopes,
  String key,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final provider = GoogleAuthProvider();
  for (final scope in scopes) {
    provider.addScope(scope);
  }
  final email = user.email;
  if (email != null) provider.setCustomParameters({'login_hint': email});
  final result = await user.reauthenticateWithProvider(provider);
  final credential = result.credential;
  final token = credential is OAuthCredential ? credential.accessToken : null;
  if (token == null) return null;
  final expiry = DateTime.now().add(const Duration(minutes: 55));
  try {
    await browserTokenStorage.write(
      key: key,
      value: '$token|${expiry.millisecondsSinceEpoch}|${user.uid}',
    );
  } catch (_) {
    // Saklanamazsa bu oturumda yine kullanılır (önbellek bellekte).
  }
  return (token: token, expiry: expiry);
}

Future<void> forgetBrowserToken(String key) async {
  try {
    await browserTokenStorage.delete(key: key);
  } catch (_) {}
}

class _AndroidScopeAuth implements GoogleScopeAuth {
  _AndroidScopeAuth(this.scope, this._key);

  final String scope;
  final String _key;

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
              scopes: [scope],
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
    if (!await gmsInstalled()) return storedBrowserToken(_key);
    try {
      return await _authorize(false);
    } catch (e) {
      debugPrint('Google jetonu alınamadı: $e');
      return null;
    }
  }

  @override
  Future<({String token, DateTime expiry})?> connect() async =>
      await gmsInstalled()
      ? _authorize(true)
      : browserScopeToken([scope], _key);
}

/// Web: Firebase'in Google açılır penceresi kapsamla yeniden
/// doğrulanır. Jeton SEKMEDE (`sessionStorage`, uid'e bağlı) — sayfa
/// yenilemesinde yeniden pencere istenmez; süre dolunca istenir (web'de
/// yenileme anahtarı yok).
class _WebScopeAuth implements GoogleScopeAuth {
  _WebScopeAuth(this.scope, this._key);

  final String scope;
  final String _key;

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
    final provider = GoogleAuthProvider()..addScope(scope);
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

/// [sessionKey]: web'de jetonun sekmede, GMS'siz Android'de şifreli depoda
/// saklandığı anahtar.
GoogleScopeAuth googleScopeAuth(String scope, String sessionKey) =>
    kIsWeb
    ? _WebScopeAuth(scope, sessionKey)
    : _AndroidScopeAuth(scope, sessionKey);

/// Kapsam jetonunun önbelleği: süresi [refreshMargin] içinde dolacaksa
/// [silentRefresh] ile pencere açmadan yenilenir; eşzamanlı istekler tek
/// yenilemeyi bekler. Yenilenemezse null (arayüz "bağla" der).
class ScopeTokenCache {
  ScopeTokenCache({
    required this.silentRefresh,
    DateTime Function()? clock,
    this.refreshMargin = const Duration(minutes: 2),
  }) : _now = clock ?? DateTime.now;

  final Future<({String token, DateTime expiry})?> Function() silentRefresh;
  final DateTime Function() _now;
  final Duration refreshMargin;

  String? _token;
  DateTime? _expiry;
  Future<String?>? _inFlight;

  void put(String token, DateTime expiry) {
    _token = token;
    _expiry = expiry;
  }

  void invalidate() {
    _token = null;
    _expiry = null;
  }

  Future<String?> get() {
    final t = _token, e = _expiry;
    if (t != null && e != null && _now().add(refreshMargin).isBefore(e)) {
      return Future.value(t);
    }
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<String?> _refresh() async {
    try {
      final r = await silentRefresh();
      if (r == null) {
        invalidate();
        return null;
      }
      put(r.token, r.expiry);
      return r.token;
    } catch (_) {
      invalidate();
      return null;
    }
  }
}
