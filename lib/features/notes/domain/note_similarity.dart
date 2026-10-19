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

/// Trigram kümesinin SAYISAL ve SIRALI hâli (F2.5): her üçlü (3 UTF-16
/// birimi) tek tamsayıya kodlanır — `c0·2³² + c1·2¹⁶ + c2` (48 bit; web'de de
/// tam, kaydırma değil çarpma: web'de `<<` 32 bittir). Sıralı tamsayı
/// dizisinde kesişim birleştirmeyle bulunur (küme aramasından hızlı) ve dizi
/// başka bir isolate'e ucuz kopyalanır.
List<int> trigramCodes(String normalized) {
  int code(int from, int to) {
    var v = to - from; // uzunluk işareti: kısa metinler 3'lüyle çakışmasın
    for (var i = from; i < to; i++) {
      v = v * 65536 + normalized.codeUnitAt(i);
    }
    return v;
  }

  if (normalized.length < 3) {
    return normalized.isEmpty ? const [] : [code(0, normalized.length)];
  }
  final codes = <int>{
    for (var i = 0; i + 3 <= normalized.length; i++) code(i, i + 3),
  }.toList()..sort();
  return codes;
}

double _jaccardSorted(List<int> a, List<int> b) {
  if (a.isEmpty || b.isEmpty) return a.isEmpty && b.isEmpty ? 1 : 0;
  var i = 0, j = 0, shared = 0;
  while (i < a.length && j < b.length) {
    final x = a[i], y = b[j];
    if (x == y) {
      shared++;
      i++;
      j++;
    } else if (x < y) {
      i++;
    } else {
      j++;
    }
  }
  return shared / (a.length + b.length - shared);
}

/// O(n²) eşleştirme aşaması — SAF ve yalnız tamsayı dizileriyle çalışır ki
/// `compute` ile arka plan isolate'inde koşabilsin (bkz.
/// `duplicateNotesProvider`). Girdi sırasındaki indeks kümelerini döndürür;
/// kümedeki ilk indeks kümeyi açan (en büyük metinli) nottur.
///
/// İki ucuzlatma: liste boyuta göre sıralanır ve boyut oranı eşiğin altına
/// düşünce iç döngü kırılır — Jaccard `min/max` oranını aşamaz.
List<List<int>> similarIndexGroups(List<List<int>> codes, double threshold) {
  final order = [
    for (var i = 0; i < codes.length; i++)
      if (codes[i].isNotEmpty) i,
  ]..sort((a, b) => codes[b].length.compareTo(codes[a].length));
  final groupOf = <int, int>{};
  final groups = <List<int>>[];
  for (var x = 0; x < order.length; x++) {
    final i = order[x];
    for (var y = x + 1; y < order.length; y++) {
      final j = order[y];
      if (codes[j].length / codes[i].length < threshold) break;
      if (groupOf.containsKey(j)) continue;
      if (_jaccardSorted(codes[i], codes[j]) < threshold) continue;
      final existing = groupOf[i];
      if (existing != null) {
        groups[existing].add(j);
        groupOf[j] = existing;
      } else {
        groupOf[i] = groups.length;
        groupOf[j] = groups.length;
        groups.add([i, j]);
      }
    }
  }
  return groups;
}

/// `compute` giriş noktası (tek argüman, üst düzey işlev).
List<List<int>> similarIndexGroupsEntry(
  (List<List<int>>, double) args,
) => similarIndexGroups(args.$1, args.$2);

/// Kopya karşılaştırmasına girecek notlar ve trigram kodları — ucuz aşama
/// (önbellekli). [trigramCache] verilirse kodlar `(updatedAt)` damgasıyla
/// orada saklanır ve İÇERİĞİ DEĞİŞMEMİŞ notlar için yeniden hesaplanmaz:
/// sağlayıcı her not yazımında yeniden çalışıyor ve n notun tamamının
/// normalize + trigram maliyeti her seferinde ödeniyordu. Boş dizi
/// "karşılaştırmaya değmez" işaretidir (kısa not).
({List<Note> notes, List<List<int>> codes}) duplicateCandidates(
  List<Note> notes, {
  Map<String, (DateTime?, List<int>)>? trigramCache,
}) {
  final kept = <Note>[];
  final codes = <List<int>>[];
  for (final note in notes) {
    if (note.archivedAt != null || note.deletedAt != null || note.locked) {
      continue;
    }
    var grams = switch (trigramCache?[note.id]) {
      (final stamp, final cached) when stamp == note.updatedAt => cached,
      _ => null,
    };
    if (grams == null) {
      final normalized = normalizeForCompare(note.toPlainText());
      grams = normalized.length < kMinCompareLength
          ? const <int>[]
          : trigramCodes(normalized);
      trigramCache?[note.id] = (note.updatedAt, grams);
    }
    if (grams.isEmpty) continue;
    kept.add(note);
    codes.add(grams);
  }
  return (notes: kept, codes: codes);
}

/// İndeks kümelerini not kümelerine çevirir; küme içinde en ESKİ not başa:
/// kullanıcıya "bunu tut, şunları sil" diye gösterilecek; orijinali tutmak
/// beklenen davranış.
List<List<Note>> notesOfGroups(List<Note> notes, List<List<int>> groups) {
  final out = [
    for (final g in groups) [for (final i in g) notes[i]],
  ];
  for (final group in out) {
    group.sort((a, b) {
      final at = a.createdAt, bt = b.createdAt;
      if (at == null || bt == null) return at == null ? 1 : -1;
      return at.compareTo(bt);
    });
  }
  return out;
}

/// Birbirinin kopyası olan not kümeleri (eşzamanlı yol — testler ve küçük
/// listeler). Her küme en az iki not içerir ve kümenin İLK notu en eskisidir
/// (korunacak olan); kalanlar silinebilir.
List<List<Note>> duplicateNoteGroups(
  List<Note> notes, {
  double threshold = kDuplicateThreshold,
  Map<String, (DateTime?, List<int>)>? trigramCache,
}) {
  final c = duplicateCandidates(notes, trigramCache: trigramCache);
  return notesOfGroups(c.notes, similarIndexGroups(c.codes, threshold));
}

/// Kopya kümelerinde SİLİNEBİLİR not sayısı (her kümede biri korunur).
/// Kutudaki sayı budur: "3 kopya" = üç not silinebilir demek.
int duplicateCount(List<List<Note>> groups) =>
    groups.fold(0, (sum, group) => sum + math.max(0, group.length - 1));
