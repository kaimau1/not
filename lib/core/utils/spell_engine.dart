/// **YAZIM KARAR MOTORU v2** (Faz 70, kullanıcı 2026-11-09: "düzeltilmişi
/// değiştiriyorum, ısrarla kendi düzelttiğine getiriyor"). Saf Dart: tek giriş
/// [SpellEngine.decide]; alan bağlama (`auto_spell.dart`) yalnız olayı taşır
/// ve kararı uygular.
///
/// Sözleşme (sırayla; ilk eşleşen karar verir):
/// 1. Bu notta dokunulmaz ya da kullanıcının "dokunma" dediği kelime → yok.
/// 2. Kullanıcının öğrettiği/onayladığı düzeltme ([SpellMemory.learned]).
/// 3. Açık kural tablosu ([fixTurkishWord]: "herşey" → "her şey").
/// 4. Yalnız kurallar kipi, başlık, Çince ya da BİLİNEN kelime → yok
///    (bilinen = sözlük + ek çözücü, bkz. [SpellMemory.known]).
/// 4b. Y-2 harfsiz yazım ("calisma" → "çalışma"): Türkçe harfli TEK bilinen
///    karşılık varsa o; birden çoksa ("aci": acı/açı) dokunma.
/// 4c. Y-3 genel kalıplar ([patternFix]): sonuç bilinen kelimeyse.
/// 5. Boşluk yerine boşluk komşusu harf: iki parça da bilinen kelime.
/// 6. Tek adaylı + yüksek güvenli bulanık eşleşme (ikinci aday
///    [confidenceMargin] içindeyse dokunma) ya da tek yakın cihaz önerisi.
/// Kullanıcının reddettiği (yazılan → düzeltilen) çift hiçbir aşamada
/// uygulanmaz: ilk adayı reddedilmiş kelimeye hiç dokunulmaz.
library;

import 'dart:math' as math;

import 'spell_fix.dart' show contextualFix, fixTurkishWord, trUpper;
import 'spell_learn.dart';

/// Türkçe Q klavyesinin harf sıraları (İngilizce QWERTY bunun alt kümesi).
const _rows = ['qwertyuıopğü', 'asdfghjklşi', 'zxcvbnmöç'];
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

const _diacritic = {
  'ı': 'i', 'i': 'ı', 'ö': 'o', 'o': 'ö', 'ü': 'u', 'u': 'ü', //
  'ş': 's', 's': 'ş', 'ç': 'c', 'c': 'ç', 'ğ': 'g', 'g': 'ğ',
};

/// Boşluk çubuğunun hemen üstündeki tuşlar ("boşluk yerine n").
const nearSpace = 'cvbnmö';

/// [a] yerine [b] basmanın bedeli (0–1). Komşu tuş ≈ 0,45, şapka 0,3.
double keyCost(String a, String b) {
  if (a == b) return 0;
  if (_diacritic[a] == b) return 0.3;
  if (a == ' ' || b == ' ') {
    final other = a == ' ' ? b : a;
    return nearSpace.contains(other) ? 0.5 : 1;
  }
  final pa = _keyPos[a];
  final pb = _keyPos[b];
  if (pa == null || pb == null) return 1;
  final d = math.sqrt(math.pow(pa.$1 - pb.$1, 2) + math.pow(pa.$2 - pb.$2, 2));
  if (d <= 1.15) return 0.45;
  if (d <= 1.6) return 0.7;
  return 1;
}

enum SpellReason { rule, learned, ascii, split, fuzzy, device }

/// Karar: [to] null ise dokunma.
class SpellDecision {
  const SpellDecision._(this.to, this.reason);
  static const none = SpellDecision._(null, null);

  final String? to;
  final SpellReason? reason;
  bool get isNone => to == null;
}

class SpellInput {
  const SpellInput({
    required this.word,
    required this.memory,
    this.title = false,
    this.rulesOnly = false,
    this.noteKeep = const {},
    this.device,
  });

  /// Biten kelime (yalnız harfler).
  final String word;

  /// Kişisel sözlük + öğrenilmişler + reddedilenler.
  final SpellMemory memory;

  /// Başlık alanı: yalnız kurallar ve öğretilenler.
  final bool title;

  /// Ayarlar → "yalnız kurallar".
  final bool rulesOnly;

  /// Bu notta otomatik düzeltilmeyecek kelimeler (küçük harf).
  final Set<String> noteKeep;

  /// Cihaz yazım denetçisinin önerileri (ikinci, eşzamansız tur); verilince
  /// bulanık sözlük araması yerine bunlar değerlendirilir.
  final List<String>? device;
}

class SpellEngine {
  SpellEngine._();

  /// GÜVEN EŞİĞİ (tek yer): en iyi adaydan sonraki aday bu kadar yakınsa
  /// karar belirsizdir, dokunulmaz.
  static const confidenceMargin = 0.3;

  static SpellDecision decide(SpellInput i) {
    final word = i.word;
    final w = trLower(word);
    if (w.length < 2) return SpellDecision.none;
    // Tamamı büyük (kısaltma); Çince'de büyük/küçük yok.
    if (w != word && trUpper(word) == word) return SpellDecision.none;
    final m = i.memory;
    if (i.noteKeep.contains(w) || m.keep.contains(w)) return SpellDecision.none;

    SpellDecision pick(String? to, SpellReason r) {
      if (to == null || m.isRejected(w, to)) return SpellDecision.none;
      return SpellDecision._(matchCase(word, to), r);
    }

    final learned = m.learned(w);
    if (learned != null) return pick(learned, SpellReason.learned);
    final rule = fixTurkishWord(w);
    if (rule != w) return pick(rule, SpellReason.rule);
    if (i.rulesOnly || i.title || isCjk(w) || m.known(w)) {
      return SpellDecision.none;
    }
    final ascii = asciiRestore(w, m);
    if (ascii.length == 1) return pick(ascii.single, SpellReason.ascii);
    if (ascii.length > 1) {
      // Belirsiz: yalnız cihaz önerisi birini seçerse.
      final dev = {for (final s in i.device ?? const <String>[]) trLower(s)};
      final hit = ascii.where(dev.contains).toList();
      return hit.length == 1
          ? pick(hit.single, SpellReason.ascii)
          : SpellDecision.none;
    }
    final pattern = patternFix(w, m);
    if (pattern != null) return pick(pattern, SpellReason.rule);
    // Sonda yinelenen harf ("kitapp"): bulanık eşleşme kök/uzantı ilişkisini
    // atladığı için burada; yazılan bilinmiyor, bir harf eksiği biliniyor.
    final n = w.length;
    if (n >= 4 && w[n - 1] == w[n - 2] && m.known(w.substring(0, n - 1))) {
      return pick(w.substring(0, n - 1), SpellReason.fuzzy);
    }
    final split = splitMissedSpace(w, m);
    if (split != null) return pick(split, SpellReason.split);
    final device = i.device;
    if (device != null) {
      final ok = {
        for (final s in device)
          if (acceptSuggestion(w, s)) trLower(s),
      };
      return ok.length == 1
          ? pick(ok.single, SpellReason.device)
          : SpellDecision.none;
    }
    return pick(nearest(w, m), SpellReason.fuzzy);
  }

  static final _trLetter = RegExp('[çğıöşü]');

  static const _turkish = {
    'c': 'ç', 'g': 'ğ', 'i': 'ı', 'o': 'ö', 's': 'ş', 'u': 'ü', //
  };

  /// **Y-2 TÜRKÇE HARF GERİ KAZANIMI**: harfsiz yazılan [w]'nin ("calisma")
  /// Türkçe harfli bilinen karşılıkları ("çalışma"); kural tablosundaki
  /// biçim de sayılır ("hersey" → "her şey"). En çok [max] + 1 döner (fazlası
  /// belirsizlik demek). Üç harften kısa ve İngilizce görünen kelime yok.
  /// Türkçe harfi OLAN kelime harfsiz yazılmamıştır (Y-4 düzyazı ölçümü:
  /// "kısım" → "kışım", "sütun" → "sütün" yanlış çiziliyordu).
  static List<String> asciiRestore(String w, SpellMemory m, {int max = 3}) {
    if (w.length < 3 || looksEnglish(w) || _trLetter.hasMatch(w)) {
      return const [];
    }
    final pos = [
      for (var k = 0; k < w.length; k++)
        if (_turkish.containsKey(w[k])) k,
    ];
    // ponytail: 2^n deneme; 8 harften fazlası tavan (kelime sonu < 1 ms).
    if (pos.isEmpty || pos.length > 8) return const [];
    final out = <String>[];
    final chars = w.split('');
    for (var mask = 1; mask < (1 << pos.length); mask++) {
      final v = [...chars];
      for (var b = 0; b < pos.length; b++) {
        if ((mask & (1 << b)) != 0) v[pos[b]] = _turkish[v[pos[b]]]!;
      }
      final cand = v.join();
      final rule = fixTurkishWord(cand);
      if (rule != cand) {
        if (rule.split(' ').every(m.known)) out.add(rule);
      } else if (m.known(cand)) {
        out.add(cand);
      }
      if (out.length > max) break;
    }
    return out;
  }

  static final _yo = RegExp(r'^(.+[ıiuü])yo(m|sun|z|sunuz|lar)$');
  static const _yoTail = {
    'm': 'rum', 'sun': 'rsun', 'z': 'ruz', 'sunuz': 'rsunuz', 'lar': 'rlar', //
  };
  static final _future = RegExp(r'^(.+?)[ıiuü]?c(am|em|az|ez|ak|ek|an|en)$');
  static final _negFuture = RegExp(r'm[ıiuü]y([ae])');
  static final _question = RegExp(r'^(.{2,})m([ıiuü])$');

  /// **Y-3 GENEL KALIPLAR** — yalnız SONUÇ bilinen kelimeyse (yazılan zaten
  /// bilinmiyor): ağız "-yom/-yosun/-yoz" ("geliyom" → "geliyorum"),
  /// gelecek zaman ağzı ("yapıcam" → "yapacağım"), "-mIyAcAk" ("gelmiyecek"
  /// → "gelmeyecek"), bitişik soru eki ("geldinmi" → "geldin mi").
  static String? patternFix(String w, SpellMemory m) {
    String? ok(String c) => c != w && c.split(' ').every(m.known) ? c : null;
    final yo = _yo.firstMatch(w);
    if (yo != null) {
      final r = ok('${yo[1]}yo${_yoTail[yo[2]]}');
      if (r != null) return r;
    }
    final f = _future.firstMatch(w);
    if (f != null) {
      final stem = f[1]!;
      final back = RegExp('[aıou][^aeıioöuü]*\$').hasMatch(stem);
      final r = ok(
        stem +
            switch (f[2]) {
              'am' || 'em' => back ? 'acağım' : 'eceğim',
              'az' || 'ez' => back ? 'acağız' : 'eceğiz',
              'an' || 'en' => back ? 'acaksın' : 'eceksin',
              _ => back ? 'acak' : 'ecek',
            },
      );
      if (r != null) return r;
    }
    if (_negFuture.hasMatch(w)) {
      final r = ok(w.replaceFirstMapped(_negFuture, (x) => 'm${x[1]}y${x[1]}'));
      if (r != null) return r;
    }
    final q = _question.firstMatch(w);
    if (q != null) {
      final head = q[1]!;
      final lv = RegExp('[aeıioöuü]').allMatches(head).lastOrNull?[0];
      final want = switch (lv) {
        'a' || 'ı' => 'ı',
        'o' || 'u' => 'u',
        'ö' || 'ü' => 'ü',
        _ => 'i',
      };
      if (lv != null && q[2] == want) return ok('$head m$want');
    }
    return null;
  }

  /// Önerinin büyük/küçük harfi yazılan kelimeye uyar.
  static String matchCase(String typed, String s) {
    if (typed.isEmpty || s.isEmpty) return s;
    final cap = typed[0] != typed[0].toLowerCase();
    return cap ? trUpper(s[0]) + s.substring(1) : s;
  }

  /// "eksiknyapılıyor" → "eksik yapılıyor": araya düşen boşluk komşusu
  /// harfin iki yanı da bilinen kelimeyse.
  static String? splitMissedSpace(String w, SpellMemory m) {
    String? best;
    var bestScore = 0;
    for (var i = 2; i < w.length - 2; i++) {
      final c = w[i];
      if (!nearSpace.contains(c)) continue;
      final left = w.substring(0, i);
      final right = w.substring(i + 1);
      final fl = m.frequency(left);
      final fr = m.frequency(right);
      if (fl < 3 || fr < 3) continue;
      final score = math.min(fl, fr) + (c == 'n' ? 1 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = '$left $right';
      }
    }
    return best;
  }

  /// Sözlükteki TEK yakın kelime (eşik [limitFor]); ikinci aday
  /// [confidenceMargin] içindeyse null.
  static String? nearest(String w, SpellMemory m) {
    final c = _near(w, m);
    if (c.isEmpty) return null;
    if (c.length > 1 && c[1].$2 - c[0].$2 < confidenceMargin) return null;
    return changesTooMuch(w, c[0].$1) ? null : c[0].$1;
  }

  /// Altı çizili denetimin önerileri: eşik içindeki en yakın [k] aday
  /// (güven payı aranmaz — kullanıcı seçer).
  static List<String> nearestList(String w, SpellMemory m, {int k = 3}) => [
    for (final c in _near(w, m).take(k))
      if (!changesTooMuch(w, c.$1)) c.$1,
  ];

  /// Eşik içindeki adaylar, yakından uzağa.
  static List<(String, double)> _near(String w, SpellMemory m) {
    final limit = limitFor(w.length);
    if (limit <= 0) return const [];
    final out = <(String, double)>[];
    final first = w[0];
    for (var len = w.length - 2; len <= w.length + 2; len++) {
      for (final cand in m.bucket(len)) {
        if (cand == w) continue;
        // TÜRKÇE EKLER: aday yazılanın kökü ya da uzantısıysa ("kalemi" ↔
        // "kalem") ikisi de büyük olasılıkla gerçek kelime.
        if (cand.startsWith(w) || w.startsWith(cand)) continue;
        if (cand[0] != first && keyCost(first, cand[0]) > 0.5) continue;
        if (m.frequency(cand) < 3) continue;
        final cost = distance(w, cand, limit: limit);
        if (cost > limit) continue;
        out.add((cand, cost));
      }
    }
    return out..sort((a, b) => a.$2.compareTo(b.$2));
  }

  /// **Y-4 ALTI ÇİZİLİ DENETİM** önerileri ([w] küçük harf). null = sorun
  /// yok. [hint]: bağlama bağlı ("bende" → "ben de") — yanlış olmayabilir,
  /// yumuşak çizilir. Otomatik düzeltmeden farkı: güven payı aranmaz,
  /// birden çok aday listelenir; hiçbiri UYGULANMAZ.
  static ({List<String> list, bool hint})? suggestions(
    String w,
    SpellMemory m, {
    Set<String> noteKeep = const {},
  }) {
    if (w.length < 2 ||
        isCjk(w) ||
        noteKeep.contains(w) ||
        m.keep.contains(w)) {
      return null;
    }
    final out = <String>[];
    void add(String? s) {
      if (s == null || s == w || out.contains(s) || m.isRejected(w, s)) return;
      out.add(s);
    }

    add(m.learned(w));
    final rule = fixTurkishWord(w);
    if (rule != w) add(rule);
    if (out.isNotEmpty) return (list: out, hint: false);
    final ctx = contextualFix(w);
    if (ctx != null && !m.isRejected(w, ctx)) return (list: [ctx], hint: true);
    if (m.known(w)) return null;
    asciiRestore(w, m).forEach(add);
    add(patternFix(w, m));
    final n = w.length;
    if (n >= 4 && w[n - 1] == w[n - 2] && m.known(w.substring(0, n - 1))) {
      add(w.substring(0, n - 1));
    }
    add(splitMissedSpace(w, m));
    nearestList(w, m).forEach(add);
    return out.isEmpty ? null : (list: out.take(4).toList(), hint: false);
  }

  static final _chunk = RegExp(r'\S+');

  /// Harf ve sarma çapası/yapıştırıcısı (editör metni; bkz. text_wrap.dart
  /// `kWrapAnchorChar`, `kWrapGlueChar`) dışında karakter yok.
  static final _plainWord = RegExp('^[\\p{L}￼⁠]+\$', unicode: true);
  static final _anchors = RegExp('[￼⁠]');

  /// **Y-4 DENETİM BİRİMLERİ**: [para] (tek paragraf, ekrandaki metin —
  /// sarma çapası ve biçim işareti içerebilir) içinde denetlenecek
  /// kelimeler; [word] küçük harf, çapasız, aralık [para] içinde.
  ///
  /// Atlanan: bağlantı, e-posta, sayılı/tireli/kesmeli yazım, #etiket,
  /// kısaltma (TAMAMI BÜYÜK) ve cümle ortasında büyük harfle başlayan
  /// kelime (özel ad: "dün Ahmet geldi").
  static List<({int start, int end, String word})> tokens(String para) {
    final out = <({int start, int end, String word})>[];
    for (final m in _chunk.allMatches(para)) {
      final s = m[0]!;
      var a = 0;
      var b = s.length;
      while (a < b && !_isLetter(s[a])) {
        a++;
      }
      while (b > a && !_isLetter(s[b - 1])) {
        b--;
      }
      if (b - a < 2) continue;
      final core = s.substring(a, b);
      if (!_plainWord.hasMatch(core)) continue;
      if (a > 0 && _glued(s[a - 1], '#@/\\.-')) continue;
      if (b < s.length && _glued(s[b], '@/\\')) continue;
      final word = core.replaceAll(_anchors, '');
      final lower = trLower(word);
      if (lower.length < 2) continue;
      if (word != lower &&
          (trUpper(word) == word || _midSentence(para, m.start + a))) {
        continue;
      }
      out.add((start: m.start + a, end: m.start + b, word: lower));
    }
    return out;
  }

  static bool _glued(String ch, String set) => set.contains(ch) || _isDigit(ch);

  static bool _isDigit(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39;
  }

  /// [i]'den önceki son harf/rakam/cümle sonu işareti cümle sonu DEĞİLSE
  /// (biçim işaretleri, tırnak ve boşluk atlanır).
  static bool _midSentence(String para, int i) {
    for (var j = i - 1; j >= 0; j--) {
      final ch = para[j];
      if ('.!?…'.contains(ch)) return false;
      if (_isLetter(ch) || _isDigit(ch)) return true;
    }
    return false;
  }

  /// Cihaz önerisi otomatik uygulanacak kadar yakın mı (klavye mesafesi).
  static bool acceptSuggestion(String word, String s) {
    final a = trLower(word);
    final b = trLower(s);
    if (a == b || b.isEmpty) return false;
    if (a[0] != b[0] && keyCost(a[0], b[0]) > 0.5) return false;
    if (changesTooMuch(a, b)) return false;
    final limit = limitFor(a.length) + 0.4;
    return distance(a, b, limit: limit) <= limit;
  }

  /// Kullanıcının elle yaptığı [from] → [to] değişimi öğrenilebilir mi:
  /// tamamlama değil, yakın ve [from] bilinen bir kelime değil (TÜRKÇE EK
  /// TUZAĞI: "kalemi" → "kalemde" dilbilgisi seçimi, yazım hatası değil).
  static bool learnable(String from, String to, SpellMemory m) {
    if (from.length < 3 || to.length < 2) return false;
    if (!from.split('').every(_isLetter)) return false;
    if (to.contains('\n') || to.split(' ').length > 2) return false;
    final lf = trLower(from);
    final lt = trLower(to);
    if (lf == lt || lt.startsWith(lf)) return false;
    if (m.known(lf)) return false;
    final limit = limitFor(lf.length) + 1.2;
    return distance(lf, lt.replaceAll(' ', ''), limit: limit) <= limit ||
        distance(lf, lt, limit: limit) <= limit;
  }

  /// Tek adımda bir kelimenin YERİNE başka kelime geldiyse (klavye öneri
  /// çubuğu, kelimeye dokunup değiştirme) öğrenilecek çift; tamamlama ve
  /// ilgisiz değişim null.
  static ({String from, String to})? replacedWord(
    String prev,
    String text,
    SpellMemory m,
  ) {
    if (prev == text || (prev.length - text.length).abs() > 12) return null;
    var p = 0;
    final minLen = math.min(prev.length, text.length);
    while (p < minLen && prev[p] == text[p]) {
      p++;
    }
    var sfx = 0;
    while (sfx < minLen - p &&
        prev[prev.length - 1 - sfx] == text[text.length - 1 - sfx]) {
      sfx++;
    }
    final removedEnd = prev.length - sfx;
    final insertedEnd = text.length - sfx;
    if (removedEnd <= p || insertedEnd <= p) return null;
    var start = p;
    while (start > 0 && _isLetter(prev[start - 1])) {
      start--;
    }
    var endOld = removedEnd;
    while (endOld < prev.length && _isLetter(prev[endOld])) {
      endOld++;
    }
    var endNew = insertedEnd;
    while (endNew < text.length && _isLetter(text[endNew])) {
      endNew++;
    }
    final from = prev.substring(start, endOld);
    final to = text.substring(start, endNew).trimRight();
    return learnable(from, to, m) ? (from: from, to: to) : null;
  }

  /// **TANINMAZ DÜZELTME KAPISI**: otomatik (bulanık / cihaz) düzeltme
  /// harflerin üçte birinden fazlasını değiştiremez.
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

  /// Uzunluğa göre izin verilen en büyük mesafe.
  static double limitFor(int length) => length <= 3
      ? 0
      : length <= 5
      ? 0.8
      : length <= 8
      ? 1.35
      : 2.1;

  /// Yazılan → kastedilen, klavye ağırlıklı Damerau–Levenshtein. [limit]
  /// aşılınca erken kesilir (dönen değer > limit).
  static double distance(String typed, String meant, {double limit = 99}) {
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
        var v = math.min(prev[j] + ins(i - 1), cur[j - 1] + 0.9);
        v = math.min(v, prev[j - 1] + (ca == cb ? 0 : keyCost(ca, cb)));
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
}

final _letter = RegExp(r'\p{L}', unicode: true);
bool _isLetter(String ch) => _letter.hasMatch(ch);
