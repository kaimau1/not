import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';

class OAuthTokens {
  const OAuthTokens({
    required this.accessToken,
    required this.expiresIn,
    this.idToken,
    this.refreshToken,
    this.grantedScopes = const [],
  });

  final String accessToken;
  final int expiresIn;
  final String? idToken;
  final String? refreshToken;
  final List<String> grantedScopes;
}

/// Windows'ta Google girişi: sistem tarayıcısı üzerinden
/// Authorization Code + PKCE + loopback (127.0.0.1) yönlendirme akışı.
/// Google'ın "installed app" istemcileri için önerdiği standart yöntemdir.
class DesktopOAuthFlow {
  DesktopOAuthFlow({
    required this.scopes,
    this.timeout = const Duration(minutes: 5),
    this.offline = false,
  });

  final List<String> scopes;
  final Duration timeout;

  /// Yenileme anahtarı istensin mi. Giriş İSTEMEZ (aşağıdaki not); yalnız
  /// arka planda saatlerce çalışan Drive ek senkronu ister (bkz.
  /// DesktopDriveAuth — anahtar yalnız `drive.appdata` kapsamlı).
  final bool offline;

  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';

  Future<OAuthTokens> run() async {
    if (AppConstants.desktopClientId.isEmpty) {
      throw StateError(
        'GOOGLE_DESKTOP_CLIENT_ID tanımlı değil. Uygulamayı '
        '--dart-define=GOOGLE_DESKTOP_CLIENT_ID=... ile derleyin (bkz. README).',
      );
    }

    final verifier = _randomString(64);
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');
    final state = _randomString(32);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri =
        'http://${InternetAddress.loopbackIPv4.address}:${server.port}';

    final authUri = Uri.parse(_authEndpoint).replace(
      queryParameters: {
        'client_id': AppConstants.desktopClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes.join(' '),
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': state,
        // access_type=offline BİLEREK YOK: refresh token istenmiyor. Firebase
        // Auth kendi oturumunu kendi yeniliyor; eskiden istenip güvenli
        // depoda saklanan refresh token'ı kodun HİÇBİR yeri okumuyordu —
        // uzun ömürlü bir Google kimlik bilgisini boşuna diskte tutmak
        // yalnızca saldırı yüzeyi büyütüyordu. ('prompt=consent' de onunla
        // birlikte gitti: tek amacı refresh token'ı her girişte döndürmekti.)
        'include_granted_scopes': 'true',
        if (offline) ...{'access_type': 'offline', 'prompt': 'consent'},
      },
    );

    try {
      if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
        throw StateError('Tarayıcı açılamadı: $authUri');
      }

      final request = await server.first.timeout(timeout);
      final params = request.uri.queryParameters;

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_resultPage(success: params['error'] == null));
      await request.response.close();

      if (params['error'] != null) {
        throw StateError('Google girişi reddedildi: ${params['error']}');
      }
      if (params['state'] != state) {
        throw StateError('OAuth state doğrulaması başarısız.');
      }
      final code = params['code'];
      if (code == null || code.isEmpty) {
        throw StateError('Google yetkilendirme kodu alınamadı.');
      }

      return await _exchangeCode(
        code: code,
        verifier: verifier,
        redirectUri: redirectUri,
      );
    } finally {
      await server.close(force: true);
    }
  }

  Future<OAuthTokens> _exchangeCode({
    required String code,
    required String verifier,
    required String redirectUri,
  }) async {
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      body: {
        'client_id': AppConstants.desktopClientId,
        'client_secret': AppConstants.desktopClientSecret,
        'code': code,
        'code_verifier': verifier,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Token değişimi başarısız (${response.statusCode}): ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return OAuthTokens(
      accessToken: json['access_token'] as String,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      idToken: json['id_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      grantedScopes: (json['scope'] as String? ?? '').split(' '),
    );
  }

  static String _randomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _resultPage({required bool success}) =>
      '''
<!DOCTYPE html>
<html lang="tr"><head><meta charset="utf-8"><title>Notlar</title>
<style>body{font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#0e0e11;color:#eee}div{text-align:center}h1{font-weight:600}</style>
</head><body><div>
<h1>${success ? 'Giriş başarılı ✓' : 'Giriş iptal edildi'}</h1>
<p>${success ? 'Bu sekmeyi kapatıp Notlar uygulamasına dönebilirsiniz.' : 'Bu sekmeyi kapatabilirsiniz.'}</p>
</div></body></html>''';
}
