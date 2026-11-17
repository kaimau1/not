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
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';

/// T14 (15 Kasım raporu §4): çöp kutusunda anlamca arama ↔ önbellek
/// temizliği döngüsü. Ana arama `pruneTo`'ya yalnız AKTİF notları veriyordu:
/// çöpteki notun vektörü her ana aramada silinip çöp aramasında yeniden
/// gömülüyordu (iki arama da açıkken `revision` üzerinden kendini besleyen
/// döngü; kapalıyken her çöp aramasında boşa gömme isteği).
class _FakeKeyStore extends ApiKeyStore {
  const _FakeKeyStore();

  @override
  Future<String?> read(AiProvider provider) async => 'test-anahtari';
}

class _NoAttachments extends AttachmentTextIndex {
  @override
  Map<String, String> build() => const {};
}

/// Gömülen not metinleri (sorgular hariç).
final _embedded = <String>[];

GeminiService _service() => GeminiService(
  const _FakeKeyStore(),
  http: JsonHttp(
    baseUrl: AiProvider.gemini.baseUrl,
    client: MockClient((req) async {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final texts = [
        for (final r in body['requests'] as List)
          ((r['content']['parts'] as List).first['text']) as String,
      ];
      _embedded.addAll(texts.where((t) => !t.contains('query:')));
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

class _NotRevealed extends HiddenFoldersRevealedNotifier {
  @override
  bool build() => false;
}

void main() {
  setUp(_embedded.clear);

  ProviderContainer container({required List<Note> trash}) {
    final c = ProviderContainer(
      overrides: [
        geminiServiceProvider.overrideWithValue(_service()),
        attachmentTextProvider.overrideWith(_NoAttachments.new),
        currentUidProvider.overrideWithValue(null),
        hiddenFolderIdsProvider.overrideWithValue(const <String>{}),
        hiddenFoldersRevealedProvider.overrideWith(_NotRevealed.new),
        notesStreamProvider.overrideWith(
          (ref) => Stream.value(const [
            Note(id: 'a', type: NoteType.text, title: 'kedi maması'),
          ]),
        ),
        trashStreamProvider.overrideWith((ref) => Stream.value(trash)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  const trashed = Note(id: 't', type: NoteType.text, title: 'kedi aşısı');

  Future<List<String>> trashSearch(ProviderContainer c) async {
    final key = (scope: SemanticScope.trash, folderId: null, query: 'kedi');
    final sub = c.listen(scopedSemanticSearchProvider(key), (_, _) {});
    final found = await c.read(scopedSemanticSearchProvider(key).future);
    sub.close();
    // autoDispose atılsın: sonraki arama önbellekteki sonucu değil yeniden
    // hesaplananı versin.
    await Future<void>.delayed(Duration.zero);
    return [for (final n in found) n.id];
  }

  Future<void> mainSearch(ProviderContainer c) async {
    final sub = c.listen(semanticSearchProvider('kedi'), (_, _) {});
    await c.read(semanticSearchProvider('kedi').future);
    sub.close();
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> streams(ProviderContainer c) async {
    final s1 = c.listen(notesStreamProvider, (_, _) {});
    final s2 = c.listen(trashStreamProvider, (_, _) {});
    addTearDown(s1.close);
    addTearDown(s2.close);
    await c.read(notesStreamProvider.future);
    await c.read(trashStreamProvider.future);
  }

  test(
    'ana arama çöpteki notun vektörünü silmez: çöpte yeniden gömme yok',
    () async {
      final t = trashed.copyWith(deletedAt: DateTime(2026, 11, 2));
      final c = container(trash: [t]);
      await streams(c);
      expect(await trashSearch(c), ['t']);
      await mainSearch(c);
      expect(await trashSearch(c), ['t']);
      final trashEmbeds = _embedded.where((e) => e.contains('aşısı')).length;
      expect(trashEmbeds, 1, reason: 'çöpteki not bir kez gömülür');
    },
  );

  test(
    'kalıcı silinen (iki listede de olmayan) notun vektörü bırakılır',
    () async {
      final t = trashed.copyWith(deletedAt: DateTime(2026, 11, 2));
      final c = container(trash: [t]);
      await streams(c);
      await trashSearch(c);
      final index = c.read(semanticIndexProvider);
      index.debugPut('gitti');
      await mainSearch(c);
      expect(index.modelOf('gitti'), isNull);
      expect(index.modelOf('t'), isNotNull);
    },
  );
}
