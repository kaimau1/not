/// **BÜYÜK TÜRKÇE KÖK SÖZLÜĞÜ** (kullanıcı isteği 2026-11-26: "yazım
/// denetimi için geniş bir sözlük, açık kaynaktan"). Saf Dart.
///
/// Kaynak Zemberek-NLP sözlükleri (Apache License 2.0; `assets/spell/
/// NOTICE.txt`), üretici `tool/spell/build_tr_lexicon.py`. ~31 bin kök: ad,
/// sıfat, zarf… ve fiil kökleri; yumuşama/ikizleşme/ince ek/ünlü düşmesi
/// bayraklarıyla. Ek çözücü ([TrMorph]) çekimli biçimleri bunlardan çıkarır
/// ("kalemlerimizden" ← kalem).
///
/// Bellek: dosya metni TEK dize olarak tutulur, satır başları/sekme yerleri
/// iki `Int32List`te; arama ikili arama (kopyasız kod birimi karşılaştırma).
/// ~0,9 MB; 31 bin ayrı `String` + `Set` ≈ 3 MB olurdu.
///
/// Yüklenene dek [instance] null'dır: yazım denetimi eski (küçük elle
/// sözlük) davranışıyla sürer, yüklenince [revision] artar.
library;

import 'dart:typed_data';

class TrLexicon {
  TrLexicon._(this._text, this._starts, this._tabs, this._flags);

  static const flagPresent = 1 << 7;
  static const flagNoun = 1 << 0;
  static const flagVerb = 1 << 1;
  static const flagSoftMono = 1 << 2;
  static const flagNoVoicing = 1 << 3;
  static const flagDoubling = 1 << 4;
  static const flagFront = 1 << 5;
  static const flagDropsVowel = 1 << 6;

  /// `kelime<TAB>bayraklar` satırları; sıralı olmalı (üretici sıralar,
  /// bekçi test doğrular).
  factory TrLexicon.parse(String text) {
    final starts = <int>[];
    final tabs = <int>[];
    final flags = <int>[];
    var pos = 0;
    final n = text.length;
    while (pos < n) {
      final nl = text.indexOf('\n', pos);
      final end = nl < 0 ? n : nl;
      final tab = text.indexOf('\t', pos);
      if (end > pos) {
        final sep = tab < 0 || tab > end ? end : tab;
        starts.add(pos);
        tabs.add(sep);
        var mask = flagPresent;
        for (var k = sep + 1; k < end; k++) {
          mask |= switch (text.codeUnitAt(k)) {
            0x6E => flagNoun,
            0x76 => flagVerb,
            0x73 => flagSoftMono,
            0x68 => flagNoVoicing,
            0x64 => flagDoubling,
            0x66 => flagFront,
            0x6C => flagDropsVowel,
            _ => 0,
          };
        }
        flags.add(mask);
      }
      pos = end + 1;
    }
    return TrLexicon._(
      text,
      Int32List.fromList(starts),
      Int32List.fromList(tabs),
      Uint8List.fromList(flags),
    );
  }

  final String _text;
  final Int32List _starts;
  final Int32List _tabs;
  final Uint8List _flags;

  static TrLexicon? _instance;

  /// Yüklü sözlük (yoksa null — denetim eski davranışta).
  static TrLexicon? get instance => _instance;

  /// Sözlük değişti sayacı (önbellekler bayatlar).
  static int revision = 0;

  static void install(TrLexicon? lexicon) {
    _instance = lexicon;
    revision++;
  }

  int get length => _starts.length;

  /// [i]. satırın kelimesi (test ve sıra denetimi için).
  String wordAt(int i) => _text.substring(_starts[i], _tabs[i]);

  int _compare(String w, int i) {
    final s = _starts[i];
    final len = _tabs[i] - s;
    final m = w.length < len ? w.length : len;
    for (var k = 0; k < m; k++) {
      final d = w.codeUnitAt(k) - _text.codeUnitAt(s + k);
      if (d != 0) return d;
    }
    return w.length - len;
  }

  int _find(String w) {
    var lo = 0;
    var hi = _starts.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final c = _compare(w, mid);
      if (c == 0) return mid;
      if (c < 0) {
        hi = mid - 1;
      } else {
        lo = mid + 1;
      }
    }
    return -1;
  }

  /// Sözcüğün tüm bayrakları tek ikili aramada (yoksa `0`, varsa bit 7 = 1).
  int flagsOf(String w) {
    final i = _find(w);
    return i < 0 ? 0 : _flags[i];
  }

  /// Sözlükte var mı (her türden).
  bool has(String w) => _find(w) >= 0;

  /// Fiil dışı kök (ad, sıfat, zarf, adıl, bağlaç, ünlem…).
  bool noun(String w) => (flagsOf(w) & flagNoun) != 0;

  /// Fiil kökü ("gel", "boya").
  bool verb(String w) => (flagsOf(w) & flagVerb) != 0;

  /// Tek heceli ve sonu yumuşar ("kap" → "kabı").
  bool softMono(String w) => (flagsOf(w) & flagSoftMono) != 0;

  /// Yumuşamaz ("adalet" → "adaleti", "adaledi" değil).
  bool noVoicing(String w) => (flagsOf(w) & flagNoVoicing) != 0;

  /// İkizleşir ("hak" → "hakkı").
  bool doubling(String w) => (flagsOf(w) & flagDoubling) != 0;

  /// İnce ünlüyle ek alır ("saat" → "saati").
  bool front(String w) => (flagsOf(w) & flagFront) != 0;

  /// Son ünlüsü düşer ("ağız" → "ağzı").
  bool dropsVowel(String w) => (flagsOf(w) & flagDropsVowel) != 0;
}
