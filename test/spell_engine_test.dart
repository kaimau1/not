import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// Alanı klavye gibi sürer: tek karakter yazma, Backspace, aralık değiştirme.
class _Kb {
  _Kb() {
    AutoSpell.attach(c, () {});
  }

  final c = WrapTextController();
  String get t => c.logicalText;

  void type(String s) {
    for (final ch in s.split('')) {
      final caret = c.selection.isValid ? c.selection.baseOffset : t.length;
      final next = t.replaceRange(caret, caret, ch);
      c.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: caret + 1),
      );
    }
  }

  void backspace() {
    final caret = c.selection.baseOffset;
    c.value = TextEditingValue(
      text: t.replaceRange(caret - 1, caret, ''),
      selection: TextSelection.collapsed(offset: caret - 1),
    );
  }

  /// [from] kelimesini (ilk geçiş) [to] yapar, imleç sona döner.
  void replaceWord(String from, String to) {
    final i = t.indexOf(from);
    final next = t.replaceRange(i, i + from.length, to);
    c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: i + to.length),
    );
    c.selection = TextSelection.collapsed(offset: next.length);
  }

  void end() => c.selection = TextSelection.collapsed(offset: t.length);
}

void main() {
  late SpellMemory saved;
  late bool savedOn;
  setUp(() {
    saved = AutoSpell.memory;
    savedOn = AutoSpell.enabled.value;
    AutoSpell.memory = SpellMemory();
    AutoSpell.enabled.value = true;
  });
  tearDown(() {
    AutoSpell.memory = saved;
    AutoSpell.enabled.value = savedOn;
  });

  group('F70.0 ısrar', () {
    test('otomatik düzeltmeyi sonradan değiştirince aynı kelime geri gelmez', () {
      final kb = _Kb();
      kb.type('bu kalen ');
      expect(kb.t, 'Bu kalem ');
      kb.type('aldım ');
      // Kullanıcı geri dönüp "kalem"i "kamel" yapar (bir kelime sonra).
      kb.replaceWord('kalem', 'kalin');
      kb.end();
      kb.type('bir kalen ');
      expect(kb.t.endsWith('bir kalem '), isFalse, reason: kb.t);
    });

    test('klavye önerisiyle değiştirilen düzeltme geri gelmez', () {
      final kb = _Kb();
      kb.type('bu kalen ');
      expect(kb.t, 'Bu kalem ');
      kb.replaceWord('kalem', 'kalin');
      kb.type('bir kalen ');
      expect(kb.t.endsWith('bir kalem '), isFalse, reason: kb.t);
    });
  });
}
