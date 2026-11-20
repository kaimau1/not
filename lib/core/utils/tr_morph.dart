/// **TÜRKÇE EK ÇÖZÜCÜ** (yazım v3 Y-1, 17K §3.3). Saf Dart.
///
/// Kelimeyi sağdan sola kök + ek zinciri olarak dener: çoğul, iyelik, hâl,
/// "-ki", bildirme, kişi, çatı, olumsuzluk, yeterlik, zaman/kip, ad-fiil,
/// zarf-fiil ve birkaç yapım eki. Ekler büyük ünlü uyumuyla (A = a/e,
/// I = ı/i/u/ü), ünsüz benzeşmesiyle (D = d/t, C = c/ç), kaynaştırma
/// harfleriyle ((y)/(n)/(s)) ve "-k → -ğ" yumuşamasıyla üretilip yazılanla
/// karşılaştırılır. Kökte: ünsüz yumuşaması ("kitab-ı" ← kitap), ünlü
/// düşmesi ("ağz-ı" ← ağız), ikizleşme ("hakk-ı" ← hak), "-yor" daralması
/// ("söyl-üyor" ← söyle), "di-yecek" ← de.
///
/// ponytail: tam bir biçimbilim değil — biçim sırası gevşek (ör. kişi eki
/// iki paradigmada da kabul). Bedeli: birkaç yazım hatası "bilinir" sayılır
/// (yakalama düşer, yanlış düzeltme düşmez). Sıkılaştırma: durum makinesi.
library;

import 'tr_roots.dart' show kTrDoubling, kTrFrontLoans, kTrSoftMono;

const _vowels = 'aeıioöuü';
const _backVowels = 'aıou';
const _voiceless = 'çfhkpsşt';
const _front = {'a': 'e', 'ı': 'i', 'o': 'ö', 'u': 'ü'};
const _hard = {'b': 'p', 'c': 'ç', 'd': 't', 'g': 'k', 'ğ': 'k'};

int _syllables(String s) => s.split('').where(_isV).length;

bool _isV(String c) => _vowels.contains(c);

String? _lastVowel(String s) {
  for (var i = s.length - 1; i >= 0; i--) {
    if (_isV(s[i])) return s[i];
  }
  return null;
}

// Durumlar (soldan sağa): ad gövdesi → çoğul → iyelik → hâl; fiil gövdesi →
// olumsuz / yeterlik → zaman → bildirme → kişi.
const _n0 = 1, _n1 = 2, _n2 = 4, _n3 = 8;
const _v0 = 16, _vn = 32, _vb = 64, _vt = 128, _c = 256, _p = 512;
const _vny = 1024; // "-m-" olumsuzluk yalnız "-(I)yor"dan önce.
const _nAny = _n0 | _n1 | _n2 | _n3;
const _vStem = _v0 | _vn | _vb;
const _end = 2047 & ~_vny;

// Bayraklar.
const _afterC = 1, _afterV = 2, _soft = 4, _yor = 8;

class _M {
  const _M(this.form, this.from, this.to, [this.flags = 0]);
  final String form;
  final int from;
  final int to;
  final int flags;
}

const _morphs = <_M>[
  // --- ad ---
  _M('lAr', _n0, _n1),
  _M('(I)m', _n0 | _n1, _n2),
  _M('(I)n', _n0 | _n1, _n2),
  _M('(s)I', _n0 | _n1, _n2),
  _M('(I)mIz', _n0 | _n1, _n2),
  _M('(I)nIz', _n0 | _n1, _n2),
  _M('lArI', _n0, _n2),
  _M('(y)I', _n0 | _n1 | _n2, _n3),
  _M('(y)A', _n0 | _n1 | _n2, _n3),
  _M('DA', _n0 | _n1 | _n2, _n3),
  _M('DAn', _n0 | _n1 | _n2, _n3),
  _M('(n)In', _n0 | _n1 | _n2, _n3),
  _M('(y)lA', _n0 | _n1 | _n2, _n3),
  _M('CA', _n0 | _n1 | _n2, _n3 | _n0),
  // Adıl n'si ("evi-ni", "evi-nde", "kendi-ne").
  _M('nI', _n0 | _n2, _n3, _afterV),
  _M('nA', _n0 | _n2, _n3, _afterV),
  _M('nDA', _n0 | _n2, _n3, _afterV),
  _M('nDAn', _n0 | _n2, _n3, _afterV),
  // "-ki" yalnız hâl ekinden sonra ("evde-ki"); "bugünkü" gibiler kökte.
  _M('ki', _n3, _n0),
  // Yapım (ad → ad).
  _M('lIk', _n0, _n0, _soft),
  _M('lI', _n0, _n0),
  _M('sIz', _n0, _n0),
  _M('CI', _n0, _n0),
  _M('CIk', _n0, _n0, _soft),
  _M('sAl', _n0, _n0),
  _M('(I)ncI', _n0, _n0),
  // Ad → fiil.
  _M('lA', _n0, _v0),
  _M('lAş', _n0, _v0),
  _M('lAn', _n0, _v0),
  _M('Al', _n0, _v0, _afterC),
  // --- fiil ---
  // Çatı.
  _M('Il', _v0, _v0, _afterC),
  _M('In', _v0, _v0, _afterC),
  _M('n', _v0, _v0, _afterV),
  _M('DIr', _v0, _v0),
  _M('t', _v0, _v0, _afterV),
  _M('Ir', _v0, _v0, _afterC),
  _M('Iş', _v0, _v0, _afterC),
  _M('ş', _v0, _v0, _afterV),
  // Olumsuzluk, yeterlik.
  _M('mA', _v0, _vn),
  _M('(y)AmA', _v0, _vn),
  _M('m', _v0, _vny),
  _M('(y)Am', _v0, _vny),
  _M('(y)Abil', _v0, _vb),
  // Zaman / kip.
  _M('(I)yor', _v0 | _vb | _vny, _vt, _yor),
  _M('(y)AcAk', _vStem, _vt | _n0, _soft),
  _M('mIş', _vStem, _vt | _n0),
  _M('DI', _vStem, _vt),
  _M('sA', _vStem, _vt),
  _M('mAlI', _vStem, _vt),
  _M('mAktA', _vStem, _vt),
  _M('r', _v0 | _vb, _vt | _n0, _afterV),
  _M('Ar', _v0, _vt | _n0, _afterC),
  _M('Ir', _v0 | _vb, _vt | _n0, _afterC),
  _M('z', _vn, _vt | _n0),
  // Emir.
  _M('(y)In', _vStem, _p),
  _M('(y)InIz', _vStem, _p),
  _M('sIn', _vStem, _p),
  _M('sInlAr', _vStem, _p),
  _M('(y)AlIm', _vStem, _p),
  _M('(y)AyIm', _vStem, _p),
  // Ad-fiil / sıfat-fiil.
  _M('mAk', _vStem, _n0),
  _M('mA', _vStem, _n0),
  _M('(y)Iş', _vStem, _n0),
  _M('(y)An', _vStem, _n0),
  _M('DIk', _vStem, _n0, _soft),
  _M('(y)ICI', _vStem, _n0),
  _M('(y)AsI', _vStem, _n0),
  // Zarf-fiil.
  _M('(y)Ip', _vStem, _p),
  _M('(y)ArAk', _vStem, _p),
  _M('(y)IncA', _vStem, _p),
  _M('mAdAn', _v0 | _vb, _p),
  _M('(y)AlI', _vStem, _p),
  _M('DIkçA', _vStem, _p),
  _M('mAksIzIn', _vStem, _p),
  // --- bildirme + kişi ---
  _M('(y)DI', _nAny | _vt, _c),
  _M('(y)mIş', _nAny | _vt, _c),
  _M('(y)sA', _nAny | _vt, _c),
  _M('(y)ken', _nAny | _vt, _p),
  _M('DIr', _nAny | _vt | _p, _p),
  _M('(y)Im', _nAny | _vt | _c, _p),
  _M('sIn', _nAny | _vt | _c, _p),
  _M('(y)Iz', _nAny | _vt | _c, _p),
  _M('sInIz', _nAny | _vt | _c, _p),
  _M('m', _vt | _c | _vn, _p, _afterV),
  _M('n', _vt | _c, _p, _afterV),
  _M('k', _vt | _c, _p, _afterV),
  _M('nIz', _vt | _c, _p, _afterV),
  _M('lAr', _vt | _c, _vt | _p),
];

/// Biçimin olası yüzey uzunlukları (kaynaştırma/yardımcı ünlü var/yok).
final List<List<int>> _lengths = [
  for (final m in _morphs)
    () {
      final opt = RegExp(r'\(([^)]*)\)').allMatches(m.form);
      final total = m.form.replaceAll(RegExp('[()]'), '').length;
      final optLen = opt.fold<int>(0, (n, x) => n + x.group(1)!.length);
      return optLen == 0 ? [total] : [total, total - optLen];
    }(),
];

/// [form] [stem]'in ardından nasıl yazılır (tek doğru yüzey).
String _realize(String form, String stem, bool front) {
  final out = StringBuffer();
  var prev = stem[stem.length - 1];
  var lastV = _lastVowel(stem);
  if (front && lastV != null) lastV = _front[lastV] ?? lastV;
  void emit(String ch) {
    String c;
    switch (ch) {
      case 'A':
        c = lastV != null && _backVowels.contains(lastV!) ? 'a' : 'e';
      case 'I':
        final v = lastV ?? 'i';
        c = switch (v) {
          'a' || 'ı' => 'ı',
          'o' || 'u' => 'u',
          'ö' || 'ü' => 'ü',
          _ => 'i',
        };
      case 'D':
        c = _voiceless.contains(prev) ? 't' : 'd';
      case 'C':
        c = _voiceless.contains(prev) ? 'ç' : 'c';
      default:
        c = ch;
    }
    out.write(c);
    prev = c;
    if (_isV(c)) lastV = c;
  }

  var i = 0;
  while (i < form.length) {
    final ch = form[i];
    if (ch == '(') {
      final close = form.indexOf(')', i);
      final opt = form.substring(i + 1, close);
      i = close + 1;
      final vowelOpt = opt == 'I' || opt == 'A';
      // Ünlüden sonra yardımcı ünlü, ünsüzden sonra kaynaştırma düşer.
      if (vowelOpt == _isV(prev)) continue;
      for (final c in opt.split('')) {
        emit(c);
      }
      continue;
    }
    emit(ch);
    i++;
  }
  return out.toString();
}

/// Özel ad + kesme ("Google'da"): [tail] [head]'den sonra kurallı bir ek
/// zinciri mi. Yabancı adın okunuşu yazıdan çıkmaz: adın kendisi, sonra her
/// ünlüyle sanal bir gövde denenir.
bool trSuffixesOk(String head, String tail) {
  if (head.isEmpty || tail.isEmpty) return head.isNotEmpty;
  final last = head[head.length - 1];
  final heads = <String>{
    head,
    for (final v in _vowels.split('')) ...[
      'q$v',
      'q${v}r',
      if (!_isV(last)) 'q$v$last',
    ],
  };
  for (final h in heads) {
    final m = TrMorph(isNoun: (r) => r == h, isVerb: (_) => false);
    if (m.parses(h + tail)) return true;
  }
  return false;
}

/// Kök sözlüğüne bakarak kelimenin kurallı bir kök + ek zinciri olup
/// olmadığını söyler. Örnek başına önbellek yok; çağıran önbellekler.
class TrMorph {
  TrMorph({required this.isNoun, required this.isVerb});

  final bool Function(String root) isNoun;
  final bool Function(String root) isVerb;

  String _w = '';
  final _memo = <int, bool>{};
  int _budget = 0;

  /// [word] küçük harf (Türkçe), yalnız harf.
  bool parses(String word) {
    if (word.length < 2 || word.length > 40) return false;
    if (isNoun(word) || isVerb(word)) return true;
    _w = word;
    _memo.clear();
    _budget = 6000; // Sapkın girdide tavan (tipik kelime < 300 adım).
    return _parse(word.length, _end, false);
  }

  bool _parse(int end, int allowed, bool rightYor) {
    final key = (end << 12) | (allowed << 1) | (rightYor ? 1 : 0);
    final hit = _memo[key];
    if (hit != null) return hit;
    if (--_budget < 0) return false;
    final r = _root(end, allowed, rightYor) || _strip(end, allowed);
    _memo[key] = r;
    return r;
  }

  bool _root(int end, int allowed, bool rightYor) {
    final stem = _w.substring(0, end);
    final noun = (allowed & _n0) != 0;
    final verb = (allowed & _v0) != 0;
    bool any(String r) => (noun && isNoun(r)) || (verb && isVerb(r));
    if (any(stem)) return true;
    final next = end < _w.length ? _w[end] : '';
    final last = stem[stem.length - 1];
    if (next.isNotEmpty && _isV(next)) {
      final head = stem.substring(0, stem.length - 1);
      final hard = _hard[last];
      // Ünsüz yumuşaması: g yalnız n'den sonra ("rengi"), ğ ünlüden sonra.
      final softOk =
          hard != null &&
          head.isNotEmpty &&
          (last != 'g' || head.endsWith('n')) &&
          (last != 'ğ' || _isV(head[head.length - 1]));
      if (softOk) {
        final r = '$head$hard';
        if (noun &&
            isNoun(r) &&
            (_syllables(r) > 1 || kTrSoftMono.contains(r))) {
          return true;
        }
        // Fiilde yalnız "git, et, tat, güt" ve "-et"li birleşikler ("kaydet").
        if (verb &&
            isVerb(r) &&
            (const {'git', 'et', 'tat', 'güt'}.contains(r) ||
                (r.endsWith('et') && _syllables(r) > 1))) {
          return true;
        }
      }
      if (noun && stem.length >= 3 && !_isV(last)) {
        final before = stem[stem.length - 2];
        if (!_isV(before)) {
          // hakk-ı
          if (before == last && kTrDoubling.contains(head)) return true;
          final h = head.substring(0, head.length - 1);
          final tail = [last, ?_hard[last]];
          for (final v in const ['ı', 'i', 'u', 'ü']) {
            for (final t in tail) {
              if (isNoun('$h$before$v$t')) return true; // ağz-ı, kayd-ı
            }
          }
        }
      }
    }
    if (rightYor && verb && !_isV(last)) {
      final lv = _lastVowel(stem);
      final tails = lv == null
          ? const ['e', 'a']
          : [_backVowels.contains(lv) ? 'a' : 'e'];
      for (final t in tails) {
        if (isVerb('$stem$t')) return true; // söyl-üyor
      }
    }
    if (verb && next == 'y' && (stem == 'di' || stem == 'yi')) {
      return isVerb('${stem[0]}e'); // di-yecek
    }
    return false;
  }

  bool _strip(int end, int allowed) {
    for (var k = 0; k < _morphs.length; k++) {
      final m = _morphs[k];
      if ((m.to & allowed) == 0) continue;
      for (final len in _lengths[k]) {
        if (len >= end) continue;
        final stemEnd = end - len;
        final last = _w[stemEnd - 1];
        if ((m.flags & _afterC) != 0 && _isV(last)) continue;
        if ((m.flags & _afterV) != 0 && !_isV(last)) continue;
        // "-yor" önünde a/e daralır: "arayor" değil "arıyor".
        if ((m.flags & _yor) != 0 && (last == 'a' || last == 'e')) continue;
        final stem = _w.substring(0, stemEnd);
        var exp = _realize(m.form, stem, kTrFrontLoans.contains(stem));
        if ((m.flags & _soft) != 0 &&
            end < _w.length &&
            _isV(_w[end]) &&
            exp.endsWith('k')) {
          exp = '${exp.substring(0, exp.length - 1)}ğ';
        }
        if (exp.length != len || !_w.startsWith(exp, stemEnd)) continue;
        if (_parse(stemEnd, m.from, (m.flags & _yor) != 0)) return true;
      }
    }
    return false;
  }
}
