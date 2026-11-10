import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notlar/core/utils/spell_engine.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/spell_learned_screen.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// Alanı klavye gibi sürer: tek karakter yazma, Backspace, aralık değiştirme.
class _Kb {
  _Kb() {
    AutoSpell.attach(c, () {});
  }

  final c = WrapTextController();
  String get t => c.logicalText;

  void type(String s) {
    for (final ch in s.split('')) {
      final caret = c.selection.isValid ? c.selection.baseOffset : t.length;
      final next = t.replaceRange(caret, caret, ch);
      c.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: caret + 1),
      );
    }
  }

  /// Tek adımda yapıştırma / dikte.
  void paste(String s) {
    final caret = c.selection.isValid ? c.selection.baseOffset : t.length;
    c.value = TextEditingValue(
      text: t.replaceRange(caret, caret, s),
      selection: TextSelection.collapsed(offset: caret + s.length),
    );
  }

  void backspace() {
    final caret = c.selection.baseOffset;
    c.value = TextEditingValue(
      text: t.replaceRange(caret - 1, caret, ''),
      selection: TextSelection.collapsed(offset: caret - 1),
    );
  }

  /// [from] kelimesini (ilk geçiş) tek adımda [to] yapar (klavye önerisi
  /// ya da kelimeye dokunup değiştirme); imleç sona döner.
  void replaceWord(String from, String to) {
    final i = t.indexOf(from);
    final next = t.replaceRange(i, i + from.length, to);
    c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: i + to.length),
    );
    end();
  }

  /// [word]ün sonuna imleç koyup [n] kez siler, [add] yazar, sona döner.
  void retype(String word, int n, String add) {
    final i = t.indexOf(word) + word.length;
    c.selection = TextSelection.collapsed(offset: i);
    for (var k = 0; k < n; k++) {
      backspace();
    }
    type(add);
    end();
  }

  void end() => c.selection = TextSelection.collapsed(offset: t.length);
}

SpellDecision _d(
  String w, {
  SpellMemory? m,
  bool title = false,
  bool rulesOnly = false,
  Set<String> keep = const {},
  List<String>? device,
}) => SpellEngine.decide(
  SpellInput(
    word: w,
    memory: m ?? SpellMemory(),
    title: title,
    rulesOnly: rulesOnly,
    noteKeep: keep,
    device: device,
  ),
);

void main() {
  late SpellMemory saved;
  late bool savedOn;
  late bool savedRules;
  setUp(() {
    saved = AutoSpell.memory;
    savedOn = AutoSpell.enabled.value;
    savedRules = AutoSpell.rulesOnly.value;
    AutoSpell.memory = SpellMemory();
    AutoSpell.enabled.value = true;
    AutoSpell.rulesOnly.value = false;
    AutoSpell.beginNote();
  });
  tearDown(() {
    AutoSpell.memory = saved;
    AutoSpell.enabled.value = savedOn;
    AutoSpell.rulesOnly.value = savedRules;
  });

  group('F70.0 ısrar', () {
    test(
      'otomatik düzeltmeyi sonradan değiştirince aynı kelime geri gelmez',
      () {
        final kb = _Kb();
        kb.type('bu kalen ');
        expect(kb.t, 'Bu kalem ');
        kb.type('aldım ');
        // Kullanıcı geri dönüp "kalem"i "kalin" yapar (bir kelime sonra).
        kb.replaceWord('kalem', 'kalin');
        kb.type('bir kalen ');
        expect(kb.t.endsWith('bir kalem '), isFalse, reason: kb.t);
      },
    );

    test('klavye önerisiyle değiştirilen düzeltme geri gelmez', () {
      final kb = _Kb();
      kb.type('bu kalen ');
      expect(kb.t, 'Bu kalem ');
      kb.replaceWord('kalem', 'kalin');
      kb.type('bir kalen ');
      expect(kb.t.endsWith('bir kalem '), isFalse, reason: kb.t);
    });
  });

  group('motor: KALANLAR örnekleri', () {
    test('C3 "herşey" kuralla ayrılır', () {
      expect(_d('herşey').to, 'her şey');
      expect(_d('herşey').reason, SpellReason.rule);
      expect(_d('Herşey').to, 'Her şey');
    });

    test('D1 "yaoçoılıyor" → "yapılıyor", "eksiknyapılıyor" bölünür', () {
      expect(_d('yaoçoılıyor').to, 'yapılıyor');
      expect(_d('eksiknyapılıyor').to, 'eksik yapılıyor');
      expect(_d('eksiknyapılıyor').reason, SpellReason.split);
    });

    test('F7 Türkçe ek: kök/uzantı ilişkisi düzeltilmez', () {
      expect(_d('kalemi').isNone, isTrue);
      expect(_d('kalemde').isNone, isTrue);
      expect(_d('notları').isNone, isTrue);
      final m = SpellMemory()..addWord('kalemi', 5);
      expect(SpellEngine.replacedWord('bu kalemi ', 'bu kalemde ', m), isNull);
      expect(SpellEngine.replacedWord('bu kalmei ', 'bu kalemi ', m), (
        from: 'kalmei',
        to: 'kalemi',
      ));
    });

    test('kısaltma, Çince ve kısa kelime değişmez', () {
      expect(_d('NATO').isNone, isTrue);
      expect(_d('我的').isNone, isTrue);
      expect(_d('ve').isNone, isTrue);
    });

    test('Çince: bulanık yok, öğretilen düzeltme uygulanır', () {
      final m = SpellMemory()
        ..learnFix('在见', '再见')
        ..learnFix('在见', '再见');
      expect(_d('在见', m: m).to, '再见');
    });

    test('İngilizce bulanık eşleşme', () {
      expect(looksEnglish('meeting'), isTrue);
      expect(looksEnglish('yapılıyor'), isFalse);
      expect(_d('meetinf').to, 'meeting');
    });

    test('notlardan sözlük: sık kelime bilinir ve aday olur', () {
      final m = SpellMemory()
        ..seed(seedCounts(['togg bakım togg servis togg']));
      expect(m.known('togg'), isTrue);
      expect(_d('togg', m: m).isNone, isTrue);
      expect(_d('tofg', m: m).to, 'togg');
    });

    test('cihaz önerisi: yalnız tek yakın aday', () {
      expect(_d('kalmel', device: ['kalem']).to, 'kalem');
      expect(_d('kalmel', device: ['kalem']).reason, SpellReason.device);
      expect(_d('kalem', device: ['Kalem']).isNone, isTrue);
      expect(_d('kalmel', device: ['masa']).isNone, isTrue);
      expect(_d('kalmel', device: ['kalem', 'kamel']).isNone, isTrue);
    });
  });

  group('motor: ilkeler', () {
    test('bilinen kelimeye dokunma', () {
      expect(_d('kalem').isNone, isTrue);
      expect(_d('eksik').isNone, isTrue);
    });

    test('3 kez görülmeden bilinen sayılmaz', () {
      final m = SpellMemory()
        ..addWord('kalen')
        ..addWord('kalen');
      expect(m.known('kalen'), isFalse);
      expect(_d('kalen', m: m).to, 'kalem');
      m.addWord('kalen');
      expect(m.known('kalen'), isTrue);
      expect(_d('kalen', m: m).isNone, isTrue);
    });

    test('emin değilsen dokunma: iki yakın aday varsa değiştirme', () {
      // "kalen": "kalem" (n↔m komşu) ile eşit yakın ikinci aday.
      final m = SpellMemory()..addWord('kaleb', 5);
      expect(_d('kalen', m: m).isNone, isTrue);
    });

    test('reddedilen çift bir daha uygulanmaz; notta dokunulmaz kelime', () {
      final m = SpellMemory()..rejectPair('kalen', 'kalem');
      expect(_d('kalen', m: m).isNone, isTrue);
      expect(_d('herşey', keep: {'herşey'}).isNone, isTrue);
      m.rejectPair('herşey', 'her şey');
      expect(_d('herşey', m: m).isNone, isTrue);
    });

    test('öğretilen düzeltme: iki kez ya da elle → uygulanır', () {
      final m = SpellMemory()..learnFix('togh', 'togg');
      expect(_d('togh', m: m).reason, isNot(SpellReason.learned));
      m.learnFix('togh', 'togg');
      expect(_d('togh', m: m).to, 'togg');
      expect(_d('togh', m: m).reason, SpellReason.learned);
      final m2 = SpellMemory()..addManualFix('yanlız', 'yalnızca');
      expect(_d('yanlız', m: m2).to, 'yalnızca');
    });

    test('yalnız kurallar kipi: bulanık/öğrenilmiş yok, tablo var', () {
      expect(_d('herşey', rulesOnly: true).to, 'her şey');
      expect(_d('yaoçoılıyor', rulesOnly: true).isNone, isTrue);
    });

    test('başlık kipi: bulanık yok, kural var', () {
      expect(_d('yaoçoılıyor', title: true).isNone, isTrue);
      expect(_d('herşey', title: true).to, 'her şey');
    });

    test('taninmaz düzeltme kapısı', () {
      expect(SpellEngine.changesTooMuch('yapıyrum', 'yapıyorum'), isFalse);
      expect(SpellEngine.changesTooMuch('toplantı', 'tıpkıydı'), isTrue);
    });

    test('klavye mesafesi', () {
      expect(keyCost('o', 'p'), lessThan(0.5));
      expect(keyCost('ı', 'i'), lessThan(0.5));
      expect(keyCost('a', 'p'), 1);
      expect(
        SpellEngine.distance('yaoçoılıyor', 'yapılıyor'),
        lessThanOrEqualTo(SpellEngine.limitFor(11)),
      );
      expect(
        SpellEngine.distance('kalem', 'kalın'),
        greaterThan(SpellEngine.limitFor(5)),
      );
    });
  });

  group('alan bağlama (ilke 1–3)', () {
    test('C3 "herşey " → "Her şey "; Enter satır sonu nokta', () {
      final kb = _Kb();
      kb.type('herşey ');
      expect(kb.t, 'Her şey ');
      kb.type('yolunda gidiyor\n');
      expect(kb.t, 'Her şey yolunda gidiyor.\n');
    });

    test('ilke 3: tek Backspace özgün yazıyı getirir, çift reddedilir', () {
      final kb = _Kb();
      kb.type('bu kalen ');
      expect(kb.t, 'Bu kalem ');
      kb.backspace();
      expect(kb.t, 'Bu kalen');
      expect(AutoSpell.memory.isRejected('kalen', 'kalem'), isTrue);
      kb.type(' bir kalen ');
      expect(kb.t, 'Bu kalen bir kalen ');
    });

    test('ilke 1: hemen silip başka kelime yazınca çift ANINDA reddedilir', () {
      final kb = _Kb();
      kb.type('bu kalen ');
      kb.retype('kalem', 2, 'in');
      expect(kb.t, 'Bu kalin ');
      kb.type('ve ');
      expect(AutoSpell.memory.isRejected('kalen', 'kalem'), isTrue);
      // Başka notta da çift dönmez; kullanıcının yazdığı öğrenildi.
      AutoSpell.beginNote();
      final kb2 = _Kb();
      kb2.type('bu kalen ');
      expect(kb2.t, 'Bu kalin ');
    });

    test('düzeltmenin önüne yeni kelime yazmak itiraz sayılmaz', () {
      final kb = _Kb();
      kb.type('bu kalen ');
      kb.c.selection = const TextSelection.collapsed(offset: 3);
      kb.type('mavi ');
      kb.end();
      kb.type('ve ');
      expect(kb.t, 'Bu mavi kalem ve ');
      expect(AutoSpell.memory.isRejected('kalen', 'kalem'), isFalse);
    });

    test('kendi kelimeni iki kez düzeltince öğrenilir', () {
      final kb = _Kb()..type('bu ');
      for (var i = 0; i < 2; i++) {
        kb.type('togh ');
        kb.retype('togh', 1, 'g');
        kb.type('x ');
      }
      kb.type('togh ');
      expect(kb.t.endsWith('togg '), isTrue, reason: kb.t);
    });

    test('J9 yapıştırma ve dikte (çok karakter) düzeltilmez', () {
      final kb = _Kb();
      kb.paste('☐ yaoıyor herşey ');
      expect(kb.t, '☐ yaoıyor herşey ');
    });

    test('D2 başlık: "bakım togg" → "Bakım Togg"', () {
      final c = WrapTextController();
      AutoSpell.attach(c, () {}, title: true);
      for (final ch in 'bakım togg '.split('')) {
        final caret = c.selection.isValid ? c.selection.baseOffset : 0;
        c.value = TextEditingValue(
          text: c.text.replaceRange(caret, caret, ch),
          selection: TextSelection.collapsed(offset: caret + 1),
        );
      }
      expect(c.text, 'Bakım Togg ');
    });
  });

  group('hafıza v2', () {
    test(
      'v1 → v2 göçü: düzeltmeler + reddedilenler taşınır, karışıklık atılır',
      () {
        const v1 =
            '{"v":1,"w":{"kalem":4},"f":{"togh":{"togg":3,"tog":1}},'
            '"r":["abc"],"c":{"o>p":2}}';
        final m = SpellMemory.decode(v1);
        expect(m.fromV1, isTrue);
        expect(m.words['kalem'], 4);
        expect(m.learned('togh'), 'togg');
        expect(m.keep, contains('abc'));
        final back = SpellMemory.decode(m.encode());
        expect(back.fromV1, isFalse);
        expect(back.learned('togh'), 'togg');
        expect(back.keep, contains('abc'));
        expect(back.encode().contains('"c"'), isFalse);
      },
    );

    test('JSON gidiş-dönüş ve bozuk dosya', () {
      final m = SpellMemory()
        ..addWord('kalem')
        ..learnFix('togh', 'togg')
        ..rejectPair('kalen', 'kalem');
      final back = SpellMemory.decode(m.encode());
      expect(back.words['kalem'], 1);
      expect(back.fixList().single.to, 'togg');
      expect(back.isRejected('kalen', 'kalem'), isTrue);
      expect(SpellMemory.decode('bozuk').isEmpty, isTrue);
    });

    test('elle eklenen düzeltme silinince unutulur; red geri alınır', () {
      final m = SpellMemory()..addManualFix('yanlız', 'yalnız');
      expect(m.learned('yanlız'), 'yalnız');
      m.removeFix('yanlız');
      expect(m.learned('yanlız'), isNull);
      m.rejectPair('kalen', 'kalem');
      m.unreject('kalen>kalem');
      expect(m.isRejected('kalen', 'kalem'), isFalse);
    });

    test('öğretilen çift reddi kaldırır', () {
      final m = SpellMemory()..rejectPair('togh', 'togg');
      m.addManualFix('togh', 'togg');
      expect(m.isRejected('togh', 'togg'), isFalse);
    });
  });

  testWidgets('F70.5 Öğrenilen yazımlar: v2 verisi, red geri alınır, kip', (
    tester,
  ) async {
    final m = SpellMemory()
      ..addManualFix('togh', 'togg')
      ..rejectPair('kalen', 'kalem')
      ..keep.add('abc');
    SharedPreferences.setMockInitialValues({'spell_memory_v2': m.encode()});
    AutoSpell.memory = m;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SpellLearnedScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spell-fix-togh')), findsOneWidget);
    expect(find.text('kalen → kalem'), findsOneWidget);
    expect(find.text('abc'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('spell-learned-rules-only')));
    expect(AutoSpell.rulesOnly.value, isTrue);
    final chip = find.ancestor(
      of: find.text('kalen → kalem'),
      matching: find.byType(InputChip),
    );
    await tester.tap(
      find.descendant(of: chip, matching: find.byIcon(Icons.clear)),
    );
    await tester.pump();
    expect(AutoSpell.memory.isRejected('kalen', 'kalem'), isFalse);
    expect(find.text('kalen → kalem'), findsNothing);
    await tester.pump(const Duration(seconds: 5)); // Erteli kayıt.
  });
}
