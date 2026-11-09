import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/local_file.dart' show appSupportPath;
import '../../../../core/utils/spell_fix.dart';
import '../../../../core/utils/spell_learn.dart';
import 'text_wrap.dart';

/// **YAZIM DÜZELT** (hızlı satırda aç/kapa, kullanıcı isteği 2026-11-08):
/// açıkken her biten kelime SORULMADAN düzeltilir — önce Türkçe kurallar
/// ([spellFixAt]), sonra ÖĞRENEN hafıza ([SpellMemory]: kullanıcının kendi
/// düzeltmeleri, boşluk yerine "n", klavye komşusu tuşlar), en son Android'in
/// yazım denetçisinin ilk önerisi (klavye mesafesiyle yakınsa); Enter / yeni
/// maddede satır son kontrolden geçer ([finalizeLine]).
///
/// **BAŞLIK** ([attach] `title: true`): kelimelerin baş harfi büyür, satır
/// sonuna nokta konmaz.
///
/// **ÖĞRENME**: biten kelimeye geri dönülüp değiştirilirse `eski → yeni`
/// kaydedilir; otomatik düzeltme geri alınırsa o kelime bir daha
/// düzeltilmez. Hafıza uygulama destek klasöründe küçük bir JSON dosyası
/// (web'de tercih); yazma 4 sn erteli ve toplu.
///
/// Etkin alan değiştikçe [attach] çağrılır (editörün biçim hedefiyle aynı
/// yerden); dinleyici kapalıyken yalnız bir bool okur.
class AutoSpell {
  AutoSpell._();

  static final enabled = ValueNotifier<bool>(false);

  /// Öğrenme açık mı (ayrı anahtar; varsayılan açık).
  static final learning = ValueNotifier<bool>(true);
  static const _key = 'auto_spell_on';
  static const _learnKey = 'auto_spell_learn';
  static const _memoryPref = 'spell_memory_v1';
  static const _memoryFile = 'spell_memory.json';

  static bool _loaded = false;

  /// Kişisel yazım hafızası (bkz. [SpellMemory]).
  static SpellMemory memory = SpellMemory();

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      enabled.value = p.getBool(_key) ?? false;
      learning.value = p.getBool(_learnKey) ?? true;
      memory = SpellMemory.decode(await _readMemory(p));
    } catch (_) {}
  }

  static Future<String?> _readMemory(SharedPreferences p) async {
    final base = appSupportPath;
    if (kIsWeb || base == null) return p.getString(_memoryPref);
    final f = File('$base/$_memoryFile');
    return await f.exists() ? f.readAsString() : null;
  }

  static Timer? _saveTimer;

  static void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 4), () => unawaited(_save()));
  }

  static Future<void> _save() async {
    try {
      final raw = memory.encode();
      final base = appSupportPath;
      if (kIsWeb || base == null) {
        final p = await SharedPreferences.getInstance();
        // Web'de tercih dosyası şişmesin: sözlük kısılır.
        await p.setString(_memoryPref, raw.length > 120000 ? '' : raw);
      } else {
        await File('$base/$_memoryFile').writeAsString(raw);
      }
    } catch (_) {}
  }

  static void toggle() {
    enabled.value = !enabled.value;
    unawaited(
      SharedPreferences.getInstance()
          .then((p) => p.setBool(_key, enabled.value))
          .catchError((_) => false),
    );
  }

  static void setLearning(bool on) {
    learning.value = on;
    unawaited(
      SharedPreferences.getInstance()
          .then((p) => p.setBool(_learnKey, on))
          .catchError((_) => false),
    );
  }

  /// Ayarlar ekranındaki elle değişiklikten sonra kaydet.
  static void changed() => _scheduleSave();

  /// Öğrenilenleri siler.
  static void forget() {
    memory = SpellMemory()..seed(memory.seeded);
    unawaited(_save());
  }

  static bool _seeding = false;

  /// Notların metninden kişisel sözlük kurar (arka planda, oturumda bir kez).
  static Future<void> seedFrom(List<String> Function() texts) async {
    if (_seeding || memory.seeded.isNotEmpty || !enabled.value) return;
    _seeding = true;
    try {
      final counts = await compute(seedCounts, texts());
      memory.seed(counts);
    } catch (_) {
      _seeding = false;
    }
  }

  static WrapTextController? _c;
  static VoidCallback? _commit;
  static String _prev = '';
  static bool _busy = false;
  static bool _title = false;

  /// Son biten kelime: kullanıcı geri dönüp değiştirirse öğrenilir.
  static _Finished? _last;

  /// [controller] artık yazılan alan; önceki alan bırakılırken son satırı
  /// son kontrolden geçer (yeni maddeye geçiş). [title] = başlık alanı.
  static void attach(
    WrapTextController controller,
    VoidCallback commit, {
    bool title = false,
  }) {
    if (identical(controller, _c)) {
      _commit = commit;
      _title = title;
      return;
    }
    final old = _c;
    final oldCommit = _commit;
    final oldTitle = _title;
    old?.removeListener(_onChange);
    if (old != null && enabled.value && !oldTitle) {
      _finalizeWhole(old, oldCommit);
    }
    _c = controller;
    _commit = commit;
    _title = title;
    _last = null;
    _prev = controller.logicalText;
    controller.addListener(_onChange);
  }

  static void detach(WrapTextController controller) {
    if (!identical(controller, _c)) return;
    controller.removeListener(_onChange);
    _c = null;
    _commit = null;
    _last = null;
  }

  static void _finalizeWhole(WrapTextController c, VoidCallback? commit) {
    try {
      final text = c.logicalText;
      final lines = text.split('\n');
      if (lines.isEmpty) return;
      final last = finalizeLine(lines.last);
      if (last == lines.last) return;
      // KÖK NEDEN ADAYI (kullanıcı bulgusu 2026-11-08: "yeni maddeye hızlı
      // geçince oto düzeltme yazıyı siliyor"): yalnız SON satırın başı ve
      // sonu değişebilir — beklenmeyen bir fark (alan o arada başka metinle
      // dolmuş) varsa dokunma.
      if (last.length > lines.last.length + 1) return;
      lines[lines.length - 1] = last;
      final next = lines.join('\n');
      _busy = true;
      // İmleç yerinde (alan artık odakta değil; sona taşımak gereksiz).
      final sel = c.selection;
      final caret = sel.isValid
          ? wrapToLogicalOffset(c.text, sel.baseOffset).clamp(0, next.length)
          : next.length;
      c.setLogical(next, caret);
      commit?.call();
    } catch (_) {
      // Bırakılan alan atılmış olabilir.
    } finally {
      _busy = false;
    }
  }

  /// Metnin [end]e kadarki son harf dizisi (geriye doğru tarar — uzun
  /// notta baştan düzenli ifade koşmasın).
  static ({int start, String word})? _lastWord(String text, int end) {
    var i = end;
    while (i > 0 && _isLetter(text[i - 1])) {
      i--;
    }
    if (i == end) return null;
    return (start: i, word: text.substring(i, end));
  }

  static final _letter = RegExp(r'\p{L}', unicode: true);
  static bool _isLetter(String ch) => _letter.hasMatch(ch);

  static void _onChange() {
    final c = _c;
    if (c == null || _busy || !enabled.value) return;
    final text = c.logicalText;
    if (text == _prev) return;
    final prev = _prev;
    _prev = text;
    final sel = c.selection;
    if (!sel.isValid || !sel.isCollapsed) return;
    final caret = wrapToLogicalOffset(c.text, sel.baseOffset);
    _trackEdit(prev, text, caret);
    if (learning.value && _learnFromReplace(prev, text)) _scheduleSave();
    // Yalnız TEK karakter yazılınca (yapıştırma, sesli yazma vb. değil).
    if (text.length != prev.length + 1) return;
    if (caret < 1 || caret > text.length) return;
    if (text.substring(0, caret - 1) + text.substring(caret) != prev) return;
    final typed = text[caret - 1];
    if (!' \n.,;:!?'.contains(typed)) return;

    // Biten kelime (sınırdan önceki harfler).
    final wm = _lastWord(text, caret - 1);
    // Kullanıcı az önceki kelimesini kendisi değiştirdiyse ÖĞREN; bu kelimeye
    // bu tur dokunulmaz (bilerek yazdı).
    final learnedNow = wm != null && _learnFromEdit(wm.start, wm.word);

    var next = text;
    var nextCaret = caret;
    String? autoFrom;
    String? autoTo;
    if (!learnedNow) {
      final edit = _title ? _titleFix(text, caret) : spellFixAt(text, caret);
      if (edit != null) {
        next = next.replaceRange(edit.start, edit.end, edit.text);
        nextCaret = edit.start + edit.text.length;
      }
      // Öğrenen hafıza (kural düzeltmesinden sonra, yalnız harf kelimede).
      final m = _lastWord(next, nextCaret - 1);
      if (m != null && _wordStartOk(next, m.start)) {
        final word = m.word;
        final s = memory.suggest(word);
        if (s != null && trUpper(word) != word) {
          final fixed = _matchCase(word, s);
          next = next.replaceRange(m.start, m.start + word.length, fixed);
          nextCaret += fixed.length - word.length;
          autoFrom = word;
          autoTo = fixed;
        }
      }
    }
    // Enter: biten satır son kontrolden geçer.
    if (typed == '\n' && !_title) {
      final lineStart = next.lastIndexOf('\n', nextCaret - 2) + 1;
      final line = next.substring(lineStart, nextCaret - 1);
      final done = finalizeLine(line);
      if (done != line) {
        next = next.replaceRange(lineStart, nextCaret - 1, done);
        nextCaret += done.length - line.length;
      }
    }
    if (next != text) _apply(c, next, nextCaret);
    // Biten kelimeyi izle (geri dönüp düzeltirse öğrenilsin).
    final fm = _lastWord(next, nextCaret - 1);
    if (fm != null) {
      final w = fm.word;
      _last = _Finished(fm.start, w, autoFrom: autoTo == w ? autoFrom : null);
      if (learning.value && autoFrom == null && !learnedNow) {
        memory.addWord(w);
        _scheduleSave();
      }
    } else {
      _last = null;
    }
    if (typed != '\n' && autoFrom == null && !learnedNow && !_title) {
      unawaited(_native(c, next, nextCaret));
    }
  }

  /// KLAVYE ÖNERİSİ / YERİNDE DEĞİŞTİRME (kullanıcı isteği 2026-11-08:
  /// "Android klavyesinin önerilerinden seçti, orası düzeldi — öğrenilmeli"):
  /// tek adımda bir kelimenin YERİNE başka bir kelime geldiyse (öneri
  /// çubuğundan seçim, kelimeye dokunup düzeltme) `eski → yeni` öğrenilir.
  /// Tamamlama ("yap" → "yapıyor") ve ilgisiz değişim (uzak mesafe)
  /// sayılmaz. Bedel: değişim başına iki uçtan ortak ön/son ek taraması.
  @visibleForTesting
  static ({String from, String to})? replacedWord(String prev, String text) {
    if (prev == text || (prev.length - text.length).abs() > 12) return null;
    var p = 0;
    final minLen = prev.length < text.length ? prev.length : text.length;
    while (p < minLen && prev[p] == text[p]) {
      p++;
    }
    var sfx = 0;
    while (sfx < minLen - p &&
        prev[prev.length - 1 - sfx] == text[text.length - 1 - sfx]) {
      sfx++;
    }
    final removedEnd = prev.length - sfx;
    final insertedEnd = text.length - sfx;
    // Saf ekleme (yazma) ya da saf silme: değiştirme değil.
    if (removedEnd <= p || insertedEnd <= p) return null;
    var start = p;
    while (start > 0 && _isLetter(prev[start - 1])) {
      start--;
    }
    var endOld = removedEnd;
    while (endOld < prev.length && _isLetter(prev[endOld])) {
      endOld++;
    }
    var endNew = insertedEnd;
    while (endNew < text.length && _isLetter(text[endNew])) {
      endNew++;
    }
    final from = prev.substring(start, endOld);
    final to = text.substring(start, endNew).trimRight();
    if (from.length < 3 || to.length < 2) return null;
    if (!from.split("").every(_isLetter)) return null;
    if (to.contains('\n') || to.split(' ').length > 2) return null;
    final lf = trLower(from);
    final lt = trLower(to);
    if (lf == lt || lt.startsWith(lf)) return null;
    // TÜRKÇE EK TUZAĞI (2026-11-09 düzeltme): BİLİNEN bir kelimenin yerine
    // başka biri gelmesi ("kalemi" → "kalemde") yazım hatası değil, dilbilgisi
    // seçimi. Öğrenilseydi iki seferden sonra her geçerli "kalemi" otomatik
    // değişirdi (öğrenilmiş düzeltme bilinen kelimede de uygulanır).
    if (memory.known(lf)) return null;
    final limit = SpellMemory.limitFor(lf.length) + 1.2;
    if (memory.distance(lf, lt.replaceAll(' ', ''), limit: limit) > limit &&
        memory.distance(lf, lt, limit: limit) > limit) {
      return null;
    }
    return (from: from, to: to);
  }

  static bool _learnFromReplace(String prev, String text) {
    final r = replacedWord(prev, text);
    if (r == null) return false;
    final last = _last;
    // Otomatik düzeltmeyi geri alma kendi yolunda ([_learnFromEdit]).
    if (last?.autoFrom != null && trLower(r.to) == trLower(last!.autoFrom!)) {
      return false;
    }
    memory.learnFix(r.from, r.to);
    return true;
  }

  /// Silme biten kelimenin içine/sonuna değiyorsa kelime "elle düzeltiliyor".
  static void _trackEdit(String prev, String text, int caret) {
    final last = _last;
    if (last == null) return;
    final end = last.start + last.word.length;
    if (text.length < prev.length) {
      if (caret >= last.start && caret <= end + 1) last.touched = true;
      return;
    }
    // Uzakta yazılıyor: izleme biter.
    if (caret < last.start || caret > end + 40) _last = null;
  }

  /// Kullanıcı [_last] kelimesini [word]e çevirdi mi? Öyleyse öğrenir.
  static bool _learnFromEdit(int start, String word) {
    final last = _last;
    if (last == null || !last.touched || last.start != start) return false;
    _last = null;
    if (word == last.word) return false;
    if (!learning.value) return true;
    final auto = last.autoFrom;
    if (auto != null && trLower(word) == trLower(auto)) {
      // Otomatik düzeltme geri alındı: bir daha dokunma.
      memory.reject(word, wrongFix: last.word);
    } else {
      memory.learnFix(auto ?? last.word, word);
    }
    _scheduleSave();
    return true;
  }

  /// Önerinin büyük/küçük harfi yazılan kelimeye uyar.
  static String _matchCase(String typed, String s) {
    if (typed.isEmpty || s.isEmpty) return s;
    final cap = typed[0] != typed[0].toLowerCase();
    return cap ? trUpper(s[0]) + s.substring(1) : s;
  }

  /// Kelime bağlantı/e-posta/sayı parçası değil (bkz. [spellFixAt]).
  static bool _wordStartOk(String text, int start) {
    final before = start == 0 ? ' ' : text[start - 1];
    return ' \n("\'«“*_~='.contains(before);
  }

  /// Başlık: kurallar + kelimenin baş harfi büyük (2026-11-08 isteği).
  static ({int start, int end, String text})? _titleFix(
    String text,
    int caret,
  ) => titleFixAt(text, caret);

  static void _apply(WrapTextController c, String next, int caret) {
    _busy = true;
    try {
      c.setLogical(next, caret);
      _prev = next;
      _commit?.call();
    } finally {
      _busy = false;
    }
  }

  static bool get _nativeAvailable => !kIsWeb && Platform.isAndroid;
  static final _service = DefaultSpellCheckService();

  /// Cihaz denetçisi: biten kelimenin ilk önerisi, yalnız klavye mesafesiyle
  /// yakınsa ve metin o arada değişmediyse. Boşluk yerine "n" basılmış
  /// kelimeyi iki parçası doğruysa böler.
  static Future<void> _native(
    WrapTextController c,
    String text,
    int caret,
  ) async {
    if (!_nativeAvailable) return;
    final m = _lastWord(text, caret - 1);
    if (m == null || m.word.length < 4) return;
    final word = m.word;
    if (trUpper(word) == word || isCjk(word)) return;
    if (memory.known(word) || memory.rejected.contains(trLower(word))) return;
    final locale = looksEnglish(word)
        ? const Locale('en', 'US')
        : const Locale('tr', 'TR');
    List<SuggestionSpan>? spans;
    try {
      spans = await _service.fetchSpellCheckSuggestions(locale, word);
    } catch (_) {
      return;
    }
    if (spans == null || spans.isEmpty) return; // Doğru kelime.
    var s = spans.first.suggestions.firstOrNull;
    if (s != null && !acceptSuggestion(word, s)) s = null;
    s ??= await _nativeSplit(word, locale);
    if (s == null || !identical(c, _c) || c.logicalText != text) return;
    final fixed = _matchCase(word, s);
    final next = text.replaceRange(m.start, m.start + word.length, fixed);
    final nextCaret = caret + fixed.length - word.length;
    _apply(c, next, nextCaret);
    _last = _Finished(m.start, fixed, autoFrom: word);
  }

  /// "eksiknyapılıyor": boşluk komşusu harfte bölünen iki parça da cihaz
  /// denetçisine göre doğruysa.
  static Future<String?> _nativeSplit(String word, Locale locale) async {
    final w = trLower(word);
    for (var i = 2; i < w.length - 2; i++) {
      if (w[i] != 'n' && w[i] != 'b' && w[i] != 'm') continue;
      final left = w.substring(0, i);
      final right = w.substring(i + 1);
      try {
        final a = await _service.fetchSpellCheckSuggestions(locale, left);
        if (a != null && a.isNotEmpty) continue;
        final b = await _service.fetchSpellCheckSuggestions(locale, right);
        if (b != null && b.isNotEmpty) continue;
        return '$left $right';
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Önerinin otomatik uygulanacak kadar yakın olup olmadığı: klavye
  /// komşuluğuyla ağırlıklı mesafe ([SpellMemory.distance]).
  @visibleForTesting
  static bool acceptSuggestion(String word, String s) {
    final a = trLower(word);
    final b = trLower(s);
    if (a == b || b.isEmpty) return false;
    // İlk harf aynı ya da komşu tuş/şapka eşi.
    if (a[0] != b[0] && keyCost(a[0], b[0]) > 0.5) return false;
    final limit = SpellMemory.limitFor(a.length) + 0.4;
    return memory.distance(a, b, limit: limit) <= limit;
  }
}

class _Finished {
  _Finished(this.start, this.word, {this.autoFrom});

  final int start;
  final String word;

  /// Kelime otomatik düzeltmeyle geldiyse kullanıcının yazdığı hâli.
  final String? autoFrom;
  bool touched = false;
}
