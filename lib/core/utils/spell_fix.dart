/// **AI'SIZ TÜRKÇE YAZIM DÜZELTME** (kullanıcı isteği 2026-11-08): saf
/// kurallar — sözlük yok. Cihazın yazım denetçisi (Android) bunun üstüne
/// kelime önerisi verir (bkz. `auto_spell.dart`).
///
/// * Sık yazım hataları ([_common]): "herşey" → "her şey", "yanlız" →
///   "yalnız", "tabiki" → "tabii ki"…
/// * Konuşma ağzı "-yo" → "-yor" ("geliyo" → "geliyor").
/// * Bitişik soru eki ayrılır ("gelirmisin" → "gelir misin").
/// * Cümle başı büyük harf (Türkçe i → İ).
/// * Noktalamadan önceki boşluk silinir ("kelime ," → "kelime,").
library;

/// Türkçe büyük harf (i → İ, ı → I).
String trUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

String _trCapitalize(String w) =>
    w.isEmpty ? w : trUpper(w.substring(0, 1)) + w.substring(1);

const _common = <String, String>{
  'herşey': 'her şey',
  'birşey': 'bir şey',
  'hiçbirşey': 'hiçbir şey',
  'birsürü': 'bir sürü',
  'hergün': 'her gün',
  'birgün': 'bir gün',
  'herzaman': 'her zaman',
  'herkez': 'herkes',
  'pekçok': 'pek çok',
  'birkez': 'bir kez',
  'yada': 'ya da',
  'yinede': 'yine de',
  'şuan': 'şu an',
  'şuanda': 'şu anda',
  'yanlız': 'yalnız',
  'yalnış': 'yanlış',
  'malesef': 'maalesef',
  'maalesefki': 'maalesef ki',
  'tabiki': 'tabii ki',
  'orjinal': 'orijinal',
  'deyil': 'değil',
  'diil': 'değil',
  'eşortman': 'eşofman',
  'yapıcam': 'yapacağım',
  'gelicem': 'geleceğim',
  'gidicem': 'gideceğim',
  'edicem': 'edeceğim',
  'bakıcam': 'bakacağım',
  'alıcam': 'alacağım',
  'napıyorsun': 'ne yapıyorsun',
  'tşk': 'teşekkürler',
  'tşkler': 'teşekkürler',
  'slm': 'selam',
  'mrb': 'merhaba',
  'klavuz': 'kılavuz',
  'süpriz': 'sürpriz',
  'sürpiz': 'sürpriz',
  'herhalde': 'herhâlde',
  'yanlızca': 'yalnızca',
  'antreman': 'antrenman',
  'ünvan': 'unvan',
  'traş': 'tıraş',
  'meyva': 'meyve',
  'kiprik': 'kirpik',
  'hoşçakal': 'hoşça kal',
};

const _questionSuffixes = [
  'misiniz', 'mısınız', 'musunuz', 'müsünüz', //
  'miyiz', 'mıyız', 'muyuz', 'müyüz', //
  'misin', 'mısın', 'musun', 'müsün', //
  'miyim', 'mıyım', 'muyum', 'müyüm', //
  'midir', 'mıdır', 'mudur', 'müdür',
];

final _letters = RegExp(r'[\p{L}]+$', unicode: true);

/// Tek kelimenin düzeltilmiş hâli (değişiklik yoksa aynısı). Büyük harfle
/// başlayan kelimenin baş harfi korunur; tamamı büyükse dokunulmaz (kısaltma).
String fixTurkishWord(String word) {
  if (word.length < 2 || trUpper(word) == word) return word;
  final cap = word[0] != word[0].toLowerCase();
  var w = cap ? word[0].toLowerCase() + word.substring(1) : word;
  final common = _common[w];
  if (common != null) {
    w = common;
  } else if (RegExp(r'(iyo|ıyo|uyo|üyo)$').hasMatch(w) && w.length > 4) {
    w = '${w}r';
  } else {
    for (final s in _questionSuffixes) {
      if (w.length >= s.length + 3 && w.endsWith(s)) {
        w = '${w.substring(0, w.length - s.length)} $s';
        break;
      }
    }
  }
  return cap ? _trCapitalize(w) : w;
}

/// Cümle başı mı: [start] öncesinde yalnız boşluk varsa ve ondan önce satır
/// başı ya da . ! ? geliyorsa.
bool _sentenceStart(String text, int start) {
  var i = start - 1;
  while (i >= 0 && text[i] == ' ') {
    i--;
  }
  if (i < 0) return true;
  return '\n.!?'.contains(text[i]);
}

/// Kullanıcı [caret]'ten hemen önce bir sınır karakteri (boşluk, noktalama,
/// satır sonu) yazdı: önündeki kelime ve noktalama düzeltilir. Değişiklik
/// yoksa null; varsa [start, end) aralığı [text] ile değişir.
({int start, int end, String text})? spellFixAt(String text, int caret) {
  if (caret < 2 || caret > text.length) return null;
  final boundary = text[caret - 1];
  if (!' \n.,;:!?'.contains(boundary)) return null;
  // "kelime ," → "kelime,"
  var spaceBefore = false;
  var wordEnd = caret - 1;
  if (',.;:!?'.contains(boundary) && text[caret - 2] == ' ') {
    spaceBefore = true;
    wordEnd = caret - 2;
  }
  final m = _letters.firstMatch(text.substring(0, wordEnd));
  if (m == null) {
    return spaceBefore
        ? (start: caret - 2, end: caret, text: boundary)
        : null;
  }
  final start = m.start;
  // Bağlantı, e-posta, sayıya yapışık kelime: dokunma (önünde boşluk, satır
  // başı, açılan tırnak/parantez ya da biçim işareti olmalı).
  final before = start == 0 ? ' ' : text[start - 1];
  if (!' \n("\'«“*_~='.contains(before)) {
    return spaceBefore
        ? (start: caret - 2, end: caret, text: boundary)
        : null;
  }
  final word = m.group(0)!;
  var fixed = fixTurkishWord(word);
  if (_sentenceStart(text, start)) fixed = _trCapitalize(fixed);
  if (fixed == word && !spaceBefore) return null;
  return (start: start, end: caret, text: fixed + boundary);
}

/// Satır/madde bitti (Enter, yeni madde): baş harf büyük, en az üç kelimelik
/// ve harfle biten satırın sonuna nokta.
String finalizeLine(String line) {
  final t = line.trimRight();
  if (t.isEmpty) return line;
  var out = t;
  final lead = RegExp(r'^(\s*)([\p{Ll}])', unicode: true).firstMatch(out);
  if (lead != null) {
    out = out.replaceRange(lead.start + lead.group(1)!.length, lead.end,
        trUpper(lead.group(2)!));
  }
  final words = out.trim().split(RegExp(r'\s+')).length;
  if (words >= 3 && RegExp(r'\p{L}$', unicode: true).hasMatch(out)) {
    out = '$out.';
  }
  return out + line.substring(t.length);
}
