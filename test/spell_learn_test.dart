import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_fix.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';

void main() {
  group('klavye mesafesi', () {
    test('komşu tuş ucuz, uzak tuş pahalı', () {
      expect(keyCost('o', 'p'), lessThan(0.5));
      expect(keyCost('ı', 'i'), lessThan(0.5));
      expect(keyCost('a', 'p'), 1);
      expect(keyCost('n', ' '), lessThan(1));
    });

    test('"yaoçoılıyor" → "yapılıyor" yakın, "kalem" → "kalın" uzak', () {
      final m = SpellMemory();
      expect(
        m.distance('yaoçoılıyor', 'yapılıyor'),
        lessThanOrEqualTo(SpellMemory.limitFor(11)),
      );
      expect(
        m.distance('kalem', 'kalın'),
        greaterThan(SpellMemory.limitFor(5)),
      );
    });
  });

  group('öneri', () {
    test('ekran görüntüsündeki hata düzelir', () {
      expect(SpellMemory().suggest('yaoçoılıyor'), 'yapılıyor');
    });

    test('Türkçe ek: kök/uzantı ilişkisi düzeltilmez', () {
      final m = SpellMemory();
      expect(m.suggest('kalemi'), isNull);
      expect(m.suggest('bilet'), isNull);
      expect(m.suggest('notları'), isNull);
    });

    test('bilinen kelimeye dokunulmaz', () {
      expect(SpellMemory().suggest('kalem'), isNull);
      expect(SpellMemory().suggest('eksik'), isNull);
    });

    test('boşluk yerine n: iki bilinen kelimeye bölünür', () {
      expect(SpellMemory().suggest('eksiknyapılıyor'), 'eksik yapılıyor');
      expect(SpellMemory().suggest('benimnkalem'), 'benim kalem');
    });

    test('kullanıcının düzeltmesi öğrenilir (iki kez → kendiliğinden)', () {
      final m = SpellMemory();
      m.learnFix('togh', 'togg');
      // Tek görülme: "togh" bilinmiyorsa yine önerilir.
      expect(m.suggest('togh'), 'togg');
      m.learnFix('togh', 'togg');
      expect(m.suggest('Togh'.toLowerCase()), 'togg');
    });

    test('harf karışıklığı öğrenilir, mesafe ucuzlar', () {
      final m = SpellMemory();
      final before = m.distance('kapq', 'kapı');
      for (var i = 0; i < 3; i++) {
        m.learnFix('kapq', 'kapı');
      }
      expect(m.confusions['q>ı'], 3);
      expect(m.distance('kapq', 'kapı'), lessThan(before));
    });

    test('geri alınan otomatik düzeltme bir daha yapılmaz', () {
      final m = SpellMemory();
      expect(m.suggest('yaoçoılıyor'), 'yapılıyor');
      m.reject('yaoçoılıyor', wrongFix: 'yapılıyor');
      expect(m.suggest('yaoçoılıyor'), isNull);
    });

    test('Çince: bulanık düzeltme yok, açık düzeltme öğrenilir', () {
      final m = SpellMemory();
      expect(m.suggest('我的'), isNull);
      m
        ..learnFix('在见', '再见')
        ..learnFix('在见', '再见');
      expect(m.suggest('在见'), '再见');
    });

    test('İngilizce', () {
      final m = SpellMemory();
      expect(looksEnglish('meeting'), isTrue);
      expect(looksEnglish('yapılıyor'), isFalse);
      expect(m.suggest('meetinf'), 'meeting');
    });

    test('notlardan sözlük: sık kelime bilinir', () {
      final m = SpellMemory()
        ..seed(seedCounts(['togg bakım togg servis togg']));
      expect(m.known('togg'), isTrue);
      expect(m.suggest('tofg'), 'togg');
    });

    test('JSON gidiş-dönüş', () {
      final m = SpellMemory()
        ..addWord('kalem')
        ..learnFix('togh', 'togg')
        ..reject('abc');
      final back = SpellMemory.decode(m.encode());
      expect(back.words['kalem'], greaterThan(0));
      expect(back.fixes['togh']?['togg'], 1);
      expect(back.rejected, contains('abc'));
      expect(SpellMemory.decode('bozuk').isEmpty, isTrue);
    });
  });

  group('başlık', () {
    test('kelime başları büyür (Türkçe i → İ)', () {
      final t = 'bakım ';
      final e = titleFixAt(t, t.length)!;
      expect(t.replaceRange(e.start, e.end, e.text), 'Bakım ');
      final t2 = 'Bakım işleri ';
      final e2 = titleFixAt(t2, t2.length)!;
      expect(t2.replaceRange(e2.start, e2.end, e2.text), 'Bakım İşleri ');
    });

    test('kısaltma ve zaten büyük kelime değişmez', () {
      expect(titleFixAt('TOGG ', 5), isNull);
      expect(titleFixAt('Bakım ', 6), isNull);
    });
  });

  group('oturum E (2026-11-08)', () {
    test('elle eklenen düzeltme ilk görüşte uygulanır, silinince unutulur', () {
      final m = SpellMemory()..addManualFix('yanlız', 'yalnız');
      expect(m.suggest('yanlız'), 'yalnız');
      expect(m.fixList().single.to, 'yalnız');
      m.removeFix('yanlız');
      expect(m.fixes, isEmpty);
    });

    test('boşluk yerine ö: iki bilinen kelime ayrılır', () {
      final m = SpellMemory()
        ..seed(seedCounts(['kalem defter kalem defter kalem defter']));
      expect(m.splitMissedSpace('kalemödefter'), 'kalem defter');
    });

    test('klavye önerisiyle değişen kelime yakalanır; tamamlama değil', () {
      expect(
        AutoSpell.replacedWord('bu yaoıyor ', 'bu yapıyor '),
        (from: 'yaoıyor', to: 'yapıyor'),
      );
      // Tamamlama ("yap" → "yapıyor") ve harf yazımı öğrenme sayılmaz.
      expect(AutoSpell.replacedWord('bu yap', 'bu yapıyor'), isNull);
      expect(AutoSpell.replacedWord('bu yap', 'bu yapı'), isNull);
      expect(AutoSpell.replacedWord('bu yapı', 'bu yap'), isNull);
      // İlgisiz kelime (yakın değil) öğrenilmez.
      expect(AutoSpell.replacedWord('bu kalem ', 'bu masa '), isNull);
    });

    test('BİLİNEN kelimenin eki değişince öğrenilmez (kalemi → kalemde)', () {
      final saved = AutoSpell.memory;
      addTearDown(() => AutoSpell.memory = saved);
      AutoSpell.memory = SpellMemory()..addWord('kalemi', 5);
      expect(AutoSpell.replacedWord('bu kalemi ', 'bu kalemde '), isNull);
      // Bilinmeyen (hatalı) kelime yine öğrenilir.
      expect(
        AutoSpell.replacedWord('bu kalmei ', 'bu kalemi '),
        (from: 'kalmei', to: 'kalemi'),
      );
    });
  });

  test('otomatik düzeltme harflerin üçte birinden fazlasını değiştiremez', () {
    expect(SpellMemory.changesTooMuch('yapıyrum', 'yapıyorum'), isFalse);
    expect(SpellMemory.changesTooMuch('kalmei', 'kalemi'), isFalse);
    expect(SpellMemory.changesTooMuch('toplantı', 'tıpkıydı'), isTrue);
    expect(SpellMemory.changesTooMuch('masa', 'kasa'), isFalse);
  });

  test('yanlış otomatik düzeltmenin üstüne başka kelime: eşleşme unutulur', () {
    final m = SpellMemory()
      ..learnFix('yapiyom', 'yapıyor')
      ..learnFix('yapiyom', 'yapıyor');
    expect(m.suggest('yapiyom'), 'yapıyor');
    m
      ..unlearnFix('yapiyom', 'yapıyor')
      ..learnFix('yapiyom', 'yapıyorum');
    expect(m.fixes['yapiyom']!.keys, ['yapıyorum']);
  });
}
