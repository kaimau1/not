import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/speech_text.dart';

/// Tanıyıcı segment sınırında kelime tekrarlıyor (bilinçli takas: konuşulanı
/// kaybetmektense tekrar etmek). Kullanıcıya giden dökümde o tekrar görünmez.
void main() {
  test('segment sınırındaki tekrar eden kelime düşer', () {
    expect(
      dedupeSpeechSegments('1156 eldiven\neldiven 558 blade'),
      '1156 eldiven\n558 blade',
    );
  });

  test('birden çok kelimelik örtüşme tümüyle düşer', () {
    expect(
      dedupeSpeechSegments('bugün markete gittim\nmarkete gittim ekmek aldım'),
      'bugün markete gittim\nekmek aldım',
    );
  });

  test('büyük harf ve noktalama farkı tekrarı gizlemez', () {
    expect(
      dedupeSpeechSegments('toplantı yarın.\nYarın saat dokuzda'),
      'toplantı yarın.\nsaat dokuzda',
    );
  });

  test('satırın tamamı tekrarsa satır tümüyle düşer', () {
    expect(dedupeSpeechSegments('merhaba dünya\nmerhaba dünya'), 'merhaba dünya');
  });

  test('tekrar yoksa metin olduğu gibi kalır', () {
    const text = 'ilk cümle\nikinci cümle';
    expect(dedupeSpeechSegments(text), text);
  });

  test('tek satırlı metne dokunulmaz', () {
    const text = 'çok çok iyi bir fikir';
    expect(dedupeSpeechSegments(text), text);
  });

  test('cümle ortasındaki gerçek tekrar korunur', () {
    // "çok çok" satır sınırında DEĞİL; kullanıcı gerçekten iki kez söylemiş.
    expect(
      dedupeSpeechSegments('bu çok çok iyi\nyarın görüşürüz'),
      'bu çok çok iyi\nyarın görüşürüz',
    );
  });
}
