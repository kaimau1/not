import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_speech.dart';
import 'package:notlar/features/ai/data/pcm_wav.dart';

/// Yapay zeka seslendirmesinin saf mantigi: modelin dondurdugu HAM PCM'e
/// WAV basligi yazma ve uzun metni model cagrisi basina paragraf boyunda
/// parcalara bolme.
void main() {
  group('pcmToWav', () {
    final pcm = Uint8List.fromList(List.filled(8, 1));

    test('44 baytlik RIFF/WAVE basligi ekler', () {
      final wav = pcmToWav(pcm);
      expect(wav.length, 44 + pcm.length);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    });

    test('baslikta ornekleme hizi ve veri boyutu dogru yazilir', () {
      final wav = pcmToWav(pcm, sampleRate: 16000);
      final view = ByteData.sublistView(wav);
      expect(view.getUint32(24, Endian.little), 16000); // sampleRate
      expect(view.getUint32(40, Endian.little), pcm.length); // data boyutu
      expect(view.getUint32(4, Endian.little), 36 + pcm.length); // RIFF boyutu
      expect(view.getUint16(20, Endian.little), 1); // 1 = PCM
      expect(view.getUint16(22, Endian.little), 1); // tek kanal
    });

    test('ham baytlar oldugu gibi kopyalanir', () {
      final wav = pcmToWav(Uint8List.fromList([7, 9]));
      expect(wav.sublist(44), [7, 9]);
    });
  });

  group('pcmSampleRate', () {
    test('MIME icindeki hizi okur', () {
      expect(pcmSampleRate('audio/L16;codec=pcm;rate=24000'), 24000);
      expect(pcmSampleRate('audio/L16;codec=pcm;rate=16000'), 16000);
    });

    test('hiz yoksa/bozuksa 24 kHz varsayilir', () {
      expect(pcmSampleRate('audio/L16'), 24000);
      expect(pcmSampleRate(''), 24000);
      expect(pcmSampleRate('audio/L16;rate=0'), 24000);
    });
  });

  group('AiSpeechController.chunk', () {
    test('kisa metin tek parca kalir', () {
      expect(AiSpeechController.chunk('Bir cumle. Iki cumle.'), hasLength(1));
    });

    test('uzun metin paragraf boyunda parcalara boluner', () {
      final uzun = List.filled(120, 'Bu bir deneme cumlesidir.').join(' ');
      final parcalar = AiSpeechController.chunk(uzun);
      expect(parcalar.length, greaterThan(1));
      // Her parca model cagrisina makul boyda gitmeli.
      for (final parca in parcalar) {
        expect(parca.length, lessThanOrEqualTo(1000));
      }
    });

    test('hicbir kelime kaybolmaz', () {
      final uzun = List.filled(120, 'Bu bir deneme cumlesidir.').join(' ');
      final birlesik = AiSpeechController.chunk(uzun).join(' ');
      expect(birlesik.split(' ').length, uzun.split(' ').length);
    });

    test('bos metin hic parca uretmez — bosa model cagrisi yok', () {
      expect(AiSpeechController.chunk('   '), isEmpty);
    });
  });
}
