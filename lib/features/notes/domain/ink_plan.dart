import 'dart:typed_data';

import 'attachment.dart';
import 'ink_pack.dart';

/// **MÜREKKEP PLANLAYICI** (F61.3): bir yüzeyin (ek ya da sayfa mürekkebi)
/// çizgilerini bantlı belgelere böler; kayıtta yalnız DEĞİŞEN bant yazılır.
///
/// Belge kimliği `<yüzey>~<sayfa>~<bant>[b|c|…]`. Bant = ilk noktanın y'si /
/// [kInkBandHeight] (PDF/görsel gibi y ≤ 1 yüzeyde hep 0). Çizim sırası
/// bantlar arasında `z` ile korunur: yüklenen çizgi z'sini taşır, yeni çizgi
/// komşularının arasına düşer.
const kInkBandHeight = 1.0;

/// Tek belgenin paket sınırı; aşan bant z sırasıyla parçalara bölünür.
const kInkDocMaxBytes = 256 * 1024;

/// Mürekkep alt koleksiyonu: `notes/{id}/ink/{docId}`.
const kInkCollection = 'ink';

/// Sayfa mürekkebinin yüzey adı (eklerde ek kimliği kullanılır).
const kPageInkSurface = '_page_ink';

/// Çizgi örneği → z (çizim sırası). Örnek kimliğiyle tutulur: düzenleme yeni
/// örnek üretir, eski örnekler z'lerini korur.
class InkOrder {
  final _z = Expando<double>();

  double? operator [](InkStroke s) => _z[s];
  void operator []=(InkStroke s, double z) => _z[s] = z;

  /// Listedeki her çizgiye kesin artan bir z verir (ve hatırlar). Bilinen ve
  /// sırası bozulmamış çizgi z'sini korur; gerisi komşularının arasına
  /// eşit aralıkla düşer. ponytail: açgözlü artan alt dizi — baştaki tek
  /// büyük z gerisini "yeni" sayar (yalnız fazladan yazım, veri kaybı yok).
  List<double> assign(List<InkStroke> strokes) {
    final n = strokes.length;
    final z = List<double?>.filled(n, null);
    double? last;
    for (var i = 0; i < n; i++) {
      final k = _z[strokes[i]];
      if (k != null && k.isFinite && (last == null || k > last)) {
        z[i] = k;
        last = k;
      }
    }
    var i = 0;
    while (i < n) {
      if (z[i] != null) {
        i++;
        continue;
      }
      var j = i;
      while (j < n && z[j] == null) {
        j++;
      }
      final lo = i > 0 ? z[i - 1] : null;
      final hi = j < n ? z[j] : null;
      final m = j - i;
      for (var k = 0; k < m; k++) {
        z[i + k] = switch ((lo, hi)) {
          (final double a, final double b) => a + (b - a) * (k + 1) / (m + 1),
          (final double a, null) => a + k + 1,
          (null, final double b) => b - (m - k),
          (null, null) => k.toDouble(),
        };
      }
      i = j;
    }
    final out = List<double>.generate(n, (k) => z[k]!);
    // Kayan nokta aralığı tükendiyse (aynı yere çok ekleme) baştan numarala.
    for (var k = 1; k < n; k++) {
      if (!(out[k] > out[k - 1])) {
        for (var t = 0; t < n; t++) {
          out[t] = t.toDouble();
        }
        break;
      }
    }
    for (var k = 0; k < n; k++) {
      _z[strokes[k]] = out[k];
    }
    return out;
  }
}

int _band(InkStroke s) {
  if (s.points.length < 2) return 0;
  final b = (s.points[1] / kInkBandHeight).floor();
  return b < 0 ? 0 : b;
}

/// docId → paket baytları.
Map<String, Uint8List> planInkDocs({
  required String surface,
  required List<InkStroke> strokes,
  required InkOrder order,
}) {
  final z = order.assign(strokes);
  final groups = <String, List<int>>{};
  for (var i = 0; i < strokes.length; i++) {
    final s = strokes[i];
    (groups['$surface~${s.page}~${_band(s)}'] ??= []).add(i);
  }
  final out = <String, Uint8List>{};
  for (final e in groups.entries) {
    final idx = e.value;
    final pack = encodeInkPack(
      [for (final i in idx) strokes[i]],
      z: [for (final i in idx) z[i]],
    );
    if (pack.length <= kInkDocMaxBytes) {
      out[e.key] = pack;
      continue;
    }
    // Çok yoğun bant: z sırasıyla açgözlü parçalar (sona ekleme yalnız son
    // parçayı değiştirir). Ek: '', 'b', 'c', …
    var part = 0;
    var chunk = <int>[];
    var size = 4;
    void flush() {
      if (chunk.isEmpty) return;
      final suffix = part == 0 ? '' : String.fromCharCode(0x61 + part);
      out['${e.key}$suffix'] = encodeInkPack(
        [for (final i in chunk) strokes[i]],
        z: [for (final i in chunk) z[i]],
      );
      part++;
      chunk = <int>[];
      size = 4;
    }

    for (final i in idx) {
      final one = encodeInkPack([strokes[i]], z: [z[i]]).length - 4;
      if (chunk.isNotEmpty && size + one + 4 > kInkDocMaxBytes) flush();
      chunk.add(i);
      size += one;
    }
    flush();
  }
  return out;
}

/// Çözülmüş paketlerden düz liste: z'ye göre kararlı sıralı; z'ler
/// [order]a işlenir (sonraki planda korunsun).
List<InkStroke> mergeDecodedInk(
  Iterable<({List<InkStroke> strokes, List<double> z})> packs,
  InkOrder order,
) {
  final all = <(InkStroke, double, int)>[];
  for (final p in packs) {
    for (var i = 0; i < p.strokes.length; i++) {
      all.add((p.strokes[i], p.z[i], all.length));
    }
  }
  all.sort((a, b) {
    final c = a.$2.compareTo(b.$2);
    return c != 0 ? c : a.$3.compareTo(b.$3);
  });
  final out = <InkStroke>[];
  for (final (s, z, _) in all) {
    order[s] = z;
    out.add(s);
  }
  return out;
}

/// Bantlardan düz listeye. Bozuk paket [FormatException] atar.
List<InkStroke> mergeInkDocs(Iterable<Uint8List> packs, InkOrder order) =>
    mergeDecodedInk(packs.map(decodeInkPack), order);
