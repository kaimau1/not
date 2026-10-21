import 'dart:math' as math;
import 'dart:typed_data';

import '../pcm_wav.dart';
import 'antalia_text.dart';

/// Antalia-2 Mini'nin modeller ARASINDAKİ saf hesapları: süre tahmininden
/// kare zaman çizelgesi, gürültü, ön/son ek kırpması ve çıkış tonu.
///
/// KAYNAK: `fr0stb1rd/antalia-mini-web` app.js `synthPieces` + audio.js (o da
/// orijinal Python `api.py`/`post.py`; PatientDesk AI, Apache-2.0). Sabitler
/// oradaki ile aynı; ONNX oturumlarına dokunmayan her şey burada olduğu için
/// birim testli (`test/antalia_audio_test.dart`).
class AntaliaDsp {
  AntaliaDsp._();

  static const sampleRate = 48000;
  static const hop = 512;
  static const nMels = 128;
  static const stack = 2;
  static const noiseDim = nMels * stack; // 256
  static const maxDurFrames = 60;

  /// En iyi akış eşleme gürültü sıcaklığı.
  static const temperature = 0.6;

  /// Sürümle gelen konuşma hızı (`weights.DEFAULTS.speed`).
  static const defaultSpeed = 0.95;

  /// Türkçe çift ünsüz ("berraktı", "mahvediyor") süre uzatması.
  static final logGem = math.log(1.3);

  /// "ö"/"ı" ile başlayan parçanın önüne söylenip kesilen ek: model cümle
  /// başı ö/ı'dan önce kaçak bir "l" sesi çıkarıyor. Son ek ise bitiş
  /// kırpılmasın diye.
  static const prefix = 'ee, ';
  static const suffix = ' ee.';
  static const prefixInitials = {'ö', 'ı'};

  /// Bir model parçası için kimlikler ve ön/son ekin kapladığı harf sayısı.
  static ({List<int> ids, int preTokens, int sufTokens, bool hasPrefix})
  encodePiece(String part) {
    final trimmed = part.trim();
    final hasPrefix = trimmed.isNotEmpty && prefixInitials.contains(trimmed[0]);
    final ids = AntaliaText.encode('${hasPrefix ? prefix : ''}$part$suffix');
    return (
      ids: ids,
      preTokens: hasPrefix ? AntaliaText.encode(prefix).length - 2 : 0,
      sufTokens: AntaliaText.encode(suffix).length - 2,
      hasPrefix: hasPrefix,
    );
  }

  /// Çift ünsüz uzatması (yerinde) — app.js ile aynı döngü.
  static void stretchGeminates(List<int> ids, Float32List logd) {
    final space = AntaliaText.symbolToId[' ']!;
    for (var i = 2; i < ids.length - 1; i++) {
      if (ids[i] == ids[i - 1] && ids[i] != space) {
        logd[i] += logGem;
      } else if (ids[i - 1] == space && ids[i] == ids[i - 2]) {
        logd[i - 1] += logGem;
      }
    }
  }

  /// Harf başına kare sayısı (1..[maxDurFrames]).
  static Int32List durations(Float32List logd, double speed) {
    final dur = Int32List(logd.length);
    for (var i = 0; i < logd.length; i++) {
      dur[i] = (math.exp(logd[i]) / speed).round().clamp(1, maxDurFrames);
    }
    return dur;
  }

  /// Toplam karenin [stack]'in katına yuvarlanmışı (mel uzunluğu).
  static int melLength(Int32List dur) {
    var total = 0;
    for (final d in dur) {
      total += d;
    }
    return (total + stack - 1) ~/ stack * stack;
  }

  /// Harf gizli durumlarını kare zaman çizelgesine yayar: `[melLen, dText]`.
  static Float32List expand(
    Float32List h,
    Int32List dur,
    int dText,
    int melLen,
  ) {
    final cond = Float32List(melLen * dText);
    final length = dur.length;
    var f = 0;
    for (var i = 0; i < length; i++) {
      for (var k = 0; k < dur[i] && f < melLen; k++) {
        cond.setRange(f * dText, (f + 1) * dText, h, i * dText);
        f++;
      }
    }
    while (f < melLen) {
      cond.setRange(f * dText, (f + 1) * dText, h, (length - 1) * dText);
      f++;
    }
    return cond;
  }

  /// [temperature] ile ölçekli Gauss gürültüsü (mulberry32 + Box-Muller,
  /// app.js ile aynı dizi — aynı tohum aynı sesi verir).
  static Float32List noise(int length, int seed) {
    const m = 0xFFFFFFFF;
    int imul(int a, int b) => ((a & m) * (b & m)) & m;
    var a = seed & m;
    double rand() {
      a = (a + 0x6D2B79F5) & m;
      var t = imul(a ^ (a >> 15), 1 | a);
      t = ((t + imul(t ^ (t >> 7), 61 | t)) & m) ^ t;
      return ((t ^ (t >> 14)) & m) / 4294967296;
    }

    final out = Float32List(length);
    for (var i = 0; i < length; i += 2) {
      final u1 = math.max(rand(), 1e-9), u2 = rand();
      final r = math.sqrt(-2 * math.log(u1)), th = 2 * math.pi * u2;
      out[i] = r * math.cos(th) * temperature;
      if (i + 1 < length) out[i + 1] = r * math.sin(th) * temperature;
    }
    return out;
  }

  /// Parça tohumu (app.js: `seed * 1000003 + sıra`).
  static int pieceSeed(int seed, int index) =>
      (seed * 1000003 + index) & 0xFFFFFFFF;

  /// Ön ve son ekin sesini keser, uçlara 5 ms yumuşak geçiş koyar.
  static Float32List trim(
    Float32List wav,
    Int32List dur, {
    required int preTokens,
    required int sufTokens,
    required bool hasPrefix,
  }) {
    final length = dur.length;
    var cum = 0;
    var a = 0, b = wav.length;
    for (var i = 0; i < length; i++) {
      cum += dur[i];
      if (i == preTokens && hasPrefix) a = cum * hop;
      if (i == length - 2 - sufTokens) b = cum * hop;
    }
    final start = math.max(0, a);
    final end = math.max(start, math.min(wav.length, b));
    final out = Float32List.fromList(wav.sublist(start, end));
    final fade = (0.005 * sampleRate).floor();
    if (out.length > 2 * fade) {
      for (var i = 0; i < fade; i++) {
        final g = i / fade;
        if (hasPrefix) out[i] *= g;
        out[out.length - 1 - i] *= g;
      }
    }
    return out;
  }

  /// Parça sonrası sessizlik (api.py `_pause`): cümle sonu 0,12 sn, diğer
  /// 0,06 sn.
  static double pauseSec(String part) {
    final t = part.trimRight();
    final last = t.isEmpty ? '' : t[t.length - 1];
    return (last == '.' || last == '?' || last == '!') ? 0.12 : 0.06;
  }

  /// [samples]'ın sonuna [seconds] sessizlik ekler.
  static Float32List withPause(Float32List samples, double seconds) {
    final out = Float32List(samples.length + (seconds * sampleRate).round());
    out.setAll(0, samples);
    return out;
  }

  // post.py: lowshelf(210 Hz, +6 dB) / highshelf(4 kHz, -9 dB), Q 0,707.
  static const _toneLow = (
    b0: 1.0067698504364737,
    b1: -1.9670261142112211,
    b2: 0.9613064506769197,
    a1: -1.9672880375281616,
    a2: 0.9678143777964527,
  );
  static const _toneHigh = (
    b0: 0.4282380647227790,
    b1: -0.4673907653709056,
    b2: 0.1672663299532398,
    a1: -1.4337659737473694,
    a2: 0.5618796030524825,
  );

  /// Çıkış tonu zinciri. Filtre durumu parçalar arasında TAŞINIR: parça
  /// parça işlemek bütünü işlemekle aynı örnekleri verir.
  static AntaliaTone tone() =>
      AntaliaTone._(AntaliaBiquad._(_toneLow), AntaliaBiquad._(_toneHigh));

  /// [-1, 1] örnekleri 16 bit PCM WAV'a döker.
  static Uint8List toWav(Float32List samples) {
    final pcm = ByteData(samples.length * 2);
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      pcm.setInt16(i * 2, v, Endian.little);
    }
    return pcmToWav(pcm.buffer.asUint8List(), sampleRate: sampleRate);
  }
}

/// Doğrudan biçim IIR (post.py `lfilter`).
class AntaliaBiquad {
  AntaliaBiquad._(({double b0, double b1, double b2, double a1, double a2}) c)
    : b0 = c.b0,
      b1 = c.b1,
      b2 = c.b2,
      a1 = c.a1,
      a2 = c.a2;

  final double b0, b1, b2, a1, a2;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  Float32List process(Float32List x) {
    final y = Float32List(x.length);
    var x1 = _x1, x2 = _x2, y1 = _y1, y2 = _y2;
    for (var i = 0; i < x.length; i++) {
      final v = x[i];
      final out = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      x2 = x1;
      x1 = v;
      y2 = y1;
      y1 = out;
      y[i] = out;
    }
    _x1 = x1;
    _x2 = x2;
    _y1 = y1;
    _y2 = y2;
    return y;
  }
}

/// Ton zinciri: lowshelf → highshelf → yumuşak sınırlayıcı (post.py
/// `OutputChain`, tone yolu).
class AntaliaTone {
  AntaliaTone._(this._low, this._high);

  final AntaliaBiquad _low;
  final AntaliaBiquad _high;

  // post.py LIMIT_THRESHOLD (-1 dBFS) / LIMIT_CEILING (-0,1 dBFS).
  static final _thresh = math.pow(10, -1.0 / 20).toDouble();
  static final _room = math.pow(10, -0.1 / 20).toDouble() - _thresh;

  Float32List process(Float32List samples) {
    final s = _high.process(_low.process(samples));
    for (var i = 0; i < s.length; i++) {
      final v = s[i];
      final a = v.abs();
      if (a > _thresh) {
        s[i] = v.sign * (_thresh + _room * _tanh((a - _thresh) / _room));
      }
    }
    return s;
  }

  static double _tanh(double x) {
    if (x > 20) return 1; // exp taşmasın (x ≥ 0 burada)
    final e = math.exp(2 * x);
    return (e - 1) / (e + 1);
  }
}
