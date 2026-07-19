import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/speech_output.dart';

/// Cümle bölme, sesli okumanın tek kırılgan parçası: yanlış bölerse okuma
/// ya cümle ortasında kesilir ya da TTS motoru uzun parçayı sessizce yutar.
void main() {
  test('Cümle sonlarından böler, boşları atar', () {
    final parts = SpeechOutputController.splitSentences(
      'Bugün markete gittim. Ekmek aldım!  Sonra eve döndüm?',
    );
    expect(parts, [
      'Bugün markete gittim.',
      'Ekmek aldım!',
      'Sonra eve döndüm?',
    ]);
  });

  test('Cümle sonu yoksa satır sonu ayraç olur', () {
    final parts = SpeechOutputController.splitSentences(
      'Süt\n\nYumurta\n   \nPeynir',
    );
    expect(parts, ['Süt', 'Yumurta', 'Peynir']);
  });

  test('Uzun cümle kelime ortasından bölünmez', () {
    final long = '${'kelime ' * 80}son';
    final parts = SpeechOutputController.splitSentences(long);
    expect(parts.length, greaterThan(1));
    for (final part in parts) {
      expect(part.length, lessThanOrEqualTo(300));
      expect(part.trim(), part);
    }
    // Hiçbir kelime kaybolmamalı.
    expect(parts.join(' ').split(' ').length, long.trim().split(' ').length);
  });

  test('Boş metin boş liste döndürür', () {
    expect(SpeechOutputController.splitSentences('   \n  '), isEmpty);
  });

  group('Otomatik ses seçimi', () {
    // Android cinsiyeti ada gömer; "female" kelimesi "male" içerdiği için
    // saf contains("male") kontrolü kadın sesi seçerdi. Asıl tuzak bu.
    test('female sesi erkek sanmaz', () {
      final picked = SpeechOutputController.pickAutoVoice(const [
        SpeechVoice(name: 'de-de-x-nfh#female_2-local', locale: 'de-DE'),
        SpeechVoice(name: 'de-de-x-nfh#male_1-local', locale: 'de-DE'),
      ]);
      expect(picked?.name, 'de-de-x-nfh#male_1-local');
    });

    test('erkek ses yoksa ilk sese düşer', () {
      final picked = SpeechOutputController.pickAutoVoice(const [
        SpeechVoice(name: 'ja-jp-x-htm#female_1-local', locale: 'ja-JP'),
        SpeechVoice(name: 'ja-jp-x-htm#female_2-local', locale: 'ja-JP'),
      ]);
      expect(picked?.name, 'ja-jp-x-htm#female_1-local');
    });

    test('hiç ses yoksa null', () {
      expect(SpeechOutputController.pickAutoVoice(const []), isNull);
    });
  });
}
