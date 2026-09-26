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
/// Bedeli: işaret karakterleri metinde DURUR (çıkarılsalardı imleç/seçim
/// konumları denetleyicinin metniyle ayrışırdı). Ama v1.0.175'ten beri
/// ÇİZİLMEZLER: saydam renk + ~0 punto ile görünmez geçerler (bkz.
/// [richTextSpans]'taki `markerStyle`), imleç de işaretin ortasına düşerse
/// gerçek karaktere çekilir. Kullanıcı yalnız biçimli metni görür.
///
/// Bu yorum bir dönem "işaretler görünür/sönük çizilir" diyordu; kod onu
/// geçmişti, 2026-08-06'da düzeltildi.
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
  color('%%'),
  size('##'),
  opacity('&&');

  const RichFormat(this.marker);

  /// Açılış ve kapanışta kullanılan işaret.
  final String marker;
}

/// [_takesIndex]'in dışa açık hâli — bekleyen biçimi metne yazarken önekin
/// `**` mi `##3:` mi olacağını denetleyici de bilmek zorunda.
bool richFormatTakesIndex(RichFormat f) => _takesIndex(f);

/// İşareti KELİME SINIRI şart koşan biçimler: italik (`_`) ve altı çizili
/// (`~`). Kalıp bunların iki yanında harf/rakam olmamasını istiyor (yoksa
/// "dosya_adi_uzun" italik sanılırdı); dolayısıyla YAZAN taraf da aynı şartı
/// gözetmeli, yoksa ürettiği işaret hiç eşleşmez ve EKRANDA HAM görünür.
bool richFormatNeedsWordBoundary(RichFormat f) =>
    f == RichFormat.italic || f == RichFormat.underline;

/// Kelime karakteri mi? (Unicode: Türkçe harfler dahil — bkz. [_wordChar].)
bool isRichWordChar(String ch) => _wordChar.hasMatch(ch);

/// İndeks (1..9) alan biçimler: renk paleti, boyut ve opaklık kademeleri.
/// İşarette `==2:metin==` gibi bir önekle taşınır.
bool _takesIndex(RichFormat f) =>
    f == RichFormat.highlight ||
    f == RichFormat.color ||
    f == RichFormat.size ||
    f == RichFormat.opacity;

/// Satır içi boyut kademeleri (`##k:metin##`, k = 1..9). Ortadaki kademe
/// (indeks 4 → 1.0) notun kendi boyutudur: o kademe seçilince işaret hiç
/// yazılmaz, metin nota ait boyutu izler.
const List<double> kRichSizeSteps = [
  0.7,
  0.8,
  0.9,
  1.0,
  1.2,
  1.4,
  1.6,
  1.8,
  2.0,
];
const int kRichSizeDefault = 4;

/// Satır içi opaklık kademeleri (`&&k:metin&&`, k = 1..8). Son kademe (1.0)
/// notun kendi opaklığıdır; seçilince işaret yazılmaz.
const List<double> kRichOpacitySteps = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
const int kRichOpacityDefault = 8;

/// [value]'ya en yakın kademenin indeksi (1 tabanlı).
int richStepIndex(List<double> steps, double value) {
  var best = 0;
  for (var i = 1; i < steps.length; i++) {
    if ((steps[i] - value).abs() < (steps[best] - value).abs()) best = i;
  }
  return best + 1;
}

double richStepValue(List<double> steps, int? index) {
  if (index == null || index < 1 || index > steps.length) return steps.last;
  return steps[index - 1];
}

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
    this.size,
    this.opacity,
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

  /// Boyut kademesi (1..9) — `##5:metin##`.
  final int? size;

  /// Opaklık kademesi (1..8) — `&&4:metin&&`.
  final int? opacity;

  bool get isEmpty =>
      !bold &&
      !italic &&
      !underline &&
      color == null &&
      highlight == null &&
      size == null &&
      opacity == null;

  bool has(RichFormat format) => switch (format) {
    RichFormat.bold => bold,
    RichFormat.italic => italic,
    RichFormat.underline => underline,
    RichFormat.color => color != null,
    RichFormat.highlight => highlight != null,
    RichFormat.size => size != null,
    RichFormat.opacity => opacity != null,
  };

  /// Renk alan biçimlerde seçili palet indeksi, diğerlerinde null.
  int? indexOf(RichFormat format) => switch (format) {
    RichFormat.color => color,
    RichFormat.highlight => highlight,
    RichFormat.size => size,
    RichFormat.opacity => opacity,
    _ => null,
  };

  RichMark applied(RichFormat format, int? index) => switch (format) {
    RichFormat.bold => _copy(bold: true),
    RichFormat.italic => _copy(italic: true),
    RichFormat.underline => _copy(underline: true),
    RichFormat.color => _copy(color: index ?? color ?? 1),
    RichFormat.highlight => _copy(highlight: index ?? highlight ?? 1),
    RichFormat.size => _copy(size: index ?? size ?? kRichSizeDefault),
    RichFormat.opacity => _copy(
      opacity: index ?? opacity ?? kRichOpacityDefault,
    ),
  };

  RichMark removed(RichFormat format) => switch (format) {
    RichFormat.bold => _copy(bold: false),
    RichFormat.italic => _copy(italic: false),
    RichFormat.underline => _copy(underline: false),
    RichFormat.color => _copy(clearColor: true),
    RichFormat.highlight => _copy(clearHighlight: true),
    RichFormat.size => _copy(clearSize: true),
    RichFormat.opacity => _copy(clearOpacity: true),
  };

  RichMark _copy({
    bool? bold,
    bool? italic,
    bool? underline,
    int? color,
    int? highlight,
    int? size,
    int? opacity,
    bool clearColor = false,
    bool clearHighlight = false,
    bool clearSize = false,
    bool clearOpacity = false,
  }) => RichMark(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    color: clearColor ? null : (color ?? this.color),
    highlight: clearHighlight ? null : (highlight ?? this.highlight),
    size: clearSize ? null : (size ?? this.size),
    opacity: clearOpacity ? null : (opacity ?? this.opacity),
  );

  @override
  bool operator ==(Object other) =>
      other is RichMark &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.color == color &&
      other.highlight == highlight &&
      other.size == size &&
      other.opacity == opacity;

  @override
  int get hashCode =>
      Object.hash(bold, italic, underline, color, highlight, size, opacity);
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
  // Vurgu da ÖNEK ZORUNLU (`==2:`): öneksiz `==` düz metinde çok geçiyor
  // ("if (a == b && c == d)") ve işaretler görünmez çizildiği için o
  // eşittirler gözden KAYBOLUYORDU — koda ya da matematiğe not alan
  // kullanıcı yazdığını ekranda bulamıyordu. Uygulama vurguyu her zaman
  // önekle yazar (paleti indeksli), yani bu şart hiçbir gerçek vurguyu
  // kırmaz; kırdığı tek şey kullanıcının KENDİ yazdığı `==` idi.
  r'|==(\d):(.+?)=='
  r'|%%(?:(\d):)?(.+?)%%'
  // Boyut ve opaklık işaretleri KADEME ÖNEKİ ZORUNLU tutar (`##3:` gibi):
  // işaretler artık görünmez çizildiğinden, düz metindeki bir "## başlık ##"
  // ya da "a && b && c" yanlışlıkla biçim sanılsa karakterler gözden
  // KAYBOLURDU. Önek şartı bu tuzağı kapatır.
  r'|##(\d):(.+?)##'
  r'|&&(\d):(.+?)&&'
  // Kelime sınırı `\w` ile DEĞİL unicode sınıfıyla: `\w` = [A-Za-z0-9_],
  // Türkçe harfler (ş, ı, ğ...) kelime karakteri sayılmıyordu ve
  // "yaş_ortalama_x" gibi düz metindeki alt çizgiler yanlışlıkla italik
  // sanılıp GÖRÜNMEZ oluyordu (aynı yazım ASCII kelimede korunuyordu).
  // _wordChar (aşağıda) zaten bilinçli olarak unicode — ikisi artık tutarlı.
  r'|(?<![\p{L}\p{N}_])_(?:(\d):)?(.+?)_(?![\p{L}\p{N}_])'
  r'|(?<![\p{L}\p{N}_])~(?:(\d):)?(.+?)~(?![\p{L}\p{N}_])',
  dotAll: false,
  unicode: true,
);

/// İçi boş kalmış işaret kutuları (`****`, `==3:==`): seçim yokken biçim
/// düğmesine basılıp hiç yazılmadığında geriye bunlar kalır. Gösterimde
/// zararsız ama dışa aktarılan metinde görünmemeli.
final RegExp _emptyBoxPattern = RegExp(
  r'\*\*\*\*|==\d:==|%%(?:\d:)?%%|##\d:##|&&\d:&&'
  // İtalik ve altı çizili boş kutuları da: bunlar kelime sınırı şartı
  // yüzünden `_formatPattern`e hiç düşmez, dolayısıyla EKRANDA HAM görünürdü.
  r'|(?<![\p{L}\p{N}_])__(?![\p{L}\p{N}_])'
  r'|(?<![\p{L}\p{N}_])~~(?![\p{L}\p{N}_])',
  unicode: true,
);

/// Metinden biçim işaretlerini söker (kart önizlemesi, dışa aktarma, AI,
/// sesli okuma — kısaca gösterime girmeyen her yol).
String stripRichMarkers(String text) {
  if (!_hasMarker(text)) return text;
  // Boş kutular ÖNCE düşer: `==3:==` çözümleyiciye kalsa içeriği "3:" olan
  // bir vurgu sanılır ve dışa aktarılan metne "3:" sızardı.
  final cleaned = text.replaceAll(_emptyBoxPattern, '');
  return _parse(cleaned).map((leaf) => leaf.text).join();
}

/// İşaretli metni **biçim parçalarına** ayırır: her parça düz metin + üzerine
/// uygulanacak [RichMark].
///
/// Ekranda `richSpans` bu işi Flutter'ın `InlineSpan`larıyla yapıyor; PDF ve
/// Word dışa aktarması ise Flutter türlerini KULLANAMAZ (kendi metin
/// parçaları var). Kök neden (kullanıcı bulgusu 2026-08-08: "yazı biçimi de
/// aktarılmıyor"): dışa aktarma yolu işaretleri yalnız SÖKÜYORDU, yani kalın
/// yazılmış bir satır PDF'e düz iniyordu. Ayrıştırmanın tek kopyası burada
/// kalsın diye çözümleyici dışarıya bu biçimde açıldı.
List<RichSegment> richSegments(String text) {
  if (text.isEmpty) return const [];
  if (!_hasMarker(text)) return [RichSegment(text, RichMark.none)];
  final cleaned = text.replaceAll(_emptyBoxPattern, '');
  return _merge([
    for (final leaf in _parse(cleaned)) RichSegment(leaf.text, leaf.mark),
  ]);
}

/// Seçilen [start, end) aralığının PANOYA gidecek düz karşılığı: biçim
/// işaretleri sökülür, işaretin ORTASINA düşen uçlar en yakın gerçek
/// karaktere hizalanır (yarım `%%1:` panoya sızmaz).
///
/// Sistem Kopyala/Kes varsayılan olarak alanın HAM metnini yazar; editördeki
/// kopyalama yolları bunun yerine bu işlevi kullanır — yoksa `**kalın**`
/// dışarı işaretli gider (dosya başındaki tasarım sözü).
String plainSelection(String text, int start, int end) {
  final from = start.clamp(0, text.length);
  final to = end.clamp(from, text.length);
  if (from >= to) return '';
  if (!_hasMarker(text)) return text.substring(from, to);
  final leaves = _parse(text);
  if (leaves.isEmpty) return '';
  final plain = leaves.map((l) => l.text).join();
  final ps = _toPlain(leaves, from);
  final pe = _toPlain(leaves, to);
  return plain
      .substring(ps.clamp(0, plain.length), pe.clamp(ps, plain.length))
      // İçi boş işaret kutuları (`****`, `==3:==`) çözümleyicide düz metin
      // sayılır ve kesite sızabilir; panoya gitmeden temizlenir
      // (stripRichMarkers ile aynı kural).
      .replaceAll(_emptyBoxPattern, '');
}

bool _hasMarker(String text) =>
    text.contains('**') ||
    text.contains('==') ||
    text.contains('%%') ||
    text.contains('##') ||
    text.contains('&&') ||
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
  if (text.startsWith('##')) return RichFormat.size;
  if (text.startsWith('&&')) return RichFormat.opacity;
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

/// Son ayrıştırmanın önbelleği (TEK giriş).
///
/// KÖK NEDEN (kasma): [_parse] saf bir işlev ama on ayrı yerden çağrılıyor —
/// biçim şeridi her tuş vuruşunda ve HER İMLEÇ HAREKETİNDE `activeFormats`
/// üzerinden tüm metni yeniden ayrıştırıyordu, `stripRichMarkers` arama
/// süzgecinde not başına koşuyordu, çizim yolu ayrıca. Aynı metin için
/// sonuç değişmediğinden tek girişlik bir önbellek bu tekrarların neredeyse
/// tamamını siliyor: ardışık çağrılar hep AYNI metinle geliyor.
///
/// Liste DIŞARIYA verildiği için değiştirilebilir olmamalı; çağıranların
/// hiçbiri yazmıyor, yine de önbellek `List.unmodifiable` ile korunuyor.
String? _parseCacheKey;
List<_Leaf>? _parseCacheValue;

/// İşaretli metni yapraklarına ayırır (iç içe biçimler dahil).
List<_Leaf> _parse(String marked) {
  if (_parseCacheKey == marked) return _parseCacheValue!;
  final result = _parseUncached(marked);
  _parseCacheKey = marked;
  _parseCacheValue = result;
  return result;
}

List<_Leaf> _parseUncached(String marked) {
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
  return List.unmodifiable(out);
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
    if (markedOffset <= end) {
      return plainStart + (markedOffset - leaf.markedStart);
    }
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
  if (mark.size != null) buffer.write('##${mark.size}:');
  if (mark.opacity != null) buffer.write('&&${mark.opacity}:');
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
  if (mark.opacity != null) buffer.write('&&');
  if (mark.size != null) buffer.write('##');
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
      (!_takesIndex(format) || index == null || mark.indexOf(format) == index);

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
        (!_takesIndex(format) ||
            index == null ||
            seg.mark.indexOf(format) == index);
    if (!ok) allFormatted = false;
  }
  return sawContent && allFormatted;
}

/// [start]–[end] aralığında ETKİN olan biçimler — biçim şeridinin hangi
/// düğmeyi "basılı" göstereceği.
///
/// Tanım [toggleFormat] ile AYNI olmak zorunda: şerit, düğmeye basılınca
/// biçimin KALKACAĞI durumu vurgulamalı, yoksa vurgu yalan söyler. Bu yüzden
/// imleçte (seçim yokken) imlecin solundaki karakterin biçimi, seçim varken
/// ise yalnız aralığın TAMAMINI kaplayan biçimler etkin sayılır.
///
/// İndeks alan biçimlerde (renk, vurgu, boyut, opaklık) dönen [RichMark] o
/// aralıktaki indeksi de taşır; şerit renk noktasını buna göre boyar.
RichMark activeFormats(String text, int start, int end) {
  if (start < 0 || end > text.length || end < start) return RichMark.none;
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final ps = _toPlain(leaves, start);
  final pe = _toPlain(leaves, end);
  if (ps == pe) return _markAt(segments, ps);

  var active = RichMark.none;
  for (final format in RichFormat.values) {
    if (!_rangeHasFormat(segments, ps, pe, format, null)) continue;
    // İndeks aralık boyunca değişiyorsa (iki farklı renk) hangisini
    // göstereceğimiz belirsizdir; ilk parçanınki alınır — düğme yine doğru
    // biçimi kaldırır, yalnız renk noktası ilk parçaya göre boyanır.
    active = active.applied(format, _markAt(segments, ps + 1).indexOf(format));
  }
  return active;
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
/// Üretilmiş span listelerinin sınırlı önbelleği.
///
/// KÖK NEDEN (kasma): kart önizlemesi HER BUILD'de `richSpans` çağırıyor ve
/// işlev metni `_formatPattern` ile ÖZYİNELEMELİ gezip yeni bir span ağacı
/// kuruyor. Ana ekranda önbellek payı ~130 kartı canlı tuttuğu için ekranın
/// her yeniden kurulumu bu işi kart (ve madde) sayısı kadar tekrarlıyordu.
/// Girdiler değişmedikçe sonuç da değişmez.
///
/// Sınır: en fazla [_spanCacheLimit] girdi; dolunca tümü atılır (LRU tutmanın
/// muhasebesi bu boyutta kazançtan çok yer tutar).
const _spanCacheLimit = 256;
final Map<
  (String, TextStyle?, Color?, List<Color>, Color, String),
  List<InlineSpan>
>
_spanCache = {};

/// [attachmentNames] notun ek dosya adları — metne gömülü ek etiketleri
/// (bkz. attachment_tag.dart) bunlara göre bulunup kırmızı çizilir. Boşsa
/// hiçbir etiket işaretlenmez.
List<InlineSpan> richSpans(
  String text,
  TextStyle? style, {
  Color? linkColor,
  required List<Color> palette,
  required Color markerColor,
  Iterable<String> attachmentNames = const [],
}) {
  if (text.isEmpty) return [TextSpan(text: text, style: style)];
  if (!_hasMarker(text)) {
    return linkSpans(text, style, linkColor, attachmentNames: attachmentNames);
  }
  // Ek adları da ANAHTARIN parçası: ek silinip eklenince etiket işaretlemesi
  // değişiyor, bayat span dönerse etiket eski hâliyle çizilirdi.
  final cacheKey = (
    text,
    style,
    linkColor,
    palette,
    markerColor,
    attachmentNames.join('\u0000'),
  );
  final cached = _spanCache[cacheKey];
  if (cached != null) return cached;
  final built = _richSpansUncached(
    text,
    style,
    linkColor: linkColor,
    palette: palette,
    markerColor: markerColor,
    attachmentNames: attachmentNames,
  );
  if (_spanCache.length >= _spanCacheLimit) _spanCache.clear();
  // Değiştirilemez: liste artık PAYLAŞILIYOR, bir çağıranın onu yerinde
  // değiştirmesi başka bir kartın çizimini bozardı.
  final shared = List<InlineSpan>.unmodifiable(built);
  _spanCache[cacheKey] = shared;
  return shared;
}

List<InlineSpan> _richSpansUncached(
  String text,
  TextStyle? style, {
  Color? linkColor,
  Iterable<String> attachmentNames = const [],
  required List<Color> palette,
  required Color markerColor,
}) {

  final base = style ?? const TextStyle();
  // İŞARETLER GÖRÜNMEZ (v1.0.175). Karakterler metinde DURUR — çıkarılsalardı
  // imleç/seçim konumları ile denetleyicinin metni ayrışırdı (bkz. dosya
  // başlığı) — ama neredeyse sıfır boyutta ve saydam çizilirler: kullanıcı
  // yalnızca biçimli metni görür. `markerColor` artık yalnızca ölçüde bir
  // etkisi kalmadığından kullanılmaz; imza korunuyor (çağrı yerleri temanın
  // rengini vermeye devam ediyor).
  final markerStyle = base.copyWith(
    color: const Color(0x00000000),
    fontSize: 0.01,
    letterSpacing: 0,
    wordSpacing: 0,
    height: 0.01,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
    backgroundColor: const Color(0x00000000),
  );
  final spans = <InlineSpan>[];

  /// Biçim eşleşmesi DIŞINDA kalan düz parça. İçinde boş işaret kutusu
  /// (`****`, `%%1:%%`) varsa o da GÖRÜNMEZ çizilir: kutu, seçim yokken biçim
  /// düğmesine basıldığında ya da biçimli metnin son harfi silindiğinde
  /// oluşur; kullanıcıya bir anda ekrana yıldızlar dolmuş gibi görünürdü.
  void emitPlain(String part, TextStyle styleFor) {
    if (part.isEmpty) return;
    var cursor = 0;
    for (final box in _emptyBoxPattern.allMatches(part)) {
      if (box.start > cursor) {
        spans.addAll(
          linkSpans(
            part.substring(cursor, box.start),
            styleFor,
            linkColor,
            attachmentNames: attachmentNames,
          ),
        );
      }
      spans.add(TextSpan(text: box[0], style: markerStyle));
      cursor = box.end;
    }
    if (cursor < part.length) {
      spans.addAll(
        linkSpans(
          part.substring(cursor),
          styleFor,
          linkColor,
          attachmentNames: attachmentNames,
        ),
      );
    }
  }

  void walk(String part, RichMark mark) {
    final styleFor = markStyle(base, mark, palette);
    var cursor = 0;
    for (final m in _formatPattern.allMatches(part)) {
      final content = _contentOf(m);
      if (content == null || content.isEmpty) continue;
      if (m.start > cursor) {
        emitPlain(part.substring(cursor, m.start), styleFor);
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
      emitPlain(part.substring(cursor), styleFor);
    }
  }

  walk(text, RichMark.none);
  return spans;
}

/// [span] ağacındaki `[start, end)` karakter aralığına [restyle] uygular.
///
/// BEKLEYEN biçimin canlı önizlemesi için: kullanıcı "kalın"a basıp yazmaya
/// başladığında tamponda henüz işaret YOKTUR (işaretler koşu bitince yazılır —
/// bkz. `WrapTextController._wrapRun`), ama harfler ekranda kalın görünmelidir.
/// Burada yalnız ÇİZİM stili değişir, metne dokunulmaz.
///
/// Düz metin uzunluğu DEĞİŞMEZ; bu şarttır, imleç ve seçim konumları
/// `buildTextSpan`in ürettiği düz metnin uzunluğuna bağlıdır (bkz.
/// text_wrap.dart dosya başlığı). Aralığa denk gelen parçalar BÖLÜNÜR, hiçbir
/// karakter atılmaz ya da eklenmez.
InlineSpan restyleRange(
  InlineSpan span,
  int start,
  int end,
  TextStyle Function(TextStyle? current) restyle,
) {
  if (end <= start) return span;
  var cursor = 0;

  InlineSpan walk(InlineSpan node) {
    if (node is! TextSpan) {
      // Widget/yer tutucu parçalar: uzunlukları 1 sayılır, stilleri yok.
      cursor += 1;
      return node;
    }
    final text = node.text;
    final children = node.children;
    if (text == null) {
      return TextSpan(
        style: node.style,
        children: children == null ? null : [for (final c in children) walk(c)],
        recognizer: node.recognizer,
        semanticsLabel: node.semanticsLabel,
      );
    }
    final from = cursor;
    final to = cursor + text.length;
    cursor = to;
    // Aralıkla hiç kesişmiyor: olduğu gibi kalsın (yeni nesne bile üretme).
    if (to <= start || from >= end) {
      if (children == null) return node;
      return TextSpan(
        text: text,
        style: node.style,
        children: [for (final c in children) walk(c)],
        recognizer: node.recognizer,
        semanticsLabel: node.semanticsLabel,
      );
    }
    final hitStart = start.clamp(from, to) - from;
    final hitEnd = end.clamp(from, to) - from;
    final parts = <InlineSpan>[
      if (hitStart > 0)
        TextSpan(text: text.substring(0, hitStart), style: node.style),
      TextSpan(
        text: text.substring(hitStart, hitEnd),
        style: restyle(node.style),
      ),
      if (hitEnd < text.length)
        TextSpan(text: text.substring(hitEnd), style: node.style),
      if (children != null) ...[for (final c in children) walk(c)],
    ];
    // Stil sarmalayıcıda DA kalır: metin parçaları kendi stillerini zaten
    // taşıyor, ama `children` (varsa) mirasla besleniyor — sarmalayıcıya
    // verilmezse hem metni hem çocuğu olan bir düğümün ALT parçaları stilini
    // kaybederdi. Bugünkü span ağacında bu şekil oluşmuyor; yine de doğru
    // olan yazılıyor ki ileride bir çağrı yeri onu üretirse sessizce
    // bozulmasın.
    return TextSpan(style: node.style, children: parts);
  }

  return walk(span);
}

/// [mark] biçimlerinin tümünü [base] stiline uygular (iç içe biçim = stil
/// birikimi).
TextStyle markStyle(TextStyle base, RichMark mark, List<Color> palette) {
  var style = base;
  if (mark.bold) style = style.copyWith(fontWeight: FontWeight.w700);
  if (mark.italic) style = style.copyWith(fontStyle: FontStyle.italic);
  if (mark.size != null) {
    style = style.copyWith(
      fontSize:
          (style.fontSize ?? 16) * richStepValue(kRichSizeSteps, mark.size),
    );
  }
  if (mark.color != null) {
    style = style.copyWith(color: _paletteColor(palette, mark.color));
  }
  if (mark.opacity != null && style.color != null) {
    style = style.copyWith(
      color: style.color!.withValues(
        alpha: richStepValue(kRichOpacitySteps, mark.opacity),
      ),
    );
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
  if (index == null || index < 1 || index > palette.length) {
    return palette.first;
  }
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
/// [pending] doluysa METİN DEĞİŞMEZ: çağıran, bu biçmi "bir sonraki yazılan
/// metne uygulanacak" olarak saklamalıdır (bkz. WrapTextController.pending…).
/// Eskiden burada metne boş kutu (`~~`, `__`) yazılıyordu; kullanıcı içine bir
/// şey yazmazsa o işaretler notta ham markdown olarak kalıyordu — italik ve
/// altı çizili kutuları gizleme kalıbında olmadığı için EKRANDA da görünüyordu
/// (kullanıcı: "bu tür markdownlar asla görünmemeli"). Kutuyu hiç yazmamak,
/// hem çöpü hem de `__init__` gibi gerçek metni kırpma riskini bitirir.
({String text, int start, int end, RichFormat? pending, int? pendingIndex})
toggleFormat(
  String text,
  int start,
  int end,
  RichFormat format, {
  int? colorIndex,
}) {
  if (start < 0 || end > text.length || end < start) {
    return (
      text: text,
      start: start,
      end: end,
      pending: null,
      pendingIndex: null,
    );
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
          _takesIndex(format) && colorIndex != null && index != colorIndex;
      final run = _runAround(segments, ps, format, index);
      final updated = _mapRange(
        segments,
        run.start,
        run.end,
        (m) => recolor ? m.applied(format, colorIndex) : m.removed(format),
      );
      final out = _serialize(updated);
      final caret = out.starts[ps.clamp(0, out.starts.length - 1)];
      return (
        text: out.text,
        start: caret,
        end: caret,
        pending: null,
        pendingIndex: null,
      );
    }
    // KÖK NEDEN (kullanıcı: "kelimenin içine tıklayıp işlem yapınca yine
    // markdown üretiliyor"): imleç bir kelimenin ORTASINDAyken boş kutu
    // açmak ham işaret bırakıyordu. `_` ve `~` çözümleyicide kelime içinde
    // SAYILMIYOR (bkz. _formatPattern'daki (?<!\w)/(?!\w) koşulları), yani
    // "merh__aba" hiçbir zaman italiğe dönüşmüyor — kullanıcı notunda ham
    // alt çizgi görüyor. `**` çözümleniyor ama o da kelimeyi "merh****aba"
    // diye ikiye bölüyor.
    //
    // Doğru davranış Word ve Docs'ta olan: imleç kelimenin içindeyse biçim
    // KELİMENİN TAMAMINA uygulanır. Kelime başında/sonunda ya da boşlukta
    // imleç eski davranışta kalır (boş kutu = "biçimli yazmaya başla").
    final plain = [for (final seg in segments) seg.text].join();
    final word = _wordAround(plain, ps);
    if (word != null) {
      final updated = _mapRange(
        segments,
        word.start,
        word.end,
        (m) => m.applied(format, colorIndex),
      );
      final out = _serialize(updated);
      return (
        text: out.text,
        start: out.starts[word.start.clamp(0, out.starts.length - 1)],
        end: out.ends[word.end.clamp(0, out.ends.length - 1)],
        pending: null,
        pendingIndex: null,
      );
    }

    // Biçimsiz imleç (kelime başı/sonu ya da boşluk): metne DOKUNULMAZ, biçim
    // "bekleyen" olarak çağırana bildirilir; bir sonraki yazılan metin doğrudan
    // işaretlerin içine girer.
    return (
      text: text,
      start: start,
      end: end,
      pending: format,
      pendingIndex: colorIndex,
    );
  }

  final remove = _rangeHasFormat(segments, ps, pe, format, colorIndex);
  // KELİME SINIRI (2026-08-07 / 14. tur): italik (`_`) ve altı çizili (`~`)
  // işaretleri kalıpta "iki yanında harf/rakam olmasın" şartı taşıyor. Seçim
  // bir kelimenin ORTASINDAN başlıyor ya da ortasında bitiyorsa yazılan
  // işaret hiç EŞLEŞMEZ ve ekranda HAM alt çizgi/tilde olarak görünür
  // ("mer_haba du_nya"). Uygulama aralığı kelime sınırına genişletir —
  // Word'de de kelime ortasından seçip italik yapmak kelimeyi biçimler.
  var from = ps;
  var to = pe;
  if (!remove && richFormatNeedsWordBoundary(format)) {
    final plain = [for (final seg in segments) seg.text].join();
    while (from > 0 && isRichWordChar(plain[from - 1])) {
      from--;
    }
    while (to < plain.length && isRichWordChar(plain[to])) {
      to++;
    }
  }
  final updated = _mapRange(
    segments,
    from,
    to,
    (m) => remove ? m.removed(format) : m.applied(format, colorIndex),
  );
  final out = _serialize(updated);
  return (
    text: out.text,
    start: out.starts[from.clamp(0, out.starts.length - 1)],
    end: out.ends[to.clamp(0, out.ends.length - 1)],
    pending: null,
    pendingIndex: null,
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

/// Kelime karakteri: harf, rakam, alt çizgi — Türkçe harfler DAHİL.
///
/// `\w` KULLANILMAZ: Dart'ta unicode bayrağı olmadan `\w` yalnız `[A-Za-z0-9_]`
/// demektir ve "çalışma" gibi bir kelimede "ş"yi kelime karakteri saymaz.
/// Kelime sınırı Türkçe metinde ASCII'ye göre farklı çıkarsa aynı tıklama
/// kelimeden kelimeye başka davranırdı.
final RegExp _wordChar = RegExp(r'[\p{L}\p{N}_]', unicode: true);

/// İmleç bir KELİMENİN İÇİNDEyse o kelimenin aralığı, değilse null.
///
/// "İçinde" = iki yanında da kelime karakteri var. Kelimenin başında ya da
/// sonundaki imleç null döner: orada boş biçim kutusu açmak doğru davranıştır
/// (kullanıcı biçimli yazmaya başlamak istiyordur).
({int start, int end})? _wordAround(String plain, int at) {
  if (at <= 0 || at >= plain.length) return null;
  if (!_wordChar.hasMatch(plain[at - 1]) || !_wordChar.hasMatch(plain[at])) {
    return null;
  }
  var start = at, end = at;
  while (start > 0 && _wordChar.hasMatch(plain[start - 1])) {
    start--;
  }
  while (end < plain.length && _wordChar.hasMatch(plain[end])) {
    end++;
  }
  return (start: start, end: end);
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

/// Aralığa bir biçimi DOĞRUDAN yazar (aç/kapa değil).
///
/// Boyut ve opaklık kaydırıcıları bunu kullanır: sürüklenen değer neyse o
/// uygulanır. [index] null ise biçim aralıktan KALDIRILIR (kaydırıcı notun
/// kendi değerine dönünce işaret yazmanın anlamı yok).
({String text, int start, int end}) setRangeFormat(
  String text,
  int start,
  int end,
  RichFormat format,
  int? index,
) {
  if (start < 0 || end > text.length || end < start) {
    return (text: text, start: start, end: end);
  }
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final ps = _toPlain(leaves, start);
  final pe = _toPlain(leaves, end);
  if (ps == pe) return (text: text, start: start, end: end);
  final updated = _mapRange(
    segments,
    ps,
    pe,
    (m) => index == null ? m.removed(format) : m.applied(format, index),
  );
  final out = _serialize(updated);
  return (
    text: out.text,
    start: out.starts[ps.clamp(0, out.starts.length - 1)],
    end: out.ends[pe.clamp(0, out.ends.length - 1)],
  );
}

/// Satır başlığı düzeyi (bkz. [setLineHeading]).
enum RichHeading {
  /// Büyük başlık: boy kademesi 7 (×1,6) + kalın.
  h1(7),

  /// Alt başlık: boy kademesi 6 (×1,4) + kalın.
  h2(6),

  /// Düz metin: boy ve kalınlık kaldırılır.
  normal(null);

  const RichHeading(this.sizeStep);

  /// [kRichSizeSteps] içindeki 1 tabanlı kademe; null = notun kendi boyu.
  final int? sizeStep;
}

/// İmlecin (ya da seçimin dokunduğu) SATIR(LAR)I başlık yapar.
///
/// Kullanıcı isteği 2026-09-23 ("başlık ve alt başlık"): yeni bir işaret
/// eklenmedi — başlık, zaten var olan iki biçimin birleşimi: satırın
/// TAMAMINA boy kademesi + kalın. Böylece eski sürümler, kartlar, PDF/Word
/// dışa aktarımı ve arama başlığı hiçbir değişiklik olmadan doğru çizer.
///
/// Seçim yoksa imlecin satırı alınır; boş satırda hiçbir şey yapılmaz (boş
/// işaret çifti yazılmaz). Dönen aralık: seçim vardıysa satırların tamamı,
/// yoksa satırın sonunda duran imleç.
({String text, int start, int end}) setLineHeading(
  String text,
  int start,
  int end,
  RichHeading heading,
) {
  if (start < 0 || end > text.length || end < start) {
    return (text: text, start: start, end: end);
  }
  final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
  final nl = text.indexOf('\n', end);
  final lineEnd = nl < 0 ? text.length : nl;
  if (lineEnd <= lineStart) return (text: text, start: start, end: end);
  final sized = setRangeFormat(
    text,
    lineStart,
    lineEnd,
    RichFormat.size,
    heading.sizeStep,
  );
  final bolded = setRangeFormat(
    sized.text,
    sized.start,
    sized.end,
    RichFormat.bold,
    heading == RichHeading.normal ? null : 1,
  );
  final collapsed = start == end;
  return (
    text: bolded.text,
    start: collapsed ? bolded.end : bolded.start,
    end: bolded.end,
  );
}

/// İmlecin satırının başlık düzeyi (biçim çubuğundaki vurgu için).
RichHeading lineHeadingAt(String text, int caret) {
  if (caret < 0 || caret > text.length) return RichHeading.normal;
  final lineStart = caret == 0 ? 0 : text.lastIndexOf('\n', caret - 1) + 1;
  final nl = text.indexOf('\n', caret);
  final lineEnd = nl < 0 ? text.length : nl;
  if (lineEnd <= lineStart) return RichHeading.normal;
  final size = rangeFormatIndex(text, lineStart, lineEnd, RichFormat.size);
  for (final h in RichHeading.values) {
    if (h.sizeStep != null && h.sizeStep == size) return h;
  }
  return RichHeading.normal;
}

/// Aralıktaki metnin ortak [format] indeksi (hepsi aynı değilse null).
int? rangeFormatIndex(String text, int start, int end, RichFormat format) {
  if (start < 0 || end > text.length || end < start) return null;
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final ps = _toPlain(leaves, start);
  final pe = _toPlain(leaves, end);
  int? found;
  var first = true;
  var pos = 0;
  for (final seg in segments) {
    final segStart = pos;
    final segEnd = pos + seg.text.length;
    pos = segEnd;
    if (segEnd <= ps || segStart >= pe) continue;
    final index = seg.mark.indexOf(format);
    if (first) {
      found = index;
      first = false;
    } else if (found != index) {
      return null;
    }
  }
  return found;
}

/// İmleci GÖRÜNMEZ işaretlerin içinden çıkarır.
///
/// İşaretler artık çizilmediği için imlecin onların arasında durması
/// kullanıcıya "imleç kıpırdamıyor" ya da "geri silme çalışmıyor" gibi
/// görünürdü (silinen şey görünmeyen bir yıldızdı). Konum, gerçek bir
/// karakterin sınırına çekilir; [backward] geriye giderken sola, ileri
/// giderken sağa öncelik verir.
///
/// Boş biçim kutusunun (`****`) içi ÖZELDİR: orası çözümlemede düz metin
/// sayıldığı için imleç orada kalır — kullanıcı yazmaya başlayınca yazdığı
/// biçimli çıksın diye.
int snapOutOfMarkers(String text, int offset, {bool backward = false}) {
  if (offset <= 0 || offset >= text.length) return offset;
  if (!_hasMarker(text)) return offset;
  final leaves = _parse(text);
  if (leaves.isEmpty) return offset;
  int? before;
  int? after;
  for (final leaf in leaves) {
    final start = leaf.markedStart;
    final end = start + leaf.text.length;
    if (offset >= start && offset <= end) return offset;
    if (end < offset) before = end;
    if (start > offset) {
      after = start;
      break;
    }
  }
  // Metnin başı ve sonu da geçerli birer sınırdır: baştaki işaretin ortasından
  // geriye giden imleç 0'a, sondakinden ileri giden imleç metnin sonuna gider.
  if (backward) return before ?? 0;
  return after ?? text.length;
}

/// İşaretli metnin GÖRÜNEN parçalarının `[başlangıç, bitiş)` aralıkları —
/// işaretli metindeki konumlarla. İşaret yoksa tek aralık: metnin tamamı.
///
/// Not içi aramanın (bkz. `TextSearchIndex`) eşleşmeyi işaretlerin
/// ARASINDAN geçerek bulabilmesi için: "**sü**t" ekranda "süt" okunur.
List<(int, int)> visibleRuns(String marked) {
  if (!_hasMarker(marked)) return [(0, marked.length)];
  return [
    for (final leaf in _parse(marked))
      (leaf.markedStart, leaf.markedStart + leaf.text.length),
  ];
}

/// [index] konumundaki karakter GÖRÜNMEZ bir işaretin parçası mı?
bool isMarkerOffset(String text, int index) {
  if (index < 0 || index >= text.length) return false;
  if (!_hasMarker(text)) return false;
  for (final leaf in _parse(text)) {
    if (index >= leaf.markedStart &&
        index < leaf.markedStart + leaf.text.length) {
      return false;
    }
  }
  return true;
}

/// Görünmez işaretin üstünde geri silme: işaret yerine imlecin solundaki
/// GERÇEK karakteri siler.
///
/// KÖK NEDEN (v1.0.182): işaretler görünmez çizildiğinden imleç biçimli
/// metnin sonunda aslında kapanış işaretinin ARDINDA duruyordu; geri silme
/// önce o işaretleri tek tek siliyor, ilk silmede biçim bozulduğu için
/// kalanlar bir anda EKRANDA BELİRİYORDU ("işaretler geldi, tek tek
/// siliniyor"). Artık silme metnin kendisine iner ve biçim korunur; son harf
/// de silinince boş kalan işaret çifti kendiliğinden düşer.
({String text, int caret})? deleteThroughMarkers(String text, int caret) {
  if (caret <= 0 || caret > text.length) return null;
  final leaves = _parse(text);
  if (leaves.isEmpty) return null;
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final plainCaret = _toPlain(leaves, caret);
  if (plainCaret <= 0) {
    // Silinecek gerçek karakter yok (imleç metnin başındaki işaretlerin
    // içinde): metne dokunma, imleci başa al.
    final out = _serialize(segments);
    return (text: out.text, caret: out.starts.first);
  }
  final updated = <RichSegment>[];
  var pos = 0;
  for (final seg in segments) {
    final start = pos;
    final end = pos + seg.text.length;
    pos = end;
    if (plainCaret - 1 < start || plainCaret - 1 >= end) {
      updated.add(seg);
      continue;
    }
    final at = plainCaret - 1 - start;
    updated.add(
      RichSegment(
        seg.text.substring(0, at) + seg.text.substring(at + 1),
        seg.mark,
      ),
    );
  }
  final out = _serialize(updated);
  final index = (plainCaret - 1).clamp(0, out.ends.length - 1);
  return (text: out.text, caret: out.ends[index]);
}

/// İmlecin İKİ YANINDA kalan boş işaret çiftlerini siler.
///
/// KÖK NEDEN (v1.0.185): biçimli bir kelimenin son harfi silinince geriye
/// iç içe geçmiş BOŞ işaretler kalıyor (`%%1:**_` + `_**%%`). Bunların içi
/// boş olduğu için hiçbiri biçim olarak eşleşmiyor ve düz metin gibi
/// ÇİZİLİYORLAR — kullanıcı sildikçe yeni işaretler beliriyormuş gibi
/// görünüyordu. Silmeden sonra imlecin iki yanı eşleşen açılış/kapanış
/// işaretiyse çift kaldırılır; içteki gidince dıştaki yan yana geldiği için
/// döngü hepsini toplar.
///
/// Yalnız İMLECİN YANINA bakar: metnin başka yerindeki `__` gibi diziler
/// (kullanıcının yazdığı olabilir) korunur.
({String text, int caret}) collapseEmptyMarkersAt(String text, int caret) {
  var out = text;
  var at = caret.clamp(0, text.length);
  var changed = true;
  while (changed) {
    changed = false;
    for (final format in RichFormat.values) {
      final close = format.marker;
      if (!out.startsWith(close, at)) continue;
      // Açılış işareti: düz (`**`) ya da kademe önekli (`%%3:`).
      final head = out.substring(0, at);
      var openStart = -1;
      if (head.endsWith(close)) {
        openStart = at - close.length;
      } else {
        final prefixed = RegExp(
          '${RegExp.escape(close)}(\\d:)\$',
        ).firstMatch(head);
        if (prefixed != null) openStart = prefixed.start;
      }
      if (openStart < 0) continue;
      out = out.replaceRange(at, at + close.length, '');
      out = out.replaceRange(openStart, at, '');
      at = openStart;
      changed = true;
      break;
    }
  }
  return (text: out, caret: at);
}
