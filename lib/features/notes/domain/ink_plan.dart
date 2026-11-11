import 'dart:typed_data';

import 'attachment.dart';
import 'ink_pack.dart';
import 'note.dart' show kPageInkId;

/// **MÜREKKEP PLANLAYICI** (F61.3): bir yüzeyin (ek ya da sayfa mürekkebi)
/// çizgilerini bantlı belgelere böler; kayıtta yalnız DEĞİŞEN bant yazılır.
///
/// Belge kimliği `<yüzey>~<sayfa>~<bant>[b|c|…]` (yüzey: ek kimliği ya da
/// sayfa mürekkebi için [kPageInkId]). Bant = ilk noktanın y'si /
/// [kInkBandHeight] (PDF/görsel gibi y ≤ 1 yüzeyde hep 0). Çizim sırası
/// bantlar arasında `z` ile korunur: yüklenen çizgi z'sini taşır, yeni çizgi
/// komşularının arasına düşer.
const kInkBandHeight = 1.0;

/// Tek belgenin paket sınırı; aşan bant z sırasıyla parçalara bölünür.
const kInkDocMaxBytes = 256 * 1024;

/// Mürekkep alt koleksiyonu: `notes/{id}/ink/{docId}`.
const kInkCollection = 'ink';

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

/// Belge kimliğinden yüzey (`<yüzey>~<sayfa>~<bant>`).
String inkDocSurface(String docId) {
  final b = docId.lastIndexOf('~');
  final p = b <= 0 ? -1 : docId.lastIndexOf('~', b - 1);
  return p < 0 ? docId : docId.substring(0, p);
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// **OKUMA ÖNBELLEĞİ** (F61.5): bir notun `ink` koleksiyonu her geldiğinde
/// yalnız BAYTLARI değişen belge çözülür (tam karşılaştırma: çizgi
/// kıpırdayınca boy aynı kalabilir); değişmeyen yüzeyin listesi aynı örnek
/// döner (editör önbellekleri kimlikle çalışıyor).
class InkDocCache {
  final _docs =
      <String, (Uint8List, ({List<InkStroke> strokes, List<double> z}))>{};
  final _surfaces = <String, List<InkStroke>>{};

  /// docId → paket. Bozuk paket atlanır ve [onBad]a gider (çökme yok).
  Map<String, List<InkStroke>> apply(
    Map<String, Uint8List> docs,
    InkOrder order, {
    void Function(String docId, Object error)? onBad,
  }) {
    final changed = <String>{};
    for (final id in [..._docs.keys]) {
      if (!docs.containsKey(id)) {
        _docs.remove(id);
        changed.add(inkDocSurface(id));
      }
    }
    for (final e in docs.entries) {
      final old = _docs[e.key];
      if (old != null && _sameBytes(old.$1, e.value)) continue;
      changed.add(inkDocSurface(e.key));
      try {
        _docs[e.key] = (e.value, decodeInkPack(e.value));
      } on FormatException catch (err) {
        _docs.remove(e.key);
        onBad?.call(e.key, err);
      }
    }
    for (final surface in changed) {
      final packs = [
        for (final e in _docs.entries)
          if (inkDocSurface(e.key) == surface) e.value.$2,
      ];
      if (packs.isEmpty) {
        _surfaces.remove(surface);
      } else {
        _surfaces[surface] = mergeDecodedInk(packs, order);
      }
    }
    return Map.unmodifiable(_surfaces);
  }
}

/// v2 mürekkebini ana belge haritasına işler (yeni harita). `inkV: 2` olan
/// not `heavyRef` sayılır: mürekkebi gelene dek HAFİF kalır ve yazım
/// mürekkebe dokunmaz. [ink] null = henüz gelmedi. Aynı yüzeyde v1 dizisi
/// varsa v2 kazanır; v2 belgesi olmayan yüzey v1 değerini korur.
Map<String, dynamic> mergeInkV2(
  Map<String, dynamic> main,
  Map<String, List<InkStroke>>? ink,
) {
  if (main['inkV'] != 2) return main;
  final out = {...main, 'heavyRef': true};
  if (ink == null || ink.isEmpty) return out;
  final raw = main['attachments'];
  final list = raw is List ? raw : const [];
  final patched = <Object?>[];
  var hasPage = false;
  for (final a in list) {
    final strokes = a is Map ? ink[a['id']] : null;
    if (a is Map && a['id'] == kPageInkId) hasPage = true;
    patched.add(
      strokes == null
          ? a
          : {...Map<String, dynamic>.from(a as Map), 'ink': strokes},
    );
  }
  final page = ink[kPageInkId];
  if (!hasPage && page != null) {
    patched.add({'id': kPageInkId, 'kind': 'pageInk', 'ink': page});
  }
  out['attachments'] = patched;
  return out;
}
