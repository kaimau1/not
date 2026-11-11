import 'dart:typed_data';

import 'attachment.dart';

/// **MÜREKKEP PAKETİ** (F61.1, OTURTMA_PLANI Ek B): çizgilerin sıkı ikili
/// biçimi. Bugünkü `toMap()` nokta başına iki Firestore sayısı (~16 bayt +
/// dizi yükü) yazıyor; paket fark kodlamalı varint ile nokta başına ~2–4
/// bayt. Yalnız v2 mürekkep belgesinde (`notes/{id}/ink/…`) kullanılır;
/// not paketi / yedek JSON biçimi değişmez.
///
/// Biçim (küçük uçlu):
/// ```
/// 'I' 'K' · sürüm u8 = 1 · çizgiSayısı varuint
/// her çizgi: bayrak u8 (bit0 ok, bit1 basınç) · sayfa varuint · renk u32
///   · kalınlık f32 · z f64 · n varuint · x0,y0 zigzag · (n−1)×(dx,dy) zigzag
///   · basınç varsa n × u8
/// ```
const kInkUnit = 1 / 16384;
const kInkPackVersion = 1;

/// F61.2 kalkışta sadeleştirme toleransı (sayfa oranı; 760 dp'de ~0,3 dp).
const kInkSimplifyTolerance = 0.0004;

/// Çizgileri pakete yazar. [z] verilmezse çizim sırası (0, 1, 2…).
Uint8List encodeInkPack(List<InkStroke> strokes, {List<double>? z}) {
  if (z != null && z.length != strokes.length) {
    throw ArgumentError('z uzunluğu çizgi sayısıyla aynı olmalı');
  }
  final w = _Writer();
  w.byte(0x49);
  w.byte(0x4B);
  w.byte(kInkPackVersion);
  w.varuint(strokes.length);
  for (var i = 0; i < strokes.length; i++) {
    final s = strokes[i];
    final pressure = s.hasPressure;
    w.byte((s.arrow ? 1 : 0) | (pressure ? 2 : 0));
    w.varuint(s.page < 0 ? 0 : s.page);
    w.u32(s.color & 0xFFFFFFFF);
    w.f32(s.width);
    w.f64(z?[i] ?? i.toDouble());
    final pts = s.points;
    final n = pts.length ~/ 2;
    w.varuint(n);
    var px = 0, py = 0;
    for (var k = 0; k < n; k++) {
      final x = (pts[2 * k] / kInkUnit).round();
      final y = (pts[2 * k + 1] / kInkUnit).round();
      w.zigzag(x - px);
      w.zigzag(y - py);
      px = x;
      py = y;
    }
    if (pressure) {
      final q = s.pressures!;
      for (var k = 0; k < n; k++) {
        w.byte((q[k].clamp(0.0, 1.0) * 255).round());
      }
    }
  }
  return w.take();
}

/// Paketi çözer. Bozuk, kısa ya da bilinmeyen sürümlü girdi
/// [FormatException] atar (çökme yok).
({List<InkStroke> strokes, List<double> z}) decodeInkPack(Uint8List bytes) {
  final r = _Reader(bytes);
  if (r.byte() != 0x49 || r.byte() != 0x4B) {
    throw const FormatException('mürekkep paketi değil');
  }
  final version = r.byte();
  if (version != kInkPackVersion) {
    throw FormatException('bilinmeyen mürekkep paketi sürümü: $version');
  }
  final count = r.varuint();
  // Her çizgi en az 18 bayt: sahte büyük sayıyla bellek ayırmayı önle.
  if (count > bytes.length) throw const FormatException('çizgi sayısı bozuk');
  final strokes = <InkStroke>[];
  final zs = <double>[];
  for (var i = 0; i < count; i++) {
    final flags = r.byte();
    final page = r.varuint();
    final color = r.u32();
    final width = r.f32();
    final z = r.f64();
    final n = r.varuint();
    if (n * 2 > bytes.length) throw const FormatException('nokta sayısı bozuk');
    final pts = Float32List(n * 2);
    var x = 0, y = 0;
    for (var k = 0; k < n; k++) {
      x += r.zigzag();
      y += r.zigzag();
      pts[2 * k] = x * kInkUnit;
      pts[2 * k + 1] = y * kInkUnit;
    }
    Float32List? q;
    if (flags & 2 != 0) {
      q = Float32List(n);
      for (var k = 0; k < n; k++) {
        q[k] = r.byte() / 255;
      }
    }
    strokes.add(
      InkStroke(
        page: page,
        color: color,
        width: width,
        points: pts,
        arrow: flags & 1 != 0,
        pressures: q,
      ),
    );
    zs.add(z);
  }
  return (strokes: strokes, z: zs);
}

/// **ÇİZGİ SADELEŞTİRME** (F61.2): düz `[x1, y1, …]` listesinde RDP. İlk/son
/// nokta korunur; [pressures] aynı indekslerle süzülür. 2 ya da daha az
/// noktalı çizgi olduğu gibi döner. (`ink_recognize.dart`'taki `_simplify`
/// `Offset` ile şekil tanımada çalışıyor; o değişmedi.)
({List<double> points, List<double>? pressures}) simplifyStroke(
  List<double> points,
  double tolerance, {
  List<double>? pressures,
}) {
  final n = points.length ~/ 2;
  if (n < 3) return (points: points, pressures: pressures);
  final keep = List<bool>.filled(n, false);
  keep[0] = keep[n - 1] = true;
  final stack = <(int, int)>[(0, n - 1)];
  final tol2 = tolerance * tolerance;
  while (stack.isNotEmpty) {
    final (s, e) = stack.removeLast();
    final ax = points[2 * s], ay = points[2 * s + 1];
    final dx = points[2 * e] - ax, dy = points[2 * e + 1] - ay;
    final len2 = dx * dx + dy * dy;
    var maxD = 0.0;
    var idx = -1;
    for (var i = s + 1; i < e; i++) {
      final px = points[2 * i] - ax, py = points[2 * i + 1] - ay;
      final t = len2 == 0 ? 0.0 : ((px * dx + py * dy) / len2).clamp(0.0, 1.0);
      final ex = px - t * dx, ey = py - t * dy;
      final d = ex * ex + ey * ey;
      if (d > maxD) {
        maxD = d;
        idx = i;
      }
    }
    if (idx >= 0 && maxD > tol2) {
      keep[idx] = true;
      stack
        ..add((s, idx))
        ..add((idx, e));
    }
  }
  var m = 0;
  for (final k in keep) {
    if (k) m++;
  }
  if (m == n) return (points: points, pressures: pressures);
  final out = Float32List(m * 2);
  final hasQ = pressures != null && pressures.length == n;
  final q = hasQ ? Float32List(m) : null;
  var j = 0;
  for (var i = 0; i < n; i++) {
    if (!keep[i]) continue;
    out[2 * j] = points[2 * i];
    out[2 * j + 1] = points[2 * i + 1];
    if (q != null) q[j] = pressures![i];
    j++;
  }
  return (points: out, pressures: hasQ ? q : pressures);
}

class _Writer {
  Uint8List _buf = Uint8List(256);
  int _len = 0;
  final _scratch = ByteData(8);

  void _ensure(int extra) {
    if (_len + extra <= _buf.length) return;
    var size = _buf.length * 2;
    while (size < _len + extra) {
      size *= 2;
    }
    _buf = Uint8List(size)..setRange(0, _len, _buf);
  }

  void byte(int b) {
    _ensure(1);
    _buf[_len++] = b & 0xFF;
  }

  void varuint(int v) {
    _ensure(10);
    // Bit işlemi değil bölme: web'de bit işlemleri 32 bit.
    while (v >= 0x80) {
      _buf[_len++] = (v % 128) | 0x80;
      v ~/= 128;
    }
    _buf[_len++] = v;
  }

  // Web'de 64 bit kaydırma yok; zigzag'ı işaretle yaz (aynı sonuç).
  void zigzag(int v) => varuint(v >= 0 ? v * 2 : -v * 2 - 1);

  void _bytes(int count) {
    _ensure(count);
    for (var i = 0; i < count; i++) {
      _buf[_len++] = _scratch.getUint8(i);
    }
  }

  void u32(int v) {
    _scratch.setUint32(0, v, Endian.little);
    _bytes(4);
  }

  void f32(double v) {
    _scratch.setFloat32(0, v, Endian.little);
    _bytes(4);
  }

  void f64(double v) {
    _scratch.setFloat64(0, v, Endian.little);
    _bytes(8);
  }

  Uint8List take() => Uint8List.sublistView(_buf, 0, _len);
}

class _Reader {
  _Reader(this._b) : _data = ByteData.sublistView(_b);
  final Uint8List _b;
  final ByteData _data;
  int _pos = 0;

  void _need(int n) {
    if (_pos + n > _b.length) {
      throw const FormatException('mürekkep paketi kısa');
    }
  }

  int byte() {
    _need(1);
    return _b[_pos++];
  }

  int varuint() {
    var result = 0;
    var mul = 1;
    for (var i = 0; i < 8; i++) {
      final b = byte();
      result += (b & 0x7F) * mul;
      if (b < 0x80) return result;
      mul *= 128;
    }
    throw const FormatException('varuint bozuk');
  }

  int zigzag() {
    final v = varuint();
    return v.isEven ? v ~/ 2 : -((v + 1) ~/ 2);
  }

  int u32() {
    _need(4);
    final v = _data.getUint32(_pos, Endian.little);
    _pos += 4;
    return v;
  }

  double f32() {
    _need(4);
    final v = _data.getFloat32(_pos, Endian.little);
    _pos += 4;
    return v;
  }

  double f64() {
    _need(8);
    final v = _data.getFloat64(_pos, Endian.little);
    _pos += 8;
    return v;
  }
}
