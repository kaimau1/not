import 'dart:math' as math;

import 'note.dart';

/// Kopya not bulma — "Kopyaları temizle" kutusunun sayısı buradan çıkar.
///
/// NEDEN AI DEĞİL: embedding kotayı harcar, yalnız Gemini'de çalışır (bkz.
/// KALANLAR) ve her açılışta yüzlerce notu vektöre çevirmek gerekirdi.
/// Kopya notlar zaten anlamca değil METİNCE aynıdır: iki kez kaydedilmiş,
/// iki cihazdan girilmiş, kopyala-yapıştır kalıntısı. Üçlü harf kümeleri
/// (trigram) üzerinde Jaccard örtüşmesi bunu yerelde, bedavaya ve küçük
/// yazım farklarına dayanıklı biçimde ölçer.

/// Karşılaştırmadan önce metni sadeleştirir: küçük harf, noktalama yok, tek
/// boşluk. Türkçe'nin I/İ ayrımı `toLowerCase` ile bozulmadığından ayrıca
/// ele alınmıyor — iki metin de aynı dönüşümden geçtiği için sonuç tutarlı.
String normalizeForCompare(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Metnin üçlü harf kümeleri. Sınırlarda boşluk eklenmez: kelime sırası
/// değişse de örtüşme korunsun ("süt ekmek" ≈ "ekmek süt" değil ama
/// "alışveriş listesi" ile "alisveris listesi" yakın kalsın).
Set<String> textTrigrams(String normalized) {
  if (normalized.length < 3) {
    return normalized.isEmpty ? const {} : {normalized};
  }
  return {
    for (var i = 0; i + 3 <= normalized.length; i++)
      normalized.substring(i, i + 3),
  };
}

/// 0–1 arası benzerlik (Jaccard). Aynı metin 1.0, hiç örtüşmeyen 0.
double textSimilarity(String a, String b) {
  final x = textTrigrams(normalizeForCompare(a));
  final y = textTrigrams(normalizeForCompare(b));
  return _jaccard(x, y);
}

double _jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return a.isEmpty && b.isEmpty ? 1 : 0;
  var shared = 0;
  // Küçük kümeyi gez: kesişim aynı, iş yarıya iner.
  final (small, large) = a.length <= b.length ? (a, b) : (b, a);
  for (final gram in small) {
    if (large.contains(gram)) shared++;
  }
  return shared / (a.length + b.length - shared);
}

/// Karşılaştırmaya değmeyecek kadar kısa not: "ok", "ara" gibi metinlerde
/// trigram örtüşmesi rastlantısal olur ve alakasız notlar kopya görünür.
const int kMinCompareLength = 12;

/// Kopya sayılma eşiği. 0.8: yazım/noktalama farkı olan aynı notu yakalar,
/// aynı konudaki İKİ AYRI notu yakalamaz (denendi: 0.6'da alışveriş
/// listeleri birbirine karışıyor).
const double kDuplicateThreshold = 0.8;

/// Birbirinin kopyası olan not kümeleri. Her küme en az iki not içerir ve
/// kümenin İLK notu en eskisidir (korunacak olan); kalanlar silinebilir.
///
/// Karşılaştırma O(n²) ama iki ucuzlatma var: (1) trigram kümeleri bir kez
/// hesaplanır, (2) liste küme boyutuna göre sıralanıp boyut oranı eşiğin
/// altına düşünce iç döngü kırılır — Jaccard `min/max` oranını aşamaz.
List<List<Note>> duplicateNoteGroups(
  List<Note> notes, {
  double threshold = kDuplicateThreshold,
}) {
  final entries = <({Note note, Set<String> grams})>[];
  for (final note in notes) {
    if (note.archivedAt != null || note.deletedAt != null || note.locked) {
      continue;
    }
    final normalized = normalizeForCompare(note.toPlainText());
    if (normalized.length < kMinCompareLength) continue;
    entries.add((note: note, grams: textTrigrams(normalized)));
  }
  // Büyükten küçüğe: iç döngüde oran düşünce kırmak için boyut sıralı olmalı.
  entries.sort((a, b) => b.grams.length.compareTo(a.grams.length));

  final groupOf = <String, int>{};
  final groups = <List<Note>>[];
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      // Jaccard en fazla min/max kadar olabilir; oran eşiğin altına düştüyse
      // kalan (daha da küçük) kümelerin hiçbiri eşiği geçemez.
      if (entries[j].grams.length / entries[i].grams.length < threshold) break;
      if (groupOf.containsKey(entries[j].note.id)) continue;
      if (_jaccard(entries[i].grams, entries[j].grams) < threshold) continue;

      final existing = groupOf[entries[i].note.id];
      if (existing != null) {
        groups[existing].add(entries[j].note);
        groupOf[entries[j].note.id] = existing;
      } else {
        groupOf[entries[i].note.id] = groups.length;
        groupOf[entries[j].note.id] = groups.length;
        groups.add([entries[i].note, entries[j].note]);
      }
    }
  }

  // Küme içinde en ESKİ not başa: kullanıcıya "bunu tut, şunları sil" diye
  // gösterilecek; orijinali tutmak beklenen davranış.
  for (final group in groups) {
    group.sort((a, b) {
      final at = a.createdAt, bt = b.createdAt;
      if (at == null || bt == null) return at == null ? 1 : -1;
      return at.compareTo(bt);
    });
  }
  return groups;
}

/// Kopya kümelerinde SİLİNEBİLİR not sayısı (her kümede biri korunur).
/// Kutudaki sayı budur: "3 kopya" = üç not silinebilir demek.
int duplicateCount(List<List<Note>> groups) =>
    groups.fold(0, (sum, group) => sum + math.max(0, group.length - 1));
