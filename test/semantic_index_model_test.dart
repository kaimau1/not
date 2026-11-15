import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/core/net/json_http.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/attachment_text_index.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/data/semantic_search.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// K-S2 (2026-11-15): semantik arama Gemini Embedding 2'ye geçti. Her vektör
/// model kimliğini taşır, skor yalnız aynı modelin sorgu vektörüyle hesaplanır,
/// Embedding 2 erişilemezse (404/429) 001'e düşülür — arama bozulmaz.
class _FakeKeyStore extends ApiKeyStore {
  const _FakeKeyStore();

  @override
  Future<String?> read(AiProvider provider) async => 'test-anahtari';
}

class _NoAttachments extends AttachmentTextIndex {
  @override
  Map<String, String> build() => const {};
}

/// İstek kaydı + model başına durum kodu. Vektör: metinde "kedi" geçerse
/// [1,0], yoksa [0,1] — iki model aynı yönü verir, karşılaştırma kolay.
class _Api {
  _Api({this.v2Status = 200});

  int v2Status;
  final calls = <(String model, List<String> texts)>[];

  GeminiService service() => GeminiService(
    const _FakeKeyStore(),
    http: JsonHttp(
      baseUrl: AiProvider.gemini.baseUrl,
      client: MockClient((req) async {
        final model = req.url.path.contains('gemini-embedding-2')
            ? GeminiService.embedModelV2
            : GeminiService.embedModelV1;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final texts = [
          for (final r in body['requests'] as List)
            ((r['content']['parts'] as List).first['text']) as String,
        ];
        calls.add((model, texts));
        if (model == GeminiService.embedModelV2 && v2Status != 200) {
          return http.Response('{}', v2Status);
        }
        return http.Response(
          jsonEncode({
            'embeddings': [
              for (final t in texts)
                {
                  'values': t.contains('kedi') ? [1, 0] : [0, 1],
                },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );
}

const _notes = [
  Note(id: 'a', type: NoteType.text, title: 'kedi maması'),
  Note(id: 'b', type: NoteType.text, title: 'vergi beyanı'),
];

(SemanticIndex, ProviderContainer) _index(_Api api) {
  final provider = Provider<SemanticIndex>(SemanticIndex.new);
  final c = ProviderContainer(
    overrides: [
      geminiServiceProvider.overrideWithValue(api.service()),
      attachmentTextProvider.overrideWith(_NoAttachments.new),
    ],
  );
  addTearDown(c.dispose);
  return (c.read(provider), c);
}

void main() {
  test(
    'Embedding 2 ile gömülür, model kimliği saklanır, önek eklenir',
    () async {
      final api = _Api();
      final (index, _) = _index(api);
      final found = await index.search('kedi', _notes);
      expect(found.map((n) => n.id), ['a']);
      expect(index.modelOf('a'), GeminiService.embedModelV2);
      expect(
        api.calls.every((c) => c.$1 == GeminiService.embedModelV2),
        isTrue,
      );
      expect(api.calls.first.$2.first, startsWith('title: none | text: '));
      expect(api.calls.last.$2.single, 'task: search result | query: kedi');
    },
  );

  for (final status in [404, 429]) {
    test('Embedding 2 $status → 001\'e düşer, veri kaybı yok', () async {
      final api = _Api(v2Status: status);
      final (index, _) = _index(api);
      final found = await index.search('kedi', _notes);
      expect(found.map((n) => n.id), ['a']);
      expect(index.activeModel, GeminiService.embedModelV1);
      expect(index.modelOf('a'), GeminiService.embedModelV1);
      // 001'e önek gitmez (belgedeki taskType'sız eski davranış).
      expect(api.calls.last.$2.single, 'kedi');
    });
  }

  test('karışık vektörler: model değişince eskiler yeniden gömülür, '
      'skor yalnız aynı modelin sorgusuyla', () async {
    final api = _Api();
    final (index, _) = _index(api);
    await index.search('kedi', _notes);
    expect(index.modelOf('b'), GeminiService.embedModelV2);

    // Oturum ortasında Embedding 2 kotası doldu: sorgu 429 → 001.
    api.v2Status = 429;
    final found = await index.search('kedi yeni', _notes);
    expect(found.map((n) => n.id), ['a']);
    expect(index.modelOf('a'), GeminiService.embedModelV1);
    expect(index.modelOf('b'), GeminiService.embedModelV1);
  });

  test('bağlantı hatası 001\'e düşürmez (yükselir, çağıran düz aramaya '
      'geçer)', () async {
    final api = _Api(v2Status: 500);
    final (index, _) = _index(api);
    await expectLater(
      index.search('kedi', _notes),
      throwsA(isA<GeminiException>()),
    );
    expect(index.activeModel, GeminiService.embedModelV2);
  });
}
