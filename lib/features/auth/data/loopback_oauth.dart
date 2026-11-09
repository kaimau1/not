import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// **GMS'SİZ ANDROID'DE GOOGLE YETKİSİ — FIREBASE SAYFASIZ** (tablet bulgusu
/// 2026-11-09, Huawei + GBox: "Unable to process request due to missing
/// initial state…" ve "A headful operation is already in progress").
///
/// Firebase'in tarayıcı akışı `firebaseapp.com/__/auth/handler` sayfasının
/// sekme deposuna (`sessionStorage`) güvenir; Huawei tarayıcısı Google'dan
/// dönüşü başka sekmede/görevde açınca depo boş kalıyor, giriş hiç bitmiyor
/// (senkron da bu yüzden duruyordu: hesap açılamıyordu). Yarım kalan akış
/// Firebase'de "sürüyor" sayıldığı için sonraki deneme de "headful" hatası
/// veriyordu.
///
/// Burada standart "masaüstü uygulaması" OAuth akışı (PKCE + geri dönüş
/// adresi `http://127.0.0.1:<port>`) kullanılır: tarayıcı tarafında saklanan
/// durum YOK, dönüşü uygulamanın kendi küçük sunucusu karşılar. Yenileme
/// anahtarı da verildiği için saatte bir "bağla" demek gerekmez.
///
/// Gerekli: Google Cloud Console'da AYNI projede (notlar-kaimau) "Masaüstü
/// uygulaması" türünde OAuth istemcisi; kimliği ve sırrı derlemeye
/// `GOOGLE_DESKTOP_CLIENT_ID` / `GOOGLE_DESKTOP_CLIENT_SECRET` olarak geçer
/// (masaüstü istemci sırrı Google'ın tanımıyla gizli değildir). Boşsa eski
/// Firebase akışı kullanılır.
const _clientId = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID');
const _clientSecret = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_SECRET');

bool get loopbackOAuthEnabled =>
    !kIsWeb && _clientId.isNotEmpty && _clientSecret.isNotEmpty;

typedef LoopbackTokens = ({
  String accessToken,
  DateTime expiry,
  String? refreshToken,
  String? idToken,
});

const _tokenUrl = 'https://oauth2.googleapis.com/token';

@visibleForTesting
String pkceChallenge(String verifier) => base64Url
    .encode(sha256.convert(ascii.encode(verifier)).bytes)
    .replaceAll('=', '');

String _randomToken([int bytes = 32]) {
  final r = Random.secure();
  return base64Url
      .encode(List<int>.generate(bytes, (_) => r.nextInt(256)))
      .replaceAll('=', '');
}

@visibleForTesting
Uri loopbackAuthUrl({
  required String clientId,
  required List<String> scopes,
  required String redirect,
  required String state,
  required String challenge,
  String? email,
}) => Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
  'client_id': clientId,
  'redirect_uri': redirect,
  'response_type': 'code',
  'scope': scopes.join(' '),
  'state': state,
  'code_challenge': challenge,
  'code_challenge_method': 'S256',
  // Yenileme anahtarı her seferinde gelsin (yalnız ilk onayda verilir).
  'access_type': 'offline',
  'prompt': 'consent',
  'login_hint': ?email,
});

@visibleForTesting
LoopbackTokens? parseTokenResponse(String body, DateTime now) {
  final Object? j;
  try {
    j = jsonDecode(body);
  } catch (_) {
    return null;
  }
  if (j is! Map || j['access_token'] is! String) return null;
  final secs = (j['expires_in'] as num?)?.toInt() ?? 3600;
  return (
    accessToken: j['access_token'] as String,
    // 1 dk pay: süre dolmadan yenilensin.
    expiry: now.add(Duration(seconds: max(0, secs - 60))),
    refreshToken: j['refresh_token'] as String?,
    idToken: j['id_token'] as String?,
  );
}

// ponytail: tek akış aynı anda — iki "bağla" üst üste gelirse ikincisi
// birincinin sonucunu bekler (eski "headful" hatasının bu taraftaki karşılığı).
Future<LoopbackTokens?>? _running;

/// Tarayıcıda Google onayını açar, dönüşü yerel sunucuda karşılar. İptal /
/// 5 dk yanıtsızlık → null.
Future<LoopbackTokens?> loopbackAuthorize(
  List<String> scopes, {
  String? email,
}) =>
    _running ??= _authorize(scopes, email).whenComplete(() => _running = null);

Future<LoopbackTokens?> _authorize(List<String> scopes, String? email) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  try {
    final redirect = 'http://127.0.0.1:${server.port}';
    final verifier = _randomToken(48);
    final state = _randomToken(16);
    final url = loopbackAuthUrl(
      clientId: _clientId,
      scopes: scopes,
      redirect: redirect,
      state: state,
      challenge: pkceChallenge(verifier),
      email: email,
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      return null;
    }
    String? code;
    await for (final req in server.timeout(const Duration(minutes: 5))) {
      final q = req.uri.queryParameters;
      if (q['state'] != state) {
        // Tarayıcının favicon vb. istekleri.
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        continue;
      }
      code = q['code'];
      req.response.headers.contentType = ContentType.html;
      req.response.write(
        '<html><body style="font:18px sans-serif;text-align:center;'
        'padding-top:30vh">${code == null ? 'İptal edildi.' : 'Tamam — Not uygulamasına dönebilirsin.'}'
        '</body></html>',
      );
      await req.response.close();
      break;
    }
    if (code == null) return null;
    final res = await http.post(
      Uri.parse(_tokenUrl),
      body: {
        'code': code,
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'redirect_uri': redirect,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
      },
    );
    if (res.statusCode != 200) {
      debugPrint('Google jeton değişimi: ${res.statusCode} ${res.body}');
      return null;
    }
    return parseTokenResponse(res.body, DateTime.now());
  } on TimeoutException {
    return null;
  } finally {
    await server.close(force: true);
  }
}

/// Yenileme anahtarıyla pencere açmadan yeni erişim jetonu; geçersizse null.
Future<LoopbackTokens?> loopbackRefresh(String refreshToken) async {
  try {
    final res = await http.post(
      Uri.parse(_tokenUrl),
      body: {
        'refresh_token': refreshToken,
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'grant_type': 'refresh_token',
      },
    );
    if (res.statusCode != 200) return null;
    final t = parseTokenResponse(res.body, DateTime.now());
    // Google yenilemede yeni anahtar vermez; eskisi geçerli kalır.
    return t == null
        ? null
        : (
            accessToken: t.accessToken,
            expiry: t.expiry,
            refreshToken: t.refreshToken ?? refreshToken,
            idToken: t.idToken,
          );
  } catch (_) {
    return null;
  }
}
