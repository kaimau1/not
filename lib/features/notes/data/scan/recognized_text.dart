import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import '../pdf/ocr_page_text.dart' show OcrWordBox;

/// Bir görselden tanınan metnin **karakter karakter seçilebilir** modeli.
///
/// KÖK NEDEN (kullanıcı isteği 2026-08-09: "metni tanı ekranında metinleri
/// harf harf seçebilmeliyiz, şu an cümle cümle seçiliyor bu iyi değil"): ilk
/// sürüm ML Kit'in SATIR kutularını dokunulabilir kutulara çeviriyordu, yani
/// en küçük seçim birimi bir satırdı — bir telefon numarasının yalnız son dört
/// hanesini almak imkânsızdı.
///
/// Burada metin tek bir dize hâlinde toplanır ve **her karakterin** kendi
/// dikdörtgeni tutulur. OCR karakter kutusu VERMEZ (yalnız sözcük kutusu);
/// sözcüğün kutusu karakter sayısına eşit dilinir. Eşit bölme orantısız yazı
/// tiplerinde birkaç piksel kayar ama seçim tutamacını doğru harfe oturtmaya
/// fazlasıyla yeter — aynı yaklaşım taranmış PDF sayfalarında da kullanılıyor
/// (bkz. `buildOcrPageText`), iki yüzey aynı hissi versin.
class RecognizedText {
  const RecognizedText({
    required this.text,
    required this.charRects,
    required this.lineOfChar,
  });

  /// Tanınan metnin tamamı; satırlar `\n` ile ayrılır.
  final String text;

  /// [text] ile BİREBİR aynı uzunlukta: her karakterin görüntü piksel
  /// koordinatındaki kutusu. Satır sonu (`\n`) karakterlerinde null.
  final List<Rect?> charRects;

  /// Her karakterin satır numarası — seçim vurgusu satır satır birleştirilir.
  final List<int> lineOfChar;

  bool get isEmpty => text.trim().isEmpty;

  /// Metin hiç tanınmadıysa boş model.
  static const empty = RecognizedText(
    text: '',
    charRects: [],
    lineOfChar: [],
  );

  /// ML Kit sözcük satırlarından modeli kurar.
  ///
  /// Sözcükler arasına BİR boşluk konur ve o boşluğun kutusu iki sözcüğün
  /// ARASINDAKİ boşluktur: seçim bir sözcükten ötekine geçerken vurgu
  /// kesintisiz görünsün (harflerin arasında beyaz delikler kalmasın).
  factory RecognizedText.fromWordLines(List<List<OcrWordBox>> lines) {
    final buffer = StringBuffer();
    final rects = <Rect?>[];
    final lineIndexes = <int>[];
    var lineNumber = 0;

    for (final rawLine in lines) {
      final words = [
        for (final w in rawLine)
          if (w.text.isNotEmpty && !w.box.isEmpty) w,
      ];
      if (words.isEmpty) continue;
      // Satır arası `\n`: ilk satırdan sonra her satırın başına.
      if (buffer.isNotEmpty) {
        buffer.write('\n');
        rects.add(null);
        lineIndexes.add(lineNumber);
        lineNumber++;
      }
      for (var wi = 0; wi < words.length; wi++) {
        final word = words[wi];
        final chars = word.text.characters();
        final slice = word.box.width / chars.length;
        for (var ci = 0; ci < chars.length; ci++) {
          buffer.write(chars[ci]);
          final rect = Rect.fromLTRB(
            word.box.left + slice * ci,
            word.box.top,
            word.box.left + slice * (ci + 1),
            word.box.bottom,
          );
          // BMP DIŞI karakter (emoji) iki UTF-16 birimi kaplar; `charRects`
          // [text] ile BİREBİR aynı uzunlukta kalmalı, yoksa indeksler kayar
          // ve seçim yanlış harfe oturur.
          for (var u = 0; u < chars[ci].length; u++) {
            rects.add(rect);
            lineIndexes.add(lineNumber);
          }
        }
        if (wi + 1 < words.length) {
          final next = words[wi + 1];
          buffer.write(' ');
          rects.add(
            Rect.fromLTRB(
              word.box.right,
              math.min(word.box.top, next.box.top),
              math.max(next.box.left, word.box.right),
              math.max(word.box.bottom, next.box.bottom),
            ),
          );
          lineIndexes.add(lineNumber);
        }
      }
    }
    return RecognizedText(
      text: buffer.toString(),
      charRects: rects,
      lineOfChar: lineIndexes,
    );
  }

  /// [point]'e en yakın karakterin indeksi (görüntü piksel uzayında).
  ///
  /// Önce noktayı İÇEREN karakter aranır; yoksa merkezi en yakın olan seçilir.
  /// Satır sonu karakterleri (kutusuz) hiç aday değildir.
  ///
  /// Metin boşsa -1 döner.
  int nearestChar(double x, double y) {
    var best = -1;
    var bestScore = double.infinity;
    for (var i = 0; i < charRects.length; i++) {
      final r = charRects[i];
      if (r == null) continue;
      if (r.contains(Offset(x, y))) return i;
      // Dikey uzaklık YATAYDAN ağır basar: parmak satırın biraz sağında
      // durduğunda aynı satırın son harfi seçilmeli, alt satırın ilk harfi
      // değil. Aksi hâlde seçim satır atlıyor gibi görünüyordu.
      final dx = x < r.left
          ? r.left - x
          : x > r.right
          ? x - r.right
          : 0.0;
      final dy = y < r.top
          ? r.top - y
          : y > r.bottom
          ? y - r.bottom
          : 0.0;
      final score = dx + dy * 3;
      if (score < bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  /// [index] karakterini içeren SÖZCÜĞÜN aralığı (boşluk ve satır sonu
  /// sınırdır). Dokununca sözcük seçilsin diye.
  (int, int) wordAt(int index) {
    if (index < 0 || index >= text.length) return (0, 0);
    bool isBreak(int i) => text[i] == ' ' || text[i] == '\n';
    if (isBreak(index)) return (index, index + 1);
    var start = index;
    var end = index + 1;
    while (start > 0 && !isBreak(start - 1)) {
      start--;
    }
    while (end < text.length && !isBreak(end)) {
      end++;
    }
    return (start, end);
  }

  /// `[start, end)` aralığının vurgu dikdörtgenleri — satır başına birleşik.
  List<Rect> selectionRects(int start, int end) {
    final from = start.clamp(0, text.length);
    final to = end.clamp(from, text.length);
    final out = <Rect>[];
    int? currentLine;
    Rect? current;
    for (var i = from; i < to; i++) {
      final r = charRects[i];
      if (r == null) continue;
      final line = lineOfChar[i];
      if (current == null || line != currentLine) {
        if (current != null) out.add(current);
        current = r;
        currentLine = line;
      } else {
        current = current.expandToInclude(r);
      }
    }
    if (current != null) out.add(current);
    return out;
  }

  /// Seçilen aralığın metni.
  String textOf(int start, int end) {
    final from = start.clamp(0, text.length);
    final to = end.clamp(from, text.length);
    return text.substring(from, to);
  }
}

/// Karakter listesi — Unicode birleşik karakterleri (ör. "ğ") bölmemek için
/// `String.split('')` YERİNE runes üzerinden gider.
extension _Chars on String {
  List<String> characters() => runes.map(String.fromCharCode).toList();
}
