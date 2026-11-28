import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/quick_create_command.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';

void main() {
  group('parseCreateNoteCommand', () {
    test('kullanıcı cümlesi (2026-11-28): yeni alışveriş listesi + başa + içerik', () {
      final c = parseCreateNoteCommand(
        'Yeni bir alışveriş listesi oluştur ve en başa koy eee oraya da elma armut peynir ekmek',
      );
      expect(c, isNotNull);
      expect(c!.list, isTrue);
      expect(c.kind, SmartListKind.shopping);
      expect(c.pin, isTrue);
      expect(c.content, 'elma armut peynir ekmek');
    });

    test('noktalı ve virgüllü yazım da aynı', () {
      final c = parseCreateNoteCommand(
        'Yeni bir alışveriş listesi oluştur ve en başa koy. Eee, oraya da elma, armut',
      );
      expect(c?.kind, SmartListKind.shopping);
      expect(c?.pin, isTrue);
      expect(c?.content, 'elma, armut');
    });

    test('içeriksiz komut ve "sabitle"', () {
      final c = parseCreateNoteCommand('yeni market listesi aç ve sabitle');
      expect(c?.kind, SmartListKind.shopping);
      expect(c?.pin, isTrue);
      expect(c?.content, '');
    });

    test('bilinmeyen ad başlık olur, tür yok', () {
      final c = parseCreateNoteCommand(
        'yeni bir Antalya listesi oluştur: güneş kremi, şapka',
      );
      expect(c?.list, isTrue);
      expect(c?.kind, isNull);
      expect(c?.title, 'Antalya listesi');
      expect(c?.pin, isFalse);
      expect(c?.content, 'güneş kremi, şapka');
    });

    test('yeni yazı notu', () {
      final c = parseCreateNoteCommand('yeni bir not oluştur yarın dişçiyi ara');
      expect(c?.list, isFalse);
      expect(c?.content, 'yarın dişçiyi ara');
    });

    test('önce içerik, sonra "yeni listeye ekle"', () {
      final c = parseCreateNoteCommand('süt ekmek yumurta yeni bir listeye ekle');
      expect(c?.list, isTrue);
      expect(c?.content, 'süt ekmek yumurta');
    });

    test('İngilizce', () {
      final c = parseCreateNoteCommand(
        'create a new shopping list with milk and eggs and pin it',
      );
      expect(c?.kind, SmartListKind.shopping);
      expect(c?.pin, isTrue);
      expect(c?.content, 'milk and eggs');
    });

    test('komut OLMAYANLAR içerik kalır', () {
      for (final s in [
        'yeni bir liste oluşturma özelliği ekle',
        'yeni liste oluştur butonu çalışmıyor',
        'kapıyı aç',
        'listeyi oluştur', // eski liste, ad/yeni yok
        'rapor listesi hazırla', // tür yok, "yeni" yok: görev
        'süt ekmek',
        'proje dosyasını kontrol et',
        'Paylaşılanlar klasörü düzenlenmeli',
      ]) {
        expect(parseCreateNoteCommand(s), isNull, reason: s);
      }
    });

    test('"yeni" olmadan tanınan tür + güçlü fiil komuttur', () {
      expect(
        parseCreateNoteCommand('bavul listesi hazırla')?.kind,
        SmartListKind.packing,
      );
    });
  });

  group('parseDeicticAdd', () {
    test('baştaki gönderme ve doldurma atılır', () {
      expect(
        parseDeicticAdd('Eee oraya da elma armut peynir ekmek'),
        'elma armut peynir ekmek',
      );
      expect(parseDeicticAdd('aynı listeye süt ekle'), 'süt');
      expect(parseDeicticAdd('ona da yumurta'), 'yumurta');
    });

    test('sondaki gönderme', () {
      expect(parseDeicticAdd('elma armut oraya ekle'), 'elma armut');
      expect(parseDeicticAdd('add eggs to it'), 'eggs');
    });

    test('gönderme yoksa null', () {
      expect(parseDeicticAdd('elma armut peynir'), isNull);
      expect(parseDeicticAdd('ona hediye al'), isNull);
      expect(parseDeicticAdd('oraya'), isNull);
    });
  });

  group('parseReminderCommand (kullanıcı bulgusu 2026-11-28)', () {
    final at1731 = DateTime(2026, 11, 28, 17, 31);
    test('"bugün saat 8\'de … bana hatırlat" akşam 20:00', () {
      final r = parseReminderCommand(
        "bugün saat 8'de duş alacağım bana hatırlat",
        now: at1731,
      );
      expect(r, isNotNull);
      expect(r!.at, DateTime(2026, 11, 28, 20));
      expect(r.content, 'Duş alacağım');
    });
    test('sabah saati açıkça söylenip geçtiyse kurulmaz', () {
      expect(
        parseReminderCommand('bugün sabah 8 de ilaç bana hatırlat', now: at1731),
        isNull,
      );
    });
    test('yarın, İngilizce, hatırlatır mısın', () {
      expect(
        parseReminderCommand('yarın 10:30 toplantıyı hatırlatır mısın',
                now: at1731)
            ?.at,
        DateTime(2026, 11, 29, 10, 30),
      );
      final en = parseReminderCommand(
        'remind me to call mom at 9 pm',
        languageCode: 'en',
        now: at1731,
      );
      expect(en?.at, DateTime(2026, 11, 28, 21));
    });
    test('hatırlatma isteği ya da tarih yoksa null', () {
      expect(parseReminderCommand('süt ekmek', now: at1731), isNull);
      expect(parseReminderCommand('bana hatırlat', now: at1731), isNull);
    });
  });
}
