/// Metin içindeki bağlantıların tek kaynağı: not gövdesinin renklendirilmesi
/// (WrapTextController), uzun basma menüsündeki "Bağlantıyı aç" ve QR
/// sonucunun "link mi" ayrımı hep buradan beslenir. Üç yerde ayrı ayrı yazılan
/// bir kalıp, birinde düzeltilip diğerinde unutulurdu.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Şemalı adresler (http/https), `www.` ile başlayanlar ve bilinen uzantıyla
/// biten çıplak alan adları.
///
/// Çıplak alan adı listesi BİLEREK dar tutuldu: `\w+\.\w+` gibi geniş bir
/// kalıp not içindeki "dosya.txt", "sürüm 1.2", "Ahmet.Yılmaz" gibi metinleri
/// de link sanıp maviye boyardı.
final RegExp _linkPattern = RegExp(
  r'(?:https?://|www\.)[^\s<>"]+'
  r'|\b[\w-]+(?:\.[\w-]+)*'
  r'\.(?:com|net|org|edu|gov|io|dev|app|ai|co|me|tr|de|uk|info|xyz)'
  r'(?:\.tr)?(?:/[^\s<>"]*)?',
  caseSensitive: false,
);

/// Adresin sonuna yapışan noktalama: "bak https://a.com." cümlesinde son
/// nokta adrese ait değildir.
const String _trailingPunctuation = '.,;:!?"\'';

/// Metindeki bağlantıların konumları (başlangıç, bitiş, adres).
List<({int start, int end, String url})> findLinks(String text) {
  final found = <({int start, int end, String url})>[];
  for (final match in _linkPattern.allMatches(text)) {
    var end = match.end;
    // Kapanmayan parantez de adrese dahil edilmez: "(bkz. a.com)".
    while (end > match.start) {
      final last = text[end - 1];
      final unbalanced =
          last == ')' && !text.substring(match.start, end).contains('(');
      if (!_trailingPunctuation.contains(last) && !unbalanced) break;
      end--;
    }
    if (end > match.start) {
      found.add((start: match.start, end: end, url: text.substring(match.start, end)));
    }
  }
  return found;
}

/// Metnin tamamı tek bir bağlantıysa o adresi, değilse null döndürür.
/// QR sonucu için: okunan kod bir link mi, yoksa düz metin mi?
String? soleLink(String text) {
  final trimmed = text.trim();
  final links = findLinks(trimmed);
  if (links.length != 1) return null;
  final only = links.first;
  return only.start == 0 && only.end == trimmed.length ? only.url : null;
}

/// [offset] konumundaki (ya da hemen bitişiğindeki) bağlantı; yoksa null.
/// İmleç adresin sonuna konduğunda da bulunması için bitiş sınırı dahildir.
String? linkAt(String text, int offset) {
  for (final link in findLinks(text)) {
    if (offset >= link.start && offset <= link.end) return link.url;
  }
  return null;
}

/// Metni düz ve bağlantı parçalarına böler. [linkColor] null ise metin
/// olduğu gibi döner — ÖLÇÜM yolu (TextPainter) rengi umursamaz ve renk/alt
/// çizgi satır genişliğini değiştirmediği için ölçüm ile çizim ayrışmaz.
List<InlineSpan> linkSpans(String text, TextStyle? style, Color? linkColor) {
  if (linkColor == null || text.isEmpty) {
    return [TextSpan(text: text, style: style)];
  }
  final links = findLinks(text);
  if (links.isEmpty) return [TextSpan(text: text, style: style)];

  final linkStyle = (style ?? const TextStyle()).copyWith(
    color: linkColor,
    decoration: TextDecoration.underline,
    decorationColor: linkColor,
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final link in links) {
    if (link.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, link.start), style: style),
      );
    }
    spans.add(TextSpan(text: link.url, style: linkStyle));
    cursor = link.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: style));
  }
  return spans;
}

/// Adresi tarayıcıda açar. Şema yoksa https varsayılır (www.x.com, x.com/y).
/// Açılamazsa false döner; çağıran kullanıcıya haber verir.
Future<bool> openLink(String raw) async {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return false;
  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
