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
library;

import 'quick_entry.dart';

typedef QuickDropTarget = ({int? index, String content});

final _trailingCommand = RegExp(
  r'\s*\b(ekle|ekler misin|ekleyin|yaz|not et|not al|kaydet)\s*[.!]?\s*$',
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
  'notuna',
  'nota',
  'notu',
  'icin',
  'list',
  'note',
};

const _dativeSuffixes = {'e', 'a', 'ye', 'ya', 'ne', 'na'};

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

/// [text]'i hedef + içerik olarak ayırır. [titles]: aday notların başlıkları
/// (dönen `index` bu listeye göre).
QuickDropTarget parseDropTarget(String text, List<String> titles) {
  final raw = text.trim();
  if (raw.isEmpty) return (index: null, content: '');
  final wordsOf = [for (final t in titles) _titleWords(t)];

  // 1) "ad: içerik"
  final colon = raw.indexOf(':');
  if (colon > 0 && colon <= 40) {
    final head = _words(raw.substring(0, colon));
    final i = _bestTitle(head, wordsOf, whole: true);
    if (i != null) return (index: i, content: raw.substring(colon + 1).trim());
  }

  // 2) "add X to Y"
  final en = _englishAdd.firstMatch(raw);
  if (en != null) {
    final i = _bestTitle(_words(en.group(2)!), wordsOf, whole: true);
    if (i != null) return (index: i, content: en.group(1)!.trim());
  }

  // 3) "… <ad>e … ekle"
  final command = _trailingCommand.hasMatch(raw);
  final body = command ? raw.replaceFirst(_trailingCommand, '').trim() : raw;
  final spans = _tokenSpans(body);
  int? best;
  var bestStart = 0;
  var bestEnd = 0;
  var bestScore = 0;
  for (var t = 0; t < wordsOf.length; t++) {
    final tw = wordsOf[t];
    if (tw.isEmpty) continue;
    for (var s = 0; s < spans.length; s++) {
      var k = 0;
      var suffix = false;
      while (k < tw.length && s + k < spans.length) {
        final tok = spans[s + k].word;
        if (tok == tw[k]) {
          k++;
        } else if (_dative(tok, tw[k]) ||
            (k == tw.length - 1 &&
                tok.startsWith(tw[k]) &&
                tok.length <= tw[k].length + 3)) {
          k++;
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
      final atEdge = s == 0 || end == spans.length;
      // Kanıt: yönelme eki / "listesine" gibi işaret, ya da başta/sonda tam ad
      // (komutla). Tek başına içerikte geçen kelime hedef sayılmaz.
      final ok =
          (full && (suffix || marker)) ||
          (full && command && atEdge) ||
          (!full && (suffix || marker) && tw[0].length >= 4 && k >= 1);
      if (!ok) continue;
      final score = k * 10 + (full ? 5 : 0) + (suffix || marker ? 2 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = t;
        bestStart = s;
        bestEnd = end;
      }
    }
  }
  if (best == null) return (index: null, content: body);
  final before = bestStart == 0
      ? ''
      : body.substring(0, spans[bestStart].start).trim();
  final after = bestEnd >= spans.length
      ? ''
      : body.substring(spans[bestEnd].start).trim();
  final content = [before, after].where((p) => p.isNotEmpty).join(' ');
  return (index: best, content: content);
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

/// [head] kelimeleri hangi başlığa uyuyor ("market" → "Market listesi").
int? _bestTitle(
  List<String> head,
  List<List<String>> titles, {
  required bool whole,
}) {
  if (head.isEmpty) return null;
  int? best;
  var bestScore = 0;
  for (var t = 0; t < titles.length; t++) {
    final tw = titles[t];
    if (tw.isEmpty) continue;
    var k = 0;
    while (k < head.length && k < tw.length) {
      final h = head[k];
      if (h == tw[k] ||
          _dative(h, tw[k]) ||
          (h.length >= 3 && tw[k].startsWith(h))) {
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
    if (k == 0 || (whole && rest > 0)) continue;
    final score = k * 10 + (k == tw.length ? 5 : 0);
    if (score > bestScore) {
      bestScore = score;
      best = t;
    }
  }
  return best;
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
