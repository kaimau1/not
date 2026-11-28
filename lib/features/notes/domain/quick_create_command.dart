/// **HIZLI EKLE NİYETİ — "YENİ LİSTE / NOT OLUŞTUR"** (kullanıcı bulgusu
/// 2026-11-28: "Yeni bir alışveriş listesi oluştur ve en başa koy. Eee oraya
/// da elma armut peynir ekmek" dedim; yeni liste açmadı, iki cümleyi başka bir
/// notun maddesi yaptı).
///
/// KÖK NEDEN: hızlı ekle yalnız iki noktalı yazımı tanıyordu (`yeni bavul
/// listesi: pasaport` — [parseNewSmartListCommand]); konuşmada iki nokta
/// olmadığından komut İÇERİK sanılıp en yakın nota yönlendiriliyordu.
///
/// Bu dosya cihazda, kurallı (0 kredi) iki niyeti çözer:
/// * [parseCreateNoteCommand] — `yeni (bir) <tür> listesi oluştur/aç/yap`,
///   "yeni not oluştur", "create a new shopping list"; ardından gelen
///   "en başa koy / sabitle" ([QuickCreateCommand.pin]) ve "oraya da …"
///   içeriği ayrılır.
/// * [parseDeicticAdd] — ayrı söylenen "oraya da elma armut" / "aynı listeye
///   süt": hedef SON eklenen nottur (çağıran bilir).
///
/// Saf Dart; testler `test/quick_create_command_test.dart`.
library;

import 'package:flutter/foundation.dart';

import '../../../core/utils/spoken_datetime.dart'
    show parseSpokenDateTimeWithSpan;

import 'quick_entry.dart';
import 'smart_list.dart';

/// Çözülmüş "yeni not/liste" komutu.
@immutable
class QuickCreateCommand {
  const QuickCreateCommand({
    required this.list,
    this.kind,
    this.title = '',
    this.pin = false,
    this.content = '',
  });

  /// Liste (işaretli maddeler) mi, yazı notu mu.
  final bool list;

  /// Tanınan akıllı liste türü ("alışveriş" → market). null: tür yok.
  final SmartListKind? kind;

  /// Tür tanınmadıysa söylenen ad ("Antalya listesi"); boş = türün adı ya da
  /// başlıksız.
  final String title;

  /// "En başa koy / sabitle" — not sabitlenir (listenin en üstünde durur).
  final bool pin;

  /// Yeni nota yazılacak içerik (doldurma sözleri ve komut atılmış).
  final String content;

  @override
  bool operator ==(Object other) =>
      other is QuickCreateCommand &&
      other.list == list &&
      other.kind == kind &&
      other.title == title &&
      other.pin == pin &&
      other.content == content;

  @override
  int get hashCode => Object.hash(list, kind, title, pin, content);
}

typedef _W = ({String w, int start, int end});

final _wordRe = RegExp(r'''[^\s,;:.!?]+''');

List<_W> _words(String text) => [
  for (final m in _wordRe.allMatches(text))
    (
      w: quickAscii(m.group(0)!).replaceAll("'", '').replaceAll('’', ''),
      start: m.start,
      end: m.end,
    ),
];

/// Güçlü oluşturma fiilleri: "yeni" olmadan da komuttur ("alışveriş listesi
/// oluştur").
///
/// Yalnız İSTEK kipleri: "oluşturma"/"oluşturmak" (ad) komut değildir —
/// "yeni liste oluşturma özelliği" bir fikir notudur.
bool _strongVerb(String w) => const {
  'olustur',
  'olusturur',
  'olusturalim',
  'olusturun',
  'olustursana',
  'olusturabilir',
  'olusturuver',
  'olusturulsun',
  'olusturmani',
  'hazirla',
  'hazirlar',
  'hazirlayalim',
  'hazirlayin',
  'hazirlasana',
  'hazirlayabilir',
  'baslat',
  'baslatir',
  'baslatalim',
  'baslatin',
  'create',
  'make',
  'start',
}.contains(w);

/// Fiilden sonra gelince cümle bir ÖZELLİK anlatır, komut değildir ("yeni
/// liste oluştur butonu").
const _featureWords = {
  'ozelligi',
  'ozellik',
  'butonu',
  'dugmesi',
  'secenegi',
  'fonksiyonu',
  'islevi',
  'sayfasi',
  'ekrani',
  'modu',
  'hatasi',
  'sorunu',
  'menusu',
  'button',
  'feature',
  'option',
};

/// Zayıf fiiller ("aç", "yap"): yalnız "yeni" ya da tanınan türle komuttur
/// ("kapıyı aç" komut değil).
bool _weakVerb(String w) => const {
  'ac',
  'acar',
  'acin',
  'acalim',
  'acsana',
  'acabilir',
  'yap',
  'yapar',
  'yapin',
  'yapalim',
  'yapsana',
  'open',
  'kur',
}.contains(w);

const _listNouns = {
  'liste',
  'listesi',
  'listem',
  'listemi',
  'listeyi',
  'listesini',
  'listemizi',
  'list',
  'checklist',
};

const _noteNouns = {'not', 'notu', 'notunu', 'note'};

/// "X yeni listeye ekle": yönelme ekli ad + ekle ailesi.
const _dativeListNouns = {'listeye', 'listesine', 'listeme'};
const _dativeNoteNouns = {'nota', 'notuna', 'notuma'};

bool _addVerb(String w) =>
    w.startsWith('ekle') ||
    const {'koy', 'yaz', 'kaydet', 'add', 'put'}.contains(w);

/// Komut öbeğinin içinde ad olmayan kelimeler.
const _headSkip = {'bir', 'tane', 'yeni', 'a', 'an', 'new', 'my', 'the'};

/// Öbeği sınırlayan bağlaçlar (öncesi içeriktir).
const _boundary = {
  've',
  'sonra',
  'ardindan',
  'simdi',
  'lutfen',
  'bana',
  'hemen',
  'and',
  'then',
  'please',
  'now',
};

/// Konuşmanın doldurma sesleri ("eee", "ııı", "hmm").
final _fillerRe = RegExp(r'^(?:e{2,}h?|i{2,}|a{3,}|h?m{2,}|eh+|uh+|um+)$');

/// İçeriğin BAŞINDA atılan bağlaç/gönderme sözleri.
const _leadDrop = {
  've',
  'sonra',
  'ardindan',
  'da',
  'de',
  'ta',
  'te',
  'sey',
  'yani',
  'oraya',
  'buraya',
  'ona',
  'buna',
  'icine',
  'icerisine',
  'iceri',
  'onun',
  'bunun',
  'sunlari',
  'sunu',
  'bunlari',
  'bunu',
  'olarak',
  'ile',
  'ekle',
  'ekleyelim',
  'maddeler',
  'maddeleri',
  'and',
  'then',
  'add',
  'with',
  'it',
  'to',
  'there',
  'also',
  'plus',
  'items',
};

/// İçeriğin SONUNDA atılan fiiller ("… ekle", "… olsun").
bool _tailDrop(String w) =>
    w.startsWith('ekle') ||
    const {
      'koy',
      'yaz',
      'olsun',
      'lutfen',
      'please',
      'misin',
      'musun',
      'there',
      'it',
      've',
      'and',
      'sonra',
      'then',
    }.contains(w);

/// "En başa koy / sabitle / to the top" öbeklerinin kelime aralıkları
/// ([words] dizinleri, uçlar dahil).
List<(int, int)> _pinSpans(List<_W> words) {
  final out = <(int, int)>[];
  const verbs = {
    'koy',
    'al',
    'tasi',
    'getir',
    'yerlestir',
    'sabitle',
    'ekle',
    'olsun',
    'dursun',
    'tut',
  };
  bool verbLike(String w) =>
      verbs.contains(w) ||
      w.startsWith('koy') ||
      w == 'sabitle' ||
      w.startsWith('tasi') ||
      w.startsWith('getir');
  for (var i = 0; i < words.length; i++) {
    final w = words[i].w;
    if (const {
      'sabitle',
      'sabitler',
      'sabitleyelim',
      'sabitlesene',
      'sabitleyin',
      'sabitlensin',
      'pinle',
    }.contains(w)) {
      out.add((i, i));
      continue;
    }
    if ((w == 'basa' || w == 'uste' || w == 'tepeye' || w == 'baslara') &&
        i + 1 < words.length &&
        verbLike(words[i + 1].w)) {
      final start = i > 0 && words[i - 1].w == 'en' ? i - 1 : i;
      out.add((start, i + 1));
      i++;
      continue;
    }
    if ((w == 'basta' || w == 'ustte') &&
        i > 0 &&
        words[i - 1].w == 'en' &&
        i + 1 < words.length &&
        verbLike(words[i + 1].w)) {
      out.add((i - 1, i + 1));
      i++;
      continue;
    }
    if (w == 'pin') {
      final end = i + 1 < words.length && words[i + 1].w == 'it' ? i + 1 : i;
      out.add((i, end));
      continue;
    }
    if ((w == 'to' || w == 'at') &&
        i + 2 < words.length &&
        words[i + 1].w == 'the' &&
        words[i + 2].w == 'top') {
      out.add((i, i + 2));
      i += 2;
    }
  }
  return out;
}

/// [text] içinden [keep] dizinli kelimeleri bırakıp gerisini atar; virgüller
/// (kesin madde ayırıcı) korunur.
String _rebuild(String text, List<_W> words, Set<int> drop) {
  if (words.isEmpty) return '';
  final b = StringBuffer();
  var cursor = 0;
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final gap = text.substring(cursor, w.start);
    b.write(gap);
    b.write(drop.contains(i) ? ' ' : text.substring(w.start, w.end));
    cursor = w.end;
  }
  b.write(text.substring(cursor));
  return b
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAllMapped(RegExp(r'\s+([,;])'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'([,;])(?:\s*[,;])+'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'^[\s,;:.!?-]+|[\s,;:.!?-]+$'), '')
      .trim();
}

/// [from]..[to) aralığındaki içerik: baştaki bağlaç/gönderme ve sondaki
/// fiil kelimeleri, doldurma sesleri ve [extraDrop] atılır.
String _contentOf(
  String text,
  List<_W> words,
  int from,
  int to,
  Set<int> extraDrop,
) {
  if (from >= to) return '';
  final drop = <int>{
    for (var i = 0; i < words.length; i++)
      if (i < from || i >= to) i,
    ...extraDrop,
  };
  for (var i = from; i < to; i++) {
    if (_fillerRe.hasMatch(words[i].w)) drop.add(i);
  }
  // Baştaki bağlaçlar.
  for (var i = from; i < to; i++) {
    if (drop.contains(i)) continue;
    if (_leadDrop.contains(words[i].w)) {
      drop.add(i);
      continue;
    }
    break;
  }
  // Sondaki fiiller.
  for (var i = to - 1; i >= from; i--) {
    if (drop.contains(i)) continue;
    if (_tailDrop(words[i].w)) {
      drop.add(i);
      continue;
    }
    break;
  }
  if (drop.length >= words.length) return '';
  return _rebuild(text, words, drop);
}

/// Söylenen ad ("alışveriş", "Antalya") → tür ya da başlık.
({SmartListKind? kind, String title}) _kindOrTitle(
  String text,
  List<_W> words,
  List<int> head,
  bool list,
) {
  if (head.isEmpty) return (kind: null, title: '');
  final phrase = text.substring(words[head.first].start, words[head.last].end);
  if (list) {
    final kind =
        smartKindFromPhrase('$phrase listesi') ?? smartKindFromPhrase(phrase);
    if (kind != null && kind != SmartListKind.generic) {
      return (kind: kind, title: '');
    }
    final isEn = words.any((w) => w.w == 'list' || w.w == 'checklist');
    return (
      kind: null,
      title: quickCapitalize(isEn ? '$phrase list' : '$phrase listesi'),
    );
  }
  return (kind: null, title: quickCapitalize(phrase));
}

/// `Yeni (bir) <tür> listesi oluştur …` komutu; komut yoksa null.
///
/// Örnekler: "yeni bir alışveriş listesi oluştur ve en başa koy eee oraya da
/// elma armut" → market, pin, "elma armut"; "yeni not oluştur: yarın ara" →
/// yazı notu; "süt ekmek yeni bir listeye ekle" → düz liste, "süt ekmek";
/// "create a new shopping list with milk and eggs".
QuickCreateCommand? parseCreateNoteCommand(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final words = _words(text);
  if (words.length < 2) return null;
  final pins = _pinSpans(words);
  final pinIdx = <int>{
    for (final (a, b) in pins)
      for (var i = a; i <= b; i++) i,
  };

  // ── Türkçe: [yeni] [bir] <ad…> LİSTESİ|NOT  OLUŞTUR ────────────────────
  for (var v = 1; v < words.length; v++) {
    final verb = words[v].w;
    final strong = _strongVerb(verb);
    final weak = !strong && _weakVerb(verb);
    final dativeAdd = _addVerb(verb);
    if (!strong && !weak && !dativeAdd) continue;
    final noun = words[v - 1].w;
    final isList = _listNouns.contains(noun);
    final isNote = _noteNouns.contains(noun);
    final isDative =
        _dativeListNouns.contains(noun) || _dativeNoteNouns.contains(noun);
    if (dativeAdd && !isDative) continue;
    if (!dativeAdd && !isList && !isNote) continue;
    if (v + 1 < words.length && _featureWords.contains(words[v + 1].w)) {
      continue;
    }
    // Öbeğin başı: "yeni"ye ya da bağlaca kadar en çok 4 kelime geri.
    var s = v - 1;
    var sawNew = false;
    final head = <int>[];
    for (var i = v - 2; i >= 0 && i >= v - 6; i--) {
      final w = words[i].w;
      if (_boundary.contains(w) || pinIdx.contains(i)) break;
      if (_fillerRe.hasMatch(w)) break;
      if (w == 'yeni' || w == 'new') {
        sawNew = true;
        s = i;
        // "yeni"den önce "bir" olabilir ("bir yeni liste").
        if (i > 0 && words[i - 1].w == 'bir') s = i - 1;
        break;
      }
      if (_headSkip.contains(w)) {
        s = i;
        continue;
      }
      // Yönelme ekli komutta ad öbeği yalnız "yeni"den sonra olur.
      if (isDative) break;
      if (head.length >= 3) break;
      head.insert(0, i);
      s = i;
    }
    if (isDative && !sawNew) continue;
    final list = isList || _dativeListNouns.contains(noun);
    final named = _kindOrTitle(text, words, head, list);
    // Zayıf fiil ("aç/yap") ancak "yeni" ya da tanınan türle komuttur.
    if (weak && !sawNew && named.kind == null) continue;
    // Güçlü fiilde de ad ya da "yeni" olmalı ("listeyi oluştur" eski liste).
    if (!sawNew && head.isEmpty) continue;
    if (!sawNew && !isList) continue;
    // Bilinmeyen ad "yeni" olmadan komut sayılmaz ("rapor listesi
    // hazırla" bir görev de olabilir) — tür tanınmalı.
    if (!sawNew && named.kind == null) continue;
    final before = _contentOf(text, words, 0, s, pinIdx);
    final after = _contentOf(text, words, v + 1, words.length, pinIdx);
    final content = [before, after].where((p) => p.isNotEmpty).join(', ');
    return QuickCreateCommand(
      list: list,
      kind: named.kind,
      title: named.title,
      pin: pins.isNotEmpty,
      content: content,
    );
  }

  // ── İngilizce: CREATE [a] [new] <name…> LIST|NOTE [with|:] … ──────────
  for (var v = 0; v < words.length - 1; v++) {
    final verb = words[v].w;
    final isNewStart = verb == 'new' && v == 0;
    if (!isNewStart && !const {'create', 'make', 'start', 'open'}.contains(verb)) {
      continue;
    }
    var sawNew = isNewStart;
    final head = <int>[];
    int? nounAt;
    for (var i = v + 1; i < words.length && i <= v + 6; i++) {
      final w = words[i].w;
      if (w == 'new') {
        sawNew = true;
        continue;
      }
      if (const {'a', 'an', 'my', 'the'}.contains(w)) continue;
      if (w == 'list' || w == 'checklist' || w == 'note') {
        nounAt = i;
        break;
      }
      head.add(i);
    }
    if (nounAt == null) continue;
    if (verb == 'open' && !sawNew) continue;
    final list = words[nounAt].w != 'note';
    final named = _kindOrTitle(text, words, head, list);
    final after = _contentOf(text, words, nounAt + 1, words.length, pinIdx);
    return QuickCreateCommand(
      list: list,
      kind: named.kind,
      title: named.kind == null && head.isNotEmpty ? named.title : '',
      pin: pins.isNotEmpty,
      content: after,
    );
  }
  return null;
}

/// Gönderme sözleri: "oraya", "aynı listeye", "o nota", "son listeye".
const _deicticSingle = {'oraya', 'buraya', 'icine', 'icerisine', 'there'};
const _deicticDet = {'ayni', 'o', 'son', 'bu', 'same', 'that', 'last'};
const _deicticNouns = {
  'listeye',
  'listesine',
  'nota',
  'notuna',
  'list',
  'note',
  'one',
};

/// "Eee oraya da elma armut" / "aynı listeye süt" / "add eggs to it":
/// SON eklenen nota gönderme. İçerik döner (gönderme ve doldurma atılmış);
/// gönderme yoksa null.
String? parseDeicticAdd(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final words = _words(text);
  if (words.length < 2) return null;
  // Baştaki doldurma ve bağlaçlar.
  var i = 0;
  while (i < words.length &&
      (_fillerRe.hasMatch(words[i].w) ||
          const {'ve', 'sonra', 'simdi', 'and', 'then', 'also'}.contains(
            words[i].w,
          ))) {
    i++;
  }
  if (i >= words.length) return null;
  final drop = <int>{for (var k = 0; k < i; k++) k};
  final w = words[i].w;
  final next = i + 1 < words.length ? words[i + 1].w : '';
  // "ona/buna" yalnız "da/de" ile gönderme ("ona hediye al" içeriktir).
  if (_deicticSingle.contains(w) ||
      ((w == 'ona' || w == 'buna') && (next == 'da' || next == 'de'))) {
    drop.add(i);
  } else if (_deicticDet.contains(w) &&
      i + 1 < words.length &&
      _deicticNouns.contains(words[i + 1].w)) {
    drop
      ..add(i)
      ..add(i + 1);
  } else {
    // Sonda: "elma armut oraya ekle", "add eggs to it / to that list".
    final n = words.length;
    var end = n;
    while (end > 0 && _tailDrop(words[end - 1].w) && words[end - 1].w != 'it' &&
        words[end - 1].w != 'there') {
      end--;
    }
    if (end <= 0) return null;
    final last = words[end - 1].w;
    if (_deicticSingle.contains(last)) {
      final content = _contentOf(text, words, 0, end - 1, const {});
      return content.isEmpty ? null : content;
    }
    if (end >= 2 &&
        _deicticDet.contains(words[end - 2].w) &&
        _deicticNouns.contains(last)) {
      var from = end - 2;
      if (from > 0 && const {'to', 'in', 'into'}.contains(words[from - 1].w)) {
        from--;
      }
      final content = _contentOf(text, words, 0, from, const {});
      return content.isEmpty ? null : content;
    }
    if (last == 'it' &&
        end >= 2 &&
        const {'to', 'in', 'into'}.contains(words[end - 2].w)) {
      final content = _contentOf(text, words, 0, end - 2, const {});
      return content.isEmpty ? null : content;
    }
    return null;
  }
  final content = _contentOf(text, words, 0, words.length, drop);
  return content.isEmpty ? null : content;
}

/// Açık hatırlatma isteği: "… bana hatırlat", "hatırlatır mısın", "hatırlatıcı
/// kur", "remind me to …".
final _remindRe = RegExp(
  r'(?:\bbana\s+)?(?:hat[ıi]rlat[a-zçğıöşü]*|an[ıi]msat[a-zçğıöşü]*)(?:\s+(?:m[ıi]s[ıi]n|musun|lütfen|lutfen))?'
  r'|\bremind\s+me(?:\s+to)?\b|\bset\s+a\s+reminder(?:\s+to)?\b',
  caseSensitive: false,
);

/// Hatırlatma cümlesinde içerikten atılan bağ sözleri.
final _remindGlueRe = RegExp(
  r"^(?:bana|ki|diye|that|to)\s+|\s+(?:diye|ki|bana)$|^['’`]?(?:da|de|ta|te)\s+",
  caseSensitive: false,
);

/// "BUGÜN SAAT 8'DE DUŞ ALACAĞIM BANA HATIRLAT" (kullanıcı bulgusu
/// 2026-11-28: "Hızlı not"a düşüyordu): açık hatırlatma isteği + tarih/saat
/// → hatırlatıcılı yeni not. İçerik komut ve tarih/saat sözleri atılmış hâl
/// ("Duş alacağım"). Saat geçmişte kalıyorsa (ve öğleden sonrası da
/// değilse) null: hatırlatıcı kurulamaz, olağan yol işler.
({String content, DateTime at})? parseReminderCommand(
  String raw, {
  String languageCode = 'tr',
  DateTime? now,
}) {
  final text = raw.trim();
  final m = _remindRe.firstMatch(text);
  if (m == null) return null;
  final rest = '${text.substring(0, m.start)} ${text.substring(m.end)}'
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final reference = now ?? DateTime.now();
  final parsed = parseSpokenDateTimeWithSpan(
    rest,
    languageCode: languageCode,
    now: reference,
  );
  if (parsed == null || !parsed.at.isAfter(reference)) return null;
  final b = StringBuffer();
  var cursor = 0;
  for (final s in parsed.spans) {
    if (s.start < cursor) continue;
    // "saat 10:30": saat yalnız "10:30"u kapsar; önündeki "saat" de gider.
    final pre = rest
        .substring(cursor, s.start)
        .replaceFirst(
          RegExp(r'(?:^|\s)(?:saat|at)\s*$', caseSensitive: false),
          ' ',
        );
    b
      ..write(pre)
      ..write(' ');
    cursor = s.end;
  }
  b.write(rest.substring(cursor));
  var content = b
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s,;:.!?-]+|[\s,;:.!?-]+$'), '')
      .trim();
  for (var i = 0; i < 3; i++) {
    final next = content.replaceAll(_remindGlueRe, '').trim();
    if (next == content) break;
    content = next;
  }
  if (content.isEmpty) content = rest;
  return (content: quickCapitalize(content), at: parsed.at);
}
