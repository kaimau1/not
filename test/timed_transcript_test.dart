import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/video_note_transcripts.dart';
import 'package:notlar/features/notes/data/timed_transcript.dart';

void main() {
  const segs = [
    CaptionSegment(0, 4, 'Merhaba arkadaşlar.'),
    CaptionSegment(4, 9, 'Bugün türev konusunu'),
    CaptionSegment(9, 14, 'baştan anlatacağım.'),
    CaptionSegment(14, 20, 'Önce limit tanımına'),
    CaptionSegment(20, 26, 'bakalım ve örnek çözelim.'),
    CaptionSegment(26, 31, 'Sonra kurallara geçeceğiz.'),
    CaptionSegment(31, 40, 'Hepsi bu kadar.'),
  ];

  test('parça ±10 sn, cümle sınırına genişler', () {
    // 18. sn: pencere 8–28; 'Bugün türev…' (4–9) cümle ortası → dahil,
    // 'Sonra kurallara…' (26–31) cümle sonuyla biter.
    final text = TimedTranscript.excerpt(segs, 18);
    expect(text, startsWith('Bugün türev konusunu'));
    expect(text, endsWith('Sonra kurallara geçeceğiz.'));
    expect(text, isNot(contains('Merhaba')));
    expect(text, isNot(contains('Hepsi')));
  });

  test('Gemini dökümü damgalardan parçalara', () {
    final out = TimedTranscript.parseStamped(
      '[0:00] Giriş cümlesi.\n\n[1:05] İkinci paragraf.',
    );
    expect(out, hasLength(2));
    expect(out[1].start, 65);
    expect(out[0].end, 65);
  });

  test('tam metin damgalı paragraflar', () {
    final full = TimedTranscript.fullText(segs);
    expect(full, startsWith('[0:00] Merhaba arkadaşlar.'));
    expect(full.split('\n'), hasLength(segs.length));
    expect(TimedTranscript.parseStamped(full), hasLength(segs.length));
  });

  test('parça doğru satırın altına, sonra bir sonrakine', () {
    var body = '0:18 türev\n\n0:18 türev';
    body = insertVideoExcerpt(body, '0:18 türev', 'A');
    expect(body, '0:18 türev\n“A”\n\n0:18 türev');
    body = insertVideoExcerpt(body, '0:18 türev', 'B');
    expect(body, '0:18 türev\n“A”\n\n0:18 türev\n“B”');
    expect(insertVideoExcerpt('x', 'yok', 'C'), 'x\n“C”');
  });

  test('Kanallarım altyazı bloğu ayrılır', () {
    final b = TimedTranscript.parseCaptionBlock(
      '1:34 Deneme\n\nAltyazı (1:24 – 1:44):\nhalde niye\nsinirleniyoruz?',
    )!;
    expect(b.head, '1:34 Deneme');
    expect(b.text, 'halde niye sinirleniyoruz?');
    expect(b.from, 84);
    expect(b.to, 104);
    expect(TimedTranscript.parseCaptionBlock('1:34 Deneme'), isNull);
  });

  test('eski biçim: satır + blok, satır + düzgün parçayla değişir', () {
    const line = '1:34 Deneme\n\nAltyazı (1:24 – 1:44):\nhalde niye';
    final body = applyVideoExcerpt(
      'önceki\n\n$line',
      line,
      '',
      'Bu hâlde niye sinirleniyoruz?',
    );
    expect(body, 'önceki\n\n1:34 Deneme\n“Bu hâlde niye sinirleniyoruz?”');
  });

  test('yeni biçim: ham altyazı satırı düzeltilmişiyle değişir', () {
    final body = applyVideoExcerpt(
      '1:34 Deneme\n${videoRawCaptionLine('halde niye')}',
      '1:34 Deneme',
      'halde niye',
      'Bu hâlde niye?',
    );
    expect(body, '1:34 Deneme\n“Bu hâlde niye?”');
  });
}
