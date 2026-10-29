/// Videonun zamanlı transkriptinden bir parça: [start] ve [end] saniye.
class CaptionSegment {
  const CaptionSegment(this.start, this.end, this.text);

  final double start;
  final double end;
  final String text;

  @override
  String toString() => 'CaptionSegment($start-$end: $text)';
}

/// Kanallarım'ın altyazı bloğu (bkz. [TimedTranscript.parseCaptionBlock]).
class CaptionBlock {
  const CaptionBlock(this.head, this.text, this.from, this.to);

  final String head;
  final String text;
  final int from;
  final int to;
}

/// **ZAMANLI TRANSKRİPT** (kullanıcı isteği 2026-10-29: "Kanallarım'dan full
/// transkript de gelsin; notlarda ±10 sn'lik transkript"). Gemini YouTube
/// videosunu bağlantıdan cümle başına "[d:ss]" damgalı döker
/// ([GeminiService.transcribeMedia], `sentenceStamps`); bu sınıf o metni
/// zamanlı parçalara çevirir, tam metni paragraflar ve not anının çevresini
/// keser. YouTube'un iç API'si kazınmaz (bot korumasına takılır, ToS dışı).
abstract final class TimedTranscript {
  static final _captionBlock = RegExp(
    r'\s*Altyazı\s*\((\d{1,2}(?::\d{2}){1,2})\s*[–—-]\s*'
    r'(\d{1,2}(?::\d{2}){1,2})\)\s*:\s*([\s\S]*)$',
  );

  /// Kanallarım notun sonuna "Altyazı (1:24 – 1:44):\n`<ham altyazı>`" ekler:
  /// bloktan önceki metin ([CaptionBlock.head]), tek satıra indirilmiş altyazı
  /// ve aralık. Blok yoksa null.
  static CaptionBlock? parseCaptionBlock(String text) {
    final m = _captionBlock.firstMatch(text);
    if (m == null) return null;
    final caption = m.group(3)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (caption.isEmpty) return null;
    return CaptionBlock(
      text.substring(0, m.start).trim(),
      caption,
      _seconds(m.group(1)!),
      _seconds(m.group(2)!),
    );
  }

  /// Gemini dökümü ("[1:23] paragraf …") → parçalar. Her paragraf bir
  /// sonrakinin başına dek sürer; damgasız metin tek parça (0 sn).
  static List<CaptionSegment> parseStamped(String text) {
    final re = RegExp(r'\[(\d{1,2}(?::\d{2}){1,2})\]');
    final matches = re.allMatches(text).toList();
    if (matches.isEmpty) {
      final t = text.trim();
      return t.isEmpty ? const [] : [CaptionSegment(0, 1e9, t)];
    }
    final out = <CaptionSegment>[];
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final body = text.substring(m.end, end).trim();
      if (body.isEmpty) continue;
      out.add(CaptionSegment(_seconds(m.group(1)!).toDouble(), 0, body));
    }
    return [
      for (var i = 0; i < out.length; i++)
        CaptionSegment(
          out[i].start,
          i + 1 < out.length ? out[i + 1].start : out[i].start + 600,
          out[i].text,
        ),
    ];
  }

  static int _seconds(String stamp) =>
      stamp.split(':').fold(0, (acc, p) => acc * 60 + int.parse(p));

  /// "0:07", "1:23", "1:02:03".
  static String stamp(num seconds) {
    final s = seconds.floor().clamp(0, 1 << 30);
    final h = s ~/ 3600;
    final m = s % 3600 ~/ 60;
    final ss = (s % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  }

  /// Tam transkript metni: parçalar paragraflara toplanır (cümle sonunda ve
  /// en az ~8 sn'de, noktalamasız otomatik altyazıda en geç ~25 sn'de bir),
  /// her paragrafın başında "[d:ss]". Damgalar okunur kalır, metin satır
  /// satır kırılmaz.
  static String fullText(List<CaptionSegment> segments) {
    final out = StringBuffer();
    final para = <String>[];
    double? paraStart;
    void flush() {
      if (para.isEmpty) return;
      if (out.isNotEmpty) out.write('\n\n');
      out.write('[${stamp(paraStart!)}] ${para.join(' ')}');
      para.clear();
      paraStart = null;
    }

    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      paraStart ??= s.start;
      para.add(s.text);
      final next = i + 1 < segments.length ? segments[i + 1].start : s.end;
      final span = next - paraStart!;
      if ((span >= 8 && _endsSentence(s.text)) || span >= 25) flush();
    }
    flush();
    return out.toString();
  }

  static bool _endsSentence(String t) => RegExp(r'[.!?…]["”’)]*$').hasMatch(t);

  /// [center] saniyesinin ±[radius] sn'sindeki parçalar; cümle bütünlüğü
  /// için iki yana en çok [slack] sn daha (AI'a giden ham pencere).
  static List<CaptionSegment> window(
    List<CaptionSegment> segments,
    num center, {
    double radius = 10,
    double slack = 6,
  }) => [
    for (final s in segments)
      if (s.end > center - radius - slack && s.start < center + radius + slack)
        s,
  ];

  /// AI olmadan parça: ±[radius] sn'deki parçalar, cümle başına/sonuna dek
  /// en çok [slack] sn genişletilir (otomatik altyazıda noktalama yoksa
  /// düz ±10 sn kalır).
  static String excerpt(
    List<CaptionSegment> segments,
    num center, {
    double radius = 10,
    double slack = 6,
  }) {
    final from = center - radius;
    final to = center + radius;
    var first = -1;
    var last = -1;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s.end > from && s.start < to) {
        if (first < 0) first = i;
        last = i;
      }
    }
    if (first < 0) return '';
    // Önceki parça cümleyle bitmiyorsa geri git (sınır: slack).
    while (first > 0 &&
        !_endsSentence(segments[first - 1].text) &&
        segments[first - 1].start >= from - slack) {
      first--;
    }
    while (last + 1 < segments.length &&
        !_endsSentence(segments[last].text) &&
        segments[last + 1].end <= to + slack) {
      last++;
    }
    return [for (var i = first; i <= last; i++) segments[i].text]
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
