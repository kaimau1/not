import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';

/// Hızlı giriş ayrıştırıcısı (kullanıcı isteği 2026-11-15): dağınık yazı →
/// maddeler, AI'sız.
void main() {
  final lex = buildQuickLexicon(locale: 'tr', grocery: true);
  QuickParser parser({SpellMemory? spell, QuickEntryMemory? memory}) =>
      buildQuickParser(
        lex,
        spell: spell ?? SpellMemory(),
        memory: memory ?? const QuickEntryMemory(),
      );
  List<String> all(String text) => [
    for (final i in parser().parse(text, flush: true).items) i.text,
  ];

  test('sözlük geniş', () {
    expect(lex.length, greaterThan(900));
  });

  test('kullanıcının örneği: boşluk, virgül, yapışık ve bozuk yazım', () {
    expect(all('muz elma,armut çilekkivi un yunurta'), [
      'Muz',
      'Elma',
      'Armut',
      'Çilek',
      'Kivi',
      'Un',
      'Yumurta',
    ]);
  });

  test('Türkçe harfsiz yazım sözlükteki hâline oturur', () {
    expect(all('sut yogurt cilek seker'), ['Süt', 'Yoğurt', 'Çilek', 'Şeker']);
  });

  test('çok kelimeli madde tek madde', () {
    expect(all('diş macunu tavuk göğsü çöp torbası'), [
      'Diş macunu',
      'Tavuk göğsü',
      'Çöp torbası',
    ]);
  });

  test('sözlükte olmayan ardışık kelimeler virgüle kadar tek madde', () {
    expect(all('ajvar sosu, muz'), ['Ajvar sosu', 'Muz']);
    expect(all('süt zımbırtı elma'), ['Süt', 'Zımbırtı', 'Elma']);
  });

  test('miktar maddeye yapışır', () {
    expect(all('2 süt'), ['Süt (2)']);
    expect(all('3 kg domates'), ['Domates (3 kg)']);
    expect(all('domates 3 kg, süt'), ['Domates (3 kg)', 'Süt']);
    expect(all('2kg patates 500gr kıyma'), ['Patates (2 kg)', 'Kıyma (500 g)']);
    expect(all('iki ekmek yarım kilo peynir'), ['Ekmek (2)', 'Peynir (½ kg)']);
    expect(all('1,5 lt süt'), ['Süt (1,5 lt)']);
    expect(all('bir ekmek'), ['Ekmek']);
    expect(all('süt 2 ekmek'), ['Süt', 'Ekmek (2)']);
  });

  test('dolgu kelimeleri atılır (konuşma)', () {
    expect(all('süt ve yumurta bir de ekmek'), ['Süt', 'Yumurta', 'Ekmek']);
  });

  test('niteleyici sonraki maddeye yapışır', () {
    expect(all('yağsız süt organik yumurta'), [
      'Yağsız süt',
      'Organik yumurta',
    ]);
  });

  test('kısa kelimede yakın eşleşme yok; belirsizde karar yok', () {
    expect(all('bak'), ['Bak']);
    final small = QuickLexicon()
      ..add('Kola')
      ..add('Kova');
    final p = QuickParser(small);
    expect(
      [for (final i in p.parse('kolaa kova', flush: true).items) i.text],
      ['Kola', 'Kova'],
    );
    // "kola" ve "kova"ya eşit uzak: dokunma.
    expect(
      [for (final i in p.parse('koya', flush: true).items) i.text],
      ['Koya'],
    );
  });

  group('canlı kip', () {
    QuickParse live(String text, {bool idle = false}) =>
        parser().parse(text, idle: idle);

    test('yazılmakta olan kelime alanda kalır', () {
      final r = live('muz elm');
      expect([for (final i in r.items) i.text], ['Muz']);
      expect(r.rest, 'elm');
    });

    test('tamamlanan kelime hemen madde olur', () {
      final r = live('muz armut ');
      expect([for (final i in r.items) i.text], ['Muz', 'Armut']);
      expect(r.rest, '');
    });

    test('öbek başı devamını bekler; durunca eklenir', () {
      var r = live('tavuk ');
      expect(r.items, isEmpty);
      expect(r.rest, 'tavuk ');
      r = live('tavuk gö');
      expect(r.items, isEmpty);
      r = live('tavuk göğsü ');
      expect([for (final i in r.items) i.text], ['Tavuk göğsü']);
      r = live('tavuk muz ');
      expect([for (final i in r.items) i.text], ['Tavuk', 'Muz']);
      r = live('tavuk ', idle: true);
      expect([for (final i in r.items) i.text], ['Tavuk']);
      expect(r.rest, '');
    });

    test('bilinmeyen öbek virgülü ya da bilinen kelimeyi bekler', () {
      var r = live('fıstıklı ezme ');
      expect(r.items, isEmpty);
      expect(r.rest, 'fıstıklı ezme ');
      r = live('fıstıklı ezme, ');
      expect([for (final i in r.items) i.text], ['Fıstıklı ezme']);
      expect(r.rest.trim(), '');
      r = live('fıstıklı ezme muz ');
      expect([for (final i in r.items) i.text], ['Fıstıklı ezme', 'Muz']);
    });

    test('miktar maddesini bekler; sonda kalırsa çağırana döner', () {
      var r = live('2 ');
      expect(r.items, isEmpty);
      expect(r.rest, '2 ');
      r = live('2 süt ', idle: true);
      expect([for (final i in r.items) i.text], ['Süt (2)']);
      final end = parser().parse('3 kg', flush: true);
      expect(end.items, isEmpty);
      expect(end.trailingQty, '3 kg');
    });
  });

  group('yazım hafızası bağı', () {
    test('öğretilen düzeltme uygulanır', () {
      final spell = SpellMemory()..addManualFix('mrl', 'marul');
      final r = parser(spell: spell).parse('mrl', flush: true);
      expect(r.items.single.text, 'Marul');
      expect(r.items.single.how, QuickHow.learned);
    });

    test('kullanıcının kendi kelimesi düzeltilmez', () {
      // "kivit" → Kivi'ye bir harf uzak; kullanıcı üç kez yazdıysa kendi
      // kelimesidir.
      expect(all('kivit'), ['Kivi']);
      final spell = SpellMemory()..addWord('kivit', 3);
      final r = parser(spell: spell).parse('kivit', flush: true);
      expect(r.items.single.text, 'Kivit');
    });

    test('geri alınan düzeltme bir daha uygulanmaz', () {
      final memory = const QuickEntryMemory().rejecting('kivit', 'Kivi');
      final r = parser(memory: memory).parse('kivit', flush: true);
      expect(r.items.single.text, 'Kivit');
    });

    test('kabul edilen düzeltme yazım hafızasına gözlem olur', () {
      final spell = SpellMemory();
      final items = parser(spell: spell).parse('yunurta', flush: true).items;
      teachSpellFromQuickItems(items, spell: spell);
      teachSpellFromQuickItems(items, spell: spell);
      expect(spell.learned('yunurta'), 'yumurta');
    });
  });

  group('hafıza', () {
    test('sık eklenenler sayıya göre; kayıt gidiş-dönüş', () {
      var m = const QuickEntryMemory();
      m = m.recorded('b:shopping', ['Süt', 'Ekmek (2)', 'Ajvar sosu']);
      m = m.recorded('b:shopping', ['Süt (2)', 'Ekmek']);
      m = m.recorded('b:shopping', ['Süt']);
      expect(m.top('b:shopping', count: 2), ['Süt', 'Ekmek']);
      final back = QuickEntryMemory.decode(m.encode());
      expect(back.top('b:shopping'), m.top('b:shopping'));
      expect(QuickEntryMemory.decode('bozuk').kinds, isEmpty);
    });

    test('eklenen yeni madde sonraki sefer tanınır', () {
      final m = const QuickEntryMemory().recorded('b:shopping', ['Ajvar sosu']);
      final l = buildQuickLexicon(
        locale: 'tr',
        grocery: true,
        learned: m.all('b:shopping'),
      );
      final r = QuickParser(l).parse('ajvar sosu muz ');
      expect([for (final i in r.items) i.text], ['Ajvar sosu', 'Muz']);
    });
  });

  test('reyon sırası: manav → kahvaltılık → temizlik, bilinmeyen sonda', () {
    final items = parser().parse('deterjan ajvar, süt muz', flush: true).items;
    final sorted = quickSortByGroup(items, (i) => i.group);
    expect(
      [for (final i in sorted) i.text],
      ['Muz', 'Süt', 'Deterjan', 'Ajvar'],
    );
  });

  test('cümleli kip: yalnız kesin ayırıcı böler', () {
    final p = QuickParser(QuickLexicon(), phrasesOnly: true);
    final r = p.parse('faturayı öde, annemi ara', flush: true);
    expect([for (final i in r.items) i.text], ['Faturayı öde', 'Annemi ara']);
    expect(p.parse('faturayı öde, annemi').rest, 'annemi');
  });

  // Kullanıcı bulgusu 2026-11-28: "tavuk göğsü" kısa duraklamada iki madde.
  group('tamlama başı (izafet) ve konuşma bölütleri', () {
    final lex = buildQuickLexicon(locale: 'tr', grocery: true);
    final p = buildQuickParser(lex, spell: SpellMemory());
    List<String> parse(String s) => [
      for (final i in p.parse(quickJoinSpeechSegments(s, lex), flush: true)
          .items)
        i.text,
    ];
    test('bölüt sınırı öbeği bölmez, iki maddeyi ayırmaya devam eder', () {
      expect(parse('peynir tavuk\ngöğsü'), ['Peynir', 'Tavuk göğsü']);
      expect(parse('domates\nsalçası'), ['Domates salçası']);
      expect(parse('süt\nekmek'), ['Süt', 'Ekmek']);
    });
    test('bilinmeyen tamlama yakın eşleşmeye düşmez', () {
      expect(parse('kuzu kolu ekmek'), ['Kuzu kolu', 'Ekmek']);
    });
    test('kökü ı/i ile biten bilinmeyen kelime yapışmaz', () {
      expect(parse('süt zımbırtı, elma'), ['Süt', 'Zımbırtı', 'Elma']);
      expect(parse('ekmek hepsi'), isNot(contains('Ekmek hepsi')));
    });
    test('quickLooksPossessive', () {
      for (final w in ['göğsü', 'salçası', 'kolisi', 'suyu', 'eti']) {
        expect(quickLooksPossessive(w), isTrue, reason: w);
      }
      for (final w in ['zımbırtı', 'kivi', 'hepsi', 'pepsi', 'elma']) {
        expect(quickLooksPossessive(w), isFalse, reason: w);
      }
    });
  });
}
