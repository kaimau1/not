import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/voice_commands.dart';

/// Akıllı sesli not (2026-10-19): dikte sırasında söylenen düzeltme
/// komutları ve sessizlikte kendiliğinden biten dinleme.
void main() {
  String apply(String raw) => applyVoiceCommands(raw).text;

  group('applyVoiceCommands', () {
    test('komut yoksa metin olduğu gibi kalır', () {
      final r = applyVoiceCommands('bugün markete gittim\nekmek aldım');
      expect(r.text, 'bugün markete gittim\nekmek aldım');
      expect(r.commands, 0);
      expect(r.stop, isFalse);
    });

    test('son kelimeyi sil — ayrı segmentte ve aynı cümlede', () {
      expect(apply('bugün markete gittim\nson kelimeyi sil'), 'bugün markete');
      expect(apply('bugün markete gittim son kelimeyi sil'), 'bugün markete');
      expect(apply('Bugün markete gittim. Son kelimeyi sil.'), 'Bugün markete');
    });

    test('silmeden sonra yazma EN SONDAN devam eder', () {
      expect(
        apply('bugün markete gittim\nson kelimeyi sil\nuğradım'),
        'bugün markete\nuğradım',
      );
      expect(
        apply('bugün markete gittim son kelimeyi sil uğradım'),
        'bugün markete uğradım',
      );
    });

    test('son N kelimeyi sil (rakam ya da sözcükle)', () {
      expect(apply('a b c d e son iki kelimeyi sil'), 'a b c');
      expect(apply('a b c d e son 3 kelimeyi sil'), 'a b');
      expect(apply('one two three delete the last two words'), 'one');
    });

    test('yarım komut düz metin görünür, tamamlanınca uygulanır', () {
      expect(
        apply('bugün markete gittim son kelimeyi'),
        'bugün markete gittim son kelimeyi',
      );
      expect(apply('bugün markete gittim son kelimeyi sil'), 'bugün markete');
    });

    test('son cümleyi sil', () {
      expect(
        apply('Birinci cümle. İkinci cümle\nson cümleyi sil'),
        'Birinci cümle.',
      );
      expect(apply('ilk satır\nikinci satır\nson cümleyi sil'), 'ilk satır');
    });

    test('X yerine Y yaz — eski kelime metindeki son geçişte değişir', () {
      expect(
        apply('yarın markete gideceğim\nmarkete yerine pazara yaz'),
        'yarın pazara gideceğim',
      );
      expect(
        apply('yarın markete gideceğim markete yerine pazara yaz ve ekmek'),
        'yarın pazara gideceğim ve ekmek',
      );
    });

    test('kelimesini … ile değiştir ve yanlış oldu … olacak', () {
      expect(
        apply('toplantı salı günü\nsalı kelimesini çarşamba ile değiştir'),
        'toplantı çarşamba günü',
      );
      expect(
        apply('toplantı salı günü\nsalı yanlış oldu perşembe olacak'),
        'toplantı perşembe günü',
      );
    });

    test('ekli eski kelime de bulunur (salıyı → salı)', () {
      expect(
        apply('toplantı salı günü\nsalıyı cuma ile değiştir'),
        'toplantı cuma günü',
      );
    });

    test('metinde olmayan eski kelime: gündelik cümle, dokunulmaz', () {
      expect(
        apply('çay yerine kahve olsun dedim'),
        'çay yerine kahve olsun dedim',
      );
    });

    test('son kelimeyi değiştir', () {
      expect(
        apply('saat beşte buluşalım\nson kelimeyi görüşelim ile değiştir'),
        'saat beşte görüşelim',
      );
      expect(
        apply('saat beşte buluşalım\nson kelime görüşelim olacak'),
        'saat beşte görüşelim',
      );
      expect(
        apply('Meet at five.\nchange the last word to six'),
        'Meet at six.',
      );
    });

    test('İngilizce replace X with Y', () {
      expect(
        apply('buy milk and bread\nreplace milk with eggs'),
        'buy eggs and bread',
      );
    });

    test('yeni satır, hepsini sil, geri al', () {
      expect(
        apply('alışveriş listesi yeni satır süt'),
        'alışveriş listesi\nsüt',
      );
      expect(apply('bir iki üç\nhepsini sil\ndört'), 'dört');
      expect(apply('bir iki üç\nson kelimeyi sil\ngeri al'), 'bir iki üç');
      expect(apply('bir iki üç\nhepsini sil\ngeri al'), 'bir iki üç');
    });

    test('"geri al" cümle içinde komut DEĞİL', () {
      expect(apply('parayı geri al dedi'), 'parayı geri al dedi');
    });

    test('dinlemeyi bitir: metinden çıkar ve stop bayrağı kalkar', () {
      final r = applyVoiceCommands('notum bu kadar\ndinlemeyi bitir');
      expect(r.text, 'notum bu kadar');
      expect(r.stop, isTrue);
      expect(r.last, VoiceCommand.stop);
    });

    test('komut sayısı artar — arayüz yeni komutu buradan anlar', () {
      expect(applyVoiceCommands('a b').commands, 0);
      expect(applyVoiceCommands('a b son kelimeyi sil').commands, 1);
      final r = applyVoiceCommands('a b c son kelimeyi sil yeni satır d');
      expect(r.commands, 2);
      expect(r.last, VoiceCommand.newLine);
      expect(r.text, 'a b\nd');
    });

    test('aynı ham metin her zaman aynı sonucu verir', () {
      const raw = 'yarın markete gideceğim\nmarkete yerine pazara yaz\nsüt al';
      expect(apply(raw), apply(raw));
      expect(apply(raw), 'yarın pazara gideceğim\nsüt al');
    });
  });

  group('applyVoiceCommands — 2. tur', () {
    String apply(String raw, {String base = ''}) =>
        applyVoiceCommands(raw, base: base).text;

    test('yeni madde liste satırı açar', () {
      expect(
        apply('süt yeni madde ekmek sonraki madde yumurta'),
        'süt\nekmek\nyumurta',
      );
      expect(apply('milk new item bread'), 'milk\nbread');
    });

    test('noktalama komutları ve ardından büyük harf', () {
      expect(
        apply('yarın geliyorum nokta koy iyi akşamlar'),
        'yarın geliyorum. İyi akşamlar',
      );
      expect(apply('geliyor musun soru işareti'), 'geliyor musun?');
      expect(apply('elma virgül koy armut'), 'elma, armut');
      expect(apply('liste iki nokta üst üste süt'), 'liste: süt');
    });

    test('tek başına nokta/virgül gündelik kelimedir', () {
      expect(
        apply('bu nokta önemli üç virgül beş'),
        'bu nokta önemli üç virgül beş',
      );
    });

    test('sondaki noktalama yenisiyle değişir', () {
      expect(apply('tamam nokta koy\nsoru işareti'), 'tamam?');
    });

    test('başlık komutu metne girmez, başlığı verir', () {
      final r = applyVoiceCommands('başlık market listesi olsun\nsüt ekmek');
      expect(r.text, 'süt ekmek');
      expect(r.title, 'Market listesi');
      expect(r.last, VoiceCommand.title);
      final en = applyVoiceCommands('buy milk\nset the title to groceries');
      expect(en.text, 'buy milk');
      expect(en.title, 'Groceries');
      expect(applyVoiceCommands('süt al').title, isNull);
    });

    test('Devam et: yeni konuşma öncekinin sonuna boşlukla eklenir', () {
      expect(apply('ve ekmek', base: 'süt aldım'), 'süt aldım ve ekmek');
      expect(apply('son kelimeyi sil', base: 'süt aldım'), 'süt');
      expect(apply('', base: 'süt aldım'), 'süt aldım');
    });
  });

  group('SilenceGate', () {
    final t0 = DateTime(2026, 10, 19, 12);

    test('konuşmadan sonra sessizlikte biter', () {
      final gate = SilenceGate()..start(t0);
      gate.onSpeech(t0.add(const Duration(seconds: 2)));
      expect(gate.shouldStop(t0.add(const Duration(seconds: 5))), isFalse);
      expect(gate.shouldStop(t0.add(const Duration(seconds: 6))), isTrue);
    });

    test('yeni metin saati sıfırlar', () {
      final gate = SilenceGate()..start(t0);
      gate.onSpeech(t0.add(const Duration(seconds: 1)));
      gate.onSpeech(t0.add(const Duration(seconds: 4)));
      expect(gate.shouldStop(t0.add(const Duration(seconds: 7))), isFalse);
      expect(gate.shouldStop(t0.add(const Duration(seconds: 8))), isTrue);
    });

    test('hiç konuşulmadıysa daha uzun bekler', () {
      final gate = SilenceGate()..start(t0);
      expect(gate.heard, isFalse);
      expect(gate.shouldStop(t0.add(const Duration(seconds: 6))), isFalse);
      expect(gate.shouldStop(t0.add(const Duration(seconds: 12))), isTrue);
    });

    test('yüksek ses kısa süre uzatır ama gürültü sonsuza dek tutamaz', () {
      final gate = SilenceGate()..start(t0);
      gate.onSpeech(t0);
      gate.onLevel(0.9, t0.add(const Duration(seconds: 3)));
      // Seviye saati uzattı: 4 sn'de bitmez.
      expect(gate.shouldStop(t0.add(const Duration(seconds: 5))), isFalse);
      expect(gate.shouldStop(t0.add(const Duration(seconds: 7))), isTrue);
      // Metinden 8 sn'den uzun sonra gelen gürültü sayılmaz.
      gate.onLevel(0.9, t0.add(const Duration(seconds: 20)));
      expect(gate.shouldStop(t0.add(const Duration(seconds: 21))), isTrue);
    });

    test('ilerleme 0–1 arası', () {
      final gate = SilenceGate()..start(t0);
      gate.onSpeech(t0);
      expect(
        gate.progress(t0.add(const Duration(seconds: 2))),
        closeTo(0.5, 0.01),
      );
      expect(gate.progress(t0.add(const Duration(seconds: 30))), 1);
    });
  });
}
