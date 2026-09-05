import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemini_service.dart';

/// Bir arama isabetinin skoru: hangi sayfa, ne kadar yakın.
typedef ArchiveScore = ({int page, double score});

/// **DEFTERİN ANLAMSAL ARAMASI** (kullanıcı isteği 2026-09-04: "tüm defterde
/// arama yapabileceğim bir alan olmalı hem anlamsal hem metin olarak").
///
/// Ana ekrandaki [SemanticIndex]'in defter ölçeğindeki ikizi: orada birim
/// NOT, burada SAYFA. Aynı defterin iki sayfası birbirine çok benzediği için
/// not düzeyinde arama defterin içinde işe yaramıyordu — sorgu defteri
/// buluyor, sayfayı bulmuyordu.
///
/// Vektörler yalnız BELLEKTE ve defter başına tutulur; ekran kapanınca
/// gider. Sayfa metni değişmedikçe yeniden gömülmez (anahtar metnin kendisi:
/// sayfa adı değişse bile içerik aynıysa ağa çıkılmaz).
final archiveSemanticIndexProvider = Provider<ArchiveSemanticIndex>(
  (ref) => ArchiveSemanticIndex(),
);

class ArchiveSemanticIndex {
  /// sayfa metni → normalize vektör.
  final _vectors = <String, Float32List>{};

  /// sorgu metni → normalize vektör (küçük, eklenme sıralı).
  final _queries = <String, Float32List>{};
  static const _maxQueryCache = 16;

  /// Tek bir sayfaya gömülecek en fazla karakter: uzun bir sayfa vektörü
  /// "sulandırır" ve istek boyutunu büyütür.
  static const int maxPageChars = 1500;

  /// Sonucun eşiği. Ana ekrandakinden (0.35) DÜŞÜK: defterin içinde zaten
  /// dar bir küme aranıyor ve kullanıcı "hiç sonuç yok" yerine sıralı bir
  /// liste görmeyi bekliyor.
  static const double minScore = 0.28;

  /// [pages] sayfa metinleri (dizin = sayfa numarası). Dönen liste skora
  /// göre azalan sıralı ve eşiği geçenlerle sınırlı.
  Future<List<ArchiveScore>> search(
    GeminiService service,
    List<String> pages,
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final texts = [
      for (final page in pages)
        page.length > maxPageChars ? page.substring(0, maxPageChars) : page,
    ];
    // Yalnız BİLİNMEYEN metinler gömülür; boş sayfa hiç gönderilmez (boş
    // metnin vektörü yok ve istek de reddedilir).
    final missing = {
      for (final text in texts)
        if (text.trim().isNotEmpty && !_vectors.containsKey(text)) text,
    }.toList();
    for (var i = 0; i < missing.length; i += 50) {
      final batch = missing.sublist(i, min(i + 50, missing.length));
      final vectors = await service.embedTexts(batch);
      for (var j = 0; j < batch.length && j < vectors.length; j++) {
        _vectors[batch[j]] = normalize(vectors[j]);
      }
    }

    var queryVector = _queries[trimmed];
    if (queryVector == null) {
      queryVector = normalize((await service.embedTexts([trimmed])).first);
      if (_queries.length >= _maxQueryCache) {
        _queries.remove(_queries.keys.first);
      }
      _queries[trimmed] = queryVector;
    }

    return rank([
      for (final text in texts) _vectors[text],
    ], queryVector);
  }

  /// Vektörleri sorguya göre sıralar. Saf ve dışa açık: sıralama kuralı
  /// (eşik, azalan sıra, boş sayfaların düşmesi) testle ölçülüyor.
  static List<ArchiveScore> rank(
    List<Float32List?> pages,
    Float32List query,
  ) {
    final scored = <ArchiveScore>[];
    for (var i = 0; i < pages.length; i++) {
      final vector = pages[i];
      if (vector == null) continue;
      final score = dot(query, vector);
      if (score < minScore) continue;
      scored.add((page: i, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  /// Birim uzunluğa ölçekler; sıfır vektör olduğu gibi kalır (skoru 0 çıkar).
  static Float32List normalize(List<double> v) {
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

  static double dot(Float32List a, Float32List b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }
}
