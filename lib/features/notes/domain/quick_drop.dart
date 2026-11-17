/// **"ŞU NOTA EKLE" — HEDEF ÇÖZÜMÜ** (kullanıcı isteği 2026-11-15: "ben
/// yazarım, söylerim, şu nota ekle derim, o ekler"; AI'sız).
///
/// Yazılan/söylenen metinden HANGİ NOTA ekleneceğini ve NEYİN ekleneceğini
/// ayırır. Tanınan biçimler:
///
/// * `market: süt, ekmek` — iki noktadan önceki kısım not adı;
/// * `alışveriş listesine süt ekle` / `süt yumurta markete ekle` — not adı
///   yönelme ekiyle ("-e/-a", "listesine", "notuna") ve sondaki "ekle";
/// * `add milk to shopping list`.
///
/// Not adı bulunamazsa hedef null döner; çağıran seçili (son kullanılan)
/// notu kullanır. Saf Dart.
///
/// 2026-11-16: hedef SONDA aranır, kökten eşlenir, başa baş kalanlar sorulur
/// (bkz. [parseDropTarget]); art arda söylenen maddeler ayrılır
/// ([quickDropSeparate]).
library;

import 'quick_entry.dart';

/// [index]: KESİN hedef (null = metinden çıkmadı). [ties]: başa baş kalan
/// adaylar (index null iken; kullanıcıya "hangi not?" sorulur). [command]:
/// cümle "… ekle" gibi bir komutla bitiyor ya da "ad: içerik" / "add X to Y"
/// biçiminde — kullanıcı cümlesini bitirdi ve büyük olasılıkla hedefi
/// adlandırdı.
typedef QuickDropTarget = ({
  int? index,
  String content,
  List<int> ties,
  bool command,
});

final _trailingCommand = RegExp(
  r'\s*\b(ekle|ekler misin|ekleyin|ekleyelim|ekleyiver|koy|yaz|not et|not al|kaydet)\s*[.!]?\s*$',
  caseSensitive: false,
);
/// Yalnız "ekle" ailesi tek başına "kullanıcı bir hedef adlandırdı" kanıtıdır.
/// `koy/yaz/kaydet/not al` gündelik içerikte de geçer ("rapor yaz", "çöpü
/// kapıya koy"): hedef bulunamadıysa içerikten SİLİNMEZ (H9, 2026-11-17).
final _addCommand = RegExp(
  r'\s*\b(ekle|ekler misin|ekleyin|ekleyelim|ekleyiver)\s*[.!]?\s*$',
  caseSensitive: false,
);
final _englishAdd = RegExp(
  r'^\s*(?:please\s+)?add\s+(.+?)\s+to\s+(?:my\s+|the\s+)?(.+?)\s*[.!]?\s*$',
  caseSensitive: false,
);

/// Not adından sonra gelip atılan kelimeler ("alışveriş LİSTESİNE", "market
/// NOTUNA").
const _markers = {
  'listesine',
  'listeye',
  'listesi',
  'listeme',
  'notuna',
  'notlarina',
  'nota',
  'notu',
  'notuma',
  'icin',
  'list',
  'note',
};

const _dativeSuffixes = {'e', 'a', 'ye', 'ya', 'ne', 'na'};

/// Kök bulmada atılan ekler (ASCII, uzundan kısaya): yer/ilgi/yönelme
/// durumu, iyelik, çoğul. Kaba ama İKİ YÖNE de aynı uygulandığı için
/// "dosyalara" ↔ "Dosyalarımdaki" aynı köke iner.
const _stemSuffixes = [
  'ndaki',
  'ndeki',
  'daki',
  'deki',
  'taki',
  'teki',
  'imiz',
  'umuz',
  'iniz',
  'unuz',
  'nin',
  'nun',
  'dan',
  'den',
  'tan',
  'ten',
  'nda',
  'nde',
  'lar',
  'ler',
  'da',
  'de',
  'ta',
  'te',
  'ya',
  'ye',
  'na',
  'ne',
  'yi',
  'yu',
  'si',
  'su',
  'im',
  'um',
  'in',
  'un',
  'a',
  'e',
  'i',
  'u',
  'm',
];

/// Kaynaştırma harfiyle (y/n/s) başlayan ek yalnız ünlüden sonra gelir:
/// "site-ye", "sitesi-ne" ek; "dosya", "kasa" kök ("dosya" → "dos" olmasın).
bool _bufferOk(String word, String suffix) {
  if (!'yns'.contains(suffix[0])) return true;
  final before = word[word.length - suffix.length - 1];
  return 'aeiou'.contains(before);
}

/// Türkçe kelimenin kaba kökü ([quickAscii] biçiminde verilir): ekler
/// sondan, kök en az üç harf kalacak şekilde atılır.
String quickStem(String ascii) {
  var w = ascii;
  for (var round = 0; round < 5; round++) {
    String? cut;
    for (final s in _stemSuffixes) {
      if (w.length - s.length >= 3 && w.endsWith(s) && _bufferOk(w, s)) {
        cut = w.substring(0, w.length - s.length);
        break;
      }
    }
    if (cut == null) break;
    w = cut;
  }
  return w;
}

List<String> _words(String s) => [
  for (final w in quickAscii(s).split(RegExp(r"[^a-z0-9']+")))
    if (w.isNotEmpty) w.replaceAll("'", ''),
];

/// Başlığın eşleşmede kullanılan kelimeleri (tarih/sayı gibi parçalar atılır).
List<String> _titleWords(String title) => [
  for (final w in _words(title.split(' · ').first))
    if (!RegExp(r'^\d+$').hasMatch(w)) w,
];

bool _dative(String token, String word) =>
    token.length > word.length &&
    token.startsWith(word) &&
    _dativeSuffixes.contains(token.substring(word.length));

/// Sözcük, başlık kelimesiyle aynı mı: birebir, yönelme ekli ("markete"),
/// ya da aynı köke iniyor ("dosyalara" ↔ "dosyalarımdaki").
bool _sameWord(String token, String word) =>
    token == word ||
    _dative(token, word) ||
    (word.length >= 3 && quickStem(token) == quickStem(word));

/// Sözcük bir yönelme ekiyle bitiyor mu ("dosyalarA", "siteYE").
bool _endsDative(String token) {
  for (final s in _dativeSuffixes) {
    if (token.length > s.length + 2 && token.endsWith(s)) return true;
  }
  return false;
}

/// [text]'i hedef + içerik olarak ayırır. [titles]: aday notların başlıkları
/// (dönen `index` ve `ties` bu listeye göre).
///
/// HEDEF SONDA ARANIR (kullanıcı isteği 2026-11-16: "isim tanıma en başta
/// değil en sonda olsun; kişi istediklerini söylesin, sonunda 'dosyalara
/// ekle' diyebilir"). Başta geçen ad ancak yönelme ekiyle VE komutla hedef
/// olur ("markete ekmek ekle"); "dosyalar geliştirme yapılması lazım"daki
/// "dosyalar" içeriktir. Ad kökten eşlenir: "dosyalara ekle" →
/// "Dosyalarımdaki hatalar". İki not başa baş kalırsa hedef seçilmez,
/// [QuickDropTarget.ties] döner.
QuickDropTarget parseDropTarget(String text, List<String> titles) {
  final raw = text.trim();
  if (raw.isEmpty) {
    return (index: null, content: '', ties: const [], command: false);
  }
  final wordsOf = [for (final t in titles) _titleWords(t)];

  // 1) "ad: içerik"
  final colon = raw.indexOf(':');
  if (colon > 0 && colon <= 40) {
    final head = _words(raw.substring(0, colon));
    final hits = _bestTitles(head, wordsOf);
    if (hits.isNotEmpty) {
      final content = raw.substring(colon + 1).trim();
      return hits.length == 1
          ? (
              index: hits.single,
              content: content,
              ties: const [],
              command: true,
            )
          : (index: null, content: content, ties: hits, command: true);
    }
  }

  // 2) "add X to Y"
  final en = _englishAdd.firstMatch(raw);
  if (en != null) {
    final hits = _bestTitles(_words(en.group(2)!), wordsOf);
    if (hits.isNotEmpty) {
      final content = en.group(1)!.trim();
      return hits.length == 1
          ? (
              index: hits.single,
              content: content,
              ties: const [],
              command: true,
            )
          : (index: null, content: content, ties: hits, command: true);
    }
  }

  // 3) "… <ad>e ekle" (sonda) ya da "<ad>e … ekle" (başta, ek + komutla)
  final command = _trailingCommand.hasMatch(raw);
  final body = command ? raw.replaceFirst(_trailingCommand, '').trim() : raw;
  final spans = _tokenSpans(body);
  // Not başına en iyi eşleşme: (puan, başlangıç, bitiş).
  final best = <int, (int, int, int)>{};
  for (var t = 0; t < wordsOf.length; t++) {
    final tw = wordsOf[t];
    if (tw.isEmpty) continue;
    for (var s = 0; s < spans.length; s++) {
      var k = 0;
      var exact = true;
      var suffix = false;
      while (k < tw.length && s + k < spans.length) {
        final tok = spans[s + k].word;
        if (_sameWord(tok, tw[k])) {
          if (tok != tw[k]) {
            exact = false;
            if (_endsDative(tok)) suffix = true;
          }
          k++;
          // Ekli kelime adın SONU sayılır ("kitap notlarına").
          if (suffix) break;
        } else if (k == tw.length - 1 &&
            tok.startsWith(tw[k]) &&
            tok.length <= tw[k].length + 3) {
          k++;
          exact = false;
          suffix = true;
          break;
        } else {
          break;
        }
      }
      if (k == 0) continue;
      var end = s + k;
      var marker = false;
      if (end < spans.length && _markers.contains(spans[end].word)) {
        marker = true;
        end++;
      }
      final full = k == tw.length;
      final atEnd = end == spans.length;
      final atStart = s == 0;
      final evidence = suffix || marker;
      // Kanıt: SONDA ek/işaret ya da komut; BAŞTA ek/işaret VE komut.
      // Ortada geçen ya da kanıtsız kelime içeriktir.
      final placed =
          (atEnd && (evidence || command)) || (atStart && command && evidence);
      if (!placed) continue;
      if (!full && tw[0].length < 4) continue;
      // Tek kelime tüm içerikse hedef değil ("market" yazıp bırakmak).
      if (s == 0 && end == spans.length && !command && !marker) continue;
      final score = k * 10 + (full ? 5 : 0) + (exact ? 3 : 0) + (atEnd ? 2 : 0);
      final old = best[t];
      if (old == null || score > old.$1) best[t] = (score, s, end);
    }
  }
  if (best.isEmpty) {
    if (command && !_addCommand.hasMatch(raw)) {
      return (index: null, content: raw, ties: const [], command: false);
    }
    return (index: null, content: body, ties: const [], command: command);
  }
  final top = best.values.map((e) => e.$1).reduce((a, b) => a > b ? a : b);
  final winners = [
    for (final e in best.entries)
      if (e.value.$1 == top) e.key,
  ];
  final (_, bestStart, bestEnd) = best[winners.first]!;
  final before = bestStart == 0
      ? ''
      : body.substring(0, spans[bestStart].start).trim();
  final after = bestEnd >= spans.length
      ? ''
      : body.substring(spans[bestEnd].start).trim();
  final content = [before, after].where((p) => p.isNotEmpty).join(' ');
  if (winners.length > 1) {
    return (index: null, content: content, ties: winners, command: command);
  }
  return (
    index: winners.single,
    content: content,
    ties: const [],
    command: command,
  );
}

/// Sesle/yazıyla art arda söylenen maddeleri ayırır (kullanıcı isteği
/// 2026-11-16: "birkaç madde de söyleyebilir"): "bir de", "ayrıca", "ve
/// sonra" gibi bağlaçlar virgüle döner — ses tanıma virgül koymuyor. Düz
/// "ve" BÖLMEZ ("kaydet ve raporla" tek iştir).
String quickDropSeparate(String text) => text.replaceAll(
  RegExp(
    r'\s+(?:ve\s+)?(?:bir de|ayrıca|ayrica|sonra da|ve sonra|and also|also)\s+',
    caseSensitive: false,
  ),
  ', ',
);

/// Yapay zekânın "sıra | içerik" yanıtı (bkz. `GeminiService.pickDropTarget`).
/// "yok", aralık dışı ya da bozuk yanıt null.
({int index, String content})? parseAiDropAnswer(String raw, int length) {
  final m = RegExp(r'(-?\d+)\s*\|\s*(.*)', dotAll: true).firstMatch(raw);
  if (m == null) return null;
  final i = int.tryParse(m.group(1)!);
  if (i == null || i < 0 || i >= length) return null;
  final content = m.group(2)!.trim().replaceAll(RegExp(r'^"|"$'), '');
  return (index: i, content: content);
}

typedef _Span = ({String word, int start});

List<_Span> _tokenSpans(String text) {
  final out = <_Span>[];
  final re = RegExp(r'[^\s,;:.!?]+');
  for (final m in re.allMatches(text)) {
    out.add((
      word: quickAscii(m.group(0)!).replaceAll("'", ''),
      start: m.start,
    ));
  }
  return out;
}

/// [head] kelimeleri hangi başlığa uyuyor ("market" → "Market listesi");
/// başa baş kalanların hepsi döner.
List<int> _bestTitles(List<String> head, List<List<String>> titles) {
  if (head.isEmpty) return const [];
  final scores = <int, int>{};
  for (var t = 0; t < titles.length; t++) {
    final tw = titles[t];
    if (tw.isEmpty) continue;
    var k = 0;
    var exact = true;
    while (k < head.length && k < tw.length) {
      final h = head[k];
      if (h == tw[k]) {
        k++;
      } else if (_sameWord(h, tw[k]) ||
          (h.length >= 3 && tw[k].startsWith(h))) {
        exact = false;
        k++;
      } else {
        break;
      }
    }
    // Baştaki işaret kelimeleri ("market listesi:") sayılır.
    var rest = head.length - k;
    for (var j = k; j < head.length; j++) {
      if (_markers.contains(head[j])) rest--;
    }
    if (k == 0 || rest > 0) continue;
    scores[t] = k * 10 + (k == tw.length ? 5 : 0) + (exact ? 3 : 0);
  }
  if (scores.isEmpty) return const [];
  final top = scores.values.reduce((a, b) => a > b ? a : b);
  return [
    for (final e in scores.entries)
      if (e.value == top) e.key,
  ];
}

/// Listeye eklemenin sonucu: [texts] yeni madde metinleri, [uncheck] yeniden
/// gerekli olduğu için işareti kalkacak mevcut maddelerin sırası,
/// [requantify] miktarı güncellenecek mevcut maddeler (sıra → yeni metin).
typedef QuickDropListPlan = ({
  List<String> texts,
  List<int> uncheck,
  Map<int, String> requantify,
});

/// [items] maddelerini [existing] listesine nasıl ekleyeceğini hesaplar:
/// zaten duran madde yeniden eklenmez (işaretliyse işareti kalkar — "yine
/// lazım"; yeni miktar geldiyse miktarı güncellenir).
QuickDropListPlan planDropIntoList(
  List<({String text, bool checked})> existing,
  List<QuickItem> items,
) {
  final byKey = <String, int>{};
  for (var i = 0; i < existing.length; i++) {
    final k = quickItemKey(existing[i].text);
    if (k.isNotEmpty) byKey.putIfAbsent(k, () => i);
  }
  final texts = <String>[];
  final uncheck = <int>[];
  final requantify = <int, String>{};
  final added = <String>{};
  for (final item in items) {
    final key = quickItemKey(item.text);
    if (key.isEmpty) continue;
    final at = byKey[key];
    if (at != null) {
      if (existing[at].checked && !uncheck.contains(at)) uncheck.add(at);
      if (item.qty.isNotEmpty && existing[at].text.trim() != item.text) {
        requantify[at] = quickCompose(
          quickBaseName(existing[at].text),
          item.qty,
        );
      }
      continue;
    }
    if (added.add(key)) texts.add(item.text);
  }
  return (texts: texts, uncheck: uncheck, requantify: requantify);
}
