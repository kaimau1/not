/// **ÖĞRENEN YAZIM DÜZELTME** (kullanıcı isteği 2026-11-08: "kişinin sık
/// yaptığı ve kendi düzelttiği yazılar arka planda öğrenilip harf harf kelime
/// kelime öğrenilip oto düzeltmede kullanılmalı — performans ve pil sorunu
/// oluşturmamalı; Türkçe, İngilizce ve Çince").
///
/// Saf Dart, Flutter'sız (testli). Üç katman:
///
/// 1. **Kişisel sözlük** ([SpellMemory.words]): kullanıcının yazdığı ve
///    notlarında geçen kelimeler, sıklıklarıyla. "Bilinen" kelimeye
///    dokunulmaz; bilinmeyen kelime en yakın sık kelimeye çekilir.
/// 2. **Kelime düzeltmeleri** ([SpellMemory.fixes]): kullanıcı bir kelimeyi
///    yazıp hemen geri dönüp düzelttiyse `yanlış → doğru` sayılır; iki kez
///    görülen düzeltme bir daha sorulmadan uygulanır. Kullanıcı OTOMATİK
///    düzeltmeyi geri aldıysa o kelime bir daha düzeltilmez
///    ([SpellMemory.rejected]).
/// 3. **Harf karışıklıkları** ([SpellMemory.confusions]): düzeltmeler harf
///    harf hizalanır ("o yerine p", "boşluk yerine n") — mesafe hesabı
///    kişinin sık karıştırdığı tuşları ucuz sayar.
///
/// Mesafe klavye düzenine göre ağırlıklıdır ([keyCost]): komşu tuş, şapkasız
/// harf (ı/i, ö/o, ş/s…) ve fazladan basılan komşu tuş ucuzdur —
/// "yaoçoılıyor" → "yapılıyor" yakındır, "kalem" → "kalın" uzaktır.
///
/// Çince (Han yazısı) için bulanık eşleştirme YOK — giriş yöntemi karakteri
/// zaten seçiyor; yalnız kullanıcının açıkça düzelttiği kalıplar öğrenilir.
///
/// Bedel: hesap yalnız KELİME BİTİNCE ve yalnız bilinmeyen kelimede; sözlük
/// uzunluğa göre kovalanır, yalnız ±2 uzunluktaki kelimeler taranır ve
/// mesafe eşiği aşılınca satır erken kesilir.
library;

import 'dart:convert';
import 'dart:math' as math;

/// Türkçe Q klavyesinin harf sıraları (İngilizce QWERTY bunun alt kümesi;
/// ı/ğ/ü/ş/i/ö/ç Türkçe konumlarında).
const _rows = ['qwertyuıopğü', 'asdfghjklşi', 'zxcvbnmöç'];

/// Sıraların yatay kayması (tuş genişliği cinsinden).
const _rowShift = [0.0, 0.3, 0.8];

final Map<String, (double, double)> _keyPos = () {
  final out = <String, (double, double)>{};
  for (var r = 0; r < _rows.length; r++) {
    for (var i = 0; i < _rows[r].length; i++) {
      out[_rows[r][i]] = (i + _rowShift[r], r.toDouble());
    }
  }
  return out;
}();

/// Şapkalı/şapkasız eşler: klavye ayarı yanlış olunca ya da aceleyle en sık
/// yapılan hata.
const _diacritic = {
  'ı': 'i', 'i': 'ı', 'ö': 'o', 'o': 'ö', 'ü': 'u', 'u': 'ü', //
  'ş': 's', 's': 'ş', 'ç': 'c', 'c': 'ç', 'ğ': 'g', 'g': 'ğ',
};

/// Boşluk çubuğunun hemen üstündeki tuşlar ("boşluk yerine n").
/// Kullanıcı 2026-11-08: "boşluk yerine yanlışlıkla v, b, n, m, ö" — Türkçe
/// Q'da ö, m'nin hemen sağında.
const _nearSpace = 'cvbnmö';

/// [a] yerine [b] basmanın bedeli (0–1). Komşu tuş ≈ 0,45, şapka 0,3.
double keyCost(String a, String b) {
  if (a == b) return 0;
  if (_diacritic[a] == b) return 0.3;
  if (a == ' ' || b == ' ') {
    final other = a == ' ' ? b : a;
    return _nearSpace.contains(other) ? 0.5 : 1;
  }
  final pa = _keyPos[a];
  final pb = _keyPos[b];
  if (pa == null || pb == null) return 1;
  final d = math.sqrt(math.pow(pa.$1 - pb.$1, 2) + math.pow(pa.$2 - pb.$2, 2));
  if (d <= 1.15) return 0.45;
  if (d <= 1.6) return 0.7;
  return 1;
}

/// Kelime Han yazısı mı (Çince: bulanık düzeltme yok).
bool isCjk(String w) => RegExp(r'\p{Script=Han}', unicode: true).hasMatch(w);

/// Kelime İngilizce mi görünüyor (yalnız Latin ASCII ve Türkçeye yabancı
/// harf kalıbı) — cihaz denetçisinin dili ve sözlük seçimi için.
bool looksEnglish(String w) {
  final l = w.toLowerCase();
  if (RegExp('[çğıöşü]').hasMatch(l)) return false;
  if (!RegExp(r'^[a-z]+$').hasMatch(l)) return false;
  if (kCommonEnglish.contains(l)) return true;
  return RegExp(r'(w|q|x|th|ee|oo|ck|sh|ght|tion)').hasMatch(l);
}

/// Türkçe küçük harf (I → ı, İ → i).
String trLower(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// Kişisel yazım hafızası. JSON'a yazılır ([toJson]); sınırlar
/// ([maxWords], [maxFixes]) dosyayı küçük tutar.
class SpellMemory {
  SpellMemory();

  static const maxWords = 5000;
  static const maxFixes = 600;
  static const maxConfusions = 400;

  /// Kelime → görülme sayısı (küçük harf).
  final Map<String, int> words = {};

  /// Yanlış → (doğru → sayı).
  final Map<String, Map<String, int>> fixes = {};

  /// Otomatik düzeltmesi kullanıcı tarafından geri alınan kelimeler.
  final Set<String> rejected = {};

  /// "yazılan>kastedilen" harf çifti → sayı ("o>p", "n> ").
  final Map<String, int> confusions = {};

  /// Notlardan gelen sözlük (kaydedilmez, her açılışta yeniden kurulur).
  final Map<String, int> seeded = {};

  /// Uzunluk → kelimeler (bulanık arama kovası); kelime değişince düşer.
  Map<int, List<String>>? _byLength;

  bool get isEmpty => words.isEmpty && fixes.isEmpty && confusions.isEmpty;

  int get learnedCount => fixes.length + confusions.length;

  /// Kelimenin toplam sıklığı (yazılan + notlardaki + yerleşik).
  int frequency(String w) {
    final l = trLower(w);
    var n = (words[l] ?? 0) + (seeded[l] ?? 0);
    if (kCommonTurkish.contains(l) || kCommonEnglish.contains(l)) n += 3;
    return n;
  }

  /// Bilinen kelime: dokunulmaz. Yalnız yazılmış (doğrulanmamış) kelime
  /// üç kez görülünce bilinir — iki kez aynı yazım hatası sözlüğe girmesin.
  bool known(String w) => frequency(w) >= 3 || rejected.contains(trLower(w));

  void addWord(String w, [int by = 1]) {
    final l = trLower(w);
    if (l.length < 2 || l.length > 30) return;
    final had = words.containsKey(l);
    words[l] = (words[l] ?? 0) + by;
    if (!had) _byLength = null;
    if (words.length > maxWords) _pruneWords();
  }

  void _pruneWords() {
    // En az görülenler gider (yarı yarıya), sayılar da yaşlanır.
    final sorted = words.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final e in sorted.take(words.length - maxWords * 3 ~/ 4)) {
      words.remove(e.key);
    }
    _byLength = null;
  }

  /// Notların metninden sözlük (ağır iş: [seedCounts] arka planda sayar).
  void seed(Map<String, int> counts) {
    seeded
      ..clear()
      ..addAll(counts);
    _byLength = null;
  }

  /// Kullanıcı [from] yazıp kendisi [to] yaptı.
  void learnFix(String from, String to) {
    final f = trLower(from);
    final t = to.trim();
    if (f.isEmpty || t.isEmpty || f == trLower(t)) return;
    rejected.remove(f);
    final m = fixes.putIfAbsent(f, () => {});
    m[t] = (m[t] ?? 0) + 1;
    if (fixes.length > maxFixes) {
      // En az kullanılan düzeltme gider.
      final weakest = fixes.entries.reduce(
        (a, b) => _total(a.value) <= _total(b.value) ? a : b,
      );
      fixes.remove(weakest.key);
    }
    for (final w in t.split(' ')) {
      addWord(w);
    }
    if (!isCjk(f)) _learnLetters(f, trLower(t));
  }

  /// ELLE EKLENEN düzeltme (Ayarlar → Öğrenilen yazımlar): ilk görüşte
  /// uygulanır (iki kez görülmüş sayılır).
  void addManualFix(String from, String to) {
    final f = trLower(from.trim());
    final t = to.trim();
    if (f.isEmpty || t.isEmpty || f == trLower(t)) return;
    rejected.remove(f);
    final m = fixes.putIfAbsent(f, () => {});
    m[t] = math.max(m[t] ?? 0, 2) + 1;
    for (final w in t.split(' ')) {
      addWord(w, 3);
    }
  }

  /// Düzeltmeyi unutur (Ayarlar listesinden silme).
  void removeFix(String from) => fixes.remove(trLower(from));

  /// "Dokunulmayan" kelimeyi yeniden düzeltmeye açar.
  void unreject(String word) => rejected.remove(trLower(word));

  /// Ayarlar listesi: her yanlış yazım için en güçlü doğrusu, sık olan önce.
  List<({String from, String to, int count})> fixList() {
    final out = [
      for (final e in fixes.entries)
        if (e.value.isNotEmpty)
          () {
            final best = e.value.entries.reduce(
              (a, b) => a.value >= b.value ? a : b,
            );
            return (from: e.key, to: best.key, count: best.value);
          }(),
    ];
    out.sort((a, b) => b.count.compareTo(a.count));
    return out;
  }

  /// Kullanıcı otomatik düzeltmeyi geri aldı: [word] bir daha düzeltilmez.
  void reject(String word, {String? wrongFix}) {
    final l = trLower(word);
    rejected.add(l);
    addWord(l, 2);
    if (wrongFix != null) fixes[l]?.remove(wrongFix);
    if (fixes[l]?.isEmpty ?? false) fixes.remove(l);
    if (rejected.length > maxFixes) rejected.remove(rejected.first);
  }

  static int _total(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

  /// Hizalama: düzeltmenin harf düzeyindeki yer değiştirmeleri sayılır.
  void _learnLetters(String from, String to) {
    for (final (a, b) in alignSubstitutions(from, to)) {
      final k = '$a>$b';
      confusions[k] = (confusions[k] ?? 0) + 1;
    }
    if (confusions.length > maxConfusions) {
      final weakest = confusions.entries.reduce(
        (a, b) => a.value <= b.value ? a : b,
      );
      confusions.remove(weakest.key);
    }
  }

  /// Kişiye göre yer değiştirme bedeli: sık karıştırdığı çift ucuzlar.
  double subCost(String typed, String meant) {
    final base = keyCost(typed, meant);
    final n = confusions['$typed>$meant'] ?? 0;
    if (n == 0) return base;
    return math.max(0.15, base / (1 + 0.5 * n));
  }

  /// Yazılan kelime → kastedilen (kişiye göre ağırlıklı Damerau–Levenshtein).
  /// [limit] aşılınca erken kesilir (dönen değer > limit).
  double distance(String typed, String meant, {double limit = 99}) {
    final a = typed;
    final b = meant;
    if ((a.length - b.length).abs() > limit + 0.01) return limit + 1;
    // Fazladan basılan tuş: komşusuna yakınsa ucuz.
    double ins(int i) {
      final c = a[i];
      final prev = i > 0 ? a[i - 1] : null;
      final next = i + 1 < a.length ? a[i + 1] : null;
      var best = 0.95;
      for (final o in [?prev, ?next]) {
        if (o == c) best = math.min(best, 0.5);
        if (keyCost(c, o) <= 0.45) best = math.min(best, 0.6);
      }
      return best;
    }

    var prev2 = <double>[];
    var prev = List<double>.generate(b.length + 1, (j) => j.toDouble());
    for (var i = 1; i <= a.length; i++) {
      final cur = List<double>.filled(b.length + 1, 0);
      cur[0] = prev[0] + ins(i - 1);
      var rowMin = cur[0];
      for (var j = 1; j <= b.length; j++) {
        final ca = a[i - 1];
        final cb = b[j - 1];
        var v = math.min(
          prev[j] + ins(i - 1), // yazılanda fazla harf
          cur[j - 1] + 0.9, // yazılanda eksik harf
        );
        v = math.min(v, prev[j - 1] + (ca == cb ? 0 : subCost(ca, cb)));
        if (i > 1 &&
            j > 1 &&
            ca == b[j - 2] &&
            a[i - 2] == cb &&
            prev2.isNotEmpty) {
          v = math.min(v, prev2[j - 2] + 0.55); // yer değiştirmiş iki harf
        }
        cur[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > limit) return limit + 1;
      prev2 = prev;
      prev = cur;
    }
    return prev[b.length];
  }

  /// Uzunluğa göre izin verilen en büyük mesafe.
  static double limitFor(int length) => length <= 3
      ? 0
      : length <= 5
      ? 0.8
      : length <= 8
      ? 1.35
      : 2.1;

  List<String> _bucket(int len) {
    final byLen = _byLength ??= () {
      final m = <int, List<String>>{};
      void add(String w) => m.putIfAbsent(w.length, () => []).add(w);
      final all = <String>{
        ...words.keys,
        ...seeded.keys,
        ...kCommonTurkish,
        ...kCommonEnglish,
      };
      all.forEach(add);
      return m;
    }();
    return byLen[len] ?? const [];
  }

  /// [word] (küçük harf, tek kelime) için öneri; yoksa null. Büyük harf ve
  /// cümle başı çağıranın işi.
  String? suggest(String word) {
    final w = trLower(word);
    if (w.length < 2 || rejected.contains(w)) return null;
    // 1) Öğrenilmiş düzeltme: iki kez görüldüyse (ya da tek ve kelime hiç
    // bilinmiyorsa) uygulanır.
    final learned = fixes[w];
    if (learned != null && learned.isNotEmpty) {
      final best = learned.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (best.value >= 2 || !known(w)) return best.key;
    }
    if (isCjk(w) || known(w)) return null;
    // 2) Boşluk yerine "n" (ya da boşluk çubuğu komşusu): iki bilinen kelime.
    final split = splitMissedSpace(w);
    if (split != null) return split;
    // 3) Bulanık: en yakın sık kelime.
    return nearest(w);
  }

  /// "eksiknyapılıyor" → "eksik yapılıyor": araya düşen boşluk komşusu
  /// harfin iki yanı da bilinen kelimeyse.
  String? splitMissedSpace(String w) {
    String? best;
    var bestScore = 0;
    for (var i = 2; i < w.length - 2; i++) {
      final c = w[i];
      if (!_nearSpace.contains(c)) continue;
      final left = w.substring(0, i);
      final right = w.substring(i + 1);
      final fl = frequency(left);
      final fr = frequency(right);
      if (fl < 3 || fr < 3) continue;
      // Kişi "n> " karışıklığını daha önce yaptıysa eşik düşer.
      final bias = confusions['$c> '] ?? 0;
      final score = math.min(fl, fr) + bias * 2 + (c == 'n' ? 1 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = '$left $right';
      }
    }
    return best;
  }

  /// Sözlükteki en yakın kelime (eşik [limitFor]); eşitlikte sık olan.
  String? nearest(String w) {
    final limit = limitFor(w.length);
    if (limit <= 0) return null;
    String? best;
    var bestCost = limit + 0.0001;
    var bestFreq = 0;
    final first = w[0];
    for (var len = w.length - 2; len <= w.length + 2; len++) {
      for (final cand in _bucket(len)) {
        if (cand == w) continue;
        // TÜRKÇE EKLER: aday yazılanın kökü ya da uzantısıysa ("kalemi" ↔
        // "kalem", "kale" ↔ "kalem") ikisi de büyük olasılıkla gerçek kelime.
        if (cand.startsWith(w) || w.startsWith(cand)) continue;
        // İlk harf aynı ya da komşu/şapka eşi olmalı (hızlı eleme).
        if (cand[0] != first && keyCost(first, cand[0]) > 0.5) continue;
        final freq = frequency(cand);
        if (freq < 3) continue;
        final cost = distance(w, cand, limit: bestCost);
        if (cost < bestCost - 0.05 ||
            (cost <= bestCost + 0.05 && freq > bestFreq)) {
          if (cost > limit) continue;
          best = cand;
          bestCost = cost;
          bestFreq = freq;
        }
      }
    }
    return best != null && changesTooMuch(w, best) ? null : best;
  }

  /// **TANINMAZ DÜZELTME KAPISI** (kullanıcı bulgusu 2026-11-09: "bazen o
  /// kadar yanlış yazılıyor ki hiçbir tanıma yapılmıyor"): klavye ağırlıklı
  /// mesafede komşu tuşlar ve şapkalar ucuz olduğu için uzun kelimede
  /// harflerin yarısı değişebiliyordu. OTOMATİK (bulanık / cihaz önerisi)
  /// düzeltme harflerin üçte birinden fazlasını değiştiremez; kullanıcının
  /// öğrettiği düzeltmeler (kısaltmalar dahil) bu kapıya girmez.
  static bool changesTooMuch(String a, String b) {
    final x = trLower(a), y = trLower(b);
    var prev = List<int>.generate(y.length + 1, (i) => i);
    for (var i = 1; i <= x.length; i++) {
      final cur = List<int>.filled(y.length + 1, 0)..[0] = i;
      for (var j = 1; j <= y.length; j++) {
        cur[j] = math.min(
          math.min(prev[j] + 1, cur[j - 1] + 1),
          prev[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1),
        );
      }
      prev = cur;
    }
    return prev[y.length] > math.max(1, x.length ~/ 3);
  }

  /// Otomatik düzeltme yanlıştı, kullanıcı başka kelime yazdı: o eşleşme
  /// unutulur (bir daha aynı yanlışa çekilmesin).
  void unlearnFix(String from, String wrongTo) {
    final f = trLower(from);
    final m = fixes[f];
    if (m == null) return;
    m.removeWhere((k, _) => trLower(k) == trLower(wrongTo));
    if (m.isEmpty) fixes.remove(f);
  }

  Map<String, Object?> toJson() => {
    'v': 1,
    'w': words,
    'f': fixes,
    'r': rejected.toList(),
    'c': confusions,
  };

  String encode() => jsonEncode(toJson());

  static SpellMemory decode(String? raw) {
    final m = SpellMemory();
    if (raw == null || raw.isEmpty) return m;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      (j['w'] as Map?)?.forEach((k, v) => m.words['$k'] = (v as num).toInt());
      (j['f'] as Map?)?.forEach((k, v) {
        m.fixes['$k'] = {
          for (final e in (v as Map).entries)
            '${e.key}': (e.value as num).toInt(),
        };
      });
      for (final r in (j['r'] as List?) ?? const []) {
        m.rejected.add('$r');
      }
      (j['c'] as Map?)?.forEach(
        (k, v) => m.confusions['$k'] = (v as num).toInt(),
      );
    } catch (_) {
      // Bozuk dosya: boş hafızayla devam.
    }
    return m;
  }
}

/// İki kelimenin harf düzeyinde hizalanmış YER DEĞİŞTİRMELERİ (yazılan,
/// kastedilen). Fazla/eksik harf çift üretmez; boşluk dahil.
List<(String, String)> alignSubstitutions(String from, String to) {
  final n = from.length;
  final m = to.length;
  if (n * m > 2500) return const [];
  final d = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = 0; i <= n; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= m; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      d[i][j] = math.min(
        math.min(d[i - 1][j] + 1, d[i][j - 1] + 1),
        d[i - 1][j - 1] + (from[i - 1] == to[j - 1] ? 0 : 1),
      );
    }
  }
  final out = <(String, String)>[];
  var i = n;
  var j = m;
  while (i > 0 && j > 0) {
    final same = from[i - 1] == to[j - 1];
    if (d[i][j] == d[i - 1][j - 1] + (same ? 0 : 1)) {
      if (!same) out.add((from[i - 1], to[j - 1]));
      i--;
      j--;
    } else if (d[i][j] == d[i - 1][j] + 1) {
      i--;
    } else {
      j--;
    }
  }
  return out;
}

/// Metinlerden kelime sayımı (notlardan sözlük). Arka planda (`compute`)
/// koşacak kadar saf; en çok [limit] kelime tutulur.
Map<String, int> seedCounts(List<String> texts, {int limit = 8000}) {
  final counts = <String, int>{};
  final re = RegExp(r'[\p{L}]{2,30}', unicode: true);
  var chars = 0;
  for (final t in texts) {
    chars += t.length;
    if (chars > 3000000) break; // 3 MB üstü: yeter.
    for (final m in re.allMatches(t)) {
      final w = trLower(m.group(0)!);
      if (isCjk(w) && w.length > 4) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
  }
  if (counts.length <= limit) return counts;
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sorted.take(limit));
}

/// Yerleşik sık Türkçe kelimeler (başlangıç sözlüğü — kişisel sözlük
/// büyüdükçe önemi azalır).
const kCommonTurkish = <String>{
  'acaba',
  'açık',
  'ad',
  'adres',
  'ağaç',
  'ahmet',
  'akşam',
  'al',
  'alan',
  'alarm',
  'alındı',
  'alış',
  'alışveriş',
  'altı',
  'altında',
  'ama',
  'amaç',
  'an',
  'ana',
  'anahtar',
  'anda',
  'anne',
  'ara',
  'araba',
  'arada',
  'aralık',
  'arasında',
  'arkadaş',
  'artık',
  'aslında',
  'ay',
  'aynı',
  'az',
  'baba',
  'bakım',
  'bakmak',
  'banka',
  'bana',
  'bazen',
  'bazı',
  'başka',
  'başla',
  'başladı',
  'başlık',
  'bekle',
  'belge',
  'ben',
  'benim',
  'beni',
  'bile',
  'bilgi',
  'bilgisayar',
  'bir',
  'biraz',
  'birlikte',
  'bitti',
  'biz',
  'bize',
  'bizim',
  'boş',
  'bu',
  'bugün',
  'bunu',
  'bunlar',
  'burada',
  'büyük',
  'cuma',
  'cumartesi',
  'çalış',
  'çalışıyor',
  'çalışma',
  'çarşamba',
  'çay',
  'çek',
  'çekme',
  'çık',
  'çocuk',
  'çok',
  'çünkü',
  'da',
  'daha',
  'dakika',
  'de',
  'değil',
  'değişti',
  'defter',
  'devam',
  'diğer',
  'diye',
  'doğru',
  'dosya',
  'dolayı',
  'durum',
  'düzelt',
  'düzeltme',
  'düzeltmeler',
  'ekmek',
  'eksik',
  'ekle',
  'eklendi',
  'el',
  'en',
  'erken',
  'eski',
  'et',
  'ev',
  'evet',
  'fakat',
  'fatura',
  'fazla',
  'fiyat',
  'gece',
  'geç',
  'gel',
  'geldi',
  'gelecek',
  'geliyor',
  'gelir',
  'gerek',
  'gerekiyor',
  'geri',
  'git',
  'gitti',
  'gibi',
  'gidiyor',
  'göre',
  'görev',
  'gör',
  'gün',
  'güncel',
  'güzel',
  'hafta',
  'hala',
  'hangi',
  'hasta',
  'hatırla',
  'hatırlatma',
  'hava',
  'hayır',
  'hazır',
  'hem',
  'hemen',
  'hep',
  'her',
  'hesap',
  'hızlı',
  'hiç',
  'için',
  'içinde',
  'iki',
  'ile',
  'ilk',
  'iptal',
  'iş',
  'işte',
  'iste',
  'istiyor',
  'iyi',
  'kadar',
  'kağıt',
  'kalan',
  'kalem',
  'kapı',
  'kaydet',
  'kayıt',
  'kendi',
  'kez',
  'kim',
  'kitap',
  'kolay',
  'kolu',
  'kontrol',
  'kötü',
  'kullan',
  'kullanıcı',
  'liste',
  'madde',
  'mail',
  'market',
  'mesaj',
  'mı',
  'mi',
  'mu',
  'mü',
  'nasıl',
  'ne',
  'neden',
  'nerede',
  'not',
  'notlar',
  'o',
  'oda',
  'okul',
  'olan',
  'olarak',
  'olacak',
  'oldu',
  'olmalı',
  'olsun',
  'on',
  'once',
  'onu',
  'onlar',
  'orada',
  'otomatik',
  'ödeme',
  'önce',
  'önemli',
  'öyle',
  'para',
  'pazar',
  'pazartesi',
  'perşembe',
  'proje',
  'randevu',
  'saat',
  'sabah',
  'sadece',
  'salı',
  'sağa',
  'sana',
  'sanki',
  'sen',
  'sende',
  'senin',
  'sev',
  'sil',
  'sipariş',
  'sonra',
  'son',
  'sorun',
  'su',
  'süt',
  'şey',
  'şimdi',
  'şu',
  'tablo',
  'tamam',
  'tam',
  'tarih',
  'telefon',
  'toplantı',
  'tüm',
  'uygulama',
  'uzun',
  've',
  'var',
  'veya',
  'ver',
  'yalnız',
  'yani',
  'yap',
  'yapıldı',
  'yapılıyor',
  'yapılacak',
  'yapıyor',
  'yapmak',
  'yarın',
  'yaz',
  'yazı',
  'yazılım',
  'yazım',
  'yemek',
  'yeni',
  'yer',
  'yeter',
  'yeterli',
  'yine',
  'yok',
  'yol',
  'yorum',
  'yukarı',
  'zaman',
  'zor',
};

/// Yerleşik sık İngilizce kelimeler.
const kCommonEnglish = <String>{
  'about',
  'after',
  'again',
  'all',
  'also',
  'always',
  'and',
  'any',
  'are',
  'back',
  'because',
  'been',
  'before',
  'being',
  'best',
  'better',
  'book',
  'both',
  'but',
  'buy',
  'call',
  'can',
  'check',
  'come',
  'could',
  'day',
  'did',
  'does',
  'done',
  'down',
  'each',
  'email',
  'even',
  'every',
  'file',
  'find',
  'first',
  'fix',
  'for',
  'from',
  'get',
  'give',
  'good',
  'great',
  'had',
  'has',
  'have',
  'help',
  'her',
  'here',
  'him',
  'his',
  'home',
  'how',
  'idea',
  'into',
  'just',
  'know',
  'last',
  'later',
  'like',
  'list',
  'little',
  'long',
  'look',
  'make',
  'many',
  'meeting',
  'more',
  'most',
  'much',
  'must',
  'need',
  'never',
  'new',
  'next',
  'not',
  'note',
  'notes',
  'now',
  'only',
  'other',
  'our',
  'out',
  'over',
  'people',
  'please',
  'project',
  'read',
  'really',
  'remember',
  'right',
  'same',
  'say',
  'see',
  'send',
  'should',
  'some',
  'something',
  'still',
  'such',
  'take',
  'task',
  'than',
  'thank',
  'thanks',
  'that',
  'the',
  'their',
  'them',
  'then',
  'there',
  'these',
  'they',
  'thing',
  'things',
  'think',
  'this',
  'those',
  'time',
  'today',
  'tomorrow',
  'two',
  'under',
  'until',
  'update',
  'use',
  'very',
  'want',
  'was',
  'way',
  'week',
  'well',
  'were',
  'what',
  'when',
  'where',
  'which',
  'while',
  'who',
  'why',
  'will',
  'with',
  'work',
  'would',
  'write',
  'year',
  'yes',
  'you',
  'your',
};
