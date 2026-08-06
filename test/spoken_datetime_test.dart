import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spoken_datetime.dart';

/// Sesli asistanın hatırlatıcı emniyet ağının sınavı.
/// En kritik iki davranış: (1) gerçek zaman ifadelerini yakalaması,
/// (2) zamansız cümlelerde hatırlatıcı UYDURMAMASI.
void main() {
  // Pazar, 26 Temmuz 2026, saat 22:15.
  final now = DateTime(2026, 7, 26, 22, 15);

  DateTime? parse(String text) => parseSpokenDateTime(text, now: now);

  test('kullanıcının bildirdiği cümle çözülür', () {
    expect(parse('yarın sabah 9 da toplantım var'), DateTime(2026, 7, 27, 9));
  });

  test('gün ifadeleri', () {
    expect(parse('bugün saat 23:30 ara'), DateTime(2026, 7, 26, 23, 30));
    expect(parse('yarın 14:00 randevu'), DateTime(2026, 7, 27, 14));
    expect(parse('öbür gün saat 10 buluşma'), DateTime(2026, 7, 28, 10));
  });

  test('gün adı en yakın gelecekteki gündür', () {
    // 26 Temmuz 2026 pazar; "salı" iki gün sonra.
    expect(parse('salı saat 11 toplantı')?.day, 28);
    // Bugünün adı söylenirse kastedilen HAFTAYA aynı gündür.
    expect(parse('pazar saat 11')?.day, 2);
  });

  test('günün bölümü saati kaydırır', () {
    expect(parse('yarın akşam 7 de yemek'), DateTime(2026, 7, 27, 19));
    expect(parse('yarın öğleden sonra 3 te'), DateTime(2026, 7, 27, 15));
    expect(parse('yarın sabah 8 de'), DateTime(2026, 7, 27, 8));
    // Saat 24'lük yazıldıysa kaydırma yapılmaz.
    expect(parse('yarın akşam 19:30'), DateTime(2026, 7, 27, 19, 30));
  });

  test('saat söylenmezse sabah 9 varsayılır', () {
    expect(parse('yarın toplantım var'), DateTime(2026, 7, 27, 9));
  });

  test('gün söylenmezse geçmiş saat ertesi güne kayar', () {
    // Şu an 22:15; "saat 9" bugün geçmiş → yarın.
    expect(parse('saat 9 da ara'), DateTime(2026, 7, 27, 9));
    expect(parse('saat 23 te ara'), DateTime(2026, 7, 26, 23));
  });

  test('zaman ipucu yoksa hatırlatıcı uydurulmaz', () {
    for (final text in [
      'toplantım var',
      'markete gitmem lazım',
      '3 elma 2 armut al',
      // "bugünlük" içinde "bugün" geçer ama kelime değildir.
      'bugünlük bu kadar diye not al',
      // "yarım" ile "yarın" karışmamalı.
      'yarım ekmek al',
    ]) {
      expect(parse(text), isNull, reason: text);
    }
  });

  test('geçmiş bir gün söylenirse hatırlatıcı kurulmaz', () {
    expect(parseSpokenDateTime('bugün saat 8 de', now: now), isNull);
  });

  test('büyük harfli ve I/İ içeren metin de çözülür', () {
    expect(parse('YARIN SABAH 9 DA'), DateTime(2026, 7, 27, 9));
  });

  group('İngilizce', () {
    DateTime? en(String text) =>
        parseSpokenDateTime(text, languageCode: 'en', now: now);

    test('gün + saat', () {
      expect(en('tomorrow at 9'), DateTime(2026, 7, 27, 9));
      expect(en('tomorrow at 9 am'), DateTime(2026, 7, 27, 9));
      expect(en('today at 23:30'), DateTime(2026, 7, 26, 23, 30));
      expect(en('half past 8 tomorrow'), DateTime(2026, 7, 27, 8, 30));
    });

    test('öğleden sonra imi saati kaydırır', () {
      expect(en('call me at 11 pm'), DateTime(2026, 7, 26, 23));
      expect(en('meeting tomorrow evening at 7'), DateTime(2026, 7, 27, 19));
      expect(en('tomorrow morning'), DateTime(2026, 7, 27, 9));
    });

    test('zaman ipucu yoksa hatırlatıcı uydurulmaz', () {
      expect(en('i have a meeting'), isNull);
      expect(en('buy 3 apples and 2 pears'), isNull);
    });

    // Bölgeli etiket ('en-US', 'en_GB') de aynı dile düşmeli.
    test('bölge kodu göz ardı edilir', () {
      expect(
        parseSpokenDateTime('tomorrow at 9', languageCode: 'en-US', now: now),
        DateTime(2026, 7, 27, 9),
      );
    });
  });

  group('Almanca', () {
    DateTime? de(String text) =>
        parseSpokenDateTime(text, languageCode: 'de', now: now);

    test('gün + saat', () {
      expect(de('morgen um 9'), DateTime(2026, 7, 27, 9));
      expect(de('heute um 23:30'), DateTime(2026, 7, 26, 23, 30));
      expect(de('übermorgen'), DateTime(2026, 7, 28, 9));
    });

    // "morgens" (sabahları) ve "übermorgen" içinde "morgen" GEÇER ama
    // kelime değildir: yarın sanılırsa hatırlatıcı bir gün kayardı.
    test('"morgens" ve "übermorgen" yarın sanılmaz', () {
      expect(de('morgens um 8 anrufen'), DateTime(2026, 7, 27, 8));
      expect(de('am nachmittag um 3'), DateTime(2026, 7, 27, 15));
    });

    test('zaman ipucu yoksa hatırlatıcı uydurulmaz', () {
      expect(de('ich habe einen termin'), isNull);
    });
  });

  group('İspanyolca', () {
    DateTime? es(String text) =>
        parseSpokenDateTime(text, languageCode: 'es', now: now);

    test('gün + saat', () {
      expect(es('mañana a las 9'), DateTime(2026, 7, 27, 9));
      expect(es('hoy a las 23:30'), DateTime(2026, 7, 26, 23, 30));
      expect(es('pasado mañana'), DateTime(2026, 7, 28, 9));
      expect(es('llámame a las 8 y media'), DateTime(2026, 7, 27, 8, 30));
    });

    // "mañana" hem yarın hem sabah demek: "por la mañana" GÜN değil bölüm.
    test('"la mañana" bölümdür, yarın değildir', () {
      expect(es('mañana por la mañana'), DateTime(2026, 7, 27, 9));
      expect(es('esta tarde a las 5'), DateTime(2026, 7, 27, 17));
    });

    test('zaman ipucu yoksa hatırlatıcı uydurulmaz', () {
      expect(es('tengo una reunión'), isNull);
    });
  });

  test('desteklenmeyen dilde emniyet ağı yok', () {
    expect(spokenDateTimeSupported('tr'), isTrue);
    expect(spokenDateTimeSupported('en-US'), isTrue);
    // Fransızca 2026-08-06'da eklendi (bkz. spoken_datetime_i18n_test.dart);
    // sözlüğü olmayan bir dil hâlâ modele düşer.
    expect(spokenDateTimeSupported('sv'), isFalse);
    // İsveççe "imorgon klockan 9" çözülmez: hatırlatıcı modele kalır.
    expect(
      parseSpokenDateTime(
        'imorgon klockan 9',
        languageCode: 'sv',
        now: now,
      ),
      isNull,
    );
  });
}
