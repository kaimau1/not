import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/ink_gestures.dart';

void main() {
  test('gömme aralığı kelime sınırına genişler (E|spanso bölünmez)', () {
    const text = 'Espanso kısaltma yap';
    final r = snapToWords(text, 1, 10);
    expect(text.substring(r.start, r.end), 'Espanso kısaltma');
  });

  test('Türkçe harfler kelime sayılır, boşluk kırpılır', () {
    const text = 'bu şeyi düzeltme ';
    final r = snapToWords(text, 4, 17);
    expect(text.substring(r.start, r.end), 'şeyi düzeltme');
  });

  test('boş aralık kelimenin tamamını alır', () {
    const text = 'yeni gemini modelde';
    final r = snapToWords(text, 7, 7);
    expect(text.substring(r.start, r.end), 'gemini');
  });
}
