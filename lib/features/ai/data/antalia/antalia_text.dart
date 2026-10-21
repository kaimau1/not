import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Antalia-2 Mini'nin TÜRKÇE METİN ÖN İŞLEMESİ: ham metni modelin okuyacağı
/// küçük harfli, rakamsız biçime çevirir ("1.250,75 TL" → "bin iki yüz elli
/// lira yetmiş beş kuruş", "Dr." → "doktor", "GitHub" → "git hab") ve harf
/// kimliklerine kodlar.
///
/// KAYNAK: `fr0stb1rd/antalia-mini-web` normalize.js (o da orijinal Python
/// `antalia_mini/text` paketinin birebir portu; PatientDesk AI, Apache-2.0).
/// Sıra ve desenler oradakiyle AYNI tutuldu — yorumlardaki `[N:..]`/`[F:..]`
/// satır işaretleri Python kaynağını gösterir. Eşitlik
/// `test/antalia_text_test.dart`'ta tarayıcı portunun kendi örnekleriyle
/// (Python çıktısı) ölçülür; bir deseni "sadeleştirmeden" önce oraya bak.
///
/// JS → Dart farkları (bilinçli):
///  - `R()` büyük/küçük harf duyarsız desenlerde i/I/ı/İ dörtlüsünü açar
///    (Python `re.IGNORECASE` bunları eşit sayar, JS/Dart saymaz).
///  - JS `split` yakalama gruplarını sonuca katar, Dart katmaz: adres
///    parçalama ([_splitKeep]) elle yazıldı.
///  - Sözlükler (yabancı kelime hecelemesi) YOKSA normalleştirici yine
///    çalışır; yalnız İngilizce kelimeler yazıldığı gibi kalır. Tarayıcı
///    portu bu durumda sayıları da okumuyordu — burada okuma asıl iş.
class AntaliaText {
  AntaliaText._();

  // ---------- yardımcılar ----------
  // Python \b'nin karşılığı (Python \w unicode kelime karakteri).
  static const _b =
      '(?:(?<![\\p{L}\\p{N}_])(?=[\\p{L}\\p{N}_])|(?<=[\\p{L}\\p{N}_])(?![\\p{L}\\p{N}_]))';
  static const _wc = '\\p{L}\\p{N}_';
  static const _w = '[$_wc]';
  static const _l = '\\p{L}';

  static String _esc(String s) =>
      s.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');

  /// JS `new RegExp(src, flags)`; `g` Dart'ta çağrıyla seçilir.
  static RegExp _re(String src, [String flags = 'u']) => RegExp(
    src,
    unicode: flags.contains('u'),
    caseSensitive: !flags.contains('i'),
  );

  /// Büyük/küçük harf duyarsız desen: i/I/ı/İ dörtlüsü açılır (bkz. sınıf
  /// açıklaması).
  static RegExp _r(String src, String flags) {
    if (!flags.contains('i')) return _re(src, flags);
    final out = StringBuffer();
    var inClass = false;
    var esc = false;
    bool isQ(String c) =>
        c == 'i' || c == 'I' || c == '\u0131' || c == '\u0130';
    for (var k = 0; k < src.length; k++) {
      final ch = src[k];
      if (esc) {
        out
          ..write('\\')
          ..write(ch);
        esc = false;
        continue;
      }
      if (ch == '\\') {
        final m = RegExp(r'^\\u013[01]').firstMatch(src.substring(k));
        if (m != null) {
          out.write(inClass ? 'iI\u0131\u0130' : '[iI\u0131\u0130]');
          k += m[0]!.length - 1;
          continue;
        }
        esc = true;
        continue;
      }
      if (ch == '[') {
        inClass = true;
        out.write(ch);
        continue;
      }
      if (ch == ']') {
        inClass = false;
        out.write(ch);
        continue;
      }
      if (isQ(ch)) {
        out.write(inClass ? 'iI\u0131\u0130' : '[iI\u0131\u0130]');
        continue;
      }
      out.write(ch);
    }
    return _re(out.toString(), flags);
  }

  /// Kod noktası listesi (JS `[...s]`).
  static List<String> _chars(String s) => [
    for (final r in s.runes) String.fromCharCode(r),
  ];

  static final _upperRe = RegExp(r'\p{Lu}', unicode: true);
  static bool _isUpperCase(String ch) => _upperRe.hasMatch(ch);

  /// Kararlı sıralama (JS `sort` kararlıdır, Dart `List.sort` değil).
  static List<String> _byLengthDesc(Iterable<String> items) {
    final list = items.toList();
    final indexed = [for (var i = 0; i < list.length; i++) (i, list[i])];
    indexed.sort((a, b) {
      final d = b.$2.length - a.$2.length;
      return d != 0 ? d : a.$1 - b.$1;
    });
    return [for (final e in indexed) e.$2];
  }

  // ---------- normalize.py tabloları ----------
  static const _ones = [
    'sıfır', 'bir', 'iki', 'üç', 'dört', 'beş', 'altı', 'yedi', 'sekiz', //
    'dokuz',
  ]; // [N:62]
  static const _tens = [
    '', 'on', 'yirmi', 'otuz', 'kırk', 'elli', 'altmış', 'yetmiş', 'seksen', //
    'doksan',
  ]; // [N:63]
  static const _months = {
    1: 'ocak', 2: 'şubat', 3: 'mart', 4: 'nisan', 5: 'mayıs', 6: 'haziran', //
    7: 'temmuz', 8: 'ağustos', 9: 'eylül', 10: 'ekim', 11: 'kasım',
    12: 'aralık',
  }; // [N:64-77]
  static const _abbreviations = {
    'dr.': 'doktor', 'prof.': 'profesör', 'vb.': 've benzeri', //
    'vs.': 'vesaire', 'örn.': 'örneğin', 'no.': 'numara', 'mg': 'miligram',
    'kg': 'kilogram', 'gr': 'gram', 'km': 'kilometre', 'cm': 'santimetre',
    'mm': 'milimetre', 'lt': 'litre', 'ml': 'mililitre', 'kb': 'kilobayt',
    'mb': 'megabayt', 'gb': 'gigabayt', 'tb': 'terabayt', 'tl': 'lira',
    'doç.': 'doçent', 'uzm.': 'uzman', 'op.': 'operatör', 'yrd.': 'yardımcı',
    'öğr. üyesi': 'öğretim üyesi', 'öğr. gör.': 'öğretim görevlisi',
    'dt.': 'diş hekimi', 'dyt.': 'diyetisyen', 'psk.': 'psikolog',
    'fzt.': 'fizyoterapist', 'hemş.': 'hemşire', 'ecz.': 'eczacı',
    'av.': 'avukat', 'müh.': 'mühendis', 'hz.': 'hazreti', 'bkz.': 'bakınız',
    'vd.': 've diğerleri', 'mah.': 'mahallesi', 'cad.': 'caddesi',
    'cd.': 'caddesi', 'sok.': 'sokak', 'sk.': 'sokak', 'bul.': 'bulvarı',
    'blv.': 'bulvarı', 'apt.': 'apartmanı', 'ltd. şti.': 'limited şirketi',
    'şti.': 'şirketi',
  }; // [N:78-127]
  static const _beforeAWord = {
    'doç.', 'uzm.', 'op.', 'yrd.', 'dt.', 'dyt.', 'psk.', 'fzt.', 'hemş.', //
    'ecz.', 'av.', 'müh.', 'hz.', 'mah.', 'cad.', 'cd.', 'sok.', 'sk.',
    'bul.', 'blv.', 'apt.',
  }; // [N:131-133]
  static const _numberUnits = {
    'm': 'metre', 'g': 'gram', 'cc': 'sisi', 'mcg': 'mikrogram', //
    'μg': 'mikrogram', 'IU': 'ünite', 'kcal': 'kilokalori',
    'mmHg': 'milimetre cıva', 'dk': 'dakika', 'sn': 'saniye', 'sa': 'saat',
    'ms': 'milisaniye', 'dl': 'desilitre',
  }; // [N:135-139]
  static const _areaUnits = {
    'm': 'metre',
    'km': 'kilometre',
    'cm': 'santimetre',
  }; // [N:140]
  static const _ordinalHeads =
      'Dünya|Lig|Ordu|Kolordu|Tümen|Dönem|Meclis|Kurultay|Kongre|Uluslararası|Ulusal|Olağan|Olağanüstü|Geleneksel|Yıl|Yüzyıl|Sınıf|Kat|Blok|Etap|Bölge|Asliye|Ağır|Sulh|İcra|Aile|Selim|Murat|Murad|Mehmet|Mehmed|Mahmut|Mahmud|Ahmet|Ahmed|Osman|Bayezid|Beyazıt|Süleyman|Mustafa|Abdülhamid|Abdülmecid|Louis|Henry|Napolyon'; // [N:144-147]
  static const _weekdays = {
    'Pzt': 'pazartesi', 'Sal': 'salı', 'Çar': 'çarşamba', //
    'Per': 'perşembe', 'Cum': 'cuma', 'Cmt': 'cumartesi', 'Paz': 'pazar',
  }; // [N:148-151]
  static const _letterNames = {
    'A': 'a', 'B': 'be', 'C': 'ce', 'Ç': 'çe', 'D': 'de', 'E': 'e', //
    'F': 'fe', 'G': 'ge', 'Ğ': 'yumuşak ge', 'H': 'he', 'I': 'ı', 'İ': 'i',
    'J': 'je', 'K': 'ke', 'L': 'le', 'M': 'me', 'N': 'ne', 'O': 'o',
    'Ö': 'ö', 'P': 'pe', 'R': 're', 'S': 'se', 'Ş': 'şe', 'T': 'te',
    'U': 'u', 'Ü': 'ü', 'V': 've', 'Y': 'ye', 'Z': 'ze', 'Q': 'kü',
    'W': 'dabılyu', 'X': 'iks',
  }; // [N:152-185]
  static final _initialismLetters = <String, String>{
    ..._letterNames,
    'K': 'ka',
    'I': 'i',
  }; // [N:191]
  static const _romanValues = {'I': 1, 'V': 5, 'X': 10}; // [N:193]
  static const _ordinalExceptions = {
    'bir': 'birinci', 'iki': 'ikinci', 'üç': 'üçüncü', 'dört': 'dördüncü', //
    'beş': 'beşinci', 'altı': 'altıncı', 'yedi': 'yedinci',
    'sekiz': 'sekizinci', 'dokuz': 'dokuzuncu', 'on': 'onuncu',
    'yirmi': 'yirminci', 'otuz': 'otuzuncu', 'kırk': 'kırkıncı',
    'elli': 'ellinci', 'altmış': 'altmışıncı', 'yetmiş': 'yetmişinci',
    'seksen': 'sekseninci', 'doksan': 'doksanıncı', 'yüz': 'yüzüncü',
    'bin': 'bininci', 'milyon': 'milyonuncu', 'milyar': 'milyarıncı',
  }; // [N:194-217]
  static const _addressWords = {
    'www': 'dabılyu dabılyu dabılyu', 'com': 'kom', 'net': 'net', //
    'org': 'org', 'gov': 'gov', 'info': 'info', 'gmail': 'cimeyl',
    'hotmail': 'hotmeyl', 'outlook': 'autluk', 'yahoo': 'yahu',
    'icloud': 'ayklaud',
  }; // [N:29-41]
  static const _perUnit = {
    'sn': 'saniye',
    'sa': 'saat',
    'dk': 'dakika',
  }; // [N:47]
  static const _capsLexicon = {
    'MR': 'emar', 'SMS': 'esemes', 'NTV': 'entivi', 'YÖK': 'yök', //
    'BİM': 'bim', 'ŞOK': 'şok', 'COVID': 'kovid', 'MEB': 'meb', 'İTÜ': 'itü',
    'IBAN': 'iban', 'İETT': 'ietete', 'ALO': 'alo', 'MİT': 'mit',
    'OK': 'okey', 'TSH': 'teseha', 'MHRS': 'meharese', 'HES': 'hes',
    'CEO': 'siio', 'PR': 'piar', 'DJ': 'dijey', 'TV': 'tivi',
    'FBI': 'efbiay', 'CNN': 'sienen', 'VIP': 'viaypi', 'HD': 'heyçdi',
  }; // [N:51-59]
  static final _vowels = _chars('aeıioöuüAEIİOÖUÜ').toSet(); // [N:46]
  static const _currencyCodes = {
    'TL': '₺',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
  }; // [N:512]
  static const _symbolsMap = {
    '&': ' ve ', '•': ' , ', '▪': ' , ', '►': ' , ', '→': ' , ', //
    '⇒': ' , ',
  }; // [N:513]
  static const _doseUnits = {
    'mg': 'miligram',
    'mcg': 'mikrogram',
    'g': 'gram',
    'ml': 'mililitre',
  }; // [N:566]
  static const _doseWords =
      'tablet|kapsül|şurup|ölçek|damla|doz|puf|kaşık|ampul|draje|saşe|fitil|iğne'; // [N:567]

  // [N:220-255] konuşulan kökler (uzundan kısaya)
  static final List<String> _spokenStems = () {
    final s = <String>{
      ..._ones,
      ..._tens.where((t) => t.isNotEmpty),
      'yüz', 'bin', 'milyon', 'milyar', 'trilyon', 'lira', 'kuruş', 'dolar', //
      'avro', 'sent', 'sterlin', 'peni', 'saniye', 'dakika', 'saat', 'buçuk',
      'metrekare', 'metreküp', 'kilometrekare', 'santimetrekare',
      'kilometreküp', 'santimetreküp',
      ..._abbreviations.values.map((v) => v.split(' ').last),
      ..._numberUnits.values.map((v) => v.split(' ').last),
      ..._ordinalExceptions.values,
    };
    return _byLengthDesc(s);
  }();
  static final _spokenStemSuffix = _re(
    "$_b(${_spokenStems.map(_esc).join('|')}|$_w+(?:inci|ıncı|üncü|uncu|nci|ncı|ncü|ncu))'([a-zçğıöşü]+)$_b",
  ); // [N:253-255]

  // ---------- foreign.py tabloları ----------
  static const _enLetters = {
    'A': 'ey', 'B': 'bi', 'C': 'si', 'D': 'di', 'E': 'i', 'F': 'ef', //
    'G': 'ci', 'H': 'eyç', 'I': 'ay', 'J': 'cey', 'K': 'key', 'L': 'el',
    'M': 'em', 'N': 'en', 'O': 'o', 'P': 'pi', 'Q': 'kyu', 'R': 'ar',
    'S': 'es', 'T': 'ti', 'U': 'yu', 'V': 'vi', 'W': 'dabılyu', 'X': 'eks',
    'Y': 'vay', 'Z': 'zi',
  }; // [F:42-46]

  /// Modelin harf tablosu (config.json `symbols`; [I:16-18]).
  static final List<String> symbols = [
    '<pad>',
    '<bos>',
    '<eos>',
    ..._chars(" .,?!'-:;"),
    ..._chars('abcçdefgğhıijklmnoöpqrsştuüvwxyz'),
    ..._chars('âîû'),
  ];
  static final Map<String, int> symbolToId = {
    for (var i = 0; i < symbols.length; i++) symbols[i]: i,
  };
  static const bos = 1;
  static const eos = 2;

  /// Gömülü sözlük: `antalia_mini/text/data/lexicon.json` ile birebir.
  static const lexicon = {
    'Adidas': 'Adidas', 'Airbnb': 'Airbnb', 'AirPods': 'AirPods', //
    'Akbank': 'Akbank', 'Amazon': 'Amazon', 'Android': 'Android',
    'Apple': 'Apple', 'Binance': 'Binance', 'Bitcoin': 'Bitcoin',
    'Bluetooth': 'Bluetooth', 'BluTV': 'Blu Ti Vi', 'Booking': 'Booking',
    'Burger King': 'Burger King', 'Canva': 'Canva',
    'ChatGPT': 'Çet Ci Pi Ti', 'check-in': 'check-in',
    'check-out': 'check-out', 'Chrome': 'Chrome', 'Coca-Cola': 'Koka Kola',
    'Copilot': 'Copilot', 'deadline': 'dedlayn', 'Discord': 'Diskord',
    "Domino's": "Domino's", 'Dropbox': 'Dropbox', 'e-Devlet': 'e-Devlet',
    'e-mail': 'e-mail', 'Excel': 'Excel', 'Facebook': 'Facebook',
    'feedback': 'fidbek', 'Figma': 'Figma', 'Firefox': 'Fayırfoks',
    'Gemini': 'Gemini', 'Getir': 'Getir', 'Gmail': 'Gmail',
    'Google': 'Google', 'Hepsiburada': 'Hepsiburada', 'Hotmail': 'Hotmail',
    'HubSpot': 'HubSpot', 'iCloud': 'Ayklaud', 'IKEA': 'IKEA',
    'Instagram': 'Instagram', 'iPad': 'iPad', 'iPhone': 'iPhone',
    'iyzico': 'iyzico', 'Jira': 'Jira', 'LinkedIn': 'LinkedIn',
    'mail': 'mail', 'Mastercard': 'Mastercard', "McDonald's": 'Mekdonalds',
    'meeting': 'miting', 'Microsoft': 'Microsoft', 'Netflix': 'Netflix',
    'Nike': 'Nike', 'offline': 'offline', 'OneDrive': 'Van Drayv',
    'online': 'online', 'OpenAI': 'Opın Ey Ay', 'Papara': 'Papara',
    'PatientDesk': 'Peyşınt Desk', 'PayPal': 'PayPal', 'Pegasus': 'Pegasus',
    'PlayStation': 'Pleysteyşın', 'PowerPoint': 'PowerPoint',
    'Safari': 'Safari', 'Salesforce': 'Salesforce', 'Samsung': 'Samsung',
    'Shopify': 'Shopify', 'Skype': 'Skayp', 'Slack': 'Slack',
    'Spotify': 'Spotifay', 'Starbucks': 'Starbucks', 'startup': 'startap',
    'Teams': 'Teams', 'Telegram': 'Telegram', 'Tesla': 'Tesla',
    'TikTok': 'TikTok', 'Togg': 'Togg', 'Trello': 'Trello',
    'Trendyol': 'Trendyol', 'Turkcell': 'Turkcell', 'Twitter': 'Twitter',
    'Uber': 'Uber', 'Visa': 'Visa', 'Vodafone': 'Vodafone',
    'WhatsApp': 'WhatsApp', 'Wi-Fi': 'Wi-Fi', 'Windows': 'Windows',
    'Wolt': 'Wolt', 'Word': 'Word', 'Xbox': 'Xbox',
    'Yemeksepeti': 'Yemeksepeti', 'YouTube': 'YouTube', 'Zara': 'Zara',
    'Zoom': 'Zoom',
  };

  // ---------- çalışma verisi ([setData] ile) ----------
  static Map<String, String> _foreign = const {};
  static Map<String, String> _parts = const {};
  static Set<String> _known = const {};
  static Set<String> _englishI = const {};

  /// Yabancı kelime sözlükleri (model dosyalarıyla birlikte indirilir:
  /// foreign_dict / foreign_parts / known_words / english_i).
  static void setData({
    Map<String, String>? foreign,
    Map<String, String>? parts,
    Iterable<String>? known,
    Iterable<String>? englishI,
  }) {
    _foreign = foreign ?? const {};
    _parts = parts ?? const {};
    _known = known?.toSet() ?? const {};
    _englishI = englishI?.toSet() ?? const {};
  }

  static String _foldKey(String t) => t
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .replaceAll('ı', 'i')
      .toLowerCase(); // [F:217]

  /// Türkçe küçük harf: I→ı, İ→i ([N:258-261]).
  static String trLower(String w) => w
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('\u0307', '');

  // ---------- foreign.py mantığı ----------
  static bool _knownInTurkish(String word) =>
      _known.contains(trLower(word)) ||
      _known.contains(word.toLowerCase()); // [F:102-103]

  static String? _foreignGet(String lw) {
    final v = _foreign[lw];
    return v != null && v != lw ? v : null;
  }

  static final _asciiWord = RegExp(r'^[A-Za-z]+$');
  static bool _looksEnglish(String word) {
    if (!_asciiWord.hasMatch(word)) return false;
    final lw = word.toLowerCase();
    return _englishI.contains(lw) || _foreignGet(lw) != null;
  } // [F:91-94]

  static bool _hasInnerCapital(String word) =>
      word.length > 1 &&
      RegExp('[A-Z]').hasMatch(word.substring(1)) &&
      RegExp('[a-z]').hasMatch(word); // [F:106-107]

  static final _camel = _re(
    '[A-Z]{2,}(?=[A-Z][a-z]|$_b|[0-9]|\$)|[A-Z]?[a-z]+|[A-Z]+|[0-9]+',
  ); // [F:52]
  static List<String> _splitCamel(String word) {
    final parts = [for (final m in _camel.allMatches(word)) m[0]!];
    return parts.isEmpty ? [word] : parts;
  } // [F:110-111]

  static String _englishIWord(String word) {
    if (RegExp(r'^[A-Z]+$').hasMatch(word) && word.length <= 5) return word;
    if (word.contains('I') && _looksEnglish(word)) {
      return word.replaceAll('I', 'İ');
    }
    return word;
  } // [F:235-239]

  static final _letterTr = RegExp('[A-Za-zÇĞİÖŞÜçğıöşü]');
  static bool _isUpperToken(String p) =>
      _letterTr.hasMatch(p) && p == p.toUpperCase();

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String? _respellPart(String part) {
    if (RegExp(r'^[0-9]+$').hasMatch(part)) return part;
    if (_isUpperToken(part) && part.length <= 5) {
      return _chars(part)
          .map(
            (c) => part.length > 1 ? _cap(_enLetters[c] ?? '') : _enLetters[c],
          )
          .join(' ');
    }
    if (part == 'i' || part == 'e') return _enLetters[part.toUpperCase()];
    final lw = part.toLowerCase();
    return _foreignGet(lw) ?? _parts[lw];
  } // [F:133-142]

  static String _upFirst(String t) {
    if (t.isEmpty) return t;
    return (t[0] == 'i' ? 'İ' : t[0].toUpperCase()) + t.substring(1);
  } // [F:155-156]

  static String? _respell(String word) {
    final parts = _hasInnerCapital(word) ? _splitCamel(word) : [word];
    final spoken = <String>[];
    for (final p in parts) {
      final r = _respellPart(p);
      if (r == null) return null;
      spoken.add(r);
    }
    final upped = [
      for (var k = 0; k < spoken.length; k++)
        (parts[k].isNotEmpty && _isUpperCase(parts[k][0])) ||
                (k == 0 && word.isNotEmpty && _isUpperCase(word[0]))
            ? _upFirst(spoken[k])
            : spoken[k],
    ];
    final merged = <String>[]; // [F:161-164]
    for (var k = 0; k < parts.length; k++) {
      final p = parts[k];
      final sp = upped[k];
      if (merged.isNotEmpty &&
          ((!_isUpperToken(p) && p.length <= 2) ||
              (k == 1 && (parts[0] == 'i' || parts[0] == 'e')))) {
        merged[merged.length - 1] += trLower(sp);
      } else {
        merged.add(sp);
      }
    }
    final text = merged.join(' ');
    return (_hasInnerCapital(word) ||
            (word.isNotEmpty && _isUpperCase(word[0])))
        ? _upFirst(text)
        : text;
  } // [F:145-166]

  static const _protectedSrc =
      '[$_wc.+\\-]+@[$_wc\\-]+(?:\\.[$_wc\\-]+)+'
      '|(?:https?://|www\\.)\\S+'
      '|$_b[$_wc\\-]+(?:\\.[$_wc\\-]+)*\\.(?:com|net|org|ai|io|co|app|dev|gov|edu|tr|me|info)(?:\\.[a-z]{2})?$_b'; // [F:170-175]
  static final _protected = _r(_protectedSrc, 'giu');
  static final _token = _re(
    "(?<![$_wc@./])([A-Za-z][A-Za-z0-9]*)(['’][a-zçğıöşü]+)?(?![$_wc@])",
  ); // [F:51]

  static Map<String, String> _addressTerms(
    String text,
    Map<String, String> lexicon,
  ) {
    final spans = [for (final m in _protected.allMatches(text)) m[0]!];
    if (spans.isEmpty) return {};
    final out = <String, String>{};
    for (final e in lexicon.entries) {
      final re = _r(
        '(?<![\\p{L}\\p{N}])${_esc(e.key)}(?![\\p{L}\\p{N}])',
        'iu',
      );
      if (spans.any(re.hasMatch)) out[e.key] = e.value;
    }
    return out;
  } // [F:178-188]

  static String _autoSpan(String text) => text.replaceAllMapped(_token, (m) {
    final word = m[1]!;
    final suffix = m[2] ?? '';
    if (RegExp(r'^[A-Z]+$').hasMatch(word) && word.length <= 5) return m[0]!;
    if (_knownInTurkish(word) ||
        !(_hasInnerCapital(word) || _foreignGet(word.toLowerCase()) != null)) {
      return _englishIWord(word) + suffix;
    }
    final r = _respell(word);
    return (r ?? _englishIWord(word)) + suffix;
  }); // [F:242-252]

  static String _respellSpan(
    String text,
    Map<String, String> lexicon,
    bool auto,
  ) {
    if (lexicon.isEmpty) return auto ? _autoSpan(text) : text;
    final sorted = _byLengthDesc(lexicon.keys);
    final pat = _r(
      "(?<!$_w)(${sorted.map(_esc).join('|')})(?=['’]|[^$_wc]|\$)",
      'giu',
    );
    final byLower = <String, String>{};
    for (final t in sorted) {
      byLower[_foldKey(t)] = lexicon[t]!;
    }
    final out = StringBuffer();
    var last = 0;
    for (final m in pat.allMatches(text)) {
      final before = text.substring(last, m.start);
      out.write(auto ? _autoSpan(before) : before);
      final term = m[1]!;
      final say = byLower[_foldKey(term)];
      last = m.end;
      if (say == null) {
        out.write(term);
        continue;
      }
      final kept = _foldKey(say) == _foldKey(term);
      out.write(
        auto ? (kept ? _englishIWord(term) : say) : (kept ? term : say),
      );
    }
    final rest = text.substring(last);
    out.write(auto ? _autoSpan(rest) : rest);
    return out.toString();
  } // [F:205-232]

  static String _respellForeign(
    String text,
    Map<String, String> lexicon,
    bool auto,
  ) {
    final out = StringBuffer();
    var last = 0;
    for (final m in _protected.allMatches(text)) {
      out.write(_respellSpan(text.substring(last, m.start), lexicon, auto));
      final span = m[0]!;
      out.write(span.contains('@') ? span.toLowerCase() : span);
      last = m.end;
    }
    out.write(_respellSpan(text.substring(last), lexicon, auto));
    return out.toString();
  } // [F:191-202]

  // ---------- normalize.py mantığı ----------
  static String _turkishUpperChar(String ch) {
    if (ch == 'i') return 'İ';
    if (ch == 'ı') return 'I';
    return ch.toUpperCase();
  } // [N:623-624]

  static String _normalizeOrthography(String text) {
    final t = unorm
        .nfkc(text)
        .replaceAll(RegExp('[’‘`´]'), "'")
        .replaceAll(RegExp('["“”„«»]'), '');
    return t
        .replaceAll("''", '')
        .replaceAll(RegExp(r'\s+', unicode: true), ' ')
        .trim();
  } // [N:264-267]

  static String numberToWords(int n) {
    if (n < 0) return 'eksi ${numberToWords(-n)}';
    if (n < 10) return _ones[n];
    if (n < 100) {
      final t = n ~/ 10, o = n % 10;
      return o == 0 ? _tens[t] : '${_tens[t]} ${_ones[o]}';
    }
    if (n < 1000) {
      final h = n ~/ 100, r = n % 100;
      final pre = h == 1 ? 'yüz' : '${_ones[h]} yüz';
      return r == 0 ? pre : '$pre ${numberToWords(r)}';
    }
    for (final (s, label) in const [
      (1000000000000, 'trilyon'),
      (1000000000, 'milyar'),
      (1000000, 'milyon'),
      (1000, 'bin'),
    ]) {
      if (n >= s) {
        final c = n ~/ s, r = n % s;
        final pre = (s == 1000 && c == 1)
            ? label
            : '${numberToWords(c)} $label';
        return r == 0 ? pre : '$pre ${numberToWords(r)}';
      }
    }
    throw ArgumentError('number is too large: $n');
  } // [N:480-498]

  static int _int(String s) => int.parse(s);

  static String _replaceDateParts(
    String d,
    String m,
    String y, [
    String? original,
  ]) {
    final day = _int(d), mon = _int(m);
    if (!(day >= 1 && day <= 31) || !_months.containsKey(mon)) {
      return original ?? '$y-$m-$d';
    }
    return '${numberToWords(day)} ${_months[mon]} ${numberToWords(_int(y))}';
  } // [N:505-509]

  static final _symDegree = RegExp(r'(?<=\d)\s?°\s?C?(?!\p{L})', unicode: true);
  static final _symPlus = RegExp(
    r'(?<=\d)\s?\+\s?(?=\d)|(?<=\s)\+(?=\s)',
    unicode: true,
  );
  static final _symEq = RegExp(r'(?<=[\d\s])=(?=[\d\s])', unicode: true);
  static final _symHash = _re('(?<![$_wc&])#(?=$_l)');
  static final _symStars = RegExp(r'\*+|_{2,}');
  static final _symDrop = RegExp(r'[\p{So}\p{Cs}\p{Co}]', unicode: true);

  static String _replaceSymbols(String text) {
    text = text.replaceAll(_symDegree, ' derece');
    text = text.replaceAll(_symPlus, ' artı ');
    text = text.replaceAll(_symEq, ' eşittir ');
    text = text.replaceAll(_symHash, 'heşteg ');
    text = text.replaceAll(_symStars, '');
    text = _chars(text).map((ch) => _symbolsMap[ch] ?? ch).join();
    text = _chars(text).where((ch) => !_symDrop.hasMatch(ch)).join();
    return text.replaceAll('\uFE0F', '').replaceAll('\u200D', '');
  } // [N:516-525]

  static String _replaceIban(Match m) {
    final g1 = m[1]!, g2 = m[2]!, g3 = m[3]!;
    final groups = g2.contains(' ')
        ? [g1, ...g2.split(RegExp(r'\s+')), g3]
        : [g1, g2, g3];
    // JS split, baştaki boşluktan boş ilk parça üretir; Python da öyle.
    return 'te re, ${groups.map(_digitSequenceToWords).join(', ')}';
  } // [N:528-530]

  static String _replaceDottedInitialism(Match m) =>
      _chars(m[0]!)
          .where((c) => c != '.')
          .map((c) => _initialismLetters[c] ?? '')
          .join();

  static String _replaceBloodGroup(Match m) {
    final g = m[1]!;
    final grp = g == '0'
        ? 'sıfır'
        : _chars(g).map((c) => _initialismLetters[c] ?? '').join();
    return '$grp eraj ${m[2] == '+' ? 'pozitif' : 'negatif'}';
  } // [N:537-539]

  static final _d4 = RegExp(r'^\d{4}$');
  static final _d2 = RegExp(r'^\d{2}$');
  static final _dAll = RegExp(r'^\d+$');

  static String _replaceRange(Match m) {
    final start = m[1]!, end = m[2]!;
    if (_d4.hasMatch(start) &&
        _d2.hasMatch(end) &&
        _int(end) == (_int(start) + 1) % 100) {
      return '$start ${_int(end)}';
    }
    if (_dAll.hasMatch(start) &&
        _dAll.hasMatch(end) &&
        _int(start) > _int(end)) {
      return '$start $end';
    }
    return '$start ile $end';
  } // [N:542-549]

  static final _vitaminBefore = _r(
    'vitamin[$_wc]*\\s+(?:[$_wc]+\\s+ve\\s+)?\$',
    'iu',
  );
  static final _vitaminAfter = _r('^\\s+vitamin', 'iu');

  static String _replaceLoneLetter(Match m) {
    final letter = m[1]!;
    final dot = m[2];
    final string = m.input;
    final end = m.end;
    final following = end < string.length ? string.substring(end, end + 1) : '';
    if (letter == 'O' ||
        letter == 'I' ||
        ((letter == 'A' || letter == 'E') &&
            const [',', '!', '?'].contains(following))) {
      return m[0]!;
    }
    final initial = dot != null || following == '.';
    final vitamin =
        _vitaminBefore.hasMatch(string.substring(0, m.start)) ||
        _vitaminAfter.hasMatch(string.substring(end));
    return ((initial || vitamin) ? _initialismLetters : _letterNames)[letter] ??
        '';
  } // [N:552-563]

  static final _doseAfter = _r('^\\s*(?:$_doseWords)', 'iu');

  static String _replaceTimes(Match m) {
    final daily = m[1];
    final first = numberToWords(_int(m[2]!));
    final second = numberToWords(_int(m[3]!));
    if ((daily != null && daily.isNotEmpty) ||
        _doseAfter.hasMatch(m.input.substring(m.end))) {
      return '${daily ?? ''}$first defa $second';
    }
    return '${_withDative(first)} $second';
  } // [N:570-575]

  static String _lastVowel(String words) =>
      _chars(words).reversed.firstWhere(_vowels.contains, orElse: () => 'e');

  static String _withDative(String words) {
    if (words.endsWith('dört')) {
      return '${words.substring(0, words.length - 1)}de';
    }
    final rev = _lastVowel(words);
    final vowel = 'aıou'.contains(rev) ? 'a' : 'e';
    final y = _vowels.contains(words[words.length - 1]) ? 'y' : '';
    return '$words$y$vowel';
  } // [N:578-584]

  static String _currencyWords(String symbol, String whole, String? fraction) {
    final pair = const {
      '₺': ['lira', 'kuruş'],
      r'$': ['dolar', 'sent'],
      '€': ['avro', 'sent'],
      '£': ['sterlin', 'peni'],
    }[symbol]!;
    var v = '${numberToWords(_int(whole.replaceAll('.', '')))} ${pair[0]}';
    if (fraction != null && fraction.isNotEmpty && _int(fraction) != 0) {
      v += ' ${numberToWords(_int(fraction.padRight(2, '0')))} ${pair[1]}';
    }
    return v;
  } // [N:592-602]

  static String _replacePhone(Match m) {
    final country = m[1];
    final trunk = m[2];
    final spoken = <String>[
      if (country != null && country.isNotEmpty) 'artı doksan',
    ];
    spoken.add(
      (trunk != null && trunk.isNotEmpty)
          ? 'sıfır ${_digitGroupToWords(m[3]!)}'
          : _digitGroupToWords(m[3]!),
    );
    for (final g in [m[4]!, m[5]!, m[6]!]) {
      spoken.add(_digitGroupToWords(g));
    }
    return spoken.join(', ');
  } // [N:605-613]

  static String _digitGroupToWords(String value) {
    final stripped = value.replaceFirst(RegExp('^0+'), '');
    final zeros = List.filled(value.length - stripped.length, 'sıfır');
    return stripped.isNotEmpty
        ? [...zeros, numberToWords(_int(stripped))].join(' ')
        : zeros.join(' ');
  } // [N:616-620]

  static String _replaceSlashPair(Match m) {
    final n = _int(m[1]!), d = _int(m[2]!);
    if (n > 0 && n < d && d <= 10) {
      return '${_withLocative(numberToWords(d))} ${numberToWords(n)}';
    }
    if ((n == 7 && d == 24) || (n == 24 && d == 7)) {
      return '${numberToWords(n)} ${numberToWords(d)}';
    }
    return '${numberToWords(n)} bölü ${numberToWords(d)}';
  } // [N:627-635]

  static String _withLocative(String words) {
    final rev = _lastVowel(words);
    final vowel = 'aıou'.contains(rev) ? 'a' : 'e';
    final t = 'çfhkpsşt'.contains(words[words.length - 1]) ? 't' : 'd';
    return '$words$t$vowel';
  } // [N:638-642]

  /// JS `s.split(/([.@/_-])/)`: ayırıcılar da sonuçta kalır.
  static List<String> _splitKeep(String s, RegExp sep) {
    final out = <String>[];
    var last = 0;
    for (final m in sep.allMatches(s)) {
      out
        ..add(s.substring(last, m.start))
        ..add(m[0]!);
      last = m.end;
    }
    out.add(s.substring(last));
    return out;
  }

  static final _letters = RegExp(r'^\p{L}+$', unicode: true);

  static String _replaceAddress(Match m) {
    final addr = m[0]!
        .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'/$'), '');
    final out = <String>[];
    for (final piece in _splitKeep(addr, RegExp(r'[.@/_-]'))) {
      if (piece == '.') {
        out.add('nokta');
      } else if (piece == '@') {
        out.add('et');
      } else if (piece == '/') {
        out.add('bölü');
      } else if (piece == '_') {
        out.add('alt tire');
      } else if (piece == '-') {
        out.add('tire');
      } else if (piece.isNotEmpty) {
        final lw = piece.toLowerCase();
        final word = _addressWords[lw];
        if (word != null) {
          out.add(word);
        } else if (_chars(piece).length <= 2 && _letters.hasMatch(lw)) {
          out.add(
            _chars(trLower(lw))
                .map((ch) => _letterNames[_turkishUpperChar(ch)] ?? ch)
                .join(' '),
          );
        } else {
          out.add(piece);
        }
      }
    }
    return out.join(' ');
  } // [N:645-659]

  static String _replaceDuration(Match m) {
    final parts = <String>[];
    for (final (v, u) in [(_int(m[1]!), 'saat'), (_int(m[2]!), 'dakika')]) {
      if (v != 0) parts.add('${numberToWords(v)} $u');
    }
    final s = _int(m[3]!);
    if (s != 0 || parts.isEmpty) parts.add('${numberToWords(s)} saniye');
    return parts.join(' ');
  } // [N:662-667]

  static String _attachSuffix(Match m) {
    var stem = m[1]!;
    var suffix = m[2]!;
    final lastStem = stem.isEmpty ? '' : stem[stem.length - 1];
    if (lastStem.isNotEmpty &&
        !_vowels.contains(lastStem) &&
        suffix.length > 1 &&
        'yns'.contains(suffix[0]) &&
        _vowels.contains(suffix[1])) {
      suffix = suffix.substring(1);
    }
    if (_vowels.contains(suffix[0])) {
      stem = stem
          .replaceFirst(RegExp(r'dört$'), 'dörd')
          .replaceFirst(RegExp(r'buçuk$'), 'buçuğ');
    }
    var vowel = _lastVowel(stem);
    final out = StringBuffer();
    final chars = _chars(suffix);
    for (var i = 0; i < chars.length; i++) {
      var char = chars[i];
      if ('ae'.contains(char)) {
        char = 'aıou'.contains(vowel) ? 'a' : 'e';
      } else if ('ıiuü'.contains(char)) {
        final back = 'aıou'.contains(vowel), round = 'ouöü'.contains(vowel);
        char = (!back && !round)
            ? 'i'
            : (!back && round)
            ? 'ü'
            : (back && !round)
            ? 'ı'
            : 'u';
      } else if (i == 0 && 'dt'.contains(char)) {
        char = 'çfhkpsşt'.contains(stem[stem.length - 1]) ? 't' : 'd';
      }
      if (_vowels.contains(char)) vowel = char;
      out.write(char);
    }
    return '$stem$out';
  } // [N:670-694]

  static String _replaceTime(Match m) {
    final hw = numberToWords(_int(m[1]!));
    final mi = m[2]!;
    if (_int(mi) == 0) return hw;
    return '$hw ${mi.startsWith('0') ? _digitSequenceToWords(mi) : numberToWords(_int(mi))}';
  } // [N:697-703]

  static final _grouped = RegExp(r'^\d{1,3}(?:\.\d{3})+(?:,\d+)?$');

  static String _numericToWords(String v) {
    if (_grouped.hasMatch(v)) {
      final noDots = v.replaceAll('.', '');
      final ci = noDots.indexOf(',');
      if (ci != -1) {
        return _decimalToWords(
          '${noDots.substring(0, ci)},${noDots.substring(ci + 1)}',
        );
      }
      return numberToWords(_int(noDots));
    }
    return RegExp('[,.]').hasMatch(v)
        ? _decimalToWords(v)
        : numberToWords(_int(v));
  } // [N:706-710]

  static String _decimalToWords(String v) {
    final i = v.indexOf(RegExp('[,.]'));
    final whole = v.substring(0, i), frac = v.substring(i + 1);
    final ww = numberToWords(_int(whole));
    if (frac == '5' && _int(whole) != 0) return '$ww buçuk';
    return '$ww virgül ${frac.length <= 2 ? _digitGroupToWords(frac) : _digitSequenceToWords(frac)}';
  } // [N:713-721]

  static String _digitSequenceToWords(String v) =>
      _chars(v).map((d) => _ones[_int(d)]).join(' '); // [N:724-725]

  static String _ordinalToWords(int n) {
    final w = numberToWords(n).split(' ');
    w[w.length - 1] = _ordinalExceptions[w.last] ?? '${w.last}inci';
    return w.join(' ');
  } // [N:728-732]

  static int _romanToInt(String s) {
    var t = 0;
    for (var i = 0; i < s.length; i++) {
      final v = _romanValues[s[i]]!;
      final next = i + 1 < s.length ? _romanValues[s[i + 1]] : null;
      t += (next != null && next > v) ? -v : v;
    }
    return t;
  } // [N:735-740]

  static const _roman =
      '(?:XX|XIX|XVIII|XVII|XVI|XV|XIV|XIII|XII|XI|IX|VIII|VII|VI|IV|III|II)';
  static final _romanOrdinal = _re(
    '$_b($_roman|I(?=\\.\\s+Dünya))\\.\\s+(?=[A-ZÇĞİÖŞÜ])',
  );
  static final _romanNumber = _re(
    "$_b([A-ZÇĞİÖŞÜ]$_l*\\s+)($_roman)$_b(?![.'’]?$_l)",
  );

  static String _replaceRoman(String text) {
    text = text.replaceAllMapped(
      _romanOrdinal,
      (m) => '${_ordinalToWords(_romanToInt(m[1]!))} ',
    );
    return text.replaceAllMapped(
      _romanNumber,
      (m) => m[1]! + numberToWords(_romanToInt(m[2]!)),
    );
  } // [N:743-749]

  static final _shoutWords = _re('$_b$_l{2,}$_b');
  static final _shoutCaps = RegExp(r'^[A-ZÇĞİÖŞÜQWX]{2,}$', unicode: true);

  static String _lowerIfShouted(String text) {
    final words = [for (final m in _shoutWords.allMatches(text)) m[0]!];
    final caps = words.where(_shoutCaps.hasMatch).toList();
    final spoken = caps.where(_isPronounceable).length;
    return (spoken >= 3 && caps.length >= 0.7 * words.length)
        ? trLower(text)
        : text;
  } // [N:752-758]

  static String _replaceInitialism(Match match) {
    final m = match[0]!;
    final known = _capsLexicon[m];
    if (known != null) return known;
    if (_isPronounceable(m)) return m;
    return _chars(m).map((c) => _initialismLetters[c] ?? '').join();
  } // [N:761-768]

  static final _threeConsonants = RegExp(r'[^AEIİOÖUÜ]{3}', unicode: true);

  static bool _isPronounceable(String word) {
    if (word.length < 4) return false;
    final v = _chars(word).where(_vowels.contains).length;
    return v / word.length >= 0.3 && !_threeConsonants.hasMatch(word);
  } // [N:771-776]

  // normalizeForModel desenleri — SIRA PYTHON İLE AYNI [N:302-451].
  static final _pApostropheCaps = _re("'([A-ZÇĞİÖŞÜ]+)$_b");
  static final _pNoAfterWord = _r(
    '(?<!${_b}sokak )(?<!${_b}sokağı )(?<!${_b}cadde )(?<!${_b}caddesi )(?<!${_b}bulvarı )(?<!${_b}mahallesi )(?<!${_b}apartmanı )(?<=$_l )no$_b\\.?:?(?=\\s)',
    'giu',
  );
  static final _pNoNumber = _r('${_b}no\\s*[:.]\\s*(?=\\d)', 'giu');
  static final _pDaire = _re('${_b}D\\s*:\\s*(?=\\d)');
  static final _pTel = _re('${_b}Tel\\s*:');
  static final _pPage = _re('${_b}s\\.\\s*(?=\\d)');
  static final _pEmail = _re('$_b[$_wc.+\\-]+@[$_wc\\-]+(?:\\.[$_wc\\-]+)+$_b');
  static final _pUrl = _r(
    '$_b(?:https?://)?(?:www\\.)?[a-z0-9-]+(?:\\.[a-z0-9-]+)*\\.(?:com|net|org|gov|edu|info|io|ai|tr)$_b(?:/[$_wc./\\-]*)?',
    'giu',
  );
  static final _pIban = _re(
    '${_b}TR(\\d{2})((?:\\s?\\d{4}){5})\\s?(\\d{2})$_b',
  );
  static final _pDotted = RegExp(r'(?:[A-ZÇĞİÖŞÜ]\.){2,}', unicode: true);
  static final _pPh = _re('${_b}pH$_b');
  static final _pH2o = _re('${_b}H2O$_b');
  static final _pPylori = _r('${_b}H\\.\\s*pylori$_b', 'giu');
  static final _pXray = _r('${_b}X-?ray$_b', 'giu');
  static final _pHane = _re('$_b(hane(?:si|leri)?)\\s+(\\d{2,6})$_b');
  static final _pHba1c = _re('${_b}HbA1c$_b');
  static final _pBlood = _re('$_b(AB|A|B|0)\\s?Rh\\s?\\(?([+-])\\)?');
  static final _pMmhg = _re('$_b(\\d{2,3})/(\\d{2,3})\\s*mmHg$_b');
  static final _pTimes = _re('(günde\\s+)?$_b(\\d+)\\s?[xX×]\\s?(\\d+)$_b');
  static final _pKmh = _re(
    '(?<![\\d.,])(\\d+(?:,\\d+)?)\\s?km\\/(?:sa|s|h)$_b',
  );
  static final _pDose = _re(
    '(?<![\\d.,])(\\d+(?:,\\d+)?)\\s?(mg|mcg|g|ml)\\/kg$_b',
  );
  static final _pArea = RegExp(
    r'(?<=\d) ?(km|cm|m)([23])(?![\p{L}\p{N}_])',
    unicode: true,
  );
  static final _pUnits = _re(
    '(?<=\\d) ?(${_numberUnits.keys.map(_esc).join('|')})(?![$_wc/])',
  );
  static final _pLitre = _re("(?<=\\d) L$_b(?![/'’])(?!\\s*\\d)");
  static final _pWeekday = _re(
    '$_b(${_weekdays.keys.join('|')})$_b\\.?(?=\\s*(?:[-–,/]|\\d|\$))',
  );
  static final _pWeekRange = _r(
    '$_b(pazartesi|salı|çarşamba|perşembe|cuma|cumartesi|pazar)\\s*[-–]\\s*(pazartesi|salı|çarşamba|perşembe|cuma|cumartesi|pazar)$_b',
    'giu',
  );
  static final _pCurrencyPre = RegExp(
    r'([₺$€£])\s*((?:\d{1,3}(?:\.\d{3})+)|\d+)(?:[,.](\d{1,2}))?',
    unicode: true,
  );
  static final _pCurrencyPost = _re(
    '(?<![\\d.,])((?:\\d{1,3}(?:\\.\\d{3})+)|\\d+)(?:,(\\d{1,2}))?\\s?(?:([₺\$€£])|(TL|USD|EUR|GBP)$_b)',
  );
  static final _pCapsNearDigit = _re(
    '(?<=\\d)[A-ZÇĞİÖŞÜQWX]{1,6}(?=\\d|$_b)|$_b[A-ZÇĞİÖŞÜQWX]{1,6}(?=\\d)|(?<=\\d )[A-ZÇĞİÖŞÜQWX]{2,6}(?= \\d)',
  );
  static final _pLetterDigit = RegExp(
    r'(?<=\p{L})(?=\d)|(?<=\d)(?=\p{L})',
    unicode: true,
  );
  static final _pLetterDashDigit = RegExp(r'(?<=\p{L})-(?=\d)', unicode: true);
  static final _pLoneCapDigit = _re(
    '$_b([A-ZÇĞİÖŞÜQWX])(?= \\d)|(?<=\\d )([A-ZÇĞİÖŞÜQWX])$_b',
  );
  static final _pDateDmy = _re('$_b(\\d{1,2})[./-](\\d{1,2})[./-](\\d{4})$_b');
  static final _pDateYmd = _re('$_b(\\d{4})-(\\d{1,2})-(\\d{1,2})$_b');
  static final _pPercentPre = RegExp(r'%\s*(\d+(?:[,.]\d+)?)', unicode: true);
  static final _pPercentPost = RegExp(
    r'(?<![\d.,])(\d+(?:,\d+)?)\s?%',
    unicode: true,
  );
  static final _pPhone = RegExp(
    r'(?<!\d)(\+90[\s-]?)?(0?)\(?(\d{3})\)?[\s-]?(\d{3})[\s-]?(\d{2})[\s-]?(\d{2})(?!\d)',
    unicode: true,
  );
  static final _pRange = RegExp(
    r'(?<![\d\-–])(\d[\d.:,]*)\s*[-–]\s*(\d[\d.:,]*)(?![\d\-–])',
    unicode: true,
  );
  static final _pMinus = RegExp(
    r'(?<![\p{L}\p{N}_.,:)\]])-(?=\d)',
    unicode: true,
  );
  static final _pDuration = _re('$_b(\\d{1,2}):([0-5]\\d):([0-5]\\d)$_b');
  static final _pClock = _re('$_b([01]?\\d|2[0-3])[:.]([0-5]\\d)$_b');
  static final _pSlashPair = _re('$_b(\\d{1,2})/(\\d{1,2})$_b');
  static final _pSlash = _re('$_b(\\d+)/(\\d+)$_b');
  static final _pGroupedNum = _re('$_b\\d{1,3}(?:\\.\\d{3})+(?:,\\d+)?$_b');
  static final _pDecimal = _re('$_b(\\d+)[,.](\\d+)$_b');
  static final _pOrdinalSuffix = _re(
    "$_b(\\d+)'?(?:inci|ıncı|üncü|uncu|nci|ncı|ncü|ncu)$_b",
  );
  static final _pOrdinalDotLower = _re('$_b(\\d+)\\.(?=[a-zçğıöşü])');
  static final _pOrdinalDotHead = _re(
    '$_b([1-9]\\d*)\\.(?=\\s+(?:[a-zçğıöşü]|(?:$_ordinalHeads)$_b))',
  );
  static final _pLongDigits = _re('$_b\\d{5,}$_b');
  static final _pLeadingZero = _re('${_b}0\\d+$_b');
  static final _pDigits = _re('$_b\\d+$_b');
  static final _pNoSu = _r("${_b}no\\.'?s[ıu]$_b", 'giu');
  static final _pPerUnit = _r('(?<=$_w)/(sn|sa|dk)$_b', 'giu');
  static final _pUnitPer = _re(
    '$_b(mg|kg|g|km|m|cm|ml)/(kg|g|m|l|lt|ml|saat|gün)$_b',
  );
  static final _pSayin = _re('${_b}Sn\\.\\s*(?=[A-ZÇĞİÖŞÜ])');
  static final List<(String, RegExp, RegExp?)> _pAbbreviations = [
    for (final abbr in _byLengthDesc(_abbreviations.keys))
      if (abbr.endsWith('.'))
        (
          abbr,
          _r('(?<!$_w)${_esc(abbr)}\\s*(?=$_w)', 'giu'),
          _beforeAWord.contains(abbr)
              ? null
              : _r('(?<!$_w)${_esc(abbr)}', 'giu'),
        )
      else
        (abbr, _r('(?<!$_w)${_esc(abbr)}(?!$_w)', 'giu'), null),
  ];
  static final _pInitialism = _re('$_b[A-ZÇĞİÖŞÜQWX]{2,6}$_b');
  static final _pLoneLetter = _re(
    "(?<![$_wc.'-])([A-ZÇĞİÖŞÜQWX])(\\.(?=\\s+[a-zçğıöşü]))?(?![$_wc-])",
  );
  static final _pSpacedSlash = RegExp(r'\s+/\s+');
  static final _pLetterSlash = RegExp(r'(?<=\p{L})/(?=\p{L})', unicode: true);
  static final _pSpacePunct = RegExp(r'\s+([,.;:!?])');
  static final _pLeadComma = RegExp(
    r'^[\s,]+|(?<=[,.;:!?])\s*,',
    unicode: true,
  );
  static final _pSpaces = RegExp(r'\s+', unicode: true);

  /// Ham metin → modelin okuyacağı (henüz büyük/küçük harfli) Türkçe metin.
  static String normalizeForModel(String text) {
    var t = _normalizeOrthography(text.replaceAll('−', '-'));
    t = _lowerIfShouted(t);
    t = _replaceRoman(t);
    t = t.replaceAllMapped(_pApostropheCaps, (m) => "'${trLower(m[1]!)}");
    t = t.replaceAll(_pNoAfterWord, 'numarası');
    t = t.replaceAll(_pNoNumber, 'numara ');
    t = t.replaceAll(_pDaire, 'daire ');
    t = t.replaceAll(_pTel, 'telefon:');
    t = t.replaceAll(_pPage, 'sayfa ');
    t = t.replaceAllMapped(_pEmail, _replaceAddress); // [N:320]
    t = t.replaceAllMapped(_pUrl, _replaceAddress); // [N:321]
    t = _replaceSymbols(t); // [N:322]
    t = t.replaceAllMapped(_pIban, _replaceIban); // [N:323]
    t = t.replaceAllMapped(_pDotted, _replaceDottedInitialism); // [N:324]
    t = t.replaceAll(_pPh, 'pe ha'); // [N:325]
    t = t.replaceAll(_pH2o, 'haş iki o'); // [N:326]
    t = t.replaceAll(_pPylori, 'ha pilori'); // [N:327]
    t = t.replaceAll(_pXray, 'iksrey'); // [N:328]
    t = t.replaceAllMapped(
      _pHane,
      (m) => '${m[1]} ${_digitSequenceToWords(m[2]!)}',
    ); // [N:329-330]
    t = t.replaceAll(_pHba1c, 'ha be a bir ce'); // [N:331]
    t = t.replaceAllMapped(_pBlood, _replaceBloodGroup); // [N:332]
    t = t.replaceAllMapped(
      _pMmhg,
      (m) =>
          '${_withDative(numberToWords(_int(m[1]!)))} ${numberToWords(_int(m[2]!))} milimetre cıva',
    ); // [N:333-337]
    t = t.replaceAllMapped(_pTimes, _replaceTimes); // [N:338]
    t = t.replaceAllMapped(
      _pKmh,
      (m) => 'saatte ${_numericToWords(m[1]!)} kilometre',
    ); // [N:341-344]
    t = t.replaceAllMapped(
      _pDose,
      (m) => 'kilogram başına ${_numericToWords(m[1]!)} ${_doseUnits[m[2]!]}',
    ); // [N:345-349]
    t = t.replaceAllMapped(
      _pArea,
      (m) => ' ${_areaUnits[m[1]!]}${m[2] == '2' ? 'kare' : 'küp'}',
    ); // [N:350-354]
    t = t.replaceAllMapped(
      _pUnits,
      (m) => ' ${_numberUnits[m[1]!]}',
    ); // [N:355-359]
    t = t.replaceAll(_pLitre, ' litre'); // [N:360]
    t = t.replaceAllMapped(_pWeekday, (m) => _weekdays[m[1]!]!); // [N:361-363]
    t = t.replaceAllMapped(
      _pWeekRange,
      (m) => '${m[1]} ile ${m[2]}',
    ); // [N:364-370]
    t = t.replaceAllMapped(
      _pCurrencyPre,
      (m) => _currencyWords(m[1]!, m[2]!, m[3]),
    ); // [N:373]
    t = t.replaceAllMapped(
      _pCurrencyPost,
      (m) => _currencyWords(m[3] ?? _currencyCodes[m[4]!]!, m[1]!, m[2]),
    ); // [N:374-378]
    t = t.replaceAllMapped(_pCapsNearDigit, (match) {
      final m = match[0]!;
      return _capsLexicon.containsKey(m) || _isPronounceable(m)
          ? m
          : ' ${_chars(m).map((c) => _initialismLetters[c] ?? '').join(' ')} ';
    }); // [N:380-385]
    t = t.replaceAll(_pLetterDigit, ' '); // [N:386]
    t = t.replaceAll(_pLetterDashDigit, ' '); // [N:387]
    t = t.replaceAllMapped(
      _pLoneCapDigit,
      (m) => _letterNames[m[1] ?? m[2]] ?? '',
    ); // [N:388]
    t = t.replaceAllMapped(
      _pDateDmy,
      (m) => _replaceDateParts(m[1]!, m[2]!, m[3]!, m[0]),
    ); // [N:389]
    t = t.replaceAllMapped(
      _pDateYmd,
      (m) => _replaceDateParts(m[3]!, m[2]!, m[1]!),
    ); // [N:390-392]
    t = t.replaceAllMapped(
      _pPercentPre,
      (m) => 'yüzde ${_numericToWords(m[1]!)}',
    ); // [N:393]
    t = t.replaceAllMapped(
      _pPercentPost,
      (m) => 'yüzde ${_numericToWords(m[1]!)}',
    ); // [N:394-396]
    t = t.replaceAllMapped(_pPhone, _replacePhone); // [N:397]
    t = t.replaceAllMapped(_pRange, _replaceRange); // [N:398]
    t = t.replaceAll(_pMinus, 'eksi '); // [N:399]
    t = t.replaceAllMapped(_pDuration, _replaceDuration); // [N:400]
    t = t.replaceAllMapped(_pClock, _replaceTime); // [N:401]
    t = t.replaceAllMapped(_pSlashPair, _replaceSlashPair); // [N:402]
    t = t.replaceAllMapped(_pSlash, (m) => '${m[1]} bölü ${m[2]}'); // [N:403]
    t = t.replaceAllMapped(
      _pGroupedNum,
      (m) => _numericToWords(m[0]!),
    ); // [N:404]
    t = t.replaceAllMapped(_pDecimal, (m) => _decimalToWords(m[0]!)); // [N:405]
    t = t.replaceAllMapped(
      _pOrdinalSuffix,
      (m) => _ordinalToWords(_int(m[1]!)),
    ); // [N:407-411]
    t = t.replaceAllMapped(
      _pOrdinalDotLower,
      (m) => _ordinalToWords(_int(m[1]!)),
    ); // [N:412]
    t = t.replaceAllMapped(
      _pOrdinalDotHead,
      (m) => _ordinalToWords(_int(m[1]!)),
    ); // [N:414-418]
    t = t.replaceAllMapped(
      _pLongDigits,
      (m) => _digitSequenceToWords(m[0]!),
    ); // [N:419]
    t = t.replaceAllMapped(
      _pLeadingZero,
      (m) => _digitGroupToWords(m[0]!),
    ); // [N:420]
    t = t.replaceAllMapped(
      _pDigits,
      (m) => numberToWords(_int(m[0]!)),
    ); // [N:421]
    t = t.replaceAll(_pNoSu, 'numarası'); // [N:422]
    t = t.replaceAllMapped(
      _pPerUnit,
      (m) => ' bölü ${_perUnit[m[1]!.toLowerCase()]}',
    ); // [N:424-426]
    t = t.replaceAllMapped(_pUnitPer, (m) => '${m[1]} bölü ${m[2]}'); // [N:427]
    t = t.replaceAll(_pSayin, 'sayın '); // [N:428]
    for (final (abbr, withWord, bare) in _pAbbreviations) {
      // [N:429-439]
      final exp = _abbreviations[abbr]!;
      if (abbr.endsWith('.')) {
        t = t.replaceAll(withWord, '$exp ');
        if (bare == null) continue;
        t = t.replaceAll(bare, exp);
      } else {
        t = t.replaceAll(withWord, exp);
      }
    }
    t = t.replaceAllMapped(_pInitialism, _replaceInitialism); // [N:440]
    t = t.replaceAllMapped(_pLoneLetter, _replaceLoneLetter); // [N:443-445]
    t = t.replaceAllMapped(_spokenStemSuffix, _attachSuffix); // [N:446]
    t = t.replaceAll(_pSpacedSlash, ', '); // [N:447]
    t = t.replaceAll(_pLetterSlash, ' '); // [N:448]
    t = t.replaceAllMapped(_pSpacePunct, (m) => m[1]!); // [N:449]
    t = t.replaceAll(_pLeadComma, ''); // [N:450]
    return t.replaceAll(_pSpaces, ' ').trim(); // [N:451]
  }

  static final _pCapsWord = _re('$_b[A-ZÇĞİÖŞÜQWX]{2,}$_b');

  static String _normalizeForCasedModel(String text) {
    final merged = {...lexicon};
    final inAddr = _addressTerms(text, merged);
    text = _respellForeign(text, merged, true);
    var out = normalizeForModel(text);
    if (inAddr.isNotEmpty) out = _respellForeign(out, inAddr, false);
    out = out.replaceAllMapped(_pCapsWord, (m) => trLower(m[0]!));
    return out.replaceAll('I', 'ı').replaceAll('İ', 'i');
  } // [N:454-477]

  // ---------- __init__.py ön uçları ----------
  static final _foldApos = RegExp('[’‘`´]'); // [I:20]
  static final _notSymbol = RegExp(
    r"[^abcçdefgğhıijklmnoöpqrsştuüvwxyzâîû .,?!'\-:;]",
  );

  static String cleanModelText(String s) {
    s = s
        .replaceAll(_foldApos, "'")
        .replaceAll(RegExp('[\u2013\u2014]'), '-')
        .replaceAll('\u2026', '.')
        .replaceAll(RegExp('[\u00a0\t\n]'), ' ');
    s = s.replaceAll(_notSymbol, ' ');
    s = s.replaceAllMapped(RegExp(r'\s+([.,?!:;])'), (m) => m[1]!);
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  } // [I:31-37]

  /// Ham metin → modelin harf dizisi (küçük harf, yalnız [symbols]).
  /// Normalleştirici bir girdide patlarsa metin yazıldığı gibi okunur
  /// (Python `api.model_text` geri dönüşü).
  static String toModelText(String raw) {
    final nfc = unorm.nfc(raw);
    try {
      return cleanModelText(trLower(_normalizeForCasedModel(nfc)));
    } catch (_) {
      return cleanModelText(trLower(nfc));
    }
  } // [I:25-28]

  /// Harf dizisi → kimlikler (`<bos>` ... `<eos>`).
  static List<int> encode(String modelText) => [
    bos,
    for (final c in _chars(modelText)) ?symbolToId[c],
    eos,
  ]; // [I:40-41]

  /// Normalleştirilmiş metni model parçalarına böler: cümle sınırından, ilk
  /// parça kısa ([firstChars]) — ilk ses çabuk gelsin — sonrakiler
  /// [maxChars]'a kadar (app.js `splitModelText`).
  static List<String> splitModelText(
    String text, {
    int maxChars = 250,
    int firstChars = 80,
  }) {
    final sentences = text
        .split(RegExp(r'(?<=[.?!])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final chunks = <String>[];
    var cur = '';
    for (final s in sentences) {
      final limit = chunks.isEmpty ? firstChars : maxChars;
      if (cur.isNotEmpty && cur.length + 1 + s.length > limit) {
        chunks.add(cur);
        cur = s;
      } else {
        cur = cur.isEmpty ? s : '$cur $s';
      }
    }
    if (cur.isNotEmpty) chunks.add(cur);
    return chunks;
  }

  /// Uzun bir cümleyi (noktasız paragraf, madde listesi) modelin
  /// kaldırabileceği boya virgül/boşluktan böler. Tarayıcı portunda yok:
  /// orada metin kullanıcının yazdığı kısa örnekler; not uygulamasında
  /// noktasız yüzlerce karakterlik satırlar olağan ve tek parçada süre
  /// tavanı aşılıp ses bozuluyor.
  static List<String> capLength(String piece, {int maxChars = 250}) {
    if (piece.length <= maxChars) return [piece];
    final out = <String>[];
    var rest = piece;
    while (rest.length > maxChars) {
      var cut = rest.lastIndexOf(RegExp(r'[,;:] '), maxChars);
      if (cut > maxChars ~/ 3) {
        cut += 1; // noktalama parçada kalsın
      } else {
        cut = rest.lastIndexOf(' ', maxChars);
        if (cut <= maxChars ~/ 3) cut = maxChars;
      }
      out.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trim();
    }
    if (rest.isNotEmpty) out.add(rest);
    return out;
  }
}
