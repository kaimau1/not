/// AKILLI SESLİ NOT — dikte sırasında söylenen DÜZELTME KOMUTLARI ve
/// sessizlikte KENDİLİĞİNDEN BİTEN dinleme.
///
/// Kullanıcı isteği 2026-10-19: "not alırken 'son kelimeyi sil' desem onu
/// silse, 'şu kelime yanlış oldu değiştir' desem değiştirse, sonrasında en
/// sondan yazmaya devam etse" ve "sesli not oto sonlanmıyor, sürekli dinliyor;
/// akıllı dinleme olmalı".
///
/// **Neden her olayda BAŞTAN hesap**: tanıyıcı her olayda o ana kadarki TAM
/// metni gönderir ve sondaki kelimeleri sonradan düzeltebilir ("son kelimeyi"
/// → "son kelimeyi sil"). Komutu bir kez uygulayıp metni yerinde değiştirmek,
/// tanıyıcının bir sonraki (düzeltilmiş) olayıyla çelişirdi. Bunun yerine
/// [applyVoiceCommands] ham metni her seferinde baştan işler: aynı ham metin
/// her zaman aynı sonucu verir, yarım kalmış komut ("son kelimeyi") düz metin
/// görünür, tamamlanınca ("… sil") kendiliğinden uygulanır. Komuttan sonra
/// söylenenler metnin SONUNA eklenir — kullanıcının "en sondan devam" isteği.
library;

/// Uygulanan komutun türü (arayüzdeki kısa geri bildirim için).
enum VoiceCommand {
  deleteWords,
  deleteSentence,
  clearAll,
  replace,
  newLine,
  undo,
  stop,

  /// "virgül koy", "soru işareti" …
  punctuation,

  /// "başlık X olsun": notun başlığı (metne girmez).
  title,
}

/// [applyVoiceCommands] sonucu.
///
/// [commands] uygulanan komut SAYISI: arayüz yeni komutu bu sayının artışından
/// anlar (her olayda baştan hesaplandığı için "yeni mi" bilgisi başka yoldan
/// gelmez). [stop] "dinlemeyi bitir" söylendi demektir. [title] "başlık X
/// olsun" ile söylenen başlık (yoksa null; birden çok kez söylendiyse sonuncu).
typedef VoiceCommandOutcome = ({
  String text,
  int commands,
  VoiceCommand? last,
  bool stop,
  String? title,
});

/// Ham dökümdeki sesli komutları uygular, metnin temiz hâlini döndürür.
///
/// Segmentler (tanıyıcının duraklamada kestiği parçalar) `\n` ile gelir ve
/// korunur. Komut segmentin herhangi bir yerinde olabilir; öncesi metne
/// eklenir, komut uygulanır, sonrası devam eder.
///
/// [base] "Devam et" ile sürdürülen dinlemede ÖNCEKİ metin: yeni konuşma
/// onun sonuna (boşlukla) eklenir ve komutlar onu da düzenleyebilir ("son
/// kelimeyi sil" önceki metnin son kelimesini siler).
VoiceCommandOutcome applyVoiceCommands(String raw, {String base = ''}) {
  var out = base.trim();
  String? title;
  var first = true;
  final history = <String>[];
  var count = 0;
  var stop = false;
  VoiceCommand? last;

  // Segment sınırı (`\n`) TEMBEL eklenir: yalnız ardından gerçekten metin
  // gelirse. Yalnız komuttan oluşan bir segment metnin sonunda boş satır
  // bırakmasın.
  var pendingBreak = false;
  String appendText(String piece) {
    if (piece.trim().isEmpty) return out;
    final base = pendingBreak && out.isNotEmpty && !_endsWithSpace(out)
        ? '$out\n'
        : out;
    pendingBreak = false;
    return _append(base, _capitalizeAfterSentence(base, piece));
  }

  for (final segment in raw.split('\n')) {
    if (segment.trim().isEmpty) continue;
    // Önceki metnin (base) devamı ilk segmentte satır değil BOŞLUKLA eklenir.
    pendingBreak = out.isNotEmpty && !first;
    first = false;
    // "Geri al" gündelik dilde de geçer ("parayı geri al"); yalnız TEK BAŞINA
    // söylendiğinde (kendi segmenti) komuttur.
    if (_undoWhole.hasMatch(_lower(segment.trim()))) {
      if (history.isNotEmpty) out = history.removeLast();
      pendingBreak = false;
      count++;
      last = VoiceCommand.undo;
      continue;
    }
    var rest = segment;
    while (rest.trim().isNotEmpty) {
      final match = _firstCommand(rest, out);
      if (match == null) {
        out = appendText(rest);
        break;
      }
      final before = appendText(rest.substring(0, match.start));
      pendingBreak = false;
      if (match.kind != VoiceCommand.undo) history.add(before);
      out = match.kind == VoiceCommand.undo
          ? (history.isEmpty ? before : history.removeLast())
          : match.apply(before);
      count++;
      last = match.kind;
      if (match.kind == VoiceCommand.stop) stop = true;
      if (match.title != null) title = match.title;
      rest = rest.substring(match.end);
    }
  }
  return (text: out, commands: count, last: last, stop: stop, title: title);
}

// ——— Eşleştirme ————————————————————————————————————————————————

/// Kelime sınırları: Dart'ta `\b` yalnız ASCII bilir ("şeyi" içinde sınır
/// bulur), bu yüzden Unicode harf/rakam bakışlarıyla kurulur.
const _b = r'(?<![\p{L}\p{N}])';
const _e = r'(?![\p{L}\p{N}])';

/// Bir-dört kelimelik yeni metin (değiştirme komutlarının hedefi).
const _words = r"([\p{L}\p{N}'’]+(?:\s+[\p{L}\p{N}'’]+){0,3}?)";

RegExp _re(String pattern) =>
    RegExp(pattern, unicode: true, caseSensitive: false);

final _undoWhole = _re(r'^(?:son\s+işlemi\s+)?(?:geri\s+al|undo)[.!]?$');

final _deleteWords = [
  _re(
    '${_b}son\\s+(?:(\\d+|bir|iki|üç|dört|beş|altı|yedi|sekiz|dokuz|on)\\s+)?'
    '(?:kelime(?:yi|leri|ler)?|sözcü(?:ğü|kleri|k))\\s+sil(?:in|iniz)?$_e',
  ),
  _re(
    '$_b(?:delete|remove|erase)\\s+(?:the\\s+)?last\\s+'
    '(?:(\\d+|one|two|three|four|five)\\s+)?words?$_e',
  ),
];

final _deleteSentence = [
  _re('${_b}son\\s+(?:cümle(?:yi)?|satır(?:ı)?)\\s+sil(?:in|iniz)?$_e'),
  _re('$_b(?:delete|remove|erase)\\s+(?:the\\s+)?last\\s+(?:sentence|line)$_e'),
];

final _clearAll = [
  _re(
    '$_b(?:hepsini|tümünü|her\\s+şeyi|tamamını|bütün\\s+metni)\\s+'
    'sil(?:in|iniz)?$_e',
  ),
  _re('$_b(?:clear|delete|erase)\\s+(?:all|everything)$_e'),
];

final _undoInline = [
  _re('${_b}son\\s+işlemi\\s+geri\\s+al$_e'),
  _re('${_b}undo\\s+that$_e'),
];

final _newLine = [
  _re('$_b(?:yeni|alt)\\s+satır(?:a\\s+geç)?$_e'),
  _re('${_b}yeni\\s+paragraf$_e'),
  // Liste notunda her satır bir madde olur (bkz. dashboard asList).
  _re('$_b(?:yeni|sonraki)\\s+madde$_e'),
  _re('${_b}new\\s+(?:line|paragraph|item)$_e'),
  _re('${_b}next\\s+item$_e'),
];

/// NOKTALAMA: Android'in Türkçe tanıması noktalamada zayıf. Tek başına
/// "nokta"/"virgül" gündelik dilde geçer ("bu nokta önemli", "üç virgül
/// beş") — bu yüzden "… koy" ya da yalnız noktalamayı anlatan adlar.
final _punctuation = <(RegExp, String)>[
  (_re('${_b}noktalı\\s+virgül(?:\\s+koy)?$_e'), ';'),
  (_re('${_b}iki\\s+nokta\\s+üst\\s+üste(?:\\s+koy)?$_e'), ':'),
  (_re('${_b}nokta\\s+koy$_e'), '.'),
  (_re('${_b}virgül\\s+koy$_e'), ','),
  (_re('${_b}soru\\s+işareti(?:\\s+koy)?$_e'), '?'),
  (_re('$_bünlem\\s+işareti(?:\\s+koy)?$_e'), '!'),
  (_re('${_b}full\\s+stop$_e'), '.'),
  (_re('${_b}insert\\s+(?:a\\s+)?comma$_e'), ','),
  (_re('${_b}insert\\s+(?:a\\s+)?period$_e'), '.'),
  (_re('${_b}question\\s+mark$_e'), '?'),
  (_re('${_b}exclamation\\s+(?:mark|point)$_e'), '!'),
];

/// BAŞLIK: "başlık X olsun", "başlığı X yap", "set the title to X". Grup 1
/// başlık (en çok 8 kelime).
const _titleWords = r"([\p{L}\p{N}'’]+(?:\s+[\p{L}\p{N}'’]+){0,7}?)";
final _title = [
  _re('${_b}başlık\\s+$_titleWords\\s+olsun$_e'),
  _re('${_b}başlığı\\s+$_titleWords\\s+(?:yap|olarak\\s+ayarla)$_e'),
  _re(
    '${_b}set\\s+(?:the\\s+)?title\\s+to\\s+'
    "([\\p{L}\\p{N}'’]+(?:\\s+[\\p{L}\\p{N}'’]+){0,7})",
  ),
];

final _stop = [
  _re('$_b(?:dinlemeyi|kaydı|kayıt)\\s+(?:bitir|durdur|kapat)$_e'),
  _re('${_b}stop\\s+(?:listening|recording)$_e'),
];

/// "son kelimeyi X ile değiştir", "son kelime X olacak", "change the last
/// word to X" — grup 1 yeni metin.
final _replaceLast = [
  _re(
    '${_b}son\\s+(?:kelime(?:yi)?|sözcü(?:ğü|k))\\s+(?:yanlış\\s+)?$_words'
    '\\s+(?:ile|olarak)\\s+değiştir(?:in)?$_e',
  ),
  _re(
    '${_b}son\\s+(?:kelime|sözcük)\\s+(?:yanlış(?:\\s+oldu)?\\s+)?$_words'
    '\\s+(?:olacak|olsun|olmalı)$_e',
  ),
  _re(
    '$_b(?:change|replace)\\s+(?:the\\s+)?last\\s+word\\s+(?:to|with)\\s+'
    "([\\p{L}\\p{N}'’]+(?:\\s+[\\p{L}\\p{N}'’]+){0,3})",
  ),
];

/// ESKİ metin komut kelimesinden ÖNCE söylenenler: "markete yerine pazara
/// yaz", "markete kelimesini pazara ile değiştir", "markete yanlış oldu
/// pazara olacak", "markete'yi pazara ile değiştir". Grup 1 yeni metin; eski
/// metin eşleşmenin SOLUNDAKİ kelimelerden seçilir (bkz. [_pickOld]).
final _replaceAfterOld = [
  _re('${_b}yerine\\s+$_words\\s+(?:yaz|koy|olsun|olacak)$_e'),
  _re(
    '$_b(?:kelimesini|sözcüğünü)\\s+$_words\\s+(?:ile|olarak)\\s+'
    'değiştir(?:in)?$_e',
  ),
  _re('${_b}yanlış(?:\\s+oldu)?\\s+$_words\\s+(?:olacak|olsun|olmalı)$_e'),
  // En genel biçim EN SONDA: "X'i Y ile değiştir" — Y tek kelime, X onun
  // solunda (ek düşürülerek aranır).
  _re("$_b([\\p{L}\\p{N}'’]+)\\s+(?:ile|olarak)\\s+değiştir(?:in)?$_e"),
];

/// İngilizce: eski metin komuttan SONRA ("replace X with Y", "change X to Y").
final _replaceEnglish = _re(
  "$_b(?:replace|change)\\s+([\\p{L}\\p{N}'’]+(?:\\s+[\\p{L}\\p{N}'’]+){0,2}?)"
  "\\s+(?:with|to)\\s+([\\p{L}\\p{N}'’]+(?:\\s+[\\p{L}\\p{N}'’]+){0,3})",
);

class _Match {
  _Match(this.start, this.end, this.kind, this.apply, {this.title});

  final int start;
  final int end;
  final VoiceCommand kind;
  final String Function(String out) apply;

  /// Yalnız [VoiceCommand.title]: söylenen başlık.
  final String? title;
}

/// [rest] içindeki EN SOLDAKİ komut. [out] o ana kadarki metin — eski kelimeyi
/// soldan seçerken "metinde var mı" sorusu için gerekir.
_Match? _firstCommand(String rest, String out) {
  final lower = _lower(rest);
  _Match? best;
  void consider(_Match? m) {
    if (m == null) return;
    if (best == null || m.start < best!.start) best = m;
  }

  int endOf(RegExpMatch m) => _swallowPunctuation(rest, m.end);

  for (final re in _deleteWords) {
    final m = re.firstMatch(lower);
    if (m == null) continue;
    final n = _number(m.group(1)) ?? 1;
    consider(
      _Match(m.start, endOf(m), VoiceCommand.deleteWords, (o) {
        return _deleteLastWords(o, n);
      }),
    );
  }
  for (final re in _deleteSentence) {
    final m = re.firstMatch(lower);
    if (m != null) {
      consider(
        _Match(
          m.start,
          endOf(m),
          VoiceCommand.deleteSentence,
          _deleteSentenceOf,
        ),
      );
    }
  }
  for (final re in _clearAll) {
    final m = re.firstMatch(lower);
    if (m != null) {
      consider(_Match(m.start, endOf(m), VoiceCommand.clearAll, (_) => ''));
    }
  }
  for (final re in _undoInline) {
    final m = re.firstMatch(lower);
    if (m != null) {
      consider(_Match(m.start, endOf(m), VoiceCommand.undo, (o) => o));
    }
  }
  for (final re in _newLine) {
    final m = re.firstMatch(lower);
    if (m != null) {
      consider(
        _Match(m.start, endOf(m), VoiceCommand.newLine, (o) {
          final t = o.trimRight();
          return t.isEmpty ? '' : '$t\n';
        }),
      );
    }
  }
  for (final (re, mark) in _punctuation) {
    final m = re.firstMatch(lower);
    if (m != null) {
      consider(
        _Match(m.start, m.end, VoiceCommand.punctuation, (o) {
          // Sondaki noktalama yenisiyle DEĞİŞİR ("." söylenip "?" denirse).
          final t = o.trimRight().replaceFirst(RegExp(r'[.,;:!?…]+$'), '');
          return t.isEmpty ? '' : '$t$mark';
        }),
      );
    }
  }
  for (var i = 0; i < _title.length; i++) {
    final m = _title[i].firstMatch(lower);
    if (m == null) continue;
    final title = _capitalizeFirst(
      _original(rest, m, 1, atEnd: i == _title.length - 1),
    );
    consider(
      _Match(m.start, endOf(m), VoiceCommand.title, (o) => o, title: title),
    );
  }
  for (final re in _stop) {
    final m = re.firstMatch(lower);
    if (m != null) {
      consider(_Match(m.start, endOf(m), VoiceCommand.stop, (o) => o));
    }
  }
  for (final re in _replaceLast) {
    final m = re.firstMatch(lower);
    if (m == null) continue;
    final next = _original(rest, m, 1);
    consider(
      _Match(m.start, endOf(m), VoiceCommand.replace, (o) {
        return _replaceLastWord(o, next);
      }),
    );
  }
  for (final re in _replaceAfterOld) {
    final m = re.firstMatch(lower);
    if (m == null) continue;
    final next = _original(rest, m, 1);
    final picked = _pickOld(rest.substring(0, m.start), out);
    if (picked == null) continue;
    consider(
      _Match(picked.start, endOf(m), VoiceCommand.replace, (o) {
        return _replaceLastOccurrence(o, picked.old, next);
      }),
    );
  }
  final en = _replaceEnglish.firstMatch(lower);
  if (en != null) {
    final old = _original(rest, en, 1);
    final next = _original(rest, en, 2, atEnd: true);
    consider(
      _Match(en.start, endOf(en), VoiceCommand.replace, (o) {
        return _replaceLastOccurrence(o, old, next);
      }),
    );
  }
  return best;
}

/// Grup [group]'un ÖZGÜN (büyük/küçük harfi korunmuş) metni. Eşleşme
/// küçük harfli kopyada yapılır ve Dart grupların konumunu vermez; kopya
/// özgünle aynı uzunlukta olduğundan grup, eşleşmenin içinde aranıp aynı
/// konumdan okunur. [atEnd]: grup eşleşmenin sonundadır (açgözlü kuyruk).
String _original(String rest, RegExpMatch m, int group, {bool atEnd = false}) {
  final whole = m.group(0)!;
  final g = m.group(group)!;
  final offset = atEnd ? whole.length - g.length : whole.indexOf(g);
  final start = m.start + (offset < 0 ? 0 : offset);
  return rest.substring(start, start + g.length);
}

/// Komut kelimesinin SOLUNDAN eski metni seçer: son 3, 2, 1 kelimeden
/// metinde GEÇEN en uzunu (ek düşürülmüş hâli de denenir — "markete'yi" →
/// "markete"). Hiçbiri geçmiyorsa null: o hâlde söylenen büyük olasılıkla
/// komut değil, gündelik cümledir ("çay yerine kahve olsun") ve dokunulmaz.
({int start, String old})? _pickOld(String before, String out) {
  final words = RegExp(r'\S+').allMatches(before).toList();
  if (words.isEmpty) return null;
  for (var n = words.length < 3 ? words.length : 3; n >= 1; n--) {
    final first = words[words.length - n];
    final candidate = _stripPunctuation(
      before.substring(first.start, words.last.end),
    );
    if (candidate.isEmpty) continue;
    // Eski metin, aynı segmentte komuttan önce söylenen metinde de olabilir.
    final context = _append(out, before.substring(0, first.start));
    for (final form in _forms(candidate)) {
      if (_lastIndexOfWord(context, form) >= 0) {
        return (start: first.start, old: form);
      }
    }
  }
  return null;
}

/// Eski kelimenin aranacak biçimleri: kendisi, kesme işaretinden öncesi ve
/// belirtme eki düşmüş hâli ("pazarı" → "pazar").
List<String> _forms(String word) {
  final forms = <String>[word];
  final apostrophe = word.indexOf(RegExp("['’]"));
  if (apostrophe > 0) forms.add(word.substring(0, apostrophe));
  final suffix = RegExp(r'(?:y|n)?[ıiuü]$', unicode: true);
  if (!word.contains(' ') && word.length > 3 && suffix.hasMatch(word)) {
    forms.add(word.replaceFirst(suffix, ''));
  }
  return forms;
}

// ——— Düzenlemeler ————————————————————————————————————————————————

String _deleteLastWords(String out, int n) {
  var t = out.trimRight();
  for (var i = 0; i < n && t.isNotEmpty; i++) {
    t = t.replaceFirst(RegExp(r'\S+$'), '').trimRight();
  }
  return t;
}

String _deleteSentenceOf(String out) {
  final t = out.trimRight().replaceFirst(RegExp(r'[.!?…]+$'), '');
  var cut = -1;
  for (final mark in const ['.', '!', '?', '…', '\n']) {
    final i = t.lastIndexOf(mark);
    if (i > cut) cut = i;
  }
  return cut < 0 ? '' : t.substring(0, cut + 1).trimRight();
}

String _replaceLastWord(String out, String next) {
  final t = out.trimRight();
  final m = RegExp(r'\S+$').firstMatch(t);
  if (m == null) return out;
  // Sondaki noktalama kelimeye ait değil: korunur.
  final word = m.group(0)!;
  final tail = RegExp(r'[.,!?;:…]+$').firstMatch(word)?.group(0) ?? '';
  return '${t.substring(0, m.start)}$next$tail';
}

String _replaceLastOccurrence(String out, String old, String next) {
  final i = _lastIndexOfWord(out, old);
  if (i < 0) return out;
  return out.replaceRange(i, i + old.length, next);
}

/// [needle]'ın [haystack]'te KELİME OLARAK son geçtiği yer (büyük/küçük harf
/// duyarsız); yoksa -1.
int _lastIndexOfWord(String haystack, String needle) {
  if (needle.isEmpty) return -1;
  final re = _re('$_b${RegExp.escape(_lower(needle))}$_e');
  final matches = re.allMatches(_lower(haystack));
  return matches.isEmpty ? -1 : matches.last.start;
}

// ——— Yardımcılar ————————————————————————————————————————————————

/// Cümle sonundan (. ! ?) sonra gelen parçanın ilk harfi büyür.
String _capitalizeAfterSentence(String out, String piece) {
  final t = out.trimRight();
  if (t.isEmpty || !'.!?'.contains(t[t.length - 1])) return piece;
  return _capitalizeFirst(piece);
}

/// İlk harfi Türkçe kurala göre büyütür (i → İ, ı → I).
String _capitalizeFirst(String s) {
  final i = s.indexOf(RegExp(r'\S'));
  if (i < 0) return s;
  final c = s[i];
  final upper = switch (c) {
    'i' => 'İ',
    'ı' => 'I',
    _ => c.toUpperCase(),
  };
  return '${s.substring(0, i)}$upper${s.substring(i + 1)}';
}

/// Parçayı metne ekler: gerekiyorsa araya tek boşluk.
String _append(String out, String piece) {
  final p = piece.trim();
  if (p.isEmpty) return out;
  if (out.isEmpty || _endsWithSpace(out)) return '$out$p';
  return '$out $p';
}

bool _endsWithSpace(String s) =>
    s.isNotEmpty && s.trimRight().length < s.length;

/// Komutun hemen ardındaki noktalama (tanıyıcının koyduğu ".") da yutulur;
/// yoksa metnin sonunda sahipsiz bir nokta kalırdı.
int _swallowPunctuation(String s, int end) {
  var i = end;
  while (i < s.length && '.,!?;:…'.contains(s[i])) {
    i++;
  }
  return i;
}

String _stripPunctuation(String s) =>
    s.replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[.,!?;:…"“”]+$', unicode: true), '');

int? _number(String? word) {
  if (word == null) return null;
  final digits = int.tryParse(word);
  if (digits != null) return digits.clamp(1, 50);
  const names = {
    'bir': 1, 'iki': 2, 'üç': 3, 'dört': 4, 'beş': 5, 'altı': 6, //
    'yedi': 7, 'sekiz': 8, 'dokuz': 9, 'on': 10,
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
  };
  return names[word];
}

/// Türkçe küçük harf, UZUNLUĞU KORUYARAK: eşleşme konumları özgün metne
/// birebir taşınır. (`'İ'.toLowerCase()` iki karakter üretir — "i̇" — ve
/// konumları kaydırırdı.)
String _lower(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final l = switch (c) {
      'İ' => 'i',
      'I' => 'ı',
      _ => c.toLowerCase(),
    };
    b.write(l.length == c.length ? l : c);
  }
  return b.toString();
}

/// AKILLI DİNLEME — sessizlikte kendiliğinden biten dinleme.
///
/// KÖK NEDEN (kullanıcı: "sesli not akışı oto sonlanmıyor, sürekli dinlemeye
/// devam ediyor"): levha yalnız "Bitir"e basılınca ya da 10 dakika dolunca
/// duruyordu; yerli tanıyıcı her sessizlikte kendini yeniden başlattığından
/// (bkz. MainActivity.restartRecognizer) konuşma bitse de mikrofon açık
/// kalıyordu. Kapı, konuşmanın İLERLEDİĞİNİ izler: yeni metin (ya da kayıt
/// yolunda yüksek ses) geldikçe saat sıfırlanır; [afterSpeech] boyunca
/// ilerleme olmazsa dinleme biter. Hiç konuşulmadıysa [noSpeech] sonra.
///
/// Ses seviyesi tek başına güvenilmez (ortam gürültüsü): seviye saati yalnız
/// son METİNDEN sonraki [levelGrace] içinde uzatabilir — gürültülü odada
/// dinleme sonsuza dek sürmesin.
class SilenceGate {
  SilenceGate({
    this.afterSpeech = const Duration(seconds: 4),
    this.noSpeech = const Duration(seconds: 12),
    this.levelGrace = const Duration(seconds: 8),
    this.loudLevel = 0.5,
  });

  final Duration afterSpeech;
  final Duration noSpeech;
  final Duration levelGrace;

  /// 0–1 seviyesinde "konuşuyor" sayılan eşik.
  final double loudLevel;

  DateTime? _startedAt;
  DateTime? _lastSpeech;
  DateTime? _lastLoud;

  /// En az bir kez konuşma algılandı mı.
  bool get heard => _lastSpeech != null;

  void start(DateTime now) {
    _startedAt = now;
    _lastSpeech = null;
    _lastLoud = null;
  }

  /// Kesin konuşma kanıtı: yeni metin geldi (ya da kayıt yolunda yüksek ses).
  void onSpeech(DateTime now) => _lastSpeech = now;

  /// Ses seviyesi (0–1).
  void onLevel(double level, DateTime now) {
    if (level >= loudLevel) _lastLoud = now;
  }

  /// Sessizliğin bitişe oranı (0–1): arayüz geri sayım şeridi için.
  double progress(DateTime now) {
    final started = _startedAt;
    if (started == null) return 0;
    final last = _lastSpeech;
    if (last == null) {
      return (now.difference(started).inMilliseconds / noSpeech.inMilliseconds)
          .clamp(0.0, 1.0);
    }
    var anchor = last;
    final loud = _lastLoud;
    if (loud != null &&
        loud.isAfter(anchor) &&
        loud.difference(last) <= levelGrace) {
      anchor = loud;
    }
    return (now.difference(anchor).inMilliseconds / afterSpeech.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  bool shouldStop(DateTime now) => progress(now) >= 1;
}
