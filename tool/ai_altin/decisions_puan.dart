// DA-E0 (docs/plan_decisions_api.md §4.7): Decisions altın seti puanlaması.
// SAF (uygulama kodu import etmez) → bekçi test anahtarsız koşar.
// Ölçütler: doğruluk, kapsam@%95 kesinlik, ECE (10 kutu), K9 doğru-ret /
// yanlış-ret, P50/P95 gecikme.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Bir sorunun sonucu: beklenen sınıf, modelin seçtiği sınıf ve güveni.
class KararOrnek {
  const KararOrnek({
    required this.id,
    required this.beklenen,
    required this.tahmin,
    required this.guven,
  });

  final String id;
  final String beklenen;

  /// null = yanıt yok (geri düşüş).
  final String? tahmin;
  final double guven;

  bool get dogru => tahmin == beklenen;
}

/// Set dosyası (`tool/ai_altin/decisions/*.json`).
Map<String, dynamic> kararSetiOku(String yol) =>
    jsonDecode(File(yol).readAsStringSync()) as Map<String, dynamic>;

List<String> kararSetleri([String klasor = 'tool/ai_altin/decisions']) => [
  for (final f in Directory(klasor).listSync())
    if (f.path.endsWith('.json')) f.path,
]..sort();

double dogruluk(List<KararOrnek> o) =>
    o.isEmpty ? 0 : o.where((e) => e.dogru).length / o.length;

/// Güven eşiği τ taranır: τ üstündeki kararların kesinliği ≥ [kesinlik]
/// olan EN GENİŞ kapsam (örneklerin yüzde kaçında karar verilebilir) ve o τ.
({double kapsam, double esik}) kapsamAt(
  List<KararOrnek> o, {
  double kesinlik = 0.95,
}) {
  final yanitli = [
    for (final e in o)
      if (e.tahmin != null) e,
  ]..sort((a, b) => b.guven.compareTo(a.guven));
  var best = (kapsam: 0.0, esik: 1.0);
  var dogru = 0;
  for (var i = 0; i < yanitli.length; i++) {
    if (yanitli[i].dogru) dogru++;
    // Eşit güvenler birlikte alınır.
    if (i + 1 < yanitli.length && yanitli[i + 1].guven == yanitli[i].guven) {
      continue;
    }
    if (dogru / (i + 1) >= kesinlik) {
      best = (kapsam: (i + 1) / o.length, esik: yanitli[i].guven);
    }
  }
  return best;
}

/// Beklenen kalibrasyon hatası: |doğruluk − ortalama güven| kutu ağırlıklı.
double ece(List<KararOrnek> o, {int kutu = 10}) {
  final yanitli = [
    for (final e in o)
      if (e.tahmin != null) e,
  ];
  if (yanitli.isEmpty) return 0;
  var toplam = 0.0;
  for (var k = 0; k < kutu; k++) {
    final lo = k / kutu, hi = (k + 1) / kutu;
    final b = [
      for (final e in yanitli)
        if (e.guven > lo && e.guven <= hi || (k == 0 && e.guven == 0)) e,
    ];
    if (b.isEmpty) continue;
    final acc = b.where((e) => e.dogru).length / b.length;
    final conf = b.map((e) => e.guven).reduce((a, c) => a + c) / b.length;
    toplam += b.length / yanitli.length * (acc - conf).abs();
  }
  return toplam;
}

/// K9 doğrulama kapısı: [ret] = uygulama eşiğinde reddedilen örnekler.
/// doğru-ret = kötülerin reddedilen oranı (≥ %80 olmalı); yanlış-ret =
/// iyilerin reddedilen oranı (≤ %2 olmalı).
({double dogruRet, double yanlisRet}) retOranlari(
  Map<String, bool> iyiMi,
  Set<String> ret,
) {
  final kotu = [
    for (final e in iyiMi.entries)
      if (!e.value) e.key,
  ];
  final iyi = [
    for (final e in iyiMi.entries)
      if (e.value) e.key,
  ];
  double oran(List<String> l) =>
      l.isEmpty ? 0 : l.where(ret.contains).length / l.length;
  return (dogruRet: oran(kotu), yanlisRet: oran(iyi));
}

int yuzdelik(List<int> ms, double q) {
  if (ms.isEmpty) return 0;
  final s = [...ms]..sort();
  return s[math
      .min(s.length - 1, (q * s.length).ceil() - 1)
      .clamp(0, s.length - 1)];
}
