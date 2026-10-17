import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';

/// `GeminiService.transcribeMedia` — transkriptin AI ucu (2026-10-17):
/// küçük kayıt satır içi, büyük kayıt Gemini DOSYA API'siyle, YouTube
/// bağlantıyla gider; anahtarsız büyük kayıt anlaşılır bir hatayla durur.
class _KeyStore extends ApiKeyStore {
  const _KeyStore(this.key);

  final String? key;

  @override
  Future<String?> read(AiProvider provider) async => key;
}

/// İstekleri kaydeden, yola göre yanıt veren sahte ağ.
class _Router implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    var sent = '';
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      sent = utf8.decode([for (final c in chunks) ...c], allowMalformed: true);
    }
    bodies.add(sent);
    final path = options.uri.path;
    Map<String, dynamic> body = const {};
    Map<String, List<String>> headers = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (path.endsWith('/models')) {
      body = {'models': <Object>[]};
    } else if (path.contains(':generateContent')) {
      body = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '[0:00] **Merhaba** dünya'},
              ],
            },
          },
        ],
      };
    } else if (path.endsWith('/upload/v1beta/files')) {
      headers = {
        ...headers,
        'x-goog-upload-url': ['https://upload.example/session-1'],
      };
    } else if (options.uri.host == 'upload.example') {
      body = {
        'file': {
          'name': 'files/abc',
          'uri': 'https://generativelanguage.googleapis.com/v1beta/files/abc',
          'mimeType': 'audio/mp4',
          'state': 'ACTIVE',
        },
      };
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: headers);
  }
}

({GeminiService service, _Router router}) _make({
  String? key = 'anahtar',
  AiProvider provider = AiProvider.gemini,
}) {
  final router = _Router();
  final dio = Dio(BaseOptions(baseUrl: provider.baseUrl))
    ..httpClientAdapter = router;
  return (
    service: GeminiService(
      _KeyStore(key),
      dio: dio,
      provider: provider,
      taskModel: (_) => 'gemini-test',
    ),
    router: router,
  );
}

Map<String, dynamic> _generateBody(_Router router) {
  final i = router.requests.indexWhere(
    (r) => r.uri.path.contains(':generateContent'),
  );
  return jsonDecode(router.bodies[i]) as Map<String, dynamic>;
}

void main() {
  test('küçük kayıt satır içi gider, Markdown temizlenir', () async {
    final (:service, :router) = _make();
    final text = await service.transcribeMedia(
      mimeType: 'audio/mp4',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    expect(text, '[0:00] Merhaba dünya');
    final parts =
        (_generateBody(router)['contents'] as List).first['parts'] as List;
    expect(parts.first['inline_data']['mime_type'], 'audio/mp4');
    expect(parts.last['text'], contains('KELİMESİ KELİMESİNE'));
  });

  test('YouTube bağlantıyla verilir (dosya yok)', () async {
    final (:service, :router) = _make();
    await service.transcribeMedia(
      mimeType: 'video/mp4',
      webUrl: 'https://www.youtube.com/watch?v=abc',
      video: true,
    );
    final parts =
        (_generateBody(router)['contents'] as List).first['parts'] as List;
    expect(
      parts.first['file_data']['file_uri'],
      'https://www.youtube.com/watch?v=abc',
    );
    expect(parts.last['text'], contains('Ekranda'));
  });

  test('büyük kayıt Dosya API ile yüklenir, sonra silinir', () async {
    final dir = await Directory.systemTemp.createTemp('transkript_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/uzun.m4a');
    await file.writeAsBytes(Uint8List(GeminiService.maxInlineMediaBytes + 10));
    final (:service, :router) = _make();
    final text = await service.transcribeMedia(
      mimeType: 'audio/mp4',
      filePath: file.path,
    );
    expect(text, '[0:00] Merhaba dünya');
    final start = router.requests.firstWhere(
      (r) => r.uri.path.endsWith('/upload/v1beta/files'),
    );
    expect(start.headers['X-Goog-Upload-Command'], 'start');
    expect(
      start.headers['X-Goog-Upload-Header-Content-Length'],
      '${GeminiService.maxInlineMediaBytes + 10}',
    );
    final parts =
        (_generateBody(router)['contents'] as List).first['parts'] as List;
    expect(parts.first['file_data']['file_uri'], endsWith('/files/abc'));
    expect(parts.first.containsKey('inline_data'), isFalse);
    // Silme ateşle-unut: yanıt beklenmez, kısa süre sonra gider.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(
      router.requests.any(
        (r) => r.method == 'DELETE' && r.uri.path.endsWith('/files/abc'),
      ),
      isTrue,
    );
  });

  test('anahtarsız büyük kayıt MediaTooLargeException', () async {
    final (:service, router: _) = _make(key: null);
    expect(
      () => service.transcribeMedia(
        mimeType: 'audio/mp4',
        bytes: Uint8List(GeminiService.maxInlineMediaBytes + 1),
      ),
      throwsA(isA<MediaTooLargeException>()),
    );
  });

  test('Gemini dışı sağlayıcıda net hata (boş istek gitmez)', () async {
    final (:service, :router) = _make(provider: AiProvider.openai);
    await expectLater(
      () => service.transcribeMedia(
        mimeType: 'audio/mp4',
        bytes: Uint8List.fromList([1]),
      ),
      throwsA(isA<GeminiException>()),
    );
    expect(router.requests, isEmpty);
  });
}
