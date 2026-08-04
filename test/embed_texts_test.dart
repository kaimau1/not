import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';

/// Semantik aramanın vektör kapısı.
///
/// Kök neden (2026-08-04 denetimi): API boş `embeddings` döndüğünde
/// `SemanticIndex` boş listenin `.first`ine gidip `StateError` atıyordu;
/// o istisna `semanticSearchProvider`'ın `on GeminiException` yedeğine
/// TAKILMADIĞI için arama düz metne düşmek yerine hata ekranına düşüyordu.
/// Buradaki sınav, boş yanıtın GeminiException'a çevrildiğini kilitler.
class _FakeKeyStore extends ApiKeyStore {
  const _FakeKeyStore();

  @override
  Future<String?> read(AiProvider provider) async => 'test-anahtari';
}

/// Ağa çıkmadan sabit bir JSON gövdesi döndüren dio adaptörü.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final Map<String, dynamic> body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

GeminiService _service(Map<String, dynamic> response) {
  final dio = Dio(BaseOptions(baseUrl: AiProvider.gemini.baseUrl))
    ..httpClientAdapter = _StubAdapter(response);
  return GeminiService(const _FakeKeyStore(), dio: dio);
}

void main() {
  test('vektörler okunur', () async {
    final service = _service({
      'embeddings': [
        {
          'values': [0.5, -1, 2],
        },
        {
          'values': [1, 1, 1],
        },
      ],
    });
    final vectors = await service.embedTexts(['bir', 'iki']);
    expect(vectors, hasLength(2));
    expect(vectors.first, [0.5, -1.0, 2.0]);
  });

  test('boş yanıt GeminiException olur — arama düz metne düşebilsin', () {
    final service = _service(const {'embeddings': []});
    expect(
      () => service.embedTexts(['bir']),
      throwsA(isA<GeminiException>()),
    );
  });

  test('alan hiç yoksa da GeminiException', () {
    final service = _service(const {});
    expect(
      () => service.embedTexts(['bir']),
      throwsA(isA<GeminiException>()),
    );
  });

  test('boş metin listesi ağa hiç çıkmaz', () async {
    final service = _service(const {});
    expect(await service.embedTexts(const []), isEmpty);
  });
}
