import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_engine.dart';
import 'package:notlar/core/utils/spell_learn.dart';

/// **YAZIM v3 Y-0 ÖLÇÜM SETİ** (17K §3.3). İki sayı:
/// * YANLIŞ DÜZELTME: doğru kelimelerden (test/spell_corpus/dogru.txt)
///   kaçına dokunuldu — hedef %0,5'in altı; mandal yalnız DÜŞER.
/// * YAKALAMA: yanlış → doğru çiftlerinden (yanlis.tsv) kaçı tam doğruya
///   çevrildi; mandal yalnız ARTAR.
/// Bellek boş (yalnız yerleşik sözlük): kişisel sözlük ölçümü kaydırmasın.
/// Mandalı gevşetmek yasak; iyileşince yeni sayıyı buraya yaz.
const _mandalYanlis = 0;
const _mandalYakalama = 216;

List<String> _lines(String path) => [
  for (final l in File(path).readAsLinesSync())
    if (l.trim().isNotEmpty && !l.startsWith('#')) l.trim(),
];

/// Editördeki gibi: kelime sınırında yalnız SON harf dizisi karara gider
/// ("İstanbul'dan" → "dan"; bkz. `AutoSpell._lastWord`).
String _lastRun(String token) {
  final m = RegExp(r'\p{L}+$', unicode: true).firstMatch(token);
  return m?.group(0) ?? '';
}

SpellDecision _decide(String w) =>
    SpellEngine.decide(SpellInput(word: w, memory: SpellMemory()));

void main() {
  final correct = _lines('test/spell_corpus/dogru.txt');
  final pairs = [
    for (final l in _lines('test/spell_corpus/yanlis.tsv')) l.split('\t'),
  ];

  test('ölçüm setinin boyu', () {
    expect(correct.length, 500);
    expect(correct.toSet().length, 500);
    expect(pairs.length, 300);
    expect(pairs.every((p) => p.length == 3), isTrue);
  });

  test('Y-1 kabul: 500 doğrunun hepsi bilinir (ek çözücü)', () {
    final m = SpellMemory();
    final unknown = [
      for (final w in correct)
        if (!m.knownToken(w)) w,
    ];
    expect(unknown, isEmpty);
  });

  test('yanlış düzeltme oranı (mandal yalnız düşer)', () {
    final touched = <String>[];
    for (final w in correct) {
      final d = _decide(_lastRun(w));
      if (!d.isNone) touched.add('$w → ${d.to}');
    }
    final rate = touched.length / correct.length * 100;
    // ignore: avoid_print
    print(
      'YANLIŞ DÜZELTME: ${touched.length}/${correct.length} '
      '(%${rate.toStringAsFixed(2)}) $touched',
    );
    expect(
      touched.length,
      lessThanOrEqualTo(_mandalYanlis),
      reason: touched.join(', '),
    );
    expect(rate, lessThan(0.5), reason: 'hedef %0,5 altı');
  });

  test('Y-1 ek çözücü aşırı kabul bekçisi', () {
    final m = SpellMemory();
    // Kurallı ama yazım hatası: bitişik ek, yanlış yumuşama, daralmayan -yor.
    for (final w in [
      'yinede',
      'hemde',
      'iyiki',
      'geldimi',
      'bittimi',
      'arayor',
      'icin',
      'ekmegi',
      'temizligi',
      'tamma',
      'yapıcam',
      'kalin',
    ]) {
      expect(m.known(w), isFalse, reason: w);
    }
    for (final w in [
      'kalemlerimizden',
      'gidiyorduk',
      'söyleyemedim',
      'kitabımdaki',
      'ağzını',
      'rengini',
      'hakkımızda',
      'diyecekler',
      'kaydedilemedi',
    ]) {
      expect(m.known(w), isTrue, reason: w);
    }
  });

  test('yakalama oranı (mandal yalnız artar)', () {
    final byKind = <String, List<int>>{};
    var caught = 0;
    final missed = <String>[];
    for (final p in pairs) {
      final d = _decide(p[0]);
      final ok = d.to != null && trLower(d.to!) == p[1];
      final k = byKind.putIfAbsent(p[2], () => [0, 0]);
      k[1]++;
      if (ok) {
        caught++;
        k[0]++;
      } else {
        missed.add('${p[0]}→${d.to ?? '-'}');
      }
    }
    final rate = caught / pairs.length * 100;
    // ignore: avoid_print
    print(
      'YAKALAMA: $caught/${pairs.length} (%${rate.toStringAsFixed(1)}) '
      '${byKind.map((k, v) => MapEntry(k, '${v[0]}/${v[1]}'))}',
    );
    // ignore: avoid_print
    print('KAÇAN: $missed');
    expect(caught, greaterThanOrEqualTo(_mandalYakalama));
  });
}
