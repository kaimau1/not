import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import 'gemini_service.dart';

final semanticIndexProvider = Provider<SemanticIndex>(
  (ref) => SemanticIndex(ref),
);

/// Sorguyla anlamca en alakalı notlar (skor eşiği uygulanmış, sıralı).
final semanticSearchProvider =
    FutureProvider.autoDispose.family<List<Note>, String>((ref, query) async {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  final active = [for (final n in notes) if (n.archivedAt == null) n];
  if (active.isEmpty || query.trim().isEmpty) return const [];
  try {
    return await ref.read(semanticIndexProvider).search(query.trim(), active);
  } on GeminiException {
    // Embedding dahili (anahtarsız) modda desteklenmiyor; arama hata ekranına
    // düşmesin, düz metin aramasıyla devam edilsin.
    final q = query.trim().toLowerCase();
    return [
      for (final n in active)
        if (n.toPlainText().toLowerCase().contains(q)) n,
    ];
  }
});

/// Bellek içi embedding indeksi: her notun vektörü not değiştikçe yenilenir,
/// arama kosinüs benzerliğiyle yapılır. Vektörler yalnızca bellekte tutulur.
class SemanticIndex {
  SemanticIndex(this._ref);

  final Ref _ref;

  /// noteId → (güncellenme zamanı, vektör)
  final _cache = <String, (DateTime?, List<double>)>{};

  Future<List<Note>> search(String query, List<Note> notes) async {
    final service = _ref.read(geminiServiceProvider);

    // Eksik veya bayat vektörleri toplu üret (100'erlik gruplar).
    final stale = [
      for (final note in notes)
        if (!_cache.containsKey(note.id) ||
            _cache[note.id]!.$1 != note.updatedAt)
          note,
    ];
    for (var i = 0; i < stale.length; i += 100) {
      final batch = stale.sublist(i, min(i + 100, stale.length));
      final texts = [
        for (final note in batch)
          () {
            final text = note.toPlainText();
            return text.length > 1500 ? text.substring(0, 1500) : text;
          }(),
      ];
      final vectors = await service.embedTexts(texts);
      for (var j = 0; j < batch.length && j < vectors.length; j++) {
        _cache[batch[j].id] = (batch[j].updatedAt, vectors[j]);
      }
    }

    final queryVector = (await service.embedTexts([query])).first;

    final scored = <(Note, double)>[];
    for (final note in notes) {
      final entry = _cache[note.id];
      if (entry == null) continue;
      scored.add((note, _cosine(queryVector, entry.$2)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [
      for (final (note, score) in scored.take(30))
        if (score > 0.35) note,
    ];
  }

  static double _cosine(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
    var dot = 0.0, normA = 0.0, normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }
}
