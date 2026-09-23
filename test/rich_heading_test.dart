import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';

/// Satır başlığı = boy kademesi + kalın, satırın TAMAMINA (bkz.
/// [setLineHeading]).
void main() {
  test('imlecin satırı büyük başlık olur, diğer satırlar dokunulmaz', () {
    const text = 'Alışveriş\nsüt al';
    // İmleç ilk satırın ortasında.
    final r = setLineHeading(text, 3, 3, RichHeading.h1);
    expect(stripRichMarkers(r.text), text);
    expect(lineHeadingAt(r.text, 0), RichHeading.h1);
    // İkinci satır düz kaldı.
    final second = r.text.indexOf('süt');
    expect(lineHeadingAt(r.text, second), RichHeading.normal);
    // Satır kalın.
    expect(activeFormats(r.text, 1, 4).bold, isTrue);
    // İmleç satırın sonunda.
    expect(r.start, r.end);
  });

  test('alt başlık → normal: boy ve kalınlık kalkar, metin aynen kalır', () {
    const text = 'Toplantı notları';
    final h2 = setLineHeading(text, 0, 0, RichHeading.h2);
    expect(lineHeadingAt(h2.text, 0), RichHeading.h2);
    final back = setLineHeading(h2.text, 0, 0, RichHeading.normal);
    expect(back.text, text);
  });

  test('boş satırda hiçbir şey yazılmaz', () {
    const text = 'a\n\nb';
    final r = setLineHeading(text, 2, 2, RichHeading.h1);
    expect(r.text, text);
  });
}
