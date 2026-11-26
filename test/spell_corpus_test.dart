import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_engine.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/core/utils/tr_lexicon.dart';

/// **YAZIM v3 Y-0 ÖLÇÜM SETİ** (17K §3.3). İki sayı:
/// * YANLIŞ DÜZELTME: doğru kelimelerden (test/spell_corpus/dogru.txt)
///   kaçına dokunuldu — hedef %0,5'in altı; mandal yalnız DÜŞER.
/// * YAKALAMA: yanlış → doğru çiftlerinden (yanlis.tsv) kaçı tam doğruya
///   çevrildi; mandal yalnız ARTAR.
/// Bellek boş (yalnız yerleşik sözlük): kişisel sözlük ölçümü kaydırmasın.
/// Mandalı gevşetmek yasak; iyileşince yeni sayıyı buraya yaz.
const _mandalYanlis = 0;
const _mandalYakalama = 273;

/// Y-4 altı çizili denetim: doğru kelimeden kaçının altı çizilir (ipucu —
/// bağlama bağlı "bende" gibi — ayrı sayılır) ve yanlıştan kaçında doğru
/// yazım ÖNERİLER arasında. İlki yalnız düşer, ikincisi yalnız artar.
const _mandalCizgi = 0;
const _mandalIpucu = 8;
const _mandalOneri = 277;

/// Düzyazı (test/spell_corpus/duzyazi.txt: kılavuz + sürüm notlarının
/// 2026-11-20 kopyası, doğru yazılmış ~9 bin kelime): altı çizilen kelime
/// sayısı. Taban 82 (eksik kökler: "gerçek" → "gerek", "şablon" → "salon",
/// "kısım" → "kışım"); kök eklenip harfsiz yazım Türkçe harfli kelimede
/// kapatılınca 3 ("yunurta" bilerek yazılmış örnek). Yalnız düşer.
const _mandalDuzyazi = 3;

/// BÜYÜK SÖZLÜK YÜKLÜ (Zemberek kökleri, 2026-11-26) ölçümleri — uygulamada
/// sözlük editör açılınca yüklenir. Yakalama sözlüksüzden 2 düşük: "kalen"
/// ve "salaya" geçerli kelime (kale-n, sala-ya), bulanık düzeltme sözlükte
/// geçerli kelimeye bilerek yapılmaz (karşılığında "böbrek → börek" gibi
/// ~100 yanlış düzeltme gitti; bkz. sozluk_gecerli.txt). Yalnız artar/düşer.
const _lexMandalYakalama = 271;
const _lexMandalYanlis = 0;
const _lexMandalCizgi = 0;
const _lexMandalOneri = 275;
const _lexMandalDuzyazi = 1;
const _lexMandalGecerli = 0;

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

  test('Y-4 altı çizili denetim: yanlış işaret ve öneri isabeti', () {
    final m = SpellMemory();
    final flagged = <String>[];
    final hinted = <String>[];
    for (final w in correct) {
      final t = SpellEngine.tokens(w);
      for (final k in t) {
        final s = SpellEngine.suggestions(k.word, m);
        if (s == null) continue;
        (s.hint ? hinted : flagged).add('$w → ${s.list.first}');
      }
    }
    var inList = 0;
    var underlined = 0;
    for (final p in pairs) {
      final s = SpellEngine.suggestions(trLower(p[0]), m);
      if (s == null) continue;
      underlined++;
      if (s.list.map(trLower).contains(p[1])) inList++;
    }
    // ignore: avoid_print
    print(
      'ALTI ÇİZİLİ: doğruda ${flagged.length}/${correct.length} '
      '(+${hinted.length} ipucu) $flagged $hinted · yanlışta çizilen '
      '$underlined/${pairs.length}, doğru öneride $inList/${pairs.length}',
    );
    expect(flagged.length, lessThanOrEqualTo(_mandalCizgi));
    expect(hinted.length, lessThanOrEqualTo(_mandalIpucu));
    expect(inList, greaterThanOrEqualTo(_mandalOneri));
  });

  test('Y-4 düzyazıda yanlış çizgi (mandal yalnız düşer)', () {
    final m = SpellMemory();
    final text = File('test/spell_corpus/duzyazi.txt').readAsStringSync();
    var words = 0;
    final flagged = <String>[];
    for (final para in text.split('\n')) {
      for (final t in SpellEngine.tokens(para)) {
        words++;
        final s = SpellEngine.suggestions(t.word, m);
        if (s != null && !s.hint) flagged.add('${t.word}→${s.list.first}');
      }
    }
    // ignore: avoid_print
    print('DÜZYAZI: ${flagged.length}/$words çizili $flagged');
    expect(flagged.length, lessThanOrEqualTo(_mandalDuzyazi));
  });

  group('büyük sözlük yüklü', () {
    setUpAll(() {
      TrLexicon.install(
        TrLexicon.parse(File('assets/spell/tr_lexicon.txt').readAsStringSync()),
      );
    });
    tearDownAll(() => TrLexicon.install(null));

    test('sözlük sıralı, tekrarsız, bayraklı', () {
      final lex = TrLexicon.instance!;
      expect(lex.length, greaterThan(25000));
      for (var i = 1; i < lex.length; i++) {
        expect(
          lex.wordAt(i - 1).compareTo(lex.wordAt(i)),
          lessThan(0),
          reason: '${lex.wordAt(i - 1)} / ${lex.wordAt(i)}',
        );
      }
      expect(lex.noun('kitap'), isTrue);
      expect(lex.verb('gel'), isTrue);
      expect(lex.doubling('hak'), isTrue);
      expect(lex.front('saat'), isTrue);
      expect(lex.dropsVowel('ağız'), isTrue);
      expect(lex.noun('yine'), isFalse, reason: 'zarf ek almaz');
      expect(lex.has('yine'), isTrue);
      expect(lex.has('herşey'), isFalse, reason: 'TDK dışı yazım yok');
    });

    test('kabul ve aşırı kabul bekçisi', () {
      final m = SpellMemory();
      for (final w in correct) {
        expect(m.knownToken(w), isTrue, reason: w);
      }
      for (final w in [
        'böbrek',
        'şehit',
        'karısı',
        'tasarımını',
        'mantığı',
        'herhangi',
        'saatleri',
        'kitabı',
      ]) {
        expect(m.lexicalKnown(w), isTrue, reason: w);
      }
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
        'kalin',
        'kitapı',
        'adaledi',
        'saatı',
        'petnr',
        'nasılsn',
        'gelyorum',
      ]) {
        expect(m.lexicalKnown(w), isFalse, reason: w);
      }
    });

    test('geçerli kelimelere dokunulmaz (sözlüksüz motor bozuyordu)', () {
      final valid = _lines('test/spell_corpus/sozluk_gecerli.txt');
      expect(valid.length, greaterThanOrEqualTo(70));
      final touched = <String>[];
      for (final w in valid) {
        final d = _decide(w);
        if (!d.isNone) touched.add('$w → ${d.to}');
        final s = SpellEngine.suggestions(w, SpellMemory());
        if (s != null && !s.hint) touched.add('$w ~ ${s.list.first}');
      }
      expect(
        touched.length,
        lessThanOrEqualTo(_lexMandalGecerli),
        reason: touched.join(', '),
      );
    });

    test('doğrulara dokunma ve yakalama', () {
      final touched = <String>[];
      for (final w in correct) {
        final d = _decide(_lastRun(w));
        if (!d.isNone) touched.add('$w → ${d.to}');
      }
      expect(
        touched.length,
        lessThanOrEqualTo(_lexMandalYanlis),
        reason: touched.join(', '),
      );
      var caught = 0;
      final missed = <String>[];
      for (final p in pairs) {
        final d = _decide(p[0]);
        if (d.to != null && trLower(d.to!) == p[1]) {
          caught++;
        } else {
          missed.add('${p[0]}→${d.to ?? '-'}');
        }
      }
      // ignore: avoid_print
      print('SÖZLÜKLÜ YAKALAMA: $caught/${pairs.length} KAÇAN: $missed');
      expect(caught, greaterThanOrEqualTo(_lexMandalYakalama));
    });

    test('altı çizili denetim ve düzyazı', () {
      final m = SpellMemory();
      final flagged = <String>[];
      for (final w in correct) {
        for (final k in SpellEngine.tokens(w)) {
          final s = SpellEngine.suggestions(k.word, m);
          if (s != null && !s.hint) flagged.add('$w → ${s.list.first}');
        }
      }
      var inList = 0;
      for (final p in pairs) {
        final s = SpellEngine.suggestions(trLower(p[0]), m);
        if (s != null && s.list.map(trLower).contains(p[1])) inList++;
      }
      final text = File('test/spell_corpus/duzyazi.txt').readAsStringSync();
      final prose = <String>[];
      for (final para in text.split('\n')) {
        for (final t in SpellEngine.tokens(para)) {
          final s = SpellEngine.suggestions(t.word, m);
          if (s != null && !s.hint) prose.add('${t.word}→${s.list.first}');
        }
      }
      // ignore: avoid_print
      print(
        'SÖZLÜKLÜ ÇİZGİ: doğruda ${flagged.length}, öneride '
        '$inList/${pairs.length}, düzyazıda ${prose.length} $prose',
      );
      expect(flagged.length, lessThanOrEqualTo(_lexMandalCizgi));
      expect(inList, greaterThanOrEqualTo(_lexMandalOneri));
      expect(prose.length, lessThanOrEqualTo(_lexMandalDuzyazi));
    });
  });
}
