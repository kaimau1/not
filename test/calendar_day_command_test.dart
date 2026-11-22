import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/calendar_day_command.dart';

void main() {
  // 22 Kasım 2026 Pazar.
  final now = DateTime(2026, 11, 22, 10, 57);
  CalendarDayCommand? tr(String s) => parseCalendarDayCommand(s, now: now);
  CalendarDayCommand? en(String s) =>
      parseCalendarDayCommand(s, languageCode: 'en', now: now);

  test('bugüne / yarına / öbür güne', () {
    expect(tr('süt al bugüne ekle'), (
      day: DateTime(2026, 11, 22),
      content: 'süt al',
    ));
    expect(tr('Dişçi yarına ekle')?.day, DateTime(2026, 11, 23));
    expect(tr('Dişçi yarına ekle')?.content, 'Dişçi');
    expect(tr('rapor öbür güne ekle')?.day, DateTime(2026, 11, 24));
    expect(tr('rapor bu güne not ekle')?.day, DateTime(2026, 11, 22));
  });

  test('1 Ocak: gelecek yılın 1 Ocağı', () {
    for (final s in [
      'parti 1 ocağa ekle',
      "parti 1 Ocak'a ekle",
      'parti 1 ocağı ekle',
      'parti 1 ocak tarihine ekle',
    ]) {
      expect(tr(s), (day: DateTime(2027), content: 'parti'), reason: s);
    }
    expect(tr('toplantı 25 kasıma ekle')?.day, DateTime(2026, 11, 25));
    expect(tr("x 3 mart 2028'e ekle")?.day, DateTime(2028, 3, 3));
  });

  test('göreli: bir hafta / bir gün / 3 gün / bir ay sonra', () {
    expect(tr('fatura bir hafta sonrasına ekle')?.day, DateTime(2026, 11, 29));
    expect(tr('fatura bir gün sonrasına ekle')?.day, DateTime(2026, 11, 23));
    expect(tr('fatura 3 gün sonraya ekle')?.day, DateTime(2026, 11, 25));
    expect(tr('fatura bir ay sonraya ekle')?.day, DateTime(2026, 12, 22));
    expect(tr('fatura haftaya ekle')?.day, DateTime(2026, 11, 29));
  });

  test('hafta günleri', () {
    expect(tr('spor cumaya ekle')?.day, DateTime(2026, 11, 27));
    expect(tr('spor pazartesiye ekle')?.day, DateTime(2026, 11, 23));
    expect(tr('spor cumartesiye ekle')?.day, DateTime(2026, 11, 28));
    expect(tr('spor pazara ekle')?.day, DateTime(2026, 11, 29));
  });

  test('takvime ekle: gün yoksa bugün', () {
    expect(tr('rapor takvime ekle'), (
      day: DateTime(2026, 11, 22),
      content: 'rapor',
    ));
    expect(tr('rapor yarın için takvime ekle')?.day, DateTime(2026, 11, 23));
  });

  test('gün hedefi olmayan olağan ekleme komut değil', () {
    expect(tr('süt ekle'), isNull);
    expect(tr('alışveriş listesine süt ekle'), isNull);
    expect(tr('bugün süt aldım'), isNull);
    expect(tr('süt, ekmek'), isNull);
  });

  test('İngilizce', () {
    expect(en('milk add to today'), (
      day: DateTime(2026, 11, 22),
      content: 'milk',
    ));
    expect(en('dentist add to tomorrow')?.day, DateTime(2026, 11, 23));
    expect(en('party add to jan 1')?.day, DateTime(2027));
    expect(en('bill add in 3 days')?.day, DateTime(2026, 11, 25));
    expect(en('gym add to friday')?.day, DateTime(2026, 11, 27));
    expect(en('report add to calendar')?.day, DateTime(2026, 11, 22));
    expect(en('add milk'), isNull);
  });
}
