import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_window.dart';

/// F24.2 pencereli kip — saf metin modeli.
void main() {
  String doc(int n) => [for (var i = 0; i < n; i++) 'satır $i'].join('\n');

  test('paragraf sınırları', () {
    const t = 'ab\ncd\n\nef';
    expect(paragraphStartAt(t, 0), 0);
    expect(paragraphStartAt(t, 4), 3);
    expect(paragraphEndAt(t, 4), 5);
    expect(paragraphStartAt(t, 6), 6); // boş paragraf
    expect(paragraphEndAt(t, 6), 6);
    expect(paragraphStartAt(t, t.length), 7);
    expect(paragraphEndAt(t, t.length), t.length);
  });

  test('pencere paragraf sınırında, imleç içeride, sınırlar tutuluyor', () {
    final t = doc(500);
    final caret = t.indexOf('satır 250') + 3;
    final w = windowAround(t, caret);
    expect(w.containsOffset(caret), isTrue);
    expect(w.start == 0 || t[w.start - 1] == '\n', isTrue);
    expect(w.end == t.length || t[w.end] == '\n', isTrue);
    final paras = w.slice(t).split('\n').length;
    expect(paras, 41); // kendi + 20 + 20
    expect(w.length, lessThanOrEqualTo(3000));
  });

  test('karakter tavanı paragraf sayısından önce durdurur', () {
    final t = doc(500);
    final w = windowAround(t, t.length ~/ 2, maxChars: 200);
    expect(w.length, lessThanOrEqualTo(200));
    expect(w.containsOffset(t.length ~/ 2), isTrue);
  });

  test('tavandan uzun tek paragraf yine pencerede', () {
    final t = 'kısa\n${'x' * 5000}\nson';
    final w = windowAround(t, 10, maxChars: 100);
    expect(w, const TextWindow(5, 5005));
  });

  test('baş ve son kenarlar', () {
    final t = doc(100);
    expect(windowAround(t, 0, paragraphs: 5).start, 0);
    expect(windowAround(t, t.length, paragraphs: 5).end, t.length);
    expect(windowAround('', 0), const TextWindow(0, 0));
  });

  test('pencere düzenlemesi tam metne yazılır, ofset eşlemesi tutarlı', () {
    final t = doc(100);
    final w = windowAround(t, t.indexOf('satır 50'), paragraphs: 2);
    final edited = w.slice(t).replaceFirst('satır 50', 'satır 50 EK\nyeni');
    final r = spliceWindow(t, w, edited);
    expect(r.text, t.replaceFirst('satır 50', 'satır 50 EK\nyeni'));
    expect(r.window.slice(r.text), edited);
    expect(
      r.window.toFull(r.window.toWindow(r.window.start + 3)),
      r.window.start + 3,
    );
    expect(w.toWindow(0), 0);
    expect(w.toWindow(t.length), w.length);
  });

  test('yeniden pencereleme kenara yaklaşınca', () {
    final t = doc(1000);
    final mid = t.length ~/ 2;
    final w = windowAround(t, mid, paragraphs: 60);
    expect(needsRewindow(t, w, mid), isFalse);
    expect(needsRewindow(t, w, w.start + 10), isTrue);
    expect(needsRewindow(t, w, w.end + 5), isTrue);
    // Metnin başındaki pencerede üst kenar sorun değil.
    final top = windowAround(t, 0, paragraphs: 60);
    expect(needsRewindow(t, top, 0), isFalse);
  });
}
