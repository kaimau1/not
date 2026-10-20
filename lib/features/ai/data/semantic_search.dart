import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/search_fold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/notes_providers.dart';
import 'attachment_text_index.dart';
import 'gemini_service.dart';

/// Hesaba bağlı (F5.5): vektör önbelleği notların içeriğinden türer; hesap
/// değişince öbür hesabınki bellekte kalmasın.
final semanticIndexProvider = Provider<SemanticIndex>((ref) {
  ref.watch(currentUidProvider);
  return SemanticIndex(ref);
});

/// Sorguyla anlamca en alakalı notlar (skor eşiği uygulanmış, sıralı).
final semanticSearchProvider = FutureProvider.autoDispose
    .family<List<Note>, String>((ref, query) async {
      final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
      // Gizli klasördeki notlar anlamsal aramaya da girmez (düz metin
      // aramasıyla aynı kural — bkz. filteredNotesProvider).
      final hiddenFolders = ref.watch(hiddenFoldersRevealedProvider)
          ? const <String>{}
          : ref.watch(hiddenFolderIdsProvider);
      // Kilitli notların içeriği embedding'e ve sonuçlara girmez.
      final active = [
        for (final n in notes)
          if (n.archivedAt == null &&
              !n.locked &&
              !hiddenFolders.contains(n.folderId))
            n,
      ];
      if (active.isEmpty || query.trim().isEmpty) return const [];
      try {
        return await (ref.read(semanticIndexProvider)
              ..pruneTo({for (final n in notes) n.id}))
            .search(query.trim(), active);
      } on GeminiException {
        // Embedding dahili (anahtarsız) modda desteklenmiyor; arama hata ekranına
        // düşmesin, düz metin aramasıyla devam edilsin.
        final q = foldForSearch(query.trim());
        return [
          for (final n in active)
            if (foldForSearch(n.toPlainText()).contains(q)) n,
        ];
      }
    });

/// Ana ekran DIŞINDAKİ arama yüzeyleri (arşiv, çöp, klasör) için anlamsal
/// aramanın aday kümesi (geliştirme raporu B4, 2026-10-20: AI anahtarı
/// arşivden çöpe ve klasöre de geldi).
enum SemanticScope { archive, trash, folder }

/// Kapsamlı anlamsal arama: [semanticSearchProvider] ile aynı indeks ve aynı
/// eşik; yalnız aday kümesi kapsamın notları. [folderId] yalnız
/// [SemanticScope.folder]da. Kilitli ve gizli klasördeki notlar girmez.
final scopedSemanticSearchProvider = FutureProvider.autoDispose
    .family<
      List<Note>,
      ({SemanticScope scope, String? folderId, String query})
    >((ref, key) async {
      final query = key.query.trim();
      final hiddenFolders = ref.watch(hiddenFoldersRevealedProvider)
          ? const <String>{}
          : ref.watch(hiddenFolderIdsProvider);
      final source = switch (key.scope) {
        SemanticScope.trash =>
          ref.watch(trashStreamProvider).value ?? const <Note>[],
        _ => ref.watch(notesStreamProvider).value ?? const <Note>[],
      };
      final candidates = [
        for (final n in source)
          if (!n.locked &&
              !hiddenFolders.contains(n.folderId) &&
              switch (key.scope) {
                SemanticScope.archive => n.archivedAt != null,
                SemanticScope.trash => n.deletedAt != null,
                SemanticScope.folder =>
                  n.folderId == key.folderId && n.archivedAt == null,
              })
            n,
      ];
      if (candidates.isEmpty || query.isEmpty) return const [];
      try {
        return await ref.read(semanticIndexProvider).search(query, candidates);
      } on GeminiException {
        final q = foldForSearch(query);
        return [
          for (final n in candidates)
            if (foldForSearch(n.toPlainText()).contains(q)) n,
        ];
      }
    });

/// Bellek içi embedding indeksi: her notun vektörü not değiştikçe yenilenir,
/// arama kosinüs benzerliğiyle yapılır. Vektörler yalnızca bellekte tutulur.
///
/// Vektörler saklanırken NORMALİZE edilir: kosinüs benzerliği düz iç çarpıma
/// iner (skorlamada norm hesabı tekrarlanmaz) ve sorgu vektörü sorgu metnine
/// göre önbelleklenir — aynı sorgu (ör. kullanıcı sonucu açıp geri dönünce
/// provider'ın yeniden kurulması) ikinci kez ağa çıkmaz.
class SemanticIndex {
  SemanticIndex(this._ref);

  final Ref _ref;

  /// noteId → (güncellenme zamanı, normalize vektör)
  final _cache = <String, (DateTime?, Float32List, int)>{};

  /// sorgu metni → normalize vektör (küçük, eklenme sıralı; taşınca en eski
  /// atılır — LinkedHashMap sırası eklenme sırasıdır).
  final _queryCache = <String, Float32List>{};
  static const _maxQueryCache = 32;

  /// Silinen notların vektörlerini bırakır (F7.5). Arşivli/gizli notlar
  /// canlı sayılır: yeniden gösterilince baştan vektörlenmesin.
  void pruneTo(Set<String> liveIds) =>
      _cache.removeWhere((id, _) => !liveIds.contains(id));

  @visibleForTesting
  int get cachedVectorCount => _cache.length;

  @visibleForTesting
  void debugPut(String id) => _cache[id] = (null, Float32List(0), 0);

  Future<List<Note>> search(String query, List<Note> notes) async {
    final service = _ref.read(geminiServiceProvider);
    final extra = _ref.read(attachmentTextProvider);

    // Eksik veya bayat vektörleri toplu üret (100'erlik gruplar).
    final stale = [
      for (final note in notes)
        if (!_cache.containsKey(note.id) ||
            _cache[note.id]!.$1 != note.updatedAt ||
            _cache[note.id]!.$3 != (extra[note.id]?.length ?? 0))
          note,
    ];
    for (var i = 0; i < stale.length; i += 100) {
      final batch = stale.sublist(i, min(i + 100, stale.length));
      final texts = [
        for (final note in batch)
          () {
            // Ek içeriği (PDF metni + görsel OCR) seçenek açıkken vektöre de
            // girer: "faturadaki tutarı" arayan kullanıcı notun yazısında
            // değil EKİNDE olanı arıyor (bkz. attachment_text_index.dart).
            final text = [
              note.toPlainText(),
              ?extra[note.id],
            ].join('\n');
            return text.length > 1500 ? text.substring(0, 1500) : text;
          }(),
      ];
      final vectors = await service.embedTexts(texts);
      for (var j = 0; j < batch.length && j < vectors.length; j++) {
        _cache[batch[j].id] = (
          batch[j].updatedAt,
          _normalized(vectors[j]),
          extra[batch[j].id]?.length ?? 0,
        );
      }
    }

    var queryVector = _queryCache[query];
    if (queryVector == null) {
      queryVector = _normalized((await service.embedTexts([query])).first);
      if (_queryCache.length >= _maxQueryCache) {
        _queryCache.remove(_queryCache.keys.first);
      }
      _queryCache[query] = queryVector;
    }

    final scored = <(Note, double)>[];
    for (final note in notes) {
      final entry = _cache[note.id];
      if (entry == null) continue;
      scored.add((note, _dot(queryVector, entry.$2)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [
      for (final (note, score) in scored.take(30))
        if (score > 0.35) note,
    ];
  }

  /// Birim uzunluğa ölçekler; sıfır vektör olduğu gibi kalır (skoru 0 çıkar).
  static Float32List _normalized(List<double> v) {
    final out = Float32List.fromList([for (final x in v) x]);
    var norm = 0.0;
    for (final x in out) {
      norm += x * x;
    }
    if (norm == 0) return out;
    final inv = 1 / sqrt(norm);
    for (var i = 0; i < out.length; i++) {
      out[i] *= inv;
    }
    return out;
  }

  static double _dot(Float32List a, Float32List b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}
