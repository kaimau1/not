import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/domain/holidays.dart';

void main() {
  test('sabit resmî tatiller ve 28 Ekim yarım gün', () {
    final h = buildHolidays(2026);
    expect(h['2026-01-01']!.short, 'Yılbaşı');
    expect(h['2026-04-23']!.isOff, isTrue);
    expect(h['2026-07-15']!.name, contains('Demokrasi'));
    expect(h['2026-10-29']!.kind, HolidayKind.national);
    expect(h['2026-10-28']!.kind, HolidayKind.halfDay);
    expect(h['2026-10-28']!.isOff, isFalse);
    expect(buildHolidays(2016)['2016-07-15'], isNull);
  });

  test('2026 bayramları: Ramazan 3 gün, Kurban 4 gün, arifeler yarım', () {
    final h = buildHolidays(2026);
    expect(h['2026-03-19']!.kind, HolidayKind.halfDay);
    for (final d in ['2026-03-20', '2026-03-21', '2026-03-22']) {
      expect(h[d]!.short, 'Ramazan Bayramı', reason: d);
    }
    expect(h['2026-03-23'], isNull);
    expect(h['2026-05-26']!.kind, HolidayKind.halfDay);
    for (final d in ['2026-05-27', '2026-05-28', '2026-05-29', '2026-05-30']) {
      expect(h[d]!.short, 'Kurban Bayramı', reason: d);
    }
    expect(h['2026-05-27']!.estimated, isFalse);
  });

  test('çakışan günler birleşir; tahmini yıl işaretli', () {
    // 2029: Kurban Bayramı tahminen 23 Nisan'a denk.
    final h = buildHolidays(2029)['2029-04-23']!;
    expect(h.name, contains('Çocuk Bayramı'));
    expect(h.name, contains('Kurban'));
    expect(h.isOff, isTrue);
    expect(h.estimated, isTrue);
  });

  test('uzaktan düzeltme: kesin tarih, uzatma, çıkarma', () {
    final o = HolidayOverrides.fromMap({
      'religious': {
        '2028': {'ramazan': '2028-02-27', 'kurban': 'bozuk'},
      },
      'extra': {'2026-05-25': ' İdari izin ', 'yanlış': 'x', '2026-05-31': ''},
      'removed': ['2026-10-28', 3],
    });
    final y26 = buildHolidays(2026, o);
    expect(y26['2026-05-25']!.kind, HolidayKind.extra);
    expect(y26['2026-05-25']!.name, 'İdari izin');
    expect(y26['2026-05-31'], isNull);
    expect(y26['2026-10-28'], isNull);
    final y28 = buildHolidays(2028, o);
    expect(y28['2028-02-27']!.short, 'Ramazan Bayramı');
    expect(y28['2028-02-27']!.estimated, isFalse);
    expect(y28['2028-02-26']!.kind, HolidayKind.halfDay); // yeni arife
    // Kurban bozuk → yerleşik tahmin sürer.
    expect(y28['2028-05-04']!.estimated, isTrue);
  });

  test('kapalı takvim hiçbir şey döndürmez; açık takvim önbellekli', () {
    expect(const HolidayCalendar.off().on(DateTime(2026, 4, 23)), isNull);
    final c = HolidayCalendar();
    expect(c.on(DateTime(2026, 10, 29))!.short, '29 Ekim Bayramı');
    expect(identical(c.year(2026), c.year(2026)), isTrue);
    expect(HolidayOverrides.fromMap(null).isEmpty, isTrue);
  });
}
