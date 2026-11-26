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
  TrLexicon._(this._text, this._starts, this._tabs);

  /// `kelime<TAB>bayraklar` satırları; sıralı olmalı (üretici sıralar,
  /// bekçi test doğrular).
  factory TrLexicon.parse(String text) {
    final starts = <int>[];
    final tabs = <int>[];
    var pos = 0;
    final n = text.length;
    while (pos < n) {
      final nl = text.indexOf('\n', pos);
      final end = nl < 0 ? n : nl;
      final tab = text.indexOf('\t', pos);
      if (end > pos) {
        starts.add(pos);
        tabs.add(tab < 0 || tab > end ? end : tab);
      }
      pos = end + 1;
    }
    return TrLexicon._(
      text,
      Int32List.fromList(starts),
      Int32List.fromList(tabs),
    );
  }

  final String _text;
  final Int32List _starts;
  final Int32List _tabs;

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

  bool _flag(String w, int flag) {
    final i = _find(w);
    if (i < 0) return false;
    final end = i + 1 < _starts.length ? _starts[i + 1] - 1 : _text.length;
    for (var k = _tabs[i] + 1; k < end; k++) {
      if (_text.codeUnitAt(k) == flag) return true;
    }
    return false;
  }

  /// Sözlükte var mı (her türden).
  bool has(String w) => _find(w) >= 0;

  /// Fiil dışı kök (ad, sıfat, zarf, adıl, bağlaç, ünlem…).
  bool noun(String w) => _flag(w, 0x6E); // n

  /// Fiil kökü ("gel", "boya").
  bool verb(String w) => _flag(w, 0x76); // v

  /// Tek heceli ve sonu yumuşar ("kap" → "kabı").
  bool softMono(String w) => _flag(w, 0x73); // s

  /// Yumuşamaz ("adalet" → "adaleti", "adaledi" değil).
  bool noVoicing(String w) => _flag(w, 0x68); // h

  /// İkizleşir ("hak" → "hakkı").
  bool doubling(String w) => _flag(w, 0x64); // d

  /// İnce ünlüyle ek alır ("saat" → "saati").
  bool front(String w) => _flag(w, 0x66); // f

  /// Son ünlüsü düşer ("ağız" → "ağzı").
  bool dropsVowel(String w) => _flag(w, 0x6C); // l
}
