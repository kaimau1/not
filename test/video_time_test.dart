import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/video_time.dart';
import 'package:notlar/core/utils/youtube.dart';

/// "Videolarda dk:sn notu, YouTube'daki gibi" (kullanıcı isteği 2026-10-16).
void main() {
  group('findVideoTimestamps', () {
    test('d:ss ve s:dd:ss damgaları saniyeye çevrilir', () {
      final hits = findVideoTimestamps('giriş 0:07, örnek 1:23 ve 1:02:33.');
      expect([for (final h in hits) h.seconds], [7, 83, 3753]);
      expect('giriş 0:07'.substring(hits.first.start, hits.first.end), '0:07');
    });

    test('uzun dakika (90:05) da damgadır', () {
      expect(findVideoTimestamps('90:05').single.seconds, 5405);
    });

    test('seri numarası, ondalık ve geçersiz saniye damga değildir', () {
      expect(findVideoTimestamps('10:30:45:12'), isEmpty);
      expect(findVideoTimestamps('12:345'), isEmpty);
      expect(findVideoTimestamps('1:75'), isEmpty);
      expect(findVideoTimestamps('v1.2:30'), isEmpty);
      expect(findVideoTimestamps('3:30.5'), isEmpty);
      expect(findVideoTimestamps('saat yok'), isEmpty);
    });

    test('cümle sonu noktalaması damgayı bozmaz', () {
      expect(findVideoTimestamps('bkz. 4:20.').single.seconds, 260);
      expect(findVideoTimestamps('(4:20)').single.seconds, 260);
    });

    test('videoTimestampAt imleç damganın içinde ya da sınırında', () {
      const text = 'a 1:23 b';
      expect(videoTimestampAt(text, 2)?.seconds, 83);
      expect(videoTimestampAt(text, 4)?.seconds, 83);
      expect(videoTimestampAt(text, 6)?.seconds, 83);
      expect(videoTimestampAt(text, 0), isNull);
      expect(videoTimestampAt(text, 8), isNull);
    });
  });

  test('formatVideoTimestamp YouTube biçimi (baştaki sıfırsız)', () {
    expect(formatVideoTimestamp(const Duration(seconds: 7)), '0:07');
    expect(formatVideoTimestamp(const Duration(seconds: 83)), '1:23');
    expect(formatVideoTimestamp(const Duration(seconds: 3753)), '1:02:33');
    expect(formatVideoTimestamp(const Duration(milliseconds: 83900)), '1:23');
    expect(formatVideoTimestamp(const Duration(seconds: -4)), '0:00');
  });

  group('insertTimestampLine', () {
    test('boş satıra damga yazılır, imleç ardında', () {
      final r = insertTimestampLine('', -1, '1:23');
      expect(r.text, '1:23 ');
      expect(r.caret, 5);
    });

    test('dolu satırda imleç varsa ALTINA yeni satır açılır', () {
      final r = insertTimestampLine('giriş\nikinci', 3, '0:42');
      expect(r.text, 'giriş\n0:42 \nikinci');
      expect(r.text.substring(0, r.caret), 'giriş\n0:42 ');
    });

    test('imleç bilinmiyorsa metnin sonuna', () {
      final r = insertTimestampLine('a\nb', -1, '2:00');
      expect(r.text, 'a\nb\n2:00 ');
      expect(r.caret, r.text.length);
    });

    test('imlecin satırı boşsa oraya (yeni satır açmaz)', () {
      final r = insertTimestampLine('a\n\nb', 2, '3:10');
      expect(r.text, 'a\n3:10 \nb');
      expect(r.caret, 7);
    });
  });

  test('gömülü oynatıcı konum okuma/sarma köprüsünü taşır, dış betik yok', () {
    final html = youTubeEmbedHtml('dQw4w9WgXcQ', start: 42);
    expect(html, contains('window.notlarTime'));
    expect(html, contains('window.notlarSeek'));
    expect(html, contains("event:'listening'"));
    // Konum hiç gelmediyse BİLİNMİYOR (-1) — yanlış 0:00 yazılmasın.
    expect(html, contains('notlarHeard?notlarCur:-1'));
    expect(html, contains('notlarCur=42'));
    expect(html, isNot(contains('iframe_api')));
  });

  group('NoteVideoHub', () {
    test('damga SON oynatılana gider; yoksa tercih edilene', () {
      final hub = NoteVideoHub();
      final a = _FakeSource('a');
      final b = _FakeSource('b');
      hub
        ..register(a)
        ..register(b);
      expect(hub.target(preferId: 'a'), same(a));
      hub.touch(b);
      expect(hub.target(preferId: 'a'), same(b));
      hub.unregister(b);
      expect(hub.target(), same(a));
      hub.unregister(a);
      expect(hub.target(), isNull);
    });

    test('noteAt konumu editöre verir; konum yoksa false', () async {
      final hub = NoteVideoHub();
      final calls = <(String, Duration)>[];
      hub.onNoteAt = (id, p) => calls.add((id, p));
      final a = _FakeSource('a', at: const Duration(seconds: 65));
      hub.register(a);
      expect(await hub.noteAt(a), isTrue);
      expect(calls.single, ('a', const Duration(seconds: 65)));
      expect(await hub.noteAt(_FakeSource('x')), isFalse);
    });

    test('başlatma isteği aynı saniyede de dinleyiciyi uyandırır', () {
      final hub = NoteVideoHub();
      var heard = 0;
      hub.startRequest.addListener(() => heard++);
      hub
        ..requestStart('v', 30)
        ..requestStart('v', 30);
      expect(heard, 2);
      expect(hub.startRequest.value?.seconds, 30);
    });
  });
}

class _FakeSource extends VideoTimeSource {
  _FakeSource(this.attachmentId, {this.at});

  @override
  final String attachmentId;
  final Duration? at;

  @override
  Future<Duration?> position() async => at;

  @override
  Future<void> seekTo(Duration position) async {}
}
