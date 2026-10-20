import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AI sağlayıcıları için ince JSON istemcisi (`package:http` üstünde).
///
/// Uygulamada tek HTTP istemcisi kalsın diye (F3.10) dio'nun kullandığımız
/// alt kümesini verir: göreli yol + taban adres, sorgu parametreleri, JSON
/// gövde ya da akış (büyük dosya yüklemesi), zaman aşımı ve 2xx dışı
/// yanıtta [JsonHttpException].
class JsonHttp {
  JsonHttp({
    required this.baseUrl,
    http.Client? client,
    this.receiveTimeout = const Duration(minutes: 3),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration receiveTimeout;
  final http.Client _client;

  Future<JsonResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) => _send<T>(
    'GET',
    path,
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
  );

  /// [data]: JSON'a çevrilecek değer ya da `Stream<List<int>>` (ham akış —
  /// uzunluk `content-length` başlığından okunur).
  Future<JsonResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, String>? headers,
    Duration? timeout,
  }) => _send<T>('POST', path, data: data, headers: headers, timeout: timeout);

  Future<JsonResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
  }) => _send<T>('DELETE', path, headers: headers);

  Uri _uri(String path, Map<String, Object?>? query) {
    final full = path.startsWith('http') ? path : '$baseUrl$path';
    final uri = Uri.parse(full);
    final q = <String, String>{
      ...uri.queryParameters,
      for (final e in (query ?? const <String, Object?>{}).entries)
        if (e.value != null) e.key: '${e.value}',
    };
    return q.isEmpty ? uri : uri.replace(queryParameters: q);
  }

  Future<JsonResponse<T>> _send<T>(
    String method,
    String path, {
    Map<String, Object?>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _uri(path, queryParameters);
    final http.BaseRequest request;
    if (data is Stream<List<int>>) {
      final streamed = http.StreamedRequest(method, uri);
      final length = int.tryParse(
        headers?.entries
                .firstWhere(
                  (e) => e.key.toLowerCase() == 'content-length',
                  orElse: () => const MapEntry('', ''),
                )
                .value ??
            '',
      );
      if (length != null) streamed.contentLength = length;
      unawaited(
        streamed.sink
            .addStream(data)
            .whenComplete(streamed.sink.close)
            .catchError((Object _) {}),
      );
      request = streamed;
    } else {
      final plain = http.Request(method, uri);
      if (data != null) {
        plain.headers['content-type'] = 'application/json';
        // BÜYÜK gövde (PDF/ses base64'ü) AYRI İZOLEDE kodlanır (F6.6): 15 MB'lık
        // bir PDF'in ~20 MB'lık dizesi ana izolede JSON'a ve UTF-8'e
        // çevriliyor, yüzlerce ms donma + 3-4 kat bellek sıçraması oluyordu.
        if (roughJsonSize(data) > kIsolateBodyBytes) {
          plain.bodyBytes = await compute(encodeJsonBytes, data);
        } else {
          plain.body = jsonEncode(data);
        }
      }
      request = plain;
    }
    headers?.forEach((k, v) {
      if (k.toLowerCase() != 'content-length') request.headers[k] = v;
    });
    final http.Response response;
    try {
      final streamed = await _client
          .send(request)
          .timeout(timeout ?? receiveTimeout);
      response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout ?? receiveTimeout);
    } on TimeoutException {
      throw const JsonHttpException('zaman aşımı');
    } on http.ClientException catch (e) {
      throw JsonHttpException(e.message);
    }
    Object? body;
    if (response.bodyBytes.isNotEmpty) {
      try {
        final bytes = response.bodyBytes;
        body = bytes.length > kIsolateResponseBytes
            ? await compute(decodeJsonBytes, bytes)
            : decodeJsonBytes(bytes);
      } on FormatException {
        body = response.body;
      }
    }
    final result = JsonResponse<T>(
      statusCode: response.statusCode,
      data: body is T ? body : null,
      headers: response.headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw JsonHttpException('HTTP ${response.statusCode}', response: result);
    }
    return result;
  }
}

/// Bu boyu aşan istek gövdesi izolede kodlanır (bkz. [JsonHttp]).
const kIsolateBodyBytes = 256 * 1024;

/// Bu boyu aşan yanıt izolede çözülür.
const kIsolateResponseBytes = 1024 * 1024;

/// JSON'a çevrilecek değerin KABA boyu (dize kod birimleri + sayılar) —
/// ayırmasız, yalnız eşik kararı için.
int roughJsonSize(Object? v) => switch (v) {
  String s => s.length,
  List l => l.fold(0, (total, e) => total + roughJsonSize(e)),
  Map m => m.entries.fold(
    0,
    (total, e) => total + e.key.toString().length + roughJsonSize(e.value),
  ),
  _ => 8,
};

/// Üst düzey: `compute` ile izolede koşar.
Uint8List encodeJsonBytes(Object? data) => utf8.encode(jsonEncode(data));

Object? decodeJsonBytes(Uint8List bytes) => jsonDecode(utf8.decode(bytes));

class JsonResponse<T> {
  const JsonResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
  });

  final int statusCode;
  final T? data;

  /// Küçük harfli başlık adlarıyla.
  final Map<String, String> headers;
}

class JsonHttpException implements Exception {
  const JsonHttpException(this.message, {this.response});

  final String message;

  /// Sunucu yanıt verdiyse (2xx dışı); ağ/zaman aşımı hatasında null.
  final JsonResponse<Object?>? response;

  @override
  String toString() => 'JsonHttpException: $message';
}
