import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/tr_datetime.dart';

/// Sesli asistanın hatırlatıcı emniyet ağının sınavı.
/// En kritik iki davranış: (1) gerçek zaman ifadelerini yakalaması,
/// (2) zamansız cümlelerde hatırlatıcı UYDURMAMASI.
void main() {
  // Pazar, 26 Temmuz 2026, saat 22:15.
  final now = DateTime(2026, 7, 26, 22, 15);

  DateTime? parse(String text) => parseTurkishDateTime(text, now: now);

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
    expect(parseTurkishDateTime('bugün saat 8 de', now: now), isNull);
  });

  test('büyük harfli ve I/İ içeren metin de çözülür', () {
    expect(parse('YARIN SABAH 9 DA'), DateTime(2026, 7, 27, 9));
  });
}
