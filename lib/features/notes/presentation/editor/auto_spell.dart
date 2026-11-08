import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/spell_fix.dart';
import 'text_wrap.dart';

/// **YAZIM DÜZELT** (hızlı satırda aç/kapa, kullanıcı isteği 2026-11-08):
/// açıkken her biten kelime SORULMADAN düzeltilir — önce Türkçe kurallar
/// ([spellFixAt]), sonra Android'in yazım denetçisinin ilk önerisi (yakınsa);
/// Enter / yeni maddede satır son kontrolden geçer ([finalizeLine]).
///
/// Etkin alan değiştikçe [attach] çağrılır (editörün biçim hedefiyle aynı
/// yerden); dinleyici kapalıyken yalnız bir bool okur.
class AutoSpell {
  AutoSpell._();

  static final enabled = ValueNotifier<bool>(false);
  static const _key = 'auto_spell_on';

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      enabled.value = p.getBool(_key) ?? false;
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

  static WrapTextController? _c;
  static VoidCallback? _commit;
  static String _prev = '';
  static bool _busy = false;

  /// [controller] artık yazılan alan; önceki alan bırakılırken son satırı
  /// son kontrolden geçer (yeni maddeye geçiş).
  static void attach(WrapTextController controller, VoidCallback commit) {
    if (identical(controller, _c)) {
      _commit = commit;
      return;
    }
    final old = _c;
    final oldCommit = _commit;
    old?.removeListener(_onChange);
    if (old != null && enabled.value) _finalizeWhole(old, oldCommit);
    _c = controller;
    _commit = commit;
    _prev = controller.logicalText;
    controller.addListener(_onChange);
  }

  static void detach(WrapTextController controller) {
    if (!identical(controller, _c)) return;
    controller.removeListener(_onChange);
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
      lines[lines.length - 1] = last;
      final next = lines.join('\n');
      _busy = true;
      c.setLogical(next, next.length);
      commit?.call();
    } catch (_) {
      // Bırakılan alan atılmış olabilir.
    } finally {
      _busy = false;
    }
  }

  static void _onChange() {
    final c = _c;
    if (c == null || _busy || !enabled.value) return;
    final text = c.logicalText;
    if (text == _prev) return;
    final prev = _prev;
    _prev = text;
    final sel = c.selection;
    if (!sel.isValid || !sel.isCollapsed) return;
    // Yalnız TEK karakter yazılınca (yapıştırma, sesli yazma vb. değil).
    if (text.length != prev.length + 1) return;
    final caret = wrapToLogicalOffset(c.text, sel.baseOffset);
    if (caret < 1 || caret > text.length) return;
    if (text.substring(0, caret - 1) + text.substring(caret) != prev) return;
    var edit = spellFixAt(text, caret);
    var next = text;
    var nextCaret = caret;
    if (edit != null) {
      next = next.replaceRange(edit.start, edit.end, edit.text);
      nextCaret = edit.start + edit.text.length;
    }
    // Enter: biten satır son kontrolden geçer.
    if (text[caret - 1] == '\n') {
      final lineStart = next.lastIndexOf('\n', nextCaret - 2) + 1;
      final line = next.substring(lineStart, nextCaret - 1);
      final done = finalizeLine(line);
      if (done != line) {
        next = next.replaceRange(lineStart, nextCaret - 1, done);
        nextCaret += done.length - line.length;
      }
    }
    if (next != text) _apply(c, next, nextCaret);
    if (text[caret - 1] != '\n') unawaited(_native(c, next, nextCaret));
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

  /// Cihaz denetçisi: biten kelimenin ilk önerisi, yalnız yakınsa
  /// (Levenshtein ≤ 2, ilk harf aynı) ve metin o arada değişmediyse.
  static Future<void> _native(
    WrapTextController c,
    String text,
    int caret,
  ) async {
    if (!_nativeAvailable) return;
    final m = RegExp(r'([\p{L}]{4,})[^\p{L}]$', unicode: true)
        .firstMatch(text.substring(0, caret));
    if (m == null) return;
    final word = m.group(1)!;
    if (trUpper(word) == word) return;
    List<SuggestionSpan>? spans;
    try {
      spans = await _service.fetchSpellCheckSuggestions(
        const Locale('tr', 'TR'),
        word,
      );
    } catch (_) {
      return;
    }
    final s = spans?.firstOrNull?.suggestions.firstOrNull;
    if (s == null || !identical(c, _c) || c.logicalText != text) return;
    if (!acceptSuggestion(word, s)) return;
    final next = text.replaceRange(m.start, m.start + word.length, s);
    _apply(c, next, caret + s.length - word.length);
  }

  /// Önerinin otomatik uygulanacak kadar yakın olup olmadığı.
  @visibleForTesting
  static bool acceptSuggestion(String word, String s) {
    if (s.toLowerCase() == word.toLowerCase()) return false;
    if (s.isEmpty || s[0].toLowerCase() != word[0].toLowerCase()) return false;
    return _distance(word.toLowerCase(), s.toLowerCase()) <= 2;
  }

  static int _distance(String a, String b) {
    var row = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final next = [i, ...List.filled(b.length, 0)];
      for (var j = 1; j <= b.length; j++) {
        next[j] = math.min(
          math.min(next[j - 1] + 1, row[j] + 1),
          row[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
        );
      }
      row = next;
    }
    return row[b.length];
  }
}
