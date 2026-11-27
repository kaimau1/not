import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';

import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/local_file.dart' show appSupportPath;
import '../../../../core/utils/spell_engine.dart';
import '../../../../core/utils/spell_fix.dart';
import '../../../../core/utils/spell_learn.dart';
import '../../../../core/utils/tr_lexicon.dart';
import 'text_wrap.dart';

/// **YAZIM DÜZELT v2 — alan bağlama** (Faz 70). Karar [SpellEngine.decide]'da;
/// burada yalnız: kelime bitişini algılamak (tek karakterlik sınır yazımı —
/// yapıştırma/dikte değil), kararı uygulamak, cümle başı büyük harf ve
/// noktalama ([spellFixAt], kelime kuralı olmadan), Enter'da satır sonu
/// ([finalizeLine]) ve kullanıcının tepkisini hafızaya yazmak:
///
/// * **Backspace geri alır** (ilke 3): otomatik düzeltmeden hemen sonra tek
///   Backspace özgün yazıyı getirir; çift reddedilir, kelime bu notta bir
///   daha düzeltilmez.
/// * **Kullanıcının düzeltmesi kutsaldır** (ilke 1): biten kelimeler izlenir;
///   otomatik düzeltilmiş bir kelime SONRADAN (silip yazarak ya da klavye
///   önerisiyle) değiştirilirse çift ilk seferde reddedilir, yazılan da
///   öğrenilir. Kendi kelimesini düzeltirse `yanlış → doğru` sayılır (iki
///   kez görülünce uygulanır).
///
/// Editör kasma kuralları: kök `setState` yok; yalnız denetleyiciye yazar.
///
/// **Y-4 üç kip** ([mode]): Kapalı / Yalnız göster (altı çizili denetim,
/// `spell_underline.dart`; hiçbir şeyi değiştirmez) / Otomatik düzelt
/// (göster + düzelt). KARAR (kullanıcı, 2026-11-17): varsayılan "Yalnız
/// göster"; eski otomatik düzelt anahtarı açık olan "Otomatik"te kalır.
enum SpellMode { off, show, auto }

class AutoSpell {
  AutoSpell._();

  /// **YAZIM DİLİ** (kullanıcı 2026-11-27: beş pazar dili tr, en, ar, id,
  /// ms). Uygulamanın kendi motoru (kurallar, harfsiz yazım, ek çözücü,
  /// öğrenme önerileri) Türkçe + İngilizce için yazıldı; Arapça, Endonezce
  /// ve Malayca'da Türkçe kurallar DOĞRU kelimeyi bozardı ("saya" → "şaya").
  /// Bu dillerde yalnız cihazın denetçisi (Gboard, o dilde) çizer; otomatik
  /// düzeltmeyi klavye yapar. Dil: Ayarlar'da seçilen uygulama dili, yoksa
  /// cihaz dili.
  static String writingLanguage = 'tr';

  /// Uygulamanın kendi yazım motoru bu dilde çalışır mı.
  static bool get ownEngine => !_foreignOnly.contains(writingLanguage);
  static const _foreignOnly = {'ar', 'id', 'ms'};

  /// Yazım dilini ayarlar; değişirse altı çizili denetim yenilenir.
  static void setWritingLanguage(String code) {
    if (code == writingLanguage) return;
    writingLanguage = code;
    // Uygulama kökünün build'inden çağrılır: dinleyiciler build sırasında
    // uyarılmasın.
    scheduleMicrotask(_bump);
  }

  /// Otomatik düzelt açık mı (= [mode] otomatik). Eski dinleyiciler için.
  static final enabled = ValueNotifier<bool>(false);

  /// Yükleme bitene dek kapalı: boş hafızayla çizgi çekilmesin.
  static final mode = ValueNotifier<SpellMode>(SpellMode.off);

  /// Hafıza ya da "bu notta dokunma" değişti: altı çizili denetimin
  /// önbellekleri boşalır, alanlar yeniden denetlenir.
  static final revision = ValueNotifier<int>(0);
  static void _bump() => revision.value++;

  /// Öğrenme açık mı (ayrı anahtar; varsayılan açık).
  static final learning = ValueNotifier<bool>(true);

  /// Yalnız açık kurallar (tablo + öğretilenler); bulanık ve cihaz önerisi
  /// yok.
  static final rulesOnly = ValueNotifier<bool>(false);

  /// İşaretli (yapıldı) maddeler de denetlensin mi — varsayılan HAYIR
  /// (kullanıcı 2026-11-24: bitmiş maddenin yazımı önemsiz, çizgi gürültü).
  static final checkDone = ValueNotifier<bool>(false);
  static const _checkDoneKey = 'spell_check_done';
  static const _key = 'auto_spell_on';
  static const _modeKey = 'spell_mode';
  static const _learnKey = 'auto_spell_learn';
  static const _rulesKey = 'auto_spell_rules_only';
  static const _memoryPrefV1 = 'spell_memory_v1';
  static const _memoryPref = 'spell_memory_v2';
  static const _memoryFile = 'spell_memory.json';

  static bool _loaded = false;

  /// Kişisel yazım hafızası (bkz. [SpellMemory]).
  static SpellMemory memory = SpellMemory();

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final m = savedMode(p.getInt(_modeKey), p.getBool(_key));
      enabled.value = m == SpellMode.auto;
      learning.value = p.getBool(_learnKey) ?? true;
      rulesOnly.value = p.getBool(_rulesKey) ?? false;
      checkDone.value = p.getBool(_checkDoneKey) ?? false;
      try {
        memory = SpellMemory.decode(await _readMemory(p));
        if (memory.fromV1) await _migrate();
      } catch (_) {}
      mode.value = m;
    } catch (_) {}
    unawaited(ensureLexicon());
  }

  /// **BÜYÜK KÖK SÖZLÜĞÜ** (Zemberek, 2026-11-26; bkz. [TrLexicon]): ilk
  /// editör açılışından [lexiconDelay] sonra bir kez, arka planda yüklenir
  /// (metin çözme ve satır dizini ayrı isolate'te; açılış geçişiyle aynı
  /// karelere binmesin). Yüklenince altı çizili denetim yeniden taranır.
  static Future<void> ensureLexicon() => _lexicon ??= _loadLexicon();
  static Future<void>? _lexicon;
  static const lexiconAsset = 'assets/spell/tr_lexicon.txt';
  static const lexiconDelay = Duration(seconds: 2);

  /// Testte kapalı (sözlük ortasında yüklenip sonuçları değiştirmesin;
  /// sözlüklü ölçüm `spell_corpus_test` "büyük sözlük yüklü").
  @visibleForTesting
  static bool lexiconEnabled =
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  static TrLexicon _parseLexiconBytes(Uint8List bytes) =>
      TrLexicon.parse(utf8.decode(bytes));

  static Future<void> _loadLexicon() async {
    if (!lexiconEnabled || TrLexicon.instance != null) return;
    try {
      await Future<void>.delayed(lexiconDelay);
      final data = await rootBundle.load(lexiconAsset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final lex = kIsWeb
          ? _parseLexiconBytes(bytes)
          : await compute(_parseLexiconBytes, Uint8List.fromList(bytes));
      TrLexicon.install(lex);
      _bump();
    } catch (_) {
      _lexicon = null; // sonraki açılışta yeniden denenir
    }
  }

  /// Kayıtlı kip; yoksa (Y-4 öncesi kurulum) eski otomatik düzelt anahtarı
  /// açıksa otomatik, değilse "Yalnız göster" (KARAR 2026-11-17).
  @visibleForTesting
  static SpellMode savedMode(int? mode, bool? oldAuto) =>
      mode != null && mode >= 0 && mode < SpellMode.values.length
      ? SpellMode.values[mode]
      : oldAuto ?? false
      ? SpellMode.auto
      : SpellMode.show;

  static Future<String?> _readMemory(SharedPreferences p) async {
    final base = appSupportPath;
    if (kIsWeb || base == null) {
      return p.getString(_memoryPref) ?? p.getString(_memoryPrefV1);
    }
    final f = File('$base/$_memoryFile');
    return await f.exists() ? f.readAsString() : null;
  }

  /// F70.4: v1 dosyası bir sürüm boyunca `.v1` adıyla saklanır (web'de eski
  /// tercih anahtarı olduğu gibi kalır), hafıza v2 yazılır.
  static Future<void> _migrate() async {
    final base = appSupportPath;
    if (!kIsWeb && base != null) {
      final old = File('$base/$_memoryFile');
      final backup = File('$base/$_memoryFile.v1');
      if (await old.exists() && !await backup.exists()) {
        await old.copy(backup.path);
      }
    }
    memory.fromV1 = false;
    await _save();
  }

  static Timer? _saveTimer;

  static void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 4), () => unawaited(_save()));
  }

  @visibleForTesting
  static String trimMemoryForWeb(
    SpellMemory mem, {
    int maxBytes = 120000,
  }) {
    final raw = mem.encode();
    if (raw.length <= maxBytes || mem.words.isEmpty) return raw;
    // Web localStorage şişmesin diye en düşük sıklıklı kelime sayımlarını at,
    // kişisel düzeltme (`fixes`), `keep` ve `rejected` kararlarını koru.
    final kept = SpellMemory()
      ..fixes.addAll(mem.fixes)
      ..keep.addAll(mem.keep)
      ..rejected.addAll(mem.rejected);
    final entries = mem.words.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var lo = 0;
    var hi = entries.length;
    var best = kept.encode();
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      kept.words
        ..clear()
        ..addEntries(entries.take(mid));
      final encoded = kept.encode();
      if (encoded.length <= maxBytes) {
        best = encoded;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return best;
  }

  static Future<void> _save() async {
    try {
      final base = appSupportPath;
      if (kIsWeb || base == null) {
        final p = await SharedPreferences.getInstance();
        await p.setString(_memoryPref, trimMemoryForWeb(memory));
      } else {
        await File('$base/$_memoryFile').writeAsString(memory.encode());
      }
    } catch (_) {}
  }

  static void _setPref(String key, bool v) => unawaited(
    SharedPreferences.getInstance()
        .then((p) => p.setBool(key, v))
        .catchError((_) => false),
  );

  /// Hızlı satırdaki düğme: otomatik düzelt ↔ yalnız göster.
  static void toggle() =>
      setMode(enabled.value ? SpellMode.show : SpellMode.auto);

  static void setMode(SpellMode m) {
    mode.value = m;
    final auto = m == SpellMode.auto;
    if (auto != enabled.value) {
      enabled.value = auto;
      // Kapalıyken değişiklik izlenmedi: izleme baştan.
      _words.clear();
      _undo = null;
      _prev = _c?.logicalText ?? '';
    }
    _setPref(_key, auto);
    unawaited(
      SharedPreferences.getInstance()
          .then((p) => p.setInt(_modeKey, m.index))
          .catchError((_) => false),
    );
  }

  static void setLearning(bool on) {
    learning.value = on;
    _setPref(_learnKey, on);
  }

  static void setCheckDone(bool on) {
    checkDone.value = on;
    _setPref(_checkDoneKey, on);
  }

  static void setRulesOnly(bool on) {
    rulesOnly.value = on;
    _setPref(_rulesKey, on);
  }

  /// Ayarlar ekranındaki elle değişiklikten sonra kaydet.
  static void changed() {
    _scheduleSave();
    _bump();
  }

  /// Öğrenilenleri siler.
  static void forget() {
    memory = SpellMemory()..seed(memory.seeded);
    unawaited(_save());
    _bump();
  }

  /// Y-6: bulutla birleştirilmiş kişisel yazım hafızasını uygular ve
  /// hemen kaydeder (altı çizili önbellekler de boşalır).
  static Future<void> applyRemoteSync(Map<String, Object?> merged) async {
    memory.applySyncMap(merged);
    await _save();
    _bump();
  }

  // ---- Y-4 altı çizili denetimin menüsü ----------------------------------

  /// "Sözlüğe ekle": kelime hiç düzeltilmez, altı çizilmez.
  static void addToDictionary(String word) {
    memory.keep.add(trLower(word));
    changed();
  }

  /// "Hep böyle düzelt": öğretilen düzeltme (onaylı, ilk görüşte uygulanır).
  static void alwaysFix(String word, String to) {
    memory.learnFix(word, to, confirmed: true);
    changed();
  }

  /// "Elle düzelt" ile girilen düzeltmeyi hemen öğrenir: hem `word → to`
  /// eşleşmesini onaylı kaydeder hem de doğru kelimeyi sözlüğe işler.
  static void learnManualFix(String word, String to) {
    memory.addManualFix(word, to);
    changed();
  }

  /// Öneri menüsünden seçilen düzeltmeyi öğrenme hafızasına işler.
  static void recordSuggestionPick(String word, String to) {
    if (!learning.value) return;
    memory.learnFix(word, to);
    changed();
  }

  /// "Bu notta dokunma": geri alınan otomatik düzeltmeyle aynı yol.
  static void keepInNote(String word, String? to) {
    if (to != null) return _reject(word, to);
    _noteKeep.add(trLower(word));
    _bump();
  }

  /// Bu notta dokunulmayacak kelimeler (küçük harf).
  static Set<String> get noteKeep => _noteKeep;

  static bool _seeding = false;

  /// Notların metninden kişisel sözlük kurar (arka planda, oturumda bir kez).
  static Future<void> seedFrom(List<String> Function() texts) async {
    if (_seeding || memory.seeded.isNotEmpty || mode.value == SpellMode.off) {
      return;
    }
    final sample = texts();
    if (sample.isEmpty) return;
    _seeding = true;
    try {
      final counts = await compute(seedCounts, sample);
      memory.seed(counts);
      _bump();
    } finally {
      _seeding = false;
    }
  }

  /// Bu notta otomatik düzeltilmeyecek kelimeler (ilke 1); not açılınca
  /// [beginNote] boşaltır.
  static final Set<String> _noteKeep = {};

  static void beginNote() {
    if (_noteKeep.isEmpty) return;
    _noteKeep.clear();
    _bump();
  }

  static WrapTextController? _c;
  static VoidCallback? _commit;
  static String _prev = '';
  static bool _busy = false;
  static bool _title = false;

  /// Bu alanda biten son kelimeler (geri dönülüp değiştirilirse öğrenilir).
  static final List<_Tracked> _words = [];
  static const _maxTracked = 30;

  /// Son otomatik düzeltme; yalnız hemen ardından gelen Backspace için.
  static _Undo? _undo;

  /// Bu değişiklikte kararı verilen (kullanıcının elle değiştirdiği) kelime
  /// başı: aynı tur yeniden düzeltilmez.
  static int? _decidedStart;

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
    if (old != null) _settleAll(old.logicalText);
    if (old != null && enabled.value && !oldTitle) {
      _finalizeWhole(old, oldCommit);
    }
    _c = controller;
    _commit = commit;
    _title = title;
    _prev = controller.logicalText;
    controller.addListener(_onChange);
  }

  static void detach(WrapTextController controller) {
    if (!identical(controller, _c)) return;
    controller.removeListener(_onChange);
    _settleAll(controller.logicalText);
    _c = null;
    _commit = null;
  }

  static void _finalizeWhole(WrapTextController c, VoidCallback? commit) {
    try {
      final text = c.logicalText;
      final lines = text.split('\n');
      if (lines.isEmpty) return;
      final last = finalizeLine(lines.last);
      if (last == lines.last) return;
      // Yalnız SON satırın başı ve sonu değişebilir — beklenmeyen bir fark
      // (alan o arada başka metinle dolmuş) varsa dokunma (2026-11-08).
      if (last.length > lines.last.length + 1) return;
      lines[lines.length - 1] = last;
      final next = lines.join('\n');
      _busy = true;
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

  /// Metnin [end]e kadarki son harf dizisi (geriye doğru tarar).
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
    final auto = enabled.value && ownEngine;
    final learnShow = mode.value == SpellMode.show && learning.value;
    if (c == null || _busy || (!auto && !learnShow)) return;
    final text = c.logicalText;
    if (text == _prev) return;
    final prev = _prev;
    _prev = text;
    final sel = c.selection;
    final caret = sel.isValid
        ? wrapToLogicalOffset(c.text, sel.baseOffset)
        : -1;

    // İlke 3: düzeltmeden hemen sonra tek Backspace → özgün yazı.
    final u = _undo;
    _undo = null;
    if (auto &&
        u != null &&
        prev == u.after &&
        sel.isCollapsed &&
        caret == u.caret - 1 &&
        text == prev.replaceRange(caret, caret + 1, '')) {
      _revert(c, u, text, caret);
      return;
    }

    final touched = _track(prev, text);
    if (!touched && learning.value) {
      final r = SpellEngine.replacedWord(prev, text, memory);
      if (r != null) {
        memory.learnFix(r.from, r.to);
        changed();
      }
    }

    // Yalnız TEK karakter yazılınca (yapıştırma, sesli yazma vb. değil).
    if (!sel.isValid || !sel.isCollapsed) return;
    if (text.length != prev.length + 1) return;
    if (caret < 1 || caret > text.length) return;
    if (text.substring(0, caret - 1) + text.substring(caret) != prev) return;
    final typed = text[caret - 1];
    if (!' \n.,;:!?'.contains(typed)) return;

    var wordEnd = caret - 1;
    if (',.;:!?'.contains(typed) && caret >= 2 && text[caret - 2] == ' ') {
      wordEnd = caret - 2;
    }
    final wm = _lastWord(text, wordEnd);
    if (!auto) {
      // Yalnız göster kipinde otomatik düzeltme YOK; biten kelime izlenir ki
      // kullanıcı geri dönüp elle düzeltirse hafıza öğrensin.
      if (wm != null && _wordStartOk(text, wm.start)) {
        _remember(_Tracked(wm.start, wm.word, null));
      }
      return;
    }
    var next = text;
    var nextCaret = caret;
    // Önce cümle başı büyük harf ve noktalama (kelime kuralı motorda);
    // kelimenin başı ve boyu değişmez.
    final edit = _title
        ? titleFixAt(next, nextCaret, fixWord: _same)
        : spellFixAt(next, nextCaret, fixWord: _same);
    if (edit != null) {
      next = next.replaceRange(edit.start, edit.end, edit.text);
      nextCaret = edit.start + edit.text.length;
    }
    String? autoFrom;
    String? autoTo;
    if (wm != null &&
        wm.start != _decidedStart &&
        _wordStartOk(text, wm.start)) {
      final shown = next.substring(wm.start, wm.start + wm.word.length);
      final d = _decide(shown);
      if (!d.isNone) {
        next = next.replaceRange(wm.start, wm.start + shown.length, d.to!);
        nextCaret += d.to!.length - shown.length;
        autoFrom = wm.word;
        autoTo = d.to;
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
    if (next != text) {
      // Arkadaki izlenen kelimeler düzeltmenin boy farkı kadar kayar.
      if (wm != null) _shiftAfter(wm.start, next.length - text.length);
      _apply(c, next, nextCaret);
    }
    if (wm == null) return;
    // Büyük harf uzunluğu değiştirmez: son kelime düzeltilenin boyunda.
    final word = next.substring(
      wm.start,
      (wm.start + (autoTo ?? wm.word).length).clamp(wm.start, next.length),
    );
    _remember(_Tracked(wm.start, word, autoFrom));
    if (autoFrom != null) {
      _undo = _Undo(next, nextCaret, wm.start, word, autoFrom);
    } else if (learning.value && wm.start != _decidedStart) {
      memory.addWord(word);
      _scheduleSave();
    }
    if (autoFrom == null &&
        typed != '\n' &&
        !_title &&
        !rulesOnly.value &&
        wm.start != _decidedStart) {
      unawaited(_native(c, next, nextCaret, wm.start, word));
    }
  }

  static String _same(String w) => w;

  static SpellDecision _decide(String word, {List<String>? device}) =>
      SpellEngine.decide(
        SpellInput(
          word: word,
          memory: memory,
          title: _title,
          rulesOnly: rulesOnly.value,
          noteKeep: _noteKeep,
          device: device,
        ),
      );

  static void _shiftAfter(int start, int delta) {
    if (delta == 0) return;
    for (final t in _words) {
      if (t.start > start) t.start += delta;
    }
  }

  static void _remember(_Tracked t) {
    _words.removeWhere((w) => w.start == t.start);
    _words.add(t);
    if (_words.length > _maxTracked) _words.removeAt(0);
  }

  /// Otomatik düzeltme reddedildi: çift bir daha uygulanmaz, kelime bu
  /// notta bir daha düzeltilmez.
  static void _reject(String from, String to) {
    _noteKeep.add(trLower(from));
    _bump();
    if (!learning.value) return;
    memory.rejectPair(from, to);
    _scheduleSave();
  }

  static void _revert(WrapTextController c, _Undo u, String text, int caret) {
    final next = text.replaceRange(u.start, u.start + u.word.length, u.from);
    _words.removeWhere((w) => w.start == u.start);
    _shiftAfter(u.start, u.from.length - u.word.length);
    _reject(u.from, u.word);
    _apply(c, next, caret + u.from.length - u.word.length);
  }

  /// İzlenen kelimeleri tek değişikliğe göre kaydırır; değişiklik bir
  /// kelimeye değdiyse onu "elle düzenleniyor" işaretler, düzenleme başka
  /// yere geçince kararı verir. Bir kelimeye değdiyse true.
  static bool _track(String prev, String text) {
    _decidedStart = null;
    if (_words.isEmpty) return false;
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
    final rEnd = prev.length - sfx;
    final ins = text.substring(p, text.length - sfx);
    final delta = text.length - prev.length;
    var hit = false;
    for (final t in _words.toList()) {
      final s = t.start;
      final e = t.start + t.len;
      // Eklenen yazı kelimeye harfle mi yapışıyor (önüne / arkasına).
      final joinsBefore = ins.isNotEmpty && _isLetter(ins[ins.length - 1]);
      final joinsAfter = ins.isNotEmpty && _isLetter(ins[0]);
      if (rEnd < s || (rEnd == s && (p < s || !joinsBefore))) {
        t.start += delta; // Önünde: kayar.
      } else if (p > e || (p == e && !(rEnd == e && joinsAfter))) {
        // Arkasında: düzenleme kelimeden ayrıldı.
        if (t.touched) {
          _settle(t, text);
          _decidedStart = t.start;
          hit = true;
        }
      } else if (p <= s && rEnd >= e && (p < s || rEnd > e)) {
        _words.remove(t); // Kelime bütünüyle silindi/değişti.
      } else {
        t.len += delta;
        t.touched = true;
        hit = true;
      }
    }
    return hit;
  }

  static void _settleAll(String text) {
    for (final t in _words.toList()) {
      if (t.touched) _settle(t, text);
    }
    _words.clear();
    _undo = null;
  }

  /// Elle düzenlenen kelimenin son hâli: özgünüyle aynıysa (ya da önüne/
  /// arkasına yeni kelime eklendiyse) bir şey yok; değiştiyse öğren/reddet.
  static void _settle(_Tracked t, String text) {
    _words.remove(t);
    if (t.start < 0 || t.start > text.length) return;
    final cur = text
        .substring(t.start, (t.start + t.len).clamp(t.start, text.length))
        .trim();
    final w = t.word;
    if (cur.isEmpty || cur.contains('\n')) return;
    if (cur == w || cur.endsWith(' $w') || cur.startsWith('$w ')) return;
    final from = t.from;
    if (from != null) {
      _reject(from, w);
      if (learning.value &&
          trLower(cur) != trLower(from) &&
          SpellEngine.learnable(from, cur, memory)) {
        memory.learnFix(from, cur, confirmed: true);
      }
    } else if (learning.value && SpellEngine.learnable(w, cur, memory)) {
      memory.learnFix(w, cur);
      changed();
    }
  }

  /// Kelime bağlantı/e-posta/sayı parçası değil (bkz. [spellFixAt]).
  static bool _wordStartOk(String text, int start) {
    final before = start == 0 ? ' ' : text[start - 1];
    return ' \n("\'«“*_~='.contains(before);
  }

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

  /// Cihaz denetçisinin önerileri motora ikinci turda verilir; metin o
  /// arada değiştiyse uygulanmaz.
  static Future<void> _native(
    WrapTextController c,
    String text,
    int caret,
    int start,
    String word,
  ) async {
    if (!_nativeAvailable || word.length < 4 || !ownEngine) return;
    if (memory.known(word) || isCjk(word)) return;
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
    final d = _decide(word, device: spans.first.suggestions);
    if (d.isNone || !identical(c, _c) || c.logicalText != text) return;
    final next = text.replaceRange(start, start + word.length, d.to!);
    final nextCaret = caret + d.to!.length - word.length;
    _apply(c, next, nextCaret);
    _remember(_Tracked(start, d.to!, word));
    _undo = _Undo(next, nextCaret, start, d.to!, word);
  }
}

/// Biten kelime; [from] = otomatik düzeltildiyse kullanıcının yazdığı.
class _Tracked {
  _Tracked(this.start, this.word, this.from) : len = word.length;

  int start;
  int len;
  final String word;
  final String? from;
  bool touched = false;
}

class _Undo {
  _Undo(this.after, this.caret, this.start, this.word, this.from);

  /// Düzeltmeden sonraki metin ve imleç.
  final String after;
  final int caret;
  final int start;
  final String word;
  final String from;
}
