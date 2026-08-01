/// Not metnindeki SATIR İÇİ biçimlendirme: kalın, italik, altı çizili, renkli
/// yazı ve renkli vurgu (chip).
///
/// KARAR — biçim, metnin İÇİNDE işaretle taşınır (Markdown mantığı); ayrı bir
/// "span listesi" alanı olarak SAKLANMAZ. Sebebi tek bir cümleyle: notun metni
/// bu uygulamada on ayrı yoldan geçiyor — arama, AI'a gönderme, sesli okuma,
/// PDF/Word/sunum dışa aktarma, pano, paylaşım, widget, yedek. Biçim ayrı bir
/// alanda dursaydı bu yolların HEPSİNİN onu ayrıca taşıması gerekirdi; biri
/// unutulduğunda metin ile biçimi birbirinden ayrı düşer (ve eski notların
/// şeması da değişirdi). İşaretli metin her yerde tek parça kalır; gösterime
/// girmeyen yollarda [stripRichMarkers] ile temizlenir.
///
/// Bedeli: işaretler düzenleyicide GÖRÜNÜR (sönük çizilir). Karakterleri
/// gizlemek, imleç ve seçim konumlarını metinden ayırmak demek olurdu —
/// sarma çapalarında (text_wrap.dart) ödenen bedelin aynısı, bu kez her
/// biçim işareti için.
///
/// İç içe biçim DESTEKLENMEZ (`**_a_**` gibi): tarayıcı tek geçişte, en dıştaki
/// eşleşmeyi alır. İki katmanlı biçim not tutarken pratikte gerekmiyor.
library;

import 'package:flutter/material.dart';

import 'link_text.dart';

/// Biçim türü ve metindeki işareti.
enum RichFormat {
  bold('**'),
  italic('_'),
  underline('~'),
  highlight('=='),
  color('%%');

  const RichFormat(this.marker);

  /// Açılış ve kapanışta kullanılan işaret.
  final String marker;
}

/// Renk seçilebilen biçimler (`==2:metin==`, `%%3:metin%%`).
bool _takesColor(RichFormat f) =>
    f == RichFormat.highlight || f == RichFormat.color;

/// Tüm biçimleri tek geçişte yakalayan kalıp. Sıra önemlidir: `**` `*`'tan
/// önce denenmeli, yoksa kalın işaretinin ilk yıldızı italik sanılır.
/// `_` ve `~` tek karakterli olduğundan sıradan metne çarpabilir
/// ("dosya_adi_uzun", "a~b"); kelime İÇİNDE geçen işaret sayılmaz — kalıp
/// ikisinin çevresinde kelime karakteri olmamasını şart koşar. `.` satır sonu
/// eşleşmez: biçim satırda başlar, satırda biter.
final RegExp _formatPattern = RegExp(
  r'\*\*(?:(\d):)?(.+?)\*\*'
  r'|==(?:(\d):)?(.+?)=='
  r'|%%(?:(\d):)?(.+?)%%'
  r'|(?<!\w)_(?:(\d):)?(.+?)_(?!\w)'
  r'|(?<!\w)~(?:(\d):)?(.+?)~(?!\w)',
  dotAll: false,
);

/// Metinden biçim işaretlerini söker (kart önizlemesi, dışa aktarma, AI,
/// sesli okuma — kısaca gösterime girmeyen her yol).
String stripRichMarkers(String text) {
  if (!_hasMarker(text)) return text;
  // Tek geçiş yetmez: `**a** ve ==b==` gibi ard arda gelenler tek geçişte
  // temizlenir ama iç içe yazılmış bir işaret kalabilir; iki geçiş yeter,
  // üçüncüsü hiçbir şeyi değiştirmediği için döngü orada durur.
  var out = text;
  for (var i = 0; i < 3; i++) {
    final next = out.replaceAllMapped(
      _formatPattern,
      (m) => _contentOf(m as RegExpMatch) ?? m[0]!,
    );
    if (next == out) break;
    out = next;
  }
  return out;
}

bool _hasMarker(String text) =>
    text.contains('**') ||
    text.contains('==') ||
    text.contains('%%') ||
    text.contains('_') ||
    text.contains('~');

/// Eşleşmenin İÇERİĞİ (renk öneki ve işaretler olmadan).
String? _contentOf(RegExpMatch m) {
  for (var g = 2; g <= m.groupCount; g += 2) {
    final value = m[g];
    if (value != null) return value;
  }
  return null;
}

/// Eşleşmenin biçim türü.
RichFormat _formatOf(RegExpMatch m) {
  final text = m[0]!;
  if (text.startsWith('**')) return RichFormat.bold;
  if (text.startsWith('==')) return RichFormat.highlight;
  if (text.startsWith('%%')) return RichFormat.color;
  if (text.startsWith('_')) return RichFormat.italic;
  return RichFormat.underline;
}

/// Eşleşmenin renk indeksi (yoksa null).
int? _colorOf(RegExpMatch m) {
  for (var g = 1; g < m.groupCount; g += 2) {
    final value = m[g];
    if (value != null) return int.tryParse(value);
  }
  return null;
}

/// Biçimli metni span'lere çevirir; biçim dışı parçalar [linkSpans]'ten geçer
/// (bağlantı renklendirmesi korunur).
///
/// [palette] renk indeksinin (1..n) karşılığı renkler. [linkColor] null ise
/// ÖLÇÜM yolundayız demektir: renk/alt çizgi satır genişliğini değiştirmez,
/// ama KALIN ve İTALİK değiştirir — bu yüzden onlar ölçümde de uygulanır,
/// yoksa ölçüm ile çizim ayrışıp imleç kayardı.
List<InlineSpan> richSpans(
  String text,
  TextStyle? style, {
  Color? linkColor,
  required List<Color> palette,
  required Color markerColor,
}) {
  if (text.isEmpty) return [TextSpan(text: text, style: style)];
  if (!_hasMarker(text)) return linkSpans(text, style, linkColor);

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _formatPattern.allMatches(text)) {
    final content = _contentOf(match);
    if (content == null || content.isEmpty) continue;
    if (match.start > cursor) {
      spans.addAll(
        linkSpans(text.substring(cursor, match.start), style, linkColor),
      );
    }
    final format = _formatOf(match);
    final color = _paletteColor(palette, _colorOf(match));
    // İşaretlerin kendisi sönük çizilir: metin akışında dururlar (imleç
    // hesabı bozulmasın) ama okumayı bölmezler.
    final markerStyle = (style ?? const TextStyle()).copyWith(
      color: markerColor,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      decoration: TextDecoration.none,
    );
    final open = match[0]!.substring(0, match[0]!.indexOf(content));
    final close = format.marker;
    spans
      ..add(TextSpan(text: open, style: markerStyle))
      ..add(
        format == RichFormat.highlight
            ? _highlightSpan(content, style, color)
            : TextSpan(text: content, style: _styleFor(format, style, color)),
      )
      ..add(TextSpan(text: close, style: markerStyle));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.addAll(linkSpans(text.substring(cursor), style, linkColor));
  }
  return spans;
}

/// Vurgu: metnin ARKASI renklenir (çip görünümü). Yuvarlak köşe için
/// `background` yerine [TextStyle.background] boyası kullanılır — WidgetSpan
/// kullanmak metin uzayında karakter sayısını değiştirirdi.
TextSpan _highlightSpan(String content, TextStyle? style, Color color) =>
    TextSpan(
      text: content,
      style: (style ?? const TextStyle()).copyWith(
        backgroundColor: color.withValues(alpha: 0.45),
      ),
    );

TextStyle _styleFor(RichFormat format, TextStyle? style, Color color) {
  final base = style ?? const TextStyle();
  return switch (format) {
    RichFormat.bold => base.copyWith(fontWeight: FontWeight.w700),
    RichFormat.italic => base.copyWith(fontStyle: FontStyle.italic),
    RichFormat.underline => base.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: base.color,
    ),
    RichFormat.color => base.copyWith(color: color),
    RichFormat.highlight => base,
  };
}

Color _paletteColor(List<Color> palette, int? index) {
  if (palette.isEmpty) return const Color(0xFFFFC94D);
  if (index == null || index < 1 || index > palette.length) return palette.first;
  return palette[index - 1];
}

/// Seçime biçim uygular ya da zaten uygulanmışsa KALDIRIR (aç/kapa).
///
/// Dönen değer yeni metin ve yeni seçimdir; çağıran denetleyiciye yazar.
/// [colorIndex] yalnız renk alan biçimlerde (vurgu/renkli yazı) anlamlıdır.
({String text, int start, int end}) toggleFormat(
  String text,
  int start,
  int end,
  RichFormat format, {
  int? colorIndex,
}) {
  if (start < 0 || end > text.length || end < start) {
    return (text: text, start: start, end: end);
  }
  // Seçim YOKSA imlece boş bir biçim kutusu açılır ve imleç ARASINA konur:
  // kullanıcı düğmeye basıp yazmaya devam eder, yazdığı biçimli çıkar
  // ("her harf kendi içinde düzenlenebilmeli"). Seçmek şart olsaydı biçim
  // yalnız yazdıktan SONRA uygulanabilirdi.
  if (end == start) {
    final marker = format.marker;
    final prefix = _takesColor(format) && colorIndex != null
        ? '$marker$colorIndex:'
        : marker;
    return (
      text: text.replaceRange(start, start, '$prefix$marker'),
      start: start + prefix.length,
      end: start + prefix.length,
    );
  }
  final marker = format.marker;
  final selected = text.substring(start, end);

  // 1) Seçimin KENDİSİ işaretliyse (kullanıcı işaretlerle birlikte seçti).
  final inner = _unwrap(selected, marker);
  if (inner != null) {
    return (
      text: text.replaceRange(start, end, inner),
      start: start,
      end: start + inner.length,
    );
  }
  // 2) Seçimin ÇEVRESİ işaretliyse (yalnız metni seçti).
  final open = _openBefore(text, start, marker);
  if (open != null && text.startsWith(marker, end)) {
    final without = text.replaceRange(end, end + marker.length, '');
    return (
      text: without.replaceRange(open, start, ''),
      start: open,
      end: open + selected.length,
    );
  }
  // 3) Uygula.
  final prefix = _takesColor(format) && colorIndex != null
      ? '$marker$colorIndex:'
      : marker;
  return (
    text: text.replaceRange(start, end, '$prefix$selected$marker'),
    start: start + prefix.length,
    end: start + prefix.length + selected.length,
  );
}

/// [text] işaretle sarılıysa içeriği, değilse null.
String? _unwrap(String text, String marker) {
  if (text.length < marker.length * 2 + 1) return null;
  if (!text.startsWith(marker) || !text.endsWith(marker)) return null;
  var inner = text.substring(marker.length, text.length - marker.length);
  // Renk öneki de düşer: "==2:metin==" → "metin".
  final colored = RegExp(r'^\d:').firstMatch(inner);
  if (colored != null) inner = inner.substring(colored.end);
  return inner;
}

/// [start]'tan hemen önce biten açılış işaretinin konumu (renk öneki dahil).
int? _openBefore(String text, int start, String marker) {
  final colored = RegExp('${RegExp.escape(marker)}(\\d:)\$');
  final head = text.substring(0, start);
  if (head.endsWith(marker)) return start - marker.length;
  final m = colored.firstMatch(head);
  if (m != null) return m.start;
  return null;
}
