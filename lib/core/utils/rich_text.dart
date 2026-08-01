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
/// KÖK NEDEN (v1.0.168) — biçim işlemleri önce METİN ÜZERİNDE, işaretleri
/// elle keserek/yapıştırarak yapılıyordu. Kalın+renk gibi İKİ biçim üst üste
/// gelince, seçim işaretin ortasına düşünce ya da aynı düğmeye ikinci kez
/// basılınca bu yöntem tutarsız metin üretiyordu (tek başına kalmış `**`,
/// kaldırılamayan biçim, kayan seçim). Artık tek yol var:
///
///   işaretli metin → [ _parse ] → DÜZ metin + parça başına [RichMark]
///                  → aralığa biçim ekle/çıkar
///                  → [ _serialize ] → işaretli metin (+ konum eşlemesi)
///
/// Böylece iç içe biçim (`**%%2:abc%%**`) doğal olarak çalışır, aç/kapa
/// Word'deki gibi davranır ve seçim işaretlerin İÇİNE düşse bile en yakın
/// gerçek karaktere hizalanır.
library;

import 'dart:math' as math;

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

/// Bir metin parçasının ÜZERİNDEKİ biçimlerin tümü.
///
/// Biçimler artık birbirini dışlamıyor: aynı harf hem kalın hem renkli hem
/// vurgulu olabilir. İşaretli metne yazılırken belirli bir SIRAYLA iç içe
/// geçirilirler (bkz. [_openMarkers]) — sıra sabit olduğu için aynı biçim
/// kümesi her zaman aynı metni üretir ve gidiş-dönüş kararlıdır.
@immutable
class RichMark {
  const RichMark({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color,
    this.highlight,
  });

  /// Biçimsiz.
  static const none = RichMark();

  final bool bold;
  final bool italic;
  final bool underline;

  /// Yazı rengi indeksi (1..n) — `%%2:metin%%`.
  final int? color;

  /// Vurgu (chip) rengi indeksi (1..n) — `==2:metin==`.
  final int? highlight;

  bool get isEmpty =>
      !bold && !italic && !underline && color == null && highlight == null;

  bool has(RichFormat format) => switch (format) {
    RichFormat.bold => bold,
    RichFormat.italic => italic,
    RichFormat.underline => underline,
    RichFormat.color => color != null,
    RichFormat.highlight => highlight != null,
  };

  /// Renk alan biçimlerde seçili palet indeksi, diğerlerinde null.
  int? indexOf(RichFormat format) => switch (format) {
    RichFormat.color => color,
    RichFormat.highlight => highlight,
    _ => null,
  };

  RichMark applied(RichFormat format, int? index) => switch (format) {
    RichFormat.bold => _copy(bold: true),
    RichFormat.italic => _copy(italic: true),
    RichFormat.underline => _copy(underline: true),
    RichFormat.color => _copy(color: index ?? color ?? 1),
    RichFormat.highlight => _copy(highlight: index ?? highlight ?? 1),
  };

  RichMark removed(RichFormat format) => switch (format) {
    RichFormat.bold => _copy(bold: false),
    RichFormat.italic => _copy(italic: false),
    RichFormat.underline => _copy(underline: false),
    RichFormat.color => _copy(clearColor: true),
    RichFormat.highlight => _copy(clearHighlight: true),
  };

  RichMark _copy({
    bool? bold,
    bool? italic,
    bool? underline,
    int? color,
    int? highlight,
    bool clearColor = false,
    bool clearHighlight = false,
  }) => RichMark(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    color: clearColor ? null : (color ?? this.color),
    highlight: clearHighlight ? null : (highlight ?? this.highlight),
  );

  @override
  bool operator ==(Object other) =>
      other is RichMark &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.color == color &&
      other.highlight == highlight;

  @override
  int get hashCode => Object.hash(bold, italic, underline, color, highlight);
}

/// Düz metnin bir parçası ve üzerindeki biçimler.
@immutable
class RichSegment {
  const RichSegment(this.text, this.mark);

  final String text;
  final RichMark mark;
}

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

/// İçi boş kalmış işaret kutuları (`****`, `==3:==`): seçim yokken biçim
/// düğmesine basılıp hiç yazılmadığında geriye bunlar kalır. Gösterimde
/// zararsız ama dışa aktarılan metinde görünmemeli.
final RegExp _emptyBoxPattern = RegExp(r'\*\*\*\*|==(?:\d:)?==|%%(?:\d:)?%%');

/// Metinden biçim işaretlerini söker (kart önizlemesi, dışa aktarma, AI,
/// sesli okuma — kısaca gösterime girmeyen her yol).
String stripRichMarkers(String text) {
  if (!_hasMarker(text)) return text;
  // Boş kutular ÖNCE düşer: `==3:==` çözümleyiciye kalsa içeriği "3:" olan
  // bir vurgu sanılır ve dışa aktarılan metne "3:" sızardı.
  final cleaned = text.replaceAll(_emptyBoxPattern, '');
  return _parse(cleaned).map((leaf) => leaf.text).join();
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

/// Açılış işaretinin uzunluğu (renk öneki dahil): `%%2:` → 4.
int _openLength(RichFormat format, int? index) =>
    format.marker.length + (index == null ? 0 : 2);

// ---------------------------------------------------------------------------
// Çözümleme (işaretli metin → parçalar) ve geri yazma
// ---------------------------------------------------------------------------

/// Çözümlenmiş bir yaprak: düz metin parçası, biçimleri ve İŞARETLİ metindeki
/// başlangıcı (konum eşlemesi bunun üzerinden yapılır).
class _Leaf {
  const _Leaf(this.text, this.mark, this.markedStart);

  final String text;
  final RichMark mark;
  final int markedStart;
}

/// İşaretli metni yapraklarına ayırır (iç içe biçimler dahil).
List<_Leaf> _parse(String marked) {
  final out = <_Leaf>[];
  void walk(String part, int base, RichMark mark) {
    var cursor = 0;
    for (final m in _formatPattern.allMatches(part)) {
      final content = _contentOf(m);
      if (content == null || content.isEmpty) continue;
      if (m.start > cursor) {
        out.add(_Leaf(part.substring(cursor, m.start), mark, base + cursor));
      }
      final format = _formatOf(m);
      final index = _colorOf(m);
      walk(
        content,
        base + m.start + _openLength(format, index),
        mark.applied(format, index),
      );
      cursor = m.end;
    }
    if (cursor < part.length) {
      out.add(_Leaf(part.substring(cursor), mark, base + cursor));
    }
  }

  walk(marked, 0, RichMark.none);
  return out;
}

/// İşaretli metindeki konumu DÜZ metindeki konuma çevirir.
///
/// Konum bir işaretin içine düşerse en yakın gerçek karaktere hizalanır:
/// kullanıcı seçimi işaretin ortasında bitirdiğinde biçim yine doğru aralığa
/// uygulanır (eski kodun "yarım işaret" hatalarının kaynağı buydu).
int _toPlain(List<_Leaf> leaves, int markedOffset) {
  var plainStart = 0;
  for (final leaf in leaves) {
    if (markedOffset < leaf.markedStart) return plainStart;
    final end = leaf.markedStart + leaf.text.length;
    if (markedOffset <= end)
      return plainStart + (markedOffset - leaf.markedStart);
    plainStart += leaf.text.length;
  }
  return plainStart;
}

/// Komşu ve biçimi aynı parçaları birleştirir; boş parçaları atar.
List<RichSegment> _merge(List<RichSegment> segments) {
  final out = <RichSegment>[];
  for (final seg in segments) {
    if (seg.text.isEmpty) continue;
    if (out.isNotEmpty && out.last.mark == seg.mark) {
      out[out.length - 1] = RichSegment(out.last.text + seg.text, seg.mark);
    } else {
      out.add(seg);
    }
  }
  return out;
}

/// Biçimlerin İŞARETLİ metindeki açılış dizisi. Sıra sabittir (dıştan içe:
/// vurgu → renk → kalın → italik → altı çizili); kapanış tam tersidir.
String _openMarkers(RichMark mark) {
  final buffer = StringBuffer();
  if (mark.highlight != null) buffer.write('==${mark.highlight}:');
  if (mark.color != null) buffer.write('%%${mark.color}:');
  if (mark.bold) buffer.write('**');
  if (mark.italic) buffer.write('_');
  if (mark.underline) buffer.write('~');
  return buffer.toString();
}

String _closeMarkers(RichMark mark) {
  final buffer = StringBuffer();
  if (mark.underline) buffer.write('~');
  if (mark.italic) buffer.write('_');
  if (mark.bold) buffer.write('**');
  if (mark.color != null) buffer.write('%%');
  if (mark.highlight != null) buffer.write('==');
  return buffer.toString();
}

/// Parçaları işaretli metne geri yazar ve DÜZ konumların işaretli metindeki
/// karşılıklarını da döndürür.
///
/// İki eşleme var, çünkü bir sınır konumunun "doğru" karşılığı seçimin hangi
/// ucu olduğuna bağlı: seçim BAŞLANGICI açılış işaretinden SONRAYA,
/// seçim SONU kapanış işaretinden ÖNCEYE düşmeli — yoksa biçim uygulanmış
/// metin seçili kalmaz ve arka arkaya iki biçim (kalın + italik) verilemez.
({String text, List<int> starts, List<int> ends}) _serialize(
  List<RichSegment> segments,
) {
  final merged = _merge(segments);
  final plainLength = merged.fold<int>(0, (sum, s) => sum + s.text.length);
  final starts = List<int>.filled(plainLength + 1, -1);
  final ends = List<int>.filled(plainLength + 1, -1);
  final buffer = StringBuffer();
  var length = 0;
  var plain = 0;
  for (final seg in merged) {
    final open = _openMarkers(seg.mark);
    buffer.write(open);
    length += open.length;
    for (var i = 0; i <= seg.text.length; i++) {
      starts[plain + i] = length + i;
      if (ends[plain + i] == -1) ends[plain + i] = length + i;
    }
    buffer.write(seg.text);
    length += seg.text.length;
    plain += seg.text.length;
    final close = _closeMarkers(seg.mark);
    buffer.write(close);
    length += close.length;
  }
  if (plainLength == 0) {
    starts[0] = 0;
    ends[0] = 0;
  }
  return (text: buffer.toString(), starts: starts, ends: ends);
}

/// [ps]–[pe] düz aralığındaki parçaların biçimini [change] ile değiştirir.
List<RichSegment> _mapRange(
  List<RichSegment> segments,
  int ps,
  int pe,
  RichMark Function(RichMark) change,
) {
  final out = <RichSegment>[];
  var pos = 0;
  for (final seg in segments) {
    final start = pos;
    final end = pos + seg.text.length;
    pos = end;
    if (end <= ps || start >= pe) {
      out.add(seg);
      continue;
    }
    final a = math.max(start, ps);
    final b = math.min(end, pe);
    if (a > start) {
      out.add(RichSegment(seg.text.substring(0, a - start), seg.mark));
    }
    out.add(
      RichSegment(seg.text.substring(a - start, b - start), change(seg.mark)),
    );
    if (b < end) out.add(RichSegment(seg.text.substring(b - start), seg.mark));
  }
  return out;
}

/// [plain] konumundaki biçim: imlecin SOLUNDAKİ karakter esas alınır (yazı
/// yazarken beklenen davranış), satır başındaysa sağdaki.
RichMark _markAt(List<RichSegment> segments, int plain) {
  var pos = 0;
  RichMark? left;
  for (final seg in segments) {
    final start = pos;
    final end = pos + seg.text.length;
    pos = end;
    if (plain > start && plain <= end) left = seg.mark;
    if (plain >= start && plain < end && left == null) return seg.mark;
  }
  return left ?? RichMark.none;
}

/// [plain] konumunu içeren, [format] biçimi KESİNTİSİZ süren aralık.
///
/// "Aynı yere tekrar basınca kalksın" bunun üzerine kurulu: imleç kalın bir
/// kelimenin içindeyken kalın düğmesi o kelimenin tamamından biçimi alır.
({int start, int end}) _runAround(
  List<RichSegment> segments,
  int plain,
  RichFormat format,
  int? index,
) {
  bool matches(RichMark mark) =>
      mark.has(format) &&
      (!_takesColor(format) || index == null || mark.indexOf(format) == index);

  var pos = 0;
  var start = plain;
  var end = plain;
  var started = false;
  for (final seg in segments) {
    final segStart = pos;
    final segEnd = pos + seg.text.length;
    pos = segEnd;
    if (!matches(seg.mark)) {
      if (started && segStart <= plain) started = false;
      if (started) break;
      continue;
    }
    // İmleci içeren ya da imlece dayanan biçimli parçalar birleştirilir.
    if (!started) {
      if (segEnd < plain || segStart > plain) continue;
      started = true;
      start = segStart;
      end = segEnd;
    } else {
      end = segEnd;
    }
  }
  return (start: start, end: end);
}

/// Aralıktaki her (boşluk olmayan) karakter zaten bu biçimde mi?
bool _rangeHasFormat(
  List<RichSegment> segments,
  int ps,
  int pe,
  RichFormat format,
  int? index,
) {
  var pos = 0;
  var sawContent = false;
  var allFormatted = true;
  for (final seg in segments) {
    final start = pos;
    final end = pos + seg.text.length;
    pos = end;
    if (end <= ps || start >= pe) continue;
    final piece = seg.text.substring(
      math.max(start, ps) - start,
      math.min(end, pe) - start,
    );
    if (piece.trim().isEmpty) continue;
    sawContent = true;
    final ok =
        seg.mark.has(format) &&
        (!_takesColor(format) ||
            index == null ||
            seg.mark.indexOf(format) == index);
    if (!ok) allFormatted = false;
  }
  return sawContent && allFormatted;
}

// ---------------------------------------------------------------------------
// Çizim
// ---------------------------------------------------------------------------

/// Biçimli metni span'lere çevirir; biçim dışı parçalar [linkSpans]'ten geçer
/// (bağlantı renklendirmesi korunur).
///
/// [palette] renk indeksinin (1..n) karşılığı renkler. [linkColor] null ise
/// ÖLÇÜM yolundayız demektir: renk/alt çizgi satır genişliğini değiştirmez,
/// ama KALIN ve İTALİK değiştirir — bu yüzden ölçüm ve çizim AYNI işlevden
/// geçer, yoksa ikisi ayrışıp imleç kayardı.
List<InlineSpan> richSpans(
  String text,
  TextStyle? style, {
  Color? linkColor,
  required List<Color> palette,
  required Color markerColor,
}) {
  if (text.isEmpty) return [TextSpan(text: text, style: style)];
  if (!_hasMarker(text)) return linkSpans(text, style, linkColor);

  final base = style ?? const TextStyle();
  final markerStyle = base.copyWith(
    color: markerColor,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
    backgroundColor: const Color(0x00000000),
  );
  final spans = <InlineSpan>[];

  void walk(String part, RichMark mark) {
    final styleFor = markStyle(base, mark, palette);
    var cursor = 0;
    for (final m in _formatPattern.allMatches(part)) {
      final content = _contentOf(m);
      if (content == null || content.isEmpty) continue;
      if (m.start > cursor) {
        spans.addAll(
          linkSpans(part.substring(cursor, m.start), styleFor, linkColor),
        );
      }
      final format = _formatOf(m);
      final index = _colorOf(m);
      spans.add(
        TextSpan(
          text: m[0]!.substring(0, _openLength(format, index)),
          style: markerStyle,
        ),
      );
      walk(content, mark.applied(format, index));
      spans.add(TextSpan(text: format.marker, style: markerStyle));
      cursor = m.end;
    }
    if (cursor < part.length) {
      spans.addAll(linkSpans(part.substring(cursor), styleFor, linkColor));
    }
  }

  walk(text, RichMark.none);
  return spans;
}

/// [mark] biçimlerinin tümünü [base] stiline uygular (iç içe biçim = stil
/// birikimi).
TextStyle markStyle(TextStyle base, RichMark mark, List<Color> palette) {
  var style = base;
  if (mark.bold) style = style.copyWith(fontWeight: FontWeight.w700);
  if (mark.italic) style = style.copyWith(fontStyle: FontStyle.italic);
  if (mark.color != null) {
    style = style.copyWith(color: _paletteColor(palette, mark.color));
  }
  if (mark.underline) {
    style = style.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: style.color,
    );
  }
  if (mark.highlight != null) {
    // Vurgu: metnin ARKASI renklenir (çip görünümü). WidgetSpan kullanmak
    // metin uzayında karakter sayısını değiştirirdi.
    style = style.copyWith(
      backgroundColor: _paletteColor(
        palette,
        mark.highlight,
      ).withValues(alpha: 0.45),
    );
  }
  return style;
}

Color _paletteColor(List<Color> palette, int? index) {
  if (palette.isEmpty) return const Color(0xFFFFC94D);
  if (index == null || index < 1 || index > palette.length)
    return palette.first;
  return palette[index - 1];
}

// ---------------------------------------------------------------------------
// Aç / kapa
// ---------------------------------------------------------------------------

/// Seçime biçim uygular ya da zaten uygulanmışsa KALDIRIR (aç/kapa).
///
/// [start]/[end] İŞARETLİ metindeki konumlardır; dönen değer yeni metin ve
/// yeni seçimdir. Seçim, biçim uygulandıktan sonra da AYNI metnin üstünde
/// kalır — kullanıcı arka arkaya kalın + renk verebilir.
///
/// Word mantığı: seçim yokken imleç biçimli bir parçanın içindeyse aynı düğme
/// o parçanın biçimini KALDIRIR; değilse imlece boş bir biçim kutusu açılır
/// (yazmaya devam edilince yazılan biçimli çıkar).
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
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final ps = _toPlain(leaves, start);
  final pe = _toPlain(leaves, end);

  if (ps == pe) {
    final mark = _markAt(segments, ps);
    if (mark.has(format)) {
      final index = mark.indexOf(format);
      final recolor =
          _takesColor(format) && colorIndex != null && index != colorIndex;
      final run = _runAround(segments, ps, format, index);
      final updated = _mapRange(
        segments,
        run.start,
        run.end,
        (m) => recolor ? m.applied(format, colorIndex) : m.removed(format),
      );
      final out = _serialize(updated);
      final caret = out.starts[ps.clamp(0, out.starts.length - 1)];
      return (text: out.text, start: caret, end: caret);
    }
    // Biçimsiz imleç: boş kutu açılır, imleç ARASINA konur.
    final out = _serialize(segments);
    final at = out.starts[ps.clamp(0, out.starts.length - 1)];
    final marker = format.marker;
    final prefix = _takesColor(format) && colorIndex != null
        ? '$marker$colorIndex:'
        : marker;
    return (
      text: out.text.replaceRange(at, at, '$prefix$marker'),
      start: at + prefix.length,
      end: at + prefix.length,
    );
  }

  final remove = _rangeHasFormat(segments, ps, pe, format, colorIndex);
  final updated = _mapRange(
    segments,
    ps,
    pe,
    (m) => remove ? m.removed(format) : m.applied(format, colorIndex),
  );
  final out = _serialize(updated);
  return (
    text: out.text,
    start: out.starts[ps.clamp(0, out.starts.length - 1)],
    end: out.ends[pe.clamp(0, out.ends.length - 1)],
  );
}

/// Seçimdeki TÜM biçimleri kaldırır (Word'ün "biçimlendirmeyi temizle"si).
({String text, int start, int end}) clearFormat(
  String text,
  int start,
  int end,
) {
  if (start < 0 || end > text.length || end < start) {
    return (text: text, start: start, end: end);
  }
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  var ps = _toPlain(leaves, start);
  var pe = _toPlain(leaves, end);
  // Seçim yoksa imlecin içinde bulunduğu biçimli parça temizlenir.
  if (ps == pe) {
    final range = _plainRunAt(segments, ps);
    ps = range.start;
    pe = range.end;
  }
  if (ps == pe) return (text: text, start: start, end: end);
  final out = _serialize(_mapRange(segments, ps, pe, (_) => RichMark.none));
  return (
    text: out.text,
    start: out.starts[ps.clamp(0, out.starts.length - 1)],
    end: out.ends[pe.clamp(0, out.ends.length - 1)],
  );
}

/// İmleci içeren, biçimi aynı olan kesintisiz parça (biçimsizse boş aralık).
({int start, int end}) _plainRunAt(List<RichSegment> segments, int plain) {
  var pos = 0;
  for (final seg in segments) {
    final start = pos;
    final end = pos + seg.text.length;
    pos = end;
    if (plain >= start && plain <= end && !seg.mark.isEmpty) {
      return (start: start, end: end);
    }
  }
  return (start: plain, end: plain);
}
