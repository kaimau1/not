import 'dart:io';

import 'package:pdfrx/pdfrx.dart';

/// PDF'ten düz metin çıkarır. `pdfrx` zaten görüntüleyici için kurulu —
/// metin katmanı da onda, yeni bağımlılık gerekmiyor.
///
/// Çıkan metin doğrudan sesli okunmaz: PDF'te her sayfada tekrarlayan
/// üstbilgi/altbilgi, sayfa numaraları ve satır sonu tirelemesi vardır;
/// [cleanForSpeech] bunları temizler.
class PdfText {
  const PdfText._();

  /// Tüm sayfaların metni. Taranmış (görüntü) PDF'lerde metin katmanı
  /// olmadığından BOŞ döner — çağıran OCR'a düşmeli.
  static Future<String> extract(String path) async {
    final document = await PdfDocument.openFile(path);
    try {
      final buffer = StringBuffer();
      for (var i = 0; i < document.pages.length; i++) {
        final page = await document.pages[i].loadText();
        final text = page.fullText.trim();
        if (text.isEmpty) continue;
        buffer.writeln(text);
      }
      return buffer.toString();
    } finally {
      await document.dispose();
    }
  }

  static Future<bool> hasTextLayer(String path) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    final text = await extract(path);
    return text.trim().length > 40;
  }

  /// Metni sesli okumaya uygun hale getirir.
  ///
  /// PDF metni ham haliyle okutulunca kulağa berbat gelir: "Sayfa 12 / 47"
  /// sesli okunur, tirelenmiş kelimeler ikiye bölünür, her sayfada aynı
  /// başlık tekrarlanır. Bunlar temizlenmezse ses kaydı dinlenmez olur.
  static String cleanForSpeech(String raw) {
    // 1) Satır sonu tirelemesi: "kelime-\nnin" → "kelimenin".
    //    Tire İKİ YANDAN da harfe bitişik olmalı; yoksa "- 13 -\n14" gibi
    //    süsleme satırları da birleşiyor ve sayfa numarası tespiti bozuluyordu
    //    (test bunu yakaladı).
    var text = raw.replaceAll(RegExp(r'(?<=\w)-\r?\n[ \t]*(?=\w)'), '');

    final lines = text.split(RegExp(r'\r?\n'));

    // 2) Her sayfada tekrarlayan satırlar (üstbilgi/altbilgi): aynı satır
    //    3+ kez geçiyorsa ve kısaysa yinelenen sayfa süslemesidir.
    final counts = <String, int>{};
    for (final line in lines) {
      final key = line.trim();
      if (key.isEmpty || key.length > 80) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final kept = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // 3) Yalnız sayfa numarası olan satırlar ("12", "- 12 -", "12 / 47")
      if (RegExp(r'^[\-–—\s]*\d+\s*(/\s*\d+)?[\-–—\s]*$').hasMatch(trimmed)) {
        continue;
      }
      if ((counts[trimmed] ?? 0) >= 3 && trimmed.length <= 80) continue;
      kept.add(trimmed);
    }

    text = kept.join('\n');
    // 4) Üç veya daha fazla boş satırı teke indir.
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
