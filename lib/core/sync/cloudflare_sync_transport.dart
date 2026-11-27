import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../net/json_http.dart';
import 'cloudflare_config.dart';
import 'sync_models.dart';
import 'sync_transport.dart';

typedef IdTokenProvider = Future<String?> Function();

/// Cloudflare Worker (`cloudflare/src/index.ts`) için somut [SyncTransport].
///
/// Hibrit kimlik doğrulama (PLAN §9 Karar #1): her istekte güncel Firebase
/// Auth ID Token `Authorization: Bearer <jwt>` olarak gönderilir; isteğe
/// bağlı `X-Firebase-AppCheck` başlığı Decisions çağrılarına eklenir.
class CloudflareSyncTransport implements SyncTransport {
  factory CloudflareSyncTransport({
    required String baseUrl,
    required Future<String?> Function() getIdToken,
    Future<String?> Function()? getAppCheckToken,
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) {
    final resolvedClient = client ?? http.Client();
    return CloudflareSyncTransport._(
      baseUrl: baseUrl,
      getIdToken: getIdToken,
      getAppCheckToken: getAppCheckToken,
      resolvedClient: resolvedClient,
      timeout: timeout,
    );
  }

  CloudflareSyncTransport._({
    required this.baseUrl,
    required this.getIdToken,
    this.getAppCheckToken,
    required http.Client resolvedClient,
    Duration timeout = const Duration(seconds: 15),
  }) : _client = resolvedClient,
       _timeout = timeout,
       _http = JsonHttp(
         baseUrl: baseUrl.endsWith('/')
             ? baseUrl.substring(0, baseUrl.length - 1)
             : baseUrl,
         client: resolvedClient,
         receiveTimeout: timeout,
       );

  final String baseUrl;
  final IdTokenProvider getIdToken;
  final IdTokenProvider? getAppCheckToken;
  final http.Client _client;
  final Duration _timeout;
  final JsonHttp _http;

  String get _cleanBase => baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  Future<Map<String, String>> _authHeaders({
    bool includeAppCheck = false,
    Map<String, String>? extra,
  }) async {
    final token = (await getIdToken())?.trim();
    if (token == null || token.isEmpty) {
      throw const SyncAuthException(
        'auth_missing',
        'Oturum belirteci alınamadı',
        statusCode: 401,
      );
    }
    final headers = <String, String>{'authorization': 'Bearer $token'};
    if (includeAppCheck && getAppCheckToken != null) {
      final ac = (await getAppCheckToken!())?.trim();
      if (ac != null && ac.isNotEmpty) {
        headers['x-firebase-appcheck'] = ac;
      }
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Never _rethrowHttp(JsonHttpException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String code = 'http_${status ?? 0}';
    String message = e.message;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      if (err['code'] is String) code = err['code'] as String;
      if (err['message'] is String) message = err['message'] as String;
    }
    if (status == 401 || status == 403 && code == 'auth_failed') {
      throw SyncAuthException(code, message, statusCode: status);
    }
    if (code == 'ai_kill_switch') {
      throw SyncKillSwitchException(code, message, statusCode: status);
    }
    if (status == 429 ||
        code == 'resource_exhausted' ||
        code == 'quota_exceeded') {
      throw SyncQuotaException(code, message, statusCode: status);
    }
    throw SyncTransportException(code, message, statusCode: status);
  }

  @override
  Future<SyncPushPullResponse> pushPull(SyncPushPullRequest request) async {
    try {
      final res = await _http.post<Map<String, dynamic>>(
        '/v1/sync',
        data: request.toJson(),
        headers: await _authHeaders(),
      );
      return SyncPushPullResponse.fromJson(res.data ?? const {});
    } on JsonHttpException catch (e) {
      _rethrowHttp(e);
    }
  }

  @override
  Future<RemoteEntitlement> fetchEntitlement() async {
    try {
      final res = await _http.get<Map<String, dynamic>>(
        '/v1/entitlement',
        headers: await _authHeaders(),
      );
      return RemoteEntitlement.fromJson(res.data ?? const {});
    } on JsonHttpException catch (e) {
      _rethrowHttp(e);
    }
  }

  @override
  Future<RemoteEntitlement> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    try {
      final res = await _http.post<Map<String, dynamic>>(
        '/v1/billing/verify',
        data: {'productId': productId, 'purchaseToken': purchaseToken},
        headers: await _authHeaders(),
      );
      final entMap = res.data?['entitlement'];
      return RemoteEntitlement.fromJson(
        entMap is Map<String, dynamic> ? entMap : const {},
      );
    } on JsonHttpException catch (e) {
      _rethrowHttp(e);
    }
  }

  @override
  Future<Map<String, dynamic>?> decide(
    Map<String, Object?> body, {
    Duration? timeout,
  }) async {
    try {
      final res = await _http.post<Map<String, dynamic>>(
        '/v1/decide',
        data: body,
        headers: await _authHeaders(includeAppCheck: true),
        timeout: timeout,
      );
      return res.data;
    } on JsonHttpException catch (e) {
      _rethrowHttp(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final res = await _http.get<Map<String, dynamic>>(
        '/v1/users/search',
        queryParameters: {'q': query.trim()},
        headers: await _authHeaders(),
      );
      final raw = res.data?['results'];
      if (raw is! List) return const [];
      return [
        for (final r in raw)
          if (r is Map) Map<String, dynamic>.from(r),
      ];
    } on JsonHttpException catch (e) {
      _rethrowHttp(e);
    }
  }

  @override
  Future<void> upsertUserDirectory({
    required String name,
    required String email,
    required bool discoverable,
  }) async {
    final uri = Uri.parse('$_cleanBase/v1/users/me');
    final headers = await _authHeaders(
      extra: {'content-type': 'application/json'},
    );
    final res = await _client
        .put(
          uri,
          headers: headers,
          body: jsonEncode({
            'name': name,
            'email': email,
            'discoverable': discoverable,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (res.statusCode == 401) {
        throw SyncAuthException(
          'http_401',
          res.body,
          statusCode: res.statusCode,
        );
      }
      throw SyncTransportException(
        'http_${res.statusCode}',
        res.body,
        statusCode: res.statusCode,
      );
    }
  }

  @override
  Future<void> upsertShare({
    required String entityKind,
    required String entityId,
    required String memberUid,
    String role = 'both',
    String status = 'active',
  }) async {
    try {
      await _http.post<Map<String, dynamic>>(
        '/v1/shares',
        data: {
          'entityKind': entityKind,
          'entityId': entityId,
          'memberUid': memberUid,
          'role': role,
          'status': status,
        },
        headers: await _authHeaders(),
      );
    } on JsonHttpException catch (e) {
      _rethrowHttp(e);
    }
  }

  String _encodeKeyPath(String key) =>
      key.split('/').map(Uri.encodeComponent).join('/');

  @override
  Future<MediaUploadResult> uploadMedia({
    required String key,
    required Uint8List bytes,
    required String contentType,
    String? noteId,
  }) async {
    final uri = Uri.parse('$_cleanBase/v1/media/${_encodeKeyPath(key)}');
    final headers = await _authHeaders(
      extra: {
        'content-type': contentType,
        if (noteId != null && noteId.isNotEmpty) 'x-notlar-note-id': noteId,
      },
    );
    final res = await _client
        .put(uri, headers: headers, body: bytes)
        .timeout(_timeout);
    if (res.statusCode == 413) {
      throw SyncQuotaException(
        'quota_exceeded',
        res.body,
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SyncTransportException(
        'http_${res.statusCode}',
        res.body,
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    return MediaUploadResult.fromJson(
      decoded is Map<String, dynamic> ? decoded : const {},
    );
  }

  @override
  Future<Uint8List> downloadMedia(String key) async {
    final uri = Uri.parse('$_cleanBase/v1/media/${_encodeKeyPath(key)}');
    final res = await _client
        .get(uri, headers: await _authHeaders())
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SyncTransportException(
        'http_${res.statusCode}',
        res.body,
        statusCode: res.statusCode,
      );
    }
    return res.bodyBytes;
  }

  @override
  Future<void> deleteMedia(String key) async {
    try {
      await _http.delete<Map<String, dynamic>>(
        '/v1/media/${_encodeKeyPath(key)}',
        headers: await _authHeaders(),
      );
    } on JsonHttpException catch (e) {
      _rethrowHttp(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _http.delete<Map<String, dynamic>>(
        '/v1/users/me',
        headers: await _authHeaders(),
      );
    } on JsonHttpException catch (e) {
      _rethrowHttp(e);
    }
  }
}

/// Yapılandırılmışsa etkin [SyncTransport], aksi halde `null` (Firestore yolu).
final cloudflareSyncTransportProvider = Provider<SyncTransport?>((ref) {
  if (!CloudflareConfig.enabled) return null;
  return CloudflareSyncTransport(
    baseUrl: CloudflareConfig.apiBase,
    getIdToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    getAppCheckToken: () async {
      try {
        return await FirebaseAppCheck.instance.getToken();
      } catch (_) {
        return null;
      }
    },
  );
});
