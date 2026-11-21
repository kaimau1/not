/// **HIZLI GİRİŞ AYRIŞTIRICISI** (kullanıcı isteği 2026-11-15: "yan yana
/// yazar, yazım bozuk da olabilir: muz elma,armut çilekkivi un yunurta…
/// bunlar o yazarken aşağıda canlı listeye eklenir"; "AI kullanmadan kendi
/// algoritmamızla").
///
/// Saf Dart, ağ/model yok. Dağınık yazılmış ya da söylenmiş metni MADDELERE
/// çevirir:
///
/// * virgül / noktalı virgül / satır sonu KESİN ayırıcıdır; boşluk YUMUŞAK;
/// * sözlükte ([QuickLexicon]) bulunan kelime ya da öbek ("diş macunu")
///   kendi maddesidir — yazımı sözlükteki hâline çevrilir ("sut" → "Süt");
/// * yapışık yazım sözlükten bölünür ("çilekkivi" → Çilek + Kivi);
/// * bir-iki harf hatası en yakın sözlük kelimesine oturur ("yunurta" →
///   Yumurta); kullanıcının kendi kelimesi ([QuickParser.isUserWord]) ya da
///   reddettiği düzeltme ([QuickParser.isRejected]) ellenmez;
/// * sözlükte OLMAYAN ardışık kelimeler kesin ayırıcıya ya da bilinen bir
///   kelimeye kadar TEK madde sayılır ("fıstık ezmesi");
/// * miktar maddeye yapışır: "2 süt", "3 kg domates", "domates 3 kg",
///   "iki ekmek" → "Süt (2)", "Domates (3 kg)".
///
/// CANLI KİP ([QuickParser.parse] `flush: false`): yalnız TAMAMLANMIŞ kısım
/// maddeye döner, gerisi [QuickParse.rest] olarak alanda kalır (yazılmakta
/// olan kelime, kapanmamış bilinmeyen öbek, devamı gelebilecek öbek başı).
library;

import '../../../core/utils/spell_learn.dart' show trLower;

/// Karşılaştırma anahtarı: Türkçe küçük harf, tek boşluk.
String quickFold(String s) => trLower(s).trim().replaceAll(RegExp(r'\s+'), ' ');

const _asciiMap = {
  'ç': 'c',
  'ğ': 'g',
  'ı': 'i',
  'ö': 'o',
  'ş': 's',
  'ü': 'u',
  'â': 'a',
  'î': 'i',
  'û': 'u',
  'é': 'e',
};

/// Türkçe harfleri düzleştirilmiş anahtar ("sut" = "süt"): Türkçe klavyesiz
/// yazan da sözlüğe oturur.
String quickAscii(String s) {
  final f = quickFold(s);
  final b = StringBuffer();
  for (final ch in f.split('')) {
    b.write(_asciiMap[ch] ?? ch);
  }
  return b.toString();
}

/// İlk harfi büyütür (Türkçe i → İ).
String quickCapitalize(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  final first = t[0];
  final up = first == 'i'
      ? 'İ'
      : first == 'ı'
      ? 'I'
      : first.toUpperCase();
  return '$up${t.substring(1)}';
}

/// "Domates (3 kg)" → "Domates".
String quickBaseName(String text) {
  final m = RegExp(r'^(.*?)\s*\(([^()]*)\)\s*$').firstMatch(text.trim());
  return m == null ? text.trim() : m.group(1)!.trim();
}

/// Aynı madde mi (miktar ve yazım farkı sayılmaz).
String quickItemKey(String text) => quickAscii(quickBaseName(text));

/// Maddenin görünen hâli.
String quickCompose(String name, String qty) =>
    qty.isEmpty ? name : '$name ($qty)';

/// "Domates (3 kg)" → "3 kg"; miktar yoksa "".
String quickQtyOf(String text) {
  final m = RegExp(r'^(.*?)\s*\(([^()]*)\)\s*$').firstMatch(text.trim());
  return m == null ? '' : m.group(2)!.trim();
}

/// AL-2 miktar toplama: "2" + "1" → "3", "1 kg" + "2 kg" → "3 kg",
/// "500 g" + "250 g" → "750 g". Birimler uyuşmazsa yeni [addedQty] döner.
String combineQuickQuantities(String existingQty, String addedQty) {
  final a = _parseQtyParts(existingQty);
  final b = _parseQtyParts(addedQty);
  if (a == null || b == null) return addedQty;
  if (a.unit != b.unit) return addedQty;
  final sum = a.value + b.value;
  final numStr = sum == sum.roundToDouble()
      ? '${sum.round()}'
      : sum.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return a.unit.isEmpty ? numStr : '$numStr ${a.rawUnit}';
}

({double value, String unit, String rawUnit})? _parseQtyParts(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(.*)$').firstMatch(t);
  if (m == null) return null;
  final v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
  if (v == null) return null;
  final rawUnit = m.group(2)!.trim();
  return (value: v, unit: quickAscii(rawUnit), rawUnit: rawUnit);
}

class QuickLexEntry {
  const QuickLexEntry(this.text, this.group, this.weight);

  /// Listeye yazılacak hâli ("Diş macunu").
  final String text;

  /// Reyon/konu sırası; -1 = bilinmiyor.
  final int group;

  /// Kullanıcının kaç kez eklediği (yakın eşleşmede öncelik).
  final int weight;
}

/// Maddelerin sözlüğü: hazır sözlük + şablon önerileri + kullanıcının
/// daha önce ekledikleri.
class QuickLexicon {
  final Map<String, QuickLexEntry> _exact = {};
  final Map<String, QuickLexEntry> _ascii = {};
  final Set<String> _heads = {};
  final Map<int, List<String>> _wordsByLen = {};

  /// En uzun öbeğin kelime sayısı.
  int maxWords = 1;

  int get length => _ascii.length;

  bool get isEmpty => _ascii.isEmpty;

  /// Sonradan eklenen aynı madde ağırlığı artırır; reyon bilgisi varsa korunur.
  void add(String text, {int group = -1, int weight = 0}) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final fold = quickFold(clean);
    final ascii = quickAscii(clean);
    final old = _ascii[ascii];
    final entry = old == null
        ? QuickLexEntry(clean, group, weight)
        : QuickLexEntry(
            old.text,
            old.group >= 0 ? old.group : group,
            old.weight + weight,
          );
    _exact[old == null ? fold : quickFold(old.text)] = entry;
    _ascii[ascii] = entry;
    if (old != null) return;
    final words = ascii.split(' ');
    if (words.length > maxWords) maxWords = words.length;
    if (words.length == 1) {
      (_wordsByLen[ascii.length] ??= []).add(ascii);
    } else {
      for (var i = 1; i < words.length; i++) {
        _heads.add(words.sublist(0, i).join(' '));
      }
    }
  }

  void addAll(Iterable<String> items, {int group = -1}) {
    for (final i in items) {
      add(i, group: group);
    }
  }

  /// Birebir eşleşme (önce Türkçe harfleriyle, sonra düzleştirilmiş).
  QuickLexEntry? exact(String phrase) =>
      _exact[quickFold(phrase)] ?? _ascii[quickAscii(phrase)];

  /// [phrase] daha uzun bir öbeğin başı mı ("tavuk" → "tavuk göğsü").
  bool isHead(String phrase) => _heads.contains(quickAscii(phrase));

  /// Maddenin reyonu; bilinmiyorsa -1.
  int groupOf(String itemText) => exact(quickBaseName(itemText))?.group ?? -1;

  /// Yapışık yazım: bütün parçaları sözlükte olan EN AZ parçalı bölünme
  /// (en çok üç parça; her parça en az iki harf).
  List<QuickLexEntry>? splitGlued(String word) {
    final w = quickAscii(word);
    if (w.length < 5 || w.contains(' ')) return null;
    for (var i = 2; i <= w.length - 2; i++) {
      final a = _ascii[w.substring(0, i)];
      final b = _ascii[w.substring(i)];
      if (a != null && b != null) return [a, b];
    }
    if (w.length < 7) return null;
    for (var i = 2; i <= w.length - 4; i++) {
      final a = _ascii[w.substring(0, i)];
      if (a == null) continue;
      for (var j = i + 2; j <= w.length - 2; j++) {
        final b = _ascii[w.substring(i, j)];
        final c = _ascii[w.substring(j)];
        if (b != null && c != null) return [a, b, c];
      }
    }
    return null;
  }

  /// En yakın TEK kelimelik madde. Kısa kelimede (≤3) arama yok; 4–6 harfte
  /// bir, 7+ harfte iki hataya kadar (iki hatada ilk harf tutmalı). Eşit
  /// uzaklıkta kullanıcının daha çok eklediği, sonra ilk harfi tutan kazanır;
  /// yine eşitse karar verilmez (yanlış düzeltmektense olduğu gibi bırak).
  QuickLexEntry? nearest(String word) {
    final w = quickAscii(word);
    if (w.length < 4 || w.contains(' ')) return null;
    final limit = w.length >= 7 ? 2 : 1;
    String? best;
    var bestCost = limit + 1;
    var tie = false;
    for (var len = w.length - limit; len <= w.length + limit; len++) {
      for (final cand in _wordsByLen[len] ?? const <String>[]) {
        final cost = _editDistance(w, cand, limit);
        if (cost > limit) continue;
        if (cost == 2 && cand[0] != w[0]) continue;
        if (cost < bestCost) {
          best = cand;
          bestCost = cost;
          tie = false;
        } else if (cost == bestCost && best != null) {
          final a = _ascii[best]!;
          final b = _ascii[cand]!;
          final aFirst = best[0] == w[0];
          final bFirst = cand[0] == w[0];
          if (b.weight > a.weight ||
              (b.weight == a.weight && bFirst && !aFirst)) {
            best = cand;
            tie = false;
          } else if (b.weight == a.weight && bFirst == aFirst) {
            tie = true;
          }
        }
      }
    }
    if (best == null || tie) return null;
    return _ascii[best];
  }
}

/// Damerau–Levenshtein (komşu harf yer değişimi tek hata); [limit] aşılınca
/// erken döner.
int _editDistance(String a, String b, int limit) {
  if ((a.length - b.length).abs() > limit) return limit + 1;
  var prev2 = List<int>.filled(b.length + 1, 0);
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    var rowMin = cur[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = prev[j] + 1;
      if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
      if (prev[j - 1] + cost < v) v = prev[j - 1] + cost;
      if (i > 1 &&
          j > 1 &&
          a[i - 1] == b[j - 2] &&
          a[i - 2] == b[j - 1] &&
          prev2[j - 2] + 1 < v) {
        v = prev2[j - 2] + 1;
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

/// Maddenin nasıl bulunduğu.
enum QuickHow {
  /// Sözlükte birebir (ya da Türkçe harfsiz yazımı).
  exact,

  /// Yakın eşleşme: yazım düzeltildi ("yunurta" → Yumurta).
  fuzzy,

  /// Yapışık yazımdan bölündü.
  split,

  /// Kullanıcının öğrettiği düzeltme (yazım hafızası).
  learned,

  /// Sözlükte yok: yazıldığı gibi.
  typed,
}

class QuickItem {
  const QuickItem({
    required this.name,
    this.qty = '',
    this.group = -1,
    this.how = QuickHow.typed,
    this.typed = '',
  });

  /// Miktarsız ad ("Domates").
  final String name;

  /// Miktar ("3 kg"); yoksa ''.
  final String qty;

  /// Reyon/konu sırası; -1 = bilinmiyor.
  final int group;

  final QuickHow how;

  /// Kullanıcının yazdığı ham hâl (düzeltme geri alınabilsin diye).
  final String typed;

  /// Listeye yazılacak metin.
  String get text => quickCompose(name, qty);

  bool get corrected => how == QuickHow.fuzzy;

  QuickItem withQty(String q) =>
      QuickItem(name: name, qty: q, group: group, how: how, typed: typed);

  @override
  String toString() => text;
}

class QuickParse {
  const QuickParse(this.items, this.rest, this.trailingQty);

  final List<QuickItem> items;

  /// Henüz maddeye dönmeyen kuyruk (canlı kipte alanda kalır).
  final String rest;

  /// Maddesi olmayan, sonda kalan miktar ("3 kg" + Enter): çağıran en son
  /// eklenen maddeye yapıştırır. Yoksa ''.
  final String trailingQty;
}

const _stopWords = {
  've',
  'bir',
  'ile',
  'de',
  'da',
  'bide',
  'sonra',
  'ayrıca',
  'ayrica',
  'lütfen',
  'lutfen',
  'and',
  'also',
  'please',
  'some',
};

const _numberWords = {
  'bir': '1',
  'iki': '2',
  'üç': '3',
  'uc': '3',
  'dört': '4',
  'dort': '4',
  'beş': '5',
  'bes': '5',
  'altı': '6',
  'alti': '6',
  'yedi': '7',
  'sekiz': '8',
  'dokuz': '9',
  'on': '10',
  'yarım': '½',
  'yarim': '½',
  'çeyrek': '¼',
  'ceyrek': '¼',
  'one': '1',
  'two': '2',
  'three': '3',
  'four': '4',
  'five': '5',
  'six': '6',
  'seven': '7',
  'eight': '8',
  'nine': '9',
  'ten': '10',
  'half': '½',
};

/// Birim → yazılacak hâli.
const _units = {
  'kg': 'kg',
  'kilo': 'kg',
  'kilogram': 'kg',
  'g': 'g',
  'gr': 'g',
  'gram': 'g',
  'lt': 'lt',
  'l': 'lt',
  'litre': 'lt',
  'liter': 'lt',
  'ml': 'ml',
  'cl': 'cl',
  'adet': 'adet',
  'tane': 'tane',
  'paket': 'paket',
  'kutu': 'kutu',
  'şişe': 'şişe',
  'sise': 'şişe',
  'demet': 'demet',
  'düzine': 'düzine',
  'duzine': 'düzine',
  'koli': 'koli',
  'poşet': 'poşet',
  'poset': 'poşet',
  'kavanoz': 'kavanoz',
  'dilim': 'dilim',
  'bardak': 'bardak',
  'torba': 'torba',
  'metre': 'm',
  'm': 'm',
  'cm': 'cm',
  'rulo': 'rulo',
  'tüp': 'tüp',
  'tup': 'tüp',
  'salkım': 'salkım',
  'salkim': 'salkım',
  'pcs': 'pcs',
  'pack': 'pack',
  'packs': 'pack',
  'lb': 'lb',
  'lbs': 'lb',
  'oz': 'oz',
  'bottle': 'bottle',
  'bottles': 'bottle',
  'box': 'box',
  'boxes': 'box',
  'can': 'can',
  'cans': 'can',
  'bag': 'bag',
  'bags': 'bag',
  'bunch': 'bunch',
  'dozen': 'dozen',
};

/// Sözlükte olmasa da SONRAKİ maddeye yapışan niteleyiciler ("kırmızı elma",
/// "tam yağlı süt").
const _modifiers = {
  'kırmızı',
  'yeşil',
  'sarı',
  'beyaz',
  'siyah',
  'mor',
  'büyük',
  'küçük',
  'orta',
  'boy',
  'taze',
  'kuru',
  'organik',
  'light',
  'sade',
  'tam',
  'yarım',
  'yağlı',
  'yağsız',
  'tuzlu',
  'tuzsuz',
  'şekerli',
  'şekersiz',
  'acı',
  'tatlı',
  'ekşi',
  'dondurulmuş',
  'donuk',
  'haşlanmış',
  'közlenmiş',
  'çekirdeksiz',
  'laktozsuz',
  'glutensiz',
  'kepekli',
  'köy',
  'ev',
  'yerli',
  'ithal',
  'mini',
  'ekstra',
  'red',
  'green',
  'white',
  'black',
  'fresh',
  'frozen',
  'dried',
  'organic',
  'large',
  'small',
  'whole',
  'lowfat',
  'unsalted',
  'salted',
  'big',
};

final _numberRe = RegExp(r'^\d+(?:[.,/]\d+)?$');
final _numberUnitRe = RegExp(r'^(\d+(?:[.,/]\d+)?)([a-zçğıöşü]+)$');

class _Tok {
  _Tok(this.word, this.start, this.complete, this.hardAfter);

  final String word;
  final int start;

  /// Kelimeden sonra bir ayırıcı yazıldı (kelime bitti).
  bool complete;

  /// Kelimeden sonra KESİN ayırıcı var (öbek burada kapanır).
  bool hardAfter;
}

bool _isHard(String ch) =>
    ch == ',' || ch == ';' || ch == '\n' || ch == '•' || ch == '·' || ch == '|';

bool _isSoft(String ch) => ch == ' ' || ch == '\t' || ch == '\r';

List<_Tok> _tokenize(String text) {
  final out = <_Tok>[];
  final b = StringBuffer();
  var start = 0;
  void close({required bool hard}) {
    if (b.isEmpty) {
      if (hard && out.isNotEmpty) out.last.hardAfter = true;
      return;
    }
    out.add(_Tok(b.toString(), start, true, hard));
    b.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    // "1,5" ondalık: iki rakam arasındaki virgül ayırıcı değil.
    final decimalComma =
        ch == ',' &&
        i > 0 &&
        i + 1 < text.length &&
        _isDigit(text[i - 1]) &&
        _isDigit(text[i + 1]) &&
        // "süt 2,3 ekmek" gibi tek haneli sayım listelerini bozmamak için
        // yalnız kelime rakamla BAŞLIYORSA ondalık say.
        b.isNotEmpty &&
        _isDigit(b.toString()[0]);
    if (_isHard(ch) && !decimalComma) {
      close(hard: true);
    } else if (_isSoft(ch)) {
      close(hard: false);
    } else {
      if (b.isEmpty) start = i;
      b.write(ch);
    }
  }
  if (b.isNotEmpty) out.add(_Tok(b.toString(), start, false, false));
  return out;
}

bool _isDigit(String ch) {
  final c = ch.codeUnitAt(0);
  return c >= 48 && c <= 57;
}

/// Baştaki/sondaki noktalama ("süt." → "süt").
String _clean(String w) =>
    w.replaceAll(RegExp(r'''^[.:!?"'()\[\]-]+|[.:!?"'()\[\]]+$'''), '');

/// Ayrıştırıcı: sözlük + kişisel yazım hafızası bağları.
class QuickParser {
  QuickParser(
    this.lexicon, {
    this.learnedFix,
    this.isUserWord,
    this.isRejected,
    this.phrasesOnly = false,
  });

  final QuickLexicon lexicon;

  /// Kullanıcının öğrettiği düzeltme (`SpellMemory.learned`).
  final String? Function(String word)? learnedFix;

  /// Kullanıcının kendi kelimesi: yakın eşleşmeyle DÜZELTİLMEZ
  /// (`SpellMemory.known`).
  final bool Function(String word)? isUserWord;

  /// Bu düzeltme daha önce geri alındı mı.
  final bool Function(String typed, String corrected)? isRejected;

  /// true: yalnız KESİN ayırıcılar böler, kelimeler ayrı maddeye dönmez
  /// (yapılacaklar listesi gibi cümleli notlar).
  final bool phrasesOnly;

  /// [flush]: metin bitti (Enter, Bitti, konuşma sonu) — kalan her şey
  /// maddeye döner. [idle]: kullanıcı yazmayı bıraktı — devamı beklenen öbek
  /// başı ("süt" → "süt tozu" olabilirdi) artık beklenmez; bilinmeyen öbek ve
  /// yarım kelime yine bekler.
  QuickParse parse(String text, {bool flush = false, bool idle = false}) {
    if (phrasesOnly) return _parsePhrases(text, flush: flush);
    final toks = _tokenize(text);
    if (toks.isEmpty) return const QuickParse([], '', '');
    if (flush) {
      toks.last
        ..complete = true
        ..hardAfter = true;
    }
    final items = <QuickItem>[];
    // Açık (henüz maddeye dönmemiş) şeyler: bilinmeyen öbek ve miktar.
    final run = <_Tok>[];
    var qty = '';
    int? qtyStart;
    // Bu KESİN öbekte çıkan son maddenin sırası (sondaki miktar ona gider).
    int? lastInSegment;
    var trailingQty = '';
    int? restStart;

    String takeQty() {
      final q = qty;
      qty = '';
      qtyStart = null;
      return q;
    }

    void emit(QuickItem item) {
      items.add(item);
      lastInSegment = items.length - 1;
    }

    void flushRun() {
      if (run.isEmpty) return;
      final name = quickCapitalize(
        run.map((t) => _clean(t.word)).where((w) => w.isNotEmpty).join(' '),
      );
      run.clear();
      if (name.isEmpty) return;
      emit(QuickItem(name: name, qty: takeQty(), typed: name));
    }

    void closeSegment() {
      flushRun();
      if (qty.isNotEmpty) {
        final q = takeQty();
        final last = lastInSegment;
        if (last != null && items[last].qty.isEmpty) {
          items[last] = items[last].withQty(q);
        } else {
          trailingQty = q;
        }
      }
      lastInSegment = null;
    }

    int pendingStart(int fallback) {
      var s = fallback;
      if (run.isNotEmpty && run.first.start < s) s = run.first.start;
      final q = qtyStart;
      if (q != null && q < s) s = q;
      return s;
    }

    var i = 0;
    while (i < toks.length) {
      final tok = toks[i];
      if (!tok.complete) {
        restStart = pendingStart(tok.start);
        break;
      }
      final word = _clean(tok.word);
      final fold = quickFold(word);
      // Öbek içinde kullanılabilecek ardışık tamamlanmış kelimeler.
      var avail = 1;
      while (avail < lexicon.maxWords &&
          i + avail < toks.length &&
          !toks[i + avail - 1].hardAfter &&
          toks[i + avail].complete) {
        avail++;
      }
      // Devamı henüz yazılmamış olabilir mi (öbek kapanmadı, metin burada bitti).
      final openEnd =
          !idle && !toks[i + avail - 1].hardAfter && i + avail == toks.length;
      // Devamı YAZILIYOR (yarım kelime): öbek başı olabilecek eşleşme bekler.
      final typingNext =
          !toks[i + avail - 1].hardAfter &&
          i + avail < toks.length &&
          !toks[i + avail].complete;

      if (word.isEmpty) {
        if (tok.hardAfter) closeSegment();
        i++;
        continue;
      }

      // 1) Sözlük öbeği (en uzun eşleşme).
      QuickLexEntry? hit;
      var hitLen = 0;
      for (var k = avail; k >= 1; k--) {
        final phrase = [for (var j = 0; j < k; j++) _clean(toks[i + j].word)]
            .join(' ');
        final e = lexicon.exact(phrase);
        if (e != null) {
          hit = e;
          hitLen = k;
          break;
        }
      }
      // Daha uzun bir öbeğin başı olabilir: devamını bekle.
      final headPhrase = [
        for (var j = 0; j < avail; j++) _clean(toks[i + j].word),
      ].join(' ');
      if ((openEnd || typingNext) &&
          (hit == null || hitLen == avail) &&
          lexicon.isHead(headPhrase)) {
        restStart = pendingStart(tok.start);
        break;
      }

      // 2) Miktar: sayı, sayı+birim ya da sayı kelimesi.
      if (hit == null) {
        String? number;
        String? unit;
        var used = 1;
        final glued = _numberUnitRe.firstMatch(fold);
        if (_numberRe.hasMatch(fold)) {
          number = fold;
        } else if (glued != null && _units.containsKey(glued.group(2))) {
          number = glued.group(1);
          unit = _units[glued.group(2)];
        } else if (_numberWords.containsKey(fold) && !tok.hardAfter) {
          // Sayı kelimesi yalnız ardından birim ya da madde geliyorsa sayıdır.
          if (i + 1 >= toks.length || !toks[i + 1].complete) {
            if (!flush) {
              restStart = pendingStart(tok.start);
              break;
            }
          } else {
            final next = quickFold(_clean(toks[i + 1].word));
            if (_units.containsKey(next) ||
                lexicon.exact(next) != null ||
                lexicon.isHead(next)) {
              number = _numberWords[fold];
            }
          }
        }
        if (number != null) {
          if (unit == null && !tok.hardAfter) {
            if (i + 1 < toks.length) {
              final nt = toks[i + 1];
              final next = quickFold(_clean(nt.word));
              if (!nt.complete) {
                // Birim yazılıyor olabilir: bekle.
                restStart = pendingStart(tok.start);
                break;
              }
              if (_units.containsKey(next) && lexicon.exact(next) == null) {
                unit = _units[next];
                used = 2;
              }
            } else if (!flush) {
              restStart = pendingStart(tok.start);
              break;
            }
          }
          flushRun();
          // "bir ekmek": tek adet yazılmaz; "bir kilo" yazılır.
          final plainOne = number == '1' && unit == null;
          if (qty.isNotEmpty) {
            // Üst üste iki miktar: ilki sahipsiz kaldı, öncekine yapışır.
            final last = lastInSegment;
            if (last != null && items[last].qty.isEmpty) {
              items[last] = items[last].withQty(qty);
            }
          }
          qty = plainOne && _numberWords.containsKey(fold)
              ? ''
              : (unit == null ? number : '$number $unit');
          qtyStart = qty.isEmpty ? null : tok.start;
          final end = toks[i + used - 1];
          i += used;
          if (end.hardAfter) closeSegment();
          continue;
        }
      }

      if (hit != null) {
        // Bilinmeyen öbek yalnız niteleyicilerden oluşuyorsa maddeye yapışır.
        var prefix = '';
        if (run.isNotEmpty &&
            run.every((t) => _modifiers.contains(quickFold(_clean(t.word))))) {
          prefix = run.map((t) => quickFold(_clean(t.word))).join(' ');
          run.clear();
        } else {
          flushRun();
        }
        final name = prefix.isEmpty
            ? hit.text
            : quickCapitalize('$prefix ${trLower(hit.text)}');
        emit(
          QuickItem(
            name: name,
            qty: takeQty(),
            group: hit.group,
            how: QuickHow.exact,
            typed: word,
          ),
        );
        final end = toks[i + hitLen - 1];
        i += hitLen;
        if (end.hardAfter) closeSegment();
        continue;
      }

      // 3) Tek kelime, sözlükte yok.
      if (_stopWords.contains(fold)) {
        flushRun();
        i++;
        if (tok.hardAfter) closeSegment();
        continue;
      }
      QuickItem? single;
      List<QuickLexEntry>? parts;
      final fix = learnedFix?.call(word);
      final fixed = fix == null ? null : lexicon.exact(fix);
      if (fix != null && fix.trim().isNotEmpty) {
        single = QuickItem(
          name: fixed?.text ?? quickCapitalize(fix),
          group: fixed?.group ?? -1,
          how: QuickHow.learned,
          typed: word,
        );
      } else if (_modifiers.contains(fold) ||
          (isUserWord?.call(word) ?? false)) {
        // Kullanıcının kendi kelimesi / niteleyici: düzeltme yok.
      } else {
        parts = lexicon.splitGlued(word);
        if (parts == null) {
          final near = lexicon.nearest(word);
          if (near != null && !(isRejected?.call(word, near.text) ?? false)) {
            single = QuickItem(
              name: near.text,
              group: near.group,
              how: QuickHow.fuzzy,
              typed: word,
            );
          }
        }
      }
      if (single != null || parts != null) {
        flushRun();
        if (single != null) {
          emit(single.withQty(takeQty()));
        } else {
          for (final p in parts!) {
            emit(
              QuickItem(
                name: p.text,
                qty: takeQty(),
                group: p.group,
                how: QuickHow.split,
                typed: word,
              ),
            );
          }
        }
      } else {
        run.add(tok);
      }
      i++;
      if (tok.hardAfter) closeSegment();
    }

    if (restStart == null) {
      if (flush) {
        closeSegment();
      } else if (run.isNotEmpty || qty.isNotEmpty) {
        restStart = pendingStart(text.length);
      }
    }
    final rest = restStart == null ? '' : text.substring(restStart);
    return QuickParse(items, rest, trailingQty);
  }

  QuickParse _parsePhrases(String text, {required bool flush}) {
    final items = <QuickItem>[];
    var start = 0;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == ',' || ch == ';' || ch == '\n' || ch == '•') {
        final part = text.substring(start, i).trim();
        if (part.isNotEmpty) {
          items.add(QuickItem(name: quickCapitalize(part), typed: part));
        }
        start = i + 1;
      }
    }
    final tail = text.substring(start);
    if (flush) {
      if (tail.trim().isNotEmpty) {
        items.add(
          QuickItem(name: quickCapitalize(tail.trim()), typed: tail.trim()),
        );
      }
      return QuickParse(items, '', '');
    }
    return QuickParse(items, tail.trimLeft(), '');
  }
}

/// Reyon sırasına dizer (kararlı): reyonu bilinmeyenler sonda, kendi
/// aralarında eklenme sırasıyla.
List<T> quickSortByGroup<T>(List<T> items, int Function(T) groupOf) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  int rank(T t) {
    final g = groupOf(t);
    return g < 0 ? 1 << 20 : g;
  }

  indexed.sort((a, b) {
    final c = rank(a.$2).compareTo(rank(b.$2));
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}
