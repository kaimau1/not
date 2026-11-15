import 'dart:convert';
import 'dart:io';

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
  _Api({this.v2Status = 200, this.v2Body = '{}'});

  int v2Status;
  String v2Body;
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
          return http.Response(v2Body, v2Status);
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

/// RPD dolu 429'u (gövdede PerDay → ModelCooldown gün sonuna dek).
const _perDay =
    '{"error":{"details":[{"violations":[{"quotaId":"EmbedRequestsPerDay"}]}]}}';

(SemanticIndex, ProviderContainer) _index(_Api api, {String? uid}) {
  final provider = Provider<SemanticIndex>((ref) {
    final index = SemanticIndex(ref, uid: uid);
    ref.onDispose(index.dispose);
    return index;
  });
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
    test('Embedding 2 $status (gün) → 001\'e düşer, veri kaybı yok', () async {
      final api = _Api(v2Status: status, v2Body: _perDay);
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

    // Oturum ortasında Embedding 2 GÜNLÜK kotası doldu: sorgu 429 → 001.
    api.v2Status = 429;
    api.v2Body = _perDay;
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

  group('kalıcı vektör önbelleği (oto/arama-onbellek)', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('sem_cache');
      SemanticIndex.overrideDir = dir.path;
    });
    tearDown(() {
      SemanticIndex.overrideDir = null;
      dir.deleteSync(recursive: true);
    });

    // Belge gömme istekleri (sorgu istekleri hariç).
    int docCalls(_Api api) => api.calls
        .where((c) => c.$2.first.startsWith('title: none'))
        .fold(0, (sum, c) => sum + c.$2.length);

    File storeFile() => File('${dir.path}/semantic_vectors_u1.bin');

    test('isabet: yeni açılışta değişmeyen not yeniden gömülmez', () async {
      final first = _Api();
      await _index(first, uid: 'u1').$1.search('kedi', _notes);
      expect(docCalls(first), 2);
      expect(storeFile().existsSync(), isTrue);

      // "Uygulama yeniden açıldı": yeni indeks, aynı hesap.
      final second = _Api();
      final found = await _index(second, uid: 'u1').$1.search('kedi', _notes);
      expect(found.map((n) => n.id), ['a']);
      expect(docCalls(second), 0, reason: 'vektörler diskten gelmeli');
    });

    test('içerik değişince yalnız o not yeniden gömülür', () async {
      await _index(_Api(), uid: 'u1').$1.search('kedi', _notes);
      final api = _Api();
      final changed = [
        _notes[0],
        const Note(id: 'b', type: NoteType.text, title: 'kedi kumu'),
      ];
      final found = await _index(api, uid: 'u1').$1.search('kedi', changed);
      expect(docCalls(api), 1);
      expect(found.map((n) => n.id).toSet(), {'a', 'b'});
    });

    test('silinen notun kaydı diskten de temizlenir', () async {
      final (index, _) = _index(_Api(), uid: 'u1');
      await index.search('kedi', _notes);
      index.pruneTo({'a'});
      await index.search('kedi', [_notes[0]]);
      final again = _index(_Api(), uid: 'u1').$1;
      await again.search('kedi', [_notes[0]]);
      expect(again.cachedVectorCount, 1);
    });

    test(
      'model değişimi: 001 kayıtları Embedding 2 göçü bitince silinir',
      () async {
        // Dün Embedding 2'nin günlük kotası doluydu → 001 ile gömüldü.
        final old = _index(_Api(v2Status: 429, v2Body: _perDay), uid: 'u1').$1;
        await old.search('kedi', _notes);
        expect(old.modelOf('a'), GeminiService.embedModelV1);

        // Bugün Embedding 2 açık: hepsi 2 ile gömülür, 001 kayıtları gider.
        final api = _Api();
        final index = _index(api, uid: 'u1').$1;
        await index.search('kedi', _notes);
        expect(docCalls(api), 2);
        expect(index.cachedVectorCount, 2);
        expect(index.modelOf('a'), GeminiService.embedModelV2);

        final reopened = _Api();
        final r = _index(reopened, uid: 'u1').$1;
        await r.search('kedi', _notes);
        expect(docCalls(reopened), 0);
        expect(r.cachedVectorCount, 2);
      },
    );

    test('anlık 429 (RPM) oturumu 001\'e kilitlemez, soğuma kısa', () async {
      final api = _Api(v2Status: 429);
      final (index, c) = _index(api, uid: 'u1');
      await expectLater(
        index.search('kedi', _notes),
        throwsA(isA<GeminiException>()),
      );
      expect(index.activeModel, GeminiService.embedModelV2);
      final left = c
          .read(geminiServiceProvider)
          .cooldown
          .remaining(GeminiService.embedModelV2);
      expect(left, greaterThan(Duration.zero));
      expect(left, lessThanOrEqualTo(const Duration(minutes: 1)));
      expect(api.calls.any((x) => x.$1 == GeminiService.embedModelV1), isFalse);
    });

    test('çıkışta önbellek silinir, süren dolum geri yazamaz', () async {
      final (index, _) = _index(_Api(), uid: 'u1');
      await index.search('kedi', _notes);
      expect(storeFile().existsSync(), isTrue);
      await SemanticIndex.deleteStore('u1');
      expect(storeFile().existsSync(), isFalse);
      // Çıkış sonrası eski indeks yazmayı denese de dosya geri gelmez.
      index.pruneTo({'a'});
      await index.search('kedi', [_notes[0]]);
      expect(storeFile().existsSync(), isFalse);
    });
  });
}
