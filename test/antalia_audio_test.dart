import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/antalia/antalia_audio.dart';
import 'package:notlar/features/ai/data/antalia/antalia_speech.dart';
import 'package:notlar/features/ai/data/antalia/antalia_text.dart';

/// Antalia ses son-işlemesi ve kare hesapları; ton zinciri orijinal Python
/// `post.py`'nin ürettiği vektörlerle (audio.js testinin verisi) ölçülür.
void main() {
  final vectors =
      (jsonDecode(
            File('test/fixtures/antalia_post_vectors.json').readAsStringSync(),
          ) as Map<String, dynamic>)['cases']
          as List;

  Float32List f32(List<dynamic> v) =>
      Float32List.fromList([for (final x in v) (x as num).toDouble()]);

  for (var i = 0; i < vectors.length; i++) {
    test('ton zinciri = post.py [$i]', () {
      final c = vectors[i] as Map<String, dynamic>;
      final got = AntaliaDsp.tone().process(f32(c['input'] as List));
      final expected = c['expected'] as List;
      expect(got.length, expected.length);
      var maxDiff = 0.0;
      for (var k = 0; k < got.length; k++) {
        final d = (got[k] - (expected[k] as num)).abs();
        if (d > maxDiff) maxDiff = d;
      }
      expect(maxDiff, lessThan(1e-6));
    });
  }

  test('ton zinciri parça parça = bütün', () {
    final input = f32((vectors[0] as Map)['input'] as List);
    final whole = AntaliaDsp.tone().process(input);
    final tone = AntaliaDsp.tone();
    final half = input.length >> 1;
    final p1 = tone.process(Float32List.sublistView(input, 0, half));
    final p2 = tone.process(Float32List.sublistView(input, half));
    final joined = [...p1, ...p2];
    for (var k = 0; k < whole.length; k++) {
      expect((joined[k] - whole[k]).abs(), lessThan(1e-6));
    }
  });

  test('pauseSec: cümle sonu 0,12, diğer 0,06', () {
    expect(AntaliaDsp.pauseSec('merhaba.'), 0.12);
    expect(AntaliaDsp.pauseSec('nasılsın?'), 0.12);
    expect(AntaliaDsp.pauseSec('boşluklu.   '), 0.12);
    expect(AntaliaDsp.pauseSec('geldim, gittim'), 0.06);
    expect(AntaliaDsp.pauseSec(''), 0.06);
  });

  test('mulberry32 gürültüsü app.js ile aynı dizi', () {
    // app.js: mulberry32(0)() ilk iki değer → Box-Muller → × 0.6.
    // mulberry32(0) = 0.26642920868471265, 0.00032974570058286190.
    final n = AntaliaDsp.noise(4, 0);
    expect(n.length, 4);
    expect(n[0], closeTo(0.9758594036102295, 1e-6));
    expect(n[1], closeTo(0.0020218403078615665, 1e-7));
    // Aynı tohum aynı gürültü, farklı tohum farklı.
    expect(AntaliaDsp.noise(4, 0), n);
    expect(AntaliaDsp.noise(4, 1), isNot(n));
  });

  test('ön ek yalnız ö/ı ile başlayan parçada', () {
    final a = AntaliaDsp.encodePiece('ölçü aldım.');
    final b = AntaliaDsp.encodePiece('merhaba.');
    expect(a.hasPrefix, isTrue);
    expect(a.preTokens, AntaliaText.encode(AntaliaDsp.prefix).length - 2);
    expect(b.hasPrefix, isFalse);
    expect(b.preTokens, 0);
    expect(b.ids.first, AntaliaText.bos);
  });

  test('süre, mel uzunluğu ve yayma', () {
    final logd = Float32List.fromList([0, 1, 10]);
    final dur = AntaliaDsp.durations(logd, 1);
    expect(dur, [1, 3, AntaliaDsp.maxDurFrames]);
    final melLen = AntaliaDsp.melLength(dur);
    expect(melLen, 64);
    final h = Float32List.fromList([1, 1, 2, 2, 3, 3]); // dText = 2
    final cond = AntaliaDsp.expand(h, dur, 2, melLen);
    expect(cond.sublist(0, 2), [1, 1]);
    expect(cond.sublist(2, 8), [2, 2, 2, 2, 2, 2]);
    expect(cond.sublist(cond.length - 2), [3, 3]);
  });

  test('kırpma ön/son eki keser, WAV 48 kHz', () {
    final dur = Int32List.fromList([1, 2, 3, 4, 5]);
    final wav = Float32List(15 * AntaliaDsp.hop)..fillRange(0, 15 * 512, 0.5);
    final out = AntaliaDsp.trim(
      wav,
      dur,
      preTokens: 1,
      sufTokens: 1,
      hasPrefix: true,
    );
    // a = (1+2)·512, b = (1+2+3)·512
    expect(out.length, 3 * AntaliaDsp.hop);
    expect(out.first, 0); // yumuşak giriş
    final bytes = AntaliaDsp.toWav(out);
    expect(
      ByteData.sublistView(bytes).getUint32(24, Endian.little),
      AntaliaDsp.sampleRate,
    );
    expect(bytes.length, 44 + out.length * 2);
  });

  test('okuma parçaları: ilk parça kısa, metin kaybolmaz', () {
    final text = List.filled(20, 'Bugün hava çok güzel.').join(' ');
    final chunks = AntaliaSpeechController.chunk(text);
    expect(chunks.length, greaterThan(1));
    expect(chunks.first.length, lessThanOrEqualTo(120));
    expect(chunks.skip(1).every((c) => c.length <= 400), isTrue);
    expect(chunks.join(' '), text);
  });
}
