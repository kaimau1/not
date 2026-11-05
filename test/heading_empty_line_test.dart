import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/presentation/editor/format_menu.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// Boş satırda başlık seçmek BEKLEYEN biçim olur (kullanıcı isteği
/// 2026-11-05: "başlık / alt başlık düğmeye basarak sırayla geçsin" — yeni
/// satırda "Başlık"a basıp yazmak).
void main() {
  test('boş satırda başlık bekler, düzey görünür, Metin kaldırır', () {
    final c = WrapTextController(text: 'abc\n');
    c.selection = const TextSelection.collapsed(offset: 4);
    expect(applyRichHeading(c, RichHeading.h1), isFalse);
    expect(c.text, 'abc\n');
    expect(c.hasPendingFormat, isTrue);
    expect(activeRichHeading(c), RichHeading.h1);
    expect(applyRichHeading(c, RichHeading.h2), isFalse);
    expect(activeRichHeading(c), RichHeading.h2);
    expect(applyRichHeading(c, RichHeading.normal), isFalse);
    expect(c.hasPendingFormat, isFalse);
    expect(activeRichHeading(c), RichHeading.normal);
  });

  test('dolu satırda eskisi gibi satırı başlık yapar', () {
    final c = WrapTextController(text: 'abc');
    c.selection = const TextSelection.collapsed(offset: 1);
    expect(applyRichHeading(c, RichHeading.h1), isTrue);
    expect(c.hasPendingFormat, isFalse);
    expect(activeRichHeading(c), RichHeading.h1);
  });
}
